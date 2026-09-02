-- =====================================================================
-- FR-005, ACEITE ESTRUTURAL. So leitura, nao escreve nada.
-- =====================================================================
--
-- Escrito ANTES da migracao, de proposito, em 29/08/2026.
--
-- Nao existe banco local neste projeto, entao nao existe teste de unidade que
-- exercite RLS. A decisao do Arthur em 29/08 foi nao subir Docker: ate 08/09 o
-- foco e a Lovable completa. O ciclo vermelho-verde continua valendo, e o que
-- muda e quem roda o teste: o banco ao vivo.
--
-- COMO USAR, e a ordem importa:
--   1. rode ISTO antes da migracao. Tudo tem de ler FALHOU. Se algo ja ler OK,
--      o objeto existe e a migracao nao e nova, entao PARE e descubra por que.
--   2. aplique `20260829040000_fr005_trilha_de_leitura.sql`
--   3. rode ISTO de novo. Tudo tem de ler OK.
--
-- Um teste que nunca foi visto falhando nao prova que ele pega alguma coisa.
-- E por isso que o passo 1 existe e nao e formalidade.
--
-- O QUE ELE NAO PROVA: os criterios de aceite 1, 2, 3 e 5 da secao 6 da regra
-- 017 sao COMPORTAMENTO, e exigem sessao de impersonacao viva e uma tela
-- abrindo prontuario. Isso e o aceite manual do Arthur, na fase 4. Aqui se
-- prova a ESTRUTURA: que a tabela e somente-anexacao, que ninguem escreve
-- direto, e que a funcao existe com a guarda certa.
-- =====================================================================

