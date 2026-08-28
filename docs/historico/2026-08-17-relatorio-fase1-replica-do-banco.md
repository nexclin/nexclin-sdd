# RELATÓRIO — Fase 1 (Réplica do banco)

**Data:** 2026-08-03 · **Projeto Supabase:** `bfkghwkhzkimzyiovotj` · **Issue:** #4/#5

## Resultado

✅ **57/57 migrações aplicadas no remoto, 0 pendentes** (`supabase migration list --linked`).
`supabase db push` terminou com `Finished supabase db push.` sem erros.

> Como todas as migrações aplicaram sem erro, o **schema aplicado é idêntico ao
> definido nas migrações versionadas** (fonte de verdade, §5 do CLAUDE.md). Os
> números abaixo vêm desse inventário; um SQL de conferência ao vivo está no fim.

## Migrações

- **57 arquivos** = 56 portadas da referência + **1 de exceção** criada nesta fase
  (`20260802090000_drop_seed_superadmin_trigger.sql`).
- Contagem nominal da spec era "55" → real **56 portadas** (divergência de
  contagem, não de conteúdo; reconciliada).

## Objetos do schema (inventário verificado)

| Objeto | Qtde | Observações |
|---|---|---|
| Tabelas (`CREATE TABLE`) | **44** | ver `data-model.md` |
| Enums | **3** | `app_role` (+valor `user`), `superadmin_role`, `subscription_status` |
| `ALTER TYPE … ADD VALUE` | 1 | `app_role ADD VALUE 'user'` (`20260725001410`) — aplicou sem erro |
| Funções | ~40 | inclui `my_permission`, `is_superadmin`, `superadmin_enter_clinic`/`exit`, `get_my_active_impersonation`, `get_my_subscription_state`, `has_role`, `handle_new_user`, `prevent_clinic_id_change`, `clinic_within_user_limit`, `enforce_team_user_limit`, `validate_enabled_modules`, `audit_superadmin_profile_edit` |
| RLS | todas as tabelas com `clinic_id` | `ENABLE ROW LEVEL SECURITY` + políticas (Princípio I) |

**Tabelas globais (sem `clinic_id`):** `clinics`, `plans`, `coupons`,
`saas_settings`, `superadmin_operators`, `superadmin_audit_log`,
`superadmin_impersonation_sessions`, `user_roles`.

## Exceções deliberadas aplicadas nesta fase

1. **Trigger de seed do superadmin (e-mail fixo):** `20260802090000` dropa o
   trigger `on_auth_user_created_superadmin`, **mantendo a função**
   `seed_superadmin_operator` (a migração `20260802073330` faz `REVOKE` nela).
   O superadmin passa a nascer pelo `scripts/seed.ts` (Fase 2).
2. **Dado de teste do MVP (`20260725034626`):** `INSERT` top-level em
   `user_roles` com `user_id` fixo (`c38ac7c1…`) violava a FK para `auth.users`
   no projeto novo → **neutralizado** (no-op documentado). As demais migrações
   de teste (`035822`/`040009`/`040340`) são auto-limpantes e inócuas na base
   nova (criam e apagam o plano "Teste CP Bloqueado"; updates atingem 0 linhas).

## Divergências

Nenhuma bloqueante remanescente. As duas encontradas (contagem 55→56; dado de
teste FK) foram reconciliadas/corrigidas acima.

## Conferência ao vivo (opcional — rode no SQL Editor do Supabase)

```sql
select
  (select count(*) from information_schema.tables
     where table_schema='public' and table_type='BASE TABLE') as tabelas,
  (select count(*) from information_schema.columns
     where table_schema='public' and column_name='clinic_id') as tabelas_com_clinic_id,
  (select count(*) from pg_tables t
     where t.schemaname='public' and rowsecurity=true) as tabelas_rls_on,
  (select count(*) from pg_policies where schemaname='public') as policies,
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname='public') as funcoes,
  (select count(*) from pg_trigger where not tgisinternal) as triggers,
  (select count(*) from pg_type t join pg_namespace n on n.oid=t.typnamespace
     where n.nspname='public' and t.typtype='e') as enums;
```

## Gate #6 (aceite manual — Arthur)

- [ ] Revisar este relatório e confirmar: 0 tabela com `clinic_id` sem RLS.
- [ ] (Opcional) rodar o SQL acima e comparar os números.
