# Quickstart — validação da SPEC 002

Cenários que provam a correção ponta a ponta. Executados manualmente por Arthur
(Princípio IV). Ordem obrigatória: a Fase 0 é gate.

## Pré-condição — backup

Exportar dados antes de qualquer escrita (Cloud → Advanced → Export). O tier
atual não tem PITR; um erro amplo é irreversível sem isto.

## Fase 0 — confirmar ao vivo (leitura pura, 30 segundos)

No SQL do Lovable:

```sql
select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and 'anon' = any(roles) order by tablename;

select column_name from information_schema.columns
where table_name = 'patients' and column_name = 'deleted_at';
select to_regclass('public.data_audit_log') as tem_audit_log;
```

**Esperado para prosseguir:** a primeira query retorna policies de `anamnesis_*`
com `qual = true` (Achado 1 vivo); a segunda e a terceira retornam vazio/nulo
(Achado 2 vivo). Se já corrigido, registrar e encerrar a fase correspondente.

## Achado 1 — anamnese por token

1. **Anon não lê mais a tabela:** requisição anônima direta a
   `GET /rest/v1/anamnesis_responses?select=*` → vazio/negado.
2. **pg_policies:** a query da Fase 0 não retorna mais policy `anon` em
   `anamnesis_*`.
3. **Formulário funciona:** abrir `/anamnese-publica/:token` de uma resposta
   pendente → carrega os campos → preencher → enviar → grava.
4. **Token consumido é inerte:** reabrir o mesmo `:token` → bloqueado (`410`);
   novo POST → bloqueado.
5. **Isolamento:** um token não devolve dado de outra resposta/clínica.

## Achado 2 — auditoria e soft delete de `patients`

1. **Auditoria no DELETE:** apagar um paciente de teste pelo app → linha em
   `data_audit_log` com `actor` (quem), `created_at` (quando), `action=DELETE`,
   `previous_state` (a linha inteira).
2. **Soft delete:** o paciente some das listas, mas a linha existe com
   `deleted_at` preenchido.
3. **Reconstrução:** a partir de `previous_state`, os dados originais voltam.
4. **Isolamento:** usuário de outra clínica não lê `data_audit_log` nem o
   paciente da primeira.

## Backport (stack nova)

5. As mesmas migrações existem em `supabase/migrations` e passam no hook
   `guarda-constituicao` (0 acusação relacionada a anon/RLS nelas).
6. `auditor-multitenant` revê a edge function e os triggers sem achado alto.

## Fecho

Todos os itens acima verdes = SPEC 002 aceita. Registrar em
`docs/seguranca/` a confirmação, com data.
