-- =====================================================================
-- AS DUAS MIGRACOES DE 27/08, PARA COLAR DE UMA VEZ
-- =====================================================================
--
-- ARQUIVO GERADO. A fonte de verdade continua sendo supabase/migrations/.
--
-- Colar as duas separadas deu erro de sintaxe em 27/08: o END do segundo
-- arquivo ficou grudado num comentario do primeiro. Este arquivo existe para
-- que a colagem seja uma so.
--
-- E SEGURO RODAR MAIS DE UMA VEZ.
-- =====================================================================


-- ---------------------------------------------------------------------
-- BLOCO 1. Foto de perfil: coluna, bucket privado e as quatro politicas
-- ---------------------------------------------------------------------

-- Foto de perfil: a coluna, o bucket e as quatro politicas dele.
--
-- Pedido do Arthur em 27/08, na linha do E-02 da triagem do Erick. O E-02 foi
-- corrigido pelo proprio Arthur: saber quem esta logado JA EXISTE, o Erick nao
-- tinha reparado. O que falta e a personalizacao do perfil, nos moldes do INI.
--
-- # Duas coisas que a leitura do codigo mostrou, e a segunda e um defeito
--
-- 1. `profiles` nao tem coluna de foto. Por isso isto e migracao e nao tela.
--
-- 2. `NxUserMenu` monta as iniciais e o nome a partir do E-MAIL, e nao de
--    `profiles.full_name`, que ja existe e ja e preenchido no cadastro. O
--    proprio comentario do arquivo assume o provisorio: *"O que vem antes do @
--    serve de nome enquanto nao houver perfil com nome"*. O perfil com nome
--    existe desde o comeco. E a tela que nunca foi ligada nele.
--
-- # Por que o bucket e PRIVADO, e o caminho tem o clinic_id na frente
--
-- A auditoria de `storage.objects` de 27/08 mediu o estado real: RLS ligada e
-- quatro politicas, todas restritas a `bucket_id LIKE 'database_export%'`. Um
-- bucket novo com outro nome nao casa com nenhuma delas, e com RLS ligada isso
-- NEGA TUDO. Ou seja, criar o bucket sem escrever politica nao vaza: quebra.
-- Ver `../../historico/2026-08-27-storage-objects-resolvido.md`.
--
-- O caminho de cada arquivo e `<clinic_id>/<user_id>.<ext>`. Com o clinic_id
-- como primeira pasta, a politica de leitura vira uma comparacao direta com
-- `get_my_clinic_id()`, que e a mesma ancora que o resto do sistema usa. Foto
-- de colega da mesma clinica aparece; de outra clinica, nao existe.
--
-- Bucket publico foi descartado de proposito. Publico significa legivel por
-- qualquer um que descubra a URL, sem autenticacao, e o que esta ali e nome e
-- rosto de profissional de saude. Nao e catastrofe, e tambem nao ha ganho que
-- pague isso: URL assinada resolve com uma chamada.

-- ---------------------------------------------------------------------------
-- 1. A coluna
-- ---------------------------------------------------------------------------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url text;

COMMENT ON COLUMN public.profiles.avatar_url IS
  'Caminho do arquivo no bucket `avatars`, no formato <clinic_id>/<user_id>.<ext>. Nao e URL publica: a tela pede uma URL assinada.';

-- ---------------------------------------------------------------------------
-- 2. O bucket
-- ---------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  false,
  2097152,  -- 2 MB. Foto de perfil que passa disso e foto que ninguem redimensionou.
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public             = false,
      file_size_limit    = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- 3. As quatro politicas
-- ---------------------------------------------------------------------------
-- LEITURA e da clinica inteira. ESCRITA e so do dono do arquivo, e a segunda
-- pasta do caminho tem de comecar com o proprio auth.uid(). Sem essa segunda
-- condicao, qualquer pessoa da clinica poderia sobrescrever a foto de outra.

