-- =====================================================================
-- CORRECAO DE VOCABULARIO. So UPDATE, nao apaga nada.
-- =====================================================================
--
-- Por que este arquivo existe em vez de rodar a corrente de novo: a corrente
-- comeca por um expurgo, e a base da Clínica Teste Final acabou de ser gravada
-- e conferida. Trocar duas colunas custa um UPDATE; refazer tudo custa apagar
-- 1.400 linhas boas e gerar numeros de referencia novos outra vez.
--
-- Os dois artefatos foram achados em 29/08/2026 lendo os consumidores dos
-- relatorios, e nao olhando a tela. Sao o sexto e o setimo da mesma familia:
-- inserir direto no banco pula a validacao do formulario.
--
-- ============ ARTEFATO 7: o estagio de funil inventado ============
--
-- O `2-povoamento` escrevia funnel_stage em
-- 'novo','contato','agendado','compareceu','fechado'.
-- O produto NUNCA escreve nenhum desses. Ele escreve exatamente cinco valores,
-- e a lista esta em `Atendimentos.tsx:179-183`:
-- novo_contato, em_atendimento, agendou, nao_agendou, recaptacao.
--
-- Este e o unico artefato que nao se manifesta como numero errado. Ele se
-- manifesta como AUSENCIA, que e mais dificil de notar:
--
--   1. `Dashboard.tsx:330` conta lead com `funnel_stage === 'agendou'`. Como
--      o script escrevia 'agendado', a conta dava zero e o painel mostrava
--      "0% agendam" ao lado de 203 agendamentos. O handoff de 29/08 registrou
--      isso na secao 6 como achado nunca investigado. E isto aqui.
--   2. `Atendimentos.tsx:327` filtra as colunas do funil por
--      `stage.stages.includes(l.funnel_stage)`. Estagio que nao existe nao
--      entra em coluna nenhuma, entao os 240 leads sumiam da tela do funil.
--   3. O Relatorio de Leads resolve o rotulo por `statusMap[funnel_stage]`,
--      nao acha, e cai no valor cru.
--
-- O de-para abaixo preserva a proporcao de um quinto para cada, entao as cinco
-- colunas do funil ficam com conteudo e a conversao de leads da 20%, que nao e
-- nem 0% nem 100%. Numero redondo demais esconde erro de divisao.
--
-- ============ ARTEFATO 8: a tarefa que nunca atrasa ============
--
-- O `2-povoamento` gravava `completed_at` com a MESMA data de `due_date`. O
-- Relatorio de Atividades deriva quatro situacoes em `situacaoDaAtividade`, e
-- a comparacao e `feita <= limite`. Com igualdade sempre verdadeira, a situacao
-- "Realizada fora do prazo" era INALCANCAVEL e a coluna Dias de Atraso ficava
-- sempre vazia.
--
-- Uma base sem atraso nenhum prova que o relatorio nao quebra. Nao prova que
-- ele classifica, que e o criterio do E-01.
--
-- ============ SEGURANCA ============
--
-- Nao ha DELETE aqui. Mira por NOME com INTO STRICT, pelo mesmo motivo do
-- expurgo: nome que nao existe, ou que casa com duas clinicas, para tudo antes
-- de escrever.
-- =====================================================================

DO $$
DECLARE
  -- >>>>>>>>>>>>>>>> TROQUE AQUI, E SO AQUI <<<<<<<<<<<<<<<<
  nome_alvo text := 'Clínica Teste Final';
  -- >>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  alvo uuid;
  nome_clinica text;
  n_leads bigint;
  n_tarefas bigint;
