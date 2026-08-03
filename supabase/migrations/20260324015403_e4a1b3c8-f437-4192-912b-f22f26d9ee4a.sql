
-- Stage 1: Add fields to clinics
ALTER TABLE public.clinics ADD COLUMN IF NOT EXISTS cnpj text DEFAULT '';
ALTER TABLE public.clinics ADD COLUMN IF NOT EXISTS specialty text DEFAULT '';
ALTER TABLE public.clinics ADD COLUMN IF NOT EXISTS owner_crm text DEFAULT '';

-- Allow clinic owner to UPDATE their clinic
CREATE POLICY "Users can update their own clinic"
ON public.clinics
FOR UPDATE
TO authenticated
USING (id IN (SELECT clinic_id FROM profiles WHERE user_id = auth.uid()))
WITH CHECK (id IN (SELECT clinic_id FROM profiles WHERE user_id = auth.uid()));

-- Stage 2: Split cost into direct_cost and room_cost for services
ALTER TABLE public.services RENAME COLUMN cost TO direct_cost;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS room_cost numeric DEFAULT 0;

-- Stage 4: Create team_members table
CREATE TABLE IF NOT EXISTS public.team_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  name text NOT NULL,
  role text NOT NULL DEFAULT 'secretaria',
  crm text DEFAULT '',
  email text DEFAULT '',
  phone text DEFAULT '',
  permission_level text DEFAULT 'basic',
  active boolean NOT NULL DEFAULT true,
  modelo_repasse text DEFAULT '',
  repasse_percent numeric DEFAULT 0,
  calcula_sobre text DEFAULT 'bruto',
  valor_fixo_sublocacao numeric DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage team_members in their clinic"
ON public.team_members
FOR ALL
TO authenticated
USING (clinic_id = public.get_my_clinic_id())
WITH CHECK (clinic_id = public.get_my_clinic_id());

-- Stage 4: Create bank_accounts table
CREATE TABLE IF NOT EXISTS public.bank_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  bank_name text NOT NULL,
  bank_code text DEFAULT '',
  agency text DEFAULT '',
  account text DEFAULT '',
  account_type text DEFAULT 'corrente',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage bank_accounts in their clinic"
ON public.bank_accounts
FOR ALL
TO authenticated
USING (clinic_id = public.get_my_clinic_id())
WITH CHECK (clinic_id = public.get_my_clinic_id());

-- Stage 4: Create goals table
CREATE TABLE IF NOT EXISTS public.goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  month integer NOT NULL,
  year integer NOT NULL,
  revenue_target numeric DEFAULT 0,
  new_patients_target integer DEFAULT 0,
  closings_target integer DEFAULT 0,
  conversion_target numeric DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(clinic_id, month, year)
);

ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage goals in their clinic"
ON public.goals
FOR ALL
TO authenticated
USING (clinic_id = public.get_my_clinic_id())
WITH CHECK (clinic_id = public.get_my_clinic_id());

-- Update handle_new_user to save new clinic fields and seed default data
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  new_clinic_id UUID;
BEGIN
  INSERT INTO public.clinics (name, cnpj, specialty, owner_crm)
  VALUES (
    COALESCE(NEW.raw_user_meta_data->>'clinic_name', 'Minha Clínica'),
    COALESCE(NEW.raw_user_meta_data->>'cnpj', ''),
    COALESCE(NEW.raw_user_meta_data->>'specialty', ''),
    COALESCE(NEW.raw_user_meta_data->>'owner_crm', '')
  )
  RETURNING id INTO new_clinic_id;

  INSERT INTO public.profiles (user_id, clinic_id, full_name, phone)
  VALUES (
    NEW.id,
    new_clinic_id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  );

  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'admin');

  INSERT INTO public.business_rules (clinic_id)
  VALUES (new_clinic_id);

  PERFORM public.seed_chart_of_accounts(new_clinic_id);
  PERFORM public.seed_closing_types(new_clinic_id);

  -- Seed default channels
  INSERT INTO public.channels (clinic_id, name) VALUES
    (new_clinic_id, 'WhatsApp'),
    (new_clinic_id, 'Instagram'),
    (new_clinic_id, 'Telefone'),
    (new_clinic_id, 'Indicação');

  -- Seed default origins
  INSERT INTO public.origins (clinic_id, name) VALUES
    (new_clinic_id, 'Google'),
    (new_clinic_id, 'Instagram'),
    (new_clinic_id, 'Indicação');

  -- Seed default payment methods
  INSERT INTO public.payment_methods (clinic_id, name, default_fee_percent, payment_term_days) VALUES
    (new_clinic_id, 'Dinheiro', 0, 0),
    (new_clinic_id, 'PIX', 0, 0),
    (new_clinic_id, 'Cartão de Crédito', 3.5, 30),
    (new_clinic_id, 'Cartão de Débito', 2.0, 1),
    (new_clinic_id, 'Boleto', 0, 3);

  -- Seed default expense categories
  INSERT INTO public.expense_categories (clinic_id, name) VALUES
    (new_clinic_id, 'Consulta'),
    (new_clinic_id, 'Procedimento'),
    (new_clinic_id, 'Produto');

  RETURN NEW;
END;
$function$;