DROP POLICY IF EXISTS "Avatares sao visiveis para a clinica" ON storage.objects;
CREATE POLICY "Avatares sao visiveis para a clinica"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = public.get_my_clinic_id()::text
  );

DROP POLICY IF EXISTS "Cada um envia o proprio avatar" ON storage.objects;
CREATE POLICY "Cada um envia o proprio avatar"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = public.get_my_clinic_id()::text
    AND split_part((storage.filename(name)), '.', 1) = auth.uid()::text
  );

DROP POLICY IF EXISTS "Cada um troca o proprio avatar" ON storage.objects;
CREATE POLICY "Cada um troca o proprio avatar"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = public.get_my_clinic_id()::text
    AND split_part((storage.filename(name)), '.', 1) = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = public.get_my_clinic_id()::text
    AND split_part((storage.filename(name)), '.', 1) = auth.uid()::text
  );

DROP POLICY IF EXISTS "Cada um apaga o proprio avatar" ON storage.objects;
CREATE POLICY "Cada um apaga o proprio avatar"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = public.get_my_clinic_id()::text
    AND split_part((storage.filename(name)), '.', 1) = auth.uid()::text
  );


-- ---------------------------------------------------------------------
-- BLOCO 2. O esqueleto da clinica vira funcao, e repara o que quebrou
-- ---------------------------------------------------------------------

-- O esqueleto da clinica vira funcao, e deixa de existir so dentro do gatilho.
--
-- # O que aconteceu em 27/08, e e a razao desta migracao
--
-- O script de expurgo (`docs/ponte/povoamento-27-08/1-expurgo.sql`) apagou,
-- entre outras coisas, `business_rules`, `chart_of_accounts`, `closing_types`,
-- `channels`, `origins`, `payment_methods`, `objections` e a conta "Caixa".
--
-- Essas tabelas nao guardam dado de operacao: elas sao o ESQUELETO que o
-- gatilho `handle_new_user` cria junto com a clinica. Apagar o esqueleto deixa
-- a clinica num estado em que nenhuma clinica real nasce, pior do que nova.
--
-- O sintoma foi o onboarding travando no passo 2. O passo pergunta quais campos
-- do paciente sao obrigatorios; a tela salva com `UPDATE business_rules ...
-- WHERE clinic_id = ...`, e **UPDATE que nao casa com nenhuma linha nao e
-- erro**: o PostgREST devolve sucesso, a tela diz "salvos!", e nada foi
-- gravado. A verificacao do passo entao pergunta se existe linha em
-- `business_rules`, recebe nao, e o tour fica parado para sempre.
--
-- # Por que a correcao e uma FUNCAO, e nao um reparo pontual
--
-- O esqueleto so existia dentro do corpo de `handle_new_user`, escrito em
-- linha. Nao havia como recria-lo para uma clinica que ja existe, nem como
-- conferir se uma clinica esta completa. Toda vez que alguem precisasse disso,
-- copiaria o corpo do gatilho a mao, e a copia envelheceria.
--
-- Agora existe `public.semear_clinica(uuid)`, idempotente, e o gatilho passa a
-- ser um dos chamadores dela, nao o dono da regra. E o Principio VIII, Uma
-- Regra Uma Fonte, aplicado ao nascimento da clinica.

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

  -- Cada bloco confere a propria tabela antes de escrever. Assim a funcao roda
  -- em clinica nova, em clinica completa e em clinica que perdeu so uma parte,
  -- e nas tres o resultado e o mesmo.

  IF NOT EXISTS (SELECT 1 FROM public.business_rules WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.business_rules (clinic_id) VALUES (_clinic_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.chart_of_accounts WHERE clinic_id = _clinic_id) THEN
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
      (_clinic_id, 'Ligação', false),  (_clinic_id, 'E-mail', false),
      (_clinic_id, 'Presencial', false);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.origins WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.origins (clinic_id, name, active) VALUES
      (_clinic_id, 'Redes Sociais Clínica', false), (_clinic_id, 'Redes Sociais Médico(a)', false),
      (_clinic_id, 'Google', false), (_clinic_id, 'Site', false),
      (_clinic_id, 'Indicação amigo/familiar', false),
      (_clinic_id, 'Indicação profissional de saúde', false),
      (_clinic_id, 'Convênio', false), (_clinic_id, 'Não informado', false);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.payment_methods WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.payment_methods (clinic_id, name, type, default_fee_percent, payment_term_days, active) VALUES
      (_clinic_id, 'Dinheiro', 'dinheiro', 0, 0, false),
      (_clinic_id, 'Pix', 'pix', 0, 0, false),
      (_clinic_id, 'Transferência', 'transferencia', 0, 0, false),
      (_clinic_id, 'Boleto', 'boleto', 0, 3, false),
      (_clinic_id, 'Cheque', 'cheque', 0, 0, false),
      (_clinic_id, 'Cartão de Débito', 'debito', 2.0, 1, false),
      (_clinic_id, 'Cartão de Crédito', 'credito', 3.5, 30, false);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.objections WHERE clinic_id = _clinic_id) THEN
    INSERT INTO public.objections (clinic_id, name, active) VALUES
      (_clinic_id, 'Parou de responder', true), (_clinic_id, 'Parou de responder após preço', true),
      (_clinic_id, 'Queria pelo plano de saúde/convênio', true), (_clinic_id, 'Distância', true),
      (_clinic_id, 'Preço', true), (_clinic_id, 'Não é prioridade', true),
      (_clinic_id, 'Marcou com outro profissional', true), (_clinic_id, 'Lead desqualificado', true),
      (_clinic_id, 'Errou de especialidade', true), (_clinic_id, 'Horário de atendimento', true),
      (_clinic_id, 'Demora na agenda', true), (_clinic_id, 'Golpe', true),
      (_clinic_id, 'Medo/Insegurança dos procedimentos', true), (_clinic_id, 'Não informado', true),
      (_clinic_id, 'Outro', true);
  END IF;
