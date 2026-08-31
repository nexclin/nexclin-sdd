-- =====================================================================
-- CONTA MORTA, e por que o superadmin nao a enxerga.
--
-- TRES BLOCOS. Rode um de cada vez e leia antes do seguinte.
-- TODOS SAO SOMENTE LEITURA. Nenhum escreve nada. Nao ha ROLLBACK a dar
-- porque nao ha transacao de escrita: sao SELECTs e um DO que so acumula texto.
-- =====================================================================
--
-- ============ A PERGUNTA QUE ISTO RESPONDE ============
--
-- Arthur, 31/08/2026: "quero saber se todas as alteracoes que o super admin
-- consegue fazer dentro da conta do cliente, ele tambem consegue fazer e
-- vice-versa."
--
-- A resposta lida no codigo e NAO: `my_permission` devolve `full` para o
-- superadmin na PRIMEIRA linha, antes de olhar assinatura, plano ou permissao
-- individual. Estes blocos provam isso contra o banco ao vivo, e medem a
-- consequencia pratica.
--
-- ============ A CONSEQUENCIA, QUE E O MOTIVO REAL DESTE ARQUIVO ============
--
-- Se uma clinica nasce sem `account_subscriptions`, esta linha da
-- `my_permission` devolve `none` em TODO modulo para o dono:
--
--     IF v_modules IS NULL OR NOT COALESCE((v_modules->>_module)::boolean,false)
--       THEN RETURN 'none';
--
-- Nada abre, e o dono nao consegue clicar em coisa nenhuma. Mas o superadmin
-- impersonando passa pelo bypass da linha 114 e VE TUDO FUNCIONANDO.
--
-- Ou seja: o Vinicius provisiona, confere por impersonacao, ve a conta
-- perfeita, entrega ao cliente, e o cliente abre e nao clica em nada. O metodo
-- de conferencia e justamente o que nao detecta o defeito.
--
-- Ja havia registro disso em 25/08, item 2 da verificacao da bateria: "a
-- clinica nasce sem `account_subscriptions`, `my_permission` devolve `none`
-- para o proprio dono". A migracao `20260825080000` foi escrita e NAO aplicada.
-- =====================================================================


-- =====================================================================
-- BLOCO 1: o censo. Que clinicas existem, e quais tem assinatura.
-- =====================================================================

SELECT
  c.name                                            AS clinica,
  c.id                                              AS clinic_id,
  count(s.id)                                       AS assinaturas,
  max(s.status::text)                               AS status,
  max(p.name)                                       AS plano,
  (SELECT count(*) FROM public.profiles pr WHERE pr.clinic_id = c.id) AS pessoas,
  CASE
    WHEN count(s.id) = 0 THEN 'SEM ASSINATURA: o dono nao abre nada'
    WHEN max(s.status::text) IN ('suspended','cancelled') THEN 'assinatura ' || max(s.status::text)
    ELSE 'ok'
  END                                               AS veredito
FROM public.clinics c
LEFT JOIN public.account_subscriptions s ON s.clinic_id = c.id
LEFT JOIN public.plans p ON p.id = s.plan_id
GROUP BY c.id, c.name
ORDER BY count(s.id) ASC, c.name;

-- 1b. A FORMA de `enabled_modules`, que e um jeito silencioso de matar a conta.
--
-- A coluna nasce `DEFAULT '[]'::jsonb`, ou seja um ARRAY. E a `my_permission`
-- le como OBJETO:
--
--     NOT COALESCE((v_modules->>_module)::boolean, false)  ->  RETURN 'none'
--
-- Num array, `->>'dashboard'` devolve NULL, o COALESCE vira false, e TODO
-- modulo responde `none`, inclusive para o admin da clinica, porque a checagem
-- de modulo vem ANTES do `has_role(admin)`. Plano guardado no formato errado
-- mata toda clinica que o assina, e nao aparece em lugar nenhum ate o cliente
-- tentar abrir a tela.
--
-- Esperado: `object` em todos. Qualquer `array` aqui e defeito.