BEGIN
  BEGIN
    SELECT id, name INTO STRICT alvo, nome_clinica
      FROM public.clinics WHERE name = nome_alvo;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'Nao existe clinica chamada "%". Nada foi alterado.', nome_alvo;
    WHEN TOO_MANY_ROWS THEN
      RAISE EXCEPTION 'Existe mais de uma clinica chamada "%". Nada foi alterado.', nome_alvo;
  END;

  RAISE NOTICE 'Corrigindo a clinica: % (%)', nome_clinica, alvo;

  -- 1. O de-para do funil. Idempotente: linha que ja esta no vocabulario certo
  -- nao casa com nenhum WHEN e fica como esta.
  UPDATE public.leads SET
    funnel_stage = CASE funnel_stage
      WHEN 'novo'       THEN 'novo_contato'
      WHEN 'contato'    THEN 'em_atendimento'
      WHEN 'agendado'   THEN 'agendou'
      WHEN 'compareceu' THEN 'nao_agendou'
      WHEN 'fechado'    THEN 'recaptacao'
      ELSE funnel_stage
    END,
    status = CASE funnel_stage
      WHEN 'novo'       THEN 'novo'
      WHEN 'contato'    THEN 'em_atendimento'
      WHEN 'agendado'   THEN 'agendou'
      WHEN 'compareceu' THEN 'nao_agendou'
      WHEN 'fechado'    THEN 'recaptacao'
      ELSE status
    END
  WHERE clinic_id = alvo
    AND funnel_stage IN ('novo','contato','agendado','compareceu','fechado');
  GET DIAGNOSTICS n_leads = ROW_COUNT;
  RAISE NOTICE '  leads remapeados: %', n_leads;

  -- 2. A conclusao das tarefas passa a variar em torno do vencimento, de tres
  -- dias antes a tres depois. Sem random: sai do hash do proprio id, entao
  -- rodar de novo nao muda mais nada, e o WHERE ja exclui o que foi corrigido.
  UPDATE public.tasks
     -- `due_date` e `completed_at` sao TIMESTAMPTZ nesta tabela, e nao DATE.
     -- Postgres nao define timestamptz + integer, so date + integer, entao os
     -- dois lados sao convertidos com `::date` de proposito. A primeira versao
     -- deste arquivo somava direto e falhou com
     -- `operator does not exist: timestamp with time zone + integer`.
     SET completed_at = (due_date::date + ((abs(hashtext(id::text)) % 7) - 3))::date
   WHERE clinic_id = alvo
     AND status = 'concluida'
     AND completed_at IS NOT NULL
     AND completed_at::date = due_date::date;
  GET DIAGNOSTICS n_tarefas = ROW_COUNT;
  RAISE NOTICE '  tarefas com conclusao redistribuida: %', n_tarefas;
END $$;


-- ================== CONFERENCIA: LEIA ESTA SAIDA ==================

WITH c AS (
  SELECT id FROM public.clinics WHERE name = 'Clínica Teste Final'
),
v AS (
  SELECT 1 AS ord, 'artefato 7  lead com estagio invalido' AS verificacao,
         count(*)::text AS valor, '0' AS esperado
    FROM public.leads
   WHERE clinic_id = (SELECT id FROM c)
     AND funnel_stage NOT IN ('novo_contato','em_atendimento','agendou','nao_agendou','recaptacao')

  UNION ALL
  -- E o balde que o dashboard conta precisa ter gente dentro. E dele que sai a
  -- conversao que estava em 0%.
  SELECT 2, 'artefato 7  leads em agendou',
         count(*)::text, '> 0'
    FROM public.leads
   WHERE clinic_id = (SELECT id FROM c) AND funnel_stage = 'agendou'

  UNION ALL
  SELECT 3, 'artefato 8  concluidas COM atraso',
         count(*)::text, '> 0'
    FROM public.tasks
   WHERE clinic_id = (SELECT id FROM c)
     AND status = 'concluida' AND completed_at::date > due_date::date

  UNION ALL
  -- Os dois lados: se TODA tarefa passar a atrasar, a situacao "no prazo" e que
  -- fica inalcancavel, e o defeito so trocou de lado.
  SELECT 4, 'artefato 8  concluidas NO prazo',
         count(*)::text, '> 0'
    FROM public.tasks
   WHERE clinic_id = (SELECT id FROM c)
     AND status = 'concluida' AND completed_at::date <= due_date::date

  UNION ALL
  SELECT 5, 'controle   total de leads (NAO pode mudar)',
         count(*)::text, '> 0'
    FROM public.leads WHERE clinic_id = (SELECT id FROM c)

  UNION ALL
  SELECT 6, 'controle   total de tarefas (NAO pode mudar)',
         count(*)::text, '> 0'
    FROM public.tasks WHERE clinic_id = (SELECT id FROM c)
)
SELECT v.verificacao, v.valor, v.esperado,
       CASE
         WHEN v.esperado = '0'   AND v.valor = '0'  THEN 'OK'
         WHEN v.esperado = '> 0' AND v.valor <> '0' THEN 'OK'
         ELSE 'FALHOU'
       END AS resultado
  FROM v ORDER BY v.ord;
