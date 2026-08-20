# Tasks: SPEC 001 — Fundação (banco, auth, multi-tenant e Super Admin)

**Feature**: `001-fundacao-superadmin` · **Branch**: `spec/001-fundacao` · **Milestone**: #1

> Organização por **fase** (F1→F4), fiel à spec. Cada fase é um incremento
> entregável com gate de aceite manual (Princípio IV). `[P]` = paralelizável.
> `[aceite]` = tarefa de verificação manual do Arthur (label `aceite`).
> Regra transversal em toda task: RLS/default deny, segurança no banco,
> nenhuma credencial versionada, TS estrito (constituição I–V).

---

## Estado verificado em 18/08/2026

Sincronizado contra o código, o repositório e **os dois bancos ao vivo** — não
contra memória. Cada marcação abaixo tem evidência ao lado.

| Fase | Situação |
|---|---|
| **F1 — réplica do banco** | **completa** (T001–T006) |
| **F2 — seeds e superadmin** | **completa exceto T012**, que é ato manual do operador |
| **F3 — edge functions** | portadas e **deployadas**; falta metade do aceite (T017) |
| **F4 — app Next.js** | **parcial** — acesso superadmin em pé, painel em 2 de 11 telas |

Legenda: ✅ feito · ⏳ parcial ou pendente de ato manual · ❌ não iniciada ·
⚠️ feito, com defeito registrado.

**Duas dívidas que merecem destaque**, porque não aparecem na contagem:
`T021` (testes de permissão) é **mínimo obrigatório da constituição** e está em
zero; e `T014` foi portada com um caminho que deixa admin definir senha de
terceiro, contra a regra (e) — correção marcada para 22–23/08.

## Fase 1 — Réplica do banco  (`fase:F1` · `tipo:db` · `setor:plataforma`)

- [x] T001 Inicializar Supabase e linkar ao projeto novo em `supabase/config.toml` (`supabase init` + `supabase link --project-ref <ref>`) ✅ `supabase/config.toml` existe.
- [x] T002 Copiar as 56 migrações de `../nexclin-lovable/supabase/migrations` para `supabase/migrations` (preservando ordem cronológica dos nomes) ✅ 58 arquivos em `supabase/migrations` (57 portadas + a de 17/08).
- [x] T003 Criar migração nova que **dropa apenas o trigger** `on_auth_user_created_superadmin`, mantendo a função `seed_superadmin_operator` (preserva o `REVOKE` da migração `20260802073330`) — exceção do seed de e-mail fixo ✅ `20260802090000_drop_seed_superadmin_trigger.sql`.
- [x] T004 Aplicar as migrações em ordem via `supabase db push`; se `ALTER TYPE app_role ADD VALUE 'user'` (`20260725001410`) falhar por transação, isolar preservando a ordem ✅ aplicadas — 44 tabelas no banco ao vivo.
- [x] T005 Gerar `specs/001-fundacao-superadmin/RELATORIO-FASE1.md` comparando schema aplicado × referência: tabelas com `clinic_id`, RLS por tabela, funções, triggers, enums ✅ `RELATORIO-FASE1.md` (57/57).
- [x] T006 [aceite] Verificar `RELATORIO-FASE1.md` sem divergências; **0 tabela com `clinic_id` sem RLS**; divergência → PARAR e reportar ✅ **verificado ao vivo 17/08**: 0 tabelas sem RLS, 0 com RLS e sem policy, 0 policies `anon`. Ver `docs/seguranca/auditoria-rls-2026-08-17.md`.

## Fase 2 — Seeds e conta Super Admin  (`fase:F2` · `tipo:db` · `setor:plataforma`)

- [x] T007 Criar `scripts/seed.ts` (service role, fora do bundle): plano "Trial Padrão" (`is_default_trial=true`, `active`, `hidden`, preços 0, `trial_days=14`, limites NULL, 15 ModuleKeys=true) ✅ `scripts/seed.ts:56-92`.
- [x] T008 [P] `seed.ts`: `saas_settings` singleton com `trial_default_plan_id` → plano Trial e `trial_default_days=14` ✅ `scripts/seed.ts:94-121`.
- [x] T009 `seed.ts`: criar usuário auth `SUPERADMIN_EMAIL` via admin API (senha ALEATÓRIA descartada) + registro em `superadmin_operators` (`active=true`) ✅ `scripts/seed.ts:137-172`.
- [x] T010 `seed.ts`: garantir idempotência (upserts / `ON CONFLICT` / checagem de existência) ✅ select-then-insert + `upsert onConflict`.
- [x] T011 [aceite] Rodar `seed.ts` **2x** e provar idempotência (nada duplica); confirmar que nenhuma senha aparece em código/log ✅ **rodado 2x em 18/08**: plano trial 1, `saas_settings` 1, operador 1, usuário auth 1, mesmo uuid de plano nas duas rodadas. Nenhuma senha em log.
- [ ] T012 [aceite] (manual do operador, pós-F2) Definir a senha real do superadmin via recovery no painel Supabase; senha só no gerenciador ⏳ **pendente** — `last_sign_in_at` nunca preenchido; o superadmin ainda não logou. O fluxo de recovery necessário já existe (T019).

