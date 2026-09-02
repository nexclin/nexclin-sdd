-- 20260902010000_so_o_super_owner_gere_operadores.sql
--
-- Item 3.1 do handoff de 30/08: os quatro papeis do painel nao limitam nada.
--
-- ============ O BURACO, MEDIDO ============
--
-- O enum tem quatro papeis (`super_owner`, `admin`, `suporte`, `financeiro`),
-- e NENHUMA policy ou funcao decide por eles. `is_superadmin(uid)` pergunta so
-- se o usuario e operador ATIVO:
--
--     SELECT EXISTS (SELECT 1 FROM superadmin_operators
--                     WHERE user_id = _user_id AND active = true)
--
-- E a policy da propria tabela de operadores e:
--
--     CREATE POLICY "Superadmins can manage operators"
--       ON public.superadmin_operators FOR ALL TO authenticated
--       USING (is_superadmin(auth.uid())) WITH CHECK (is_superadmin(auth.uid()));
--
-- `FOR ALL`, com a checagem de "e operador ativo". Logo: QUALQUER operador pode
-- criar operador, promover a si mesmo a `super_owner`, rebaixar quem quiser, e
-- APAGAR o dono da plataforma. A unica verificacao de papel do produto inteiro
-- esta em `SuperAdminOperadores.tsx:42`, e ela decide se um BOTAO aparece.
--
-- Isso e a regra (c) da constituicao sendo violada: "seguranca mora no banco; a
-- tela apenas reflete".
--
-- ============ POR QUE ISTO AGORA, E NAO A MATRIZ DE QUATRO PAPEIS ============
--
-- Era latente enquanto havia UM operador. Em 30/08 o Arthur respondeu que o
-- Erick e o Vinicius viram operadores antes de 08/09, e que os dois vao
-- impersonar. O buraco abre quando essas contas nascerem.
--
-- E somando o que os tres precisam, sobra tudo menos gerir operadores: o Erick
-- precisa de faturamento E de impersonacao, o Vinicius de impersonacao E de
-- provisionamento. Um RBAC de quatro papeis nao compra quase nada para um time
-- de tres em que cada um precisa de quase tudo, e custa uma matriz inteira para
-- manter.
--
-- O que separa "opera" de "controla quem opera" e UMA guarda, e e esta.
--
-- ============ POR QUE POLICY RESTRITIVA, E NAO REESCRITA ============
--
-- Restritiva entra em E logico com a permissiva que ja existe, entao ela
-- SUBTRAI permissao sem que eu precise saber o que a outra concede. Reescrever
-- a permissiva arriscaria afrouxar a leitura sem querer. Mesmo padrao da
-- 20260828030000, que negou exclusao de linha de sistema.
--
-- ============ POR QUE POLICY BASTA, e foi CONFERIDO ============
--
-- Service role ignora RLS, entao policy nao alcanca edge function. As duas que
-- tocam a tabela, `superadmin-manage-user` e `superadmin-provisionar-clinica`,
-- foram lidas: as duas apenas SELECIONAM a linha do chamador para autorizar, e
-- NENHUMA escreve operador. O unico caminho de escrita e direto do front, e ele
-- passa por RLS.
--
-- Se um dia uma function passar a criar operador, esta guarda deixa de alcancar
-- aquele caminho, e a verificacao tem de ser repetida la dentro.
--
-- Faixa A da Sec. 2.5: e banco, e migra intacta.

-- =====================================================================
-- 1. QUEM E DONO DA PLATAFORMA
-- =====================================================================
--
-- Funcao propria em vez de subconsulta repetida nas policies, pelo Principio
-- VIII: o de-para de "dono" existe num lugar so. Se um dia `super_owner` virar
-- outra coisa, muda-se aqui.
--
-- `SECURITY DEFINER` porque ela le a propria tabela que as policies protegem, e
-- sem isso a leitura recursaria na policy.

CREATE OR REPLACE FUNCTION public.is_super_owner(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.superadmin_operators
    WHERE user_id = _user_id AND active = true AND role = 'super_owner'
  )
