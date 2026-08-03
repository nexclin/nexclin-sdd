ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS cancellation_reason text DEFAULT '';
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS no_show_reason text DEFAULT '';
ALTER TABLE public.business_rules ADD COLUMN IF NOT EXISTS reschedule_days integer NOT NULL DEFAULT 1;