-- =====================================================================
-- ACEITE da 20260902010000: so o super_owner gere operadores.
--
-- DOIS BLOCOS. Rode o 1 ANTES de aplicar a migracao, e o 2 DEPOIS.
-- Os dois rodam dentro de BEGIN/ROLLBACK e NAO gravam nada.
-- =====================================================================
--
-- ============ POR QUE O BLOCO 1 EXISTE ============
--
-- Porque asercao negativa passa por vacuidade. "Operador comum nao cria
-- operador" fica verdadeiro se o teste estiver errado, se o usuario escolhido
-- nao existir, ou se outra coisa barrar antes. O bloco 1 prova que HOJE ele
-- CONSEGUE. Sem esse vermelho, o verde do bloco 2 nao significa nada.
--
-- Foi assim que o FR-005 quase passou por engano: tres checagens liam OK com a
-- tabela nao existindo.
--
-- ============ O CONTEXTO, MEDIDO EM 02/09 ============
--
-- Existe UM operador na plataforma, `erpclinicas@gmail.com`, papel
-- `super_owner`. Como nao ha operador comum, os dois blocos CRIAM um dentro da
-- transacao, exercitam, e desfazem no ROLLBACK.
-- =====================================================================


-- =====================================================================
-- BLOCO 1: o vermelho. Rode ANTES da migracao.
-- Esperado: o operador comum CONSEGUE criar e promover. Se ja vier negado,
-- a migracao ja foi aplicada, ou algo mais mudou, e vale investigar antes.
-- =====================================================================

BEGIN;

SELECT set_config('op.r', '', true);

DO $antes$
DECLARE
  v_comum uuid;
  v_novo  uuid;
  v_out   text := '';
BEGIN
  -- Um usuario qualquer que NAO seja operador hoje.
  SELECT p.user_id INTO v_comum
    FROM public.profiles p
   WHERE NOT EXISTS (SELECT 1 FROM public.superadmin_operators o
                      WHERE o.user_id = p.user_id)
   LIMIT 1;

  -- Um SEGUNDO usuario real, para o alvo do INSERT. A primeira versao usava
  -- `gen_random_uuid()`, e como `user_id` referencia `auth.users`, os dois
  -- INSERTs morriam com 23503, `foreign_key_violation`, ANTES de a guarda
  -- opinar. O teste dizia "negado" sem nada ter sido negado pela policy.
  SELECT p.user_id INTO v_novo
    FROM public.profiles p
   WHERE p.user_id <> v_comum
     AND NOT EXISTS (SELECT 1 FROM public.superadmin_operators o
                      WHERE o.user_id = p.user_id)
   LIMIT 1;

  IF v_comum IS NULL OR v_novo IS NULL THEN
    PERFORM set_config('op.r', 'CONTEXTO FALTANDO: sao precisos DOIS usuarios '
      || 'fora da tabela de operadores.', true);
    RETURN;
  END IF;

  -- Vira operador COMUM, papel `suporte`. E esta a pessoa cujo poder se quer
  -- limitar: hoje `is_superadmin` diz sim para ela, porque so olha `active`.
  INSERT INTO public.superadmin_operators (user_id, role, active, name, email)
  VALUES (v_comum, 'suporte', true, 'TESTE suporte', 'teste@exemplo.invalido');

  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_comum::text, 'role', 'authenticated')::text, true);

  -- A1: um `suporte` cria outro operador?
  BEGIN
    INSERT INTO public.superadmin_operators (user_id, role, active, name, email)
    VALUES (v_novo, 'admin', true, 'TESTE criado por suporte', 'x@exemplo.invalido');
    v_out := v_out || 'A1 suporte cria operador ......... CONSEGUE (e o buraco)' || E'\n';
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'A1 suporte cria operador ......... negado (' || SQLSTATE || ')' || E'\n';
  END;

  -- A2: um `suporte` promove a si mesmo a dono da plataforma?
  BEGIN
    UPDATE public.superadmin_operators
       SET role = 'super_owner'
     WHERE user_id = v_comum;
    IF FOUND THEN
      v_out := v_out || 'A2 suporte se promove a dono ..... CONSEGUE (e o buraco)' || E'\n';
    ELSE
      v_out := v_out || 'A2 suporte se promove ............ zero linha' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'A2 suporte se promove ............ negado (' || SQLSTATE || ')' || E'\n';
  END;

  PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('op.r', v_out, true);
