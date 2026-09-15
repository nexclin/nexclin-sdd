-- ===========================================================================
-- 023 — task_comments, o comentario na tarefa (FR-005), como migracao
-- ===========================================================================
--
-- APLICADA EM 07/09/2026 POR BLOCO DE SQL (docs/ponte/aplicacao-023/b1), e
-- confirmada no banco ao vivo pelo censo de 14/09 (docs/historico/
-- 2026-09-14-censo-operacional.md, secao 4). Esta migracao existe para que a
-- stack nova a herde: ela nao estava em supabase/migrations de nenhum dos
-- dois repositorios. T213 (nexclin#16).
--
-- NAO RODAR DE NOVO NO BANCO AO VIVO. Se rodar, e inofensiva: tudo abaixo e
-- IF NOT EXISTS, e as policies sao recriadas iguais depois de um DROP IF
-- EXISTS. A data no nome e a da aplicacao real, para a ordem ficar certa.
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.task_comments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- A ancora multi-tenant, alinea (a). Sem ela nao ha RLS que preste.
  clinic_id  uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  task_id    uuid NOT NULL REFERENCES public.tasks(id)   ON DELETE CASCADE,
  -- Autor: quem escreveu. NAO e texto livre, e referencia, para nao repetir o
  --   defeito de `tasks.responsible`, que guarda setor e nao pessoa.
  author_id  uuid NOT NULL DEFAULT auth.uid(),
  body       text NOT NULL CHECK (btrim(body) <> ''),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS task_comments_task_idx
  ON public.task_comments (task_id, created_at);


ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read task comments in their clinic" ON public.task_comments;
CREATE POLICY "Users can read task comments in their clinic"
  ON public.task_comments FOR SELECT TO authenticated
  USING (clinic_id IN (SELECT p.clinic_id FROM public.profiles p WHERE p.user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can write their own task comments" ON public.task_comments;
CREATE POLICY "Users can write their own task comments"
  ON public.task_comments FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND clinic_id IN (SELECT p.clinic_id FROM public.profiles p WHERE p.user_id = auth.uid())
  );


COMMENT ON TABLE public.task_comments IS
  'Recado preso a tarefa (regra 023, FR-005). Aplicada por bloco em 07/09/2026; a migracao existe para a stack nova herdar.';
