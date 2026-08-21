# Data Model — deltas de schema (SPEC 002)

Só as mudanças. Nada de recriar tabelas existentes.

## `anamnesis_responses` (alteração)

| Campo | Tipo | Regra |
|---|---|---|
| `public_token` | `uuid not null default gen_random_uuid()` | **novo**; índice único; é o que vai na URL pública, nunca o `id` |

Policies:
- **Remover** `"Anon can read response by id"` (SELECT anon USING true)
- **Remover** `"Anon can update pending response"` (UPDATE anon)
- **Manter** a policy de `authenticated` por clínica (inalterada)
- Acesso anônimo passa a existir **só** pela edge function (service role)

Transição de estado (inalterada, agora aplicada na edge function):
`pendente → preenchido`. Token só serve enquanto `status = 'pendente'`.

## `anamnesis_config` (alteração)

- **Remover** `"Anon can read anamnesis config"` (SELECT anon USING true). A
  config do formulário é devolvida pela edge function junto com a resposta.

## `data_audit_log` (tabela nova)

| Campo | Tipo | Nota |
|---|---|---|
| `id` | `uuid pk default gen_random_uuid()` | |
| `clinic_id` | `uuid not null` | âncora multi-tenant |
| `table_name` | `text not null` | `'patients'` no MVP desta spec |
| `record_id` | `uuid not null` | id da linha afetada |
| `action` | `text not null` | `INSERT` / `UPDATE` / `DELETE` |
| `actor` | `uuid` | `auth.uid()` — nulo se service role/sistema |
| `previous_state` | `jsonb` | linha inteira ANTES (permite reconstruir) |
| `created_at` | `timestamptz not null default now()` | |

RLS: **habilitado**. SELECT só para admin da própria clínica e superadmin —
filtro por `clinic_id = get_my_clinic_id()` + papel. Sem INSERT/UPDATE/DELETE por
usuário (só o trigger escreve, via service role). Default deny para o resto.

## `patients` (alteração)

| Campo | Tipo | Regra |
|---|---|---|
| `deleted_at` | `timestamptz null` | **novo**; soft delete |

- Trigger `AFTER INSERT/UPDATE/DELETE` → grava em `data_audit_log` com
  `previous_state` = linha anterior completa.
- Exclusão do app vira `update ... set deleted_at = now()`.
- Leituras filtram `deleted_at is null`; RLS/policies ajustadas para não vazar
  linha "apagada" em nenhum papel.

## Backport (stack nova)

As mesmas quatro mudanças como migrações versionadas em `supabase/migrations`,
reescritas na ordem/nome deste repo. O `guarda-constituicao` confirma: nenhuma
policy `anon USING(true)` em tabela de negócio, RLS presente na tabela nova.
