-- BLOCO 6. Zera o movimento. NÃO TEM VOLTA sem o export do Bloco 0.
--
-- # O que sai
--
-- Tudo que foi LANÇADO durante os testes: paciente, lead, consulta, orçamento,
-- fechamento, recebível, receita, despesa, tarefa, anamnese respondida,
-- insight.
--
-- # O que fica
--
-- Conta, acesso e configuração. Clínica, perfil, equipe, papel, assinatura,
-- plano, e os catálogos (serviço, forma de pagamento, plano de contas,
-- categoria de despesa, conta bancária, canal, origem, objeção, regra de
-- negócio, meta). Ninguém precisa reconfigurar nada para retestar.
--
-- Para começar com a configuração em branco também, existe o Bloco 6B. Ele é
-- separado justamente porque é outra decisão.
--
-- # Por que TRUNCATE e não DELETE
--
-- Três motivos, e o terceiro é o que importa aqui:
--
-- 1. É instantâneo, mesmo com muita linha.
-- 2. Resolve sozinho a ordem entre as tabelas: listadas juntas, as chaves
--    estrangeiras entre elas não atrapalham.
-- 3. **Não dispara trigger de linha.** Com o Bloco 5 já aplicado, um DELETE em
--    `patients` escreveria uma linha de auditoria por paciente apagado, e a
--    trilha nasceria cheia de lixo de teste.
--
-- # Se der erro
--
-- A mensagem vai dizer que alguma tabela de fora aponta para uma daqui. Isso é
-- informação, não acidente: me mande o nome dela em vez de acrescentar
-- CASCADE. CASCADE apagaria essa tabela também, sem perguntar, e ela pode ser
-- uma das que decidimos manter.
--
-- Dando erro, nada foi apagado: o TRUNCATE é uma operação só, e ou faz tudo ou
-- não faz nada.

TRUNCATE TABLE
  public.lead_history,
  public.funnel_2_entries,
  public.appointment_items,
  public.budget_items,
  public.prescriptions,
  public.anamnesis_responses,
  public.receivables,
  public.revenues,
  public.expenses,
  public.closings,
  public.appointments,
  public.budgets,
  public.tasks,
  public.leads,
  public.patients,
  public.ai_insights;
