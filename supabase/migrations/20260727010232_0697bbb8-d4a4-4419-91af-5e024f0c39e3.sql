
-- 1. Policy: superadmins can update all profiles
CREATE POLICY "Superadmins can update all profiles"
ON public.profiles
FOR UPDATE
TO authenticated
USING (public.is_superadmin(auth.uid()))
WITH CHECK (public.is_superadmin(auth.uid()));

-- 2. Audit trigger for profile edits by superadmin
CREATE OR REPLACE FUNCTION public.audit_superadmin_profile_edit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_operator_id uuid;
  v_old jsonb := '{}'::jsonb;
  v_new jsonb := '{}'::jsonb;
BEGIN
  IF v_uid IS NULL OR NOT public.is_superadmin(v_uid) THEN
    RETURN NEW;
  END IF;
  IF NEW.user_id = v_uid THEN
    RETURN NEW;
  END IF;

  IF OLD.full_name IS DISTINCT FROM NEW.full_name THEN
    v_old := v_old || jsonb_build_object('full_name', OLD.full_name);
    v_new := v_new || jsonb_build_object('full_name', NEW.full_name);
  END IF;
  IF OLD.phone IS DISTINCT FROM NEW.phone THEN
    v_old := v_old || jsonb_build_object('phone', OLD.phone);
    v_new := v_new || jsonb_build_object('phone', NEW.phone);
  END IF;
  IF OLD.clinic_id IS DISTINCT FROM NEW.clinic_id THEN
    v_old := v_old || jsonb_build_object('clinic_id', OLD.clinic_id);
    v_new := v_new || jsonb_build_object('clinic_id', NEW.clinic_id);
  END IF;

  IF v_new = '{}'::jsonb THEN
    RETURN NEW;
  END IF;

  SELECT id INTO v_operator_id
  FROM public.superadmin_operators
  WHERE user_id = v_uid AND active = true
  LIMIT 1;

  INSERT INTO public.superadmin_audit_log
    (operator_id, action, clinic_id, previous_state, new_state)
  VALUES (
    v_operator_id,
    'profile_edit',
    NEW.clinic_id,
    v_old || jsonb_build_object('target_user_id', NEW.user_id),
    v_new
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_superadmin_profile_edit ON public.profiles;
CREATE TRIGGER trg_audit_superadmin_profile_edit
AFTER UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.audit_superadmin_profile_edit();
