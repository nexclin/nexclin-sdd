-- ===========================================================================
-- 024 FASE 1, BLOCO 1 — REVERSAO. So rodar se b1-conferencia.sql disser FALTA
--   ou se a Fase 2 precisar voltar. Ordem inversa da aplicacao.
-- ===========================================================================
-- CUIDADO: o passo 6 recria a policy FOR ALL de 22/03 no MESMO comando em que
--   apaga as tres novas. Nao parar no meio: entre DROP e CREATE ninguem le
--   tarefa. As linhas de data_audit_log ja gravadas ficam: auditoria nao se
--   apaga.

-- 6. tasks volta a FOR ALL
DROP POLICY IF EXISTS "tasks_select_na_propria_clinica" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_na_propria_clinica" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_na_propria_clinica" ON public.tasks;
CREATE POLICY "Users can manage tasks in their clinic" ON public.tasks FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));

-- 4. pesos
ALTER TABLE public.business_rules DROP COLUMN IF EXISTS task_type_weights;

-- 3. triggers
DROP TRIGGER IF EXISTS tasks_audita_mudanca ON public.tasks;
DROP TRIGGER IF EXISTS appointments_audita_mudanca ON public.appointments;

-- 2. appointments
DROP INDEX IF EXISTS public.appointments_responsible_member_idx;
DROP INDEX IF EXISTS public.appointments_doctor_member_idx;
ALTER TABLE public.appointments
  DROP COLUMN IF EXISTS responsible_member_id,
  DROP COLUMN IF EXISTS doctor_member_id;

-- 1. tasks
DROP INDEX IF EXISTS public.tasks_responsible_member_idx;
ALTER TABLE public.tasks DROP COLUMN IF EXISTS responsible_member_id;
