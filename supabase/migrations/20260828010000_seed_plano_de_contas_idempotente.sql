-- 20260828010000_seed_plano_de_contas_idempotente.sql
--
-- Por que esta migracao existe, em uma frase: `semear_clinica` nao conseguia
-- reparar uma clinica cujo plano de contas tinha sido esvaziado pela metade, e
-- afrouxar so o guarda dela teria QUEBRADO a criacao de clinica.
--
-- O caso real, 28/08/2026, conta mestra `erpclinicas@gmail.com`. O diagnostico
-- do V-24 na bateria do Vinicius. A arvore tinha UM no, `1 nexclin`, nivel 1,
-- sem filhos, e nenhuma conta analitica. O dialogo de despesa avulsa recusava
-- o lancamento com "Nenhuma conta analitica disponivel", corretamente: nao
-- havia conta de ultimo nivel para oferecer.
--
-- Dois defeitos somados, e a ordem entre eles importa.
--
-- PRIMEIRO, o guarda de `semear_clinica` (20260827020000) pergunta a coisa
-- errada:
--
--     IF NOT EXISTS (SELECT 1 FROM chart_of_accounts WHERE clinic_id = _clinic_id)
--
-- "Tem pelo menos uma linha" nao e a mesma pergunta que "o esqueleto esta
-- completo". Com uma linha solta, a condicao e falsa, o seed e pulado, e a
-- clinica fica presa. A funcao de reparo passa reto pelo que deveria reparar.
--
-- SEGUNDO, e por isso o conserto do guarda sozinho seria pior que o defeito:
-- `chart_of_accounts` tem `UNIQUE(clinic_id, code)`, e `seed_chart_of_accounts`
-- (20260322185846) usa INSERT puro, sem ON CONFLICT. Ele comeca inserindo o
-- codigo '1'. Numa clinica que ja tem o codigo '1', o seed levanta excecao. Como
-- `semear_clinica` tambem e chamada pelo gatilho de nascimento da clinica,
-- afrouxar o guarda antes de consertar o seed trocaria uma falha silenciosa por
-- criacao de clinica quebrada.
--
-- E a raiz do segundo defeito e uma regra deste repositorio sendo violada desde
-- marco. `.claude/rules/banco.md`, secao Seeds: "Idempotentes por contrato:
-- rodar duas vezes nao pode duplicar nada." `seed_chart_of_accounts` nunca foi.
--
-- O que esta migracao faz, nesta ordem:
--
--   1. Torna `seed_chart_of_accounts` idempotente de verdade. Onde o INSERT
--      original devolvia o id do pai com RETURNING, usa
--      `ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()`, e nao
--      DO NOTHING: DO NOTHING nao devolve linha, `v_id` viria NULL e a arvore
--      nasceria sem pai. O DO UPDATE toca so `updated_at` DE PROPOSITO, para
--      NAO sobrescrever nome que a clinica tenha editado. Nos filhos, que nao
--      usam RETURNING, DO NOTHING basta.
--
--   2. Corrige o guarda de `semear_clinica` para perguntar por conta ANALITICA
--      ativa, que e o que o lancamento exige, em vez de por linha qualquer.
--
-- O que esta migracao NAO faz, e e deliberado: nao renomeia o no `1 nexclin`.
-- Ele vira o pai da subarvore semeada e mantem o nome. Sobrescrever dado que a
-- clinica pode ter digitado nao e trabalho de migracao, e a tela permite
-- renomear em dois cliques.
--
-- Faixa A da Sec. 2.5: e banco, e migra intacta para a stack nova.

-- 1. O seed vira idempotente.

