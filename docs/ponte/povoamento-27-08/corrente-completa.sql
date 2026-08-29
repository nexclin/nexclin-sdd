-- =====================================================================
-- A CORRENTE COMPLETA, para a Clínica Teste Final, numa colagem so.
-- =====================================================================
--
-- Montada em 28/08/2026 depois de duas falhas seguidas, e cada uma ensinou
-- uma coisa que esta corrigida aqui.
--
-- FALHA 1: o `3-fechamentos` recusou a clinica dizendo que ela nao tinha
-- consulta com status compareceu. Era a trava dele funcionando, porque o
-- povoamento ainda nao havia rodado.
--
-- FALHA 2: o povoamento estourou com
-- `duplicate key value violates unique constraint "goals_clinic_id_month_year_key"`.
-- A clinica ja tinha meta de julho de 2026, e a trava do povoamento so olha
-- paciente, entao nao pegou. A insercao de metas foi endurecida com
-- ON CONFLICT DO UPDATE, mas isso trata UMA tabela.
--
-- O QUE AS DUAS FALHAS REVELARAM: o povoamento pressupoe clinica EXPURGADA.
-- Das vinte insercoes dele, dezoito nao tratam conflito, e as que caem em
-- tabela sem restricao unica DUPLICAM EM SILENCIO, que e pior que estourar.
-- A Clínica Teste Final nunca foi expurgada, entao ainda tem os catalogos que
-- `semear_clinica` criou no nascimento dela: canais, origens, tipos de
-- fechamento, contas bancarias e servicos. Sem o expurgo, tudo isso duplica.
--
-- ============ A ORDEM, E POR QUE ELA E ESTA ============
--
--   1. EXPURGO       apaga o conteudo da clinica, catalogos inclusive.
--   2. POVOAMENTO    cria pacientes, leads, consultas e os catalogos de novo.
--   3. FECHAMENTOS   pendura fechamento nas consultas que compareceram.
--   4. SEMEAR        devolve o que o expurgo levou e o povoamento nao recria.
--
-- O passo 4 nao e enfeite, e a ausencia dele foi o V-24. O expurgo apaga
-- `chart_of_accounts`, e o povoamento NAO o recria. Foi assim que a conta
-- mestra ficou com um plano de contas de UM no, e o lancamento de despesa
-- passou a recusar tudo com "Nenhuma conta analitica disponivel". Sem o
-- passo 4, a Clínica Teste Final termina com o mesmo defeito.
--
-- E o passo 4 vem DEPOIS do 2, e nao antes, para nao duplicar: `semear_clinica`
-- so preenche o que esta faltando, entao rodando no fim ela ve canais, tipos de
-- fechamento e contas bancarias ja criados pelo povoamento e os pula, e cria so
-- o que ninguem criou, que e o plano de contas e as regras de negocio.
--
-- ============ SEGURANCA ============
--
-- O passo 1 APAGA. Ele mira por NOME, conferivel a olho, com INTO STRICT: nome
-- que nao existe, ou que casa com duas clinicas, para tudo antes de apagar. Ele
-- nao toca na clinica em si, nos perfis, na equipe, na assinatura nem nos
-- papeis. A conta continua existindo e continua logando.
--
-- ALVO: Clínica Teste Final, `d51ce6c7-582b-469b-a01b-608bd9b38885`.
-- Confira este nome antes de rodar.
--
-- Para provar sem gravar, use `corrente-completa-teste-de-sintaxe.sql`, que e
-- este conteudo dentro de BEGIN e ROLLBACK. Ele exercita a cadeia inteira,
-- inclusive o passo 3 achando as consultas que o passo 2 acabou de criar, e
-- desfaz tudo no fim.
-- =====================================================================


-- ================== PASSO 1 de 4: EXPURGO (APAGA) ==================

-- =====================================================================
-- EXPURGO. Apaga TODO o dado de operacao de UMA clinica.
-- =====================================================================
--
-- Este arquivo existe antes do povoamento de proposito, e a razao esta em
-- ../../historico/2026-08-27-triagem-erick.md, item E-01: o banco da Lovable
-- migra intacto em outubro, entao dado de simulacao sem expurgo escrito nao
-- e descartado na migracao, e importado.
--
-- O QUE ELE APAGA: paciente, lead, consulta, orcamento, receita, recebivel,
-- despesa, tarefa, meta, insumo, sala, imobilizado e os catalogos, tudo
-- filtrado por clinic_id.
--
-- O QUE ELE NAO TOCA, e isto e o que o torna seguro de rodar: a propria
-- clinica, os perfis, os membros de equipe, a assinatura e os papeis. A conta
-- continua existindo e continua logando. So o conteudo some.
--
-- COMO USAR: troque o NOME da clinica na linha do `nome_alvo`, rode, e leia o
-- aviso com a contagem por tabela.
--
-- Por que nome e nao UUID: a versao anterior pedia um UUID colado a mao, e
-- UUID copiado errado num script que apaga dado apaga a clinica errada. O
-- nome e conferivel a olho. A busca e exata e usa INTO STRICT, entao nome que
-- nao existe ou que casa com duas clinicas para tudo antes de apagar.
--
-- Para ver os nomes:
--   select name, created_at from public.clinics order by created_at;
-- =====================================================================

