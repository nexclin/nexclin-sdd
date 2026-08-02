# INVENTÁRIO — MVP `nexclin-lovable`

> **Fonte:** `../nexclin-lovable` (exportado do Lovable) — tratado como **referência somente leitura**.
> **Objetivo:** documentar o produto real (banco, edge functions, frontend, contratos) para orientar a reescrita em Next.js + TypeScript + Supabase sob Spec-Driven Development.
> **Stack de origem:** React 18 + TypeScript + Vite + Supabase (`@supabase/supabase-js`), TanStack Query, React Router v6, `@hello-pangea/dnd`, shadcn/ui, sonner.
> **Escala:** 55 migrações SQL (`20260322075121` … `20260727010232`), 4 edge functions, ~175 arquivos em `src/`, ~42 tabelas.

---

## 1. BANCO

Estado **consolidado final** após todas as 55 migrações. Multi-tenant onde a fronteira do inquilino é `clinic_id`, ancorada em `profiles.clinic_id`, com uma camada de superadmin/operações de SaaS por cima.

### 1.1 Mecanismo multi-tenant (a âncora `clinic_id`)

- **`profiles`** é a âncora: uma linha por `auth.users`, carregando o `clinic_id` **ativo** daquele usuário.
  - `user_id uuid NOT NULL UNIQUE → auth.users(id) ON DELETE CASCADE`
  - `clinic_id uuid → clinics(id) ON DELETE SET NULL` (nullable — um superadmin pode ter `clinic_id` NULL)
- **`get_my_clinic_id()`** (SECURITY DEFINER) lê `profiles.clinic_id` do chamador sem disparar RLS recursivo. É a espinha dorsal das políticas.
- **Duas idiomáticas de isolamento coexistem** (funcionalmente equivalentes — "linha.clinic_id == clínica ativa do chamador"):
  1. Tabelas antigas: `clinic_id IN (SELECT clinic_id FROM profiles WHERE user_id = auth.uid())`
  2. Tabelas a partir de `20260322185846`: `clinic_id = public.get_my_clinic_id()`
- Como a impersonação **troca o próprio `profiles.clinic_id` do superadmin**, ele passa transparentemente pelos mesmos filtros de tenant "dentro" da clínica.

### 1.2 ENUMS

| Enum | Valores (final) | Definido em |
|---|---|---|
| `app_role` | `admin`, `medico`, `secretaria`, `user` | criado em `20260322075121` (3 valores); `user` adicionado em `20260725001410` |
| `superadmin_role` | `super_owner`, `admin`, `suporte`, `financeiro` | `20260408034446` |
| `subscription_status` | `trial`, `active`, `overdue`, `suspended`, `cancelled` | `20260408034446` |

### 1.3 Tabelas

Convenções: todo `id` é `uuid PK DEFAULT gen_random_uuid()`; `u@t` = trigger de `updated_at`.

**Núcleo de tenancy / identidade**
- **`clinics`** — raiz do inquilino. `name`, `cnpj`, `specialty`, `owner_crm`, timestamps.
- **`profiles`** — âncora multi-tenant (ver 1.1).
- **`user_roles`** — RBAC global. `user_id → auth.users`, `role app_role DEFAULT 'admin'`, `UNIQUE(user_id, role)`.

**Configuração / catálogo (clinic-scoped)**
- **`channels`**, **`origins`**, **`objections`** — listas simples `{name, active}` por clínica.
- **`services`** — `name`, `category`, `macro_category`, `price`, `direct_cost` (renomeado de `cost`), `room_cost`, `duration_minutes`.
- **`payment_methods`** — `default_fee_percent`, `anticipation_fee_percent`, `payment_term_days`, `type`, taxas/prazos débito/crédito, `credit_2x_fee…credit_12x_fee`, `credit_Nx_fee_anticip`, `anticipation_default`.
- **`expense_categories`** — `name`, `subcategory`, `cost_center`.
- **`business_rules`** — **uma linha por clínica** (`UNIQUE(clinic_id)`). `followup_days`, `confirmation_hours` (24), `recapture_days`, `recall_days`, `patient_required_fields jsonb`, `appointment_required_fields jsonb`, `satisfaction_survey_days`, `anamnesis_send_days`, `reschedule_days`, `work_saturday`.
- **`chart_of_accounts`** — árvore DRE hierárquica. `code`, `parent_id → self`, `level`, `is_system`, `UNIQUE(clinic_id, code)`. Semeada por `seed_chart_of_accounts`.
- **`closing_types`** — tipos de fechamento (`is_system`).
- **`team_members`** — equipe da clínica + vínculo com usuário. `name`, `role`, `permission_level` (default `basic`), `permissions jsonb` (mapa por módulo), `user_id`, `invited_email`, `invite_status`, campos de repasse (`modelo_repasse`, `repasse_percent`, `calcula_sobre`, `valor_fixo_sublocacao`). Índice único parcial em `user_id WHERE user_id IS NOT NULL`.
- **`bank_accounts`** — `bank_name`, `opening_balance`, `opening_date`, `is_system` (conta "Caixa (dinheiro)").
- **`goals`** — metas por mês/ano. `UNIQUE(clinic_id, month, year)`.
- **`acquirers`** — adquirentes/maquininhas com tabela de taxas por bandeira e parcelamento.
- **`consultation_types`** — tipos de consulta.

