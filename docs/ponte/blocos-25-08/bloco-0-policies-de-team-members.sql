-- BLOCO 0B. O que já existe em `team_members`. Só lê. Não muda nada.
--
-- # Por que este bloco nasceu
--
-- Em 25/08, no painel de chat do Lovable, o agente deles afirmou ter feito
-- exatamente a correção que o Bloco 5B faz:
--
--   "substituí a política aberta da equipe por regras granulares (leitura para
--    a clínica, gestão só para administradores, autoedição sem poder alterar
--    cargo/permissões/repasse)"
--
-- Se isso rodou, o 5B pode ser redundante, e pode conflitar. Duas camadas
-- fazendo a mesma checagem por caminhos diferentes é como nasce o bug em que
-- uma delas é afrouxada e ninguém percebe, porque a outra ainda segura.
--
-- **Rode isto ANTES do Bloco 5B.** Se voltar mais de uma policy, ou qualquer
-- trigger com nome parecido, pare e me mande o resultado.

-- 1. As policies que existem hoje na tabela.
--
--    Antes da correção: UMA linha, `cmd = 'ALL'`, com a condição sendo só o
--    `clinic_id`. Se aparecerem várias, separadas por comando, a correção do
--    agente do Lovable rodou, e o 5B precisa ser reavaliado.
SELECT
  policyname,
  cmd,
  roles::text,
  qual        AS condicao_using,
  with_check  AS condicao_with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename  = 'team_members'
ORDER BY cmd, policyname;

-- 2. Os triggers que existem hoje na tabela.
--
--    Esperado antes do Bloco 5B: nada com "autoconcessao", "permissao" ou
--    "repasse" no nome. Se já houver, a regra foi implementada de outra forma.
SELECT
  t.tgname                                   AS trigger_name,
  p.proname                                  AS funcao,
  pg_get_triggerdef(t.oid)                   AS definicao
FROM pg_trigger t
JOIN pg_class     c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_proc      p ON p.oid = t.tgfoid
WHERE n.nspname = 'public'
  AND c.relname = 'team_members'
  AND NOT t.tgisinternal
ORDER BY t.tgname;

-- 3. Quem tem permissão de escrita na tabela, e em quais colunas.
--
--    Se a correção do agente tiver ido por GRANT de coluna em vez de policy,
--    é aqui que aparece: `permission_level`, `permissions` e as colunas de
--    repasse sumiriam da lista de UPDATE para `authenticated`.
SELECT
  grantee,
  privilege_type,
  string_agg(column_name, ', ' ORDER BY column_name) AS colunas
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name   = 'team_members'
  AND grantee      = 'authenticated'
  AND privilege_type IN ('UPDATE', 'INSERT')
GROUP BY grantee, privilege_type
ORDER BY privilege_type;
