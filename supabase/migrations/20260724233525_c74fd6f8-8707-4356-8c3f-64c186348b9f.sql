
-- 1) Trigger to lock clinic_id on profiles UPDATE
CREATE OR REPLACE FUNCTION public.prevent_clinic_id_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.clinic_id IS DISTINCT FROM OLD.clinic_id THEN
    IF auth.uid() IS NULL OR public.is_superadmin(auth.uid()) THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Alteração de clínica não permitida';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_prevent_clinic_id_change ON public.profiles;
CREATE TRIGGER profiles_prevent_clinic_id_change
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.prevent_clinic_id_change();

-- 2) Superadmin management policies on clinics
CREATE POLICY "Superadmin can insert clinics"
ON public.clinics
FOR INSERT
TO authenticated
WITH CHECK (public.is_superadmin(auth.uid()));

CREATE POLICY "Superadmin can update clinics"
ON public.clinics
FOR UPDATE
TO authenticated
USING (public.is_superadmin(auth.uid()))
WITH CHECK (public.is_superadmin(auth.uid()));

CREATE POLICY "Superadmin can delete clinics"
ON public.clinics
FOR DELETE
TO authenticated
USING (public.is_superadmin(auth.uid()));