**CRM / clínico**
- **`patients`** — cadastro; `is_first_visit`, `origin_id`/`channel_id` (uuid **sem FK**).
- **`leads`** — funil 1. `status` (default `novo`), `funnel_stage` (default `novo_contato`), `objection_id`, `appointment_date`.
- **`lead_history`** — trilha de ações do lead.
- **`appointments`** — `patient_id` (obrigatório), `date`, `status` (default `agendada`), `closing_type_id`, `has_prescription`, `prescribed_value`, `sold_value`, `approval_status`, `deposit_value`, `consultation_type_id` (uuid **sem FK** — FK foi dropada), `cancellation_reason`, `no_show_reason`.
- **`tasks`** — `type` (default `follow_up`), `due_date`, `status`, `completed_at` (mantido por trigger).
- **`funnel_2_entries`** — conversão pós-consulta. `stage`, `attendance_status`, `has_prescription`, `prescribed_value`, `sold_value`.
- **`prescriptions`**, **`closings`** — prescrição e fechamento (valores, parcelas, `payment_method_id` sem FK).
- **`anamnesis_config`** — templates (`fields jsonb`), **`anamnesis_responses`** — respostas (`responses jsonb`, `status`).
- **`ai_insights`** — insights gerados por IA.

**Financeiro**
- **`revenues`** — **efetivamente morta**: campos absorvidos por `receivables`, dados apagados em `20260408031859`, nada escreve nela depois (tabela + RLS + trigger permanecem).
- **`receivables`** — contas a receber (a tabela financeira canônica). `value`, `due_date`, `payment_type`, parcelamento, `status`, `paid_at`, `conciliated`, `payment_method_id`, `fee_percent`, `net_value`, `gross_value`, `is_anticipated`, `appointment_id`, `acquirer_id`, `bank_account_id`, `item`, `category`, `macro_category`.
- **`expenses`** — contas a pagar. `category_id`, `chart_account_id`, `value`, `due_date`, `paid_at`, `status`, `person_type`, `is_recurring`, `fixed_expense_id`, `bank_account_id`, `conciliated`.
- **`fixed_expenses`** — despesas fixas recorrentes.
- **`appointment_items`** — itens/orçamento da consulta. `prescribed_value`, `sold_value`, `approval_status`, `quantity`. (`clinic_id → clinics` sem `ON DELETE`.)
- **`budgets`** / **`budget_items`** — orçamentos (`clinic_id`, `service_id`, etc. **sem FK**).

**Camada SaaS / superadmin**
- **`superadmin_operators`** — `user_id UNIQUE`, `role superadmin_role`, `active`, `last_login_*`.
- **`plans`** — `monthly_price`, `annual_price`, `trial_days`, `max_users`/`max_patients`/`max_leads_month` (tornaram-se nullable = ilimitado), **`enabled_modules jsonb`**, `support_level`, `status`, `visibility`, `is_default_trial`. Validada por `validate_enabled_modules`.
- **`account_subscriptions`** — `clinic_id UNIQUE`, `plan_id`, `status subscription_status`, janelas de trial/período, `cancelled_at`, `cancel_reason`, `coupon_id` (sem FK).
- **`account_timeline`** — linha do tempo de eventos por conta.
- **`superadmin_audit_log`** — **trilha de auditoria** (`operator_id`, `action`, `clinic_id`, `previous_state jsonb`, `new_state jsonb`, `reason`, `ip_address`).
- **`billings`** — cobranças (`amount`, `status`, `attempts`, período).
- **`coupons`** — cupons (`code UNIQUE`, `discount_type`, `applies_to`, `duration`, `max_uses`, `used_count`, `expires_at`).
- **`saas_settings`** — config global de linha única (régua de trial/inadimplência).
- **`superadmin_impersonation_sessions`** — sessões de impersonação (`superadmin_user_id`, `target_clinic_id`, `original_clinic_id`, `started_at`, `ended_at`). Índice parcial de sessão aberta.

### 1.4 RLS

**RLS habilitado em TODAS as tabelas.** Padrão de isolamento por inquilino: cada tabela de negócio tem uma única política `FOR ALL TO authenticated` com `USING` = `WITH CHECK` = igualdade de `clinic_id` (via subquery ou `get_my_clinic_id()`). Leitura/escrita cross-tenant é impossível para um `authenticated` normal.

- **`clinics`**: usuário vê/atualiza a própria; superadmin faz `SELECT/INSERT/UPDATE/DELETE` (`is_superadmin(auth.uid())`, migração `20260724233525`).
- **`profiles`**: `SELECT`/`UPDATE` **somente do próprio** (`user_id = auth.uid()` — substituiu a política clinic-wide recursiva em `20260322170954`); superadmin vê/atualiza todos.
- **`user_roles`**: apenas `SELECT` do próprio; escrita só via funções SECURITY DEFINER.
- **Tabelas superadmin-only** (`plans`, `account_subscriptions`, `billings`, `coupons`, `saas_settings`, `superadmin_operators`, `account_timeline`, `superadmin_impersonation_sessions`): tudo gated em `is_superadmin(auth.uid())`. `superadmin_audit_log`: `SELECT` + `INSERT` separados para superadmin.
- **Políticas `anon` removidas**: `anamnesis_config`/`anamnesis_responses` tiveram políticas `anon` para formulário público (`20260324032228`), **todas dropadas** em `20260723211722` (migrado para edge function com service role).

### 1.5 Funções (Postgres)

Todas em `public`. SD = SECURITY DEFINER.

