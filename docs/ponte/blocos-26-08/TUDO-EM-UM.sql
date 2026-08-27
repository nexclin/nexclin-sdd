-- =====================================================================
-- AS SEIS MIGRACOES DE 26/08, PARA COLAR DE UMA VEZ
-- =====================================================================
--
-- ARQUIVO GERADO. A fonte de verdade continua sendo supabase/migrations/.
-- Este e so a concatenacao das seis, na ordem, para uma unica colagem.
--
-- E SEGURO RODAR MAIS DE UMA VEZ. Todas usam IF NOT EXISTS ou
-- DROP ... IF EXISTS antes de criar, e nenhuma apaga dado.
--
-- Se parar no meio com erro, me mande a mensagem inteira e rode de novo
-- depois da correcao: o que ja entrou nao entra duas vezes.
-- =====================================================================


-- ---------------------------------------------------------------------
-- BLOCO 1. Linha do tempo da conta
-- origem: 20260826010000_toda_acao_de_superadmin_vira_linha_na_timeline.sql
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.descricao_de_acao_de_superadmin(
  _action text,
  _previous jsonb,
  _new jsonb
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT CASE _action
    WHEN 'impersonation_start' THEN 'Suporte entrou na conta'
    WHEN 'impersonation_end'   THEN 'Suporte saiu da conta'
    WHEN 'profile_edit'        THEN 'Perfil de usuário editado pelo suporte'
    WHEN 'email_change'        THEN
      'E-mail de login alterado de ' ||
      COALESCE(_previous ->> 'email', 'desconhecido') || ' para ' ||
      COALESCE(_new ->> 'email', 'desconhecido')
    WHEN 'password_reset_sent' THEN
      'Reset de senha enviado para ' || COALESCE(_new ->> 'email', 'o usuário')
    ELSE 'Ação do suporte: ' || _action
  END;
$$;

COMMENT ON FUNCTION public.descricao_de_acao_de_superadmin(text, jsonb, jsonb) IS
  'O texto humano da linha do tempo. Separado da trigger porque e a unica parte que muda quando surge uma acao nova.';

CREATE OR REPLACE FUNCTION public.espelha_auditoria_na_timeline()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- `account_timeline.clinic_id` é NOT NULL, e `superadmin_audit_log.clinic_id`
  -- é anulável. Ação sem clínica não tem linha do tempo a que pertencer, e
  -- inventar uma seria pior que não ter: a auditoria continua registrada, que é
  -- o que a regra (d) da constituição exige.
  IF NEW.clinic_id IS NULL THEN
    RETURN NULL;
  END IF;

  INSERT INTO public.account_timeline (
    clinic_id, operator_id, event_type, description, metadata, created_at
  ) VALUES (
    NEW.clinic_id,
    NEW.operator_id,
    NEW.action,
    public.descricao_de_acao_de_superadmin(NEW.action, NEW.previous_state, NEW.new_state),
    jsonb_build_object(
      'audit_log_id',   NEW.id,
      'previous_state', NEW.previous_state,
      'new_state',      NEW.new_state,
      'reason',         NEW.reason
    ),
    NEW.created_at   -- o mesmo instante, para as duas linhas casarem
  );

  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.espelha_auditoria_na_timeline() IS
  'SPEC 003 F1: toda linha de superadmin_audit_log vira uma linha de account_timeline. Trigger e nao funcao de aplicacao, porque a referencia perdeu a segunda linha por esquecimento repetido dos chamadores.';

REVOKE ALL ON FUNCTION public.espelha_auditoria_na_timeline() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS superadmin_audit_log_espelha_timeline ON public.superadmin_audit_log;
CREATE TRIGGER superadmin_audit_log_espelha_timeline
  AFTER INSERT ON public.superadmin_audit_log
  FOR EACH ROW EXECUTE FUNCTION public.espelha_auditoria_na_timeline();

INSERT INTO public.account_timeline (
  clinic_id, operator_id, event_type, description, metadata, created_at
)
SELECT
  a.clinic_id,
  a.operator_id,
  a.action,
  public.descricao_de_acao_de_superadmin(a.action, a.previous_state, a.new_state),
  jsonb_build_object(
    'audit_log_id',   a.id,
    'previous_state', a.previous_state,
    'new_state',      a.new_state,
    'reason',         a.reason,
    'reparo',         true
  ),
  a.created_at
FROM public.superadmin_audit_log a
WHERE a.clinic_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.account_timeline t
     WHERE t.metadata ->> 'audit_log_id' = a.id::text
  );


