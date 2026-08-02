# Implementation Plan: SPEC 001 — Fundação (banco, auth, multi-tenant e Super Admin)

**Branch**: `001-fundacao-superadmin` | **Date**: 2026-08-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-fundacao-superadmin/spec.md`

> **Método SDD (constituição, Princípio IV):** este plano gera artefatos de
> design por fases. O executor **PARA para aprovação humana antes de implementar
> cada fase**. Nenhuma fase fecha sem os critérios de aceite executados por
> Arthur. Este documento **não implementa nada** — é design.

## Summary

Replicar no Supabase próprio o banco já validado do MVP (56 migrações,
multi-tenant com RLS, cascata de permissões, planos como teto, superadmin com
impersonação e auditoria) e reconstruir em **Next.js (App Router) + TypeScript**
apenas a camada de aplicação (auth + painel Super Admin + esqueleto do app da
clínica), consumindo a segurança que **já mora no banco**. Abordagem: banco
migra intacto; aplicação renasce limpa; entrega por 4 fases com gate humano.

## Technical Context

**Language/Version**: TypeScript (strict) · Node LTS · SQL (Postgres 15, Supabase)

**Primary Dependencies**: Next.js (App Router) · `@supabase/supabase-js` +
`@supabase/ssr` · Supabase CLI · Deno (runtime das Edge Functions) ·
Vitest + Playwright (testes) · Resend (e-mail transacional — integração
pós-fundação, desenhada para plugar sem retrabalho)

**Storage**: Supabase Postgres (próprio), com RLS multi-tenant. Fonte de
verdade do schema = `supabase/migrations` versionadas.

**Testing**: Vitest (unit — hook de permissões), Playwright (e2e — guards de
rota, fluxo superadmin/impersonação). Mínimo obrigatório: guards + hook de
permissão (constituição, Princípio V).

**Target Platform**: Web (Vercel) + Supabase (Postgres/Auth/Edge Functions)

**Project Type**: Web app (frontend Next.js + backend Supabase gerenciado)

**Performance Goals**: N/A crítico nesta fundação (painel administrativo).
Prioridade é correção de acesso e isolamento multi-tenant, não throughput.

**Constraints**: Custo previsível (~R$0 dev, ~R$250-270/mês com clientes);
LGPD por arquitetura; nenhuma credencial versionada; e-mail via Resend (SMTP
embutido não entrega — comprovado).

**Scale/Scope**: Fundação — ~1 painel superadmin (11 telas) + auth + esqueleto
do app da clínica. Módulos de negócio ficam para specs 002+.

### Fatos verificados e pendências (Phase 0)

**Resolvidos pelo inventário do schema (2026-08-02):**

1. **Localização da referência — RESOLVIDO.** O export do MVP foi movido para a
   pasta irmã `../nexclin-lovable` (read-only), alinhando com a decisão 6. As
   56 migrações vivem em `../nexclin-lovable/supabase/migrations`.
2. **Contagem de migrações:** são **56** arquivos `.sql` (a spec dizia 55 —
   valor nominal). Todos entram na Fase 1.
3. **Contagem de tabelas:** **44** tabelas no total (ver `data-model.md`). O
   subconjunto exato com `clinic_id` (spec esperava 43) será contado contra o
   banco no `RELATORIO-FASE1.md` — divergência residual é reconciliação, não erro.
4. **Pegadinha do seed (crítico p/ Fase 1):** a exceção "não portar o seed de
   e-mail fixo" não pode ser um simples *delete* da migração
   `20260408034946`, porque a migração de `20260802073330` faz
   `REVOKE EXECUTE ON FUNCTION ... seed_superadmin_operator()`. **Decisão:**
   manter a FUNÇÃO `seed_superadmin_operator` e dropar apenas o TRIGGER
   `on_auth_user_created_superadmin` (a função inofensiva sem trigger preserva
   a integridade do REVOKE posterior). Ver `research.md`.
5. **Risco `ALTER TYPE ADD VALUE`:** confirmado — isolado em
   `20260725001410` (`app_role ADD VALUE 'user'`). Já está sozinho no arquivo,
   então roda fora de transação sem quebrar uso imediato. Baixo risco.

**Pendências que bloqueiam a EXECUÇÃO da Fase 1 (não este plano):**

6. **Projeto Supabase novo + `.env.local`** com as 4 variáveis — ainda não
   existem. Ação de Arthur.
7. **Supabase CLI** — não instalada nesta máquina; instalar e linkar.
8. **Repositório git** — o diretório ainda não é repo git; inicializar para
   versionar migrações e habilitar o fluxo de branches do Spec Kit.

## Constitution Check

*GATE: precisa passar antes do Phase 0. Reavaliar após o design (Phase 1).*

| Princípio (constituição v1.0.0) | Como o plano adere | Status |
|---|---|---|
| I — Segurança mora no banco | RLS em toda tabela com clinic_id migra intacta; app só consome `my_permission`/estado de assinatura | ✅ |
| II — Privacidade e auditoria (LGPD) | `superadmin_audit_log` migra; edge functions mantêm auditoria old→new; nenhuma action define senha | ✅ |
| III — Contrato único de módulos | Editor de planos e guards usam as 15 ModuleKeys; seed marca as 15 = true | ✅ |
| IV — SDD com parada humana | 4 fases, cada uma com gate de aceite manual; nada implementado sem aprovação | ✅ |
| V — Segredos fora do código + qualidade | `.env.local` gitignored; service role só no script de seed; TS estrito; testes em guards + hook | ✅ |
| VI — Valor operacional | Fundação habilita operação/venda (superadmin gerencia contas/planos) | ✅ |

**Gate inicial: PASS** (sem violações). Complexity Tracking vazio.

## Project Structure

### Documentation (this feature)

```text
specs/001-fundacao-superadmin/
├── spec.md              # Especificação (fonte de verdade do "quê")
├── plan.md              # Este arquivo (design + fases)
├── research.md          # Phase 0 — decisões e riscos resolvidos
├── data-model.md        # Phase 1 — inventário do schema validado
├── quickstart.md        # Phase 1 — roteiro de validação (7 critérios de aceite)
├── contracts/           # Phase 1 — contratos de RPC / edge functions / guards
└── tasks.md             # Gerado por /speckit-tasks (NÃO por este comando)
```

### Source Code (repository root)

Layout físico já reestruturado (2026-08-02): o repo de trabalho é a **estrutura
nova limpa**; o MVP Lovable vive **ao lado**, como irmão read-only.

```text
Downloads/
├── nexclin-main/                    # ← REPO NOVO (estrutura nova, este repo)
│   ├── CLAUDE.md                    # contexto permanente
│   ├── .specify/  .claude/          # Spec Kit + skills
│   ├── specs/                       # specs SDD (001 aqui)
│   ├── .gitignore                   # blinda .env / .env.local
│   ├── .env.local                   # segredos (gitignored) — a criar
│   ├── supabase/                    # ← criado na Fase 1
│   │   ├── migrations/              #   56 migrações portadas do irmão
│   │   ├── functions/               #   superadmin-manage-user, invite-team-user (Fase 3)
│   │   └── config.toml
│   ├── scripts/
│   │   └── seed.ts                  # Fase 2 — seed idempotente (service role)
│   ├── app/                         # Next.js App Router (Fase 4)
│   │   ├── (public)/                #   login, reset de senha, request-access
│   │   ├── (protected)/             #   app da clínica: dashboard vazio + menu por my_permission
│   │   ├── superadmin/              #   painel: login próprio + 11 telas
│   │   │   ├── login/ contas/ planos/ cupons/ faturamento/
│   │   │   └── metricas/ logs/ operadores/ configuracoes/ comunicacao/
│   │   └── layout.tsx               #   banner âmbar de impersonação (todas as rotas)
│   ├── lib/
│   │   ├── supabase/                # clients server/browser (@supabase/ssr)
│   │   └── auth/                    # guards: ProtectedRoute, RequirePermission,
│   │                               #         SuperAdminGuard, OnboardingGuard (bypass impers.)
│   └── tests/
│       ├── unit/                    # hook de permissões
│       └── e2e/                     # guards + fluxo superadmin/impersonação
│
└── nexclin-lovable/                 # ← REFERÊNCIA SOMENTE LEITURA (MVP Vite)
    ├── src/  (telas do MVP — extrair regras, não estilo)
    └── supabase/migrations/ (as 56 — fonte da cópia da Fase 1)