END;
$$;

COMMENT ON FUNCTION public.semear_clinica(uuid) IS
  'Cria o esqueleto de uma clinica (regras, catalogos, conta caixa) se faltar. Idempotente: rodar de novo nao duplica.';

-- ---------------------------------------------------------------------------
-- Uma trava para o defeito nao poder voltar em silencio
-- ---------------------------------------------------------------------------
-- `business_rules` e um registro por clinica, e o codigo inteiro assume isso:
-- sao onze lugares usando `.single()` ou `.maybeSingle()` sobre a tabela. Sem
-- indice unico, isso era so convencao. Com ele, duas linhas viram erro na hora
-- de escrever, e nao comportamento estranho na leitura tres telas adiante.
CREATE UNIQUE INDEX IF NOT EXISTS business_rules_uma_por_clinica
  ON public.business_rules (clinic_id);

-- ---------------------------------------------------------------------------
-- Reparo do que ja esta no ar
-- ---------------------------------------------------------------------------
-- Toda clinica existente passa pela funcao. Quem esta completa nao muda nada;
-- quem perdeu parte do esqueleto recupera.
DO $$
DECLARE
  c record;
  reparadas int := 0;
BEGIN
  FOR c IN SELECT id, name FROM public.clinics LOOP
    IF NOT EXISTS (SELECT 1 FROM public.business_rules WHERE clinic_id = c.id)
       OR NOT EXISTS (SELECT 1 FROM public.payment_methods WHERE clinic_id = c.id)
       OR NOT EXISTS (SELECT 1 FROM public.chart_of_accounts WHERE clinic_id = c.id) THEN
      RAISE NOTICE 'Reparando o esqueleto da clinica: %', c.name;
      reparadas := reparadas + 1;
    END IF;
    PERFORM public.semear_clinica(c.id);
  END LOOP;
  RAISE NOTICE 'Clinicas conferidas. Reparadas: %', reparadas;
END $$;