-- ---------------------------------------------------------------------
-- BLOCO 2. Sessao de suporte com prazo
-- origem: 20260826020000_impersonacao_com_prazo.sql
-- ---------------------------------------------------------------------

ALTER TABLE public.superadmin_impersonation_sessions
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

COMMENT ON COLUMN public.superadmin_impersonation_sessions.expires_at IS
  'Quando a sessao de suporte deixa de valer. Vencida, a ancora do operador e restaurada por encerra_impersonacoes_vencidas().';

ALTER TABLE public.superadmin_impersonation_sessions
  ALTER COLUMN expires_at SET DEFAULT (now() + interval '2 hours');

UPDATE public.superadmin_impersonation_sessions
   SET expires_at = started_at + interval '2 hours'
 WHERE expires_at IS NULL;

CREATE OR REPLACE FUNCTION public.encerra_impersonacoes_vencidas()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sessao record;
  v_encerradas integer := 0;
BEGIN
  FOR v_sessao IN
    SELECT * FROM public.superadmin_impersonation_sessions
     WHERE ended_at IS NULL
       AND expires_at IS NOT NULL
       AND expires_at <= now()
  LOOP
    -- A ordem importa: restaurar a âncora ANTES de fechar a sessão. Se algo
    -- falhar no meio, a sessão continua aberta e o próximo chamador tenta de
    -- novo. Fechando primeiro, uma falha deixaria a âncora trocada sem nenhum
    -- registro aberto apontando para o problema.
    --
    -- `original_clinic_id` pode ser NULL quando o operador não tinha clínica
    -- antes de entrar, e nesse caso NULL é o valor certo a restaurar.
    UPDATE public.profiles
       SET clinic_id = v_sessao.original_clinic_id, updated_at = now()
     WHERE user_id = v_sessao.superadmin_user_id;

    UPDATE public.superadmin_impersonation_sessions
       SET ended_at = now()
     WHERE id = v_sessao.id;

    -- A saída automática é auditada como qualquer outra, e a trigger de
    -- 20260826010000 põe a linha correspondente na linha do tempo da conta
    -- sem que nada aqui precise saber que ela existe.
    INSERT INTO public.superadmin_audit_log (
      operator_id, action, clinic_id, previous_state, new_state, reason
    )
    SELECT
      o.id,
      'impersonation_end',
      v_sessao.target_clinic_id,
      jsonb_build_object('session_id', v_sessao.id, 'started_at', v_sessao.started_at),
      jsonb_build_object('encerrada_por', 'prazo', 'expires_at', v_sessao.expires_at),
      'Sessao de suporte encerrada automaticamente por vencimento do prazo'
    FROM public.superadmin_operators o
    WHERE o.user_id = v_sessao.superadmin_user_id;

    v_encerradas := v_encerradas + 1;
  END LOOP;

  RETURN v_encerradas;
END;
$$;

COMMENT ON FUNCTION public.encerra_impersonacoes_vencidas() IS
  'Restaura a ancora do operador e fecha a sessao de suporte vencida. Restaurar a ancora e o ponto: prazo que so escondesse o banner manteria o acesso.';

REVOKE ALL ON FUNCTION public.encerra_impersonacoes_vencidas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.encerra_impersonacoes_vencidas() TO authenticated;

