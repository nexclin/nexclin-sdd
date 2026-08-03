
-- Create a function to seed native services for a clinic
CREATE OR REPLACE FUNCTION public.seed_native_services(p_clinic_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO services (clinic_id, name, active) VALUES
    (p_clinic_id, 'Acompanhamento medicamentoso', false),
    (p_clinic_id, 'Acroma', false),
    (p_clinic_id, 'Acroma Melasma', false),
    (p_clinic_id, 'Acroma Olheiras', false),
    (p_clinic_id, 'Audiometria', false),
    (p_clinic_id, 'Avaliação de desenvolvimento', false),
    (p_clinic_id, 'Avaliação de lesão', false),
    (p_clinic_id, 'Avaliação diagnóstica', false),
    (p_clinic_id, 'Avaliação metabólica', false),
    (p_clinic_id, 'Avaliação neurológica', false),
    (p_clinic_id, 'Avaliação pré-operatória', false),
    (p_clinic_id, 'Bioestimulador injetável', false),
    (p_clinic_id, 'Bioimpedância', false),
    (p_clinic_id, 'Biópsia', false),
    (p_clinic_id, 'Botox', false),
    (p_clinic_id, 'Botox - Axilas', false),
    (p_clinic_id, 'Botox - Rosto', false),
    (p_clinic_id, 'Botox - Rosto e Pescoço', false),
    (p_clinic_id, 'Calorimetria', false),
    (p_clinic_id, 'Cetamina Assistida', false),
    (p_clinic_id, 'Check-up cardíaco', false),
    (p_clinic_id, 'Check-up geral', false),
    (p_clinic_id, 'Cipionato de Testosterona', false),
    (p_clinic_id, 'Cirurgia refrativa', false),
    (p_clinic_id, 'Clareamento íntimo', false),
    (p_clinic_id, 'Coleta de Sangue', false),
    (p_clinic_id, 'Colocação de Balão Intragástrico (1 ano)', false),
    (p_clinic_id, 'Colocação de Balão Intragástrico (6 meses)', false),
    (p_clinic_id, 'Colonoscopia', false),
    (p_clinic_id, 'Colposcopia', false),
    (p_clinic_id, 'Consulta cardiológica', false),
    (p_clinic_id, 'Consulta cirúrgica', false),
    (p_clinic_id, 'Consulta clínica', false),
    (p_clinic_id, 'Consulta dermatológica', false),
    (p_clinic_id, 'Consulta endócrino', false),
    (p_clinic_id, 'Consulta gastro', false),
    (p_clinic_id, 'Consulta ginecológica', false),
    (p_clinic_id, 'Consulta neurológica', false),
    (p_clinic_id, 'Consulta Nutricionista', false),
    (p_clinic_id, 'Consulta nutrológica', false),
    (p_clinic_id, 'Consulta oftalmológica', false),
    (p_clinic_id, 'Consulta ortopédica', false),
    (p_clinic_id, 'Consulta otorrino', false),
    (p_clinic_id, 'Consulta pediátrica', false),
    (p_clinic_id, 'Consulta pneumológica', false),
    (p_clinic_id, 'Consulta Psicólogo(a)', false),
    (p_clinic_id, 'Consulta psiquiátrica', false),
    (p_clinic_id, 'Consulta reumatológica', false),
    (p_clinic_id, 'Consulta urológica', false),
    (p_clinic_id, 'Cortisol', false),
    (p_clinic_id, 'CPRE', false),
    (p_clinic_id, 'Curcumina', false),
    (p_clinic_id, 'Deposteron', false),
    (p_clinic_id, 'Dilatação Endoscópica', false),
    (p_clinic_id, 'Dilatação Segmentar', false),
    (p_clinic_id, 'Drenagem', false),
    (p_clinic_id, 'Dual mode corporal', false),
    (p_clinic_id, 'Dual mode olheiras', false),
    (p_clinic_id, 'ECT', false),
    (p_clinic_id, 'Eletrocardiograma', false),
    (p_clinic_id, 'Eletroencefalograma', false),
    (p_clinic_id, 'Eletroporação', false),
    (p_clinic_id, 'Emagrecimento', false),
    (p_clinic_id, 'EMT', false),
    (p_clinic_id, 'Enantato de Testosterona', false),
    (p_clinic_id, 'Endoscopia', false),
    (p_clinic_id, 'Endoscopia nasal', false),
    (p_clinic_id, 'Espirometria', false),
    (p_clinic_id, 'Exame de próstata', false),
    (p_clinic_id, 'Exame de vista', false),
    (p_clinic_id, 'Exerese', false),
    (p_clinic_id, 'Gastroplastia Endoscópica (sutura)', false),
    (p_clinic_id, 'Gastrostomia Endoscópica', false),
    (p_clinic_id, 'Gestão de doenças crônicas', false),
    (p_clinic_id, 'GH', false),
    (p_clinic_id, 'HCG', false),
    (p_clinic_id, 'Hemostasia Mecânica', false),
    (p_clinic_id, 'Hemostasia Térmica', false),
    (p_clinic_id, 'Histeroscopia', false),
    (p_clinic_id, 'Imobilização', false),
    (p_clinic_id, 'Implante - Adicional', false),
    (p_clinic_id, 'Implante - Base', false),
    (p_clinic_id, 'Infiltração', false),
    (p_clinic_id, 'Infiltração articular', false),
    (p_clinic_id, 'Infusão de Cetamina', false),
    (p_clinic_id, 'Inserção de DIU', false),
    (p_clinic_id, 'Intradermo', false),
    (p_clinic_id, 'Laser ablativo - dual mode', false),
    (p_clinic_id, 'Laser dermatológico', false),
    (p_clinic_id, 'Laser vaginal', false),
    (p_clinic_id, 'L-Carnitina + cafeína', false),
    (p_clinic_id, 'Lha la peel', false),
    (p_clinic_id, 'Liftera', false),
    (p_clinic_id, 'Liftera flacidez', false),
    (p_clinic_id, 'Liftera olheiras', false),
    (p_clinic_id, 'Liftera papada', false),
    (p_clinic_id, 'Liftera Pescoço', false),
    (p_clinic_id, 'Liftera rejuvenescimento', false),
    (p_clinic_id, 'Limpeza de Pele', false),
    (p_clinic_id, 'Luz pulsada acne', false),
    (p_clinic_id, 'Lumina eye peel', false),
    (p_clinic_id, 'Luz pulsada mãos', false),
    (p_clinic_id, 'Mapeamento de retina', false),
    (p_clinic_id, 'Medicação - Venvanse', false),
    (p_clinic_id, 'Microagulhamento', false),
    (p_clinic_id, 'MMP Capilar', false),
    (p_clinic_id, 'Mounjaro/Tirzepatida - 2,5mg', false),
    (p_clinic_id, 'Mounjaro/Tirzepatida - 5mg', false),
    (p_clinic_id, 'Mounjaro/Tirzepatida - 7,5mg', false),
    (p_clinic_id, 'Mounjaro/Tirzepatida - 10mg', false),
    (p_clinic_id, 'Mounjaro/Tirzepatida - 12,5mg', false),
    (p_clinic_id, 'Mounjaro/Tirzepatida - frasco 60mg', false),
    (p_clinic_id, 'Mounjaro/Tirzepatida - frasco 90mg', false),
    (p_clinic_id, 'Mucosectomia em Colonoscopia', false),
    (p_clinic_id, 'Mucosectomia em Endoscopia', false),
    (p_clinic_id, 'Nandrolona', false),
    (p_clinic_id, 'Noripurum', false),
    (p_clinic_id, 'Outras medicações', false),
    (p_clinic_id, 'Passagem de sonda por Endoscopia', false),
    (p_clinic_id, 'Peeling', false),
    (p_clinic_id, 'Peeling 4D', false),
    (p_clinic_id, 'Pequenas cirurgias', false),
    (p_clinic_id, 'Plano de Acompanhamento', false),
    (p_clinic_id, 'Plano de Acompanhamento - 2 meses', false),
    (p_clinic_id, 'Plano de Acompanhamento - 3 meses', false),
    (p_clinic_id, 'Plano de Acompanhamento - 6 meses', false),
    (p_clinic_id, 'Plano de Acompanhamento - 12 meses', false),
    (p_clinic_id, 'Plasma de argônio', false),
    (p_clinic_id, 'Polipectomia em Colonoscopia', false),
    (p_clinic_id, 'Polipectomia em Endoscopia', false),
    (p_clinic_id, 'Preenchimento', false),
    (p_clinic_id, 'Pré-natal', false),
    (p_clinic_id, 'Preventivo (Papanicolau)', false),
    (p_clinic_id, 'Procedimentos de ouvido/nariz', false),
    (p_clinic_id, 'Profhilo', false),
    (p_clinic_id, 'Puericultura', false),
    (p_clinic_id, 'Radiesse (2 seringas)', false),
    (p_clinic_id, 'Radiesse (4 seringas)', false),
    (p_clinic_id, 'Radiofrequência', false),
    (p_clinic_id, 'Repasse parceiros', false),
    (p_clinic_id, 'Retirada de corpo estranho', false),
    (p_clinic_id, 'Sangria Terapêutica', false),
    (p_clinic_id, 'Sculptra', false),
    (p_clinic_id, 'Soro - AlfaLipoico', false),
    (p_clinic_id, 'Soro - Antioxidante', false),
    (p_clinic_id, 'Soro - Azul de Metileno', false),
    (p_clinic_id, 'Soro - Ferro', false),
    (p_clinic_id, 'Soro - Hidrocortisona', false),
    (p_clinic_id, 'Soro - Mitocondrial', false),
    (p_clinic_id, 'Soro - Outros', false),
    (p_clinic_id, 'Soro - Performance', false),
    (p_clinic_id, 'Soro - Pele, cabelo e unha', false),
    (p_clinic_id, 'Soro - Queima de gordura', false),
    (p_clinic_id, 'Soro - Vitamina B12', false),
    (p_clinic_id, 'Soro - Vitamina C', false),
    (p_clinic_id, 'Sublocação', false),
    (p_clinic_id, 'Suplementação', false),
    (p_clinic_id, 'Terapia hormonal masculina', false),
    (p_clinic_id, 'Terapias injetáveis', false),
    (p_clinic_id, 'Teste ergométrico', false),
    (p_clinic_id, 'Tratamento de acne', false),
    (p_clinic_id, 'Tratamento de dor crônica', false),
    (p_clinic_id, 'Tratamento digestivo', false),
    (p_clinic_id, 'Tratamento hormonal', false),
    (p_clinic_id, 'Tratamento respiratório', false),
    (p_clinic_id, 'Triancinolona', false),
    (p_clinic_id, 'Ultrassom', false),
    (p_clinic_id, 'Ultrassonografia obstétrica', false),
    (p_clinic_id, 'Vasectomia', false),
    (p_clinic_id, 'Vitamina D3 - 600.000ui', false)
  ON CONFLICT DO NOTHING;
END;
$$;

-- Update handle_new_user to seed services and remove expense_categories seed
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
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

  RETURN NEW;
END;
$$;

-- Backfill: seed native services for all existing clinics that don't have them yet
DO $$
DECLARE
  clinic RECORD;
BEGIN
  FOR clinic IN SELECT id FROM public.clinics LOOP
    PERFORM public.seed_native_services(clinic.id);
  END LOOP;
END;
$$;
