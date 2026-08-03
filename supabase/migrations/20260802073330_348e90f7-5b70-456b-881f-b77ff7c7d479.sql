-- 1. Restrict SECURITY DEFINER function execution
REVOKE EXECUTE ON FUNCTION public.audit_superadmin_profile_edit() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.auto_complete_anamnese_task() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.auto_complete_appointment_task() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.clinic_within_user_limit(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.enforce_team_user_limit() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.prevent_clinic_id_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_superadmin_operator() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_chart_of_accounts(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_closing_types(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_native_services(uuid) FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.get_my_active_impersonation() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_my_clinic_id() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_my_subscription_state() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_my_team_member() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_superadmin(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.my_permission(text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.my_team_member_name() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.superadmin_enter_clinic(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.superadmin_exit_clinic() FROM PUBLIC, anon;

-- 2. Impersonation sessions scoped to the owning superadmin
DROP POLICY IF EXISTS "Superadmins manage impersonation sessions" ON public.superadmin_impersonation_sessions;
CREATE POLICY "Superadmins manage own impersonation sessions"
ON public.superadmin_impersonation_sessions
FOR ALL TO authenticated
USING (superadmin_user_id = auth.uid() AND public.is_superadmin(auth.uid()))
WITH CHECK (superadmin_user_id = auth.uid() AND public.is_superadmin(auth.uid()));

-- 3. team_members: hide sensitive contact / payout columns from regular clinic users
REVOKE SELECT ON public.team_members FROM authenticated;
GRANT SELECT (
  id, clinic_id, name, role, permission_level, active,
  created_at, updated_at, user_id, invite_status, permissions
) ON public.team_members TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.team_members TO authenticated;
GRANT ALL ON public.team_members TO service_role;

CREATE OR REPLACE FUNCTION public.get_clinic_team_full()
RETURNS SETOF public.team_members
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_clinic uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Não autenticado';
  END IF;
  v_clinic := public.get_my_clinic_id();

  IF NOT (
    public.is_superadmin(v_uid)
    OR public.has_role(v_uid, 'admin')
    OR EXISTS (
      SELECT 1 FROM public.team_members tm
      WHERE tm.user_id = v_uid AND tm.active = true
        AND tm.permission_level IN ('master','gerencial')
    )
  ) THEN
    RAISE EXCEPTION 'Acesso negado';
  END IF;

  RETURN QUERY
  SELECT * FROM public.team_members t
  WHERE t.clinic_id = v_clinic
  ORDER BY t.name;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_clinic_team_full() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_clinic_team_full() TO authenticated;

-- 4. Explicit write policies on user_roles (superadmin only)
CREATE POLICY "Superadmins can insert user roles"
ON public.user_roles FOR INSERT TO authenticated
WITH CHECK (public.is_superadmin(auth.uid()));

CREATE POLICY "Superadmins can update user roles"
ON public.user_roles FOR UPDATE TO authenticated
USING (public.is_superadmin(auth.uid()))
WITH CHECK (public.is_superadmin(auth.uid()));

CREATE POLICY "Superadmins can delete user roles"
ON public.user_roles FOR DELETE TO authenticated
USING (public.is_superadmin(auth.uid()));