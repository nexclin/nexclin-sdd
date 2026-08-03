# Quickstart / Validação — SPEC 001

Roteiro de validação ponta a ponta. Os 7 cenários abaixo são os **critérios de
aceite** que Arthur executa manualmente ao final da Fase 4 ("implementado ≠
funciona"). Não contém código de implementação — só pré-requisitos, passos e
resultado esperado.

## Pré-requisitos de ambiente

- Projeto Supabase próprio criado; `.env.local` com `NEXT_PUBLIC_SUPABASE_URL`,
  `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
  `SUPERADMIN_EMAIL=erpclinicas@gmail.com`.
- Fases 1–3 aprovadas (banco replicado, seed rodado, edge functions no ar).
- Senha real do superadmin definida via recovery no painel do Supabase (pós-F2).
- App Next.js rodando (`npm run dev`) e uma clínica de teste com plano associado.

## Setup rápido

```bash
# na raiz do repo novo
supabase db push                 # aplica as 56 migrações (Fase 1)
npx tsx scripts/seed.ts           # seed idempotente (Fase 2)
supabase functions deploy         # edge functions (Fase 3)
npm run dev                       # app (Fase 4)
```

## Cenários de aceite

### 1. Login superadmin × usuário comum
- **Passos:** acessar `/superadmin/login`, entrar com `SUPERADMIN_EMAIL`.
- **Esperado:** painel abre. Usuário comum tentando `/superadmin/*` → 403/redirect.
- **Verifica:** `SuperAdminGuard` + `is_superadmin`.

### 2. Impersonação completa e auditada
- **Passos:** contas → detalhe → "Acessar conta" (confirmar) → escrever 1
  registro na clínica-alvo → trocar de clínica sem sair → "Sair da conta".
- **Esperado:** banner âmbar "Modo suporte — <clínica>" em todas as rotas; a
  escrita persiste na clínica certa; ao sair, âncora restaurada; todos os
  eventos em `superadmin_audit_log` (`impersonation_start/end`).
- **Verifica:** `superadmin_enter_clinic` / `superadmin_exit_clinic`, cache
  zerado a cada troca, `OnboardingGuard` com bypass sob impersonação.

### 3. Teto do plano vence permissão individual
- **Setup:** plano da clínica **sem** `contas_pagar`; usuário com permissão
  individual `full` em `contas_pagar`.
- **Esperado:** menu esconde o módulo; URL direta `/contas-pagar` bloqueia.
- **Verifica:** `my_permission` (plano é o teto; individual nunca excede).

### 4. Conta suspensa
- **Setup:** `account_subscriptions.status = suspended`.
- **Esperado:** usuário comum → tela de bloqueio; superadmin impersonando →
  acesso pleno.
- **Verifica:** `get_my_subscription_state` na cascata.

### 5. Limite de usuários (`max_users=1`)
- **Passos:** com 1 acesso ativo, tentar adicionar o 2º (inclusive via
  reativação de um inativo).
- **Esperado:** bloqueio com mensagem clara; nenhum 2º acesso criado.
- **Verifica:** `enforce_team_user_limit` / `clinic_within_user_limit`
  (comparação estrita `<`).

### 6. Edição de perfil pelo painel
- **Passos:** superadmin edita o perfil de um cliente; depois edita o próprio;
  troca o e-mail de login de um cliente; usuário comum tenta `INSERT` direto em
  `profiles`.
- **Esperado:** edição do cliente audita `old→new`; **auto-edição não audita**;
  `update_email` troca o login; `INSERT` do usuário comum → **negado** por RLS.
- **Verifica:** `audit_superadmin_profile_edit`, edge `superadmin-manage-user`
  (`update_email`), política de INSERT ausente em `profiles`.

### 7. Idempotência do seed
- **Passos:** rodar `scripts/seed.ts` duas vezes.
- **Esperado:** segunda execução não duplica plano Trial, `saas_settings`,
  usuário superadmin nem `superadmin_operators`.
- **Verifica:** upserts / `ON CONFLICT` do seed.

## Smoke tests automatizados (mínimos — Princípio V)

- **Unit (Vitest):** hook de permissão resolve a cascata (superadmin, suspenso,
  fora do plano, individual, default deny).
- **E2E (Playwright):** `ProtectedRoute`, `RequirePermission`, `SuperAdminGuard`
  bloqueiam/permitem conforme esperado; fluxo de impersonação entra e sai.
- **Edge (F3):** chamada sem token → 401/403.
