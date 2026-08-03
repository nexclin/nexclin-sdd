
ALTER TABLE public.plans
  ALTER COLUMN max_users DROP NOT NULL,
  ALTER COLUMN max_patients DROP NOT NULL,
  ALTER COLUMN max_leads_month DROP NOT NULL;

WITH inserted AS (
  INSERT INTO public.plans (
    name, description, is_default_trial, status, visibility,
    monthly_price, annual_price, trial_days,
    max_users, max_patients, max_leads_month, enabled_modules
  ) VALUES (
    'Trial Padrão',
    'Plano de avaliação com acesso completo',
    true, 'active', 'hidden',
    0, 0, 14,
    NULL, NULL, NULL,
    jsonb_build_object(
      'dashboard', true, 'leads', true, 'pacientes', true, 'anamnese', true,
      'consultas', true, 'acompanhamento', true, 'tarefas', true,
      'contas_receber', true, 'contas_pagar', true, 'fluxo_caixa', true,
      'relatorios_vendas', true, 'relatorios_demais', true,
      'configuracoes', true, 'equipe', true, 'insights', true
    )
  )
  RETURNING id
)
UPDATE public.saas_settings
SET trial_default_plan_id = (SELECT id FROM inserted), updated_at = now();

CREATE OR REPLACE FUNCTION public.validate_enabled_modules()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  allowed text[] := ARRAY[
    'dashboard','leads','pacientes','anamnese','consultas','acompanhamento',
    'tarefas','contas_receber','contas_pagar','fluxo_caixa',
    'relatorios_vendas','relatorios_demais','configuracoes','equipe','insights'
  ];
  k text;
BEGIN
  IF NEW.enabled_modules IS NULL THEN RETURN NEW; END IF;
  IF jsonb_typeof(NEW.enabled_modules) <> 'object' THEN
    RAISE EXCEPTION 'enabled_modules deve ser um objeto JSON';
  END IF;
  FOR k IN SELECT jsonb_object_keys(NEW.enabled_modules) LOOP
    IF NOT (k = ANY(allowed)) THEN
      RAISE EXCEPTION 'Chave inválida em enabled_modules: %', k;
    END IF;
    IF jsonb_typeof(NEW.enabled_modules->k) <> 'boolean' THEN
      RAISE EXCEPTION 'Valor de enabled_modules.% deve ser boolean', k;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS plans_validate_enabled_modules ON public.plans;
CREATE TRIGGER plans_validate_enabled_modules
BEFORE INSERT OR UPDATE ON public.plans
FOR EACH ROW EXECUTE FUNCTION public.validate_enabled_modules();

DO $$
DECLARE
  v_plan_id uuid;
  v_days integer;
BEGIN
  SELECT trial_default_plan_id, trial_default_days INTO v_plan_id, v_days
  FROM public.saas_settings LIMIT 1;
  IF v_plan_id IS NULL THEN
    SELECT id INTO v_plan_id FROM public.plans WHERE is_default_trial = true LIMIT 1;
  END IF;
  IF v_plan_id IS NULL THEN
    RAISE EXCEPTION 'Nenhum plano padrão de trial disponível.';
  END IF;
  v_days := COALESCE(v_days, 14);

  INSERT INTO public.account_subscriptions (clinic_id, plan_id, status, trial_start, trial_end)
  SELECT c.id, v_plan_id, 'trial'::subscription_status, now(), now() + (v_days || ' days')::interval
  FROM public.clinics c
  LEFT JOIN public.account_subscriptions s ON s.clinic_id = c.id
  WHERE s.id IS NULL;
END $$;

CREATE OR REPLACE FUNCTION public.get_my_subscription_state()
RETURNS TABLE(
  plan_id uuid, plan_name text, status subscription_status,
  trial_end timestamptz, enabled_modules jsonb, max_users integer
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT p.id, p.name, s.status, s.trial_end, p.enabled_modules, p.max_users
  FROM public.account_subscriptions s
  JOIN public.plans p ON p.id = s.plan_id
  WHERE s.clinic_id = public.get_my_clinic_id()
  ORDER BY s.created_at DESC LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_subscription_state() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_subscription_state() TO authenticated;

CREATE OR REPLACE FUNCTION public.my_permission(_module text)
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clinic uuid;
  v_status subscription_status;
  v_modules jsonb;
  v_individual text;
BEGIN
  IF public.is_superadmin(v_uid) THEN RETURN 'full'; END IF;
  v_clinic := public.get_my_clinic_id();

  SELECT s.status, p.enabled_modules INTO v_status, v_modules
  FROM public.account_subscriptions s
  JOIN public.plans p ON p.id = s.plan_id
  WHERE s.clinic_id = v_clinic
  ORDER BY s.created_at DESC LIMIT 1;

  IF v_status IN ('suspended','cancelled') THEN RETURN 'none'; END IF;
  IF v_modules IS NULL OR NOT COALESCE((v_modules->>_module)::boolean, false) THEN
    RETURN 'none';
  END IF;

  IF public.has_role(v_uid, 'admin') THEN RETURN 'full'; END IF;

  SELECT permissions->>_module INTO v_individual
  FROM public.team_members
  WHERE user_id = v_uid AND active = true LIMIT 1;

  RETURN COALESCE(v_individual, 'full');
END;
$$;

CREATE OR REPLACE FUNCTION public.clinic_within_user_limit(_clinic_id uuid)
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_max integer;
  v_count integer;
BEGIN
  SELECT p.max_users INTO v_max
  FROM public.account_subscriptions s
  JOIN public.plans p ON p.id = s.plan_id
  WHERE s.clinic_id = _clinic_id
  ORDER BY s.created_at DESC LIMIT 1;

  IF v_max IS NULL THEN RETURN true; END IF;

  SELECT count(*) INTO v_count
  FROM public.team_members
  WHERE clinic_id = _clinic_id AND active = true AND user_id IS NOT NULL;

  RETURN v_count <= v_max;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_team_user_limit()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL OR public.is_superadmin(v_uid) THEN RETURN NEW; END IF;
  IF NEW.user_id IS NULL OR NEW.active IS NOT TRUE THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE'
     AND OLD.user_id IS NOT DISTINCT FROM NEW.user_id
     AND OLD.active IS NOT DISTINCT FROM NEW.active THEN
    RETURN NEW;
  END IF;
  IF NOT public.clinic_within_user_limit(NEW.clinic_id) THEN
    RAISE EXCEPTION 'Limite de usuários do plano atingido';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS team_members_enforce_user_limit ON public.team_members;
CREATE TRIGGER team_members_enforce_user_limit
BEFORE INSERT OR UPDATE ON public.team_members
FOR EACH ROW EXECUTE FUNCTION public.enforce_team_user_limit();
