# Contract — RPCs do banco (consumidas pelo front)

O front **só consome**; a decisão de acesso mora no banco (Princípio I). Assinaturas
conforme o schema validado. Todas com `REVOKE EXECUTE` de PUBLIC/anon.

## `my_permission(_module text) → text`
- **Retorna:** nível de acesso ao módulo (`full` / … / `none`).
- **Cascata (garantida pelo banco):** superadmin → `full`; assinatura
  `suspended/cancelled` → `none`; módulo ausente/false em `enabled_modules` do
  plano → `none`; admin da clínica → `full`; senão permissão individual do
  team_member; **fallback `none`** (default deny).
- **Uso no front:** `RequirePermission`, montagem do menu.
- **Contrato inegociável:** o plano é o teto; individual nunca excede.

## `get_my_subscription_state() → record`
- **Retorna:** estado da assinatura da clínica logada (status + flags).
- **Uso:** tela de conta suspensa; gate de acesso ao app.

## `get_my_clinic_id() → uuid`
- **Retorna:** âncora da clínica do usuário (respeita impersonação ativa).

## `is_superadmin(_uid uuid default auth.uid()) → boolean`
- **Uso:** `SuperAdminGuard`, login do painel.

## `superadmin_enter_clinic(_clinic_id uuid) → ...`
- **Efeito:** troca auditada da âncora para a clínica alvo; abre sessão em
  `superadmin_impersonation_sessions`; grava `impersonation_start` na auditoria.
- **Guarda:** exige `is_superadmin`; usuário comum → erro "Acesso negado".

## `superadmin_exit_clinic() → ...`
- **Efeito:** restaura a âncora; fecha a sessão; grava `impersonation_end`.

## `get_my_active_impersonation() → record | null`
- **Uso:** renderizar o banner âmbar "Modo suporte — <clínica>".

## Erros esperados
- Chamar RPC de superadmin sem ser superadmin → exceção/deny (mapear para 403 no
  front).
- Qualquer módulo não concedido → `none` (nunca "vazar" acesso por omissão).