DO $$
DECLARE
  -- >>>>>>>>>>>>>>>> TROQUE AQUI, E SO AQUI <<<<<<<<<<<<<<<<
  nome_alvo text := 'Clínica Teste Final';
  -- >>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  alvo uuid;
  nome_da_clinica text;
  t text;
  n bigint;
  total bigint := 0;

  -- Ordem obrigatoria: filho antes de pai. Trocar a ordem produz erro de
  -- chave estrangeira, e o erro diz qual tabela, entao e recuperavel; mas a
  -- ordem certa evita a ida e volta.
  tabelas text[] := ARRAY[
    'lead_history',
    'appointment_items',
    'appointment_resources',
    'budget_items',
    'budgets',
    'prescriptions',
    'receivables',
    'revenues',
    'expenses',
    'fixed_expenses',
    'tasks',
    'closings',
    'ai_insights',
    'anamnesis_responses',
    'appointments',
    'leads',
    'patients',
    'goals',
    'service_supplies',
    'supplies',
    'suppliers',
    'assets',
    'pricing_params',
    'resources',
    'budget_notices',
    'services',
    'consultation_types',
    'closing_types',
    'origins',
    'channels',
    'objections',
    'payment_methods',
    'acquirers',
    'expense_categories',
    'chart_of_accounts',
    'bank_accounts',
    'business_rules',
    'anamnesis_config'
  ];
  -- Estas tabelas fazem parte do ESQUELETO que `handle_new_user` cria junto com
  -- a clinica, e nao de dado de operacao. Elas continuam sendo apagadas acima,
  -- porque simulacao suja o catalogo tambem, mas o esqueleto e RECRIADO no fim,
  -- por `semear_clinica`.
  --
  -- Isto foi aprendido errando em 27/08. A primeira versao apagava e nao
  -- recriava, e a clinica ficava num estado em que nenhuma clinica real nasce:
  -- sem `business_rules`, sem plano de contas, sem forma de pagamento. O
  -- sintoma foi o onboarding travar no passo 2 para sempre.
BEGIN
  -- INTO STRICT: zero linhas e mais de uma linha viram excecao. E o que
  -- garante que um nome ambiguo pare aqui, e nao apague duas clinicas.
  BEGIN
    SELECT id, name INTO STRICT alvo, nome_da_clinica
      FROM public.clinics WHERE name = nome_alvo;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'Nao existe clinica chamada "%". Nada foi apagado.', nome_alvo;
    WHEN TOO_MANY_ROWS THEN
      RAISE EXCEPTION 'Existe mais de uma clinica chamada "%". Nada foi apagado.', nome_alvo;
  END;

  RAISE NOTICE 'Expurgando a clinica: % (%)', nome_da_clinica, alvo;

  FOREACH t IN ARRAY tabelas LOOP
    -- A tabela pode nao existir: as seis migracoes de 26/08 entraram, mas o
    -- script precisa continuar valendo em um banco que esteja atras disso.
    IF to_regclass('public.' || t) IS NULL THEN
      RAISE NOTICE '  % : tabela nao existe, pulando', t;
      CONTINUE;
    END IF;

    EXECUTE format('DELETE FROM public.%I WHERE clinic_id = $1', t) USING alvo;
    GET DIAGNOSTICS n = ROW_COUNT;
    total := total + n;
    IF n > 0 THEN
      RAISE NOTICE '  % : % linhas', t, n;
    END IF;
  END LOOP;

  RAISE NOTICE 'Total apagado: % linhas. Clinica, perfis, equipe e assinatura intactos.', total;

  -- Recompoe o esqueleto. Sem isto a clinica fica pior que nova, e o onboarding
  -- nao tem como ser concluido. Ver a migracao 20260827020000.
  IF to_regclass('public.clinics') IS NOT NULL
     AND EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
                  WHERE n.nspname = 'public' AND p.proname = 'semear_clinica') THEN
    PERFORM public.semear_clinica(alvo);
    RAISE NOTICE 'Esqueleto recriado: regras, plano de contas, catalogos e conta caixa.';
  ELSE
    RAISE WARNING 'A funcao semear_clinica NAO existe. Aplique a migracao 20260827020000 e rode-a para esta clinica, senao o onboarding trava no passo 2.';
  END IF;
END $$;

-- Conferencia. Rode junto, e troque o nome no `WHERE c.name` se trocou acima.
-- Tudo tem de voltar zero, menos `team_members`, que nao e apagado de proposito.
WITH c AS (SELECT id FROM public.clinics WHERE name = 'NexClin')
SELECT 'patients' AS tabela, count(*) FROM public.patients     WHERE clinic_id = (SELECT id FROM c)
UNION ALL SELECT 'appointments',  count(*) FROM public.appointments  WHERE clinic_id = (SELECT id FROM c)
UNION ALL SELECT 'receivables',   count(*) FROM public.receivables   WHERE clinic_id = (SELECT id FROM c)
UNION ALL SELECT 'expenses',      count(*) FROM public.expenses      WHERE clinic_id = (SELECT id FROM c)
UNION ALL SELECT 'team_members (NAO deve zerar)', count(*) FROM public.team_members WHERE clinic_id = (SELECT id FROM c);


-- ================== PASSO 2 de 4: POVOAMENTO ==================

