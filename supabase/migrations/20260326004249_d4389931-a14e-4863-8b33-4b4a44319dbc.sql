
CREATE TABLE public.consultation_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text DEFAULT '',
  price numeric DEFAULT 0,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.consultation_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clinic_access" ON public.consultation_types 
  FOR ALL TO authenticated
  USING (clinic_id = get_my_clinic_id()) 
  WITH CHECK (clinic_id = get_my_clinic_id());

ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS consultation_type_id uuid REFERENCES public.consultation_types(id);
