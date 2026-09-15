-- ===========================================================================
-- 024 FASE 1, BLOCO 1 — CONFERENCIA. Rodar DEPOIS do b1, no mesmo editor.
-- ===========================================================================
-- T319 (nexclin#68). Le como um teste: cada linha diz OK ou FALTA. Se qualquer
-- linha vier FALTA, o bloco nao aplicou inteiro e a reversao esta em
-- b1-reversao.sql.
--
-- CONTROLE POSITIVO na ultima linha de cada consulta: procura algo que NAO
-- deve existir. Se vier "OK", a consulta esta quebrada e o resto nao vale.

-- 1. As tres colunas novas e a jsonb
with esperado(tabela, coluna, tipo) as (
  values
    ('tasks',          'responsible_member_id', 'uuid'),
    ('appointments',   'responsible_member_id', 'uuid'),
    ('appointments',   'doctor_member_id',      'uuid'),
    ('business_rules', 'task_type_weights',     'jsonb'),
    ('tasks',          'ESTA_COLUNA_NAO_EXISTE', 'uuid')
)
select
  e.tabela, e.coluna,
  case when c.column_name is not null and c.data_type = e.tipo then 'OK' else 'FALTA' end as estado
from esperado e
left join information_schema.columns c
  on c.table_schema = 'public' and c.table_name = e.tabela and c.column_name = e.coluna
order by e.tabela, e.coluna;

-- 2. Os dois triggers de auditoria (mais o de patients, que ja existia)
with esperado(tabela, trigger) as (
  values
    ('tasks',        'tasks_audita_mudanca'),
    ('appointments', 'appointments_audita_mudanca'),
    ('patients',     'patients_audita_mudanca'),
    ('tasks',        'ESTE_TRIGGER_NAO_EXISTE')
)
select
  e.tabela, e.trigger,
  case when t.tgname is not null then 'OK' else 'FALTA' end as estado
from esperado e
left join pg_class c on c.relname = e.tabela
left join pg_trigger t on t.tgrelid = c.oid and t.tgname = e.trigger and not t.tgisinternal
order by e.tabela, e.trigger;

-- 3. As policies de tasks: tres novas, nenhuma DELETE, e a antiga fora
select
  policyname, cmd,
  case
    when policyname like 'tasks_%_na_propria_clinica' and cmd in ('SELECT','INSERT','UPDATE') then 'OK'
    else 'INESPERADA'
  end as estado
from pg_policies
where schemaname = 'public' and tablename = 'tasks'
union all
select 'tem policy de DELETE?', 'DELETE',
  case when exists (select 1 from pg_policies where schemaname='public' and tablename='tasks' and cmd='DELETE')
       then 'FALHA: existe' else 'OK: nenhuma' end
union all
select 'a FOR ALL de 22/03 sumiu?', 'ALL',
  case when exists (select 1 from pg_policies where schemaname='public' and tablename='tasks' and cmd='ALL')
       then 'FALHA: ainda existe' else 'OK: sumiu' end
order by 2, 1;
