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
  nome_alvo text := 'NexClin';
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
    -- Acrescentada em 29/08/2026. O `3-fechamentos` escreve aqui, e a lista
    -- nunca citou esta tabela: ela sumia so por CASCADE de `patients`, que e
    -- verdadeiro mas nao esta escrito em lugar nenhum. Explicita, ela aparece
    -- na contagem do aviso e para de depender de uma cascata implicita. Vem
    -- depois de `prescriptions` e `closings`, que sao os filhos dela.
    'funnel_2_entries',
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
