
-- Anamnesis config (configurable form blocks per specialty)
CREATE TABLE public.anamnesis_config (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  specialty TEXT DEFAULT '',
  fields JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_default BOOLEAN NOT NULL DEFAULT false,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.anamnesis_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage anamnesis_config in their clinic"
  ON public.anamnesis_config FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Anamnesis responses (filled forms per patient)
CREATE TABLE public.anamnesis_responses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  config_id UUID NOT NULL REFERENCES public.anamnesis_config(id) ON DELETE CASCADE,
  responses JSONB NOT NULL DEFAULT '{}'::jsonb,
  filled_by UUID,
  status TEXT NOT NULL DEFAULT 'pendente',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.anamnesis_responses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage anamnesis_responses in their clinic"
  ON public.anamnesis_responses FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- AI Insights
CREATE TABLE public.ai_insights (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'weekly',
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  category TEXT DEFAULT 'geral',
  priority TEXT DEFAULT 'medium',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage ai_insights in their clinic"
  ON public.ai_insights FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Triggers
CREATE TRIGGER update_anamnesis_config_updated_at BEFORE UPDATE ON public.anamnesis_config
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_anamnesis_responses_updated_at BEFORE UPDATE ON public.anamnesis_responses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
