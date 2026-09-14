-- ===========================================================================
-- 023 FASE 1, BLOCO 5 — CONFERENCIA. Rodar DEPOIS do b5, no mesmo editor.
-- ===========================================================================
-- Le como um teste: OK ou FALTA. As linhas NAO_EXISTE sao o controle
-- positivo: tem de vir FALTA, senao a consulta esta quebrada.

-- 1. tabela, colunas, indices, RLS
with esperado(o_que, nome) as (
  values
    ('coluna',  'sender_id'), ('coluna', 'recipient_id'), ('coluna', 'body'),
    ('coluna',  'ref_type'),  ('coluna', 'ref_id'),       ('coluna', 'read_at'),
    ('indice',  'internal_messages_nao_lidas_idx'),
    ('indice',  'internal_messages_conversa_idx'),
    ('trigger', 'internal_messages_so_read_at'),
    ('coluna',  'ESTA_COLUNA_NAO_EXISTE')
)
select e.o_que, e.nome,
  case
    when e.o_que = 'coluna'  and exists (select 1 from information_schema.columns where table_schema='public' and table_name='internal_messages' and column_name = e.nome) then 'OK'
    when e.o_que = 'indice'  and exists (select 1 from pg_indexes where schemaname='public' and tablename='internal_messages' and indexname = e.nome) then 'OK'
    when e.o_que = 'trigger' and exists (select 1 from pg_trigger t join pg_class c on c.oid=t.tgrelid where c.relname='internal_messages' and t.tgname = e.nome) then 'OK'
    else 'FALTA'
  end as estado
from esperado e
union all
select 'rls', 'ligado', case when (select relrowsecurity from pg_class where relname='internal_messages') then 'OK' else 'FALTA' end
order by 1, 2;

-- 2. policies: tres, e nenhuma DELETE
select policyname, cmd,
  case when cmd in ('SELECT','INSERT','UPDATE') then 'OK' else 'INESPERADA' end as estado
from pg_policies where schemaname='public' and tablename='internal_messages'
union all
select 'tem policy de DELETE?', 'DELETE',
  case when exists (select 1 from pg_policies where schemaname='public' and tablename='internal_messages' and cmd='DELETE') then 'FALHA: existe' else 'OK: nenhuma' end
order by 2, 1;
