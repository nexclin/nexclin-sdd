-- Regra 005 / FR-013 — a edição de configuração passa a deixar rastro.
--
-- POR QUE ESTA MIGRAÇÃO EXISTE
--
--   A regra 002 deu à clínica uma trilha de auditoria (`data_audit_log`) e a
--   ligou a UMA tabela: `patients`. O escopo era consciente e está escrito lá.
--
--   Só que configuração muda número que o resto do sistema lê. Trocar a taxa de
--   uma forma de pagamento muda o líquido e o vencimento de TODO recebível
--   criado depois; mexer no preço de um serviço muda todo orçamento seguinte;
--   apagar uma conta do plano de contas move lançamento de lugar. Sem rastro,
--   ninguém reconstrói por que os números de duas semanas atrás não batem, e a
--   resposta vira "o sistema está errado".
--
--   É a regra (d) da constituição aplicada onde ela ainda não estava.
--
-- O QUE ESTA MIGRAÇÃO **NÃO** FAZ, E É DELIBERADO
--
--   Não cria função nova. `public.audita_mudanca_de_dado()`, da migração
--   20260825060000, já é genérica: lê `TG_TABLE_NAME`, `clinic_id` e `id`, e
--   serve a qualquer tabela de negócio sem uma linha nova de plpgsql. Escrever
--   uma segunda função seria criar a divergência que a regra 002 evitou.
--
--   Não mexe em policy. As catorze tabelas já têm RLS por `clinic_id`,
--   verificada por varredura em 25/08. Nada aqui altera quem lê o quê.
--
--   Não toca `patients`. O trigger dela continua como está, e o teste
--   `lib/config/__tests__/auditoria.test.ts` guarda isso contra regressão.
--
-- AS TRÊS OPERAÇÕES, INCLUSIVE INSERT
--
--   `previous_state` fica NULL no INSERT, e alguém pode achar que a linha não
--   serve. Serve: ela responde **quem** criou aquela forma de pagamento com 15%
--   de taxa, e **quando**. Auditar só UPDATE e DELETE responde metade da
--   pergunta, que é a mesma razão dada no FR-011 da regra 002.
--
--   Consequência aceita: o onboarding de uma clínica roda os seeds
--   (`seed_chart_of_accounts`, `seed_closing_types`, `seed_native_services`) e
--   escreve algumas dezenas de linhas de INSERT de uma vez. É ruído barato, e
--   tem serventia própria: distingue o que o sistema semeou do que a clínica
--   cadastrou depois.
--
-- IDEMPOTÊNCIA
--
--   Cada trigger é precedido de `DROP TRIGGER IF EXISTS`. Rodar a migração duas
--   vezes não duplica nada e não falha.

-- ---------------------------------------------------------------------------
-- Catálogos: as dez tabelas servidas pela tela genérica de catálogo
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS channels_audita_mudanca ON public.channels;
CREATE TRIGGER channels_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.channels
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS origins_audita_mudanca ON public.origins;
CREATE TRIGGER origins_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.origins
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS objections_audita_mudanca ON public.objections;
CREATE TRIGGER objections_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.objections
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- `services` carrega preço e custo: é a tabela de catálogo cuja alteração mais
-- move dinheiro, porque todo orçamento novo lê daqui.
DROP TRIGGER IF EXISTS services_audita_mudanca ON public.services;
CREATE TRIGGER services_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- `payment_methods` guarda taxa e prazo, e é deles que saem o líquido e o
-- vencimento do recebível. Mudança aqui reverbera no fluxo de caixa inteiro.
DROP TRIGGER IF EXISTS payment_methods_audita_mudanca ON public.payment_methods;
CREATE TRIGGER payment_methods_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.payment_methods
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS expense_categories_audita_mudanca ON public.expense_categories;
CREATE TRIGGER expense_categories_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.expense_categories
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS bank_accounts_audita_mudanca ON public.bank_accounts;
CREATE TRIGGER bank_accounts_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.bank_accounts
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS closing_types_audita_mudanca ON public.closing_types;
CREATE TRIGGER closing_types_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.closing_types
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS consultation_types_audita_mudanca ON public.consultation_types;
CREATE TRIGGER consultation_types_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.consultation_types
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

DROP TRIGGER IF EXISTS acquirers_audita_mudanca ON public.acquirers;
CREATE TRIGGER acquirers_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.acquirers
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- ---------------------------------------------------------------------------
-- As quatro tabelas de configuração com tela própria
-- ---------------------------------------------------------------------------

-- `business_rules` tem uma linha por clínica (`clinic_id` é UNIQUE), então a
-- trilha dela é a história dos parâmetros: quando `confirmation_hours` passou
-- de 24 para 48, e quem mudou. É a tabela que a automação de tarefas obedece.
DROP TRIGGER IF EXISTS business_rules_audita_mudanca ON public.business_rules;
CREATE TRIGGER business_rules_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.business_rules
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- Meta é alvo, e alvo alterado depois do fato reescreve a leitura do mês.
DROP TRIGGER IF EXISTS goals_audita_mudanca ON public.goals;
CREATE TRIGGER goals_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.goals
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- `anamnesis_config` define o que se pergunta ao paciente. Campo removido do
-- modelo não apaga resposta já dada, mas muda o que o próximo formulário colhe,
-- e isso é dado de saúde.
DROP TRIGGER IF EXISTS anamnesis_config_audita_mudanca ON public.anamnesis_config;
CREATE TRIGGER anamnesis_config_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.anamnesis_config
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- O plano de contas é hierárquico: apagar um pai move os filhos e os
-- lançamentos pendurados. `previous_state` guarda `parent_id` e `level`, que é
-- o que permite remontar a árvore de antes.
DROP TRIGGER IF EXISTS chart_of_accounts_audita_mudanca ON public.chart_of_accounts;
CREATE TRIGGER chart_of_accounts_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.chart_of_accounts
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();

-- ---------------------------------------------------------------------------
-- O que continua sem auditoria, e é dívida escrita
-- ---------------------------------------------------------------------------
--
--   Consultas (`appointments`), recebíveis (`receivables`) e as respostas de
--   anamnese (`anamnesis_responses`) seguem sem trigger. É a mesma mecânica e
--   uma migração de dez linhas, mas o escopo pertence às regras desses módulos,
--   e entrar aqui misturaria duas decisões numa migração só.
--
--   A dívida da §7 da regra 006 fica PARCIALMENTE fechada: o suporte, sob
--   impersonação, ainda pode criar um bem ou um insumo indistinguível do que o
--   cliente criou, porque `imobilizado` e `insumos` também não têm trigger. O
--   que muda é que agora, se ele mexer em preço, taxa ou parâmetro, a linha
--   fica gravada com `auth.uid()` dele.
