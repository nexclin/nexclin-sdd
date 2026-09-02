-- =====================================================================
-- DOIS BLOCOS. RODE UM DE CADA VEZ, e leia o resultado antes do seguinte.
--
-- BLOCO 1: censo de `is_system`. SOMENTE LEITURA, nao abre transacao.
-- BLOCO 2: o B4 do FR-006, que ficou NAO PROVADO em 30/08. BEGIN/ROLLBACK.
-- =====================================================================
--
-- ============ POR QUE O BLOCO 1 VEIO PARAR AQUI ============
--
-- O handoff de 30/08 mandou rodar o B4 contra `closing_types` "que tem linhas
-- comuns". Ao conferir o esquema antes de escrever o teste, a premissa nao se
-- sustentou, e no lugar dela apareceu um defeito:
--
--   closing_types.is_system    NOT NULL DEFAULT true   (20260322191407)
--   chart_of_accounts.is_system NOT NULL DEFAULT true   (20260322185846)
--   bank_accounts.is_system    NOT NULL DEFAULT false  (20260510231935)
--
-- Nas duas primeiras o default e `true`, e nenhum caminho de escrita informa a
-- coluna: `ConfigListDialog.tsx:57` da plataforma ao vivo insere
-- `{ name, clinic_id }`, e `Acompanhamento.tsx:1684` insere
-- `{ clinic_id, name, active }`. Na stack nova o campo e removido de proposito
-- na fronteira (`entrada.test.ts:68`).
--
-- Ou seja: linha que a CLINICA cria nasce marcada como linha de SISTEMA. Isso
-- era inofensivo enquanto `is_system` so pintava um selo. Desde que a migracao
-- 20260828030000 entrou no banco, o gatilho `protege_linha_de_sistema` trava
-- essa linha: so `active` muda, e a exclusao e negada por policy restritiva.
--
-- O `ConfigListDialog` nem le `is_system`, entao ele oferece lapis e lixeira na
-- linha travada. Renomear devolve um toast generico. Apagar nao devolve erro
-- nenhum, porque zero linha afetada nao e erro no PostgREST, e a tela diz
-- "Excluido!" sobre um registro que continua la.
--
-- Isto foi LIDO no codigo e no esquema. NAO foi provado no banco. O bloco 1
-- existe justamente para provar ou derrubar, com numero.
-- =====================================================================


-- =====================================================================
-- BLOCO 1: censo. Somente leitura. Nao altera nada.
-- =====================================================================
--
-- 1a. O default de cada coluna, direto do catalogo. E o fato de origem.

SELECT c.table_name,
       c.column_default,
       c.is_nullable
  FROM information_schema.columns c
 WHERE c.table_schema = 'public'
   AND c.column_name  = 'is_system'
 ORDER BY c.table_name;

-- 1b. Quantas linhas de `closing_types` estao marcadas como de sistema SEM
-- terem vindo do seed. O seed (`seed_closing_types`, 20260322191407) insere
-- exatamente sete nomes. Qualquer outro nome com `is_system` verdadeiro e uma
-- linha que a clinica criou e que nasceu travada.
--
-- Esperado se o defeito for real: `criadas_pela_clinica_travadas` > 0 em pelo
-- menos uma clinica que ja mexeu em tipos de fechamento. Zero em todas
-- significa que ninguem criou tipo novo ainda, e nao que o defeito nao existe.

SELECT cl.name AS clinica,
       count(*) FILTER (
         WHERE ct.is_system
           AND ct.name NOT IN ('Fechou Completo','Fechou Parcial','Fechou por Sessão',
                               'Em Negociação','Não Fechou','Recaptação','Cortesia')
       ) AS criadas_pela_clinica_travadas,
       count(*) FILTER (WHERE ct.is_system)     AS is_system,
       count(*) FILTER (WHERE NOT ct.is_system) AS comuns,
       count(*)                                  AS total
  FROM public.closing_types ct
  JOIN public.clinics cl ON cl.id = ct.clinic_id
 GROUP BY cl.name
 ORDER BY criadas_pela_clinica_travadas DESC, cl.name;

-- 1c. Onde existe linha comum, em qualquer das tres tabelas do FR-006. E o
-- que o bloco 2 precisa para nao sair inconclusivo de novo.

SELECT 'closing_types'     AS tabela, cl.name AS clinica, count(*) AS comuns
  FROM public.closing_types t JOIN public.clinics cl ON cl.id = t.clinic_id
 WHERE NOT t.is_system GROUP BY cl.name
UNION ALL
SELECT 'chart_of_accounts', cl.name, count(*)
  FROM public.chart_of_accounts t JOIN public.clinics cl ON cl.id = t.clinic_id
 WHERE NOT t.is_system GROUP BY cl.name
