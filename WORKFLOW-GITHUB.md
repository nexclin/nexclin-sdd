# NexClin — Workflow GitHub (governança para o Claude Code)

> **O que é:** as regras de como specs viram milestones, tasks viram issues,
> issues viram branches/PRs e PRs viram merge — no repositório
> `nexclin/nexclin-sdd`. O Claude Code segue este documento em toda sessão.
> Baseado nas práticas de mercado para fluxo com agente de código
> (branch isolada por trabalho de agente, issues detalhadas, CI como
> portão de merge, humano revisando o delta).

---

## 1. Mapeamento (a espinha dorsal)

| Conceito do projeto | Recurso do GitHub |
|---|---|
| Spec (ROADMAP-SPECS.md) | **Milestone** `SPEC NNN — nome` (descrição = objetivo + nº de tasks) |
| Etapa da spec | **Label** `fase:F1`, `fase:F2`... + prefixo no título da issue |
| Task | **Issue** — título `[NNN][F#] verbo + objeto` (ex.: `[002][F1] CI: lint + type-check no PR`) |
| Execução de uma spec | **Branch** `spec/NNN-nome-curto` (ex.: `spec/002-esteira`) |
| Task individual dentro da spec | Commit referenciando a issue (`feat: ... (closes #12)`) |
| Entrega da spec | **1 Pull Request** da branch para `main` |

## 2. Labels padrão

- Prioridade: `P0`, `P1`, `P2`
- Setor: `setor:plataforma`, `setor:seguranca`, `setor:clinico`,
  `setor:financeiro`, `setor:receita`, `setor:gestao`
- Tipo: `tipo:db`, `tipo:ui`, `tipo:infra`, `tipo:teste`, `tipo:docs`
- Estado especial: `bloqueada` (com o motivo no corpo), `aceite`
  (issues de teste manual do Arthur)

## 3. Regras de issue (qualidade obrigatória)

Toda issue nasce com: **contexto** (por que existe, assumindo leitor com
contexto zero), **escopo** (o que entra e o que NÃO entra), **critério de
pronto** (verificável), e **referências** (spec, arquivos da referência
`../nexclin-lovable` quando houver). Issue vaga é devolvida, não executada.

**Criação just-in-time:** issues são criadas apenas quando a spec entra em
execução (após `/speckit.tasks`, que define a lista real). Milestones de
specs futuras existem desde já (dão visão), mas sem issues — backlog
gigante e desatualizado é passivo, não planejamento.

## 4. Regras de branch

- O agente **nunca** comita em `main`. Todo trabalho nasce em
  `spec/NNN-nome` (uma branch por spec, alinhada ao Spec Kit).
- Correção fora de spec (hotfix): branch `fix/descricao-curta`, issue
  própria, PR próprio.
- Branch mergeada é apagada.

## 5. Regras de PR e merge

1. **1 spec = 1 PR** para `main`, com corpo listando: issues fechadas
   (`Closes #a, #b, ...`), resumo do que mudou, e o resultado do
   `/speckit.analyze`.
2. **Portões de merge, em ordem:**
   - CI verde (a partir da SPEC 002: lint, type-check, testes, varredura
     de segredo). Até a 002 existir, o portão é revisão manual do Arthur.
   - Tasks com label `aceite` executadas manualmente pelo Arthur e
     confirmadas no PR (comentário "aceite ok").
3. Com os portões verdes, o Claude Code executa o merge (**squash**) e
   apaga a branch — `gh pr merge --squash --delete-branch`.
4. **Nunca** merge com CI vermelha, aceite pendente ou conflito resolvido
   às cegas. Na dúvida, parar e perguntar.
5. Fechada a spec: mover o milestone para fechado e atualizar o painel do
   `ROADMAP-SPECS.md` (tasks reais e concluídas) no mesmo PR ou em
   commit de docs.

## 6. Commits

Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`,
`refactor:` — sempre referenciando a issue (`(closes #N)` fecha no merge).
Um commit por task concluída; nada de commits gigantes multi-task.

## 7. Comandos de referência (gh CLI)

```bash
# milestone por spec
gh api repos/nexclin/nexclin-sdd/milestones -f title="SPEC 002 — Esteira & qualidade" -f description="12 tasks · P0"

# issue de task
gh issue create --title "[002][F1] CI: lint + type-check no PR" \
  --body-file .github/issue-bodies/002-f1-ci.md \
  --milestone "SPEC 002 — Esteira & qualidade" \
  --label "P0,setor:plataforma,tipo:infra"

# branch da spec
git checkout -b spec/002-esteira

# PR da spec
gh pr create --title "SPEC 002 — Esteira & qualidade" --body "Closes #1, #2, ..."

# merge com portões verdes
gh pr merge --squash --delete-branch
```

## 8. Estrutura de pastas das specs

```
specs/
├── 001-fundacao-superadmin/
│   ├── spec.md          (a especificação — o quê e por quê)
│   ├── plan.md          (gerado pelo /speckit.plan)
│   └── tasks.md         (gerado pelo /speckit.tasks)
├── 002-esteira-qualidade/
│   └── spec.md          (stub com o brief do ROADMAP até entrar em execução)
├── ...
└── BACKLOG.md
```

Cada spec do ROADMAP ganha sua pasta com `spec.md` (stub = brief do
roadmap). `plan.md` e `tasks.md` só nascem quando a spec entra em execução.