| Função | → Retorno | Sec | Papel |
|---|---|---|---|
| `update_updated_at_column()` | trigger | INV | mantém `updated_at` |
| `has_role(uuid, app_role)` | bool | SD | EXISTS em `user_roles` |
| `handle_new_user()` | trigger | SD | provisiona clínica+perfil+role+regras+equipe e semeia catálogo; ramo separado de "usuário convidado" |
| `get_my_clinic_id()` | uuid | SD | `profiles.clinic_id` do chamador — base da RLS |
| `seed_chart_of_accounts` / `seed_closing_types` / `seed_native_services` | void | SD | seeds de catálogo |
| `auto_complete_anamnese_task()` / `auto_complete_appointment_task()` | trigger | SD | fecham tarefas automáticas |
| `is_superadmin(uuid)` | bool | SD | EXISTS ativo em `superadmin_operators` |
| `seed_superadmin_operator()` | trigger | SD | cria super_owner para o e-mail semente |
| `get_my_team_member()` / `my_team_member_name()` | TABLE/text | SD | dados do team_member do chamador |
| **`my_permission(text)`** | text | SD | **resolutor de permissão por módulo** (ver 1.7) |
| `set_task_completed_at()` | trigger | INV | mantém `tasks.completed_at` |
| **`prevent_clinic_id_change()`** | trigger | SD | **bloqueia reatribuição de tenant** (ver 1.6) |
| **`superadmin_enter_clinic(uuid)` / `superadmin_exit_clinic()`** | sessão | SD | **impersonação** (ver 1.6) |
| `get_my_active_impersonation()` | TABLE | SD | sessão de impersonação ativa |
| `validate_enabled_modules()` | trigger | INV | valida `plans.enabled_modules` |
| `get_my_subscription_state()` | TABLE | SD | plano/status/módulos da clínica |
| `clinic_within_user_limit(uuid)` | bool | SD | clínica sob `max_users` do plano |
| `enforce_team_user_limit()` | trigger | SD | barra ultrapassar limite de usuários |
| `audit_superadmin_profile_edit()` | trigger | SD | **audita** edições de perfil por superadmin |

**Endurecimento de acesso (`20260723211722`):** um bloco `DO` faz `REVOKE ALL` em toda função SECURITY DEFINER de `public` de `PUBLIC, anon, authenticated`, e re-concede `EXECUTE` a `authenticated` só para: `has_role`, `get_my_clinic_id`, `get_my_team_member`, `my_permission`, `my_team_member_name`, `is_superadmin`. Funções de impersonação/assinatura adicionam grants próprios.

### 1.6 Mecanismos destacados (corpo verificado)

**Trigger `prevent_clinic_id_change` (`20260724233525`)** — trava o `clinic_id` em `UPDATE` de `profiles`, mas **permite** quando o chamador é superadmin ou `auth.uid()` é NULL (contexto servidor confiável) — o que viabiliza a impersonação:

```sql
CREATE OR REPLACE FUNCTION public.prevent_clinic_id_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.clinic_id IS DISTINCT FROM OLD.clinic_id THEN
    IF auth.uid() IS NULL OR public.is_superadmin(auth.uid()) THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Alteração de clínica não permitida';
  END IF;
  RETURN NEW;
END; $$;
```

**Impersonação do superadmin (`20260725002557`)** — `superadmin_enter_clinic(_target_clinic_id)`:
1. exige `is_superadmin`; valida a clínica alvo;
2. fecha qualquer sessão aberta anterior, **restaurando** o `original_clinic_id` no perfil;
3. captura o `clinic_id` original (cria perfil com `clinic_id = NULL` se não existir);
4. abre uma nova `superadmin_impersonation_sessions`;
5. **sobrescreve `profiles.clinic_id` do superadmin** para a clínica alvo;
6. registra `impersonation_start` em `superadmin_audit_log`.

`superadmin_exit_clinic()` faz o inverso: restaura `original_clinic_id`, marca `ended_at`, registra `impersonation_end`. `get_my_active_impersonation()` retorna a sessão aberta. Todas com `REVOKE ... FROM PUBLIC, anon` e `GRANT EXECUTE TO authenticated`.

**Auditoria de edição de perfil (`20260727010232`)** — trigger `AFTER UPDATE` em `profiles` que, se o autor é superadmin editando **outro** usuário, faz diff de `full_name`/`phone`/`clinic_id` e insere `profile_edit` em `superadmin_audit_log`.

### 1.7 Enforcement de planos em `my_permission` (ordem confirmada)

Versão **FINAL** (`20260725034148`), verificada verbatim:

```sql
CREATE OR REPLACE FUNCTION public.my_permission(_module text)
 RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE v_uid uuid := auth.uid(); v_clinic uuid; v_status subscription_status;
        v_modules jsonb; v_individual text;
BEGIN
  IF public.is_superadmin(v_uid) THEN RETURN 'full'; END IF;          -- (1) superadmin
  v_clinic := public.get_my_clinic_id();
  SELECT s.status, p.enabled_modules INTO v_status, v_modules
  FROM public.account_subscriptions s JOIN public.plans p ON p.id = s.plan_id
  WHERE s.clinic_id = v_clinic ORDER BY s.created_at DESC LIMIT 1;
  IF v_status IN ('suspended','cancelled') THEN RETURN 'none'; END IF; -- (2) status da assinatura
  IF v_modules IS NULL OR NOT COALESCE((v_modules->>_module)::boolean, false)
     THEN RETURN 'none'; END IF;                                      -- (3) enabled_modules do plano
  IF public.has_role(v_uid, 'admin') THEN RETURN 'full'; END IF;      -- (3.5) admin global
  SELECT permissions->>_module INTO v_individual
  FROM public.team_members WHERE user_id = v_uid AND active = true LIMIT 1;
  RETURN COALESCE(v_individual, 'none');                              -- (4) individual + default deny
END; $$;
```

