
-- Trigger: auto-complete anamnese tasks when patient fills in the response
CREATE OR REPLACE FUNCTION public.auto_complete_anamnese_task()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.status = 'preenchido' AND OLD.status <> 'preenchido' THEN
    UPDATE public.tasks
    SET status = 'concluida', updated_at = now()
    WHERE patient_id = NEW.patient_id
      AND clinic_id = NEW.clinic_id
      AND type = 'envio_anamnese'
      AND status = 'pendente';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_complete_anamnese_task
AFTER UPDATE ON public.anamnesis_responses
FOR EACH ROW
EXECUTE FUNCTION public.auto_complete_anamnese_task();
