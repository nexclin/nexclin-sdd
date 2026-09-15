-- 024 FASE 1, BLOCO 2 — CONFERÊNCIA. Rodar depois de b2-business-rules-e-assumidas.sql.

-- 1. Esperado: três linhas, SELECT, INSERT e UPDATE, e nenhuma "Users can manage".
select policyname, cmd from pg_policies
 where schemaname = 'public' and tablename = 'business_rules' order by cmd;

-- 2. Esperado: uma linha, prosecdef = true (SECURITY DEFINER).
select p.proname, p.prosecdef
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'tarefas_assumidas_por_membro';

-- 3. Esperado: authenticated com EXECUTE; anon e PUBLIC sem.
select grantee, privilege_type from information_schema.routine_privileges
 where specific_schema = 'public' and routine_name = 'tarefas_assumidas_por_membro';
