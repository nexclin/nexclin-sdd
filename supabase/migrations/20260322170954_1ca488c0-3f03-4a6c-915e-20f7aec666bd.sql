
-- 1. Create security definer function to get clinic_id without RLS
CREATE OR REPLACE FUNCTION public.get_my_clinic_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid() LIMIT 1
$$;

-- 2. Fix recursive SELECT policy on profiles
DROP POLICY IF EXISTS "Users can view profiles in their clinic" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());
