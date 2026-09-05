-- =============================================================================
-- 021 · CENSO DO FINANCEIRO · Fase 0 da frente 021
-- =============================================================================
-- Issues: T001 (#55), T002 (#56), T003 (#57)
-- Regra:  docs/regras/021-financeiro-que-nao-erra-o-caixa.md
--
-- COMO RODAR: no editor de SQL da plataforma, UM BLOCO POR VEZ.
--   Clique no Run POR REFERENCIA, nunca por coordenada: o botao muda de altura
--   conforme o painel do chat rola. Escape fecha o painel inteiro.
--
-- POR QUE AQUI E NAO PELA API: o RLS esconde as outras clinicas, e a contagem
--   sai errada SEM ERRO NENHUM. Um alarme falso de "21 de 22 clinicas sem tipo
--   de consulta" quase saiu por causa disso.
--
-- NADA AQUI ESCREVE. Todos os blocos sao leitura, e o BLOCO 3 roda dentro de
--   BEGIN/ROLLBACK.
-- =============================================================================


-- =============================================================================
-- BLOCO 1 · As colunas que a regra afirma que existem  ·  T001 (#55)
-- =============================================================================
-- ESPERADO, segundo a secao 3 da regra 021:
--   receivables: tem bank_account_id, acquirer_id, conciliated, conciliated_at,
--                payment_method_id, gross_value, net_value, fee_percent.
--                paid_at e DATE. NAO tem valor recebido nem autor da baixa.
--   expenses:    tem bank_account_id. payment_method e TEXT, nao FK.
--   bank_accounts: NAO TEM COLUNA DE SALDO NENHUMA.
--
-- Se divergir, a divergencia e o achado, e a secao 3 se corrige no mesmo commit.

select
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('receivables', 'expenses', 'bank_accounts', 'revenues')
order by table_name, ordinal_position;


-- -----------------------------------------------------------------------------
-- BLOCO 1b · A pergunta direta: existe coluna de saldo em bank_accounts?
-- -----------------------------------------------------------------------------
-- ESPERADO: zero linhas. E o que torna o FR-004 faixa A em vez de faixa B.
-- ATENCAO A VACUIDADE: o bloco confirma antes que a TABELA existe, senao
--   "zero colunas de saldo" seria trivialmente verdadeiro com a tabela ausente.

select
  (select count(*) from information_schema.tables
    where table_schema='public' and table_name='bank_accounts')  as a_tabela_existe,
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='bank_accounts'
      and column_name ~* 'saldo|balance')                        as colunas_de_saldo;


-- -----------------------------------------------------------------------------
-- BLOCO 1c · A conciliacao tem contraparte?
-- -----------------------------------------------------------------------------
-- ESPERADO: conciliated e conciliated_at existem, e NAO existe tabela de
--   extrato nem de vinculo. E o que sustenta o FR-007: hoje conciliar e marcar
--   uma caixinha, o que responde "alguem disse que conferiu" e nao "bate com o
--   banco".

select
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='receivables'
      and column_name in ('conciliated','conciliated_at'))       as marcas_de_conciliacao,
  (select count(*) from information_schema.tables
    where table_schema='public'
      and table_name ~* 'extrato|statement|conciliac|reconcil|transfer') as tabelas_de_contraparte;


