DO $$
DECLARE
  v_trial_plan_id uuid;
  v_test_plan_id uuid;
  v_clinic_id uuid := '722cafb8-32b3-45f7-8033-b281038c0ee0';
BEGIN
  SELECT id INTO v_trial_plan_id FROM public.plans WHERE name = 'Trial Padrão' LIMIT 1;
  SELECT id INTO v_test_plan_id FROM public.plans WHERE name = 'Teste CP Bloqueado' LIMIT 1;

  UPDATE public.account_subscriptions
     SET plan_id = v_trial_plan_id,
         status = 'trial',
         trial_start = now(),
         trial_end = now() + interval '14 days',
         cancelled_at = NULL,
         cancel_reason = NULL,
         updated_at = now()
   WHERE clinic_id = v_clinic_id;

  IF v_test_plan_id IS NOT NULL THEN
    UPDATE public.account_subscriptions SET plan_id = v_trial_plan_id, status='trial', updated_at=now()
      WHERE plan_id = v_test_plan_id;
    DELETE FROM public.plans WHERE id = v_test_plan_id;
  END IF;
END$$;