## Fase 3 — Edge functions  (`fase:F3` · `tipo:infra` · `setor:seguranca`)

- [x] T013 Portar `supabase/functions/superadmin-manage-user` (guardas: bearer + `is_superadmin`; `update_email` audita `old→new`; `send_password_reset` via `resetPasswordForEmail`; **nenhuma action define senha**) ✅ `supabase/functions/superadmin-manage-user/` — só `update_email` e `send_password_reset`; `set_password` removida.
- [x] T014 [P] Portar `supabase/functions/invite-team-user` (cria usuário convidado + vínculo; secrets via env do projeto novo) ✅ portada; o defeito herdado do MVP — aceitava `password` do cliente, contra a regra (e) — foi **corrigido em 19/08 pelo T017 da SPEC 002**. Hoje a função convida por `generateLink` e nenhum caminho define senha de terceiro. Falta aplicar o mesmo na plataforma Lovable, que segue com a versão antiga.
- [x] T015 [P] Registrar `anamnesis-public` e `generate-insights` em `specs/BACKLOG.md` (não portar agora) ✅ as duas registradas em `specs/BACKLOG.md`.
- [x] T016 Deploy das functions via CLI (`supabase functions deploy`) ✅ **verificado ao vivo 18/08**: as duas respondem no projeto novo.
- [ ] T017 [aceite] Smoke test de auth: chamada sem token → 401/403; `update_email` grava diff em `superadmin_audit_log` ⏳ **parcial** — sem token → **401 confirmado** nas duas. Falta provar o diff de `update_email` em `superadmin_audit_log`.

## Fase 4 — App Next.js: acesso e painel Super Admin  (`fase:F4` · `tipo:ui` · `setor:plataforma`)

- [x] T018 Scaffold Next.js (App Router) + TS strict + Tailwind/shadcn; `lib/supabase/` clients server/browser via `@supabase/ssr` ✅ `app/`, `lib/supabase/{client,server,middleware}.ts`.
- [ ] T019 Auth: login e-mail/senha (Supabase Auth), reset de senha, rotas públicas/protegidas espelhando a referência ⏳ **parcial** — reset completo e testado (`/esqueci-senha`, `/auth/callback`, `/nova-senha`; 200/307 verificados). Falta o login do usuário comum e as rotas da clínica.
- [ ] T020 Guards em `lib/auth/`: `ProtectedRoute`, `RequirePermission` (consome `my_permission`/`get_my_subscription_state`), `SuperAdminGuard`, `OnboardingGuard` (bypass sob impersonação) ❌ só existe `lib/auth/useSuperAdmin.ts`. Faltam `ProtectedRoute`, `RequirePermission`, `OnboardingGuard`.
- [x] T021 [P] Hook de permissões + testes unit (Vitest) — mínimo obrigatório da constituição ✅ **fechado em 20/08/2026.** `vitest.config.ts` (ambiente node, sem jsdom — a lógica testável foi escrita pura de propósito), `lib/auth/modulos.ts` (as 15 ModuleKeys), `lib/auth/permissao.ts` (núcleo puro) e `lib/auth/usePermissao.ts` (o hook). **19 testes, todos passando.**
  - **Decisão de projeto:** o front **não reimplementa a cascata**. Ela vive em `my_permission`, e o hook chama a mesma função que a RLS usa — a forma mais segura de espelhar é não copiar, porque uma segunda implementação sempre diverge da primeira, e diverge para o lado de liberar demais (regra (c); `.claude/rules/app.md`).
  - **O que os testes protegem:** o front falhar fechado. Erro de RPC, resposta nula, tipo errado, string vazia, módulo fora das 15 chaves → `none`. Mais a trava do contrato de módulos: acrescentar chave em `modulos.ts` sem acrescentar no banco quebra o teste, de propósito.
  - **Provado por mutação, não só por passar:** removida a checagem de erro → 2 testes falham; removida a verificação do contrato de módulo → 2 testes falham. Teste que não falha quando o código quebra não protege nada.
  - **Fora de escopo aqui, e continua aberto:** a cascata em si (superadmin, assinatura suspensa, teto do plano) exige banco e é o **T027**, em Playwright. Este T021 cobre o perímetro do front, não a regra.