END
$antes$;

RESET ROLE;
SELECT current_setting('op.r', true) AS antes_da_migracao;

ROLLBACK;


-- =====================================================================
-- BLOCO 2: o verde. Rode DEPOIS da migracao.
--
-- Esperado, nesta ordem:
--   B1 negado, B2 negado, B3 PERMITIDO, B4 negado com 23514.
--
-- O B3 e o controle positivo, e sem ele os outros tres nao provam nada: se o
-- dono tambem nao conseguisse, "negado" viria de qualquer coisa, e nao da
-- guarda.
-- =====================================================================

BEGIN;

SELECT set_config('op.r2', '', true);

DO $depois$
DECLARE
  v_comum uuid;
  v_dono  uuid;
  v_novo  uuid;
  v_out   text := '';
BEGIN
  SELECT o.user_id INTO v_dono
    FROM public.superadmin_operators o
   WHERE o.active AND o.role = 'super_owner'
   LIMIT 1;

  SELECT p.user_id INTO v_comum
    FROM public.profiles p
   WHERE NOT EXISTS (SELECT 1 FROM public.superadmin_operators o
                      WHERE o.user_id = p.user_id)
   LIMIT 1;

  SELECT p.user_id INTO v_novo
    FROM public.profiles p
   WHERE p.user_id <> v_comum
     AND NOT EXISTS (SELECT 1 FROM public.superadmin_operators o
                      WHERE o.user_id = p.user_id)
   LIMIT 1;

  IF v_dono IS NULL OR v_comum IS NULL OR v_novo IS NULL THEN
    PERFORM set_config('op.r2',
      'CONTEXTO FALTANDO: dono=' || coalesce(v_dono::text,'nulo') ||
      ' comum=' || coalesce(v_comum::text,'nulo') ||
      ' alvo=' || coalesce(v_novo::text,'nulo'), true);
    RETURN;
  END IF;

  INSERT INTO public.superadmin_operators (user_id, role, active, name, email)
  VALUES (v_comum, 'suporte', true, 'TESTE suporte', 'teste@exemplo.invalido');

  -- ---- como OPERADOR COMUM ----
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_comum::text, 'role', 'authenticated')::text, true);

  BEGIN
    INSERT INTO public.superadmin_operators (user_id, role, active, name, email)
    VALUES (v_novo, 'admin', true, 'TESTE', 'y@exemplo.invalido');
    v_out := v_out || 'B1 suporte cria operador ......... FALHOU, ainda consegue' || E'\n';
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B1 suporte cria operador ......... OK, negado (' || SQLSTATE || ')' || E'\n';
  END;

  BEGIN
    UPDATE public.superadmin_operators SET role = 'super_owner' WHERE user_id = v_comum;
    IF FOUND THEN
      v_out := v_out || 'B2 suporte se promove a dono ..... FALHOU, ainda consegue' || E'\n';
    ELSE
      v_out := v_out || 'B2 suporte se promove a dono ..... OK, zero linha' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B2 suporte se promove a dono ..... OK, negado (' || SQLSTATE || ')' || E'\n';
  END;

  -- ---- como DONO: o controle positivo ----
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_dono::text, 'role', 'authenticated')::text, true);

  BEGIN
    INSERT INTO public.superadmin_operators (user_id, role, active, name, email)
    VALUES (v_novo, 'admin', true, 'TESTE do dono', 'z@exemplo.invalido');
    v_out := v_out || 'B3 dono cria operador ............ OK, permitido' || E'\n';
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B3 dono cria operador ....... FALHOU, negado (' || SQLSTATE
                   || '). Sem isto, os outros nao provam nada' || E'\n';
  END;

  -- B4: o dono tira o proprio papel e deixa a plataforma sem dono.
  BEGIN
    UPDATE public.superadmin_operators SET role = 'admin' WHERE user_id = v_dono;
    v_out := v_out || 'B4 dono se rebaixa sozinho ....... FALHOU, plataforma sem dono' || E'\n';
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B4 dono se rebaixa sozinho ....... OK, negado (' || SQLSTATE
                   || '), esperado 23514' || E'\n';
  END;

  PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('op.r2', v_out, true);
END
$depois$;

RESET ROLE;
SELECT current_setting('op.r2', true) AS depois_da_migracao;

ROLLBACK;
