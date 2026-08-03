
CREATE OR REPLACE FUNCTION public.seed_superadmin_operator()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email = 'erpclinicas@gmail.com' THEN
    INSERT INTO public.superadmin_operators (user_id, name, email, role, active)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', 'Super Owner'), NEW.email, 'super_owner', true)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created_superadmin
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.seed_superadmin_operator();
