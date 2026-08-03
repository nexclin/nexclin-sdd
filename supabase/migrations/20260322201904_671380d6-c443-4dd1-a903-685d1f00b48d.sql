
-- Add closing/sales fields to appointments
ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS closing_type_id uuid REFERENCES public.closing_types(id),
  ADD COLUMN IF NOT EXISTS has_prescription boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS prescribed_value numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sold_value numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS closing_date date,
  ADD COLUMN IF NOT EXISTS responsible text DEFAULT '',
  ADD COLUMN IF NOT EXISTS approval_status text NOT NULL DEFAULT 'pendente',
  ADD COLUMN IF NOT EXISTS deposit_value numeric NOT NULL DEFAULT 0;

-- Add revenue fields to receivables (absorbing from revenues table)
ALTER TABLE public.receivables
  ADD COLUMN IF NOT EXISTS payment_method_id uuid REFERENCES public.payment_methods(id),
  ADD COLUMN IF NOT EXISTS fee_percent numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS net_value numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS gross_value numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_anticipated boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS anticipation_fee_percent numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS brand text DEFAULT '',
  ADD COLUMN IF NOT EXISTS item text DEFAULT '',
  ADD COLUMN IF NOT EXISTS category text DEFAULT '',
  ADD COLUMN IF NOT EXISTS macro_category text DEFAULT '',
  ADD COLUMN IF NOT EXISTS quantity integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS appointment_id uuid REFERENCES public.appointments(id);

-- Create appointment_items table for prescription sub-items
CREATE TABLE public.appointment_items (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  appointment_id uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  clinic_id uuid NOT NULL REFERENCES public.clinics(id),
  description text NOT NULL DEFAULT '',
  prescribed_value numeric NOT NULL DEFAULT 0,
  sold_value numeric NOT NULL DEFAULT 0,
  approval_status text NOT NULL DEFAULT 'pendente',
  notes text DEFAULT '',
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE public.appointment_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage appointment_items in their clinic"
  ON public.appointment_items
  FOR ALL
  TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));