-- =============================================================================
-- BLOCO 2 · As policies das quatro tabelas financeiras  ·  T001 (#55)
-- =============================================================================
-- ESPERADO: quatro policies FOR ALL (cmd = 'ALL'), filtrando so por clinic_id,
--   e NENHUMA citando my_permission. E a alinea (c) da constituicao ao
--   contrario: o que nega o modulo hoje e o menu.

select
  tablename,
  policyname,
  cmd,
  roles,
  (qual   ilike '%my_permission%') as usa_my_permission_no_using,
  (with_check ilike '%my_permission%') as usa_my_permission_no_check,
  qual   as clausula_using,
  with_check as clausula_check
from pg_policies
where schemaname = 'public'
  and tablename in ('receivables','expenses','revenues','fixed_expenses')
order by tablename, policyname;


-- -----------------------------------------------------------------------------
-- BLOCO 2b · O resumo em uma linha, para colar no registro
-- -----------------------------------------------------------------------------
select
  count(*)                                                        as policies_no_financeiro,
  count(*) filter (where cmd = 'ALL')                             as policies_for_all,
  count(*) filter (where qual ilike '%my_permission%'
                      or with_check ilike '%my_permission%')      as policies_com_cascata,
  count(*) filter (where qual ilike '%true%' and qual not ilike '%clinic%') as suspeitas_de_using_true
from pg_policies
where schemaname='public'
  and tablename in ('receivables','expenses','revenues','fixed_expenses');


-- =============================================================================
-- BLOCO 3 · PROVA 3 · revenues contra receivables, e as 28 linhas  ·  T002 (#56)
-- =============================================================================
-- A HIPOTESE, e ela e hipotese e nao fato: revenues e receivables guardam os
--   mesmos campos desde que o receivables os absorveu em 22/03, e as duas
--   continuam de pe. Pode explicar as 28 linhas entre 252 na tela de Vendas e
--   280 na base.
--
-- ESTE NUMERO ABRE O PORTAO 1, que decide o destino de revenues.
--
-- Referencia da Clinica Teste Final: 280 recebiveis, 70 despesas.

with alvo as (
  select 'd51ce6c7-582b-469b-a01b-608bd9b38885'::uuid as clinic_id
)
select
  (select count(*) from receivables r, alvo a where r.clinic_id = a.clinic_id) as receivables_total,
  (select count(*) from revenues   v, alvo a where v.clinic_id = a.clinic_id) as revenues_total,
  280                                                                          as referencia_esperada,
  (select count(*) from receivables r, alvo a where r.clinic_id = a.clinic_id) - 280 as diferenca_contra_referencia;


-- -----------------------------------------------------------------------------
-- BLOCO 3b · A diferenca por ano de vencimento
-- -----------------------------------------------------------------------------
-- O handoff de 30/08 registrou que as 28 linhas tem vencimento em 2026 e que o
--   filtro de data NAO justifica. Este bloco confirma ou derruba isso.

select
  extract(year from due_date)::int as ano_vencimento,
  count(*)                          as quantidade,
  sum(value)                        as soma_valor
from receivables
where clinic_id = 'd51ce6c7-582b-469b-a01b-608bd9b38885'
group by 1
order by 1;


-- -----------------------------------------------------------------------------
-- BLOCO 3c · revenues tem linha que receivables nao tem?
-- -----------------------------------------------------------------------------
-- Se revenues estiver vazia, a hipotese das 28 linhas CAI, e isso tambem e
--   resultado: registre que caiu, em vez de deixar a suspeita solta.

select
  count(*)                                             as revenues_da_clinica,
  count(*) filter (where patient_id is not null)       as com_paciente,
  min(revenue_date)                                    as primeira,
  max(revenue_date)                                    as ultima
from revenues
where clinic_id = 'd51ce6c7-582b-469b-a01b-608bd9b38885';


-- =============================================================================
-- BLOCO 4 · PROVA 2 · o buraco de permissao, com controle positivo  ·  T003 (#57)
-- =============================================================================
-- ATENCAO, TRES ARMADILHAS JA PAGAS COM TEMPO:
--
--  1. TABELA TEMPORARIA NAO SERVE aqui. Ela nasce do superusuario, e a parte
--     que interessa roda como `authenticated`: o teste morre com 42501 ANTES de
--     exercitar o que ha para exercitar. Por isso o resultado vai em
--     set_config, com prefixo proprio, que nao exige permissao de ninguem.
--
--  2. ASSERCAO NEGATIVA PASSA POR VACUIDADE. "O usuario negado nao consegue"
--     fica verdadeiro se o teste estiver errado. Por isso existe o CONTROLE
--     POSITIVO no fim: um usuario com o modulo liberado TEM de voltar linha.
--     Sem as duas metades, este bloco nao prova nada.
--
--  3. Tudo dentro de BEGIN/ROLLBACK. Nada e escrito.
--
-- ANTES DE RODAR, preencha os dois user_id abaixo:
--   NEGADO   = usuario da clinica COM o modulo contas_receber negado
--   LIBERADO = usuario da mesma clinica COM o modulo liberado
--
-- Para achar candidatos, rode antes o BLOCO 4a.

-- -----------------------------------------------------------------------------
-- BLOCO 4a · Achar os dois usuarios de teste
-- -----------------------------------------------------------------------------
select
  p.user_id,
  p.full_name,
  p.clinic_id,
  tm.permission_level,
  tm.permissions -> 'contas_receber' as permissao_contas_receber,
  tm.active
from profiles p
left join team_members tm on tm.user_id = p.user_id
where p.clinic_id = 'd51ce6c7-582b-469b-a01b-608bd9b38885'
order by tm.permission_level nulls last, p.full_name;


-- -----------------------------------------------------------------------------
-- BLOCO 4b · O teste, com as duas metades
-- -----------------------------------------------------------------------------
BEGIN;

-- ---- metade 1: o usuario com o modulo NEGADO ----
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" = '{"sub":"COLE_AQUI_O_USER_ID_NEGADO","role":"authenticated"}';

select set_config(
  'nx021.negado_ve_linhas',
  (select count(*)::text from receivables),
  true
);
select set_config(
  'nx021.negado_permissao',
  coalesce(my_permission('contas_receber'), 'nulo'),
  true
);

-- ---- metade 2: o CONTROLE POSITIVO, usuario com o modulo LIBERADO ----
SET LOCAL "request.jwt.claims" = '{"sub":"COLE_AQUI_O_USER_ID_LIBERADO","role":"authenticated"}';

select set_config(
  'nx021.liberado_ve_linhas',
  (select count(*)::text from receivables),
  true
);
select set_config(
  'nx021.liberado_permissao',
  coalesce(my_permission('contas_receber'), 'nulo'),
  true
);

-- ---- o veredito ----
RESET ROLE;
select
  current_setting('nx021.negado_permissao',   true) as permissao_do_negado,
  current_setting('nx021.negado_ve_linhas',   true) as linhas_que_o_negado_ve,
  current_setting('nx021.liberado_permissao', true) as permissao_do_liberado,
  current_setting('nx021.liberado_ve_linhas', true) as linhas_que_o_liberado_ve,
  case
    when current_setting('nx021.liberado_ve_linhas', true)::int = 0
      then 'TESTE INVALIDO: o controle positivo voltou zero. Confira o user_id LIBERADO antes de concluir qualquer coisa'
    when current_setting('nx021.negado_ve_linhas', true)::int > 0
      then 'DEFEITO CONFIRMADO: usuario com o modulo negado le o financeiro. E o FR-011'
    else 'SEM DEFEITO: a policy ja consulta a cascata. Corrija a secao 3 da regra'
  end as veredito;

ROLLBACK;


-- =============================================================================
-- REGISTRAR O RESULTADO  ·  T005 (#59)
-- =============================================================================
-- Copiar as saidas para docs/historico/2026-09-NN-censo-financeiro.md,
-- INCLUSIVE o que nao deu para conferir. Item sem prova fecha como
-- "codigo lido, nao comportamento provado" e continua aberto. Sem arredondar.
-- =============================================================================
