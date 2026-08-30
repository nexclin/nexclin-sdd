-- =====================================================================
-- FR-006 da regra 005: ACEITE, PARTE B (comportamento).
-- Roda inteiro dentro de BEGIN/ROLLBACK. NAO grava nada.
-- =====================================================================
--
-- Esta e a parte que prova de verdade. Ela DEIXA de ser superusuario e passa a
-- ser um usuario comum da clinica, e tenta o que a regra proibe.
--
-- ============ POR QUE NAO USA TABELA TEMPORARIA ============
--
-- A primeira versao acumulava os resultados numa `CREATE TEMP TABLE`, e morria
-- com `42501 permission denied for table _r` ANTES de exercitar qualquer coisa:
-- a temporaria nasce do superusuario e a parte B roda como `authenticated`.
--
-- Conceder GRANT na temporaria resolveria, e adiciona um passo que precisa dar
-- certo para o teste sequer comecar. Acumular numa variavel de sessao nao
-- precisa de permissao nenhuma, porque GUC com prefixo proprio e livre para
-- qualquer papel. E o mesmo mecanismo que o Supabase usa para `request.jwt`.
--
-- ============ COMO LER O RESULTADO ============
--
-- Sai UMA linha, com um texto de quatro linhas dentro. Cada uma tem de dizer OK.
-- =====================================================================

BEGIN;

SELECT set_config('fr006.r', '', true);

DO $$
DECLARE
  v_user uuid;
  v_id   uuid;
  v_out  text := '';
BEGIN
  SELECT p.user_id INTO v_user
    FROM public.profiles p
   WHERE p.clinic_id = (SELECT id FROM public.clinics WHERE name = 'Clínica Teste Final')
     AND NOT EXISTS (SELECT 1 FROM public.superadmin_operators o WHERE o.user_id = p.user_id)
   LIMIT 1;

  SELECT id INTO v_id
    FROM public.chart_of_accounts
   WHERE clinic_id = (SELECT id FROM public.clinics WHERE name = 'Clínica Teste Final')
     AND is_system
   LIMIT 1;

  IF v_user IS NULL OR v_id IS NULL THEN
    PERFORM set_config('fr006.r',
      'CONTEXTO FALTANDO: usuario comum=' || coalesce(v_user::text,'nulo') ||
      ' linha is_system=' || coalesce(v_id::text,'nula') ||
      '. Comportamento NAO testado.', true);
    RETURN;
  END IF;

  -- Vira usuario comum da clinica. `true` = local a transacao.
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_user::text, 'role', 'authenticated')::text, true);

  -- B1: editar o NOME de linha de sistema tem de ser NEGADO.
  BEGIN
    UPDATE public.chart_of_accounts SET name = name || ' EDITADO' WHERE id = v_id;
    IF FOUND THEN
      v_out := v_out || 'B1 editar nome de linha de sistema ....... FALHOU (passou)' || E'\n';
    ELSE
      -- Zero linha afetada NAO e a trava do FR-006: e o RLS escondendo a linha.
      -- A distincao importa, senao o teste passa pelo motivo errado.
      v_out := v_out || 'B1 editar nome ........... invisivel ao RLS, inconclusivo' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B1 editar nome de linha de sistema ....... OK, negado ('
                   || SQLSTATE || ')' || E'\n';
  END;

  -- B2: alternar `active` tem de ser PERMITIDO. E o FR-005: a clinica desativa
  -- o que nao oferece. Trava que negasse tudo quebraria aquele requisito.
  BEGIN
    UPDATE public.chart_of_accounts SET active = NOT active WHERE id = v_id;
    IF FOUND THEN
      v_out := v_out || 'B2 alternar active ...................... OK, permitido' || E'\n';
    ELSE
      v_out := v_out || 'B2 alternar active ....... invisivel ao RLS, inconclusivo' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B2 alternar active .......... FALHOU, negado (' || SQLSTATE || ')' || E'\n';
  END;

  -- B3: apagar linha de sistema tem de ser NEGADO.
  BEGIN
    DELETE FROM public.chart_of_accounts WHERE id = v_id;
    IF FOUND THEN
      v_out := v_out || 'B3 apagar linha de sistema .............. FALHOU (apagou)' || E'\n';
    ELSE
      v_out := v_out || 'B3 apagar linha de sistema ......... OK, zero linha' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B3 apagar linha de sistema ....... OK, negado ('
                   || SQLSTATE || ')' || E'\n';
  END;

  -- B4: promover a PROPRIA linha a linha de sistema tem de ser NEGADO. E o
  -- caminho inverso, o que ninguem lembra de fechar.
  BEGIN
    UPDATE public.chart_of_accounts SET is_system = true
     WHERE clinic_id = (SELECT id FROM public.clinics WHERE name = 'Clínica Teste Final')
       AND NOT is_system;
    IF FOUND THEN
      v_out := v_out || 'B4 promover a si mesma a is_system ...... FALHOU (passou)' || E'\n';
    ELSE
      v_out := v_out || 'B4 promover a si mesma ... nenhuma linha comum, inconclusivo' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || 'B4 promover a si mesma a is_system ...... OK, negado ('
                   || SQLSTATE || ')' || E'\n';
  END;

  PERFORM set_config('fr006.r', v_out, true);
END $$;

RESET ROLE;

SELECT current_setting('fr006.r', true) AS resultado_do_comportamento;

ROLLBACK;
