-- TAR-1 · `tasks` não sabe quem criou nem se foi a automação.
--
-- # O que isto destrava
--
-- Da bateria de 25/08: *"Ações criadas automaticamente não seriam editáveis,
-- mas podem ser clicadas e revistas para ler observações. Tarefas criadas
-- manualmente podem ser editadas pelo criador ou pelo usuário master."*
--
-- A regra tem duas metades, e só uma precisa de banco:
--
-- **Manual contra automática** já funciona sem migração. A aplicação deriva do
-- `type`, porque `tasks.type` é `TEXT` sem `CHECK` e os tipos que a automação
-- cria são conhecidos (`src/lib/tiposDeTarefa.ts`). A derivação é boa, e não é
-- perfeita: uma tarefa manual do tipo follow-up é indistinguível de uma
-- automática do mesmo tipo. **Ela erra para o lado de permitir editar**, que é
-- o lado certo — travar o usuário fora da própria tarefa é pior.
--
-- **"Pelo criador ou pelo master"** não tem como existir sem `created_by`. Não
-- há de onde tirar quem criou.
--
-- # Por que a coluna `origem` também entra
--
-- Ela torna a derivação desnecessária. A partir dela, tarefa nova carrega a
-- origem explícita, e a heurística vira só o tratamento do passado.
--
-- NÃO APLICADA POR ESTA SESSÃO. Aplicar exige colagem manual no SQL editor,
-- pelo motivo em `docs/seguranca/nota-sql-editor-lovable-2026-08-19.md`.

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS origem text NOT NULL DEFAULT 'manual'
    CHECK (origem IN ('manual', 'automatica'));

COMMENT ON COLUMN public.tasks.created_by IS
  'Quem criou a tarefa. NULL quando veio da automacao, que nao tem auth.uid().';
COMMENT ON COLUMN public.tasks.origem IS
  'manual | automatica. Decide se a tarefa e editavel pelo usuario.';

-- ---------------------------------------------------------------------------
-- O default é `manual`, e isso é deliberado
-- ---------------------------------------------------------------------------
--
-- Toda linha existente vira `manual`, ou seja, **editável**. A alternativa
-- seria marcar tudo como automática, o que travaria o usuário fora de tarefas
-- que ele mesmo criou antes desta coluna existir.
--
-- O reparo abaixo corrige o que dá para corrigir com certeza: os tipos que
-- **só** a automação produz.

UPDATE public.tasks
   SET origem = 'automatica'
 WHERE type IN (
   'confirmar_agendamento',
   'envio_anamnese',
   'recaptacao',
   'recaptacao_lead',
   'recaptacao_consulta',
   'recaptacao_orcamento',
   'recall',
   'pos_consulta'
 );

-- `recaptacao` sem sufixo está na lista de propósito: é o valor antigo, de
-- antes de os subtipos existirem, e toda tarefa com ele veio da automação.

CREATE INDEX IF NOT EXISTS tasks_clinic_origem_idx
  ON public.tasks (clinic_id, origem);

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
--
--   SELECT origem, count(*) FROM public.tasks GROUP BY origem;
--
-- Esperado: as duas linhas, com `automatica` cobrindo as tarefas de
-- confirmação, anamnese, recaptação, recall e pós-consulta.
--
--   SELECT type, count(*) FROM public.tasks GROUP BY type ORDER BY 2 DESC;
--
-- Esperado depois do Publish: `recaptacao_lead`, `recaptacao_consulta` e
-- `recaptacao_orcamento` começando a aparecer, e `recaptacao` parando de
-- crescer. É assim que se prova que os subtipos entraram em produção.
