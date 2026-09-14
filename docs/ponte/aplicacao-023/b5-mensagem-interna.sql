-- ===========================================================================
-- 023 FASE 1 — a mensagem interna: uma tabela, e a policy por participante
-- ===========================================================================
--
-- Regra: docs/regras/023-avisos-e-recados-da-equipe.md, seção 8.3.
-- Plano: docs/planos/023-avisos-e-recados-da-equipe/plan.md, Fase 1.
-- Tarefas: T207 a T214 (nexclin#10 a #17).
--
-- O que este arquivo assume, pelo censo de 14/09:
--   a publicação supabase_realtime existe e está vazia (o Realtime é a Fase 3,
--   arquivo próprio); task_comments está no ar com SELECT e INSERT; e
--   get_my_clinic_id() existe.
--
-- A POLICY AQUI É DIFERENTE DAS 79 QUE O BANCO TEM: é por PARTICIPANTE, não
-- por clínica. Quem lê uma mensagem é quem a escreveu ou quem a recebeu, e
-- mais ninguém da mesma clínica. Mensagem carrega nome de paciente; vazamento
-- entre pessoas da mesma clínica é tão grave quanto entre clínicas.
--
-- Ninguém edita nem apaga (FR-009). A única escrita depois do INSERT é
-- read_at, pelo destinatário, e um trigger BEFORE UPDATE tranca o resto,
-- porque policy não enxerga OLD.
--
-- COMO RODAR: um bloco por vez, com o export do banco feito antes. Reversão de
-- cada bloco em comentário logo abaixo dele.
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- BLOCO 1 · a tabela  ·  T207
-- ---------------------------------------------------------------------------
-- ref_id SEM chave estrangeira, de propósito: a mensagem sobrevive ao item
-- (cancelar a tarefa não apaga a conversa sobre ela). Mesmo motivo do FR-005
-- da regra 017. O cartão da tela diz "item não encontrado" quando sumiu.

CREATE TABLE IF NOT EXISTS public.internal_messages (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id    uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  sender_id    uuid NOT NULL DEFAULT auth.uid(),
  recipient_id uuid NOT NULL,
  body         text NOT NULL CHECK (btrim(body) <> ''),
  ref_type     text CHECK (ref_type IN ('task', 'appointment', 'lead', 'patient')),
  ref_id       uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  read_at      timestamptz,
  CONSTRAINT internal_messages_ref_par CHECK ((ref_type IS NULL) = (ref_id IS NULL)),
  CONSTRAINT internal_messages_nao_para_si CHECK (sender_id <> recipient_id)
);

COMMENT ON TABLE public.internal_messages IS
  'Mensagem interna entre dois membros da mesma clinica (regra 023, secao 8). Ninguem edita nem apaga; so read_at muda, pelo destinatario.';
COMMENT ON COLUMN public.internal_messages.ref_id IS
  'Item anexado (tarefa, consulta, lead ou paciente), SEM chave estrangeira de proposito: a mensagem sobrevive ao item.';
COMMENT ON COLUMN public.internal_messages.read_at IS
  'Gravado quando o DESTINATARIO abre a conversa (FR-010). E o que alimenta o balao e o sino.';

-- REVERSÃO DO BLOCO 1 (só se a tabela estiver vazia; senão, desligar as
--   policies do bloco 3 e parar a tela, porque mensagem não se apaga):
--   DROP TABLE IF EXISTS public.internal_messages;


-- ---------------------------------------------------------------------------
-- BLOCO 2 · os índices  ·  T208
-- ---------------------------------------------------------------------------
-- O primeiro é a contagem de não lidas (balão e sino); o segundo, a conversa.

CREATE INDEX IF NOT EXISTS internal_messages_nao_lidas_idx
  ON public.internal_messages (clinic_id, recipient_id, read_at);

CREATE INDEX IF NOT EXISTS internal_messages_conversa_idx
  ON public.internal_messages (clinic_id, sender_id, recipient_id, created_at);

-- REVERSÃO DO BLOCO 2:
--   DROP INDEX IF EXISTS public.internal_messages_nao_lidas_idx;
--   DROP INDEX IF EXISTS public.internal_messages_conversa_idx;


-- ---------------------------------------------------------------------------
-- BLOCO 3 · RLS e as três policies, sem DELETE  ·  T209, T210, T211
-- ---------------------------------------------------------------------------

ALTER TABLE public.internal_messages ENABLE ROW LEVEL SECURITY;

-- SELECT: participante, na própria clínica. Terceiro da mesma clínica não lê.
CREATE POLICY "internal_messages_select_participante"
  ON public.internal_messages FOR SELECT TO authenticated
  USING (
    clinic_id = public.get_my_clinic_id()
    AND (sender_id = auth.uid() OR recipient_id = auth.uid())
  );

-- INSERT: em nome próprio, na própria clínica, para membro ATIVO, COM LOGIN,
-- da MESMA clínica. É esta linha que impede mensagem para quem não lê (FR-007)
-- e mensagem assinada por outro (FR-014). A lista da tela é conveniência.
CREATE POLICY "internal_messages_insert_para_membro_com_login"
  ON public.internal_messages FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND clinic_id = public.get_my_clinic_id()
    AND EXISTS (
      SELECT 1 FROM public.team_members tm
      WHERE tm.clinic_id = public.get_my_clinic_id()
        AND tm.user_id = recipient_id
        AND tm.active = true
    )
  );

