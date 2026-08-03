
-- 1. Estender team_members
ALTER TABLE public.team_members
  ADD COLUMN IF NOT EXISTS user_id uuid,
  ADD COLUMN IF NOT EXISTS invited_email text,
  ADD COLUMN IF NOT EXISTS invite_status text NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS permissions jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE UNIQUE INDEX IF NOT EXISTS idx_team_members_user_id_unique
  ON public.team_members(user_id) WHERE user_id IS NOT NULL;

-- 2. Função para retornar team_member do usuário logado (SECURITY DEFINER evita recursão)
CREATE OR REPLACE FUNCTION public.get_my_team_member()
RETURNS TABLE(id uuid, clinic_id uuid, name text, role text, permission_level text, permissions jsonb)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT tm.id, tm.clinic_id, tm.name, tm.role, tm.permission_level, tm.permissions
  FROM public.team_members tm
  WHERE tm.user_id = auth.uid() AND tm.active = true
  LIMIT 1
$$;

-- 3. Função para retornar nível de permissão por módulo
CREATE OR REPLACE FUNCTION public.my_permission(_module text)
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE(
    -- Admin global: tudo full
    CASE WHEN public.has_role(auth.uid(), 'admin') THEN 'full' END,
    -- Permissão explícita do team_member
    (SELECT permissions->>_module FROM public.team_members
     WHERE user_id = auth.uid() AND active = true LIMIT 1),
    -- Default: acesso total se não houver team_member (compat retro)
    'full'
  )
$$;

-- 4. Função auxiliar: nome do team_member logado
CREATE OR REPLACE FUNCTION public.my_team_member_name()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT name FROM public.team_members
  WHERE user_id = auth.uid() AND active = true LIMIT 1
$$;

-- 5. Atualizar handle_new_user para diferenciar dono x convidado
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $function$
DECLARE
  new_clinic_id UUID;
  invite_clinic_id UUID;
  invite_team_member_id UUID;
BEGIN
  invite_clinic_id := NULLIF(NEW.raw_user_meta_data->>'invite_clinic_id', '')::uuid;
  invite_team_member_id := NULLIF(NEW.raw_user_meta_data->>'invite_team_member_id', '')::uuid;

  -- Fluxo de CONVIDADO: vincula clínica existente, sem seed
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

  -- Fluxo de DONO (original)
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

  INSERT INTO public.channels (clinic_id, name, active) VALUES
    (new_clinic_id, 'Whatsapp', false),(new_clinic_id, 'Direct Instagram', false),
    (new_clinic_id, 'Ligação', false),(new_clinic_id, 'E-mail', false),(new_clinic_id, 'Presencial', false);

  INSERT INTO public.origins (clinic_id, name, active) VALUES
    (new_clinic_id, 'Redes Sociais Clínica', false),(new_clinic_id, 'Redes Sociais Médico(a)', false),
    (new_clinic_id, 'Google', false),(new_clinic_id, 'Site', false),
    (new_clinic_id, 'Indicação amigo/familiar', false),(new_clinic_id, 'Indicação profissional de saúde', false),
    (new_clinic_id, 'Convênio', false),(new_clinic_id, 'Não informado', false);

  INSERT INTO public.payment_methods (clinic_id, name, default_fee_percent, payment_term_days, active) VALUES
    (new_clinic_id, 'Dinheiro', 0, 0, false),(new_clinic_id, 'Pix', 0, 0, false),
    (new_clinic_id, 'Transferência', 0, 0, false),(new_clinic_id, 'Boleto', 0, 3, false),
    (new_clinic_id, 'Cheque', 0, 0, false),(new_clinic_id, 'Cartão de Débito', 2.0, 1, false),
    (new_clinic_id, 'Cartão de Crédito', 3.5, 30, false);

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

-- 6. Backfill: vincular dono atual (admin) ao team_member existente quando faltar user_id
UPDATE public.team_members tm
SET user_id = p.user_id, invite_status = 'active'
FROM public.profiles p
WHERE tm.user_id IS NULL
  AND tm.clinic_id = p.clinic_id
  AND tm.role = 'medico_principal'
  AND EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = p.user_id AND ur.role = 'admin');
