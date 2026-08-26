-- Modelagem INI: salas e equipamentos, e a duração que faltava.
--
-- # Por que a duração vem junto, e não é escopo extra
--
-- A pesquisa de mercado lista *"salas, equipamentos e profissionais"* como o
-- trio que a agenda de clínica precisa controlar. O motivo é operacional e
-- direto: marcar dois procedimentos na mesma sala no mesmo horário só é
-- descoberto quando os dois pacientes chegam.
--
-- Só que **conflito é sobreposição de intervalo**, e `appointments` guarda um
-- instante e nada mais. Sem duração não existe intervalo, e sem intervalo não
-- há conflito a detectar. Criar as salas sem a duração daria uma tela bonita
-- que não descobre nada.
--
-- # O efeito colateral que vale tanto quanto
--
-- A tela de Precificação estima a ocupação da agenda multiplicando as consultas
-- realizadas pela duração MÉDIA dos serviços, e diz na cara que é estimativa.
-- Com duração por consulta, ela passa a ser medida. O número que sustenta a
-- hora clínica deixa de ser suposição.

-- ---------------------------------------------------------------------------
-- 1. A duração da consulta
-- ---------------------------------------------------------------------------

-- Trinta minutos é o default de `services.duration_minutes` desde o começo.
-- Repetir o mesmo número aqui é deliberado: dois defaults diferentes para a
-- mesma ideia é como nasce a divergência que ninguém explica depois.
ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS duration_minutes integer NOT NULL DEFAULT 30;

COMMENT ON COLUMN public.appointments.duration_minutes IS
  'Minutos reservados na agenda. Sem isto nao existe intervalo, e sem intervalo nao ha conflito de sala a detectar.';

ALTER TABLE public.appointments
  DROP CONSTRAINT IF EXISTS appointments_duracao_positiva;
ALTER TABLE public.appointments
  ADD CONSTRAINT appointments_duracao_positiva
  CHECK (duration_minutes > 0 AND duration_minutes <= 720);

-- O teto de 12 horas não é preciosismo: duração digitada errada, como 3000 em
-- vez de 30, bloquearia a sala por dois dias e o erro apareceria como "a agenda
-- travou", não como "alguém digitou um zero a mais".

-- ---------------------------------------------------------------------------
-- 2. Salas e equipamentos
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.resources (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  name        text NOT NULL DEFAULT '',

  -- 'sala' e 'equipamento' na mesma tabela, e isso é escolha.
  --
  -- Para a agenda os dois são a mesma coisa: um recurso que só uma consulta usa
  -- por vez. Separar em duas tabelas obrigaria a duplicar a detecção de
  -- conflito, e detecção duplicada é onde uma das cópias fica para trás.
  --
  -- O que muda entre eles é só o rótulo na tela.
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

-- ---------------------------------------------------------------------------
-- 3. Qual consulta usa qual recurso
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.appointment_resources (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id      uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  appointment_id uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  resource_id    uuid NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
  created_at     timestamptz NOT NULL DEFAULT now(),

  -- Um recurso uma vez por consulta. Duas linhas iguais não dariam erro, e
  -- fariam a mesma consulta aparecer duas vezes na linha do tempo da sala.
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

-- ---------------------------------------------------------------------------
-- Por que o conflito NÃO é impedido por constraint
-- ---------------------------------------------------------------------------
--
-- Daria para usar um índice de exclusão com `tstzrange` e `gist`, e o banco
-- recusaria a marcação sobreposta. Deliberadamente não se faz isso aqui, por
-- duas razões:
--
-- 1. **A base atual já tem conflitos.** A duração nasce hoje, e toda consulta
--    existente ganhou 30 minutos de uma vez. Uma constraint só entra se o dado
--    já estiver limpo, e limpar exige antes que alguém VEJA os conflitos.
--
-- 2. **Nem toda sobreposição é erro.** Encaixe, retorno rápido, avaliação
--    enquanto a anestesia age. Barrar no banco obrigaria a clínica a mentir a
--    duração para conseguir marcar, e aí o dado de ocupação vira lixo.
--
-- A tela **mostra** o conflito e deixa a pessoa decidir. Constraint entra depois
-- da base limpa, se entrar, e é decisão de outra spec.

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
--
--   SELECT to_regclass('public.resources') IS NOT NULL AS tem_recursos,
--          EXISTS (SELECT 1 FROM information_schema.columns
--                   WHERE table_schema='public' AND table_name='appointments'
--                     AND column_name='duration_minutes') AS tem_duracao;
--
-- Esperado: true nas duas.
