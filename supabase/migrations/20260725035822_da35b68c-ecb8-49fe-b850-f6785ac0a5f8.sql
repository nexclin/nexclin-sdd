
INSERT INTO public.plans (name, status, visibility, max_users, max_patients, max_leads_month, trial_days, monthly_price, annual_price, support_level, enabled_modules)
VALUES (
  'Teste CP Bloqueado', 'active', 'private', 1, 0, 0, 0, 0, 0, 'email',
  jsonb_build_object(
    'dashboard', true, 'leads', true, 'pacientes', true, 'anamnese', true,
    'consultas', true, 'acompanhamento', true, 'tarefas', true,
    'contas_receber', true, 'contas_pagar', false, 'fluxo_caixa', true,
    'relatorios_vendas', true, 'relatorios_demais', true,
    'configuracoes', true, 'equipe', true, 'insights', true
  )
);

UPDATE public.account_subscriptions
SET plan_id = (SELECT id FROM public.plans WHERE name = 'Teste CP Bloqueado'),
    status = 'active'
WHERE clinic_id = '722cafb8-32b3-45f7-8033-b281038c0ee0';
