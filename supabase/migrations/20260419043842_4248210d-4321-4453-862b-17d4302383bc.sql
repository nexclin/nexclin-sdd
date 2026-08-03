CREATE OR REPLACE FUNCTION public.auto_complete_appointment_task()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status IN ('confirmada', 'compareceu') AND OLD.status = 'agendada' THEN
    UPDATE public.tasks
    SET status = 'concluida', updated_at = now()
    WHERE patient_id = NEW.patient_id
      AND clinic_id = NEW.clinic_id
      AND type = 'confirmar_agendamento'
      AND status = 'pendente';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_auto_complete_appointment_task ON public.appointments;
CREATE TRIGGER trg_auto_complete_appointment_task
AFTER UPDATE ON public.appointments
FOR EACH ROW
EXECUTE FUNCTION public.auto_complete_appointment_task();