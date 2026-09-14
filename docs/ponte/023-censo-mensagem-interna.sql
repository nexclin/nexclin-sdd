-- =============================================================================
-- 023 · CENSO DA MENSAGEM INTERNA · Fase 0 da frente 023
-- =============================================================================
-- Issues: T201 a T205 (nexclin#4 a #8). Rodado em 14/09/2026, uma consulta por
--   vez, no editor de SQL da Lovable. Resultado em
--   docs/historico/2026-09-14-censo-operacional.md, secoes 4 e 5.
-- NADA AQUI ESCREVE.
-- =============================================================================

-- BLOCO 1 · task_comments esta no ar, com as duas policies do bloco b1?  ·  T201
-- RESULTADO 14/09: sim. SELECT por clinica e INSERT com author_id = auth.uid().
select tablename, policyname, cmd, roles::text, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'task_comments'
order by policyname;

-- BLOCO 2 · a publicacao supabase_realtime existe, e com quais tabelas?  ·  T202
-- RESULTADO 14/09: existe, puballtables = false, nenhuma tabela. T241 e ALTER.
select
  p.pubname,
  p.puballtables::text as todas,
  coalesce((select string_agg(pt.tablename, ', ' order by pt.tablename)
            from pg_publication_tables pt where pt.pubname = p.pubname), '(nenhuma)') as tabelas
from pg_publication p
order by p.pubname;

-- BLOCO 3 · team_members com login e sem user_id  ·  T203
-- NAO RODADO AQUI: e o bloco 1 de docs/ponte/024-censo-operacional.sql, rodado
--   no mesmo dia. A premissa da secao 8.4 da regra 023 e a premissa 1 da 024.