```

**Structure Decision**: Web app (Next.js na raiz do repo novo + Supabase). A
camada de banco é portada 1:1 do irmão `../nexclin-lovable`; a de aplicação é
reescrita em App Router. O MVP nunca é editado (constituição, Princípio IV) e
serve só para extrair regras de comportamento.

## Fases de execução (com gate humano)

> Cada fase abre só após aprovação explícita de Arthur da fase anterior.
> O detalhamento acionável (tarefas) sai do `/speckit-tasks`.

| Fase | Entregável | Gate de aceite (resumo) | Pré-requisitos |
|---|---|---|---|
| **1 — Réplica do banco** | 56 migrações aplicadas no Supabase novo + `RELATORIO-FASE1.md` | Relatório sem divergências; 0 tabela com clinic_id sem RLS | Projeto Supabase + CLI + git |
| **2 — Seeds e superadmin** | `scripts/seed.ts` idempotente (plano Trial, saas_settings, user + operator) | Rodar 2x sem duplicar; senha nunca em código | Fase 1 aprovada; `SUPERADMIN_EMAIL` |
| **3 — Edge functions** | `superadmin-manage-user` + `invite-team-user` no ar | Chamada sem token → 401/403; update_email audita old→new | Fase 2 aprovada; secrets no projeto |
| **4 — App Next.js** | Auth + guards + painel superadmin + esqueleto da clínica | Os 7 critérios de aceite da spec, executados por Arthur | Fase 3 aprovada |

**Pós-Fase 2 (ação manual do operador, fora do executor):** definir a senha
real do superadmin via recovery no painel do Supabase; senha só no gerenciador.

## Complexity Tracking

> Sem violações da constituição. Nenhuma justificativa de complexidade
> necessária nesta fundação.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
