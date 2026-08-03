ALTER TABLE public.bank_accounts ADD COLUMN IF NOT EXISTS is_system boolean NOT NULL DEFAULT false;
ALTER TABLE public.closings ADD COLUMN IF NOT EXISTS payment_method_id uuid;

INSERT INTO public.bank_accounts (clinic_id, bank_name, account_type, opening_balance, is_system, active)
SELECT c.id, 'Caixa (dinheiro)', 'caixa', 0, true, true
FROM public.clinics c
WHERE NOT EXISTS (
  SELECT 1 FROM public.bank_accounts ba WHERE ba.clinic_id = c.id AND ba.is_system = true
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  new_clinic_id UUID;
  invite_clinic_id UUID;
  invite_team_member_id UUID;
BEGIN
  invite_clinic_id := NULLIF(NEW.raw_user_meta_data->>'invite_clinic_id', '')::uuid;
  invite_team_member_id := NULLIF(NEW.raw_user_meta_data->>'invite_team_member_id', '')::uuid;

  IF invite_clinic_id IS NOT NULL THEN
    INSERT INTO public.profiles (user_id, clinic_id, full_name, phone)
    VALUES (
      NEW.id,
      invite_clinic_id,
      COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
      COALESCE(NEW.raw_user_meta_data->>'phone', '')
    );
    INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'user');

    IF invite_team_member_id IS NOT NULL THEN
      UPDATE public.team_members
      SET user_id = NEW.id, invite_status = 'active', email = NEW.email
      WHERE id = invite_team_member_id AND clinic_id = invite_clinic_id;
    END IF;
    RETURN NEW;
  END IF;

  INSERT INTO public.clinics (name, cnpj, specialty, owner_crm)
  VALUES (
    COALESCE(NEW.raw_user_meta_data->>'clinic_name', 'Minha Clínica'),
    COALESCE(NEW.raw_user_meta_data->>'cnpj', ''),
    COALESCE(NEW.raw_user_meta_data->>'specialty', ''),
    COALESCE(NEW.raw_user_meta_data->>'owner_crm', '')
  ) RETURNING id INTO new_clinic_id;

  INSERT INTO public.profiles (user_id, clinic_id, full_name, phone)
  VALUES (NEW.id, new_clinic_id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''));

  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'admin');

  INSERT INTO public.business_rules (clinic_id) VALUES (new_clinic_id);

  INSERT INTO public.team_members (clinic_id, name, role, crm, phone, permission_level, active, user_id, invite_status)
  VALUES (
    new_clinic_id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    'medico_principal',
    COALESCE(NEW.raw_user_meta_data->>'owner_crm', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    'master', true, NEW.id, 'active'
  );

  PERFORM public.seed_chart_of_accounts(new_clinic_id);
  PERFORM public.seed_closing_types(new_clinic_id);
  PERFORM public.seed_native_services(new_clinic_id);

  INSERT INTO public.bank_accounts (clinic_id, bank_name, account_type, opening_balance, is_system, active)
  VALUES (new_clinic_id, 'Caixa (dinheiro)', 'caixa', 0, true, true);

  INSERT INTO public.channels (clinic_id, name, active) VALUES
    (new_clinic_id, 'Whatsapp', false),(new_clinic_id, 'Direct Instagram', false),
    (new_clinic_id, 'Ligação', false),(new_clinic_id, 'E-mail', false),(new_clinic_id, 'Presencial', false);

  INSERT INTO public.origins (clinic_id, name, active) VALUES
    (new_clinic_id, 'Redes Sociais Clínica', false),(new_clinic_id, 'Redes Sociais Médico(a)', false),
    (new_clinic_id, 'Google', false),(new_clinic_id, 'Site', false),
    (new_clinic_id, 'Indicação amigo/familiar', false),(new_clinic_id, 'Indicação profissional de saúde', false),
    (new_clinic_id, 'Convênio', false),(new_clinic_id, 'Não informado', false);

  INSERT INTO public.payment_methods (clinic_id, name, type, default_fee_percent, payment_term_days, active) VALUES
    (new_clinic_id, 'Dinheiro', 'dinheiro', 0, 0, false),
    (new_clinic_id, 'Pix', 'pix', 0, 0, false),
    (new_clinic_id, 'Transferência', 'transferencia', 0, 0, false),
    (new_clinic_id, 'Boleto', 'boleto', 0, 3, false),
    (new_clinic_id, 'Cheque', 'cheque', 0, 0, false),
    (new_clinic_id, 'Cartão de Débito', 'debito', 2.0, 1, false),
    (new_clinic_id, 'Cartão de Crédito', 'credito', 3.5, 30, false);

  INSERT INTO public.objections (clinic_id, name, active) VALUES
    (new_clinic_id, 'Parou de responder', true),(new_clinic_id, 'Parou de responder após preço', true),
    (new_clinic_id, 'Queria pelo plano de saúde/convênio', true),(new_clinic_id, 'Distância', true),
    (new_clinic_id, 'Preço', true),(new_clinic_id, 'Não é prioridade', true),
    (new_clinic_id, 'Marcou com outro profissional', true),(new_clinic_id, 'Lead desqualificado', true),
    (new_clinic_id, 'Errou de especialidade', true),(new_clinic_id, 'Horário de atendimento', true),
    (new_clinic_id, 'Demora na agenda', true),(new_clinic_id, 'Golpe', true),
    (new_clinic_id, 'Medo/Insegurança dos procedimentos', true),(new_clinic_id, 'Não informado', true),
    (new_clinic_id, 'Outro', true);

  RETURN NEW;
END;
$function$;