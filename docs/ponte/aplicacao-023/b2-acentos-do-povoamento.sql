-- =============================================================================
-- ACENTOS DO DADO SEMEADO
-- =============================================================================
-- Achado pelo Arthur em 07/09/2026, abrindo uma tarefa: em Observacoes lia-se
--   "Tarefa gerada pela simulacao", sem acento.
--
-- ONDE ESTA O PROBLEMA, e importa saber: NAO e no codigo. A varredura das
--   telas em 07/09 nao achou UM texto de interface sem acento; todos os
--   resultados eram identificador, chave de enum, nome de arquivo ou rota, com
--   o rotulo visivel acentuado ao lado. O que falta acento e o DADO, escrito
--   pelo nosso proprio povoamento de 27/08, que e ASCII por convencao do
--   projeto para arquivos SQL.
--
-- CONSEQUENCIA QUE ACALMA: clinica de cliente NAO tem estes textos. Eles so
--   existem onde o povoamento rodou, ou seja nas clinicas de teste. Nenhum
--   fundador vera "simulacao" sem acento, porque nenhum fundador tera dado de
--   simulacao.
--
-- Mesmo assim vale corrigir: e nessas clinicas que os socios julgam o produto.
--
-- COMO RODAR: exporte o banco antes. Este bloco ESCREVE, ao contrario dos
--   outros. Ele so troca texto, e nao mexe em valor, data nem status.
-- =============================================================================

BEGIN;

UPDATE public.tasks
   SET description = replace(description, 'simulacao', 'simulação')
 WHERE description LIKE '%simulacao%';

UPDATE public.lead_history
   SET details = replace(details, 'simulacao', 'simulação')
 WHERE details LIKE '%simulacao%';

UPDATE public.appointments
   SET notes = replace(notes, 'Consulta clinica', 'Consulta clínica')
 WHERE notes LIKE '%Consulta clinica%';

-- CONFERENCIA ANTES DE CONFIRMAR. Rode o SELECT abaixo ainda dentro da
--   transacao: `sobraram` tem de vir ZERO nas tres.
--
-- O CONTROLE POSITIVO e a coluna `corrigidas`: se ela vier zero TAMBEM, o
--   UPDATE nao achou nada, e ai ou o texto ja estava certo ou o LIKE errou o
--   alvo. Zero e zero nao prova sucesso, prova que nada aconteceu.
SELECT
  (SELECT count(*) FROM public.tasks         WHERE description LIKE '%simulacao%')      AS sobraram_tarefas,
  (SELECT count(*) FROM public.lead_history  WHERE details     LIKE '%simulacao%')      AS sobraram_leads,
  (SELECT count(*) FROM public.appointments  WHERE notes       LIKE '%Consulta clinica%') AS sobraram_consultas,
  (SELECT count(*) FROM public.tasks         WHERE description LIKE '%simulação%')      AS corrigidas_tarefas;

-- Se os tres `sobraram` vierem zero e `corrigidas_tarefas` vier maior que zero:
COMMIT;
-- Se algo vier diferente do esperado, rode no lugar:
-- ROLLBACK;
