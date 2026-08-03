
-- 1. Create chart_of_accounts table
CREATE TABLE public.chart_of_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  code text NOT NULL,
  name text NOT NULL,
  parent_id uuid REFERENCES public.chart_of_accounts(id) ON DELETE CASCADE,
  level integer NOT NULL DEFAULT 1,
  active boolean NOT NULL DEFAULT true,
  is_system boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(clinic_id, code)
);

ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage chart_of_accounts in their clinic"
  ON public.chart_of_accounts FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());

-- 2. Alter expenses table
ALTER TABLE public.expenses
  ADD COLUMN chart_account_id uuid REFERENCES public.chart_of_accounts(id),
  ADD COLUMN competence_date date,
  ADD COLUMN supplier text DEFAULT '',
  ADD COLUMN origin_type text NOT NULL DEFAULT 'manual',
  ADD COLUMN conciliated boolean NOT NULL DEFAULT false,
  ADD COLUMN conciliated_at timestamptz;

-- 3. Alter fixed_expenses table
ALTER TABLE public.fixed_expenses
  ADD COLUMN chart_account_id uuid REFERENCES public.chart_of_accounts(id),
  ADD COLUMN start_date date DEFAULT CURRENT_DATE,
  ADD COLUMN end_date date,
  ADD COLUMN recurrence text NOT NULL DEFAULT 'monthly';

-- 4. Alter receivables table
ALTER TABLE public.receivables
  ADD COLUMN conciliated boolean NOT NULL DEFAULT false,
  ADD COLUMN conciliated_at timestamptz;

