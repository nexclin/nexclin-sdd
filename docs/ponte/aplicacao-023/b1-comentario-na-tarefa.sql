-- =============================================================================
-- REGRA 023, BLOCO 1: comentario na tarefa
-- =============================================================================
-- Pedido do Arthur em 07/09/2026: "um campo onde eles possam trocar mensagens,
--   pra que o outro possa se justificar".
--
-- E o caminho SEM emenda a constituicao, e a regra 023 ja o preferia: o recado
--   preso a tarefa vive sob a ModuleKey `tarefas` e herda a permissao dela.
--   Caixa de mensagens solta exigiria ModuleKey nova, e a alinea (f) manda a
--   emenda vir ANTES do codigo.
--
-- COMO RODAR: um bloco so, no editor de SQL. ANTES, exporte o banco:
--   More > Cloud > Overview > Advanced settings > Export project data.
--   O tier atual nao tem recuperacao no tempo, e o export e a unica rede.
--
-- ESTE BLOCO NAO TOCA NENHUMA LINHA EXISTENTE. Ele so CRIA.
-- =============================================================================

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

-- DEFAULT DENY, alinea (b): o que nao esta concedido abaixo, esta negado.
--
-- A policy segue a MESMA FORMA das 79 que ja existem, por `clinic_id`, e NAO
--   chama `my_permission`. Isso e deliberado e esta registrado: nenhuma policy
--   do schema chama a cascata hoje, e fazer esta ser a unica diferente criaria
--   uma inconsistencia nova sem resolver o FR-011, que e geral. Quando a Etapa
--   1 do FR-011 rodar, esta entra junto com as outras.
DROP POLICY IF EXISTS "Users can read task comments in their clinic" ON public.task_comments;
CREATE POLICY "Users can read task comments in their clinic"
  ON public.task_comments FOR SELECT TO authenticated
  USING (clinic_id IN (SELECT p.clinic_id FROM public.profiles p WHERE p.user_id = auth.uid()));

-- ESCRITA SO EM NOME PROPRIO: o autor tem de ser quem esta logado. Sem esta
--   linha, um usuario poderia gravar recado assinado por outro, e recado que
--   nao prova autoria nao serve para cobrar ninguem.
DROP POLICY IF EXISTS "Users can write their own task comments" ON public.task_comments;
CREATE POLICY "Users can write their own task comments"
  ON public.task_comments FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND clinic_id IN (SELECT p.clinic_id FROM public.profiles p WHERE p.user_id = auth.uid())
  );

-- SEM UPDATE E SEM DELETE, de proposito. Recado apagado depois da cobranca e
--   pior do que recado nenhum: some justamente quando alguem quer conferir o
--   que foi combinado. Se um dia precisar de correcao, ela vem como recado
--   novo, e nao como reescrita do antigo.

-- =============================================================================
-- CONFERENCIA, para rodar DEPOIS. Controle positivo embutido.
-- =============================================================================
-- ESPERADO: existe=1, politicas=2, e o teste_negativo devolve 0 linhas, porque
--   a tabela nasce vazia. Se `existe` vier 0, o bloco de cima nao rodou.
--
-- select
--   (select count(*) from information_schema.tables
--     where table_schema='public' and table_name='task_comments') as existe,
--   (select count(*) from pg_policies
--     where schemaname='public' and tablename='task_comments')    as politicas,
--   (select count(*) from public.task_comments)                   as linhas;