-- UPDATE: só o destinatário, e o trigger do bloco 4 garante que só read_at
-- muda. Sem policy de DELETE: default deny, alínea (b), e FR-009.
CREATE POLICY "internal_messages_update_so_destinatario"
  ON public.internal_messages FOR UPDATE TO authenticated
  USING (clinic_id = public.get_my_clinic_id() AND recipient_id = auth.uid())
  WITH CHECK (clinic_id = public.get_my_clinic_id() AND recipient_id = auth.uid());

-- REVERSÃO DO BLOCO 3:
--   DROP POLICY IF EXISTS "internal_messages_select_participante" ON public.internal_messages;
--   DROP POLICY IF EXISTS "internal_messages_insert_para_membro_com_login" ON public.internal_messages;
--   DROP POLICY IF EXISTS "internal_messages_update_so_destinatario" ON public.internal_messages;
--   (RLS ligado sem policy = ninguém lê nem escreve, que é a reversão segura)


-- ---------------------------------------------------------------------------
-- BLOCO 4 · o trigger que tranca tudo menos read_at  ·  T212
-- ---------------------------------------------------------------------------
-- Policy de UPDATE compara a linha nova com a regra, mas não enxerga a linha
-- antiga. Só o trigger vê OLD e NEW. Lida não volta a não lida.

CREATE OR REPLACE FUNCTION public.internal_messages_so_read_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.id           IS DISTINCT FROM OLD.id
  OR NEW.clinic_id    IS DISTINCT FROM OLD.clinic_id
  OR NEW.sender_id    IS DISTINCT FROM OLD.sender_id
  OR NEW.recipient_id IS DISTINCT FROM OLD.recipient_id
  OR NEW.body         IS DISTINCT FROM OLD.body
  OR NEW.ref_type     IS DISTINCT FROM OLD.ref_type
  OR NEW.ref_id       IS DISTINCT FROM OLD.ref_id
  OR NEW.created_at   IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'mensagem interna nao se edita: so read_at muda (regra 023, FR-009)'
      USING ERRCODE = 'check_violation';
  END IF;
  IF OLD.read_at IS NOT NULL AND NEW.read_at IS DISTINCT FROM OLD.read_at THEN
    RAISE EXCEPTION 'mensagem lida nao volta a nao lida (regra 023, FR-010)'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.internal_messages_so_read_at() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS internal_messages_so_read_at ON public.internal_messages;
CREATE TRIGGER internal_messages_so_read_at
  BEFORE UPDATE ON public.internal_messages
  FOR EACH ROW EXECUTE FUNCTION public.internal_messages_so_read_at();

-- REVERSÃO DO BLOCO 4:
--   DROP TRIGGER IF EXISTS internal_messages_so_read_at ON public.internal_messages;
--   DROP FUNCTION IF EXISTS public.internal_messages_so_read_at();