CREATE OR REPLACE FUNCTION public.seed_chart_of_accounts(p_clinic_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
  v_sub_id uuid;
BEGIN
  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '1', 'IMPOSTOS, TAXAS E AFINS', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '1.1', 'Tributos sobre faturamento e lucro', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '1.1.1', 'Simples Nacional', v_sub_id, 3),
    (p_clinic_id, '1.1.2', 'ICMS', v_sub_id, 3),
    (p_clinic_id, '1.1.3', 'ISS', v_sub_id, 3),
    (p_clinic_id, '1.1.4', 'PIS', v_sub_id, 3),
    (p_clinic_id, '1.1.5', 'COFINS', v_sub_id, 3),
    (p_clinic_id, '1.1.6', 'IRPJ', v_sub_id, 3),
    (p_clinic_id, '1.1.7', 'IRs Diversos', v_sub_id, 3),
    (p_clinic_id, '1.1.8', 'CSLL', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '1.2', 'Parcelamentos, regularizações e obrigações fiscais', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '1.2.1', 'REFIS', v_sub_id, 3),
    (p_clinic_id, '1.2.2', 'INSS', v_sub_id, 3),
    (p_clinic_id, '1.2.3', 'FGTS', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '1.3', 'Tributos patrimoniais, regulatórios e taxas', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '1.3.1', 'IPTU', v_sub_id, 3),
    (p_clinic_id, '1.3.2', 'IPVA', v_sub_id, 3),
    (p_clinic_id, '1.3.3', 'Vigilância Sanitária', v_sub_id, 3),
    (p_clinic_id, '1.3.4', 'Taxas e Certificados', v_sub_id, 3),
    (p_clinic_id, '1.3.5', 'Certificados / Certidões', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '2', 'DESPESAS ADMINISTRATIVAS', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '2.1', 'Despesas administrativas gerais', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '2.1.1', 'Desp. Adm. Diversas', v_sub_id, 3),
    (p_clinic_id, '2.1.2', 'Material de expediente e limpeza', v_sub_id, 3),
    (p_clinic_id, '2.1.3', 'Assinaturas', v_sub_id, 3),
    (p_clinic_id, '2.1.4', 'Uniformes', v_sub_id, 3),
    (p_clinic_id, '2.1.5', 'Seguros', v_sub_id, 3),
    (p_clinic_id, '2.1.6', 'Manutenções', v_sub_id, 3),
    (p_clinic_id, '2.1.7', 'Obras e Construções', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '2.2', 'Deslocamento, eventos e bem-estar', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '2.2.1', 'Viagens', v_sub_id, 3),
    (p_clinic_id, '2.2.2', 'Transporte (passagens, táxi, Uber etc.)', v_sub_id, 3),
    (p_clinic_id, '2.2.3', 'Saúde Ocupacional', v_sub_id, 3),
    (p_clinic_id, '2.2.4', 'Confraternizações', v_sub_id, 3),
    (p_clinic_id, '2.2.5', 'Segurança e afins', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '3', 'DESPESAS OPERACIONAIS', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '3.1', 'Operação clínica e assistencial', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '3.1.1', 'Repasse para Prestadores de Serviços Clínicos', v_sub_id, 3),
    (p_clinic_id, '3.1.2', 'Benefícios para Pacientes', v_sub_id, 3),
    (p_clinic_id, '3.1.3', 'Envio de medicações', v_sub_id, 3),
    (p_clinic_id, '3.1.4', 'Custo de Coleta Laboratorial', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '3.2', 'Operação de apoio e rotina', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '3.2.1', 'Desp. Oper. Diversas', v_sub_id, 3),
    (p_clinic_id, '3.2.2', 'Sistemas de Gestão', v_sub_id, 3),
    (p_clinic_id, '3.2.3', 'Coleta de Resíduos', v_sub_id, 3),
    (p_clinic_id, '3.2.4', 'Comissão por Indicação', v_sub_id, 3),
    (p_clinic_id, '3.2.5', 'Locomoção entre outras unidades', v_sub_id, 3),
    (p_clinic_id, '3.2.6', 'Devoluções', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '4', 'INFRAESTRUTURA', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '4.1', 'Ocupação e utilidades', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '4.1.1', 'Aluguel', v_sub_id, 3),
    (p_clinic_id, '4.1.2', 'Condomínio', v_sub_id, 3),
    (p_clinic_id, '4.1.3', 'Luz', v_sub_id, 3),
    (p_clinic_id, '4.1.4', 'Internet', v_sub_id, 3),
    (p_clinic_id, '4.1.5', 'Telefone', v_sub_id, 3),
    (p_clinic_id, '4.1.6', 'Água', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '5', 'SERVIÇOS TERCEIRIZADOS', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '5.1', 'Serviços técnicos e de suporte', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '5.1.1', 'Limpeza', v_sub_id, 3),
    (p_clinic_id, '5.1.2', 'Contabilidade', v_sub_id, 3),
    (p_clinic_id, '5.1.3', 'Jurídico', v_sub_id, 3),
    (p_clinic_id, '5.1.4', 'Consultorias, Assessorias e Mentorias', v_sub_id, 3),
    (p_clinic_id, '5.1.5', 'Cursos, Treinamentos e Workshops', v_sub_id, 3),
    (p_clinic_id, '5.1.6', 'Gestão', v_sub_id, 3),
    (p_clinic_id, '5.1.7', 'Prestador de Serviços', v_sub_id, 3),
    (p_clinic_id, '5.1.8', 'Serviço de Office-Boy', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '6', 'PESSOAL', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '6.1', 'Remuneração fixa', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '6.1.1', 'Pró-Labore', v_sub_id, 3),
    (p_clinic_id, '6.1.2', 'Salários', v_sub_id, 3),
    (p_clinic_id, '6.1.3', 'Férias', v_sub_id, 3),
    (p_clinic_id, '6.1.4', 'Rescisões', v_sub_id, 3),
    (p_clinic_id, '6.1.5', 'Acordos Trabalhistas', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '6.2', 'Benefícios e incentivos', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '6.2.1', 'Vale Transporte e Bilhete Único', v_sub_id, 3),
    (p_clinic_id, '6.2.2', 'Vale Alimentação', v_sub_id, 3),
    (p_clinic_id, '6.2.3', 'Assistência Médica / Odontológica', v_sub_id, 3),
    (p_clinic_id, '6.2.4', 'Recrutamento de Colaboradores', v_sub_id, 3),
    (p_clinic_id, '6.2.5', 'Bonificações e Comissões', v_sub_id, 3),
    (p_clinic_id, '6.2.6', 'Benefícios Diversos', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '7', 'MARKETING', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '7.1', 'Marketing operacional e digital', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '7.1.1', 'Social Media', v_sub_id, 3),
    (p_clinic_id, '7.1.2', 'Gestor de Tráfego', v_sub_id, 3),
    (p_clinic_id, '7.1.3', 'Tráfego Pago', v_sub_id, 3),
    (p_clinic_id, '7.1.4', 'Serviços Digitais', v_sub_id, 3),
    (p_clinic_id, '7.1.5', 'Brindes', v_sub_id, 3),
    (p_clinic_id, '7.1.6', 'Marketing Visual', v_sub_id, 3),
    (p_clinic_id, '7.1.7', 'Experiência do Cliente', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '8', 'DESPESAS FINANCEIRAS', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '8.1', 'Custos financeiros', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '8.1.1', 'Despesas Bancárias', v_sub_id, 3),
    (p_clinic_id, '8.1.2', 'Empréstimos e Consórcios', v_sub_id, 3),
    (p_clinic_id, '8.1.3', 'Descontos Concedidos', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '9', 'ESTOQUE', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '9.1', 'Estoque assistencial', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '9.1.1', 'Estoque de Medicações', v_sub_id, 3),
    (p_clinic_id, '9.1.2', 'Material Clínico', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;

  INSERT INTO chart_of_accounts (clinic_id, code, name, level) VALUES (p_clinic_id, '10', 'AQUISIÇÕES', 1) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES (p_clinic_id, '10.1', 'Bens e estrutura', v_id, 2) ON CONFLICT (clinic_id, code) DO UPDATE SET updated_at = now()
    RETURNING id INTO v_sub_id;
  INSERT INTO chart_of_accounts (clinic_id, code, name, parent_id, level) VALUES
    (p_clinic_id, '10.1.1', 'Móveis e Utensílios', v_sub_id, 3),
    (p_clinic_id, '10.1.2', 'Máquinas e Equipamentos', v_sub_id, 3),
    (p_clinic_id, '10.1.3', 'Computadores e afins', v_sub_id, 3),
    (p_clinic_id, '10.1.4', 'Ferramentas', v_sub_id, 3)
    ON CONFLICT (clinic_id, code) DO NOTHING;
END;
$$;

-- 2. O guarda passa a perguntar por conta ANALITICA ativa.
--
-- Repare que a mudanca e so na condicao do bloco de `chart_of_accounts`. Os
-- outros blocos ficam como estao: para eles "existe pelo menos uma linha" ainda
-- e a pergunta certa, porque nao tem nivel nem hierarquia. O plano de contas e
-- o unico com esqueleto, e por isso o unico que sabe estar pela metade.

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

  -- Mudou em 28/08/2026: pergunta por conta analitica ativa, nao por linha
  -- qualquer. Ver o cabecalho desta migracao. O seed agora e idempotente, entao
  -- chama-lo com a arvore pela metade completa o que falta em vez de estourar.
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
REVOKE EXECUTE ON FUNCTION public.seed_chart_of_accounts(uuid) FROM PUBLIC, anon, authenticated;
