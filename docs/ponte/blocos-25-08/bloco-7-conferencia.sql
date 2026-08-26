-- BLOCO 7. Conferência final. Só lê. Não muda nada.
--
-- Rode depois de todos os outros. Cada linha tem um valor esperado, e é ele
-- que diz se a sequência fechou. Qualquer coisa fora do esperado, pare e me
-- mande o resultado.

SELECT 'clinicas sem assinatura (esperado 0)' AS conferencia,
       (SELECT count(*) FROM public.clinics c
         WHERE NOT EXISTS (SELECT 1 FROM public.account_subscriptions s
                            WHERE s.clinic_id = c.id))::text AS valor

UNION ALL
SELECT 'planos fora do formato objeto (esperado 0)',
       (SELECT count(*) FROM public.plans
         WHERE jsonb_typeof(enabled_modules) <> 'object')::text

UNION ALL
SELECT 'tasks.created_by existe (esperado true)',
       EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = 'tasks'
                  AND column_name = 'created_by')::text

UNION ALL
SELECT 'tasks.origem existe (esperado true)',
       EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = 'tasks'
                  AND column_name = 'origem')::text

UNION ALL
SELECT 'patients.deleted_at existe (esperado true)',
       EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = 'patients'
                  AND column_name = 'deleted_at')::text

UNION ALL
SELECT 'data_audit_log existe (esperado true)',
       EXISTS (SELECT 1 FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name = 'data_audit_log')::text

UNION ALL
SELECT 'policies de escrita em data_audit_log (esperado 0)',
       (SELECT count(*) FROM pg_policies
         WHERE schemaname = 'public' AND tablename = 'data_audit_log'
           AND cmd <> 'SELECT')::text

UNION ALL
SELECT 'movimento restante (esperado 0)',
       ((SELECT count(*) FROM public.patients)
      + (SELECT count(*) FROM public.leads)
      + (SELECT count(*) FROM public.appointments)
      + (SELECT count(*) FROM public.receivables)
      + (SELECT count(*) FROM public.tasks))::text

UNION ALL
SELECT 'clinicas de pe (esperado: o mesmo do Bloco 1)',
       (SELECT count(*) FROM public.clinics)::text

UNION ALL
SELECT 'acessos de pe (esperado: o mesmo do Bloco 1)',
       (SELECT count(*) FROM public.team_members)::text;