SELECT
  p.name                                    AS plano,
  jsonb_typeof(p.enabled_modules)           AS forma,
  CASE jsonb_typeof(p.enabled_modules)
    WHEN 'object' THEN (SELECT count(*) FROM jsonb_object_keys(p.enabled_modules))
    ELSE jsonb_array_length(p.enabled_modules)
  END                                       AS itens,
  (SELECT count(*) FROM public.account_subscriptions s WHERE s.plan_id = p.id) AS clinicas,
  CASE jsonb_typeof(p.enabled_modules)
    WHEN 'object' THEN 'ok'
    ELSE '<<< ARRAY: my_permission le como objeto, toda clinica deste plano morre'
  END                                       AS veredito
FROM public.plans p
ORDER BY 2 DESC, 1;


-- =====================================================================
-- BLOCO 2: o que o DONO de cada clinica realmente enxerga.
-- =====================================================================
--
-- Percorre as 15 ModuleKeys do contrato, para cada clinica, respondendo como o
-- dono dela. Nao troca de ROLE: `my_permission` e SECURITY DEFINER, entao ela
-- roda como o definidor de qualquer jeito, e o que decide o resultado e
-- `auth.uid()`, que vem do claim. Trocar o papel so atrapalharia as leituras de
-- catalogo desta propria consulta.
--
-- Pula quem e operador da plataforma, senao o bypass mascara o resultado e o
-- teste responde sobre outra pessoa.

DO $censo$
DECLARE
  MODULOS text[] := ARRAY[
    'dashboard','leads','pacientes','anamnese','consultas','acompanhamento',
    'tarefas','contas_receber','contas_pagar','fluxo_caixa','relatorios_vendas',
    'relatorios_demais','configuracoes','equipe','insights'];
  r        record;
  m        text;
  v_perm   text;
  v_none   int;
  v_full   int;
  v_out    text := '';
  v_claim  text;
BEGIN
  FOR r IN
    SELECT c.id, c.name,
           (SELECT pr.user_id
              FROM public.profiles pr
             WHERE pr.clinic_id = c.id
               AND NOT EXISTS (SELECT 1 FROM public.superadmin_operators o
                                WHERE o.user_id = pr.user_id)
             ORDER BY pr.created_at
             LIMIT 1) AS dono
      FROM public.clinics c
     ORDER BY c.name
  LOOP
    IF r.dono IS NULL THEN
      v_out := v_out || rpad(left(r.name, 28), 30)
                     || 'SEM PESSOA COMUM: so operador, nao da para medir' || E'\n';
      CONTINUE;
    END IF;

    v_claim := json_build_object('sub', r.dono::text, 'role', 'authenticated')::text;
    PERFORM set_config('request.jwt.claims', v_claim, true);

    v_none := 0; v_full := 0;
    FOREACH m IN ARRAY MODULOS LOOP
      v_perm := public.my_permission(m);
      IF v_perm = 'none' THEN v_none := v_none + 1; END IF;
      IF v_perm = 'full' THEN v_full := v_full + 1; END IF;
    END LOOP;

    v_out := v_out || rpad(left(r.name, 28), 30)
                   || 'none=' || lpad(v_none::text, 2)
                   || '  full=' || lpad(v_full::text, 2)
                   || '  de 15   '
                   || CASE
                        WHEN v_none = 15 THEN '<<< CONTA MORTA: nao abre NADA'
                        WHEN v_none > 0  THEN 'parcial, ' || v_none || ' modulo(s) fora'
                        ELSE 'ok'
                      END
                   || E'\n';
  END LOOP;

  -- Devolve o claim ao estado anterior, para nao contaminar o proximo bloco.
  PERFORM set_config('request.jwt.claims', '', true);

  RAISE NOTICE E'\n%', v_out;
  PERFORM set_config('censo.r', v_out, false);
END
$censo$;

SELECT current_setting('censo.r', true) AS o_que_o_dono_enxerga;


-- =====================================================================
-- BLOCO 3: a assimetria, medida lado a lado na MESMA clinica.
-- =====================================================================
--
-- Pega uma clinica, e pergunta o mesmo modulo duas vezes: como o dono e como o
-- operador da plataforma. Se as duas colunas diferirem, esta provado que a tela
-- do superadmin NAO e a tela do cliente, e que conferir por impersonacao nao
-- responde pelo que o cliente vai ver.

