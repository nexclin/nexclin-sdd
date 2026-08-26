-- Modelagem INI, item 3: o custo da hora clínica.
--
-- Cria as duas tabelas que faltavam para fechar a cadeia de precificação. Tudo
-- o mais já existia: `fixed_expenses` guarda o custo fixo mensal, e `services`
-- já tem `price`, `cost` e `duration_minutes`.
--
-- # A cadeia que isto completa
--
--   custo fixo + depreciação
--   ------------------------  =  hora clínica
--     horas produtivas
--
--   (hora clínica × duração) + insumo
--   ---------------------------------  =  preço mínimo
--   1 − repasse% − imposto% − margem%
--
-- Com isso o sistema deixa de registrar o que a clínica cobrou e passa a dizer
-- se ela devia estar cobrando aquilo.
--
-- # Por que duas tabelas e não colunas em `business_rules`
--
-- `business_rules` é uma linha por clínica com colunas fixas, e várias telas a
-- gravam inteira. Acrescentar colunas ali significaria que uma tela antiga,
-- salvando o objeto que conhece, apagaria os campos novos sem erro nenhum. É o
-- tipo de perda silenciosa que só aparece quando alguém repara que o preço
-- mínimo voltou ao padrão.
--
-- # A aplicação degrada sem esta migração, e isso é deliberado
--
-- A tela funciona antes de ela rodar: sem `pricing_params` usa os padrões e
-- avisa na tela, e sem `assets` a depreciação entra como zero. O número sai
-- **subestimado**, nunca superestimado, que é o lado seguro dos dois.

-- ---------------------------------------------------------------------------
-- 1. Imobilizado
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.assets (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id     uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  description   text NOT NULL DEFAULT '',
  value         numeric(12,2) NOT NULL DEFAULT 0,
  -- Vida útil em ANOS, que é como o contador informa e como a nota fiscal
  -- costuma vir. Converter para meses aqui pouparia uma divisão e obrigaria
  -- quem preenche a fazer a conta de cabeça.
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

-- ---------------------------------------------------------------------------
-- 2. Capacidade e parâmetros de preço
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.pricing_params (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id     uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,

  hours_per_day      numeric(5,2) NOT NULL DEFAULT 8,
  working_days       integer      NOT NULL DEFAULT 21,
  professionals      integer      NOT NULL DEFAULT 1,
  -- Ocupação esperada, de 0 a 1.
  --
  -- É o número que quase ninguém põe na conta, e é o que mais muda o
  -- resultado. Agenda nunca fica 100% cheia: buraco entre pacientes, falta, e
  -- horário que ninguém quer marcar. Dividir o custo por 168 horas quando só
  -- 117 são vendidas subestima a hora clínica em 30%, e a clínica fecha o mês
  -- achando que ganhou.
  occupancy          numeric(4,3) NOT NULL DEFAULT 0.700,

  tax_percent        numeric(6,3) NOT NULL DEFAULT 6,
  payout_percent     numeric(6,3) NOT NULL DEFAULT 30,
  margin_percent     numeric(6,3) NOT NULL DEFAULT 20,

  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  -- Uma linha por clínica. Duas linhas fariam a tela escolher uma por ordem de
  -- leitura, que muda sem aviso.
  UNIQUE (clinic_id),

  CONSTRAINT pricing_params_ocupacao_valida
    CHECK (occupancy > 0 AND occupancy <= 1),
  -- A trava que impede o preço absurdo: se repasse, imposto e margem somarem
  -- 100%, não sobra nada para pagar o custo e o preço mínimo tende ao
  -- infinito. Passando de 100%, a divisão vira negativa e a tela diria que
  -- está tudo bem. O código já trata os dois casos; a constraint impede que o
  -- dado chegue lá.
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

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
--
--   SELECT to_regclass('public.assets')         IS NOT NULL AS tem_assets,
--          to_regclass('public.pricing_params') IS NOT NULL AS tem_params;
--
-- Esperado: true nas duas.
--
-- E a prova que vale mais: abrir a tela de Precificação, cadastrar o aluguel em
-- Custos Fixos, e ver a hora clínica mudar. Antes desta migração ela já
-- aparece, calculada sobre os padrões, e a tela diz que está usando padrões.