UNION ALL
SELECT 'bank_accounts', cl.name, count(*)
  FROM public.bank_accounts t JOIN public.clinics cl ON cl.id = t.clinic_id
 WHERE NOT t.is_system GROUP BY cl.name
 ORDER BY 1, 3 DESC;


-- =====================================================================
-- BLOCO 2: o B4. Roda inteiro dentro de BEGIN/ROLLBACK. NAO grava nada.
-- =====================================================================
--
-- ============ POR QUE NAO BASTA TROCAR O NOME DA TABELA ============
--
-- O B4 e uma asercao NEGATIVA: "tem de ser negado". Asercao negativa e
-- trivialmente satisfeita por qualquer coisa que impeca o UPDATE de chegar ao
-- gatilho. Quatro causas produzem o MESMO "negado" ou o MESMO zero linha:
--
--   1. o gatilho do FR-006 negou, que e o unico resultado que queremos;
--   2. o RLS escondeu a linha do usuario, e o UPDATE casou zero linha;
--   3. outra constraint da tabela negou, com outro ERRCODE;
--   4. o gatilho nem existe naquela tabela, e ai "passou" seria o certo.
--
-- Entao ha um CONTROLE POSITIVO antes: mesmo usuario, mesma linha, um UPDATE
-- que TEM de passar. Se o controle passa e o B4 e negado com 23514, a unica
-- explicacao que sobra e o gatilho. Se o controle falha, o B4 nao significa
-- nada, e o bloco diz isso em vez de arredondar.
--
-- E ele VARRE as tres tabelas em vez de apostar numa, porque a premissa de que
-- `closing_types` tem linha comum e justamente o que o bloco 1 questiona.
--
-- ============ COMO LER ============
--
-- Sai UMA linha com um texto dentro. O veredito esta no fim. Nao leia o
-- veredito sem ler o controle positivo antes.
-- =====================================================================

BEGIN;

SELECT set_config('b4.r', '', true);

DO $b4$
DECLARE
  v_clinic   uuid;
  v_user     uuid;
  v_tabs     text[] := ARRAY['closing_types','chart_of_accounts','bank_accounts'];
  v_cols     text[] := ARRAY['name','name','bank_name'];
  i          int;
  v_n        int;
  v_id       uuid;
  v_alvo_tab text;
  v_alvo_col text;
  v_alvo_id  uuid;
  v_trig     int;
  v_vis      int;
  v_out      text := '';
  v_ok_ctrl  boolean := false;
  v_state    text;
