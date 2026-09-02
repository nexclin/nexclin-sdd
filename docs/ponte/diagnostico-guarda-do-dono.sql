-- =====================================================================
-- DIAGNOSTICO da guarda do dono. SOMENTE LEITURA, nao altera nada.
--
-- Rode os DOIS blocos e mande as duas saidas.
-- =====================================================================
--
-- ============ POR QUE ISTO EXISTE ============
--
-- O aceite de 02/09 reprovou, e o meu teste tinha defeito:
--
--   B1 e B3 deram 23503, que e `foreign_key_violation`, e nao negacao de
--   policy. Os dois inseriam com `gen_random_uuid()`, um UUID que nao existe em
--   `auth.users`, e `superadmin_operators.user_id` referencia aquela tabela. Os
--   dois bateram na FK antes de chegar na guarda.
--
--   B4 falhou por cascata: o B2 conseguiu virar `super_owner`, entao ainda
--   havia um dono quando o B4 rodou, e o gatilho corretamente nao disparou.
--
-- Sobra o B2, que e a duvida de verdade: o operador comum promoveu a si mesmo.
-- Duas explicacoes possiveis, e elas pedem consertos OPOSTOS:
--
--   (a) as policies nao existem, e a migracao nao pegou como se pensou;
--   (b) as policies existem, e o TESTE nao esta rodando como usuario comum,
--       porque a troca de papel nao surtiu efeito e o RLS foi ignorado.
--
-- Consertar a migracao quando o defeito e do teste seria estragar o que
-- funciona. Por isso: medir antes.


-- =====================================================================
-- BLOCO A: as policies e o gatilho existem?
-- =====================================================================

SELECT
  p.policyname                                  AS policy,
  p.cmd                                         AS comando,
  p.permissive                                  AS tipo,
  coalesce(p.qual, '(sem USING)')               AS usando,
  coalesce(p.with_check, '(sem WITH CHECK)')    AS com_check
FROM pg_policies p
WHERE p.schemaname = 'public'
  AND p.tablename  = 'superadmin_operators'
ORDER BY p.permissive DESC, p.cmd, p.policyname;

-- Esperado: as tres restritivas de 02/09 (INSERT, UPDATE, DELETE) mais a
-- permissiva antiga "Superadmins can manage operators", que e FOR ALL.
-- Na coluna `tipo`, restritiva aparece como RESTRICTIVE.

SELECT
  (SELECT count(*) FROM pg_proc  WHERE proname = 'is_super_owner')              AS funcao_is_super_owner,
  (SELECT count(*) FROM pg_proc  WHERE proname = 'exige_um_dono_da_plataforma') AS funcao_do_gatilho,
  (SELECT count(*) FROM pg_trigger
    WHERE tgname = 'operadores_exige_um_dono' AND NOT tgisinternal)             AS gatilho,
  (SELECT relrowsecurity FROM pg_class
    WHERE oid = 'public.superadmin_operators'::regclass)                        AS rls_ligado,
  (SELECT relforcerowsecurity FROM pg_class
    WHERE oid = 'public.superadmin_operators'::regclass)                        AS rls_forcado;

-- `rls_forcado` e a coluna que pode explicar tudo. RLS NAO SE APLICA AO DONO DA
-- TABELA a menos que ela esteja verdadeira. Se o editor de SQL conecta como
-- dono, as policies ficam de enfeite para ele, e um teste rodado dali passa por
-- cima delas sem avisar.


-- =====================================================================
-- BLOCO B: a troca de papel surte efeito?
-- =====================================================================
--
-- Roda em BEGIN/ROLLBACK e nao grava nada. Responde quem o banco pensa que voce
-- e, antes e depois da troca, e se a guarda enxerga o usuario comum.

BEGIN;

SELECT set_config('diag.r', '', true);

DO $diag$
DECLARE
  v_comum uuid;
  v_out   text := '';
BEGIN
  SELECT p.user_id INTO v_comum
    FROM public.profiles p
   WHERE NOT EXISTS (SELECT 1 FROM public.superadmin_operators o
                      WHERE o.user_id = p.user_id)
   LIMIT 1;

  v_out := 'ANTES da troca' || E'\n'
        || '  current_user ....... ' || current_user || E'\n'
        || '  current_role ....... ' || current_role || E'\n'
        || '  auth.uid() ......... ' || coalesce(auth.uid()::text, 'nulo') || E'\n';

  PERFORM set_config('role', 'authenticated', true);
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_comum::text, 'role', 'authenticated')::text, true);

  v_out := v_out || E'\n' || 'DEPOIS da troca' || E'\n'
        || '  current_user ....... ' || current_user || E'\n'
        || '  current_role ....... ' || current_role || E'\n'
        || '  auth.uid() ......... ' || coalesce(auth.uid()::text, 'nulo') || E'\n'
        || '  is_superadmin() .... ' || coalesce(public.is_superadmin(auth.uid())::text, 'nulo') || E'\n'
        || '  is_super_owner() ... ' || coalesce(public.is_super_owner(auth.uid())::text, 'nulo') || E'\n';

  v_out := v_out || E'\n' || 'COMO LER' || E'\n'
        || '  Se current_user continuar postgres ou supabase_admin depois da' || E'\n'
        || '  troca, o RLS foi ignorado e o defeito e do TESTE.' || E'\n'
        || '  Se current_user virar authenticated e is_super_owner responder' || E'\n'
        || '  false, entao a guarda deveria ter negado, e o defeito e da' || E'\n'
        || '  MIGRACAO.' || E'\n';

  PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('diag.r', v_out, true);
END
$diag$;

RESET ROLE;
SELECT current_setting('diag.r', true) AS diagnostico;

ROLLBACK;