$$;

REVOKE EXECUTE ON FUNCTION public.is_super_owner(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_super_owner(uuid) TO authenticated;

COMMENT ON FUNCTION public.is_super_owner(uuid) IS
  'Dono da plataforma: operador ativo com papel super_owner. Separa "opera" de '
  '"controla quem opera". Ver 20260902010000.';

-- =====================================================================
-- 2. SO O DONO CRIA, ALTERA E REMOVE OPERADOR
-- =====================================================================
--
-- `auth.uid() IS NULL` cobre service role e os seeds `SECURITY DEFINER`, que
-- rodam sem JWT. Mesmo padrao de `prevent_clinic_id_change` (20260724233525) e
-- de `protege_linha_de_sistema` (20260828030000). Sem isso, provisionamento por
-- function quebraria.
--
-- A LEITURA continua livre a todo operador, de proposito: a equipe precisa ver
-- quem esta no time, e esconder isso nao protege nada.

DROP POLICY IF EXISTS "So o dono cria operador" ON public.superadmin_operators;
CREATE POLICY "So o dono cria operador"
  ON public.superadmin_operators AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (auth.uid() IS NULL OR public.is_super_owner(auth.uid()));

DROP POLICY IF EXISTS "So o dono altera operador" ON public.superadmin_operators;
CREATE POLICY "So o dono altera operador"
  ON public.superadmin_operators AS RESTRICTIVE FOR UPDATE TO authenticated
  USING (auth.uid() IS NULL OR public.is_super_owner(auth.uid()))
  WITH CHECK (auth.uid() IS NULL OR public.is_super_owner(auth.uid()));

DROP POLICY IF EXISTS "So o dono remove operador" ON public.superadmin_operators;
CREATE POLICY "So o dono remove operador"
  ON public.superadmin_operators AS RESTRICTIVE FOR DELETE TO authenticated
  USING (auth.uid() IS NULL OR public.is_super_owner(auth.uid()));

-- =====================================================================
-- 3. A PLATAFORMA NAO PODE FICAR SEM DONO
-- =====================================================================
--
-- A guarda acima cria um jeito novo de se trancar para fora: o unico
-- `super_owner` se rebaixa, ou se desativa, e a partir dali NINGUEM pode criar
-- ou promover operador. So service role destravaria, e isso significa pedir
-- socorro a plataforma.
--
-- Hoje ha exatamente UM operador e ele e `super_owner`, entao o risco nao e
-- teorico: e uma tela de distancia.
--
-- Nao entra na policy porque policy responde por LINHA, e esta pergunta e sobre
-- o CONJUNTO: "sobrou algum dono?". Gatilho ve o depois.

CREATE OR REPLACE FUNCTION public.exige_um_dono_da_plataforma()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_donos int;
BEGIN
  SELECT count(*) INTO v_donos
    FROM public.superadmin_operators
   WHERE active = true AND role = 'super_owner';

  IF v_donos = 0 THEN
    RAISE EXCEPTION
      'A plataforma ficaria sem dono. Promova outro operador a super_owner '
      'antes de rebaixar, desativar ou remover o ultimo.'
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NULL;
END;
$$;

-- `AFTER`, `STATEMENT` e `DEFERRABLE` nao se aplicam aqui: o gatilho precisa
-- ver o estado FINAL da tabela, e por isso e AFTER e por linha, com a contagem
-- feita depois da mudanca.
DROP TRIGGER IF EXISTS operadores_exige_um_dono ON public.superadmin_operators;
CREATE TRIGGER operadores_exige_um_dono
  AFTER UPDATE OR DELETE ON public.superadmin_operators
  FOR EACH ROW EXECUTE FUNCTION public.exige_um_dono_da_plataforma();

COMMENT ON FUNCTION public.exige_um_dono_da_plataforma() IS
  'Impede que a plataforma fique sem nenhum super_owner ativo, o que trancaria '
  'a gestao de operadores para sempre. Ver 20260902010000.';
