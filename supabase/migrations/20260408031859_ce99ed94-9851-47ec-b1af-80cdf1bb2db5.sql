
-- 1. Dependent data tables
DELETE FROM public.receivables;
DELETE FROM public.expenses;
DELETE FROM public.appointment_items;
DELETE FROM public.appointments;
DELETE FROM public.lead_history;
DELETE FROM public.leads;
DELETE FROM public.tasks;
DELETE FROM public.closings;
DELETE FROM public.prescriptions;
DELETE FROM public.funnel_2_entries;
DELETE FROM public.revenues;
DELETE FROM public.anamnesis_responses;
DELETE FROM public.anamnesis_config;
DELETE FROM public.patients;
DELETE FROM public.services;
DELETE FROM public.consultation_types;
DELETE FROM public.closing_types;
DELETE FROM public.team_members;
DELETE FROM public.payment_methods;
DELETE FROM public.acquirers;
DELETE FROM public.bank_accounts;
DELETE FROM public.channels;
DELETE FROM public.origins;
DELETE FROM public.objections;
DELETE FROM public.goals;
DELETE FROM public.expense_categories;
DELETE FROM public.fixed_expenses;
DELETE FROM public.chart_of_accounts;
DELETE FROM public.business_rules;
DELETE FROM public.ai_insights;

-- 2. Profiles and roles
DELETE FROM public.user_roles;
DELETE FROM public.profiles;

-- 3. Clinics
DELETE FROM public.clinics;

-- 4. Auth users
DELETE FROM auth.users;
