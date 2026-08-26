-- BLOCO 6B, OPCIONAL. Zera também a configuração da clínica.
--
-- # Rode só se a resposta for sim a esta pergunta
--
-- *"O reteste tem de começar com a clínica em branco, configurando serviço,
-- plano de contas e forma de pagamento do zero?"*
--
-- Se a resposta for não, PULE ESTE BLOCO. O Bloco 6 já entrega a base limpa de
-- movimento, com a configuração de pé, que é o cenário mais próximo do que o
-- cliente fundador vai encontrar: ele configura uma vez e opera.
--
-- # O que este bloco leva junto, e é fácil esquecer
--
-- `bank_accounts`, `payment_methods`, `channels`, `origins`, `objections` e
-- `business_rules` são criados pelo cadastro da clínica, não por alguém. Zerar
-- aqui deixa a clínica SEM eles, e o cadastro não roda de novo para repor: ele
-- só dispara quando uma clínica nasce.
--
-- Ou seja: depois deste bloco, ou se cadastra tudo pela tela, ou se cria uma
-- clínica nova do zero. Vale a pena saber disso antes, não depois.
--
-- Por isso as seis primeiras estão comentadas. Descomente com intenção.

TRUNCATE TABLE
  public.services,
  public.consultation_types,
  public.closing_types,
  public.chart_of_accounts,
  public.expense_categories,
  public.fixed_expenses,
  public.acquirers,
  public.anamnesis_config,
  public.goals;

-- Seed do cadastro da clínica. Zerar aqui não repõe sozinho.
-- TRUNCATE TABLE
--   public.bank_accounts,
--   public.payment_methods,
--   public.channels,
--   public.origins,
--   public.objections,
--   public.business_rules;
