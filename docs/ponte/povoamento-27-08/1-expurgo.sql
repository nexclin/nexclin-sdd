-- =====================================================================
-- EXPURGO. Apaga TODO o dado de operacao de UMA clinica.
-- =====================================================================
--
-- Este arquivo existe antes do povoamento de proposito, e a razao esta em
-- docs/planejamento/triagem-erick-27-08.md, item E-01: o banco da Lovable
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
-- COMO USAR: troque o UUID na linha do `alvo`, rode, e leia o aviso que ele
-- imprime com a contagem por tabela.
--
-- Para descobrir o UUID:
--   select id, name from public.clinics order by created_at;
-- =====================================================================

DO $$
DECLARE
  -- >>>>>>>>>>>>>>>> TROQUE AQUI, E SO AQUI <<<<<<<<<<<<<<<<
  alvo uuid := '00000000-0000-0000-0000-000000000000';
  -- >>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

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
BEGIN
  IF alvo = '00000000-0000-0000-0000-000000000000'::uuid THEN
    RAISE EXCEPTION 'Troque o UUID do alvo antes de rodar. Nada foi apagado.';
  END IF;

  SELECT name INTO nome_da_clinica FROM public.clinics WHERE id = alvo;
  IF nome_da_clinica IS NULL THEN
    RAISE EXCEPTION 'Nao existe clinica com id %. Nada foi apagado.', alvo;
  END IF;

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
END $$;

-- Conferencia. Tudo tem de voltar zero, menos a propria clinica e a equipe.
-- Troque o UUID aqui tambem.
SELECT 'patients'     AS tabela, count(*) FROM public.patients     WHERE clinic_id = '00000000-0000-0000-0000-000000000000'
UNION ALL SELECT 'appointments',  count(*) FROM public.appointments  WHERE clinic_id = '00000000-0000-0000-0000-000000000000'
UNION ALL SELECT 'receivables',   count(*) FROM public.receivables   WHERE clinic_id = '00000000-0000-0000-0000-000000000000'
UNION ALL SELECT 'expenses',      count(*) FROM public.expenses      WHERE clinic_id = '00000000-0000-0000-0000-000000000000'
UNION ALL SELECT 'team_members (NAO deve zerar)', count(*) FROM public.team_members WHERE clinic_id = '00000000-0000-0000-0000-000000000000';
