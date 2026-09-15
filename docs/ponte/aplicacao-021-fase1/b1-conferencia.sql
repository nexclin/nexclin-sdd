-- ===========================================================================
-- 021 FASE 1, BLOCO 1 — CONFERENCIA. Rodar DEPOIS do b1, no mesmo editor.
-- ===========================================================================
--
-- Le como um teste: cada linha diz OK ou FALTA, e nenhuma delas depende de
-- voce interpretar contagem. Se qualquer linha vier FALTA, o bloco nao
-- aplicou inteiro e a reversao esta em b1-reversao.sql.
--
-- CONTROLE POSITIVO na ultima linha: ela procura uma coluna que NAO deve
-- existir. Se ela vier "OK", a consulta esta quebrada e o resto do resultado
-- nao vale nada. E a armadilha do teste vazio, que ja mordeu este projeto:
-- afirmacao negativa passa quando o teste esta errado.

with esperado(tabela, coluna, tipo) as (
  values
    ('receivables', 'settled_value', 'numeric'),
    ('receivables', 'settled_by',    'uuid'),
    ('receivables', 'settled_at',    'timestamp with time zone'),
    ('expenses',    'settled_value', 'numeric'),
    ('expenses',    'settled_by',    'uuid'),
    ('expenses',    'settled_at',    'timestamp with time zone'),
    ('receivables', 'ESTA_COLUNA_NAO_EXISTE', 'numeric')
)
select
  e.tabela,
  e.coluna,
  case
    when e.coluna = 'ESTA_COLUNA_NAO_EXISTE' then
      case when c.column_name is null
           then 'CONTROLE POSITIVO OK, a consulta enxerga ausencia'
           else 'CONSULTA QUEBRADA, ignore o resto deste resultado' end
    when c.column_name is null then 'FALTA'
    when c.data_type <> e.tipo then 'TIPO ERRADO: ' || c.data_type
    else 'OK'
  end as veredito
from esperado e
left join information_schema.columns c
  on c.table_schema = 'public'
 and c.table_name   = e.tabela
 and c.column_name  = e.coluna
order by e.tabela, e.coluna;

-- As duas restricoes de valor nao negativo.
select conrelid::regclass as tabela, conname,
       case when convalidated then 'OK, valida' else 'NAO VALIDADA' end as veredito
from pg_constraint
where conname in ('receivables_settled_value_nao_negativo',
                  'expenses_settled_value_nao_negativo')
order by 1;

-- Nenhuma linha antiga pode ter sido tocada. As tres colunas nascem nulas em
-- TODAS as linhas, e este numero tem de ser igual ao total da tabela.
select 'receivables' as tabela,
       count(*) as linhas,
       count(*) filter (where settled_value is null
                          and settled_by is null
                          and settled_at is null) as intactas
from public.receivables
union all
select 'expenses', count(*),
       count(*) filter (where settled_value is null
                          and settled_by is null
                          and settled_at is null)
from public.expenses;
