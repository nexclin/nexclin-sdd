# SPEC 001 — Fundação: banco, auth, multi-tenant e Super Admin

> **Status:** aguardando aprovação da Fase 1.
> **Método:** Spec-Driven Development — cada fase só é implementada após aprovação explícita.
> **Referência (somente leitura):** `../nexclin-lovable`. Inventário completo: [`../INVENTARIO.md`](../INVENTARIO.md). Regras: [`../CLAUDE.md`](../CLAUDE.md).

---

## Objetivo

Replicar no **Supabase próprio** o banco validado do MVP e reconstruir em **Next.js + TypeScript** o acesso e o painel **Super Admin**, com **paridade de comportamento** com o sistema de referência.

## Pré-requisitos (pedir o que faltar antes de começar)

- [ ] Projeto **Supabase próprio** criado (tier gratuito).
- [ ] Variáveis em `.env.local` (**NUNCA** commitadas):
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `SUPERADMIN_EMAIL=erpclinicas@gmail.com`
- [ ] **Supabase CLI** instalada e **linkada** ao projeto novo.

---

## FASE 1 — Réplica do banco

1. Copiar as **55 migrações** de `../nexclin-lovable/supabase/migrations` para `supabase/migrations` deste repo e aplicá-las **EM ORDEM** no Supabase próprio via CLI.
2. **Atenção conhecida:** `ALTER TYPE ... ADD VALUE` não roda dentro de transação com uso imediato — se alguma migração falhar por isso, **dividir preservando a ordem**. (Relevante para `app_role` ganhar `'user'` em `20260725001410` — ver INVENTARIO §5.4.7.)
3. **Exceção deliberada:** **não** portar o trigger de seed do superadmin com e-mail fixo (`seed_superadmin_operator`). O seed será por script (Fase 2), dirigido por variável de ambiente.
4. **Verificação:** gerar `RELATORIO-FASE1.md` comparando o schema aplicado com a referência — contagem de tabelas (esperado: **43** com `clinic_id` + globais), políticas RLS por tabela, funções, triggers e enums. **Qualquer divergência: PARAR e reportar.**

## FASE 2 — Seeds e conta Super Admin

1. Script **idempotente** `scripts/seed.ts` (service role, **fora do bundle** do app):
   a. Plano **"Trial Padrão"**: `is_default_trial=true`, `status=active`, `visibility=hidden`, preços 0, `trial_days=14`, limites `NULL`, `enabled_modules` com as **15 ModuleKeys = true**.
   b. `saas_settings` singleton com `trial_default_plan_id` apontando para ele e `trial_default_days=14`.
   c. Usuário auth com e-mail `SUPERADMIN_EMAIL` (criar via admin API se não existir, com **senha aleatória descartada** — a senha real será definida pelo operador humano via reset no painel do Supabase; o script **NUNCA** recebe senha por variável ou código).
   d. Registro em `superadmin_operators` vinculado a esse `user_id`, `active=true`.
2. **Verificação:** rodar o script **2×** e provar idempotência (nada duplica).

## FASE 3 — Edge Functions

1. Portar de `../nexclin-lovable` as functions **`superadmin-manage-user`** e **`invite-team-user`** para `supabase/functions`, adaptando só o necessário (secrets via env do projeto novo). Manter as guardas: **bearer + `is_superadmin`**; `update_email` audita `old→new`; `send_password_reset` usa `resetPasswordForEmail`; **NENHUMA action define senha** (a `set_password` do MVP **não** é portada — ver regra (e)).
2. **`anamnesis-public`** e **`generate-insights`**: **NÃO** portar agora — registrar em [`BACKLOG.md`](BACKLOG.md) (`generate-insights` depende do gateway de IA do Lovable e será re-especificada).
3. Deploy via CLI + **smoke test** de auth (chamada sem token → 401/403).

## FASE 4 — App Next.js: acesso e painel Super Admin

Next.js (**App Router**) + TypeScript. Paridade de comportamento com a referência — ler as telas do MVP para extrair **regras**, não o estilo.

