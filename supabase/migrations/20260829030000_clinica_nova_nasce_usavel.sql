-- 20260829030000_clinica_nova_nasce_usavel.sql
--
-- A clinica nova passa a nascer com TIPOS DE CONSULTA e CATEGORIAS DE DESPESA.
--
-- Achado em 29/08/2026, na bateria de teste da primeira conta provisionada. A
-- clinica nascia com 79 contas analiticas, 7 meios de pagamento, 8 origens,
-- servicos nativos e a conta Caixa. E com ZERO tipos de consulta e ZERO
-- categorias de despesa.
--
-- POR QUE ISSO IMPORTA, e nao e preciosismo: sem tipo de consulta nao se agenda,
-- e sem categoria de despesa nao se classifica o que se paga. Sao as duas
-- primeiras coisas que uma clinica faz no dia um. A conta nascia completa no
-- financeiro e incompleta na operacao.
--
-- E IMPORTA MAIS AINDA PELO MODELO DE IMPLANTACAO da NexClin, que e entregar a
-- plataforma pronta para o cliente so chegar e usar. Entregar uma conta que nao
-- agenda contradiz a promessa que sustenta a venda.
--
-- O QUE ESTES VALORES SAO, E O QUE NAO SAO: sao um PONTO DE PARTIDA usavel, e
-- nao a configuracao final da clinica. Nascem com `active = true` e preco zero
-- nos tipos, porque preco e decisao de cada clinica e chutar numero seria pior
-- que deixar em branco. A clinica renomeia, desativa e acrescenta no
-- onboarding, e e para isso que o passo existe.
--
-- Nao levam `is_system`, de proposito. `is_system` significa "veio do seed e a
-- clinica nao mexe", e aqui e o contrario: espera-se que ela mexa. Marcar como
-- sistema faria a trava do FR-006 impedir justamente a personalizacao que se
-- quer.
--
-- Faixa A da Sec. 2.5: e banco, e migra intacta.

CREATE OR REPLACE FUNCTION public.semeia_operacao_da_clinica(_clinic_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Os blocos conferem antes de escrever, pelo mesmo contrato de
  -- `semear_clinica`: a funcao roda em clinica nova, em clinica completa e em
  -- clinica que perdeu so uma parte, e nas tres o resultado e o mesmo.
  IF NOT EXISTS (SELECT 1 FROM public.consultation_types WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.consultation_types (clinic_id, name, price, active) VALUES
      (_clinic_id, 'Primeira consulta', 0, true),
      (_clinic_id, 'Retorno',           0, true),
      (_clinic_id, 'Avaliacao',         0, true),
      (_clinic_id, 'Procedimento',      0, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.expense_categories WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.expense_categories (clinic_id, name, cost_center, subcategory, active) VALUES
      (_clinic_id, 'Aluguel',             'Estrutura',   'Fixo',     true),
      (_clinic_id, 'Folha e encargos',    'Pessoal',     'Fixo',     true),
      (_clinic_id, 'Material de consumo', 'Operacional', 'Variavel', true),
      (_clinic_id, 'Marketing',           'Comercial',   'Variavel', true),
      (_clinic_id, 'Energia e agua',      'Estrutura',   'Fixo',     true),
      (_clinic_id, 'Software e sistemas', 'Estrutura',   'Fixo',     true),
      (_clinic_id, 'Impostos',            'Financeiro',  'Variavel', true);
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.semeia_operacao_da_clinica(uuid) FROM PUBLIC, anon, authenticated;

-- `semear_clinica` passa a chamar a nova, em vez de o gatilho ganhar mais um
-- corpo escrito em linha. Principio VIII: quem quiser reparar uma clinica
-- existente chama `semear_clinica` e recebe o esqueleto INTEIRO, e nao a metade
-- que existia antes desta migracao.
CREATE OR REPLACE FUNCTION public.semear_clinica(_clinic_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF _clinic_id IS NULL THEN
    RAISE EXCEPTION 'semear_clinica: clinic_id nulo';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.clinics WHERE id = _clinic_id) THEN
    RAISE EXCEPTION 'semear_clinica: nao existe clinica %', _clinic_id;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.business_rules WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.business_rules (clinic_id) VALUES (_clinic_id);
  END IF;

  -- Pergunta por conta ANALITICA ativa, e nao por linha qualquer. Ver
  -- 20260828010000: "tem pelo menos uma linha" nao e "o esqueleto esta
  -- completo", e foi essa confusao que produziu o V-24.
  IF NOT EXISTS (
    SELECT 1 FROM public.chart_of_accounts
    WHERE clinic_id = _clinic_id AND level = 3 AND active
  ) THEN
    PERFORM public.seed_chart_of_accounts(_clinic_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.closing_types WHERE clinic_id = _clinic_id) THEN
    PERFORM public.seed_closing_types(_clinic_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.services WHERE clinic_id = _clinic_id) THEN
    PERFORM public.seed_native_services(_clinic_id);
  END IF;

  -- A parte que faltava, e que esta migracao acrescenta.
  PERFORM public.semeia_operacao_da_clinica(_clinic_id);

  IF NOT EXISTS (SELECT 1 FROM public.bank_accounts WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.bank_accounts (clinic_id, bank_name, account_type, opening_balance, is_system, active)
    VALUES (_clinic_id, 'Caixa (dinheiro)', 'caixa', 0, true, true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.channels WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.channels (clinic_id, name, active) VALUES
      (_clinic_id, 'Whatsapp', false), (_clinic_id, 'Direct Instagram', false),
      (_clinic_id, 'Ligacao', false),  (_clinic_id, 'E-mail', false),
      (_clinic_id, 'Presencial', false);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.origins WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.origins (clinic_id, name, active) VALUES
      (_clinic_id, 'Redes Sociais Clinica', false), (_clinic_id, 'Redes Sociais Medico(a)', false),
      (_clinic_id, 'Google', false), (_clinic_id, 'Site', false),
      (_clinic_id, 'Indicacao amigo/familiar', false),
      (_clinic_id, 'Indicacao profissional de saude', false),
      (_clinic_id, 'Convenio', false), (_clinic_id, 'Nao informado', false);
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.semear_clinica(uuid) FROM PUBLIC, anon, authenticated;

-- As clinicas que ja existem e nasceram sem estes dois catalogos recebem agora.
-- A funcao confere antes de escrever, entao quem ja tem nao ganha duplicata.
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT id FROM public.clinics LOOP
    PERFORM public.semeia_operacao_da_clinica(r.id);
  END LOOP;
END $$;
