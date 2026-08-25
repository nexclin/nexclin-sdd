-- SPEC 002, Fase 2 — T005, T006, T007, T008.
--
-- Fecha duas lacunas que a constituição já exigia e o banco não entregava:
--
--   Regra (d): toda ação administrativa sobre dado de cliente gera auditoria
--   com quem, o quê, quando e o diff old→new. Hoje só ação de SUPERADMIN é
--   auditada (`superadmin_audit_log`). O que o dono da clínica faz dentro da
--   própria conta não deixa rastro nenhum — e é dado de saúde.
--
--   Exclusão de paciente é destrutiva e definitiva. Um DELETE apaga a linha e
--   leva junto o histórico clínico, sem volta e sem registro de quem mandou.
--
-- Esta migração é FAIXA A pela §2.5 do CLAUDE.md: atravessa como banco, e vai
-- intacta para a stack nova. Escrita primeiro aqui, que é a fonte de verdade do
-- schema, e só depois levada à plataforma pela ponte inversa (T014 inverte a
-- ordem que o handoff previa, e essa é a ordem certa pela constituição).
--
-- NÃO aplicada em produção por esta sessão. Aplicar exige o export do banco
-- feito antes (T004) e é ato do Arthur.

-- ---------------------------------------------------------------------------
-- T005 — a trilha de auditoria de dado da clínica
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.data_audit_log (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id    uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  actor        uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  table_name   text NOT NULL,
  action       text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  record_id    uuid NOT NULL,
  previous_state jsonb
);

-- `actor` é anulável de propósito: escrita por trigger de banco (service role,
-- job, migração) não tem `auth.uid()`. Registrar NULL e dizer que foi o sistema
-- é honesto; inventar um autor não é.

COMMENT ON TABLE  public.data_audit_log IS
  'Trilha de auditoria de dado da clínica (regra (d) da constituição). Escrita apenas por trigger; ninguém escreve direto.';
COMMENT ON COLUMN public.data_audit_log.previous_state IS
  'Linha inteira ANTES da mudança, em jsonb. É o que permite reconstruir o registro (T012).';
COMMENT ON COLUMN public.data_audit_log.actor IS
  'auth.uid() no momento da escrita. NULL quando a mudança veio do sistema, não de uma pessoa.';

CREATE INDEX IF NOT EXISTS data_audit_log_clinic_created_idx
  ON public.data_audit_log (clinic_id, created_at DESC);
CREATE INDEX IF NOT EXISTS data_audit_log_registro_idx
  ON public.data_audit_log (table_name, record_id);

ALTER TABLE public.data_audit_log ENABLE ROW LEVEL SECURITY;

-- Leitura: admin da própria clínica, ou superadmin. Ninguém mais.
-- Auditoria que o auditado consegue ler inteira perde metade da serventia; e
-- auditoria que ninguém consegue ler perde a outra metade.
CREATE POLICY "Admin da clinica ou superadmin leem a trilha"
  ON public.data_audit_log
  FOR SELECT
  TO authenticated
  USING (
    public.is_superadmin(auth.uid())
    OR (
      clinic_id = public.get_my_clinic_id()
      AND public.has_role(auth.uid(), 'admin')
    )
  );

-- Sem policy de INSERT, UPDATE ou DELETE, de propósito.
--
-- Com RLS ligada e nenhuma policy de escrita, toda escrita vinda de uma sessão
-- de usuário é negada. Quem grava é o trigger, que roda SECURITY DEFINER e não
-- passa por RLS. É assim que "escrita só pelo trigger" se implementa de fato:
-- pela ausência da permissão, não por confiança no código da aplicação.
--
-- A consequência desejada: a trilha é imutável para todo mundo, inclusive para
-- o admin da clínica e para o superadmin. Não existe caminho de UPDATE nem de
-- DELETE em cima dela por sessão autenticada.

REVOKE INSERT, UPDATE, DELETE ON public.data_audit_log FROM authenticated;
GRANT  SELECT ON public.data_audit_log TO authenticated;

-- ---------------------------------------------------------------------------
-- T007 — soft delete em patients
-- ---------------------------------------------------------------------------

ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