CREATE OR REPLACE FUNCTION public.get_my_active_impersonation()
RETURNS TABLE (
  id uuid,
  superadmin_user_id uuid,
  target_clinic_id uuid,
  original_clinic_id uuid,
  started_at timestamptz,
  target_clinic_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT s.id, s.superadmin_user_id, s.target_clinic_id, s.original_clinic_id,
         s.started_at, c.name
  FROM public.superadmin_impersonation_sessions s
  JOIN public.clinics c ON c.id = s.target_clinic_id
  WHERE s.superadmin_user_id = auth.uid()
    AND s.ended_at IS NULL
    AND (s.expires_at IS NULL OR s.expires_at > now())
  ORDER BY s.started_at DESC
  LIMIT 1
$$;

REVOKE EXECUTE ON FUNCTION public.get_my_active_impersonation() FROM PUBLIC, anon;


-- ---------------------------------------------------------------------
-- BLOCO 3. Imobilizado e parametros de preco
-- origem: 20260826030000_imobilizado_e_parametros_de_preco.sql
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.assets (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id     uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  description   text NOT NULL DEFAULT '',
  value         numeric(12,2) NOT NULL DEFAULT 0,
  useful_life_years integer NOT NULL DEFAULT 0,
  acquired_at   date,
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.assets IS
  'Bens com depreciacao mensal. Alimenta o custo da hora clinica: equipamento que se desgasta e custo, mesmo que nao saia do caixa no mes.';
COMMENT ON COLUMN public.assets.useful_life_years IS
  'Zero significa NAO DEPRECIA. Bem sem vida util informada fica de fora da conta, o que subestima o custo e e o lado seguro.';

ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clinica gerencia seus bens" ON public.assets;
CREATE POLICY "Clinica gerencia seus bens"
  ON public.assets FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());

ALTER TABLE public.assets
  ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();

CREATE INDEX IF NOT EXISTS assets_clinic_idx ON public.assets (clinic_id) WHERE active;

CREATE TABLE IF NOT EXISTS public.pricing_params (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id     uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,

  hours_per_day      numeric(5,2) NOT NULL DEFAULT 8,
  working_days       integer      NOT NULL DEFAULT 21,
  professionals      integer      NOT NULL DEFAULT 1,
  occupancy          numeric(4,3) NOT NULL DEFAULT 0.700,

  tax_percent        numeric(6,3) NOT NULL DEFAULT 6,
  payout_percent     numeric(6,3) NOT NULL DEFAULT 30,
  margin_percent     numeric(6,3) NOT NULL DEFAULT 20,

  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  UNIQUE (clinic_id),

  CONSTRAINT pricing_params_ocupacao_valida
    CHECK (occupancy > 0 AND occupancy <= 1),
  CONSTRAINT pricing_params_sobra_fatia
    CHECK (tax_percent + payout_percent + margin_percent < 100)
);

COMMENT ON TABLE public.pricing_params IS
  'Capacidade e parametros que transformam custo fixo em preco minimo por procedimento. Uma linha por clinica.';

ALTER TABLE public.pricing_params ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clinica gerencia seus parametros de preco" ON public.pricing_params;
CREATE POLICY "Clinica gerencia seus parametros de preco"
  ON public.pricing_params FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());

ALTER TABLE public.pricing_params
  ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();


-- ---------------------------------------------------------------------
-- BLOCO 4. Informativos
-- origem: 20260826040000_informativos_de_orcamento_e_consentimento.sql
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.budget_notices (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  title       text NOT NULL DEFAULT '',
  body        text NOT NULL DEFAULT '',
  kind        text NOT NULL DEFAULT 'orcamento'
              CHECK (kind IN ('orcamento', 'consentimento', 'recibo')),
  position    integer NOT NULL DEFAULT 1,
  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.budget_notices IS
  'Blocos de texto reutilizaveis em orcamento, termo de consentimento e recibo. Uma fonte so, em vez de um arquivo do Word por recepcionista.';
COMMENT ON COLUMN public.budget_notices.kind IS
  'orcamento | consentimento | recibo. Impede que texto de garantia vaze para o termo de consentimento.';

ALTER TABLE public.budget_notices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clinica gerencia seus informativos" ON public.budget_notices;
CREATE POLICY "Clinica gerencia seus informativos"
  ON public.budget_notices FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());

ALTER TABLE public.budget_notices
  ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();

CREATE INDEX IF NOT EXISTS budget_notices_clinic_kind_idx
  ON public.budget_notices (clinic_id, kind, position) WHERE active;


-- ---------------------------------------------------------------------
-- BLOCO 5. Insumos, fornecedores e composicao
-- origem: 20260826050000_insumos_fornecedores_e_composicao.sql
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.suppliers (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  name        text NOT NULL DEFAULT '',
  contact     text NOT NULL DEFAULT '',
  phone       text NOT NULL DEFAULT '',
  notes       text NOT NULL DEFAULT '',
  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Clinica gerencia seus fornecedores" ON public.suppliers;
CREATE POLICY "Clinica gerencia seus fornecedores"
  ON public.suppliers FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());
ALTER TABLE public.suppliers ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();

