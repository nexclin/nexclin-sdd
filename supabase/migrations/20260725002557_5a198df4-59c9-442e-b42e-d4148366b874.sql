
-- 1) TABELA
CREATE TABLE public.superadmin_impersonation_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  superadmin_user_id uuid NOT NULL,
  target_clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  original_clinic_id uuid NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.superadmin_impersonation_sessions TO authenticated;
GRANT ALL ON public.superadmin_impersonation_sessions TO service_role;

ALTER TABLE public.superadmin_impersonation_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Superadmins manage impersonation sessions"
  ON public.superadmin_impersonation_sessions
  FOR ALL
  TO authenticated
  USING (public.is_superadmin(auth.uid()))
  WITH CHECK (public.is_superadmin(auth.uid()));

CREATE INDEX idx_impersonation_open
  ON public.superadmin_impersonation_sessions (superadmin_user_id)
  WHERE ended_at IS NULL;

-- 2) ENTRAR
CREATE OR REPLACE FUNCTION public.superadmin_enter_clinic(_target_clinic_id uuid)
RETURNS public.superadmin_impersonation_sessions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_operator_id uuid;
  v_operator_name text;
  v_original uuid;
  v_open public.superadmin_impersonation_sessions;
  v_new public.superadmin_impersonation_sessions;
BEGIN
  IF NOT public.is_superadmin(v_uid) THEN
    RAISE EXCEPTION 'Acesso negado';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.clinics WHERE id = _target_clinic_id) THEN
    RAISE EXCEPTION 'Clínica não encontrada';
  END IF;

  SELECT id, name INTO v_operator_id, v_operator_name
  FROM public.superadmin_operators
  WHERE user_id = v_uid AND active = true
  LIMIT 1;

  -- Fecha sessão aberta anterior, restaurando original
  SELECT * INTO v_open
  FROM public.superadmin_impersonation_sessions
  WHERE superadmin_user_id = v_uid AND ended_at IS NULL
  ORDER BY started_at DESC
  LIMIT 1;

  IF FOUND THEN
    UPDATE public.profiles
      SET clinic_id = v_open.original_clinic_id, updated_at = now()
      WHERE user_id = v_uid;
    UPDATE public.superadmin_impersonation_sessions
      SET ended_at = now()
      WHERE id = v_open.id;
  END IF;

  -- Garante perfil e captura clinic_id original
  SELECT clinic_id INTO v_original FROM public.profiles WHERE user_id = v_uid;
  IF NOT FOUND THEN
    INSERT INTO public.profiles (user_id, clinic_id, full_name, phone)
    VALUES (v_uid, NULL, COALESCE(v_operator_name, 'Superadmin'), '');
    v_original := NULL;
  END IF;

  INSERT INTO public.superadmin_impersonation_sessions
    (superadmin_user_id, target_clinic_id, original_clinic_id)
  VALUES (v_uid, _target_clinic_id, v_original)
  RETURNING * INTO v_new;

  UPDATE public.profiles
    SET clinic_id = _target_clinic_id, updated_at = now()
    WHERE user_id = v_uid;

  INSERT INTO public.superadmin_audit_log (operator_id, action, clinic_id, new_state)
  VALUES (
    v_operator_id,
    'impersonation_start',
    _target_clinic_id,
    jsonb_build_object('session_id', v_new.id, 'original_clinic_id', v_original)
  );

  RETURN v_new;
END;
$$;

REVOKE ALL ON FUNCTION public.superadmin_enter_clinic(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.superadmin_enter_clinic(uuid) TO authenticated;

-- 3) SAIR
CREATE OR REPLACE FUNCTION public.superadmin_exit_clinic()
RETURNS public.superadmin_impersonation_sessions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_operator_id uuid;
  v_open public.superadmin_impersonation_sessions;
BEGIN
  IF NOT public.is_superadmin(v_uid) THEN
    RAISE EXCEPTION 'Acesso negado';
  END IF;

  SELECT * INTO v_open
  FROM public.superadmin_impersonation_sessions
  WHERE superadmin_user_id = v_uid AND ended_at IS NULL
  ORDER BY started_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Nenhuma sessão ativa';
  END IF;

  UPDATE public.profiles
    SET clinic_id = v_open.original_clinic_id, updated_at = now()
    WHERE user_id = v_uid;

  UPDATE public.superadmin_impersonation_sessions
    SET ended_at = now()
    WHERE id = v_open.id
    RETURNING * INTO v_open;

  SELECT id INTO v_operator_id
  FROM public.superadmin_operators
  WHERE user_id = v_uid AND active = true
  LIMIT 1;

  INSERT INTO public.superadmin_audit_log (operator_id, action, clinic_id, new_state)
  VALUES (
    v_operator_id,
    'impersonation_end',
    v_open.target_clinic_id,
    jsonb_build_object('session_id', v_open.id, 'restored_clinic_id', v_open.original_clinic_id)
  );

  RETURN v_open;
END;
$$;

REVOKE ALL ON FUNCTION public.superadmin_exit_clinic() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.superadmin_exit_clinic() TO authenticated;

-- 4) CONSULTA
CREATE OR REPLACE FUNCTION public.get_my_active_impersonation()
RETURNS TABLE (
  id uuid,
  superadmin_user_id uuid,
  target_clinic_id uuid,
  original_clinic_id uuid,
  started_at timestamptz,
  target_clinic_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT s.id, s.superadmin_user_id, s.target_clinic_id, s.original_clinic_id,
         s.started_at, c.name
  FROM public.superadmin_impersonation_sessions s
  JOIN public.clinics c ON c.id = s.target_clinic_id
  WHERE s.superadmin_user_id = auth.uid()
    AND s.ended_at IS NULL
  ORDER BY s.started_at DESC
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_active_impersonation() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_active_impersonation() TO authenticated;

-- 5) my_permission: superadmin sempre 'full'
CREATE OR REPLACE FUNCTION public.my_permission(_module text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    -- Superadmin: acesso pleno (equivalente ao 'master')
    CASE WHEN public.is_superadmin(auth.uid()) THEN 'full' END,
    -- Admin global: tudo full
    CASE WHEN public.has_role(auth.uid(), 'admin') THEN 'full' END,
    -- Permissão explícita do team_member
    (SELECT permissions->>_module FROM public.team_members
     WHERE user_id = auth.uid() AND active = true LIMIT 1),
    -- Default: acesso total se não houver team_member (compat retro)
    'full'
  )
$$;
