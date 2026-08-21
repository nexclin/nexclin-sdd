-- Endurece a policy de UPDATE em public.profiles com WITH CHECK explícito.
--
-- ORIGEM: auditoria de RLS de 17/08/2026 (docs/seguranca/auditoria-rls-2026-08-17.md).
-- A policy original nasceu em 20260322075121 com apenas
--   USING (user_id = auth.uid())
-- e sem WITH CHECK. Nesse caso o Postgres reaproveita a expressão do USING para
-- validar a linha nova — e o USING só olha user_id. Ou seja: a policy sozinha
-- NÃO impedia o usuário de alterar o próprio clinic_id e migrar para dentro de
-- outra clínica. Quem segurava era só o trigger profiles_prevent_clinic_id_change.
--
-- Isso deixava a âncora multi-tenant apoiada numa camada única: desabilitar o
-- trigger bastaria para abrir a brecha. Esta migração acrescenta a segunda
-- camada, na própria policy.
--
-- POR QUE NÃO QUEBRA NADA: a condição abaixo é exatamente a mesma que o trigger
-- já impõe hoje (exceção quando um usuário comum muda clinic_id; service role,
-- com auth.uid() nulo, e superadmin seguem liberados por caminhos próprios —
-- SECURITY DEFINER e policies de superadmin não passam por esta policy).
-- Qualquer fluxo que o WITH CHECK bloquearia já está bloqueado pelo trigger.
--
-- get_my_clinic_id() é STABLE SECURITY DEFINER: dentro do UPDATE ela lê o
-- snapshot do statement e devolve o clinic_id ANTIGO, o que faz a comparação
-- equivaler a "clinic_id não mudou". Sendo SECURITY DEFINER, também evita a
-- recursão de RLS que um subselect direto em profiles causaria.
--
-- IS NOT DISTINCT FROM (e não =) por causa do perfil ainda sem clínica, em que
-- os dois lados são NULL: com "=" o resultado seria NULL e a policy negaria o
-- update legítimo do próprio perfil durante o onboarding.

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND clinic_id IS NOT DISTINCT FROM public.get_my_clinic_id()
  );
