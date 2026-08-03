
-- Funil 2 entries (post-appointment conversion tracking)
CREATE TABLE public.funnel_2_entries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  doctor TEXT DEFAULT '',
  stage TEXT NOT NULL DEFAULT 'compareceu',
  notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.funnel_2_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage funnel_2_entries in their clinic"
  ON public.funnel_2_entries FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Prescriptions
CREATE TABLE public.prescriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  funnel_2_entry_id UUID NOT NULL REFERENCES public.funnel_2_entries(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  has_prescription BOOLEAN NOT NULL DEFAULT false,
  prescription_type TEXT DEFAULT '',
  prescribed_value NUMERIC DEFAULT 0,
  notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage prescriptions in their clinic"
  ON public.prescriptions FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Closings
CREATE TABLE public.closings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  funnel_2_entry_id UUID NOT NULL REFERENCES public.funnel_2_entries(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  closing_type TEXT NOT NULL DEFAULT 'completo',
  closed_value NUMERIC DEFAULT 0,
  discount_percent NUMERIC DEFAULT 0,
  installments INTEGER DEFAULT 1,
  payment_condition TEXT DEFAULT '',
  responsible TEXT DEFAULT '',
  closed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.closings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage closings in their clinic"
  ON public.closings FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Add updated_at triggers
CREATE TRIGGER update_funnel_2_entries_updated_at BEFORE UPDATE ON public.funnel_2_entries
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_prescriptions_updated_at BEFORE UPDATE ON public.prescriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_closings_updated_at BEFORE UPDATE ON public.closings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
