-- 024 FASE 1, BLOCO 2 — REVERSÃO, palavra por palavra. Só se o b2 tiver de sair.

DROP FUNCTION IF EXISTS public.tarefas_assumidas_por_membro(timestamptz, timestamptz);

DROP POLICY IF EXISTS "business_rules_select_na_propria_clinica" ON public.business_rules;
DROP POLICY IF EXISTS "business_rules_insert_so_quem_manda" ON public.business_rules;
DROP POLICY IF EXISTS "business_rules_update_so_quem_manda" ON public.business_rules;
CREATE POLICY "Users can manage business_rules in their clinic"
  ON public.business_rules FOR ALL TO authenticated
  USING (clinic_id IN (SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid()));
