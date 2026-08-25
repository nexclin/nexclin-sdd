-- SPEC 004 / FR-001, FR-002 e FR-003 — o default de `plans.enabled_modules`.
--
-- # O defeito
--
-- A coluna nasceu assim, em `20260408034446`:
--
--     enabled_modules jsonb NOT NULL DEFAULT '[]'::jsonb
--
-- E o trigger que a valida, criado depois em `20260725033102`, roda
-- `BEFORE INSERT OR UPDATE` e recusa qualquer coisa que não seja objeto:
--
--     IF jsonb_typeof(NEW.enabled_modules) <> 'object' THEN
--       RAISE EXCEPTION 'enabled_modules deve ser um objeto JSON';
--     END IF;
--
-- `'[]'` é array. O default da coluna é um valor que a própria tabela recusa.
--
-- **Consequência reproduzível:** todo `INSERT` em `plans` que não informe
-- `enabled_modules` explicitamente falha, com a mensagem acima. Hoje ninguém
-- esbarra porque os planos existentes vieram de migração, que informa o objeto
-- na mão. Esbarra no dia em que um plano for criado pela tela do superadmin.
--
-- # O que esta migração NÃO faz
--
-- Não decide o formato. **O formato já estava decidido pelo trigger**, desde
-- julho: é objeto. O `specs/BACKLOG.md` tratava isso como pergunta em aberto
-- ("padronizar `enabled_modules` como Record<ModuleKey, boolean>") por engano.
-- Aqui só se alinha o default ao que a tabela já exige.
--
-- Faixa A pela §2.5 do CLAUDE.md: é migração, atravessa intacta, e o banco da
-- Lovable migra junto. Corrigir uma vez resolve dos dois lados.

-- ---------------------------------------------------------------------------
-- 1. Normaliza o que já existe, antes de mexer no default
-- ---------------------------------------------------------------------------

-- A ordem importa: normalizar primeiro deixa a base consistente mesmo que a
-- alteração do default falhe por qualquer motivo.
--
-- `'{}'` e não uma tentativa de converter o array: um array de chaves ligadas
-- seria convertível, mas um array vazio não carrega informação nenhuma, e
-- adivinhar quais módulos o plano deveria liberar é pior que deixar explícito
-- que nenhum está. Plano com objeto vazio libera nada, que é o default seguro.
UPDATE public.plans
SET enabled_modules = '{}'::jsonb
WHERE jsonb_typeof(enabled_modules) <> 'object';

-- ---------------------------------------------------------------------------
-- 2. Alinha o default ao que o trigger exige
-- ---------------------------------------------------------------------------

ALTER TABLE public.plans
  ALTER COLUMN enabled_modules SET DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.plans.enabled_modules IS
  'Record<ModuleKey, boolean>. Objeto, nunca array: o trigger plans_validate_enabled_modules recusa qualquer outro tipo. Chave ausente vale como false, e o default {} libera nenhum modulo.';

-- ---------------------------------------------------------------------------
-- 3. Trava para que o defeito não volte
-- ---------------------------------------------------------------------------

-- O trigger valida INSERT e UPDATE, mas não impede que alguém volte a apontar o
-- default para um array numa migração futura. A constraint fecha isso no nível
-- da tabela: ela é verificada também contra o valor default, então um
-- `SET DEFAULT '[]'` passa a falhar na hora, e não meses depois, na primeira
-- tentativa de criar plano pela tela.
--
-- `NOT VALID` seria o caminho cauteloso se houvesse dúvida sobre as linhas
-- existentes. Não há: o UPDATE acima acabou de normalizá-las, então a
-- constraint entra validando.
ALTER TABLE public.plans
  DROP CONSTRAINT IF EXISTS plans_enabled_modules_e_objeto;

ALTER TABLE public.plans
  ADD CONSTRAINT plans_enabled_modules_e_objeto
  CHECK (enabled_modules IS NULL OR jsonb_typeof(enabled_modules) = 'object');

-- ---------------------------------------------------------------------------
-- Conferência, para rodar depois de aplicar
-- ---------------------------------------------------------------------------
--
--   SELECT
--     (SELECT column_default FROM information_schema.columns
--        WHERE table_name = 'plans' AND column_name = 'enabled_modules')  AS padrao,
--     (SELECT count(*) FROM public.plans
--        WHERE jsonb_typeof(enabled_modules) <> 'object')                 AS fora_do_formato;
--
-- Esperado: `padrao` contendo `'{}'::jsonb`, e `fora_do_formato = 0`.
--
-- E a prova de que o defeito sumiu, que vale mais que a conferência acima:
--
--   INSERT INTO public.plans (name, monthly_price) VALUES ('teste de default', 0);
--   -- antes desta migração: ERRO 'enabled_modules deve ser um objeto JSON'
--   -- depois: cria o plano com enabled_modules = {}
--   DELETE FROM public.plans WHERE name = 'teste de default';