DO $assim$
DECLARE
  MODULOS text[] := ARRAY['dashboard','contas_receber','relatorios_vendas','insights','equipe'];
  v_clinic uuid;
  v_nome   text;
  v_dono   uuid;
  v_oper   uuid;
  m        text;
  v_d      text;
  v_o      text;
  v_out    text := '';
  v_dif    int := 0;
BEGIN
  -- A clinica e escolhida JUNTO com o dono, e nao antes dele.
  --
  -- A primeira versao escolhia a clinica com menos assinaturas e so depois
  -- procurava um dono comum. Na primeira execucao, em 31/08, caiu na clinica
  -- propria da conta mestra, cujos unicos perfis sao operadores da plataforma,
  -- e o bloco respondeu `dono=nulo` sem medir nada. O `JOIN LATERAL` garante
  -- que so entra clinica que TEM dono comum.
  SELECT c.id, c.name, d.user_id INTO v_clinic, v_nome, v_dono
    FROM public.clinics c
    JOIN LATERAL (
      SELECT pr.user_id
        FROM public.profiles pr
       WHERE pr.clinic_id = c.id
         AND NOT EXISTS (SELECT 1 FROM public.superadmin_operators o
                          WHERE o.user_id = pr.user_id)
       ORDER BY pr.created_at
       LIMIT 1
    ) d ON true
   ORDER BY (SELECT count(*) FROM public.account_subscriptions s WHERE s.clinic_id = c.id) ASC,
            c.name
   LIMIT 1;

  SELECT o.user_id INTO v_oper
    FROM public.superadmin_operators o
   WHERE o.active
   LIMIT 1;

  IF v_dono IS NULL OR v_oper IS NULL THEN
    PERFORM set_config('assim.r',
      'CONTEXTO FALTANDO: dono=' || coalesce(v_dono::text,'nulo') ||
      ' operador=' || coalesce(v_oper::text,'nulo') || E'.\n' ||
      CASE WHEN v_dono IS NULL THEN
        'NENHUMA clinica do banco tem pessoa que nao seja operador da ' ||
        'plataforma.' || E'\n' ||
        'Isso e resultado, e nao falha: significa que so existem contas de ' ||
        'teste' || E'\n' ||
        'operadas por voces, e que a assimetria so podera ser medida quando ' ||
        'houver' || E'\n' ||
        'uma clinica com dono de verdade.'
      ELSE
        'Nao ha operador ativo em superadmin_operators.'
      END, false);
    RETURN;
  END IF;

  v_out := 'clinica medida: ' || v_nome || E'\n\n'
        || rpad('modulo', 22) || rpad('o dono ve', 14) || 'o superadmin ve' || E'\n'
        || repeat('-', 55) || E'\n';

  FOREACH m IN ARRAY MODULOS LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_dono::text, 'role','authenticated')::text, true);
    v_d := public.my_permission(m);

    PERFORM set_config('request.jwt.claims',
      json_build_object('sub', v_oper::text, 'role','authenticated')::text, true);
    v_o := public.my_permission(m);

    IF v_d IS DISTINCT FROM v_o THEN v_dif := v_dif + 1; END IF;

    v_out := v_out || rpad(m, 22) || rpad(v_d, 14) || v_o
                   || CASE WHEN v_d IS DISTINCT FROM v_o THEN '   <<< diferente' ELSE '' END
                   || E'\n';
  END LOOP;

  PERFORM set_config('request.jwt.claims', '', true);

  v_out := v_out || E'\n' || CASE
    WHEN v_dif > 0 THEN
      'PROVADO: ' || v_dif || ' de ' || array_length(MODULOS,1) ||
      ' modulos diferem. Conferir a conta por impersonacao NAO' || E'\n' ||
      'responde pelo que o cliente vai ver, e demonstrar assim mostra ao' || E'\n' ||
      'cliente modulo que o plano dele pode nao incluir.'
    ELSE
      'Nesta clinica as duas visoes coincidem. Isso NAO derruba a assimetria:' || E'\n' ||
      'ela some quando o plano ja libera tudo. Repita numa clinica de plano' || E'\n' ||
      'menor, ou com assinatura suspensa, que e onde ela aparece.'
  END;

  PERFORM set_config('assim.r', v_out, false);
END
$assim$;

SELECT current_setting('assim.r', true) AS dono_contra_superadmin;