CREATE TABLE IF NOT EXISTS public.supplies (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  supplier_id uuid REFERENCES public.suppliers(id) ON DELETE SET NULL,
  name        text NOT NULL DEFAULT '',

  purchase_unit text NOT NULL DEFAULT 'unidade',
  purchase_cost numeric(12,4) NOT NULL DEFAULT 0,
  units_per_purchase numeric(12,4) NOT NULL DEFAULT 1,

  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT supplies_unidades_positivas CHECK (units_per_purchase > 0)
);

COMMENT ON COLUMN public.supplies.units_per_purchase IS
  'Unidades de USO por compra. Caixa de 100 luvas: purchase_cost e da caixa, units_per_purchase e 100. Evita lancar o preco da caixa como custo do procedimento.';

ALTER TABLE public.supplies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Clinica gerencia seus insumos" ON public.supplies;
CREATE POLICY "Clinica gerencia seus insumos"
  ON public.supplies FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());
ALTER TABLE public.supplies ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();

CREATE INDEX IF NOT EXISTS supplies_clinic_idx ON public.supplies (clinic_id) WHERE active;

CREATE TABLE IF NOT EXISTS public.service_supplies (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  service_id  uuid NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  supply_id   uuid NOT NULL REFERENCES public.supplies(id) ON DELETE CASCADE,
  quantity    numeric(12,4) NOT NULL DEFAULT 1,
  created_at  timestamptz NOT NULL DEFAULT now(),

  UNIQUE (service_id, supply_id),
  CONSTRAINT service_supplies_quantidade_positiva CHECK (quantity > 0)
);

ALTER TABLE public.service_supplies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Clinica gerencia a composicao dos servicos" ON public.service_supplies;
CREATE POLICY "Clinica gerencia a composicao dos servicos"
  ON public.service_supplies FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());
ALTER TABLE public.service_supplies ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();

CREATE INDEX IF NOT EXISTS service_supplies_service_idx
  ON public.service_supplies (service_id);


-- ---------------------------------------------------------------------
-- BLOCO 6. Salas, equipamentos e duracao
-- origem: 20260826060000_salas_equipamentos_e_duracao_da_consulta.sql
-- ---------------------------------------------------------------------

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS duration_minutes integer NOT NULL DEFAULT 30;

COMMENT ON COLUMN public.appointments.duration_minutes IS
  'Minutos reservados na agenda. Sem isto nao existe intervalo, e sem intervalo nao ha conflito de sala a detectar.';

ALTER TABLE public.appointments
  DROP CONSTRAINT IF EXISTS appointments_duracao_positiva;
ALTER TABLE public.appointments
  ADD CONSTRAINT appointments_duracao_positiva
  CHECK (duration_minutes > 0 AND duration_minutes <= 720);

CREATE TABLE IF NOT EXISTS public.resources (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  name        text NOT NULL DEFAULT '',

  kind        text NOT NULL DEFAULT 'sala'
              CHECK (kind IN ('sala', 'equipamento')),

  notes       text NOT NULL DEFAULT '',
  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.resources IS
  'Salas e equipamentos. Para a agenda os dois sao a mesma coisa: um recurso que so uma consulta usa por vez.';

ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Clinica gerencia seus recursos" ON public.resources;
CREATE POLICY "Clinica gerencia seus recursos"
  ON public.resources FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());
ALTER TABLE public.resources ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();

CREATE INDEX IF NOT EXISTS resources_clinic_kind_idx
  ON public.resources (clinic_id, kind) WHERE active;

CREATE TABLE IF NOT EXISTS public.appointment_resources (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id      uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  appointment_id uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  resource_id    uuid NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
  created_at     timestamptz NOT NULL DEFAULT now(),

  UNIQUE (appointment_id, resource_id)
);

ALTER TABLE public.appointment_resources ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Clinica gerencia a alocacao de recursos" ON public.appointment_resources;
CREATE POLICY "Clinica gerencia a alocacao de recursos"
  ON public.appointment_resources FOR ALL TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());
ALTER TABLE public.appointment_resources
  ALTER COLUMN clinic_id SET DEFAULT public.get_my_clinic_id();

CREATE INDEX IF NOT EXISTS appointment_resources_resource_idx
  ON public.appointment_resources (resource_id);
CREATE INDEX IF NOT EXISTS appointment_resources_appointment_idx
  ON public.appointment_resources (appointment_id);