-- =====================================================================
-- POVOAMENTO. Dois meses de operacao simulada, em UMA clinica.
-- =====================================================================
--
-- Pedido pelo Erick (E-01): base vazia esconde a classe de defeito que so
-- aparece com volume, e ele nomeia tres, paginacao, espaco de tela e
-- relatorio que nao fecha com o que foi lancado.
--
-- RODE `1-expurgo.sql` ANTES. Este arquivo nao apaga nada, entao rodar duas
-- vezes duplica tudo.
--
-- Os numeros do porte estao na secao de parametros e sao para trocar. O
-- padrao simula faturamento na faixa que o Erick citou, entre 200 e 300 mil
-- em dois meses, com ticket medio proximo de R$ 1.400.
--
-- NAO USA random(). Todo valor sai de aritmetica sobre o indice da serie,
-- entao rodar de novo depois do expurgo produz exatamente a mesma base, e
-- comparar duas execucoes tem sentido.
-- =====================================================================

DO $$
DECLARE
  -- ============ PARAMETROS. Trocar aqui. ============
  -- O nome exato da clinica, o mesmo que voce usou no expurgo.
  nome_alvo        text := 'Clínica Teste Final';
  qtd_pacientes    int  := 180;
  qtd_leads        int  := 240;
  qtd_consultas    int  := 420;   -- nos dois meses
  ticket_base      numeric := 1400.00;
  primeiro_dia     date := (date_trunc('month', current_date) - interval '1 month')::date;
  -- =================================================

  ultimo_dia   date := (date_trunc('month', current_date) + interval '1 month - 1 day')::date;
  alvo         uuid;
  nome_clinica text;

  -- ids de catalogo, preenchidos ao longo do bloco
  origem_ids   uuid[];
  canal_ids    uuid[];
  objecao_ids  uuid[];
  tipo_ids     uuid[];
  fecha_ids    uuid[];
  pag_ids      uuid[];
  conta_id     uuid;
  categoria_ids uuid[];
  servico_ids  uuid[];
  forn_ids     uuid[];
  insumo_ids   uuid[];


