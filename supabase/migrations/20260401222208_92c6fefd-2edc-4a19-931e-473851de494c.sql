
-- Add anamnesis_send_days column to business_rules
ALTER TABLE public.business_rules
  ADD COLUMN IF NOT EXISTS anamnesis_send_days integer NOT NULL DEFAULT 1;

-- Update handle_new_user to also seed team_members and objections
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

  -- Auto-create owner as team member
  INSERT INTO public.team_members (clinic_id, name, role, crm, phone, permission_level, active)
  VALUES (
    new_clinic_id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    'medico_principal',
    COALESCE(NEW.raw_user_meta_data->>'owner_crm', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    'master',
    true
  );

  PERFORM public.seed_chart_of_accounts(new_clinic_id);
  PERFORM public.seed_closing_types(new_clinic_id);
  PERFORM public.seed_native_services(new_clinic_id);

  -- Seed channels
  INSERT INTO public.channels (clinic_id, name, active) VALUES
    (new_clinic_id, 'Whatsapp', false),
    (new_clinic_id, 'Direct Instagram', false),
    (new_clinic_id, 'Ligação', false),
    (new_clinic_id, 'E-mail', false),
    (new_clinic_id, 'Presencial', false);

  -- Seed origins
  INSERT INTO public.origins (clinic_id, name, active) VALUES
    (new_clinic_id, 'Redes Sociais Clínica', false),
    (new_clinic_id, 'Redes Sociais Médico(a)', false),
    (new_clinic_id, 'Google', false),
    (new_clinic_id, 'Site', false),
    (new_clinic_id, 'Indicação amigo/familiar', false),
    (new_clinic_id, 'Indicação profissional de saúde', false),
    (new_clinic_id, 'Convênio', false),
    (new_clinic_id, 'Não informado', false);

  -- Seed payment methods
  INSERT INTO public.payment_methods (clinic_id, name, default_fee_percent, payment_term_days, active) VALUES
    (new_clinic_id, 'Dinheiro', 0, 0, false),
    (new_clinic_id, 'Pix', 0, 0, false),
    (new_clinic_id, 'Transferência', 0, 0, false),
    (new_clinic_id, 'Boleto', 0, 3, false),
    (new_clinic_id, 'Cheque', 0, 0, false),
    (new_clinic_id, 'Cartão de Débito', 2.0, 1, false),
    (new_clinic_id, 'Cartão de Crédito', 3.5, 30, false);

  -- Seed bank accounts
  INSERT INTO public.bank_accounts (clinic_id, bank_name, bank_code, active) VALUES
    (new_clinic_id, 'Banco do Brasil', '001', false),
    (new_clinic_id, 'Caixa Econômica Federal', '104', false),
    (new_clinic_id, 'Banco Bradesco', '237', false),
    (new_clinic_id, 'Banco Itaú Unibanco', '341', false),
    (new_clinic_id, 'Banco Santander', '033', false),
    (new_clinic_id, 'Banco BTG Pactual', '208', false),
    (new_clinic_id, 'Banco Inter', '077', false),
    (new_clinic_id, 'Banco C6', '336', false),
    (new_clinic_id, 'Nubank', '260', false),
    (new_clinic_id, 'Banco XP', '348', false),
    (new_clinic_id, 'Banco Safra', '422', false),
    (new_clinic_id, 'Banco Votorantim', '655', false),
    (new_clinic_id, 'Banco Pan', '623', false),
    (new_clinic_id, 'Sicoob', '756', false),
    (new_clinic_id, 'Sicredi', '748', false),
    (new_clinic_id, 'PicPay', '380', false),
    (new_clinic_id, 'PagSeguro', '290', false),
    (new_clinic_id, 'Mercado Pago', '323', false),
    (new_clinic_id, 'Stone Pagamentos', '197', false),
    (new_clinic_id, 'Cielo', '362', false),
    (new_clinic_id, 'BRB - Banco de Brasília', '070', false),
    (new_clinic_id, 'Banco Rendimento', '633', false),
    (new_clinic_id, 'Banco Modal', '746', false),
    (new_clinic_id, 'Banco BMG', '318', false),
    (new_clinic_id, 'Banco Agibank', '121', false),
    (new_clinic_id, 'Banco Original', '212', false),
    (new_clinic_id, 'Banco BS2', '218', false),
    (new_clinic_id, 'Banco Daycoval', '707', false),
    (new_clinic_id, 'Banco Digimais', '654', false),
    (new_clinic_id, 'SumUp', '404', false),
    (new_clinic_id, 'Cora', '403', false),
    (new_clinic_id, 'Banco Topázio', '082', false),
    (new_clinic_id, 'Banestes', '021', false),
    (new_clinic_id, 'BRK S.A. Crédito', '092', false);

  -- Seed acquirers
  INSERT INTO public.acquirers (clinic_id, name, active) VALUES
    (new_clinic_id, 'Stone', false),
    (new_clinic_id, 'Cielo', false),
    (new_clinic_id, 'Rede', false),
    (new_clinic_id, 'PagSeguro', false),
    (new_clinic_id, 'Mercado Pago', false),
    (new_clinic_id, 'Getnet', false),
    (new_clinic_id, 'SumUp', false),
    (new_clinic_id, 'Ton', false),
    (new_clinic_id, 'InfinitePay', false),
    (new_clinic_id, 'PicPay', false),
    (new_clinic_id, 'Safrapay', false),
    (new_clinic_id, 'Vero', false);

  -- Seed objections
  INSERT INTO public.objections (clinic_id, name, active) VALUES
    (new_clinic_id, 'Parou de responder', true),
    (new_clinic_id, 'Parou de responder após preço', true),
    (new_clinic_id, 'Queria pelo plano de saúde/convênio', true),
    (new_clinic_id, 'Distância', true),
    (new_clinic_id, 'Preço', true),
    (new_clinic_id, 'Não é prioridade', true),
    (new_clinic_id, 'Marcou com outro profissional', true),
    (new_clinic_id, 'Lead desqualificado', true),
    (new_clinic_id, 'Errou de especialidade', true),
    (new_clinic_id, 'Horário de atendimento', true),
    (new_clinic_id, 'Demora na agenda', true),
    (new_clinic_id, 'Golpe', true),
    (new_clinic_id, 'Medo/Insegurança dos procedimentos', true),
    (new_clinic_id, 'Não informado', true);

  RETURN NEW;
END;
$function$;
