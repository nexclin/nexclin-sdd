-- =============================================================================
-- MENSAGENS DA REGUA DE COBRANCA, editaveis
-- =============================================================================
-- Continuacao do pedido do Vinicius, autorizada pelo Arthur em 08/09/2026:
--   "pode dar lugar de edicao tambem pras mensagens da regua de cobranca".
--
-- UMA COLUNA `jsonb`, E NAO CINCO COLUNAS `text`. As faixas tem id proprio
--   (`a_vencer`, `vence_hoje`, `atraso_leve`, `atraso_medio`, `atraso_grave`),
--   e guardar por chave faz faixa nova nao exigir migracao nova. Cinco colunas
--   exigiriam, e a propria regua ja avisa no codigo que tornar as faixas
--   configuraveis e o passo seguinte.
--
-- Chave ausente cai no modelo de fabrica, igual ao recall. Nao existe estado
--   "mensagem em branco enviada ao paciente".
--
-- SO CRIA COLUNA.
-- =============================================================================

ALTER TABLE public.business_rules
  ADD COLUMN IF NOT EXISTS cobranca_messages jsonb;

COMMENT ON COLUMN public.business_rules.cobranca_messages IS
  'Modelos da regua por id de faixa. Campos: {paciente}, {valor}, {vencimento}, {dias}. Chave ausente usa o padrao do codigo.';

select
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='business_rules'
      and column_name='cobranca_messages')   as coluna_nova,
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='business_rules'
      and column_name='coluna_inventada')    as controle_negativo;