BEGIN
  SELECT id INTO v_clinic FROM public.clinics WHERE name = 'Clínica Teste Final';

  SELECT p.user_id INTO v_user
    FROM public.profiles p
   WHERE p.clinic_id = v_clinic
     AND NOT EXISTS (
           SELECT 1 FROM public.superadmin_operators o WHERE o.user_id = p.user_id)
   LIMIT 1;

  v_out := 'P0 contexto' || E'\n'
        || '   clinica ......... ' || coalesce(v_clinic::text, 'NAO ACHADA') || E'\n'
        || '   usuario comum ... ' || coalesce(v_user::text, 'NAO ACHADO')  || E'\n';

  IF v_clinic IS NULL OR v_user IS NULL THEN
    PERFORM set_config('b4.r', v_out ||
      E'\nVEREDITO: CONTEXTO FALTANDO. O B4 NAO foi testado.', true);
    RETURN;
  END IF;

  -- Procura a primeira das tres tabelas que tenha linha comum nesta clinica.
  FOR i IN 1..array_length(v_tabs, 1) LOOP
    EXECUTE format(
      'SELECT count(*), min(id) FROM public.%I WHERE clinic_id = $1 AND NOT is_system',
      v_tabs[i]) INTO v_n, v_id USING v_clinic;

    v_out := v_out || '   ' || rpad(v_tabs[i], 18) || ' linhas comuns: ' || v_n || E'\n';

    IF v_n > 0 AND v_alvo_tab IS NULL THEN
      v_alvo_tab := v_tabs[i];
      v_alvo_col := v_cols[i];
      v_alvo_id  := v_id;
    END IF;
  END LOOP;

  IF v_alvo_tab IS NULL THEN
    PERFORM set_config('b4.r', v_out ||
      E'\nVEREDITO: NENHUMA das tres tabelas tem linha comum nesta clinica.' ||
      E'\nO B4 continua NAO PROVADO, e isto e resultado, nao falha do teste:' ||
      E'\nreforca o defeito do default `is_system = true`. Ver o bloco 1.', true);
    RETURN;
  END IF;

  -- O gatilho existe na tabela escolhida? Sem ele, "passou" seria o certo, e
  -- confundir as duas coisas e como o teste passaria pelo motivo errado.
  EXECUTE format(
    'SELECT count(*) FROM pg_trigger WHERE tgrelid = %L::regclass'
    || ' AND tgname = %L AND NOT tgisinternal',
    'public.' || v_alvo_tab, v_alvo_tab || '_protege_sistema') INTO v_trig;

  v_out := v_out || E'\n' || 'P1 alvo e controle positivo' || E'\n'
        || '   tabela .......... ' || v_alvo_tab || E'\n'
        || '   linha ........... ' || v_alvo_id  || E'\n'
        || '   gatilho presente  ' || v_trig || '   (esperado 1)' || E'\n';

  IF v_trig <> 1 THEN
    PERFORM set_config('b4.r', v_out ||
      E'\nVEREDITO: o gatilho NAO esta nesta tabela. E a migracao 20260828030000' ||
      E'\nque nao pegou aqui, e nao ha B4 a provar.', true);
    RETURN;
  END IF;

  -- Deixa de ser superusuario. Daqui para baixo o RLS e o gatilho decidem de
  -- verdade. O terceiro argumento `true` diz "local a transacao".
  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_user::text, 'role', 'authenticated')::text, true);

  EXECUTE format('SELECT count(*) FROM public.%I WHERE id = $1', v_alvo_tab)
    INTO v_vis USING v_alvo_id;
  v_out := v_out || '   visivel sob RLS . ' || v_vis || '   (esperado 1)' || E'\n';

  -- Controle: renomear a linha comum. Nenhum ramo do gatilho se aplica, porque
  -- `is_system` continua falso nos dois lados. Tem de passar.
  BEGIN
    EXECUTE format('UPDATE public.%I SET %I = %I || '' CONTROLE'' WHERE id = $1',
                   v_alvo_tab, v_alvo_col, v_alvo_col) USING v_alvo_id;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n > 0 THEN
      v_ok_ctrl := true;
      v_out := v_out || '   renomear ........ OK, passou' || E'\n';
    ELSE
      v_out := v_out || '   renomear ........ ZERO LINHA, e o RLS, nao o gatilho' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_out := v_out || '   renomear ........ NEGADO (' || SQLSTATE || '), e nao devia ser' || E'\n';
  END;

  -- O B4: promover a PROPRIA linha a linha de sistema.
  -- Esperado: 23514, levantado pelo ramo `ELSIF NEW.is_system`.
  v_out := v_out || E'\n' || 'P2 o B4, tem de ser NEGADO' || E'\n';
  BEGIN
    EXECUTE format('UPDATE public.%I SET is_system = true WHERE id = $1', v_alvo_tab)
      USING v_alvo_id;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n > 0 THEN
      v_state := 'PASSOU';
      v_out := v_out || '   promover ........ PASSOU, e o FR-006 falhou' || E'\n';
    ELSE
      v_state := 'ZERO';
      v_out := v_out || '   promover ........ zero linha, nao foi o gatilho' || E'\n';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_state := SQLSTATE;
    v_out := v_out || '   promover ........ negado, ERRCODE ' || v_state || E'\n';
  END;

  -- O veredito depende dos DOIS anteriores, e nunca so do segundo.
  v_out := v_out || E'\n' || 'P3 veredito' || E'\n';

  IF NOT v_ok_ctrl THEN
    v_out := v_out ||
      '   INCONCLUSIVO. O controle positivo nao passou, entao o resultado' || E'\n' ||
      '   do P2 nao pode ser atribuido ao gatilho do FR-006.' || E'\n';
  ELSIF v_state = '23514' THEN
    v_out := v_out ||
      '   B4 PROVADO em ' || v_alvo_tab || '. O controle passou na mesma' || E'\n' ||
      '   linha e com o mesmo usuario, e a promocao foi negada com 23514,' || E'\n' ||
      '   que e o check_violation do ramo ELSIF NEW.is_system. Nao foi o' || E'\n' ||
      '   RLS, que daria zero linha, e nao foi 42501.' || E'\n';
  ELSIF v_state = 'PASSOU' THEN
    v_out := v_out ||
      '   B4 REPROVADO. O gatilho existe e ainda assim deixou a clinica' || E'\n' ||
      '   marcar a propria linha como de sistema.' || E'\n';
  ELSE
    v_out := v_out ||
      '   B4 NAO PROVADO. O UPDATE foi barrado, mas por ' || v_state || ', e nao' || E'\n' ||
      '   pelo 23514 do FR-006. Descobrir o que barrou antes de contar' || E'\n' ||
      '   isto como aceite.' || E'\n';
  END IF;

  PERFORM set_config('b4.r', v_out, true);
END
$b4$;

RESET ROLE;

SELECT current_setting('b4.r', true) AS b4_fr006;

ROLLBACK;
