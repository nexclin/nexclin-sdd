-- ===========================================================================
-- 024 FASE 1 — o que fica gravado: quem e responsável, quem e o médico, e
--              tarefa que não se apaga
-- ===========================================================================
--
-- Regra: docs/regras/024-perfil-operacional.md, seção 3.
-- Plano: docs/planos/024-perfil-operacional/plan.md, Fase 1.
-- Tarefas: T308 a T314 (nexclin#57 a #63).
--
-- Escrita depois do censo de 14/09 (docs/historico/2026-09-14-censo-operacional.md),
-- que fixou três fatos que este arquivo assume:
--   1. `audita_mudanca_de_dado()` existe no banco ao vivo e está ligada só em
--      `patients`. Aqui ela é ESTENDIDA, não criada.
--   2. `tasks.type` é `text` sem `CHECK`. O bloco 5 é comentário.
--   3. `tasks` e `appointments` têm UMA policy cada, `FOR ALL`, por `clinic_id`.
--      `get_my_clinic_id()` existe e é o que as policies de `team_members` usam.
--
-- ESTE ARQUIVO NÃO TOCA NENHUMA LINHA EXISTENTE. Só cria coluna anulável,
-- trigger, coluna jsonb com default e policies. Nenhuma coluna de texto
-- (`tasks.responsible`, `appointments.doctor`, `appointments.responsible`) é
-- alterada ou migrada: a conversão de texto para pessoa é da stack nova
-- (regra 022, FR-005, emenda de 12/09).
--
-- COMO RODAR: pelo editor de SQL da Lovable, um bloco por vez, na ordem, com
-- o export do banco feito antes (docs/seguranca/registro-exports-banco.md). A
-- reversão de cada bloco está em comentário logo abaixo dele.
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- BLOCO 1 · tasks.responsible_member_id  ·  T308
-- ---------------------------------------------------------------------------
-- "Meu" é o responsável (FR-003). O texto `responsible` fica: 73% dele aponta
-- para setor (censo de 05/09), e não há pessoa para casar. As duas colunas
-- gravam juntas: assumir escreve id e nome; devolver zera os dois.

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS responsible_member_id uuid
    REFERENCES public.team_members(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.tasks.responsible_member_id IS
  'Quem e responsavel pela tarefa, como referencia a team_members (regra 024, FR-003). NULL e tarefa sem dono, que se assume (FR-007). O texto responsible continua existindo e grava junto; nao foi migrado de proposito.';

CREATE INDEX IF NOT EXISTS tasks_responsible_member_idx
  ON public.tasks (clinic_id, responsible_member_id);

-- REVERSÃO DO BLOCO 1:
--   DROP INDEX IF EXISTS public.tasks_responsible_member_idx;
--   ALTER TABLE public.tasks DROP COLUMN IF EXISTS responsible_member_id;


-- ---------------------------------------------------------------------------
-- BLOCO 2 · appointments.responsible_member_id e doctor_member_id  ·  T309
-- ---------------------------------------------------------------------------
-- Responsável é quem agendou; médico é o delegado (FR-002). Data, horário e
-- troca de médico são do responsável e do master; status e fechamento também
-- do médico (FR-004). A tela grava as duas ao criar e ao delegar; o texto fica.

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS responsible_member_id uuid
    REFERENCES public.team_members(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS doctor_member_id uuid
    REFERENCES public.team_members(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.appointments.responsible_member_id IS
  'Quem agendou a consulta, como referencia a team_members (regra 024, FR-002). Edita data, horario e medico. O texto responsible fica.';
COMMENT ON COLUMN public.appointments.doctor_member_id IS
  'O medico delegado, como referencia a team_members (regra 024, FR-002). Edita status e fechamento. O texto doctor fica.';

CREATE INDEX IF NOT EXISTS appointments_responsible_member_idx
  ON public.appointments (clinic_id, responsible_member_id);
CREATE INDEX IF NOT EXISTS appointments_doctor_member_idx
  ON public.appointments (clinic_id, doctor_member_id);

-- REVERSÃO DO BLOCO 2:
--   DROP INDEX IF EXISTS public.appointments_responsible_member_idx;
--   DROP INDEX IF EXISTS public.appointments_doctor_member_idx;
--   ALTER TABLE public.appointments
--     DROP COLUMN IF EXISTS responsible_member_id,
--     DROP COLUMN IF EXISTS doctor_member_id;


-- ---------------------------------------------------------------------------
-- BLOCO 3 · auditoria em tasks e appointments  ·  T310
-- ---------------------------------------------------------------------------
-- Alínea (d): assumir, devolver, reatribuir, mudar data e trocar médico ficam
-- com `previous_state` em `data_audit_log`. NENHUMA tabela nova de histórico
-- (FR-008 e FR-001 da regra 020). Mesma forma de patients_audita_mudanca, da
-- migração 20260825060000, que o censo de 14/09 confirmou no ar.
--
-- A função é SECURITY DEFINER e já cobre INSERT, UPDATE e DELETE. Em `tasks`
-- o DELETE deixa de existir no bloco 6; o trigger cobre mesmo assim, para o
-- caso de service role.

DROP TRIGGER IF EXISTS tasks_audita_mudanca ON public.tasks;
CREATE TRIGGER tasks_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS appointments_audita_mudanca ON public.appointments;
CREATE TRIGGER appointments_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- REVERSÃO DO BLOCO 3:
--   DROP TRIGGER IF EXISTS tasks_audita_mudanca ON public.tasks;
--   DROP TRIGGER IF EXISTS appointments_audita_mudanca ON public.appointments;
--   (as linhas ja gravadas em data_audit_log ficam; auditoria nao se apaga)


-- ---------------------------------------------------------------------------
-- BLOCO 4 · business_rules.task_type_weights  ·  T311
-- ---------------------------------------------------------------------------
-- Peso por tipo de tarefa (FR-012), `{tipo: peso}`, padrão vazio lido como 1
-- para todo tipo ausente. Mesma forma de patient_required_fields
-- (20260324033818). O peso é lido na soma, não gravado na tarefa: mudar o
-- peso muda o passado, e a auditoria de business_rules mostra quando.

ALTER TABLE public.business_rules
  ADD COLUMN IF NOT EXISTS task_type_weights jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.business_rules.task_type_weights IS
  'Peso de cada tipo de tarefa na produtividade (regra 024, FR-012). Objeto {tipo: peso}. Tipo ausente vale 1. Lido na hora da soma, nunca gravado na tarefa.';

-- REVERSÃO DO BLOCO 4:
--   ALTER TABLE public.business_rules DROP COLUMN IF EXISTS task_type_weights;


-- ---------------------------------------------------------------------------
-- BLOCO 5 · recall_paciente em tasks.type  ·  T312  ·  NÃO SE APLICA
-- ---------------------------------------------------------------------------
-- O censo de 14/09 (bloco 3) mostrou: `tasks.type` é `text` e a única CHECK
-- de `tasks` é `tasks_origem_check`. Não há lista de tipos no banco, então
-- `recall_paciente` entra só pela lista do front (src/lib/tiposDeTarefa.ts,
-- T343). Nada a rodar aqui. O bloco existe para que ninguém procure onde
-- ele "deveria" estar.


-- ---------------------------------------------------------------------------
-- BLOCO 6 · tasks: a policy FOR ALL vira três, sem DELETE  ·  T313
-- ---------------------------------------------------------------------------
-- FR-009: tarefa não se apaga; conclui-se ou cancela-se, com registro. A
-- policy de 22/03 é `FOR ALL`, e é o único jeito de tirar o DELETE sem uma
-- quarta policy com USING(false). O predicado de clínica é o mesmo de hoje,
-- escrito com get_my_clinic_id(), que já existe e é o que team_members usa.
--
-- O QUE ESTE BLOCO NÃO FAZ, por decisão da seção 3 da regra: a policy de
-- escopo ("UPDATE só se responsible_member_id é o meu ou sou master") fica
-- declarada e NÃO construída na Lovable. Vai para a stack nova com o FR-011
-- da regra 021. Na Lovable, "edito só o meu" é só no front.
--
-- CUIDADO NA ORDEM: DROP e CREATE no mesmo bloco, sem parar no meio. Entre um
-- e outro, `tasks` fica sem policy e RLS ligado, ou seja, ninguém lê tarefa.

DROP POLICY IF EXISTS "Users can manage tasks in their clinic" ON public.tasks;

CREATE POLICY "tasks_select_na_propria_clinica"
  ON public.tasks FOR SELECT TO authenticated
  USING (clinic_id = public.get_my_clinic_id());

CREATE POLICY "tasks_insert_na_propria_clinica"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (clinic_id = public.get_my_clinic_id());

CREATE POLICY "tasks_update_na_propria_clinica"
  ON public.tasks FOR UPDATE TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());

-- Sem policy de DELETE: default deny, alínea (b). Cancelar é UPDATE de status.

-- REVERSÃO DO BLOCO 6 (volta a policy de 22/03, palavra por palavra):
--   DROP POLICY IF EXISTS "tasks_select_na_propria_clinica" ON public.tasks;
--   DROP POLICY IF EXISTS "tasks_insert_na_propria_clinica" ON public.tasks;
--   DROP POLICY IF EXISTS "tasks_update_na_propria_clinica" ON public.tasks;
--   CREATE POLICY "Users can manage tasks in their clinic" ON public.tasks FOR ALL TO authenticated
--     USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
--     WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));
