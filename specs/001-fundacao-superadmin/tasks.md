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

**As duas dívidas que mereciam destaque foram fechadas em 20/08/2026:**
`T021` (testes de permissão, mínimo obrigatório da constituição) saiu de zero
para 19 testes verificados por mutação; e o `T014`, que aceitava senha de
terceiro contra a regra (e), foi reescrito e publicado — aqui e na plataforma ao
vivo — antecipando a janela de 22–23/08.

**O que ficou aberto e importa:** `T020` (guards `ProtectedRoute`,
`RequirePermission`, `OnboardingGuard`), `T027` (e2e da cascata, que é onde a
regra de permissão de fato se prova) e `T012` (senha do superadmin, ato manual).

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
- [x] T014 [P] Portar `supabase/functions/invite-team-user` (cria usuário convidado + vínculo; secrets via env do projeto novo) ✅ portada; o defeito herdado do MVP — aceitava `password` do cliente, contra a regra (e) — foi **corrigido em 20/08 pelo T017 da SPEC 002**. Hoje a função convida por `generateLink` e nenhum caminho define senha de terceiro. O mesmo já foi aplicado e deployado na plataforma Lovable no mesmo dia (commit `dabf1ef`).
- [x] T015 [P] Registrar `anamnesis-public` e `generate-insights` em `specs/BACKLOG.md` (não portar agora) ✅ as duas registradas em `specs/BACKLOG.md`.
- [x] T016 Deploy das functions via CLI (`supabase functions deploy`) ✅ **verificado ao vivo 18/08**: as duas respondem no projeto novo.
- [ ] T017 [aceite] Smoke test de auth: chamada sem token → 401/403; `update_email` grava diff em `superadmin_audit_log` ⏳ **parcial** — sem token → **401 confirmado** nas duas. Falta provar o diff de `update_email` em `superadmin_audit_log`.

## Fase 4 — App Next.js: acesso e painel Super Admin  (`fase:F4` · `tipo:ui` · `setor:plataforma`)

- [x] T018 Scaffold Next.js (App Router) + TS strict + Tailwind/shadcn; `lib/supabase/` clients server/browser via `@supabase/ssr` ✅ `app/`, `lib/supabase/{client,server,middleware}.ts`.
- [x] T019 Auth: login e-mail/senha, reset de senha, rotas públicas e protegidas ✅ **código completo em 25/08**: `app/login/page.tsx` e as rotas `/app/*`. O reset já estava testado. **Falta o aceite manual**, que é entrar com uma conta real. A mensagem de erro é única para e-mail inexistente e senha errada, de propósito, para não permitir enumeração de usuário (requisito `NGS1.02.16` da certificação SBIS).
- [x] T020 Guards em `lib/auth/`: `ProtectedRoute`, `RequirePermission`, `SuperAdminGuard`, `OnboardingGuard` ✅ **fechado em 25/08.**
  - **Arquitetura:** a decisão foi separada do componente. `lib/auth/decisoes.ts` é puro e síncrono e concentra toda a regra; `lib/auth/servidor.ts` busca o dado e **nunca lança**; `lib/auth/guards.tsx` só obedece. Guard `async` que chama `redirect()` é caro de testar, então ele ficou burro de propósito.
  - **Server Components, não cliente.** Resolve antes de mandar HTML, então não existe janela em que conteúdo protegido pisca. É a exigência de estado de carga do contrato de guards.
  - **61 testes novos**, somados aos 19 do T021: **80 no total, todos passando.** Cobrem sessão ausente em oito formatos, `is_superadmin` quase verdadeiro (string, número, objeto), permissão nula, vazia e com erro de RPC, módulo fora das 15 chaves, assinatura suspensa e cancelada, o bypass de onboarding sob impersonação, e a **ordem** das decisões.
  - **Defeito encontrado por teste, e corrigido:** a rota do dashboard é `/app`, e o casamento por prefixo fazia **qualquer** rota desconhecida (`/app/inexistente`) resolver como dashboard. Como o dashboard não é gateado, a rota desconhecida saía liberada. Corrigido com a marca `gateada` no catálogo.
  - **`OnboardingGuard` é derivado, não persistido:** a referência não guarda onboarding concluído em coluna nenhuma, ela deriva de doze contagens. `lib/auth/onboarding.ts` replica isso, inclusive a regra de que o passo de equipe exige **duas** pessoas ativas.
  - **Middleware ajustado:** `x-pathname` passou a ser escrito no request. Sem ele o layout não sabe qual módulo protege a rota, e `RequirePermission` não dispararia no nível do layout.
