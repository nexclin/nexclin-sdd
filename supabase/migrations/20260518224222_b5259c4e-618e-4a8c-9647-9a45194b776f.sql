
-- 1. business_rules.work_saturday
ALTER TABLE public.business_rules
  ADD COLUMN IF NOT EXISTS work_saturday boolean NOT NULL DEFAULT false;

-- 2. payment_methods.anticipation_default
ALTER TABLE public.payment_methods
  ADD COLUMN IF NOT EXISTS anticipation_default boolean NOT NULL DEFAULT false;

-- 3. budgets + budget_items
CREATE TABLE IF NOT EXISTS public.budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL,
  appointment_id uuid,
  patient_id uuid,
  responsible text DEFAULT '',
  status text NOT NULL DEFAULT 'orcado',
  prescribed_value numeric NOT NULL DEFAULT 0,
  closed_value numeric NOT NULL DEFAULT 0,
  notes text DEFAULT '',
  closed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage budgets in their clinic"
ON public.budgets FOR ALL TO authenticated
USING (clinic_id = public.get_my_clinic_id())
WITH CHECK (clinic_id = public.get_my_clinic_id());

CREATE TRIGGER budgets_updated_at
BEFORE UPDATE ON public.budgets
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_budgets_clinic ON public.budgets(clinic_id);
CREATE INDEX IF NOT EXISTS idx_budgets_appointment ON public.budgets(appointment_id);
CREATE INDEX IF NOT EXISTS idx_budgets_patient ON public.budgets(patient_id);

CREATE TABLE IF NOT EXISTS public.budget_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id uuid NOT NULL REFERENCES public.budgets(id) ON DELETE CASCADE,
  clinic_id uuid NOT NULL,
  service_id uuid,
  item text NOT NULL DEFAULT '',
  macro_category text DEFAULT '',
  category text DEFAULT '',
  quantity integer NOT NULL DEFAULT 1,
  unit_price numeric NOT NULL DEFAULT 0,
  total numeric NOT NULL DEFAULT 0,
  closed_value numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'orcado',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.budget_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage budget_items in their clinic"
ON public.budget_items FOR ALL TO authenticated
USING (clinic_id = public.get_my_clinic_id())
WITH CHECK (clinic_id = public.get_my_clinic_id());

CREATE TRIGGER budget_items_updated_at
BEFORE UPDATE ON public.budget_items
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_budget_items_budget ON public.budget_items(budget_id);
CREATE INDEX IF NOT EXISTS idx_budget_items_clinic ON public.budget_items(clinic_id);
