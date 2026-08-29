-- =====================================================================
-- FECHAMENTOS. O que faltava para o financeiro do dashboard sair do zero.
-- =====================================================================
--
-- RODE `2-povoamento.sql` ANTES. Este arquivo depende das consultas que ele
-- cria, e recusa a clinica que nao as tiver.
--
-- POR QUE ELE EXISTE: em 28/08/2026 a base povoada mostrava faturamento,
-- recebimento e despesa corretos, e ao lado disso `FECHAMENTOS 0`, `TAXA DE
-- CONVERSAO 0.0%`, `Ticket Medio R$ 0,00` e as duas listas do dashboard vazias,
-- dizendo "nenhum fechamento e nenhum recebimento no periodo". O `2-povoamento`
-- insere `closing_types`, o CATALOGO, e nunca inseriu fechamento nenhum.
--
-- Isso derrubava justamente o E-01 do Erick, que pediu volume para expor a
-- classe de defeito que so aparece com base cheia. A area que ficou sem
-- exercicio foi a financeira, que e o diferencial de venda do produto.
--
-- O QUE O DASHBOARD LE DE VERDADE, verificado no codigo da plataforma, e nao
-- suposto. Sao DUAS fontes, e por isso este arquivo escreve nas duas:
--
--   1. `Dashboard.tsx` calcula o KPI "Fechamentos" SEM tocar na tabela
--      `closings`. Ele pega consultas com `status = 'compareceu'` e conta as
--      que tem `appointment_items` com `approval_status = 'aprovado'`.
--   2. `useFinancialBreakdown.ts` le `closings` (para `closingsNoPeriodo`),
--      `funnel_2_entries` (para o medico do ranking) e `appointment_items`
--      (para os valores, somando so o que esta aprovado).
--
-- Escrever so em `closings` deixaria o KPI em zero. Escrever so em
-- `appointment_items` deixaria o ticket medio e os rankings em zero. As duas.
--
-- `closings.funnel_2_entry_id` e NOT NULL, entao a cadeia obrigatoria e
-- consulta -> funnel_2_entries -> closings, com os itens pendurados na consulta.
--
-- NAO USA random(), pelo mesmo motivo do `2-povoamento`: todo valor sai de
-- aritmetica sobre o indice da serie, entao rodar de novo depois de limpar
-- produz exatamente a mesma base, e comparar duas execucoes tem sentido.
-- =====================================================================

DO $$
DECLARE
  -- ============ PARAMETROS. Trocar aqui. ============
  nome_alvo         text := 'Clínica Teste Final';
  -- Quantas das consultas que compareceram viram fechamento. 55% deixa a taxa
  -- de conversao num numero que da para conferir de cabeca e nao e 100%, que
  -- esconderia erro no filtro de aprovacao.
  pct_fecha         int  := 55;
  ticket_base       numeric := 1400.00;
  -- =================================================

  alvo          uuid;
  nome_clinica  text;
  medicos       text[] := ARRAY['Dra. Helena Prado', 'Dr. Rafael Nunes', 'Dra. Marina Alves'];
  tipos         text[] := ARRAY['completo', 'parcial', 'completo'];
  r             record;
  i             int := 0;
  n_fechados    int := 0;
  n_itens       int := 0;
  entrada_id    uuid;
  valor         numeric;
  aprova        boolean;
BEGIN
  SELECT id, name INTO alvo, nome_clinica
  FROM public.clinics WHERE name = nome_alvo;

  IF alvo IS NULL THEN
    RAISE EXCEPTION 'Nao existe clinica chamada "%". Nada foi inserido.', nome_alvo;
  END IF;
  IF (SELECT count(*) FROM public.clinics WHERE name = nome_alvo) > 1 THEN
    RAISE EXCEPTION 'Existe mais de uma clinica chamada "%". Nada foi inserido.', nome_alvo;
  END IF;

  -- Idempotencia, pelo mesmo contrato do `2-povoamento`: este arquivo nao apaga
  -- nada, entao rodar duas vezes duplicaria. Recusa em vez de duplicar.
  IF EXISTS (SELECT 1 FROM public.closings WHERE clinic_id = alvo) THEN
    RAISE EXCEPTION 'A clinica % ja tem fechamentos. Limpe-os antes de rodar de novo.', nome_clinica;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.appointments
    WHERE clinic_id = alvo AND status = 'compareceu'
  ) THEN
    RAISE EXCEPTION
      'A clinica % nao tem consulta com status compareceu. Rode 2-povoamento.sql antes.',
      nome_clinica;
  END IF;

  -- Percorre em ordem de data para que a serie seja estavel entre execucoes.
  FOR r IN
    SELECT a.id, a.patient_id, a.doctor, a.date
    FROM public.appointments a
    WHERE a.clinic_id = alvo AND a.status = 'compareceu'
    ORDER BY a.date, a.id
  LOOP
    i := i + 1;

    -- A regra de quem fecha e aritmetica pura sobre o indice: os primeiros
    -- `pct_fecha` de cada bloco de 100 fecham. Sem random, e reproduzivel.
    aprova := (i % 100) <= pct_fecha AND (i % 100) <> 0;

    -- O valor varia em degraus de 50 reais em torno da base, para o ticket
    -- medio nao sair um numero redondo demais e mascarar erro de divisao.
    valor := ticket_base + ((i % 9) - 4) * 50;

    IF aprova THEN
      INSERT INTO public.funnel_2_entries (clinic_id, patient_id, appointment_id, doctor, stage, notes)
      VALUES (
        alvo, r.patient_id, r.id,
        COALESCE(NULLIF(r.doctor, ''), medicos[1 + (i % 3)]),
        'fechado',
        'Povoamento 3-fechamentos'
      )
      RETURNING id INTO entrada_id;

      INSERT INTO public.closings (
        clinic_id, funnel_2_entry_id, patient_id, closing_type,
        closed_value, discount_percent, installments, payment_condition,
        responsible, closed_at, notes
      )
      VALUES (
        alvo, entrada_id, r.patient_id, tipos[1 + (i % 3)],
        valor, (i % 4) * 5, 1 + (i % 6), 'Cartao em ' || (1 + (i % 6))::text || 'x',
        COALESCE(NULLIF(r.doctor, ''), medicos[1 + (i % 3)]),
        r.date + interval '2 hours',
        'Povoamento 3-fechamentos'
      );

      n_fechados := n_fechados + 1;
    END IF;

    -- O item vai em TODA consulta que compareceu, aprovado ou nao. E isso que
    -- faz o filtro `approval_status = 'aprovado'` ter o que descartar: se so
    -- existisse item aprovado, um bug que ignorasse o filtro passaria verde.
    INSERT INTO public.appointment_items (
      clinic_id, appointment_id, description, prescribed_value, sold_value,
      approval_status, notes
    )
    VALUES (
      alvo, r.id,
      CASE (i % 4)
        WHEN 0 THEN 'Plano de acompanhamento'
        WHEN 1 THEN 'Tratamento restaurador'
        WHEN 2 THEN 'Profilaxia e orientacao'
        ELSE 'Avaliacao complementar'
      END,
      valor + 200,
      CASE WHEN aprova THEN valor ELSE 0 END,
      CASE WHEN aprova THEN 'aprovado'
           WHEN (i % 7) = 0 THEN 'reprovado'
           ELSE 'pendente' END,
      'Povoamento 3-fechamentos'
    );

    n_itens := n_itens + 1;
  END LOOP;

  RAISE NOTICE 'Clinica %: % consultas percorridas, % fechamentos, % itens.',
    nome_clinica, i, n_fechados, n_itens;
END $$;