**Ordem confirmada:** `superadmin → status da assinatura → enabled_modules do plano → (admin global) → permissão individual → default deny`.
Nuance: o atalho `admin → full` vem **depois** dos portões de assinatura e módulo, então até um admin recebe `none` para conta suspensa ou módulo desabilitado (intencional).

### 1.8 Triggers destacados

| Trigger | Tabela | Timing | Função | Papel |
|---|---|---|---|---|
| `on_auth_user_created` | `auth.users` | AFTER INSERT | `handle_new_user` | provisiona/vincula conta |
| `on_auth_user_created_superadmin` | `auth.users` | AFTER INSERT | `seed_superadmin_operator` | cria super_owner do e-mail semente |
| `update_*_updated_at` (muitas) | ~22 tabelas | BEFORE UPDATE | `update_updated_at_column` | mantém `updated_at` |
| `trg_auto_complete_anamnese_task(_ins)` | anamnesis_responses | AFTER INS/UPD | `auto_complete_anamnese_task` | fecha tarefa de anamnese |
| `trg_auto_complete_appointment_task` | appointments | AFTER UPDATE | `auto_complete_appointment_task` | fecha tarefa de confirmação |
| `trg_set_task_completed_at` | tasks | BEFORE UPDATE | `set_task_completed_at` | mantém `completed_at` |
| **`profiles_prevent_clinic_id_change`** | **profiles** | **BEFORE UPDATE** | `prevent_clinic_id_change` | trava tenant |
| `plans_validate_enabled_modules` | plans | BEFORE INS/UPD | `validate_enabled_modules` | valida mapa de módulos |
| `team_members_enforce_user_limit` | team_members | BEFORE INS/UPD | `enforce_team_user_limit` | limite de usuários do plano |
| **`trg_audit_superadmin_profile_edit`** | **profiles** | **AFTER UPDATE** | `audit_superadmin_profile_edit` | auditoria |

`profiles` carrega **os dois** gatilhos: `prevent_clinic_id_change` (BEFORE) e `audit_superadmin_profile_edit` (AFTER).

---

## 2. EDGE FUNCTIONS

Quatro funções Deno. Todas com CORS aberto (`Access-Control-Allow-Origin: *`).

### 2.1 `anamnesis-public` (76 linhas) — formulário público de anamnese
- **Cliente:** service role (bypass de RLS). **Não exige autenticação** (paciente anônimo via link).
- **Entrada:** `{ action: "get" | "submit", responseId (uuid), responses? }`.
  - `get` → retorna `{ id, status, config: { title, fields } }` da `anamnesis_responses` + `anamnesis_config`.
  - `submit` → grava `responses`, muda `status` para `preenchido`; **idempotente** (rejeita 409 se já `preenchido`, usa `.neq("status","preenchido")`).
- **Saída:** JSON. Erros: `invalid_id` 400, `not_found` 404, `already_submitted` 409.
- **Depende de:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`; tabelas `anamnesis_responses`, `anamnesis_config`.

### 2.2 `generate-insights` (120 linhas) — insights de gestão por IA
- **Entrada:** `{ clinicData, type: "weekly" | "monthly" }`.
- **Processo:** monta prompt PT-BR e chama o **AI Gateway do Lovable** (`https://ai.gateway.lovable.dev/v1/chat/completions`, modelo `google/gemini-3-flash-preview`) com tool-calling forçado (`generate_insights`). Retorna 3–5 insights `{ title, content, category ∈ {marketing, comercial, operação, financeiro, geral}, priority ∈ {high, medium, low} }`.
- **Saída:** `{ insights: [...] }`. Trata 429 (rate limit) e 402 (créditos).
- **Depende de:** `LOVABLE_API_KEY`. ⚠️ **Dependência de fornecedor (Lovable AI Gateway)** — precisa ser substituída no port (ver Veredito).

