-- billings table
CREATE TABLE public.billings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES public.plans(id),
  amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  attempted_at timestamptz,
  paid_at timestamptz,
  attempts integer NOT NULL DEFAULT 0,
  period_start date,
  period_end date,
  notes text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.billings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Superadmins can manage billings"
  ON public.billings FOR ALL TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

-- coupons table
CREATE TABLE public.coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  discount_type text NOT NULL DEFAULT 'percent',
  discount_value numeric NOT NULL DEFAULT 0,
  applies_to text NOT NULL DEFAULT 'both',
  duration text NOT NULL DEFAULT 'permanent',
  duration_months integer DEFAULT 0,
  max_uses integer NOT NULL DEFAULT 0,
  used_count integer NOT NULL DEFAULT 0,
  expires_at timestamptz,
  eligible_plan_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Superadmins can manage coupons"
  ON public.coupons FOR ALL TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

-- saas_settings table (single-row config)
CREATE TABLE public.saas_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trial_default_days integer NOT NULL DEFAULT 14,
  trial_default_plan_id uuid REFERENCES public.plans(id),
  trial_requires_card boolean NOT NULL DEFAULT false,
  trial_max_extension_days integer NOT NULL DEFAULT 14,
  overdue_email_days jsonb NOT NULL DEFAULT '[1, 3, 7, 15]'::jsonb,
  overdue_suspend_days integer NOT NULL DEFAULT 30,
  overdue_cancel_days integer NOT NULL DEFAULT 60,
  overdue_max_retries integer NOT NULL DEFAULT 3,
  support_email text DEFAULT '',
  terms_url text DEFAULT '',
  privacy_url text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.saas_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Superadmins can manage saas_settings"
  ON public.saas_settings FOR ALL TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

-- Insert default settings row
INSERT INTO public.saas_settings (id) VALUES (gen_random_uuid());