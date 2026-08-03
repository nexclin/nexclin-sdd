
-- Update handle_new_user to seed all native data
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

  PERFORM public.seed_chart_of_accounts(new_clinic_id);
  PERFORM public.seed_closing_types(new_clinic_id);

  -- Seed channels (5)
  INSERT INTO public.channels (clinic_id, name, active) VALUES
    (new_clinic_id, 'Whatsapp', false),
    (new_clinic_id, 'Direct Instagram', false),
    (new_clinic_id, 'Ligação', false),
    (new_clinic_id, 'E-mail', false),
    (new_clinic_id, 'Presencial', false);

  -- Seed origins (8)
  INSERT INTO public.origins (clinic_id, name, active) VALUES
    (new_clinic_id, 'Redes Sociais Clínica', false),
    (new_clinic_id, 'Redes Sociais Médico(a)', false),
    (new_clinic_id, 'Google', false),
    (new_clinic_id, 'Site', false),
    (new_clinic_id, 'Indicação amigo/familiar', false),
    (new_clinic_id, 'Indicação profissional de saúde', false),
    (new_clinic_id, 'Convênio', false),
    (new_clinic_id, 'Não informado', false);

  -- Seed payment methods (7)
  INSERT INTO public.payment_methods (clinic_id, name, default_fee_percent, payment_term_days, active) VALUES
    (new_clinic_id, 'Dinheiro', 0, 0, false),
    (new_clinic_id, 'Pix', 0, 0, false),
    (new_clinic_id, 'Transferência', 0, 0, false),
    (new_clinic_id, 'Boleto', 0, 3, false),
    (new_clinic_id, 'Cheque', 0, 0, false),
    (new_clinic_id, 'Cartão de Débito', 2.0, 1, false),
    (new_clinic_id, 'Cartão de Crédito', 3.5, 30, false);

  -- Seed expense categories (3 basic active)
  INSERT INTO public.expense_categories (clinic_id, name) VALUES
    (new_clinic_id, 'Consulta'),
    (new_clinic_id, 'Procedimento'),
    (new_clinic_id, 'Produto');

  -- Seed bank accounts (34 banks, all inactive)
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

  RETURN NEW;
END;
$function$;

-- Seed missing data into existing clinics

-- Channels
INSERT INTO public.channels (clinic_id, name, active)
SELECT c.id, v.name, false
FROM public.clinics c
CROSS JOIN (VALUES ('Whatsapp'),('Direct Instagram'),('Ligação'),('E-mail'),('Presencial')) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM public.channels ch WHERE ch.clinic_id = c.id AND LOWER(ch.name) = LOWER(v.name)
);

-- Origins
INSERT INTO public.origins (clinic_id, name, active)
SELECT c.id, v.name, false
FROM public.clinics c
CROSS JOIN (VALUES ('Redes Sociais Clínica'),('Redes Sociais Médico(a)'),('Google'),('Site'),('Indicação amigo/familiar'),('Indicação profissional de saúde'),('Convênio'),('Não informado')) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM public.origins o WHERE o.clinic_id = c.id AND LOWER(o.name) = LOWER(v.name)
);

-- Payment methods
INSERT INTO public.payment_methods (clinic_id, name, default_fee_percent, payment_term_days, active)
SELECT c.id, v.name, v.fee, v.term, false
FROM public.clinics c
CROSS JOIN (VALUES 
  ('Dinheiro', 0::numeric, 0),
  ('Pix', 0::numeric, 0),
  ('Transferência', 0::numeric, 0),
  ('Boleto', 0::numeric, 3),
  ('Cheque', 0::numeric, 0),
  ('Cartão de Débito', 2.0::numeric, 1),
  ('Cartão de Crédito', 3.5::numeric, 30)
) AS v(name, fee, term)
WHERE NOT EXISTS (
  SELECT 1 FROM public.payment_methods pm WHERE pm.clinic_id = c.id AND LOWER(pm.name) = LOWER(v.name)
);

-- Bank accounts
INSERT INTO public.bank_accounts (clinic_id, bank_name, bank_code, active)
SELECT c.id, v.bname, v.bcode, false
FROM public.clinics c
CROSS JOIN (VALUES
  ('Banco do Brasil','001'),('Caixa Econômica Federal','104'),('Banco Bradesco','237'),
  ('Banco Itaú Unibanco','341'),('Banco Santander','033'),('Banco BTG Pactual','208'),
  ('Banco Inter','077'),('Banco C6','336'),('Nubank','260'),('Banco XP','348'),
  ('Banco Safra','422'),('Banco Votorantim','655'),('Banco Pan','623'),
  ('Sicoob','756'),('Sicredi','748'),('PicPay','380'),('PagSeguro','290'),
  ('Mercado Pago','323'),('Stone Pagamentos','197'),('Cielo','362'),
  ('BRB - Banco de Brasília','070'),('Banco Rendimento','633'),('Banco Modal','746'),
  ('Banco BMG','318'),('Banco Agibank','121'),('Banco Original','212'),
  ('Banco BS2','218'),('Banco Daycoval','707'),('Banco Digimais','654'),
  ('SumUp','404'),('Cora','403'),('Banco Topázio','082'),('Banestes','021'),
  ('BRK S.A. Crédito','092')
) AS v(bname, bcode)
WHERE NOT EXISTS (
  SELECT 1 FROM public.bank_accounts ba WHERE ba.clinic_id = c.id AND LOWER(ba.bank_name) = LOWER(v.bname)
);
