ALTER TABLE public.business_rules 
ADD COLUMN IF NOT EXISTS appointment_required_fields jsonb DEFAULT '["patient_id","date"]'::jsonb;