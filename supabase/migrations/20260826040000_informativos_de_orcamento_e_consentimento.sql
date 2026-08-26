-- Modelagem INI: Informativos de Orçamento, adaptados para clínica.
--
-- No INI são "blocos de texto reutilizáveis (garantia, prazos, política)". Numa
-- clínica o item ganha um uso a mais, e ele é mais importante que os outros:
-- **o termo de consentimento**.
--
-- # Por que o consentimento entra aqui e não numa spec de LGPD
--
-- Ele já é praticado hoje, em papel. A clínica imprime, o paciente assina, e o
-- papel some numa gaveta. O que falta não é a decisão de pedir consentimento; é
-- o texto viver num lugar só, versionado, em vez de num arquivo do Word que
-- cada recepcionista tem uma cópia diferente.
--
-- Isto **não** é assinatura digital com validade jurídica. Assinatura exige
-- certificado e é roadmap (SBIS e CFM, §1 do CLAUDE.md). Aqui o que se resolve
-- é a fonte do texto, que é o degrau anterior e o que hoje está errado.
--
-- # Por que uma tabela e não uma coluna em business_rules
--
-- São vários blocos, com ordem e ativação própria. Uma coluna de texto guardaria
-- um só, e a clínica tem pelo menos três: garantia, política de remarcação e
-- consentimento.

CREATE TABLE IF NOT EXISTS public.budget_notices (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  title       text NOT NULL DEFAULT '',
  body        text NOT NULL DEFAULT '',
  -- 'orcamento' aparece no documento do orçamento.
  -- 'consentimento' é o termo que o paciente assina antes do procedimento.
  -- 'recibo' é o rodapé do recibo.
  --
  -- O tipo existe para o mesmo cadastro servir aos três documentos sem que um
  -- texto de garantia vaze para o termo de consentimento, que é onde erro de
  -- texto vira problema de verdade.
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

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
--
--   SELECT to_regclass('public.budget_notices') IS NOT NULL AS existe;
--
-- Esperado: true. A tela funciona antes disso, mostrando que o cadastro ainda
-- não existe, em vez de quebrar.