- [x] T022 Painel `/superadmin`: login próprio validando `is_superadmin` ✅ `app/superadmin/login/page.tsx` + guard server-side em `(panel)/layout.tsx:27-33` (RPC `is_superadmin`).
- [ ] T023 Telas do painel: contas (lista+detalhe), planos (editor 15 ModuleKeys), cupons, faturamento, métricas, logs, operadores, configurações, comunicação ⏳ **2 de 11** — dashboard e contas. Faltam detalhe da conta, planos, cupons, faturamento, métricas, logs, operadores, configurações, comunicação.
- [ ] T024 Seção Perfis: edição auditada, troca de e-mail e envio de reset (via edge function da F3) ❌ não iniciada. Sem modelo na referência (divergência D5) — precisa ser desenhada antes de executada.
- [ ] T025 Impersonação: "Acessar conta" (confirmação) → RPC `superadmin_enter_clinic` → banner âmbar fixo em todas as rotas + "Sair da conta"; cache zerado a cada entrada/saída ⏳ **parcial** — `enter-clinic-button.tsx` existe. Banner âmbar, sair da conta e limpeza de cache não verificados.
- [ ] T026 [P] App da clínica: esqueleto navegável (dashboard vazio + menu respeitando `my_permission`) ❌ não iniciada.
- [ ] T027 e2e (Playwright): guards de rota + fluxo superadmin/impersonação ❌ sem `playwright.config`, sem pasta de e2e.
- [ ] T028 [aceite] Executar os 7 critérios de aceite da spec (roteiro em `quickstart.md`) ❌ depende das anteriores.

---

## Dependências (ordem de conclusão)

```
F1 (T001→T006) ──▶ F2 (T007→T012) ──▶ F3 (T013→T017) ──▶ F4 (T018→T028)
```

Fases são sequenciais (cada uma abre só após o aceite da anterior — Princípio IV).
Dentro de cada fase, tarefas `[P]` podem correr em paralelo (arquivos distintos,
sem dependência mútua): T008; T014/T015; T021/T026.

## Gates de aceite manual (label `aceite`)

`T006` · `T011` · `T012` · `T017` · `T028` — executados por Arthur; a fase não
fecha sem eles ("implementado ≠ funciona").

## Escopo MVP da fundação

O MVP da fundação é **F1+F2** (banco replicado + superadmin sem senha em código):
prova o isolamento multi-tenant e a identidade de suporte. F3+F4 entregam a
operação real do painel. Módulos de negócio → specs 002+.

## Contexto / escopo / pronto por task

> Base para os corpos das issues (regra da seção 3 do WORKFLOW: contexto zero).
> Referências: `spec.md`, `plan.md`, `data-model.md`, `contracts/`.

- **T001–T006 (F1):** contexto — o schema validado (56 migrações, 44 tabelas, 3
  enums, ~40 funções) precisa existir intacto no Supabase próprio antes de
  qualquer app. Escopo — só banco; não tocar app. Pronto — `db push` sem erro +
  `RELATORIO-FASE1.md` sem divergências.
- **T007–T012 (F2):** contexto — sem o plano Trial e o operador superadmin, o
  painel não tem como nascer nem ser acessado. Escopo — seed idempotente; senha
  jamais no script. Pronto — 2ª execução não duplica; superadmin em `auth.users`
  + `superadmin_operators`.
- **T013–T017 (F3):** contexto — e-mail/reset e convites dependem de functions com
  guarda dupla. Escopo — portar 2 functions; backlog das outras 2. Pronto —
  sem token → 401/403; auditoria de `update_email` gravada.
- **T018–T028 (F4):** contexto — a aplicação renasce consumindo a segurança do
  banco (a cascata já está no Postgres). Escopo — auth + guards + painel
  superadmin + esqueleto da clínica; sem módulos de negócio. Pronto — os 7
  critérios de aceite executados por Arthur.
