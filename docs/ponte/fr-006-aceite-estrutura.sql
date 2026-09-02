-- =====================================================================
-- FR-006 da regra 005: ACEITE, PARTE A (estrutura). SO LEITURA.
-- =====================================================================
--
-- A migracao `20260828030000_is_system_so_active_e_editavel.sql` foi escrita em
-- 28/08/2026 e, segundo o handoff, NUNCA rodou em banco nenhum. Pela regra (j)
-- ela e codigo lido e comportamento nao provado.
--
--   1. rode ISTO antes da migracao. Tem de ler FALHOU. Se ja ler OK, ela ja
--      foi aplicada em algum momento e o handoff esta errado: PARE e descubra.
--   2. aplique a migracao
--   3. rode ISTO de novo. Tem de ler OK.
--   4. rode `fr-006-aceite-comportamento.sql`, que e o que prova de verdade.
-- =====================================================================

SELECT 'A1  funcao protege_linha_de_sistema existe' AS verificacao,
       (SELECT count(*)::text FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public' AND p.proname = 'protege_linha_de_sistema') AS valor,
       '1' AS esperado
UNION ALL SELECT 'A2  a funcao e SECURITY DEFINER',
       coalesce((SELECT p.prosecdef::text FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public' AND p.proname = 'protege_linha_de_sistema'), 'AUSENTE'), 'true'
UNION ALL SELECT 'A3  search_path travado na funcao',
       coalesce((SELECT (p.proconfig IS NOT NULL)::text FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public' AND p.proname = 'protege_linha_de_sistema'), 'AUSENTE'), 'true'
UNION ALL SELECT 'A4  TRES gatilhos, um por tabela com is_system',
       (SELECT count(*)::text FROM pg_trigger
         WHERE NOT tgisinternal AND tgname LIKE '%protege_sistema'), '3'
UNION ALL SELECT 'A5  TRES policies de DELETE, e RESTRICTIVE',
       (SELECT count(*)::text FROM pg_policies
         WHERE schemaname = 'public' AND policyname = 'Linha de sistema nao se apaga'
           AND cmd = 'DELETE' AND permissive = 'RESTRICTIVE'), '3'
UNION ALL SELECT 'A6  authenticated NAO executa a funcao do gatilho',
       coalesce((SELECT has_function_privilege('authenticated', p.oid, 'EXECUTE')::text
         FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public' AND p.proname = 'protege_linha_de_sistema'), 'AUSENTE'), 'false'
UNION ALL SELECT 'ctx  existe linha is_system para o teste de comportamento',
       (SELECT count(*)::text FROM public.chart_of_accounts WHERE is_system), 'maior que zero';
