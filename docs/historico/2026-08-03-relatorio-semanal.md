# Relatório Semanal — NexClin (estrutura nova)

**Data:** 2026-08-03 · **Gerado a partir de:** git + GitHub (`nexclin/nexclin-sdd`) reais.
_Notas marcadas "não verificado" = não confirmável no repo/GitHub nesta data._

---

## 1. Foto do momento

- **Branch atual:** `spec/001-fundacao`
- **Último commit:** `a195158` — 2026-08-03 — _"docs(001-F1): RELATORIO-FASE1 (57/57 aplicadas) + fix seed carrega .env.local"_
- **SPEC em execução:** **SPEC 001 — Fundação** (banco, autenticação, multi-tenant e Super Admin).
- **Fase atual:** **Fase 2 (seeds/superadmin)** em andamento; Fase 1 concluída; Fase 3 parcialmente concluída; Fase 4 com a base (acesso) pronta.

### Painel de progresso (por spec)

> **Aviso factual:** o arquivo `ROADMAP-SPECS.md` **não existe** no repositório
> nesta data. Portanto, só a **SPEC 001** está definida e rastreável. As specs
> 002–015 são **não verificadas** (sem roadmap versionado, sem milestones).

| Spec | Status | Tasks (total × concluídas) | Fonte |
|---|---|---|---|
| **SPEC 001 — Fundação** | Em execução | 28 × 0 issues fechadas no GitHub (≈11 tarefas de código concluídas e verificadas — ver §6) | Milestone #1 + issues #1–#28 (reais) |
| SPEC 002–015 | Não verificado | Não verificado | `ROADMAP-SPECS.md` ausente |

---

## 2. O que foi feito (desde o início da estrutura nova)

**Setup do repositório e método (2026-08-02)**
- Repositório `nexclin/nexclin-sdd` com **Spec Kit** (método SDD) instalado.
- **Constituição do projeto v1.0.0** (6 princípios inegociáveis: segurança no banco, LGPD/auditoria, contrato de módulos, aprovação humana por fase, segredos fora do código, valor operacional).
- Documentos de governança: `../harness/workflow-github.md`, `README.md`, `CLAUDE.md`.

