
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS completed_at timestamptz;

UPDATE public.tasks SET completed_at = updated_at WHERE status='concluida' AND completed_at IS NULL;

CREATE OR REPLACE FUNCTION public.set_task_completed_at()
RETURNS trigger LANGUAGE plpgsql SET search_path TO 'public' AS $$
BEGIN
  IF NEW.status = 'concluida' AND (OLD.status IS DISTINCT FROM 'concluida') THEN
    NEW.completed_at := now();
  ELSIF NEW.status <> 'concluida' AND OLD.status = 'concluida' THEN
    NEW.completed_at := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_task_completed_at ON public.tasks;
CREATE TRIGGER trg_set_task_completed_at
BEFORE UPDATE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.set_task_completed_at();

CREATE OR REPLACE FUNCTION public.auto_complete_anamnese_task()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  IF NEW.status = 'preenchido' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'preenchido') THEN
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

DROP TRIGGER IF EXISTS trg_auto_complete_anamnese_task_ins ON public.anamnesis_responses;
CREATE TRIGGER trg_auto_complete_anamnese_task_ins
AFTER INSERT ON public.anamnesis_responses
FOR EACH ROW EXECUTE FUNCTION public.auto_complete_anamnese_task();

CREATE OR REPLACE FUNCTION public.auto_complete_appointment_task()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  IF NEW.status IN ('confirmada', 'compareceu') AND OLD.status IS DISTINCT FROM NEW.status THEN
    UPDATE public.tasks
    SET status = 'concluida', updated_at = now()
    WHERE patient_id = NEW.patient_id
      AND clinic_id = NEW.clinic_id
      AND type = 'confirmar_agendamento'
      AND status = 'pendente';
  END IF;
  RETURN NEW;
END;
$$;