WITH v AS (

  -- ---------- A tabela ----------
  SELECT 1 AS ord,
         'A1  tabela patient_access_log existe' AS verificacao,
         (to_regclass('public.patient_access_log') IS NOT NULL)::text AS valor,
         'true' AS esperado

  UNION ALL
  -- Regra (a) da constituicao: RLS em TODA tabela com clinic_id, sem excecao.
  SELECT 2, 'A2  RLS habilitada',
         coalesce((SELECT relrowsecurity::text FROM pg_class
                    WHERE oid = to_regclass('public.patient_access_log')), 'AUSENTE'),
         'true'

  UNION ALL
  -- FR-005a: somente-anexacao. Policy de UPDATE nao pode existir para ninguem.
  SELECT 3, 'A3  ZERO policy de UPDATE',
         -- Condicionada a tabela EXISTIR. Sem isto a verificacao e verdadeira
         -- por vacuidade: "zero policies de UPDATE" e trivialmente satisfeito
         -- quando nao ha tabela, e ela leria OK mesmo com a migracao esquecida.
         -- Achado rodando o vermelho em 29/08/2026, antes de existir codigo.
         CASE WHEN to_regclass('public.patient_access_log') IS NULL THEN 'AUSENTE'
              ELSE (SELECT count(*)::text FROM pg_policies
                     WHERE schemaname='public' AND tablename='patient_access_log'
                       AND cmd='UPDATE') END,
         '0'

  UNION ALL
  SELECT 4, 'A4  ZERO policy de DELETE',
         -- Condicionada a tabela EXISTIR. Sem isto a verificacao e verdadeira
         -- por vacuidade: "zero policies de DELETE" e trivialmente satisfeito
         -- quando nao ha tabela, e ela leria OK mesmo com a migracao esquecida.
         -- Achado rodando o vermelho em 29/08/2026, antes de existir codigo.
         CASE WHEN to_regclass('public.patient_access_log') IS NULL THEN 'AUSENTE'
              ELSE (SELECT count(*)::text FROM pg_policies
                     WHERE schemaname='public' AND tablename='patient_access_log'
                       AND cmd='DELETE') END,
         '0'

  UNION ALL
  -- FR-005b: cliente nao escreve direto. Se houvesse policy de INSERT, daria
  -- para forjar linha na trilha, e trilha forjavel nao serve de prova.
  SELECT 5, 'A5  ZERO policy de INSERT',
         -- Condicionada a tabela EXISTIR. Sem isto a verificacao e verdadeira
         -- por vacuidade: "zero policies de INSERT" e trivialmente satisfeito
         -- quando nao ha tabela, e ela leria OK mesmo com a migracao esquecida.
         -- Achado rodando o vermelho em 29/08/2026, antes de existir codigo.
         CASE WHEN to_regclass('public.patient_access_log') IS NULL THEN 'AUSENTE'
              ELSE (SELECT count(*)::text FROM pg_policies
                     WHERE schemaname='public' AND tablename='patient_access_log'
                       AND cmd='INSERT') END,
         '0'

  UNION ALL
  -- Duas de leitura: uma para superadmin, uma para a clinica dona do dado.
  SELECT 6, 'A6  DUAS policies de SELECT',
         CASE WHEN to_regclass('public.patient_access_log') IS NULL THEN 'AUSENTE'
              ELSE (SELECT count(*)::text FROM pg_policies
                     WHERE schemaname='public' AND tablename='patient_access_log'
                       AND cmd IN ('SELECT','ALL')) END,
         '2'

  UNION ALL
  -- FR-005a: sem FK para patients. Com ON DELETE CASCADE, apagar o paciente
  -- apagaria a prova de que alguem o leu.
  SELECT 7, 'A7  ZERO chave estrangeira para patients',
         CASE WHEN to_regclass('public.patient_access_log') IS NULL THEN 'AUSENTE'
              ELSE (SELECT count(*)::text FROM pg_constraint
                     WHERE conrelid = to_regclass('public.patient_access_log')
                       AND contype = 'f'
                       AND confrelid = to_regclass('public.patients')) END,
         '0'

  UNION ALL
  -- As colunas que a regra exige, nomeadas uma a uma para o teste falhar se
  -- alguem renomear alguma sem atualizar a regra.
  SELECT 8, 'A8  colunas obrigatorias presentes',
         coalesce((SELECT count(*)::text FROM information_schema.columns
                    WHERE table_schema='public' AND table_name='patient_access_log'
                      AND column_name IN ('session_id','clinic_id','patient_id',
                                          'operator_user_id','operator_email',
                                          'context','read_at')), 'AUSENTE'),
         '7'

  -- ---------- A funcao ----------
  UNION ALL
  SELECT 9, 'B1  funcao registrar_leitura_de_paciente existe',
         (SELECT count(*)::text FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname='public' AND p.proname='registrar_leitura_de_paciente'),
         '1'

  UNION ALL
  -- SECURITY DEFINER e o que permite escrever numa tabela sem policy de INSERT.
  SELECT 10, 'B2  funcao e SECURITY DEFINER',
         coalesce((SELECT p.prosecdef::text FROM pg_proc p
                     JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname='public'
                      AND p.proname='registrar_leitura_de_paciente'), 'AUSENTE'),
         'true'

  UNION ALL
  -- search_path travado. Sem isto, SECURITY DEFINER e vetor de escalonamento:
  -- quem controlar o search_path escolhe qual funcao a definer vai chamar.
  SELECT 11, 'B3  search_path travado na funcao',
         coalesce((SELECT (p.proconfig IS NOT NULL
                           AND EXISTS (SELECT 1 FROM unnest(p.proconfig) c
                                        WHERE c LIKE 'search_path=%'))::text
                     FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname='public'
                      AND p.proname='registrar_leitura_de_paciente'), 'AUSENTE'),
         'true'

  UNION ALL
  -- Regra (b), default deny: anon nao executa.
  SELECT 12, 'B4  anon NAO executa a funcao',
         coalesce((SELECT has_function_privilege('anon',
                     p.oid, 'EXECUTE')::text
                     FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname='public'
                      AND p.proname='registrar_leitura_de_paciente'), 'AUSENTE'),
         'false'

  UNION ALL
  SELECT 13, 'B5  authenticated executa a funcao',
         coalesce((SELECT has_function_privilege('authenticated',
                     p.oid, 'EXECUTE')::text
                     FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
                    WHERE n.nspname='public'
                      AND p.proname='registrar_leitura_de_paciente'), 'AUSENTE'),
         'true'
)
SELECT v.verificacao, v.valor, v.esperado,
       CASE WHEN v.valor = v.esperado THEN 'OK' ELSE 'FALHOU' END AS resultado
  FROM v ORDER BY v.ord;
