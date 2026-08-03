# Contract — Edge Functions (Fase 3)

Portadas de `../nexclin-lovable/supabase/functions`. Guardas mantidas: **bearer +
`is_superadmin`**. **Nenhuma action define senha** (Princípio II).

## `superadmin-manage-user`
Guarda: valida JWT (bearer) e `is_superadmin` antes de qualquer action.

### action `update_email`
- **Entrada:** `{ user_id, new_email }`
- **Efeito:** troca o e-mail de login via Admin API; grava `email_change` em
  `superadmin_audit_log` com diff `old→new`.
- **Resposta:** `200 { ok, old_email, new_email }`.

### action `send_password_reset`
- **Entrada:** `{ email }`
- **Efeito:** dispara `resetPasswordForEmail` (entrega via Resend). Grava
  `password_reset_sent` na auditoria.
- **Resposta:** `200 { ok }`.
- **Proibido:** definir/gravar senha diretamente — **jamais**.

### Erros
- Sem token / token inválido → `401`.
- Token válido mas não superadmin → `403`.

## `invite-team-user`
Guarda: bearer + autorização do solicitante (admin da clínica ou superadmin).
- **Entrada:** dados do convidado + vínculo (clínica, papel/permissões).
- **Efeito:** cria usuário convidado via Admin API e o vínculo em `team_members`
  (respeitando `enforce_team_user_limit` → estoura se exceder `max_users`).
- **Resposta:** `200 { ok, user_id }` ou `409`/erro claro se limite excedido.
- **Senha:** convidado define via fluxo de convite/reset — nunca setada aqui.

## Smoke test (aceite F3)
- `curl` sem `Authorization` → **401**.
- Token de usuário comum → **403**.
- `update_email` como superadmin → registro `email_change` com `old→new`.

## Não portar agora (backlog → `specs/BACKLOG.md`)
- `anamnesis-public` (endpoint público) — Fase futura.
- `generate-insights` — depende do gateway de IA do Lovable; **re-especificar**
  com API própria.