COMMENT ON COLUMN public.patients.deleted_at IS
  'Exclusão marca, não remove. NULL = ativo. Preenchido = excluído para a aplicação, presente para auditoria.';

-- Índice parcial: as listas do dia a dia leem só o que está ativo, e é o
-- caminho quente. O índice parcial é menor e mais rápido que um índice cheio
-- sobre uma coluna quase toda NULL.
CREATE INDEX IF NOT EXISTS patients_ativos_idx
  ON public.patients (clinic_id)
  WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- T006 — o trigger de auditoria
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.audita_mudanca_de_dado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clinic_id uuid;
  v_record_id uuid;
  v_previous  jsonb;
BEGIN
  -- Em DELETE só existe OLD; em INSERT só existe NEW.
  IF TG_OP = 'INSERT' THEN
    v_clinic_id := NEW.clinic_id;
    v_record_id := NEW.id;
    v_previous  := NULL;   -- não havia estado anterior
  ELSE
    v_clinic_id := OLD.clinic_id;
    v_record_id := OLD.id;
    v_previous  := to_jsonb(OLD);
  END IF;

  INSERT INTO public.data_audit_log (
    clinic_id, actor, table_name, action, record_id, previous_state
  ) VALUES (
    v_clinic_id, auth.uid(), TG_TABLE_NAME, TG_OP, v_record_id, v_previous
  );

  -- AFTER trigger: o retorno é ignorado, mas plpgsql exige um.
  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.audita_mudanca_de_dado() IS
  'Grava em data_audit_log o estado ANTERIOR da linha. SECURITY DEFINER para escrever numa tabela sem policy de INSERT.';

-- SECURITY DEFINER com search_path fixo. Sem o `SET search_path`, um schema
-- malicioso no caminho poderia sequestrar a função — é o erro clássico de
-- SECURITY DEFINER, e o resto do banco já segue esse padrão.

REVOKE ALL ON FUNCTION public.audita_mudanca_de_dado() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS patients_audita_mudanca ON public.patients;
CREATE TRIGGER patients_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- ---------------------------------------------------------------------------
-- T008 — as policies de patients param de entregar linha apagada
-- ---------------------------------------------------------------------------

-- A policy antiga era uma só, `FOR ALL`, e cobria leitura e escrita com a mesma
-- condição. Ela precisa ser separada por operação: a leitura passa a esconder
-- o que foi excluído, e a escrita continua podendo tocar a linha excluída, que
-- é o que permite restaurar um paciente apagado por engano.

DROP POLICY IF EXISTS "Users can manage patients in their clinic" ON public.patients;

CREATE POLICY "Clinica le seus pacientes ativos"
  ON public.patients
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.get_my_clinic_id()
    AND deleted_at IS NULL
  );

CREATE POLICY "Clinica cadastra paciente"
  ON public.patients
  FOR INSERT
  TO authenticated
  WITH CHECK (clinic_id = public.get_my_clinic_id());

-- UPDATE não filtra `deleted_at` no USING: é por ele que a exclusão acontece
-- (`SET deleted_at = now()`) e é por ele que a restauração acontece
-- (`SET deleted_at = NULL`). O `WITH CHECK` impede que a linha seja movida para
-- outra clínica no meio do caminho.
CREATE POLICY "Clinica atualiza e restaura seu paciente"
  ON public.patients
  FOR UPDATE
  TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());

-- DELETE físico deixa de existir para a aplicação.
--
-- Não se cria policy de DELETE, e por isso ele é negado por default deny. É
-- deliberado e é o ponto da tarefa: se o DELETE continuasse disponível, a
-- aplicação poderia apagar de verdade e o soft delete viraria convenção
-- opcional em vez de garantia do banco. Expurgo por retenção da LGPD, quando
-- existir, entra por rotina com service role e spec própria.
REVOKE DELETE ON public.patients FROM authenticated;

-- ---------------------------------------------------------------------------
-- Retenção
-- ---------------------------------------------------------------------------

-- A trilha não tem expurgo aqui de propósito. A política de retenção e expurgo
-- da LGPD é dívida própria, registrada no BACKLOG, e precisa considerar pisos
-- de guarda conflitantes (prontuário 20 anos, documento de resíduo 5 anos).
-- Apagar trilha antes dessa decisão é escolher errado por omissão.