### 2.3 `invite-team-user` (100 linhas) — convite de membro de equipe
- **Autentica o chamador** (Bearer token via cliente anon → `auth.getUser()`).
- **Entrada:** `{ email, password, full_name, team_member_id? }`.
- **Processo:** lê `clinic_id` do chamador; cria usuário via `admin.createUser` com `email_confirm: true` e `user_metadata { full_name, invite_clinic_id, invite_team_member_id }` (sinaliza ao trigger `handle_new_user` que é convidado); reforça o vínculo em `team_members` (`user_id`, `invite_status='active'`).
- **Saída:** `{ ok: true, user_id }`.
- **Depende de:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`; trigger `handle_new_user`, tabelas `profiles`, `team_members`.
- ⚠️ **A senha do convidado é passada em texto claro pelo admin da clínica** (ver Veredito / regra e).

### 2.4 `superadmin-manage-user` (147 linhas) — gestão de usuários pelo superadmin
- **Autentica** o chamador e **verifica `is_superadmin` via RPC** (403 se não); resolve `operator_id`.
- **Ações:**
  - `update_email` → valida e-mail, `admin.updateUserById(email, email_confirm)`, audita `email_change`.
  - `send_password_reset` → `resetPasswordForEmail(email)` (reset **por e-mail**), audita `password_reset_sent`.
  - `set_password` → `admin.updateUserById(password)` (mín. 12 chars), audita `password_set`. Comentado como "cleanup de testes / emergência".
- **Saída:** `{ ok: true }`. Toda ação grava em `superadmin_audit_log`.
- **Depende de:** `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`; RPC `is_superadmin`, tabelas `profiles`, `superadmin_operators`, `superadmin_audit_log`.
- ⚠️ **`set_password` contraria a regra (e)** ("senha jamais definida por admin") — só deve sobreviver como break-glass auditado, se sobreviver (ver Veredito).

---

## 3. FRONTEND

### 3.1 Rotas e telas

Router único em **`src/App.tsx`** (`<BrowserRouter>` + `<Routes>`). Wrappers `ProtectedRoute` e `PublicRoute` são declarados no próprio `App.tsx`.

**Auth / públicas:** `/login`, `/signup` (`PublicRoute`); `/forgot-password`, `/reset-password`, `/request-access`; `/anamnese-publica/:responseId` (formulário público do paciente).

**App protegido** (todas em `ProtectedRoute → AppLayout → OnboardingGuard`, com `RequirePermission` no módulo indicado):

| Rota | Tela | Módulo |
|---|---|---|
| `/` | Dashboard | — (interno) |
| `/configuracoes` | Configuracoes | `configuracoes` |
| `/pacientes` | Pacientes | `pacientes` |
| `/atendimentos` | Atendimentos (kanban de leads) | `leads` |
| `/acompanhamento` | Acompanhamento (**tela "Consultas" ativa**) | `acompanhamento` |
| `/tarefas` | Tarefas | `tarefas` |
| `/contas-receber` | ContasReceber | `contas_receber` |
| `/contas-pagar` | ContasPagar | `contas_pagar` |
| `/fluxo-caixa` | FluxoCaixa | `fluxo_caixa` |
| `/anamnese` | Anamnese | `anamnese` |
| `/insights` | Insights | `insights` |
| `/relatorios` + `/relatorios/{leads,vendas,contas-pagar,contas-receber,dfc-dre,produtividade,repasse}` | Relatórios | `relatorios_vendas` (vendas) / `relatorios_demais` (demais) |

**SuperAdmin** (todas em `SuperAdminGuard`, exceto login): `/superadmin/login`, `/superadmin` (Dashboard MRR/churn), `/superadmin/contas`, `/superadmin/contas/:id`, `/superadmin/planos`, `/superadmin/cupons`, `/superadmin/faturamento`, `/superadmin/metricas`, `/superadmin/comunicacao`, `/superadmin/logs`, `/superadmin/operadores`, `/superadmin/configuracoes`.

**⚠️ Páginas órfãs (têm lógica real, mas NÃO estão roteadas nem no menu):** `Consultas.tsx`, `Funil.tsx`, `Funil2.tsx`, `Leads.tsx`, `Despesas.tsx`, `ContasFixas.tsx`. Duas não-roteadas SÃO usadas internamente: `DashboardOperational.tsx` (Dashboard em escopo `simplified`) e `AccountBlocked.tsx` (parede de conta bloqueada). O item de menu rotulado "Consultas" leva a `/acompanhamento`.

### 3.2 Guards de acesso

- **`ProtectedRoute`** (App.tsx) — `useAuth()`; sem sessão → `Navigate /login`; com sessão → envolve em `AppLayout` + `OnboardingGuard`.
- **`PublicRoute`** (App.tsx) — inverso; com sessão → `Navigate /`.
- **`RequirePermission`** (`components/RequirePermission.tsx`) — props `{ module: ModuleKey }`; `usePermissions().can(module)`; loading → `null`; falha → `Navigate /` (bounce ao dashboard); ok → children.
- **`SuperAdminGuard`** (`components/superadmin/SuperAdminGuard.tsx`) — `useAuth()` + `useSuperAdmin()`; sem sessão ou não superadmin → `Navigate /superadmin/login`.
- **`OnboardingGuard`** (`components/OnboardingGuard.tsx`) — `useOnboardingStatus()` + `useImpersonation()`; **bypass** se `skip || isComplete || activeSession` (superadmin impersonando pula onboarding); senão renderiza children + overlay `<OnboardingTour>`. Onboarding é um **checklist de 12 passos** (`team ≥2`, `patient_fields`, `appointment_fields`, `business_rules`, `channels_origins`, `services`, `objections`, `payment_methods`, `chart_of_accounts`, `bank_accounts`, `goals`, `anamnese`).
- **Bloqueio de assinatura** (`NxAppShell.tsx`, guard-like) — se `subscriptionBlocked && !isImpersonating`, o shell inteiro vira `<AccountBlocked />`.

### 3.3 Plumbing de autenticação/permissão

- **`AuthContext`** (`contexts/AuthContext.tsx`) — wrapper fino do Supabase auth: `{ session, user, loading, signOut }`. **Não** carrega perfil/clínica (resolvidos por hooks).
- **`useClinicId`** — `profiles.clinic_id` do usuário; quase toda query de feature filtra por ele.
- **`usePermissions`** (o núcleo, `hooks/usePermissions.ts`) — 3 queries paralelas: `get_my_team_member` (+ `user_roles` p/ `isAdmin`), `get_my_subscription_state` (plano/status/`enabled_modules`), `get_my_active_impersonation`. Deriva:
  - `subscriptionBlocked = !isImpersonating && status ∈ {suspended, cancelled}`;
  - `isModuleEnabledInPlan(mod)` (impersonando → sempre true; sem estado → fail-open até resolver);
  - `scope(mod)` → `PermissionLevel` do módulo;
  - **`can(mod)`** — o portão mestre, **espelha a ordem do `my_permission` do banco**: (a) impersonando → true; (b) `subscriptionBlocked` → false; (c) módulo desabilitado no plano → false; (d) `scope(mod) !== 'none'`.
  - Admins sempre recebem o mapa `master` completo.
- **`useSuperAdmin`** — `superadmin_operators` ativo → `isSuperAdmin`.
- **`useImpersonation`** — RPCs `superadmin_enter_clinic`/`superadmin_exit_clinic`, depois `queryClient.clear()` + navegação.
- **`useCanViewAnamnesis`** — **privacidade médica row-level**: permite se admin, ou se o `full_name` do usuário casa com um `team_members` de papel de saúde que é `doctor`/`responsible` em ≥1 appointment do paciente.

> **Nota crítica:** a authz do frontend é **advisory/UX**. O `can()` explicitamente espelha o `my_permission` do servidor; a fronteira real é RLS + as RPCs `superadmin_*`/impersonação.

### 3.4 Regras de negócio embutidas (lógica, não estilo)

- **Dias úteis** (`lib/businessDays.ts`): domingo **nunca** conta; sábado só se `business_rules.work_saturday`.
- **Automação de tarefas** (`lib/tasksAutomation.ts`): `createAppointmentTasks` gera `confirmar_agendamento` (due = consulta − `confirmation_hours`, snap p/ dia útil) e `envio_anamnese` (due = `anamnesis_send_days` úteis antes; pulada se já há anamnese preenchida); `createSatisfactionTask` gera `pesquisa_satisfacao` (due = `satisfaction_survey_days` úteis após `compareceu`). Todas idempotentes/dedup.
- **Consultas/Acompanhamento** (`Acompanhamento.tsx`): máquina de estados `agendada → confirmada → compareceu | nao_compareceu | cancelada`. Salva itens de orçamento (`appointment_items` c/ `approval_status`); calcula `prescribed_value`/`sold_value`/desconto% embutido na descrição; depósito → `receivables` `pago`; aprovado & vendido → `receivables` `pendente` origem `consulta`; `compareceu` c/ saldo → tarefa `follow_up` "Contato de venda" +3 dias; dispara satisfação.
- **Diálogos de status** (`components/appointment/AppointmentStatusDialogs.tsx`): no-show e cancelamento exigem motivo ≥3 chars; cancelamento oferece adicionar à recaptação.
- **Wizard Lead→Consulta** (`components/lead/LeadToAppointmentWizard.tsx`): valida `patient_required_fields`/`appointment_required_fields` dinâmicos + `consultation_type_id`; upsert de paciente (herda origem/canal do lead); insere appointment `agendada`, opcional `anamnesis_responses` `pendente`, move lead p/ `agendou`, grava `lead_history`, dispara `createAppointmentTasks`. CEP via ViaCEP.
- **Funil 1 (leads)**: estágios `novo_contato, em_atendimento, nao_agendou, recaptacao, agendou`; arrastar p/ `agendou` **abre o wizard** (não escreve direto).
- **Funil 2 (consultas/fechamentos, `Funil2.tsx`)**: estágios fixos + **dinâmicos a partir de `closing_types` ativos** (nome slugificado).
- **Fechamento** (`components/funil2/ClosingDetailDialog.tsx`): `canClose = compareceu && hasPrescription`; recomputa `stage`; método `dinheiro` liga à conta `is_system`; **geração idempotente de `receivables`** (apaga `origin='fechamento'` antes) com taxa/prazo por tipo de método (crédito/débito/antecipação); cortesia não gera nada.
- **Taxas** (`lib/paymentFees.ts`): `computeFeeForMethod` lê `credit_${N}x_fee`/`_anticip` com fallbacks.
- **Breakdown financeiro** (`hooks/useFinancialBreakdown.ts`): base = fechamentos no período; separa consultas × vendas; `ticketMedioConsolidado`, conversão, ranking macro.
- **Config** (`pages/Configuracoes.tsx` + `components/config/*`): destaque para `ConfigBusinessRulesDialog` — **confirmação mostrada em dias mas armazenada em horas** (`confirmation_hours`: carrega `max(1, round(h/24))`, salva `days×24`); a mesma linha guarda `patient_required_fields`/`appointment_required_fields` (diálogos irmãos não podem sobrescrever um ao outro). `ConfigTeamDialog` liga papel → `permission_level` → matriz por módulo (`LEVEL_OPTIONS`), fluxo de convite via edge function com contador de assentos. `ConfigBankAccountsDialog`: conta `is_system` não pode ser excluída/desativada; saldo = abertura + recebidos − pagos.
- **SuperAdmin (contas/métricas/faturamento):** máquina de estados de assinatura (`active/suspended/cancelled` + trial/reactivate, gated por status); **toda ação de operador grava DUAS linhas** (`superadmin_audit_log` + `account_timeline`) e algumas exigem `reason`; health score, MRR, churn, régua de cobrança (D+1,3,7,15,30→Suspensão). Detalhe completo dos relatórios/superadmin no Anexo abaixo.

### 3.5 Integrações

- **Cliente Supabase** (`integrations/supabase/client.ts`): `createClient(VITE_SUPABASE_URL, VITE_SUPABASE_PUBLISHABLE_KEY)` — lança se faltar env.
- **Tipos gerados** (`integrations/supabase/types.ts`, ~2.986 linhas): ~42 tabelas + assinaturas de RPC.
- **Chamadas de edge function** (`supabase.functions.invoke`): `anamnesis-public` (AnamnesePublica), `generate-insights` (Insights), `invite-team-user` (ConfigTeamDialog, com Bearer).
- **HTTP externo:** ViaCEP (endereço), links `wa.me` (envio de anamnese via WhatsApp).

---

## 4. CONTRATOS

### 4.1 As 15 ModuleKeys oficiais

Fonte única: **`src/hooks/usePermissions.ts`** (`MODULE_KEYS`).

```
dashboard, leads, pacientes, anamnese, consultas, acompanhamento, tarefas,
contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas, relatorios_demais,
configuracoes, equipe, insights
```

> ⚠️ **Inconsistência a resolver:** existem 15 keys, mas o roteamento usa `acompanhamento` para a tela ativa e **`consultas` não tem rota própria**; `equipe` é módulo mas configurado dentro de `configuracoes`. `SuperAdminPlanos` monta `enabled_modules` sobre essas 15 keys.

### 4.2 Níveis de permissão

Há **dois vocabulários distintos**:

**(a) Escopos por módulo (`PermissionLevel`):**
```
full, all, own, read, simplified, status_only, responsible_only, none
```

**(b) Tiers de papel (`DEFAULT_PERMISSIONS_BY_LEVEL` / `PERMISSION_LEVELS`):**
```
master, gerencial, operacional, configuravel
```
Cada tier traz um mapa completo das 15 keys. Só `master` dá `configuracoes: full` e `equipe: full`. Escopos selecionáveis variam por módulo (`LEVEL_OPTIONS`): anamnese aceita `full|responsible_only|status_only|none`; financeiro `full|read|none`; leads/relatorios_vendas `all|own|none`.

> No **banco**, `my_permission` retorna string (`'full'`/`'none'`/escopo individual) — o vocabulário (a) é o contrato de escopo entre banco e frontend.

### 4.3 Status de assinatura

Enum `subscription_status`:
```
trial, active, overdue, suspended, cancelled
```
Rótulos no frontend: Trial / Ativa / Inadimplente / Suspensa / Cancelada. **Só `suspended` e `cancelled`** disparam `subscriptionBlocked`/`AccountBlocked`. Estado implícito `sem_plano` quando não há `account_subscriptions`.
Status auxiliares (não confundir): `plans.status` e `coupons.status` usam `active`/`inactive`/`paused`/`expired`.

---

## 5. VEREDITO DE PORTE

### 5.1 Migra como está (SQL / migrações) — **o coração do sistema**

O modelo de dados e a segurança-no-banco são o ativo mais valioso e portam quase diretamente para o Supabase próprio:

- **Todo o schema** (tabelas, colunas, tipos, enums) — porta como definição consolidada (não replicar as 55 migrações incrementais; escrever migrações limpas a partir do estado final).
- **RLS por `clinic_id`** em toda tabela de negócio — padrão comprovado, manter.
- **Funções de segurança** `get_my_clinic_id`, `has_role`, `is_superadmin`, **`my_permission` (versão final, default-deny)**, `prevent_clinic_id_change`, impersonação (`superadmin_enter/exit_clinic`), auditoria (`audit_superadmin_profile_edit`) — portam verbatim.
- **Triggers** de `updated_at`, auto-conclusão de tarefas, limite de usuários, validação de módulos, trava de tenant e auditoria — mantêm-se.
- **Corrigir na consolidação** (ver 5.4): FKs faltantes, tabela `revenues` morta, unicidade em catálogos, coluna `consultation_type_id` sem FK, migrações destrutivas/QA fora do schema limpo.

### 5.2 Se adapta (edge functions → Route Handlers / Server Actions do Next)

As 4 funções viram endpoints server-side do Next (ou Edge Functions do Supabase próprio), preservando a lógica mas trocando dependências:

- **`anamnesis-public`** — porta direto (service role no server; endpoint público idempotente).
- **`invite-team-user`** — porta; **rever regra de senha** (ver 5.3).
- **`superadmin-manage-user`** — porta; **remover/segregar `set_password`** (break-glass auditado apenas, ou eliminar).
- **`generate-insights`** — **precisa de reescrita da dependência de IA**: trocar o Lovable AI Gateway (`LOVABLE_API_KEY`, `google/gemini-3-flash-preview`) por um provedor próprio (recomendado: **Claude** via API Anthropic) mantendo o contrato de saída (`insights[] {title, content, category, priority}`).

### 5.3 Se reescreve (frontend)

Todo o `src/` React+Vite será **reescrito em Next.js + TypeScript**, preservando a **lógica de negócio** (não o estilo):

- Preservar: máquinas de estado (leads, consultas, fechamento), automação de tarefas por dias úteis, cálculos financeiros (taxas, net, ticket, repasse, DRE/DFC), regras de validação dinâmica de campos, onboarding de 12 passos, e o **espelhamento de `my_permission` em `can()`**.
- Consolidar as duplicações (health score, mapas de status, regra "Consulta vs Prescrição", `enabled_modules`) em fontes únicas.
- Descartar/decidir sobre as páginas órfãs antes de portar.
- **Guards**: reimplementar `ProtectedRoute`/`RequirePermission`/`SuperAdminGuard`/`OnboardingGuard` no modelo do Next (middleware + server components), lembrando que **a autorização real é do banco**.

### 5.4 Inconsistências e lacunas encontradas (para decidir na spec)

**Segurança / permissões**
1. **`my_permission` foi fail-open por um intervalo:** v3 (`20260725033102`) usava `COALESCE(..., 'full')`; a final v4 (`20260725034148`) corrigiu para `'none'`. O estado final é default-deny — **garantir default-deny desde a primeira migração** no repo novo.
2. **`enabled_modules`: default do plano é `'[]'` (array), mas `my_permission` lê como objeto** `{module: true}` (`v_modules->>_module`). Com o default `[]`, tudo resulta `none` (default-deny se sustenta), mas há **descasamento de forma** entre coluna e uso — padronizar como objeto `Record<ModuleKey, boolean>`.
3. **`set_password` (edge `superadmin-manage-user`) contraria a regra (e)** "senha jamais definida por admin". Decidir: eliminar ou manter só como break-glass auditado.
4. **`invite-team-user` passa senha em texto claro** definida pelo admin da clínica. Preferir fluxo de convite por e-mail (magic link / definição de senha pelo próprio convidado).
5. **Auditoria cobre só ações de superadmin** (`superadmin_audit_log` + `account_timeline` + trigger de perfil). A regra (d) pede auditoria de **toda ação administrativa sobre dado de cliente** — hoje ações de admin **dentro** da clínica não são auditadas. Lacuna a fechar na spec.
6. **`.env` versionado no MVP:** o `.env` da referência **está rastreado no git** e **não** está no `.gitignore` (contém `VITE_SUPABASE_URL` + publishable/anon key + project id — públicas por design, mas ainda assim arquivo de credencial versionado). No repo novo: `.env` sempre no `.gitignore` (regra g).
7. **`app_role 'user'` usado antes de existir no enum** (`handle_new_user` inseria `'user'` em `20260510225339`; enum só ganhou `'user'` em `20260725001410`) — bug latente já resolvido, mas evidencia falta de ordem nas migrações.

**Integridade de dados**
8. **Tabela `revenues` morta** (dados apagados, nada escreve) — não portar; `receivables` é a canônica.
9. **FKs faltantes:** `budgets.clinic_id`, `budget_items.clinic_id`, `budgets.appointment_id/patient_id`, `budget_items.service_id`, `patients.origin_id/channel_id`, `closings.payment_method_id`, `account_subscriptions.coupon_id`, `appointments.consultation_type_id` (FK dropada) — sem integridade referencial. Adicionar FKs no schema limpo.
10. **`appointment_items.clinic_id` sem `ON DELETE`** (NO ACTION, divergente do CASCADE usado no resto).
11. **Catálogos sem `UNIQUE(clinic_id, name)`** (`services`, `objections`, etc.) — `ON CONFLICT DO NOTHING` dos seeds é no-op sem índice; risco de duplicação ao re-semear.
12. **`profiles` SELECT é self-only** — normal não enxerga colegas da clínica via RLS (por causa da correção de recursão); listagem de equipe depende de `team_members`/funções SD. Decidir política de leitura de equipe.
13. **Enforcement parcial de limites do plano:** só `max_users` tem trigger; `max_patients` e `max_leads_month` são apenas advisory (sem enforcement). Decidir onde/como impor.
14. **Migrações destrutivas/QA na história:** `20260408031859` **apaga todos os dados incluindo `auth.users`**; várias migrações com UUIDs hardcoded e criação/remoção de plano de teste. Não carregar para o repo novo — começar de schema limpo.

**Frontend / lógica**
15. **Páginas órfãs** com lógica real (`Consultas`, `Funil`, `Funil2`, `Leads`, `Despesas`, `ContasFixas`) — não roteadas; confirmar intenção antes de portar.
16. **Duplicações load-bearing:** fórmula de health score (com divergência de chave `teamMembers` vs `team`), mapas de status, regra "Consulta vs Prescrição", labels de assinatura — repetidas em vários arquivos; centralizar.
17. **Aproximações no MVP:** histórico de MRR é **sintético** (projeção proporcional, não snapshots); imposto no repasse **hardcoded 0**; atribuição de profissional no repasse é heurística (último médico do appointment do paciente); Comunicação do superadmin é **stub simulado**; limites/expiração de cupom **não são enforçados**. Especificar as versões reais.
18. **Duas idiomáticas de RLS** (`IN (subquery)` vs `get_my_clinic_id()`) — consolidar numa só.

---

## ANEXO — Detalhe de SuperAdmin e Relatórios

**Conceitos transversais:** máquina de estados de assinatura `trial → active → overdue → suspended → cancelled` (+`sem_plano`); split de receita "Consulta" (quando `macro_category` == `"consulta"`) vs "Prescrição/Venda", load-bearing em Repasse/Vendas/ContasReceber/DfcDre/Produtividade.

**SuperAdmin:** login exige operador **ativo** (senão faz signOut); Dashboard calcula MRR (Σ `monthly_price` de ativos), ARR, ARPU, churn (`cancelledThisMonth / (active+cancelled no início)`), evolução de MRR **estimada**, distribuição por plano, alertas de vencimento/trial; Métricas calcula **health score** ponderado 0–100 e conversão trial→pago; ContaDetalhe executa transições (`change_plan/suspend/reactivate/cancel/extend_trial/apply_discount/refund/note`) com gating por status e auditoria dupla; Planos edita `enabled_modules` (`Record<ModuleKey, boolean>` normalizado defensivamente) + limites + `is_default_trial`; Cupons (code uppercase, `max_uses` 0=∞); Faturamento (detecção de overdue, régua de cobrança, `mark_paid`/`refund`); Configurações (`saas_settings`: régua de trial/inadimplência que dirige automações); Operadores (RBAC, só `super_owner` edita, não cria pela UI); Logs (auditoria paginada + export CSV).

**Relatórios (clinic-scoped, range = mês atual):** Leads (label = `funnel_stage` ou `status`); Vendas (`receivables`, `revenue_date = paid_at||due_date`, ticket = bruto/pacientes únicos); ContasPagar/Receber (status efetivo com "Vencido"/"Antecipado"); DFC/DRE (entradas Consultas×Vendas, saídas por nível-1 do plano de contas, resultado realizado × projetado); Produtividade (por profissional: atendimentos `compareceu`, itens `aprovado`, conversão, ticket); **Repasse** (net após taxas/custos por linha atribuída ao profissional; **imposto hardcoded 0**, atribuição heurística — precisa de tabela de comissão/repasse por profissional que ainda não existe).
