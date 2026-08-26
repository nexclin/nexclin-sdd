-- BLOCO 1. Inventário. Só lê. Não muda nada.
--
-- Rode antes de qualquer outro bloco e GUARDE O RESULTADO. Ele é a única foto
-- de "como estava" que sobrevive ao resto da sequência, e é com ele que se
-- confere, no fim, que só sumiu o que devia sumir.
--
-- Cole o bloco inteiro de uma vez. Ele devolve uma tabela só, ordenada da
-- maior para a menor.

SELECT 'clinics'                AS tabela, count(*) AS linhas FROM public.clinics
UNION ALL SELECT 'profiles',                count(*) FROM public.profiles
UNION ALL SELECT 'team_members',            count(*) FROM public.team_members
UNION ALL SELECT 'user_roles',              count(*) FROM public.user_roles
UNION ALL SELECT 'account_subscriptions',   count(*) FROM public.account_subscriptions
UNION ALL SELECT 'plans',                   count(*) FROM public.plans
-- movimento: é o que o Bloco 6 zera
UNION ALL SELECT 'patients',                count(*) FROM public.patients
UNION ALL SELECT 'leads',                   count(*) FROM public.leads
UNION ALL SELECT 'lead_history',            count(*) FROM public.lead_history
UNION ALL SELECT 'funnel_2_entries',        count(*) FROM public.funnel_2_entries
UNION ALL SELECT 'appointments',            count(*) FROM public.appointments
UNION ALL SELECT 'appointment_items',       count(*) FROM public.appointment_items
UNION ALL SELECT 'budgets',                 count(*) FROM public.budgets
UNION ALL SELECT 'budget_items',            count(*) FROM public.budget_items
UNION ALL SELECT 'prescriptions',           count(*) FROM public.prescriptions
UNION ALL SELECT 'anamnesis_responses',     count(*) FROM public.anamnesis_responses
UNION ALL SELECT 'closings',                count(*) FROM public.closings
UNION ALL SELECT 'receivables',             count(*) FROM public.receivables
UNION ALL SELECT 'revenues',                count(*) FROM public.revenues
UNION ALL SELECT 'expenses',                count(*) FROM public.expenses
UNION ALL SELECT 'tasks',                   count(*) FROM public.tasks
UNION ALL SELECT 'ai_insights',             count(*) FROM public.ai_insights
-- catálogo: o Bloco 6 NÃO zera. O 6B zera, e ele é opcional.
UNION ALL SELECT 'services',                count(*) FROM public.services
UNION ALL SELECT 'consultation_types',      count(*) FROM public.consultation_types
UNION ALL SELECT 'closing_types',           count(*) FROM public.closing_types
UNION ALL SELECT 'chart_of_accounts',       count(*) FROM public.chart_of_accounts
UNION ALL SELECT 'expense_categories',      count(*) FROM public.expense_categories
UNION ALL SELECT 'fixed_expenses',          count(*) FROM public.fixed_expenses
UNION ALL SELECT 'bank_accounts',           count(*) FROM public.bank_accounts
UNION ALL SELECT 'payment_methods',         count(*) FROM public.payment_methods
UNION ALL SELECT 'acquirers',               count(*) FROM public.acquirers
UNION ALL SELECT 'channels',                count(*) FROM public.channels
UNION ALL SELECT 'origins',                 count(*) FROM public.origins
UNION ALL SELECT 'objections',              count(*) FROM public.objections
UNION ALL SELECT 'business_rules',          count(*) FROM public.business_rules
UNION ALL SELECT 'anamnesis_config',        count(*) FROM public.anamnesis_config
UNION ALL SELECT 'goals',                   count(*) FROM public.goals
ORDER BY linhas DESC;
