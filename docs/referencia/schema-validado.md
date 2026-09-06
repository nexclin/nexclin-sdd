# Data Model — SPEC 001 (Phase 1)

Inventário do schema **validado** que a Fase 1 replica intacto. Extraído das 56
migrações em `../nexclin-lovable/supabase/migrations` (estado final acumulado).
Este documento é descritivo — a fonte de verdade são as migrações; o
`RELATORIO-FASE1.md` confirmará a paridade contra o banco aplicado.

## Visão geral

- **44 tabelas** no total (`public`).
- **3 enums**, **~40 funções**, triggers de negócio + segurança, RLS multi-tenant.
- Âncora multi-tenant: `profiles.clinic_id`.

## Tabelas (44)

### Globais (nível SaaS / sem isolamento por clínica)
| Tabela | Papel |
|---|---|
| `clinics` | a clínica (tenant) |
| `user_roles` | papel global do usuário (enum `app_role`) |
| `plans` | planos (preços, limites, `enabled_modules`) |
| `coupons` | cupons |
| `saas_settings` | singleton de configuração SaaS |
| `superadmin_operators` | identidade superadmin |
| `superadmin_audit_log` | auditoria de ações administrativas |
| `superadmin_impersonation_sessions` | sessões de impersonação (entrada/saída) |
| `account_subscriptions` | assinatura da conta (enum `subscription_status`) |
| `account_timeline` | linha do tempo da conta |
| `billings` | faturamento |

> A quantidade exata de tabelas que carregam **coluna** `clinic_id` (a spec
> esperava 43) é confirmada no RELATORIO-FASE1 — algumas das "globais" acima
> são de fato clinic-scoped (ex. `account_subscriptions`, `billings`,
> `account_timeline`).

### Perfil e acesso
`profiles` (âncora `clinic_id`, `user_id` UNIQUE) · `team_members` (permissão
operacional por módulo, `permission_level` + `permissions` jsonb, repasse médico)

### CRM / Comercial
`leads` · `lead_history` · `channels` · `origins` · `objections` ·
`funnel_2_entries` · `closings` · `closing_types`

### Clínico
`patients` · `appointments` · `appointment_items` · `consultation_types` ·
`services` · `prescriptions` · `anamnesis_config` · `anamnesis_responses` ·
`tasks`

### Financeiro
`revenues` · `receivables` · `expenses` · `fixed_expenses` ·
`payment_methods` · `expense_categories` · `acquirers` · `bank_accounts` ·
`chart_of_accounts` · `budgets` · `budget_items`

### Configuração / Gestão
`business_rules` · `goals`

### Inteligência
`ai_insights`

## Enums (3)

| Enum | Valores | Observação |
|---|---|---|
| `app_role` | `admin, medico, secretaria` **+ `user`** | `user` adicionado via `ALTER TYPE ADD VALUE` em `20260725001410` (isolado — risco fora-de-transação controlado) |
| `superadmin_role` | `super_owner, admin, suporte, financeiro` | nível SaaS |
| `subscription_status` | `trial, active, overdue, suspended, cancelled` | estado da assinatura |

## Funções-chave (SECURITY DEFINER)

> Todas com `REVOKE EXECUTE` de PUBLIC/anon aplicado na migração `20260802073330`
> (hardening) — replicar tal qual.

**Multi-tenant / acesso**
- `get_my_clinic_id()` — âncora da clínica do usuário logado
- `has_role(uuid, app_role)` — papel global
- `is_superadmin(uuid)` — identidade superadmin
- `get_my_team_member()` / `my_team_member_name()` — vínculo operacional
- `get_my_subscription_state()` — status da assinatura da clínica
- **`my_permission(text)`** — a cascata central (redefinida 5×; **versão final em
  `20260725034148`**, e não em `20260725033102`, corrigido em 05/09/2026):
  superadmin → status assinatura → teto do plano
  (`enabled_modules`) → permissão individual → **default deny**

  > **Ler a versão certa importa, e a diferença é de segurança.** A penúltima,
  > `20260725033102`, termina em `COALESCE(v_individual, 'full')`, ou seja
  > default **allow**. Ela foi substituída dez minutos depois por
  > `20260725034148`, que termina em `COALESCE(v_individual, 'none')`. Quem ler
  > a penúltima achando que é a final conclui que o banco é default-allow, e
  > isso é falso.
- `get_clinic_team_full()` — leitura consolidada da equipe

**Impersonação (superadmin)**
- `superadmin_enter_clinic(uuid)` — troca auditada da âncora
- `superadmin_exit_clinic()` — restaura a âncora
- `get_my_active_impersonation()` — sessão ativa

**Validação / limites**
- `prevent_clinic_id_change()` — trava estrutural da âncora
- `clinic_within_user_limit(uuid)` + `enforce_team_user_limit()` — limite de
  usuários do plano (comparação estrita `<`)
- `validate_enabled_modules()` — valida jsonb do plano contra as 15 ModuleKeys

**Provisão de conta**
- `handle_new_user()` — cria profile no signup (evoluída ao longo das migrações)
- `seed_chart_of_accounts / seed_closing_types / seed_native_services(uuid)` —
  seeds por clínica no onboarding (portar normalmente)
- `seed_superadmin_operator()` ⚠️ — seed com e-mail fixo; **manter a função,
  dropar só o trigger** (ver research R2)

**Automação de tarefas / util**
- `auto_complete_anamnese_task()` · `auto_complete_appointment_task()` ·
  `set_task_completed_at()` · `update_updated_at_column()`
- `audit_superadmin_profile_edit()` — grava diff old→new na auditoria

## Triggers relevantes

| Trigger | Tabela | Papel |
|---|---|---|
| `on_auth_user_created` | `auth.users` | dispara `handle_new_user` |
| `on_auth_user_created_superadmin` | `auth.users` | ⚠️ **NÃO portar** — seed e-mail fixo (dropar) |
| `profiles_prevent_clinic_id_change` | `profiles` | trava da âncora |
| `plans_validate_enabled_modules` | `plans` | valida as 15 ModuleKeys |
| `team_members_enforce_user_limit` | `team_members` | limite de usuários do plano |
| `trg_audit_superadmin_profile_edit` | `profiles` | auditoria de edição pelo superadmin |
| `update_*_updated_at` | várias | timestamp automático |

## RLS

Toda tabela de negócio com `clinic_id` tem `ENABLE ROW LEVEL SECURITY`, com
políticas no padrão subselect em `profiles` ou `get_my_clinic_id()`
(SECURITY DEFINER). `profiles` não tem política pública de INSERT (perfis nascem
só via `handle_new_user`). **Verificação da Fase 1:** nenhuma tabela com
`clinic_id` pode ficar sem RLS (Princípio I) → o RELATORIO-FASE1 lista RLS por
tabela.

## Auditoria — `superadmin_audit_log`

Registra: `impersonation_start` / `impersonation_end`, `profile_edit` (com diff
old→new), `email_change`, `password_reset_sent`. Auto-edição do próprio
superadmin **não** audita.

## As 15 ModuleKeys (contrato único — Princípio III)

```
dashboard · leads · pacientes · anamnese · consultas · acompanhamento ·
tarefas · contas_receber · contas_pagar · fluxo_caixa · relatorios_vendas ·
relatorios_demais · configuracoes · equipe · insights
```
Usadas identicamente em `plans.enabled_modules`, `team_members.permissions`,
guards de rota e menu. O seed da Fase 2 marca as 15 = `true` no plano Trial.
