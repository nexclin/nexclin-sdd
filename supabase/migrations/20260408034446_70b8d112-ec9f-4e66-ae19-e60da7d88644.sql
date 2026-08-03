
CREATE TYPE public.superadmin_role AS ENUM ('super_owner', 'admin', 'suporte', 'financeiro');
CREATE TYPE public.subscription_status AS ENUM ('trial', 'active', 'overdue', 'suspended', 'cancelled');

CREATE TABLE public.superadmin_operators (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL,
  role superadmin_role NOT NULL DEFAULT 'admin',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz,
  last_login_ip text,
  UNIQUE(user_id)
);

CREATE OR REPLACE FUNCTION public.is_superadmin(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.superadmin_operators
    WHERE user_id = _user_id AND active = true
  )
$$;

ALTER TABLE public.superadmin_operators ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Superadmins can manage operators"
  ON public.superadmin_operators FOR ALL TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

CREATE TABLE public.plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  monthly_price numeric NOT NULL DEFAULT 0,
  annual_price numeric NOT NULL DEFAULT 0,
  trial_days integer NOT NULL DEFAULT 14,
  max_users integer NOT NULL DEFAULT 0,
  max_patients integer NOT NULL DEFAULT 0,
  max_leads_month integer NOT NULL DEFAULT 0,
  enabled_modules jsonb NOT NULL DEFAULT '[]'::jsonb,
  support_level text NOT NULL DEFAULT 'email',
  status text NOT NULL DEFAULT 'active',
  visibility text NOT NULL DEFAULT 'public',
  is_default_trial boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Superadmins can manage plans"
  ON public.plans FOR ALL TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

CREATE TABLE public.account_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES public.plans(id),
  status subscription_status NOT NULL DEFAULT 'trial',
  trial_start timestamptz,
  trial_end timestamptz,
  started_at timestamptz,
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  coupon_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(clinic_id)
);
ALTER TABLE public.account_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Superadmins can manage subscriptions"
  ON public.account_subscriptions FOR ALL TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

CREATE TABLE public.account_timeline (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  operator_id uuid REFERENCES public.superadmin_operators(id),
  event_type text NOT NULL,
  description text NOT NULL DEFAULT '',
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.account_timeline ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Superadmins can manage timeline"
  ON public.account_timeline FOR ALL TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

CREATE TABLE public.superadmin_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id uuid REFERENCES public.superadmin_operators(id),
  action text NOT NULL,
  clinic_id uuid REFERENCES public.clinics(id) ON DELETE SET NULL,
  previous_state jsonb,
  new_state jsonb,
  reason text,
  ip_address text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.superadmin_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Superadmins can view audit logs"
  ON public.superadmin_audit_log FOR SELECT TO authenticated
  USING (public.is_superadmin(auth.uid()));
CREATE POLICY "Superadmins can insert audit logs"
  ON public.superadmin_audit_log FOR INSERT TO authenticated
  WITH CHECK (public.is_superadmin(auth.uid()));

CREATE POLICY "Superadmins can view all clinics"
  ON public.clinics FOR SELECT TO authenticated
  USING (public.is_superadmin(auth.uid()));

CREATE POLICY "Superadmins can view all profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (public.is_superadmin(auth.uid()));
