-- Endurece a policy de UPDATE em public.profiles com WITH CHECK explicito.
--
-- ORIGEM: sessao de 18/08/2026 deste repositorio (stack nova).
-- Espelha a migracao supabase/migrations/20260817021500_endurece_update_profiles_with_check.sql,
-- motivada pela auditoria docs/seguranca/auditoria-rls-2026-08-17.md.
--
-- ONDE RODAR: Lovable Cloud -> SQL editor, no banco de PRODUCAO (o mesmo
-- que o primeiro cliente vai acessar em 01/09). Nao rode em outro projeto.
--
-- EXPORTE ANTES: Lovable Cloud -> Overview -> Advanced settings -> Export
-- project data. O tier atual nao tem recuperacao no tempo (PITR) — sem o
-- export nao ha rollback se algo der errado no SQL editor.
--
-- POR QUE ISSO E NECESSARIO NA PRODUCAO LOVABLE
-- A policy original ("Users can update their own profile", nascida em
-- 20260322075121) foi criada apenas com:
--   USING (user_id = auth.uid())
-- sem WITH CHECK. Quando a clausula WITH CHECK esta ausente, o Postgres
-- reaproveita a expressao do USING para validar a linha nova. O USING so
-- olha user_id, entao a policy sozinha NAO impede o usuario de alterar o
-- proprio clinic_id e migrar para dentro de outra clinica. Quem hoje segura
-- essa brecha e apenas o trigger profiles_prevent_clinic_id_change. Sao
-- duas camadas que deveriam existir; falta uma. Esta correcao adiciona a
-- camada da policy.
--
-- POR QUE NAO QUEBRA NADA
-- A condicao do WITH CHECK abaixo e exatamente a mesma que o trigger
-- profiles_prevent_clinic_id_change ja impoe hoje na producao: qualquer
-- UPDATE que ele deixaria passar, este WITH CHECK tambem deixa. Superadmin
-- e service role nao passam por esta policy — usam caminhos proprios
-- (funcoes SECURITY DEFINER e policies especificas de superadmin).
--
-- POR QUE `IS NOT DISTINCT FROM` E NAO `=`
-- Perfil recem-criado antes do onboarding tem clinic_id nulo. Com `=`, a
-- comparacao NULL = NULL devolve NULL, e a policy negaria o UPDATE legitimo
-- do proprio perfil durante o onboarding. `IS NOT DISTINCT FROM` trata os
-- dois NULLs como iguais e deixa o fluxo passar.
--
-- SOBRE get_my_clinic_id()
-- E STABLE SECURITY DEFINER: dentro do UPDATE le o snapshot do statement e
-- devolve o clinic_id ANTIGO da linha, o que faz a comparacao equivaler a
-- "clinic_id nao mudou". Sendo SECURITY DEFINER, tambem evita a recursao
-- de RLS que um subselect direto em profiles causaria.

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND clinic_id IS NOT DISTINCT FROM public.get_my_clinic_id()
  );

-- Verificacao: rode a query abaixo apos aplicar. Espera-se ver a policy
-- "Users can update their own profile" com cmd = UPDATE, qual referenciando
-- user_id = auth.uid(), e with_check contendo tanto user_id = auth.uid()
-- quanto a comparacao com get_my_clinic_id(). Se with_check vier NULL, o
-- endurecimento nao foi aplicado.
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'profiles'
  AND policyname = 'Users can update their own profile';