- [x] T021 [P] Hook de permissões + testes unit (Vitest) — mínimo obrigatório da constituição ✅ **fechado em 20/08/2026.** `vitest.config.ts` (ambiente node, sem jsdom — a lógica testável foi escrita pura de propósito), `lib/auth/modulos.ts` (as 15 ModuleKeys), `lib/auth/permissao.ts` (núcleo puro) e `lib/auth/usePermissao.ts` (o hook). **19 testes, todos passando.**
  - **Decisão de projeto:** o front **não reimplementa a cascata**. Ela vive em `my_permission`, e o hook chama a mesma função que a RLS usa — a forma mais segura de espelhar é não copiar, porque uma segunda implementação sempre diverge da primeira, e diverge para o lado de liberar demais (regra (c); `.claude/rules/app.md`).
  - **O que os testes protegem:** o front falhar fechado. Erro de RPC, resposta nula, tipo errado, string vazia, módulo fora das 15 chaves → `none`. Mais a trava do contrato de módulos: acrescentar chave em `modulos.ts` sem acrescentar no banco quebra o teste, de propósito.
  - **Provado por mutação, não só por passar:** removida a checagem de erro → 2 testes falham; removida a verificação do contrato de módulo → 2 testes falham. Teste que não falha quando o código quebra não protege nada.
  - **Fora de escopo aqui, e continua aberto:** a cascata em si (superadmin, assinatura suspensa, teto do plano) exige banco e é o **T027**, em Playwright. Este T021 cobre o perímetro do front, não a regra.
- [x] T022 Painel `/superadmin`: login próprio validando `is_superadmin` ✅ `app/superadmin/login/page.tsx` + guard server-side em `(panel)/layout.tsx:27-33` (RPC `is_superadmin`).
- [x] T023 Telas do painel ✅ **11 de 11 em 25/08.** Dashboard e contas já existiam; entraram detalhe da conta, planos, cupons, faturamento, métricas, logs, operadores, configurações e comunicação. Todas Server Components. **Falta aceite manual com dado real.**
  - **Planos** mostra as 15 ModuleKeys sempre, acesas e apagadas. Listar só as acesas esconderia plano mal configurado, que é justamente o que se procura. Leitura por enquanto: escrever exige fechar o formato de `enabled_modules` (array no default, objeto no uso), decisão do BACKLOG que pertence à SPEC 004.
  - **Métricas** não porta o histórico de MRR da referência, que era sintético. Gráfico com número inventado é pior que ausência de gráfico, porque alguém decide em cima dele.
  - **Comunicação** foi portada como aviso do que falta, e não como formulário. Na referência é stub, e formulário que não envia é pior que tela vazia.
  - **Detalhe da conta** mostra o contador de assentos, que fecha a divergência D4 do INVENTARIO-UI: o limite existia no banco, com trigger, e não aparecia em tela nenhuma.
- [x] T024 Seção Perfis ✅ **desenhada e implementada em 25/08**, dentro do detalhe da conta. Consome a edge function `superadmin-manage-user`. **Falta aceite manual.**
  - **Duas ações, e a terceira não existe de propósito:** trocar e-mail, auditado e com confirmação explícita porque troca a credencial de acesso da pessoa, e enviar recuperação de senha. **Não há caminho para definir senha de ninguém**, pela regra (e), e o e2e tem um teste que falha se um botão desses reaparecer na tela.
  - **Limitação registrada:** o e-mail atual não é exibido porque vive em `auth.users`, fora do alcance de qualquer sessão autenticada. Quem o resolve é a própria edge function, com service role. Expor `auth.users` por RPC só para melhorar um rótulo seria troca ruim.
- [x] T025 Impersonação ✅ **completado em 25/08.** O botão de entrar já existia; entraram o banner âmbar e a saída. **Falta aceite manual: entrar numa conta e sair.**
  - **Todas as rotas é literal:** o banner vive nos dois layouts, o do app da clínica e o do painel. Operador que volta ao painel com impersonação ativa precisa continuar vendo onde está, senão a próxima ação sai na conta errada.
  - **Cache:** não há React Query neste app, os dados são lidos em Server Component. O equivalente exato de zerar o cache é `router.refresh()`, e a ordem importa: descarta primeiro, navega depois. Invertido, a primeira tela após a saída ainda mostraria dado da clínica de onde se saiu.
- [x] T026 [P] App da clínica: esqueleto navegável ✅ **25/08.** `app/app/` com layout, menu lateral, início, conta suspensa e configurações. **Falta aceite manual.**
  - O menu é montado a partir de `my_permission`, um módulo por vez, e item negado não aparece. Esconder é cortesia; quem bloqueia é a rota e a RLS.
  - **`consultas` e `equipe` ficaram fora do menu**, com motivo: `consultas` não tem destino próprio decidido (a ambiguidade está registrada em `docs/dominio/modulos.md`) e `equipe` vive dentro de configurações. Item de menu sem destino é bug de navegação.
  - A tela de conta suspensa existe porque negar sem explicar manda o usuário para um app sem menu nenhum, sem entender por quê.
- [ ] T027 e2e (Playwright) ⏳ **escrito em 25/08, NÃO executado.** `playwright.config.ts` e `e2e/guards.spec.ts` existem, `@playwright/test` instalado, script `npm run test:e2e` criado.
  - **Por que não fechou:** rodar exige um banco com seed e credenciais de teste (`E2E_SUPERADMIN_EMAIL`, `E2E_USUARIO_EMAIL` e as senhas). Elas não existem ainda, e o T012 registra que o superadmin nunca logou.
  - **O que já roda sem credencial:** o bloco de sessão ausente, que cobre as 3 rotas do app e as 10 do painel.
  - **Os testes pulam com motivo explícito quando falta credencial**, em vez de passar vazios. Suíte verde que não exercitou nada é o pior resultado possível: some com o alarme sem resolver o problema.
  - **Fecha quando** o Arthur rodar `npm run test:e2e` com as variáveis preenchidas.
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
