-- 023 FASE 3, BLOCO 6 — CONFERENCIA. Esperado: uma linha, internal_messages.
select pubname, tablename from pg_publication_tables where pubname = 'supabase_realtime' order by tablename;
