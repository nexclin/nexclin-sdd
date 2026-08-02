# Tasks: SPEC 001 — Fundação (banco, auth, multi-tenant e Super Admin)

**Feature**: `001-fundacao-superadmin` · **Branch**: `spec/001-fundacao` · **Milestone**: #1

> Organização por **fase** (F1→F4), fiel à spec. Cada fase é um incremento
> entregável com gate de aceite manual (Princípio IV). `[P]` = paralelizável.
> `[aceite]` = tarefa de verificação manual do Arthur (label `aceite`).
> Regra transversal em toda task: RLS/default deny, segurança no banco,
> nenhuma credencial versionada, TS estrito (constituição I–V).

---

## Fase 1 — Réplica do banco  (`fase:F1` · `tipo:db` · `setor:plataforma`)

- [ ] T001 Inicializar Supabase e linkar ao projeto novo em `supabase/config.toml` (`supabase init` + `supabase link --project-ref <ref>`)
- [ ] T002 Copiar as 56 migrações de `../nexclin-lovable/supabase/migrations` para `supabase/migrations` (preservando ordem cronológica dos nomes)
- [ ] T003 Criar migração nova que **dropa apenas o trigger** `on_auth_user_created_superadmin`, mantendo a função `seed_superadmin_operator` (preserva o `REVOKE` da migração `20260802073330`) — exceção do seed de e-mail fixo
- [ ] T004 Aplicar as migrações em ordem via `supabase db push`; se `ALTER TYPE app_role ADD VALUE 'user'` (`20260725001410`) falhar por transação, isolar preservando a ordem
- [ ] T005 Gerar `specs/001-fundacao-superadmin/RELATORIO-FASE1.md` comparando schema aplicado × referência: tabelas com `clinic_id`, RLS por tabela, funções, triggers, enums
- [ ] T006 [aceite] Verificar `RELATORIO-FASE1.md` sem divergências; **0 tabela com `clinic_id` sem RLS**; divergência → PARAR e reportar

## Fase 2 — Seeds e conta Super Admin  (`fase:F2` · `tipo:db` · `setor:plataforma`)

- [ ] T007 Criar `scripts/seed.ts` (service role, fora do bundle): plano "Trial Padrão" (`is_default_trial=true`, `active`, `hidden`, preços 0, `trial_days=14`, limites NULL, 15 ModuleKeys=true)
- [ ] T008 [P] `seed.ts`: `saas_settings` singleton com `trial_default_plan_id` → plano Trial e `trial_default_days=14`
- [ ] T009 `seed.ts`: criar usuário auth `SUPERADMIN_EMAIL` via admin API (senha ALEATÓRIA descartada) + registro em `superadmin_operators` (`active=true`)
- [ ] T010 `seed.ts`: garantir idempotência (upserts / `ON CONFLICT` / checagem de existência)
- [ ] T011 [aceite] Rodar `seed.ts` **2x** e provar idempotência (nada duplica); confirmar que nenhuma senha aparece em código/log
- [ ] T012 [aceite] (manual do operador, pós-F2) Definir a senha real do superadmin via recovery no painel Supabase; senha só no gerenciador

## Fase 3 — Edge functions  (`fase:F3` · `tipo:infra` · `setor:seguranca`)

- [ ] T013 Portar `supabase/functions/superadmin-manage-user` (guardas: bearer + `is_superadmin`; `update_email` audita `old→new`; `send_password_reset` via `resetPasswordForEmail`; **nenhuma action define senha**)
- [ ] T014 [P] Portar `supabase/functions/invite-team-user` (cria usuário convidado + vínculo; secrets via env do projeto novo)
- [ ] T015 [P] Registrar `anamnesis-public` e `generate-insights` em `specs/BACKLOG.md` (não portar agora)
- [ ] T016 Deploy das functions via CLI (`supabase functions deploy`)
- [ ] T017 [aceite] Smoke test de auth: chamada sem token → 401/403; `update_email` grava diff em `superadmin_audit_log`

## Fase 4 — App Next.js: acesso e painel Super Admin  (`fase:F4` · `tipo:ui` · `setor:plataforma`)

- [ ] T018 Scaffold Next.js (App Router) + TS strict + Tailwind/shadcn; `lib/supabase/` clients server/browser via `@supabase/ssr`
- [ ] T019 Auth: login e-mail/senha (Supabase Auth), reset de senha, rotas públicas/protegidas espelhando a referência
- [ ] T020 Guards em `lib/auth/`: `ProtectedRoute`, `RequirePermission` (consome `my_permission`/`get_my_subscription_state`), `SuperAdminGuard`, `OnboardingGuard` (bypass sob impersonação)
- [ ] T021 [P] Hook de permissões + testes unit (Vitest) — mínimo obrigatório da constituição
- [ ] T022 Painel `/superadmin`: login próprio validando `is_superadmin`
- [ ] T023 Telas do painel: contas (lista+detalhe), planos (editor 15 ModuleKeys), cupons, faturamento, métricas, logs, operadores, configurações, comunicação
- [ ] T024 Seção Perfis: edição auditada, troca de e-mail e envio de reset (via edge function da F3)
- [ ] T025 Impersonação: "Acessar conta" (confirmação) → RPC `superadmin_enter_clinic` → banner âmbar fixo em todas as rotas + "Sair da conta"; cache zerado a cada entrada/saída
- [ ] T026 [P] App da clínica: esqueleto navegável (dashboard vazio + menu respeitando `my_permission`)
- [ ] T027 e2e (Playwright): guards de rota + fluxo superadmin/impersonação
- [ ] T028 [aceite] Executar os 7 critérios de aceite da spec (roteiro em `quickstart.md`)

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
