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
-- Ver `docs/seguranca/storage-objects-2026-08-27-resolvido.md`.
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
