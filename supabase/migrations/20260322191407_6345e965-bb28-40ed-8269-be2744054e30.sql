
-- 1. Create closing_types table
CREATE TABLE public.closing_types (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  is_system BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.closing_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage closing_types in their clinic"
  ON public.closing_types FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- 2. Add new columns to funnel_2_entries
ALTER TABLE public.funnel_2_entries
  ADD COLUMN IF NOT EXISTS attendance_status TEXT NOT NULL DEFAULT 'compareceu',
  ADD COLUMN IF NOT EXISTS has_prescription BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS prescribed_value NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sold_value NUMERIC NOT NULL DEFAULT 0;

-- 3. Add closing_type_id to closings (keep old closing_type for backwards compat)
ALTER TABLE public.closings
  ADD COLUMN IF NOT EXISTS closing_type_id UUID REFERENCES public.closing_types(id);

-- 4. Create seed function for closing types
CREATE OR REPLACE FUNCTION public.seed_closing_types(p_clinic_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO closing_types (clinic_id, name, is_system) VALUES
    (p_clinic_id, 'Fechou Completo', true),
    (p_clinic_id, 'Fechou Parcial', true),
    (p_clinic_id, 'Fechou por Sessão', true),
    (p_clinic_id, 'Em Negociação', true),
    (p_clinic_id, 'Não Fechou', true),
    (p_clinic_id, 'Recaptação', true),
    (p_clinic_id, 'Cortesia', true);
END;
$$;

-- 5. Update handle_new_user to also seed closing_types
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  new_clinic_id UUID;
BEGIN
  INSERT INTO public.clinics (name)
  VALUES (COALESCE(NEW.raw_user_meta_data->>'clinic_name', 'Minha Clínica'))
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

  RETURN NEW;
END;
$$;