**Governança no GitHub (2026-08-02)**
- **20 labels** padronizadas, **1 milestone** (SPEC 001), **28 issues** detalhadas (#1–#28), uma por tarefa das 4 fases.
- **PR #29** aberto e **mergeado** na `main` (primeira leva da fundação).
  - _Observação factual:_ **7 commits recentes** (execução das fases) ainda estão só na branch `spec/001-fundacao`, **não mergeados** na `main` — aguardam novo PR.

**SPEC 001 — estado das fases**
- **Fase 1 — Banco replicado: CONCLUÍDA e verificada (2026-08-03).**
  As **57 migrações** foram aplicadas no Supabase próprio (`bfkghwkhzkimzyiovotj`); verificação: **57/57 aplicadas, 0 pendentes**. Relatório técnico em `RELATORIO-FASE1.md`. Duas correções feitas: contagem 55→56 e remoção de dado de teste do MVP que travava a carga.
- **Fase 2 — Seeds/superadmin: EM ANDAMENTO.** Script `scripts/seed.ts` escrito (cria plano Trial + superadmin de forma idempotente). **Ainda não executado** — depende de uma chave de acesso (ver §5).
- **Fase 3 — Edge functions: majoritariamente CONCLUÍDA (2026-08-02/03).**
  Duas funções portadas (`superadmin-manage-user`, `invite-team-user`) e **deployadas** no projeto. Teste de segurança básico passou: chamada **sem autenticação → bloqueada (HTTP 401)**. Falta a verificação de auditoria completa (depende do superadmin existir).
- **Fase 4 — Aplicação (acesso Super Admin): BASE CONCLUÍDA (2026-08-02).**
  Aplicação Next.js criada; **tela de login do Super Admin** e **guarda de acesso** implementadas e com verificação de tipos limpa. As demais telas do painel (contas, planos etc.) ainda **não** foram construídas.

---

## 3. O que está em andamento agora

- **Tarefa exata:** rodar o **seed** que cria a conta Super Admin (Fase 2, issues #9/#11).
- **O que falta para fechar a SPEC 001:**
  1. Preencher 2 chaves de acesso do Supabase no ambiente local (bloqueio ativo — §5).
  2. Rodar o seed e definir a senha real do Super Admin (via recuperação por e-mail).
  3. Construir as telas restantes do painel (contas, planos, cupons, impersonação etc.).
  4. **Critérios de aceite manuais pendentes** (a serem executados por Arthur):
     - #6 (F1): schema sem divergências, RLS 100%.
     - #11 (F2): seed rodado 2× sem duplicar. · #12 (F2): senha real definida por recovery.
     - #17 (F3): auditoria de troca de e-mail. · #28 (F4): os 7 critérios de aceite do acesso.

---

## 4. Próximos passos (2 semanas)

> **Não verificado em detalhe:** sem `ROADMAP-SPECS.md` no repo, a fila 002+ não
> é confirmável. O que segue é o encadeamento já registrado no `../harness/workflow-github.md`.

- **Fechar a SPEC 001 (Fundação):** superadmin funcionando ponta a ponta + telas do painel + aceites manuais. _Valor: base segura multi-tenant e painel de operação do SaaS._
- **SPEC 002 — Esteira/CI (próxima da fila, citada no workflow):** automação de testes e do portão de merge. _Valor: deixar de depender de revisão manual a cada entrega._
- **SPEC 003+ (módulos do 1º cliente):** **não verificado** — escopo a ser definido no `ROADMAP-SPECS.md`.

---

## 5. Bloqueios e decisões pendentes

1. **[BLOQUEIO ATIVO] Duas chaves do Supabase** (`anon` e `service_role`) não preenchidas no ambiente local (`.env.local`). Sem elas: o seed não roda (sem Super Admin) e o app não conecta (sem teste do login). _Ação: Arthur cola as chaves do painel._
2. **MCP do Supabase não autorizado** (login OAuth pendente). Não é bloqueio: o banco segue sendo operado pela CLI + migrações versionadas.
3. **`ROADMAP-SPECS.md` ausente** no repo → specs 002–015 não definidas, sem milestones. _Decisão pendente: publicar o roadmap para destravar o planejamento das próximas specs._
4. **Senha real do Super Admin** a definir por recuperação de e-mail (após o seed).
5. **Aceites manuais de Arthur** pendentes (issues com label `aceite`: #6, #11, #12, #17, #28).
6. **7 commits na branch ainda não mergeados** na `main` (aguardando novo PR).
7. **Corte do escopo de lançamento:** **não verificado / a decidir** (quais módulos entram no 1º cliente).

---

## 6. Números

- **Tasks da SPEC 001 (única definida):** **28** (das quais **26 P0** e 2 P1).
- **Concluídas formalmente (issues fechadas no GitHub):** **0 / 28**.
  _As issues fecham no aceite/merge; o trabalho de código está adiante do fechamento formal._
- **Concluídas de fato (código pronto e verificado):** **≈11 / 28** (Fase 1: 5; Fase 3: 4; Fase 4: 2) → **~39%** da SPEC 001.
- **% de progresso até o lançamento:** **não verificado** — o escopo de lançamento (SPEC 001 + módulos do 1º cliente) não está definido sem o `ROADMAP-SPECS.md`.
- **Commits na última semana:** **12** (11 na branch `spec/001-fundacao`).
- **Migrações de banco aplicadas:** **57 / 57**.
- **Edge functions no ar:** **2 / 2**.

---

_Relatório factual gerado do estado real do repositório e do GitHub. Itens "não
verificado" indicam ausência de fonte confirmável (principalmente o
`ROADMAP-SPECS.md`), não ausência de trabalho._
