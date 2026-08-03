CREATE OR REPLACE FUNCTION public.clinic_within_user_limit(_clinic_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_max integer;
  v_count integer;
BEGIN
  SELECT p.max_users INTO v_max
  FROM public.account_subscriptions s
  JOIN public.plans p ON p.id = s.plan_id
  WHERE s.clinic_id = _clinic_id
  ORDER BY s.created_at DESC LIMIT 1;

  IF v_max IS NULL THEN RETURN true; END IF;

  SELECT count(*) INTO v_count
  FROM public.team_members
  WHERE clinic_id = _clinic_id AND active = true AND user_id IS NOT NULL;

  -- Trigger é BEFORE INSERT/UPDATE: o novo registro ainda não conta.
  -- Permitimos passar apenas se cabe mais um.
  RETURN v_count < v_max;
END;
$function$;