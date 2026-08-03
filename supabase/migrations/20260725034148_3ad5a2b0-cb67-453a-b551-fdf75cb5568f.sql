CREATE OR REPLACE FUNCTION public.my_permission(_module text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_clinic uuid;
  v_status subscription_status;
  v_modules jsonb;
  v_individual text;
BEGIN
  IF public.is_superadmin(v_uid) THEN RETURN 'full'; END IF;
  v_clinic := public.get_my_clinic_id();

  SELECT s.status, p.enabled_modules INTO v_status, v_modules
  FROM public.account_subscriptions s
  JOIN public.plans p ON p.id = s.plan_id
  WHERE s.clinic_id = v_clinic
  ORDER BY s.created_at DESC LIMIT 1;

  IF v_status IN ('suspended','cancelled') THEN RETURN 'none'; END IF;
  IF v_modules IS NULL OR NOT COALESCE((v_modules->>_module)::boolean, false) THEN
    RETURN 'none';
  END IF;

  IF public.has_role(v_uid, 'admin') THEN RETURN 'full'; END IF;

  SELECT permissions->>_module INTO v_individual
  FROM public.team_members
  WHERE user_id = v_uid AND active = true LIMIT 1;

  RETURN COALESCE(v_individual, 'none');
END;
$function$;