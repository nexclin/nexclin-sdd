-- =============================================================================
-- MODELOS DE MENSAGEM EDITAVEIS, em business_rules
-- =============================================================================
-- Pedido do Vinicius em 07/09/2026: "tudo que e mensagem pronta, que ja fica
--   como padrao, eu colocaria la na parte de configuracoes. (...) eu nao sei
--   onde e que fica esse padrao pra eu editar o padrao direto."
--
-- POR QUE EM `business_rules` E NAO NUMA TABELA NOVA: a mensagem de recall e
--   configuracao da clinica, exatamente como `recall_days`, que ja mora ali. E
--   uma linha por clinica, com RLS ja resolvida e dialogo de edicao ja pronto.
--   Tabela nova de modelos so se paga quando houver muitos modelos com dono e
--   historico proprios, e nao ha: hoje sao dois.
--
-- COLUNA NOVA NAO QUEBRA TELA: quem nao tiver o valor cai no modelo do codigo,
--   que continua sendo a fonte do padrao de fabrica.
--
-- SO CRIA COLUNA. Nao escreve em linha nenhuma.
-- =============================================================================

ALTER TABLE public.business_rules
  ADD COLUMN IF NOT EXISTS recall_message      text,
  ADD COLUMN IF NOT EXISTS recall_message_new  text;

COMMENT ON COLUMN public.business_rules.recall_message IS
  'Modelo da mensagem de recall para quem ja veio. Campos: {nome}, {tempo}. Nulo usa o padrao do codigo.';
COMMENT ON COLUMN public.business_rules.recall_message_new IS
  'Modelo da mensagem para quem nunca veio. Campo: {nome}. Nulo usa o padrao do codigo.';

-- CONFERENCIA, com controle negativo embutido: `coluna_inventada` tem de vir 0,
--   senao a consulta esta contando qualquer coisa e o 2 acima nao significa
--   nada.
select
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='business_rules'
      and column_name in ('recall_message','recall_message_new'))    as colunas_novas,
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='business_rules'
      and column_name = 'coluna_inventada')                          as controle_negativo;
