-- Modelagem INI: Matérias-Primas e Fornecedores, adaptados para clínica.
--
-- # O que isto conserta
--
-- `services.cost` é hoje um número digitado à mão. Ninguém sabe de onde ele
-- veio, e ele nunca é atualizado: a resina subiu 20% e o custo do serviço
-- continua o mesmo de um ano atrás. O preço mínimo calculado em cima dele fica
-- errado sem que nada denuncie.
--
-- Com composição, o custo passa a ser **derivado**: quanto de cada insumo o
-- procedimento consome, vezes o preço atual do insumo.
--
-- # Por que a composição não substitui `services.cost`
--
-- Ela alimenta. `services.cost` continua existindo e continua sendo o que o
-- resto do sistema lê, porque mudar isso obrigaria a reescrever orçamento,
-- fechamento e relatórios de uma vez. A tela mostra o custo composto ao lado do
-- gravado e oferece aplicar.
--
-- Substituir a leitura em toda parte é migração de outra spec. Aqui a conta
-- passa a existir; a decisão de quando gravar continua sendo de quem opera.

-- ---------------------------------------------------------------------------
-- 1. Fornecedores
-- ---------------------------------------------------------------------------

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

-- ---------------------------------------------------------------------------
-- 2. Insumos
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.supplies (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  supplier_id uuid REFERENCES public.suppliers(id) ON DELETE SET NULL,
  name        text NOT NULL DEFAULT '',

  -- A unidade em que o insumo é COMPRADO: caixa, frasco, pacote.
  purchase_unit text NOT NULL DEFAULT 'unidade',
  purchase_cost numeric(12,4) NOT NULL DEFAULT 0,
  -- Quantas unidades de USO vêm na compra. Uma caixa de 100 luvas tem
  -- `purchase_cost` da caixa e `units_per_purchase` igual a 100.
  --
  -- É a coluna que evita o erro mais comum de custeio em clínica: lançar o
  -- preço da caixa como custo do procedimento. Uma caixa de luva de R$ 30 num
  -- procedimento que usa um par viraria R$ 30 de custo em vez de R$ 0,60, e o
  -- preço mínimo sairia cinquenta vezes maior.
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

-- ---------------------------------------------------------------------------
-- 3. A composição: quanto de cada insumo um serviço consome
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.service_supplies (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  service_id  uuid NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  supply_id   uuid NOT NULL REFERENCES public.supplies(id) ON DELETE CASCADE,
  -- Em unidades de USO, não de compra.
  quantity    numeric(12,4) NOT NULL DEFAULT 1,
  created_at  timestamptz NOT NULL DEFAULT now(),

  -- Um insumo aparece uma vez por serviço. Duas linhas do mesmo insumo seriam
  -- somadas em silêncio, e o custo dobraria sem ninguém entender por quê.
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

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
--
--   SELECT to_regclass('public.suppliers')        IS NOT NULL AS tem_fornecedores,
--          to_regclass('public.supplies')         IS NOT NULL AS tem_insumos,
--          to_regclass('public.service_supplies') IS NOT NULL AS tem_composicao;
--
-- Esperado: true nas três. A tela avisa quando faltam, em vez de quebrar.