BEGIN
  BEGIN
    SELECT id, name INTO STRICT alvo, nome_clinica
      FROM public.clinics WHERE name = nome_alvo;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'Nao existe clinica chamada "%". Nada foi inserido.', nome_alvo;
    WHEN TOO_MANY_ROWS THEN
      RAISE EXCEPTION 'Existe mais de uma clinica chamada "%". Nada foi inserido.', nome_alvo;
  END;

  IF EXISTS (SELECT 1 FROM public.patients WHERE clinic_id = alvo) THEN
    RAISE EXCEPTION 'A clinica % ja tem pacientes. Rode 1-expurgo.sql antes.', nome_clinica;
  END IF;

  RAISE NOTICE 'Povoando % de % a %', nome_clinica, primeiro_dia, ultimo_dia;

  -- ---------------------------------------------------------------
  -- 1. CATALOGOS
  -- ---------------------------------------------------------------
  INSERT INTO public.origins (clinic_id, name, active)
  SELECT alvo, x, true FROM unnest(ARRAY['Instagram','Indicacao','Google','Fachada','WhatsApp','Convenio']) x;
  SELECT array_agg(id ORDER BY name) INTO origem_ids FROM public.origins WHERE clinic_id = alvo;

  INSERT INTO public.channels (clinic_id, name, active)
  SELECT alvo, x, true FROM unnest(ARRAY['WhatsApp','Telefone','Presencial','Direct','E-mail']) x;
  SELECT array_agg(id ORDER BY name) INTO canal_ids FROM public.channels WHERE clinic_id = alvo;

  INSERT INTO public.objections (clinic_id, name, active)
  SELECT alvo, x, true FROM unnest(ARRAY['Preco','Vai pensar','Sem tempo','Consultou concorrente','Sem interesse']) x;
  SELECT array_agg(id ORDER BY name) INTO objecao_ids FROM public.objections WHERE clinic_id = alvo;

  INSERT INTO public.consultation_types (clinic_id, name, price, active) VALUES
    (alvo, 'Primeira consulta', 350, true),
    (alvo, 'Retorno',           180, true),
    (alvo, 'Avaliacao',         250, true),
    (alvo, 'Procedimento',      900, true);
  SELECT array_agg(id ORDER BY name) INTO tipo_ids FROM public.consultation_types WHERE clinic_id = alvo;

  INSERT INTO public.closing_types (clinic_id, name, active, is_system)
  SELECT alvo, x, true, false FROM unnest(ARRAY['A vista','Parcelado','Convenio','Pacote']) x;
  SELECT array_agg(id ORDER BY name) INTO fecha_ids FROM public.closing_types WHERE clinic_id = alvo;

  INSERT INTO public.bank_accounts (clinic_id, bank_name, bank_code, agency, account, account_type, opening_balance, opening_date, active, is_system)
  VALUES (alvo, 'Banco do Brasil', '001', '1234-5', '98765-4', 'corrente', 25000, primeiro_dia, true, false)
  RETURNING id INTO conta_id;

  INSERT INTO public.payment_methods (clinic_id, name, type, default_fee_percent, payment_term_days, active) VALUES
    (alvo, 'Dinheiro',        'dinheiro', 0,    0,  true),
    (alvo, 'PIX',             'pix',      0,    0,  true),
    (alvo, 'Debito',          'debito',   1.99, 1,  true),
    (alvo, 'Credito a vista', 'credito',  3.49, 30, true),
    (alvo, 'Credito 3x',      'credito',  4.60, 30, true);
  SELECT array_agg(id ORDER BY name) INTO pag_ids FROM public.payment_methods WHERE clinic_id = alvo;

  INSERT INTO public.expense_categories (clinic_id, name, cost_center, subcategory, active) VALUES
    (alvo, 'Aluguel',            'Estrutura',   'Fixo',      true),
    (alvo, 'Folha e encargos',   'Pessoal',     'Fixo',      true),
    (alvo, 'Material de consumo','Operacional', 'Variavel',  true),
    (alvo, 'Marketing',          'Comercial',   'Variavel',  true),
    (alvo, 'Energia e agua',     'Estrutura',   'Fixo',      true),
    (alvo, 'Software e sistemas','Estrutura',   'Fixo',      true),
    (alvo, 'Impostos',           'Financeiro',  'Variavel',  true);
  SELECT array_agg(id ORDER BY name) INTO categoria_ids FROM public.expense_categories WHERE clinic_id = alvo;

  INSERT INTO public.services (clinic_id, name, category, macro_category, price, direct_cost, duration_minutes, active) VALUES
    (alvo, 'Consulta clinica',        'Consulta',      'Servicos', 350,  40,  30, true),
    (alvo, 'Retorno',                 'Consulta',      'Servicos', 180,  20,  20, true),
    (alvo, 'Avaliacao completa',      'Consulta',      'Servicos', 250,  30,  40, true),
    (alvo, 'Procedimento estetico',   'Procedimento',  'Servicos', 1200, 320, 60, true),
    (alvo, 'Aplicacao de toxina',     'Procedimento',  'Servicos', 1800, 520, 45, true),
    (alvo, 'Preenchimento',           'Procedimento',  'Servicos', 2200, 780, 60, true),
    (alvo, 'Limpeza de pele',         'Procedimento',  'Servicos', 320,  60,  50, true),
    (alvo, 'Pacote 4 sessoes',        'Pacote',        'Servicos', 3600, 900, 60, true);
  SELECT array_agg(id ORDER BY name) INTO servico_ids FROM public.services WHERE clinic_id = alvo;

  -- ---------------------------------------------------------------
  -- 2. PACIENTES
  -- ---------------------------------------------------------------
  INSERT INTO public.patients (clinic_id, name, phone, email, birth_date, gender, city, state, profession, origin_id, channel_id, is_first_visit, created_at)
  SELECT
    alvo,
    (ARRAY['Ana','Bruno','Carla','Diego','Elisa','Fabio','Gabriela','Henrique','Isabela','Joao',
           'Karina','Lucas','Mariana','Nelson','Olivia','Paulo','Renata','Sergio','Tatiana','Vitor'])[1 + (g % 20)]
      || ' ' ||
    (ARRAY['Silva','Souza','Costa','Pereira','Almeida','Rodrigues','Martins','Barbosa','Ribeiro','Carvalho',
           'Gomes','Lima','Araujo','Fernandes','Melo'])[1 + (g % 15)],
    '(11) 9' || lpad(((g * 7919) % 100000000)::text, 8, '0'),
    'paciente' || g || '@exemplo.com.br',
    (date '1960-01-01' + ((g * 137) % 16000))::date,
    CASE WHEN g % 2 = 0 THEN 'feminino' ELSE 'masculino' END,
    (ARRAY['Sao Paulo','Campinas','Santo Andre','Guarulhos','Osasco'])[1 + (g % 5)],
    'SP',
    (ARRAY['Advogado','Professor','Engenheiro','Autonomo','Comerciante','Aposentado'])[1 + (g % 6)],
    origem_ids[1 + (g % array_length(origem_ids, 1))],
    canal_ids[1 + (g % array_length(canal_ids, 1))],
    (g % 3 = 0),
    primeiro_dia + ((g * 3) % 60) * interval '1 day'
  FROM generate_series(1, qtd_pacientes) g;

  RAISE NOTICE '  pacientes: %', qtd_pacientes;

  -- ---------------------------------------------------------------
  -- 3. LEADS, com o funil distribuido
  -- ---------------------------------------------------------------
  INSERT INTO public.leads (clinic_id, name, phone, email, funnel_stage, status, interest, origin_id, channel_id, objection_id, responsible, appointment_date, created_at)
  SELECT
    alvo,
    (ARRAY['Adriana','Bernardo','Cecilia','Daniel','Eduarda','Felipe','Giovana','Heitor','Iara','Julio',
           'Larissa','Marcelo','Natalia','Otavio','Priscila','Rafael','Sabrina','Thiago','Ursula','Wagner'])[1 + (g % 20)]
      || ' ' ||
    (ARRAY['Antunes','Braga','Cardoso','Dias','Esteves','Freitas','Guimaraes','Henriques','Ipolito','Junqueira'])[1 + (g % 10)],
    '(11) 9' || lpad(((g * 6421) % 100000000)::text, 8, '0'),
    'lead' || g || '@exemplo.com.br',
    (ARRAY['novo','contato','agendado','compareceu','fechado'])[1 + (g % 5)],
    (ARRAY['novo','agendou','nao_agendou','recaptacao','agendou'])[1 + (g % 5)],
    (ARRAY['Botox','Preenchimento','Consulta','Limpeza de pele','Pacote'])[1 + (g % 5)],
    origem_ids[1 + (g % array_length(origem_ids, 1))],
    canal_ids[1 + (g % array_length(canal_ids, 1))],
    CASE WHEN g % 5 = 2 THEN objecao_ids[1 + (g % array_length(objecao_ids, 1))] ELSE NULL END,
    (ARRAY['Recepcao','Comercial','Dra. Marina'])[1 + (g % 3)],
    CASE WHEN g % 5 IN (2,3,4) THEN (primeiro_dia + ((g * 2) % 60) * interval '1 day')::date ELSE NULL END,
    primeiro_dia + ((g * 2) % 60) * interval '1 day'
  FROM generate_series(1, qtd_leads) g;

  INSERT INTO public.lead_history (clinic_id, lead_id, action, details, created_at)
  SELECT alvo, l.id, 'criado', 'Lead registrado pela simulacao', l.created_at
  FROM public.leads l WHERE l.clinic_id = alvo;

  RAISE NOTICE '  leads: % (mais historico)', qtd_leads;

  -- ---------------------------------------------------------------
  -- 4. CONSULTAS
  -- ---------------------------------------------------------------
  -- O status segue uma distribuicao de clinica real: cerca de 20% de falta,
  -- que e a faixa que a triagem do Vinicius citou e que nao aparecia em
  -- lugar nenhum do sistema antes da modelagem.
  INSERT INTO public.appointments
    (clinic_id, patient_id, date, status, approval_status, consultation_type_id, closing_type_id,
     doctor, responsible, sold_value, prescribed_value, deposit_value, has_prescription, duration_minutes, notes, created_at)
  SELECT
    alvo,
    p.id,
    (primeiro_dia + ((g * 11) % 60) * interval '1 day' + ((8 + (g % 9)) * interval '1 hour')),
    CASE
      WHEN (primeiro_dia + ((g * 11) % 60)) > current_date THEN
        (ARRAY['agendada','confirmada'])[1 + (g % 2)]
      ELSE
        (ARRAY['compareceu','compareceu','compareceu','compareceu','nao_compareceu','cancelada'])[1 + (g % 6)]
    END,
    CASE WHEN g % 4 = 0 THEN 'pendente' ELSE 'aprovado' END,
    tipo_ids[1 + (g % array_length(tipo_ids, 1))],
    fecha_ids[1 + (g % array_length(fecha_ids, 1))],
    (ARRAY['Dra. Marina Alves','Dr. Rodrigo Pinto','Dra. Helena Castro'])[1 + (g % 3)],
    (ARRAY['Recepcao','Comercial'])[1 + (g % 2)],
    round((ticket_base * (0.5 + ((g % 17)::numeric / 10)))::numeric, 2),
    round((ticket_base * (0.8 + ((g % 23)::numeric / 10)))::numeric, 2),
    CASE WHEN g % 6 = 0 THEN 200 ELSE 0 END,
    (g % 3 <> 0),
    (ARRAY[30, 30, 45, 60, 20])[1 + (g % 5)],
    CASE WHEN g % 9 = 0 THEN 'Paciente remarcou uma vez' ELSE NULL END,
    primeiro_dia + ((g * 11) % 60) * interval '1 day'
  FROM generate_series(1, qtd_consultas) g
  JOIN LATERAL (
    SELECT id FROM public.patients
     WHERE clinic_id = alvo
     ORDER BY created_at, id
     OFFSET (g % qtd_pacientes) LIMIT 1
  ) p ON true;

  RAISE NOTICE '  consultas: %', qtd_consultas;

  -- ---------------------------------------------------------------
  -- 5. ORCAMENTOS, com itens
  -- ---------------------------------------------------------------
  INSERT INTO public.budgets (clinic_id, patient_id, appointment_id, status, prescribed_value, closed_value, closed_at, responsible, created_at)
  SELECT alvo, a.patient_id, a.id,
         CASE WHEN row_number() OVER (ORDER BY a.date) % 3 = 0 THEN 'aprovado' ELSE 'orcado' END,
         a.prescribed_value,
         CASE WHEN row_number() OVER (ORDER BY a.date) % 3 = 0 THEN a.sold_value ELSE 0 END,
         CASE WHEN row_number() OVER (ORDER BY a.date) % 3 = 0 THEN a.date ELSE NULL END,
         a.responsible, a.created_at
  FROM public.appointments a
  WHERE a.clinic_id = alvo AND a.has_prescription;

  INSERT INTO public.budget_items (clinic_id, budget_id, service_id, item, category, macro_category, quantity, unit_price, total, closed_value, status)
  SELECT alvo, b.id, s.id, s.name, s.category, s.macro_category, 1, s.price, s.price,
         CASE WHEN b.status = 'aprovado' THEN s.price ELSE 0 END,
         b.status
  FROM public.budgets b
  JOIN LATERAL (
    SELECT id, name, category, macro_category, price FROM public.services
     WHERE clinic_id = alvo ORDER BY name
     OFFSET (abs(hashtext(b.id::text)) % 8) LIMIT 1
  ) s ON true
  WHERE b.clinic_id = alvo;

  RAISE NOTICE '  orcamentos e itens inseridos';

  -- ---------------------------------------------------------------
  -- 6. RECEITAS e RECEBIVEIS
  -- ---------------------------------------------------------------
  INSERT INTO public.revenues (clinic_id, patient_id, item, category, macro_category, gross_value, net_value, quantity, revenue_date, payment_method_id, fee_percent)
  SELECT alvo, a.patient_id, 'Atendimento', 'Consulta', 'Servicos',
         a.sold_value,
         round(a.sold_value * 0.965, 2),
         1, a.date::date,
         pag_ids[1 + (abs(hashtext(a.id::text)) % array_length(pag_ids, 1))],
         3.49
  FROM public.appointments a
  WHERE a.clinic_id = alvo AND a.status = 'compareceu';

  -- As datas de vencimento sao espalhadas de proposito para a regua de
  -- cobranca ter as cinco faixas povoadas: a vencer, vencido em 1 a 7, em 8
  -- a 15, em 16 a 30, e mais de 30. Sem isso a tela de cobranca nasce vazia
  -- e nao da para conferir nada nela.
  INSERT INTO public.receivables
    (clinic_id, patient_id, appointment_id, description, item, category, macro_category,
     value, gross_value, net_value, due_date, status, paid_at, payment_type, quantity,
     payment_method_id, bank_account_id, installment_number, total_installments, fee_percent, conciliated)
  SELECT alvo, a.patient_id, a.id,
         'Atendimento de ' || to_char(a.date, 'DD/MM'),
         'Atendimento', 'Consulta', 'Servicos',
         a.sold_value, a.sold_value, round(a.sold_value * 0.965, 2),
         (a.date::date + ((abs(hashtext(a.id::text)) % 75) - 30)),
         CASE WHEN abs(hashtext(a.id::text)) % 10 < 6 THEN 'pago' ELSE 'pendente' END,
         CASE WHEN abs(hashtext(a.id::text)) % 10 < 6 THEN a.date ELSE NULL END,
         'a_vista', 1,
         pag_ids[1 + (abs(hashtext(a.id::text)) % array_length(pag_ids, 1))],
         conta_id, 1, 1, 3.49,
         (abs(hashtext(a.id::text)) % 10 < 6)
  FROM public.appointments a
  WHERE a.clinic_id = alvo AND a.status IN ('compareceu','confirmada');

  RAISE NOTICE '  receitas e recebiveis inseridos';

  -- ---------------------------------------------------------------
  -- 7. DESPESAS, fixas e variaveis
  -- ---------------------------------------------------------------
  INSERT INTO public.fixed_expenses (clinic_id, description, value, due_day, category_id, person_type, recurrence, start_date, active) VALUES
    (alvo, 'Aluguel da sala',        8500,  5,  categoria_ids[1], 'juridica', 'mensal', primeiro_dia, true),
    (alvo, 'Folha da equipe',        32000, 5,  categoria_ids[3], 'fisica',   'mensal', primeiro_dia, true),
    (alvo, 'Energia e agua',         1900,  15, categoria_ids[2], 'juridica', 'mensal', primeiro_dia, true),
    (alvo, 'Sistema de gestao',      280,   10, categoria_ids[7], 'juridica', 'mensal', primeiro_dia, true),
    (alvo, 'Contabilidade',          1200,  10, categoria_ids[7], 'juridica', 'mensal', primeiro_dia, true);

  INSERT INTO public.expenses (clinic_id, description, value, due_date, competence_date, status, paid_at,
                               category_id, bank_account_id, person_type, origin_type, is_recurring, supplier, conciliated)
  SELECT alvo, f.description, f.value,
         (d + (f.due_day - 1) * interval '1 day')::date,
         d,
         CASE WHEN (d + (f.due_day - 1) * interval '1 day')::date <= current_date THEN 'pago' ELSE 'pendente' END,
         CASE WHEN (d + (f.due_day - 1) * interval '1 day')::date <= current_date
              THEN (d + (f.due_day - 1) * interval '1 day')::date ELSE NULL END,
         f.category_id, conta_id, f.person_type, 'fixa', true, 'Fornecedor padrao',
         ((d + (f.due_day - 1) * interval '1 day')::date <= current_date)
  FROM public.fixed_expenses f
  CROSS JOIN generate_series(date_trunc('month', primeiro_dia), date_trunc('month', ultimo_dia), interval '1 month') d
  WHERE f.clinic_id = alvo;

  INSERT INTO public.expenses (clinic_id, description, value, due_date, competence_date, status, paid_at,
                               category_id, bank_account_id, person_type, origin_type, is_recurring, supplier, conciliated)
  SELECT alvo,
         (ARRAY['Compra de insumos','Campanha de trafego','Manutencao de equipamento','Material de escritorio','Treinamento da equipe'])[1 + (g % 5)],
         round((450 + (g % 13) * 190)::numeric, 2),
         (primeiro_dia + ((g * 5) % 60))::date,
         (primeiro_dia + ((g * 5) % 60))::date,
         CASE WHEN (primeiro_dia + ((g * 5) % 60))::date <= current_date THEN 'pago' ELSE 'pendente' END,
         CASE WHEN (primeiro_dia + ((g * 5) % 60))::date <= current_date THEN (primeiro_dia + ((g * 5) % 60))::date ELSE NULL END,
         categoria_ids[1 + (g % array_length(categoria_ids, 1))],
         conta_id, 'juridica', 'avulsa', false,
         (ARRAY['Dental Cremer','Meta Ads','TecnoMed','Kalunga','Instituto Formar'])[1 + (g % 5)],
         ((primeiro_dia + ((g * 5) % 60))::date <= current_date)
  FROM generate_series(1, 60) g;

  RAISE NOTICE '  despesas fixas e variaveis inseridas';

  -- ---------------------------------------------------------------
  -- 8. TAREFAS e METAS
  -- ---------------------------------------------------------------
  INSERT INTO public.tasks (clinic_id, title, description, type, status, due_date, responsible, patient_id, completed_at, created_at)
  SELECT alvo,
         (ARRAY['Retornar contato','Confirmar consulta','Enviar orcamento','Cobrar pendencia','Agendar retorno'])[1 + (g % 5)],
         'Tarefa gerada pela simulacao',
         (ARRAY['contato','confirmacao','comercial','financeiro','recall'])[1 + (g % 5)],
         CASE WHEN g % 3 = 0 THEN 'concluida' ELSE 'pendente' END,
         (primeiro_dia + ((g * 4) % 70))::date,
         (ARRAY['Recepcao','Comercial','Financeiro'])[1 + (g % 3)],
         p.id,
         CASE WHEN g % 3 = 0 THEN (primeiro_dia + ((g * 4) % 70))::date ELSE NULL END,
         primeiro_dia + ((g * 4) % 60) * interval '1 day'
  FROM generate_series(1, 90) g
  JOIN LATERAL (
    SELECT id FROM public.patients WHERE clinic_id = alvo ORDER BY created_at, id OFFSET (g % qtd_pacientes) LIMIT 1
  ) p ON true;

  INSERT INTO public.goals (clinic_id, year, month, revenue_target, closings_target, conversion_target, new_patients_target)
  SELECT alvo, extract(year FROM d)::int, extract(month FROM d)::int, 260000, 120, 45, 60
  FROM generate_series(date_trunc('month', primeiro_dia), date_trunc('month', ultimo_dia), interval '1 month') d
  -- Endurecido em 28/08/2026, depois de estourar em producao com
  -- `duplicate key value violates unique constraint
  -- "goals_clinic_id_month_year_key"` na Clinica Teste Final. A meta e a unica
  -- coisa que uma clinica de teste costuma ter mesmo sem paciente nenhum,
  -- entao a trava de "ja tem pacientes" nao a pegava.
  --
  -- DO UPDATE, e nao DO NOTHING, porque o contrato deste arquivo e produzir
  -- SEMPRE a mesma base. Com DO NOTHING, uma meta antiga de valor diferente
  -- sobreviveria, e o dashboard mostraria um alvo diferente a cada clinica.
  --
  -- Isto NAO torna o arquivo seguro em clinica nao expurgada: das vinte
  -- insercoes, dezoito seguem sem tratamento de conflito, e as que caem em
  -- tabela sem restricao unica DUPLICAM em silencio, que e pior que estourar.
  -- Rode o `1-expurgo.sql` antes. Sempre.
  ON CONFLICT (clinic_id, month, year) DO UPDATE SET
    revenue_target      = EXCLUDED.revenue_target,
    closings_target     = EXCLUDED.closings_target,
    conversion_target   = EXCLUDED.conversion_target,
    new_patients_target = EXCLUDED.new_patients_target;

  RAISE NOTICE '  tarefas e metas inseridas';

  -- ---------------------------------------------------------------
  -- 9. AS TABELAS DAS SEIS MIGRACOES DE 26/08
  -- ---------------------------------------------------------------
  -- Cada bloco so roda se a tabela existir, para o script continuar valendo
  -- num banco que esteja atras das migracoes.

  IF to_regclass('public.suppliers') IS NOT NULL THEN
    INSERT INTO public.suppliers (clinic_id, name, active)
    SELECT alvo, x, true FROM unnest(ARRAY['Dental Cremer','TecnoMed','Farmalab','Distribuidora Vida']) x;
    SELECT array_agg(id ORDER BY name) INTO forn_ids FROM public.suppliers WHERE clinic_id = alvo;

    -- units_per_purchase e a coluna que importa: caixa de 100 luvas por
    -- R$ 30 custa R$ 0,30 o par, e lancar os R$ 30 como custo do
    -- procedimento e o erro de custeio mais comum em clinica.
    INSERT INTO public.supplies (clinic_id, supplier_id, name, purchase_cost, units_per_purchase, purchase_unit, active) VALUES
      (alvo, forn_ids[1], 'Luva de procedimento', 30.00,   100, 'caixa',   true),
      (alvo, forn_ids[1], 'Seringa 3ml',          45.00,   50,  'caixa',   true),
      (alvo, forn_ids[3], 'Toxina botulinica',    1450.00, 100, 'frasco',  true),
      (alvo, forn_ids[3], 'Acido hialuronico',    890.00,  1,   'seringa', true),
      (alvo, forn_ids[2], 'Gaze esteril',         22.00,   200, 'pacote',  true),
      (alvo, forn_ids[4], 'Mascara descartavel',  18.00,   50,  'caixa',   true);
    SELECT array_agg(id ORDER BY name) INTO insumo_ids FROM public.supplies WHERE clinic_id = alvo;

    INSERT INTO public.service_supplies (clinic_id, service_id, supply_id, quantity)
    SELECT alvo, s.id, i.id, 1 + (abs(hashtext(s.id::text || i.id::text)) % 4)
    FROM public.services s
    CROSS JOIN LATERAL (
      SELECT id FROM public.supplies WHERE clinic_id = alvo ORDER BY name
      OFFSET (abs(hashtext(s.id::text)) % 6) LIMIT 2
    ) i
    WHERE s.clinic_id = alvo;
    RAISE NOTICE '  fornecedores, insumos e composicao inseridos';
  END IF;

  IF to_regclass('public.assets') IS NOT NULL THEN
    -- Vida util em ANOS, e a coluna e `description`, nao `name`.
    INSERT INTO public.assets (clinic_id, description, value, acquired_at, useful_life_years, active) VALUES
      (alvo, 'Cadeira odontologica',   28000, primeiro_dia - 400, 10, true),
      (alvo, 'Laser de CO2',           95000, primeiro_dia - 250, 8,  true),
      (alvo, 'Autoclave',              12000, primeiro_dia - 600, 10, true),
      (alvo, 'Mobiliario da recepcao', 18000, primeiro_dia - 700, 5,  true),
      (alvo, 'Computadores e rede',    14000, primeiro_dia - 300, 4,  true);
    RAISE NOTICE '  imobilizado inserido';
  END IF;

  IF to_regclass('public.pricing_params') IS NOT NULL THEN
    -- Os tres percentuais sao numero inteiro de porcento, nao fracao, e o
    -- CHECK exige soma abaixo de 100: somando 100 nao sobra nada para pagar
    -- o custo e o preco minimo tenderia ao infinito. 6 + 30 + 20 = 56.
    -- `occupancy` e fracao, entre 0 e 1, por outro CHECK.
    INSERT INTO public.pricing_params
      (clinic_id, hours_per_day, working_days, professionals, occupancy, tax_percent, payout_percent, margin_percent)
    VALUES (alvo, 8, 21, 3, 0.700, 6, 30, 20)
    ON CONFLICT (clinic_id) DO NOTHING;
    RAISE NOTICE '  parametros de preco inseridos';
  END IF;

  IF to_regclass('public.resources') IS NOT NULL THEN
    INSERT INTO public.resources (clinic_id, name, kind, active) VALUES
      (alvo, 'Sala 1',            'sala',        true),
      (alvo, 'Sala 2',            'sala',        true),
      (alvo, 'Sala de procedimento', 'sala',     true),
      (alvo, 'Laser de CO2',      'equipamento', true),
      (alvo, 'Ultrassom',         'equipamento', true);

    -- Aloca uma sala por consulta. Isso e o que faz a tela de Salas ter o que
    -- mostrar, e e de proposito que ela vai encontrar conflito: com a duracao
    -- padrao de 30 minutos aplicada a toda consulta existente, a base nasce
    -- com sobreposicao que nao e real. A migracao 20260826060000 registra que
    -- o conflito e MOSTRADO e nao impedido, exatamente por isso: limpar exige
    -- antes que alguem veja.
    IF to_regclass('public.appointment_resources') IS NOT NULL THEN
      INSERT INTO public.appointment_resources (clinic_id, appointment_id, resource_id)
      SELECT alvo, a.id, r.id
      FROM public.appointments a
      JOIN LATERAL (
        SELECT id FROM public.resources
         WHERE clinic_id = alvo AND kind = 'sala'
         ORDER BY name
         OFFSET (abs(hashtext(a.id::text)) % 3) LIMIT 1
      ) r ON true
      WHERE a.clinic_id = alvo
      ON CONFLICT (appointment_id, resource_id) DO NOTHING;
    END IF;
    RAISE NOTICE '  salas, equipamentos e alocacao inseridos';
  END IF;

  IF to_regclass('public.budget_notices') IS NOT NULL THEN
    -- O CHECK do kind aceita so 'orcamento', 'consentimento' e 'recibo'.
    INSERT INTO public.budget_notices (clinic_id, kind, title, body, position, active) VALUES
      (alvo, 'orcamento',    'Validade do orcamento',  'Este orcamento e valido por 30 dias a contar da data de emissao.', 1, true),
      (alvo, 'orcamento',    'Formas de pagamento',    'Aceitamos dinheiro, PIX, debito e credito em ate 12 vezes.', 2, true),
      (alvo, 'consentimento','Termo de consentimento', 'Declaro ter sido informado sobre o procedimento, seus riscos, alternativas e cuidados posteriores.', 1, true),
      (alvo, 'recibo',       'Recibo de pagamento',    'Recebemos a importancia descrita acima referente aos servicos prestados.', 1, true);
    RAISE NOTICE '  informativos inseridos';
  END IF;

  RAISE NOTICE 'Povoamento concluido para %.', nome_clinica;
END $$;


-- ================== PASSO 3 de 4: FECHAMENTOS ==================

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


-- ================== PASSO 4 de 4: SEMEAR O ESQUELETO ==================
--
-- Devolve o que o expurgo levou e o povoamento nao recria. Na pratica, o plano
-- de contas e as regras de negocio. Idempotente: o que ja existe, ela pula.
--
-- Sem esta linha a clinica termina sem conta analitica, e o lancamento de
-- despesa avulsa recusa tudo. Foi o V-24.

SELECT public.semear_clinica('d51ce6c7-582b-469b-a01b-608bd9b38885');