-- 5. Create seed function for chart of accounts
CREATE OR REPLACE FUNCTION public.seed_chart_of_accounts(p_clinic_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_sub_id uuid;
BEGIN
  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '1', 'IMPOSTOS, TAXAS E AFINS', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '1.1', 'Tributos sobre faturamento e lucro', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '1.1.1', 'Simples Nacional', v_sub_id, 3),
    (p_clinic_id, '1.1.2', 'ICMS', v_sub_id, 3),
    (p_clinic_id, '1.1.3', 'ISS', v_sub_id, 3),
    (p_clinic_id, '1.1.4', 'PIS', v_sub_id, 3),
    (p_clinic_id, '1.1.5', 'COFINS', v_sub_id, 3),
    (p_clinic_id, '1.1.6', 'IRPJ', v_sub_id, 3),
    (p_clinic_id, '1.1.7', 'IRs Diversos', v_sub_id, 3),
    (p_clinic_id, '1.1.8', 'CSLL', v_sub_id, 3);
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '1.2', 'Parcelamentos, regularizações e obrigações fiscais', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '1.2.1', 'REFIS', v_sub_id, 3),
    (p_clinic_id, '1.2.2', 'INSS', v_sub_id, 3),
    (p_clinic_id, '1.2.3', 'FGTS', v_sub_id, 3);
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '1.3', 'Tributos patrimoniais, regulatórios e taxas', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '1.3.1', 'IPTU', v_sub_id, 3),
    (p_clinic_id, '1.3.2', 'IPVA', v_sub_id, 3),
    (p_clinic_id, '1.3.3', 'Vigilância Sanitária', v_sub_id, 3),
    (p_clinic_id, '1.3.4', 'Taxas e Certificados', v_sub_id, 3),
    (p_clinic_id, '1.3.5', 'Certificados / Certidões', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '2', 'DESPESAS ADMINISTRATIVAS', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '2.1', 'Despesas administrativas gerais', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '2.1.1', 'Desp. Adm. Diversas', v_sub_id, 3),
    (p_clinic_id, '2.1.2', 'Material de expediente e limpeza', v_sub_id, 3),
    (p_clinic_id, '2.1.3', 'Assinaturas', v_sub_id, 3),
    (p_clinic_id, '2.1.4', 'Uniformes', v_sub_id, 3),
    (p_clinic_id, '2.1.5', 'Seguros', v_sub_id, 3),
    (p_clinic_id, '2.1.6', 'Manutenções', v_sub_id, 3),
    (p_clinic_id, '2.1.7', 'Obras e Construções', v_sub_id, 3);
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '2.2', 'Deslocamento, eventos e bem-estar', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '2.2.1', 'Viagens', v_sub_id, 3),
    (p_clinic_id, '2.2.2', 'Transporte (passagens, táxi, Uber etc.)', v_sub_id, 3),
    (p_clinic_id, '2.2.3', 'Saúde Ocupacional', v_sub_id, 3),
    (p_clinic_id, '2.2.4', 'Confraternizações', v_sub_id, 3),
    (p_clinic_id, '2.2.5', 'Segurança e afins', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '3', 'DESPESAS OPERACIONAIS', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '3.1', 'Operação clínica e assistencial', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '3.1.1', 'Repasse para Prestadores de Serviços Clínicos', v_sub_id, 3),
    (p_clinic_id, '3.1.2', 'Benefícios para Pacientes', v_sub_id, 3),
    (p_clinic_id, '3.1.3', 'Envio de medicações', v_sub_id, 3),
    (p_clinic_id, '3.1.4', 'Custo de Coleta Laboratorial', v_sub_id, 3);
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '3.2', 'Operação de apoio e rotina', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '3.2.1', 'Desp. Oper. Diversas', v_sub_id, 3),
    (p_clinic_id, '3.2.2', 'Sistemas de Gestão', v_sub_id, 3),
    (p_clinic_id, '3.2.3', 'Coleta de Resíduos', v_sub_id, 3),
    (p_clinic_id, '3.2.4', 'Comissão por Indicação', v_sub_id, 3),
    (p_clinic_id, '3.2.5', 'Locomoção entre outras unidades', v_sub_id, 3),
    (p_clinic_id, '3.2.6', 'Devoluções', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '4', 'INFRAESTRUTURA', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '4.1', 'Ocupação e utilidades', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '4.1.1', 'Aluguel', v_sub_id, 3),
    (p_clinic_id, '4.1.2', 'Condomínio', v_sub_id, 3),
    (p_clinic_id, '4.1.3', 'Luz', v_sub_id, 3),
    (p_clinic_id, '4.1.4', 'Internet', v_sub_id, 3),
    (p_clinic_id, '4.1.5', 'Telefone', v_sub_id, 3),
    (p_clinic_id, '4.1.6', 'Água', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '5', 'SERVIÇOS TERCEIRIZADOS', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '5.1', 'Serviços técnicos e de suporte', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '5.1.1', 'Limpeza', v_sub_id, 3),
    (p_clinic_id, '5.1.2', 'Contabilidade', v_sub_id, 3),
    (p_clinic_id, '5.1.3', 'Jurídico', v_sub_id, 3),
    (p_clinic_id, '5.1.4', 'Consultorias, Assessorias e Mentorias', v_sub_id, 3),
    (p_clinic_id, '5.1.5', 'Cursos, Treinamentos e Workshops', v_sub_id, 3),
    (p_clinic_id, '5.1.6', 'Gestão', v_sub_id, 3),
    (p_clinic_id, '5.1.7', 'Prestador de Serviços', v_sub_id, 3),
    (p_clinic_id, '5.1.8', 'Serviço de Office-Boy', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '6', 'PESSOAL', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '6.1', 'Remuneração fixa', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '6.1.1', 'Pró-Labore', v_sub_id, 3),
    (p_clinic_id, '6.1.2', 'Salários', v_sub_id, 3),
    (p_clinic_id, '6.1.3', 'Férias', v_sub_id, 3),
    (p_clinic_id, '6.1.4', 'Rescisões', v_sub_id, 3),
    (p_clinic_id, '6.1.5', 'Acordos Trabalhistas', v_sub_id, 3);
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '6.2', 'Benefícios e incentivos', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '6.2.1', 'Vale Transporte e Bilhete Único', v_sub_id, 3),
    (p_clinic_id, '6.2.2', 'Vale Alimentação', v_sub_id, 3),
    (p_clinic_id, '6.2.3', 'Assistência Médica / Odontológica', v_sub_id, 3),
    (p_clinic_id, '6.2.4', 'Recrutamento de Colaboradores', v_sub_id, 3),
    (p_clinic_id, '6.2.5', 'Bonificações e Comissões', v_sub_id, 3),
    (p_clinic_id, '6.2.6', 'Benefícios Diversos', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '7', 'MARKETING', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '7.1', 'Marketing operacional e digital', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '7.1.1', 'Social Media', v_sub_id, 3),
    (p_clinic_id, '7.1.2', 'Gestor de Tráfego', v_sub_id, 3),
    (p_clinic_id, '7.1.3', 'Tráfego Pago', v_sub_id, 3),
    (p_clinic_id, '7.1.4', 'Serviços Digitais', v_sub_id, 3),
    (p_clinic_id, '7.1.5', 'Brindes', v_sub_id, 3),
    (p_clinic_id, '7.1.6', 'Marketing Visual', v_sub_id, 3),
    (p_clinic_id, '7.1.7', 'Experiência do Cliente', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '8', 'DESPESAS FINANCEIRAS', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '8.1', 'Custos financeiros', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '8.1.1', 'Despesas Bancárias', v_sub_id, 3),
    (p_clinic_id, '8.1.2', 'Empréstimos e Consórcios', v_sub_id, 3),
    (p_clinic_id, '8.1.3', 'Descontos Concedidos', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '9', 'ESTOQUE', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '9.1', 'Estoque assistencial', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '9.1.1', 'Estoque de Medicações', v_sub_id, 3),
    (p_clinic_id, '9.1.2', 'Material Clínico', v_sub_id, 3);

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '10', 'AQUISIÇÕES', 1) RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '10.1', 'Bens e estrutura', v_id, 2) RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '10.1.1', 'Móveis e Utensílios', v_sub_id, 3),
    (p_clinic_id, '10.1.2', 'Máquinas e Equipamentos', v_sub_id, 3),
    (p_clinic_id, '10.1.3', 'Computadores e afins', v_sub_id, 3),
    (p_clinic_id, '10.1.4', 'Ferramentas', v_sub_id, 3);
END;
$$;

-- 6. Update handle_new_user to seed chart of accounts
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

  RETURN NEW;
END;
$$;

-- 7. Seed chart of accounts for existing clinics
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM public.clinics WHERE id NOT IN (SELECT DISTINCT clinic_id FROM public.chart_of_accounts)
  LOOP
    PERFORM public.seed_chart_of_accounts(r.id);
  END LOOP;
END;
$$;