1. **Auth:** login e-mail/senha (Supabase Auth), reset de senha, guards de sessão. Rotas públicas e protegidas espelhando a referência.
2. **Guardas:** equivalentes a `ProtectedRoute`, `RequirePermission` (via `my_permission`/`get_my_subscription_state` do banco — a cascata plano→individual **já está no banco**, o front só consome), `SuperAdminGuard` e `OnboardingGuard` (com **bypass sob impersonação**).
3. **Painel `/superadmin`:** login próprio (valida `is_superadmin`) + telas: contas (lista + detalhe com **"Acessar conta"** e a seção de **Perfis** com edição auditada, troca de e-mail e envio de reset — paridade), planos (editor alinhado às **15 ModuleKeys**), cupons, faturamento, métricas, logs de auditoria, operadores, configurações.
4. **Impersonação:** botão "Acessar conta" com confirmação → RPC `superadmin_enter_clinic` → app da clínica com **banner âmbar fixo "Modo suporte — <clínica>"** em todas as rotas + **"Sair da conta"** (exit + volta ao painel). **Cache de dados zerado** a cada entrada/saída.
5. **App da clínica nesta spec:** apenas o **esqueleto navegável** (dashboard vazio + menu respeitando `my_permission`) — módulos de negócio virão em specs próprias.

---

## Regras transversais (do CLAUDE.md — valem em todas as fases)

RLS em toda tabela com `clinic_id`; **default deny**; segurança no banco, nunca só na tela; toda ação administrativa **auditada**; **nenhuma credencial** em código ou arquivo versionado; **TypeScript estrito**; testes automatizados mínimos: **guards de rota** e o **hook de permissões**.

---

## Critérios de aceite (roteiro de validação manual do responsável)

1. Login superadmin no painel funciona; usuário comum recebe **403/redirect**.
2. **Impersonação:** entrar → banner com nome certo → escrever um registro na clínica-alvo → trocar de clínica sem sair → sair → âncora restaurada → tudo em `superadmin_audit_log`.
3. **Plano sem `contas_pagar`:** menu esconde, URL direta bloqueia, **mesmo com permissão individual `full`**.
4. **Conta suspensa:** tela de bloqueio; superadmin impersonando: **acesso pleno**.
5. **`max_users=1`:** segundo acesso barrado com mensagem clara (inclusive reativação).
6. **Edição de perfil** pelo painel audita `old→new`; auto-edição **não** audita; `update_email` troca o login; **INSERT direto em `profiles` por usuário comum: negado**.
7. `seed.ts` rodado **2×** sem duplicar nada.

---

## Rastreabilidade → INVENTARIO.md

- Cascata `my_permission` (ordem canônica) — INVENTARIO §1.7.
- Impersonação (`superadmin_enter/exit_clinic`) + trava `prevent_clinic_id_change` — §1.6.
- Auditoria (`superadmin_audit_log`, trigger de perfil) — §1.6, §1.8.
- 15 ModuleKeys / níveis / status — §4.
- Edge functions e guardas de senha — §2.3, §2.4; regra (e) — §5.4.3–4.
- Decisões abertas a confirmar durante a implementação — §5.4.

## Plano de execução (gate por fase)

Cada fase abaixo é implementada **somente após aprovação explícita**. Ao concluir uma fase, gerar seu relatório/verificação e **parar**.

| Fase | Entregável | Gate de saída |
|---|---|---|
| 1 | `supabase/migrations/*` aplicadas + `RELATORIO-FASE1.md` | schema bate com a referência (43 tabelas, RLS/func/trigger/enum), zero divergência |
| 2 | `scripts/seed.ts` + conta superadmin + Trial Padrão + saas_settings | idempotência provada (2× sem duplicar) |
| 3 | `supabase/functions/{superadmin-manage-user,invite-team-user}` + `BACKLOG.md` | deploy + smoke test 401/403; nenhuma action define senha |
| 4 | App Next.js (auth, guards, painel superadmin, impersonação, esqueleto da clínica) | 7 critérios de aceite validados manualmente |

> **Próximo passo:** aprovar a **Fase 1** (e confirmar os pré-requisitos) para iniciar a réplica do banco.
