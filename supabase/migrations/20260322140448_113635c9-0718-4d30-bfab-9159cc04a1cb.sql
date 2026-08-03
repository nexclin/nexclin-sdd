
-- Revenues (Faturamento / Receitas)
CREATE TABLE public.revenues (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  patient_id UUID REFERENCES public.patients(id) ON DELETE SET NULL,
  item TEXT NOT NULL DEFAULT '',
  category TEXT DEFAULT '',
  macro_category TEXT DEFAULT '',
  quantity INTEGER NOT NULL DEFAULT 1,
  gross_value NUMERIC NOT NULL DEFAULT 0,
  payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL,
  brand TEXT DEFAULT '',
  fee_percent NUMERIC DEFAULT 0,
  net_value NUMERIC DEFAULT 0,
  is_anticipated BOOLEAN NOT NULL DEFAULT false,
  anticipation_fee_percent NUMERIC DEFAULT 0,
  revenue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.revenues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage revenues in their clinic"
  ON public.revenues FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Receivables (Contas a Receber)
CREATE TABLE public.receivables (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  patient_id UUID REFERENCES public.patients(id) ON DELETE SET NULL,
  description TEXT NOT NULL DEFAULT '',
  origin TEXT DEFAULT '',
  value NUMERIC NOT NULL DEFAULT 0,
  due_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_type TEXT NOT NULL DEFAULT 'a_vista',
  installment_number INTEGER DEFAULT 1,
  total_installments INTEGER DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'pendente',
  paid_at DATE,
  notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.receivables ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage receivables in their clinic"
  ON public.receivables FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Expenses (Despesas / Contas a Pagar)
CREATE TABLE public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  description TEXT NOT NULL DEFAULT '',
  category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
  value NUMERIC NOT NULL DEFAULT 0,
  due_date DATE NOT NULL DEFAULT CURRENT_DATE,
  paid_at DATE,
  payment_method TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pendente',
  person_type TEXT NOT NULL DEFAULT 'pj',
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  fixed_expense_id UUID,
  notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage expenses in their clinic"
  ON public.expenses FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Fixed Expenses (Contas Fixas)
CREATE TABLE public.fixed_expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  clinic_id UUID NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  description TEXT NOT NULL DEFAULT '',
  category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
  value NUMERIC NOT NULL DEFAULT 0,
  due_day INTEGER NOT NULL DEFAULT 1,
  person_type TEXT NOT NULL DEFAULT 'pj',
  active BOOLEAN NOT NULL DEFAULT true,
  notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.fixed_expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage fixed_expenses in their clinic"
  ON public.fixed_expenses FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- Add FK from expenses to fixed_expenses
ALTER TABLE public.expenses
  ADD CONSTRAINT expenses_fixed_expense_id_fkey
  FOREIGN KEY (fixed_expense_id) REFERENCES public.fixed_expenses(id) ON DELETE SET NULL;

-- Triggers
CREATE TRIGGER update_revenues_updated_at BEFORE UPDATE ON public.revenues
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_receivables_updated_at BEFORE UPDATE ON public.receivables
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_fixed_expenses_updated_at BEFORE UPDATE ON public.fixed_expenses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
