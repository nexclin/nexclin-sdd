
-- Remove overly-permissive anon policies (now handled via edge function using service role)
DROP POLICY IF EXISTS "Anon can read anamnesis config" ON public.anamnesis_config;
DROP POLICY IF EXISTS "Anon can read response by id" ON public.anamnesis_responses;
DROP POLICY IF EXISTS "Anon can update pending response" ON public.anamnesis_responses;

-- Lock down SECURITY DEFINER functions: revoke default EXECUTE from public/anon/authenticated,
-- then grant EXECUTE only where clients or RLS policies need to call them.
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prosecdef = true
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %I.%I(%s) FROM PUBLIC, anon, authenticated',
                   r.nspname, r.proname, r.args);
  END LOOP;
END $$;

-- Re-grant EXECUTE for functions called by authenticated clients or referenced in RLS policies
GRANT EXECUTE ON FUNCTION public.has_role(uuid, app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_clinic_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_team_member() TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_permission(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_team_member_name() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_superadmin(uuid) TO authenticated;
