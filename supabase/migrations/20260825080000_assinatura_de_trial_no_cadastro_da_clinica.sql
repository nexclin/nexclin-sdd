-- EQP-1 · A clínica nova nasce sem assinatura, e por isso o dono não consegue
-- convidar ninguém.
--
-- # O sintoma
--
-- "Ao cadastrar colaboradora e colocar para gerar acesso, deu como não
-- permitido: Sem permissão para convidar na equipe" — bateria de 25/08, e quem
-- recebeu o 403 era o **administrador** da própria clínica.
--
-- # A cadeia, do fim para o começo
--
-- `handle_new_user` cria clínica, perfil, papel `admin`, `team_members` e todos
-- os catálogos de seed. **Não cria linha em `account_subscriptions`.** A única
-- inserção que existe é um bloco de backfill que rodou uma vez, em julho.
--
-- Sem essa linha, `my_permission(_module)` não encontra `enabled_modules`, cai
-- no `RETURN 'none'` e **sai antes** de chegar no `has_role(uid,'admin')` da
-- linha seguinte, que devolveria `'full'`. A edge function `invite-team-user`
-- exige `'full'` e responde 403.
--
-- O botão aparece porque a tela usa a política oposta: `usePermissions.ts` tem
-- `if (!subscriptionState) return true`. **A tela é permissiva e o banco é
-- restritivo** — o usuário vê o botão e leva a recusa.
--
-- # O que esta migração faz, e o que ela deliberadamente não faz
--
-- Faz duas coisas: repara as clínicas que já existem sem assinatura, e cria a
-- assinatura para as próximas, por trigger.
--
-- **Não mexe em `handle_new_user`.** Aquela função é grande, roda em `auth`, e
-- alterá-la na semana do lançamento é risco desproporcional: se ela quebrar,
-- ninguém mais consegue se cadastrar. Um trigger separado em `clinics` alcança
-- o mesmo resultado, é isolado, e desligar é `DROP TRIGGER`.
--
-- NÃO APLICADA POR ESTA SESSÃO. Aplicar exige colagem manual no SQL editor,
-- pelo mesmo motivo registrado em `docs/seguranca/nota-sql-editor-lovable-2026-08-19.md`.

-- ---------------------------------------------------------------------------
-- 1. A função que cria a assinatura de trial
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.cria_assinatura_de_trial()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan_id uuid;
  v_dias    integer;
BEGIN
  -- Idempotente: se a clínica já tem assinatura, não faz nada. Isso permite
  -- rodar a migração duas vezes e permite que `handle_new_user` passe a criar
  -- a assinatura no futuro sem conflitar com este trigger.
  IF EXISTS (SELECT 1 FROM public.account_subscriptions WHERE clinic_id = NEW.id) THEN
    RETURN NEW;
  END IF;

  SELECT trial_default_plan_id, COALESCE(trial_default_days, 14)
    INTO v_plan_id, v_dias
    FROM public.saas_settings
   LIMIT 1;

  -- Sem plano padrão configurado, cai para o plano marcado como trial. Se nem
  -- esse existir, **não** cria assinatura: melhor a clínica nascer sem
  -- assinatura, e o problema aparecer, do que apontar para um plano arbitrário
  -- e a clínica receber um teto de acesso que ninguém escolheu.
  IF v_plan_id IS NULL THEN
    SELECT id INTO v_plan_id
      FROM public.plans
     WHERE is_default_trial = true
     ORDER BY created_at
     LIMIT 1;
  END IF;

  IF v_plan_id IS NULL THEN
    RAISE WARNING 'cria_assinatura_de_trial: nenhum plano de trial configurado; clinica % ficou sem assinatura', NEW.id;
    RETURN NEW;
  END IF;

  INSERT INTO public.account_subscriptions (
    clinic_id, plan_id, status, trial_start, trial_end, started_at
  ) VALUES (
    NEW.id,
    v_plan_id,
    'trial',
    now(),
    now() + make_interval(days => v_dias),
    now()
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.cria_assinatura_de_trial() IS
  'EQP-1: toda clinica nasce com assinatura de trial. Sem ela, my_permission devolve none para o proprio dono e o convite de equipe falha com 403.';

REVOKE ALL ON FUNCTION public.cria_assinatura_de_trial() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS clinics_cria_assinatura_de_trial ON public.clinics;
CREATE TRIGGER clinics_cria_assinatura_de_trial
  AFTER INSERT ON public.clinics
  FOR EACH ROW EXECUTE FUNCTION public.cria_assinatura_de_trial();

-- ---------------------------------------------------------------------------
-- 2. Reparo das clínicas que já existem sem assinatura
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_plan_id uuid;
  v_dias    integer;
  v_reparadas integer;
BEGIN
  SELECT trial_default_plan_id, COALESCE(trial_default_days, 14)
    INTO v_plan_id, v_dias
    FROM public.saas_settings
   LIMIT 1;

  IF v_plan_id IS NULL THEN
    SELECT id INTO v_plan_id FROM public.plans WHERE is_default_trial = true ORDER BY created_at LIMIT 1;
  END IF;

  IF v_plan_id IS NULL THEN
    RAISE WARNING 'Reparo EQP-1 nao executado: nenhum plano de trial configurado.';
    RETURN;
  END IF;

  INSERT INTO public.account_subscriptions (clinic_id, plan_id, status, trial_start, trial_end, started_at)
  SELECT c.id, v_plan_id, 'trial', now(), now() + make_interval(days => v_dias), now()
    FROM public.clinics c
   WHERE NOT EXISTS (SELECT 1 FROM public.account_subscriptions s WHERE s.clinic_id = c.id);

  GET DIAGNOSTICS v_reparadas = ROW_COUNT;
  RAISE NOTICE 'Reparo EQP-1: % clinica(s) receberam assinatura de trial.', v_reparadas;
END $$;

-- ---------------------------------------------------------------------------
-- Conferência, para rodar depois de aplicar
-- ---------------------------------------------------------------------------
--
--   SELECT count(*) AS clinicas_sem_assinatura
--     FROM public.clinics c
--    WHERE NOT EXISTS (SELECT 1 FROM public.account_subscriptions s WHERE s.clinic_id = c.id);
--
-- Esperado: 0.
--
-- E a prova de que o sintoma sumiu, que vale mais: **entrar como o dono de uma
-- clínica e convidar alguém.** Antes desta migração, 403.

-- ---------------------------------------------------------------------------
-- Duas dívidas que este achado revelou, e que NÃO se corrigem aqui
-- ---------------------------------------------------------------------------
--
-- 1. **O dono entra em `team_members` sem `user_id`.** Hoje passa despercebido
--    porque `has_role(admin)` cobre. No dia em que a permissão individual do
--    master for consultada, ela falha em silêncio. Precisa de spec própria.
--
-- 2. **A migração `20260725035822` fixa uma clínica específica num plano
--    chamado "Teste CP Bloqueado", com `contas_pagar: false`.** É artefato de
--    teste dentro da cadeia de migrações da produção. Remover exige saber se
--    aquela clínica ainda existe e o que ela deveria ter. Registrado, não
--    tocado.
