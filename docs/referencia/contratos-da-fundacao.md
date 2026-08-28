# Contratos da fundação: RPCs, guards e edge functions

> **Referência.** Descreve o que já existe e é consumido, não o que se pretende
> construir. A regra que o governa é
> [`../regras/001-fundacao-superadmin.md`](../regras/001-fundacao-superadmin.md).
> Reunido em 27/08/2026 a partir dos três contratos da SPEC 001.

O front **só consome**: a decisão de acesso mora no banco (Princípio I). Nenhuma
regra de acesso pode existir só no front.

---

## Contract — RPCs do banco (consumidas pelo front)

O front **só consome**; a decisão de acesso mora no banco (Princípio I). Assinaturas
conforme o schema validado. Todas com `REVOKE EXECUTE` de PUBLIC/anon.

### `my_permission(_module text) → text`
- **Retorna:** nível de acesso ao módulo (`full` / … / `none`).
- **Cascata (garantida pelo banco):** superadmin → `full`; assinatura
  `suspended/cancelled` → `none`; módulo ausente/false em `enabled_modules` do
  plano → `none`; admin da clínica → `full`; senão permissão individual do
  team_member; **fallback `none`** (default deny).
- **Uso no front:** `RequirePermission`, montagem do menu.
- **Contrato inegociável:** o plano é o teto; individual nunca excede.

### `get_my_subscription_state() → record`
- **Retorna:** estado da assinatura da clínica logada (status + flags).
- **Uso:** tela de conta suspensa; gate de acesso ao app.

### `get_my_clinic_id() → uuid`
- **Retorna:** âncora da clínica do usuário (respeita impersonação ativa).

### `is_superadmin(_uid uuid default auth.uid()) → boolean`
- **Uso:** `SuperAdminGuard`, login do painel.

### `superadmin_enter_clinic(_clinic_id uuid) → ...`
- **Efeito:** troca auditada da âncora para a clínica alvo; abre sessão em
  `superadmin_impersonation_sessions`; grava `impersonation_start` na auditoria.
- **Guarda:** exige `is_superadmin`; usuário comum → erro "Acesso negado".

### `superadmin_exit_clinic() → ...`
- **Efeito:** restaura a âncora; fecha a sessão; grava `impersonation_end`.

### `get_my_active_impersonation() → record | null`
- **Uso:** renderizar o banner âmbar "Modo suporte — <clínica>".

### Erros esperados
- Chamar RPC de superadmin sem ser superadmin → exceção/deny (mapear para 403 no
  front).
- Qualquer módulo não concedido → `none` (nunca "vazar" acesso por omissão).

---

## Contract — Guards do app (Fase 4)

Paridade de **comportamento** com a referência (não estilo). Todo guard só
reflete o que o banco decide; nenhuma regra de acesso vive só no front (Princípio
I e III).

### `ProtectedRoute`
- **Regra:** sem sessão → redireciona para `/login`. Com sessão → renderiza.
- **Estado de carga:** enquanto resolve a sessão, não pisca conteúdo protegido.

### `RequirePermission({ module })`
- **Regra:** consulta `my_permission(module)`; se `none` → bloqueia (404/redirect
  + esconde do menu). Caso contrário renderiza.
- **Contrato de módulos:** `module` ∈ 15 ModuleKeys. String fora do contrato é
  erro de desenvolvimento.
- **Aceite:** cenário 3 do quickstart (plano vence individual).

### `SuperAdminGuard`
- **Regra:** valida `is_superadmin`; senão 403/redirect para `/superadmin/login`.
- **Escopo:** todas as rotas `/superadmin/*`.

### `OnboardingGuard`
- **Regra:** direciona clínica sem onboarding concluído para o fluxo inicial.
- **Bypass obrigatório:** **não** dispara sob impersonação
  (`get_my_active_impersonation()` ativo) — o superadmin entra direto na conta.

### Banner de impersonação (layout global)
- **Regra:** se `get_my_active_impersonation()` retorna sessão ativa, renderizar
  banner âmbar fixo "Modo suporte — <clínica>" em **todas** as rotas + ação
  "Sair da conta" (chama `superadmin_exit_clinic` e volta ao painel).
- **Cache:** invalidar/zerar o cache de dados (React Query) a cada entrada e
  saída de impersonação.

### Menu lateral
- **Regra:** montar itens a partir de `my_permission` por módulo — item com
  `none` **não aparece**. Espelha o bloqueio de rota (defesa em profundidade,
  mas a decisão continua no banco).

### Testes mínimos (Princípio V)
- E2E: cada guard bloqueia/permite conforme a matriz de permissão.
- Unit: hook que consome `my_permission` cobre superadmin, suspenso, fora do
  plano, individual e default deny.

---

## Contract — Edge Functions (Fase 3)

Portadas de `../nexclin-lovable/supabase/functions`. Guardas mantidas: **bearer +
`is_superadmin`**. **Nenhuma action define senha** (Princípio II).

### `superadmin-manage-user`
Guarda: valida JWT (bearer) e `is_superadmin` antes de qualquer action.

#### action `update_email`
- **Entrada:** `{ user_id, new_email }`
- **Efeito:** troca o e-mail de login via Admin API; grava `email_change` em
  `superadmin_audit_log` com diff `old→new`.
- **Resposta:** `200 { ok, old_email, new_email }`.

#### action `send_password_reset`
- **Entrada:** `{ email }`
- **Efeito:** dispara `resetPasswordForEmail` (entrega via Resend). Grava
  `password_reset_sent` na auditoria.
- **Resposta:** `200 { ok }`.
- **Proibido:** definir/gravar senha diretamente — **jamais**.

#### Erros
- Sem token / token inválido → `401`.
- Token válido mas não superadmin → `403`.

### `invite-team-user`
Guarda: bearer + autorização do solicitante (admin da clínica ou superadmin).
- **Entrada:** dados do convidado + vínculo (clínica, papel/permissões).
- **Efeito:** cria usuário convidado via Admin API e o vínculo em `team_members`
  (respeitando `enforce_team_user_limit` → estoura se exceder `max_users`).
- **Resposta:** `200 { ok, user_id }` ou `409`/erro claro se limite excedido.
- **Senha:** convidado define via fluxo de convite/reset — nunca setada aqui.

### Smoke test (aceite F3)
- `curl` sem `Authorization` → **401**.
- Token de usuário comum → **403**.
- `update_email` como superadmin → registro `email_change` com `old→new`.

### Não portar agora (backlog → `../regras/000-backlog.md`)
- `anamnesis-public` (endpoint público) — Fase futura.
- `generate-insights` — depende do gateway de IA do Lovable; **re-especificar**
  com API própria.

---

