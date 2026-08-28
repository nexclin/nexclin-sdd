# Skills e plugins a importar para o harness

> Pesquisa feita em **25/08/2026**, direto na API do GitHub (estrelas, licença
> e data do último push conferidas na hora, não de memória). O catálogo de
> skills e plugins da conta claude.ai foi consultado primeiro e voltou **vazio**,
> por isso a busca foi para os repositórios públicos.

---

## A regra que vem antes da lista

A mesma lição do OpenClinic vale aqui, e ela decide **como** se importa:

> **Nada de terceiro é copiado para dentro deste repositório.**
> Marketplace de plugin é **referência**, não cópia. O plugin vive no cache do
> Claude Code, com a licença dele, e o nosso `git` não carrega uma linha do
> código dos outros.

Isso não é preciosismo. Duas das melhores opções pesquisadas são copyleft:
`context-engineering-kit` é GPL-3.0 e `trailofbits/skills` é CC-BY-SA-4.0.
Copiar o texto delas para `.claude/skills/` cria exatamente o problema que a
§2 da análise do OpenClinic descreve. Referenciar pelo marketplace não cria.

Onde precisarmos do comportamento e não da licença, **escrevemos a nossa
versão**, como foi feito em `nx-paralelo`.

---

## Camada 1: o que instalar já

### `superpowers` · obra/superpowers-marketplace

**277.193 ★ · MIT · push em 19/08/2026.** É o repositório de skills mais
adotado do ecossistema, e a licença é permissiva.

Skills que respondem diretamente ao que o Arthur pediu (executar várias
tarefas ao mesmo tempo):

| Skill | O que resolve aqui |
|---|---|
| `dispatching-parallel-agents` | um agente por domínio independente. É o motor das raias do mapa de execução. |
| `using-git-worktrees` | workspace isolado por tarefa, com detecção de isolamento que já existe. Resolve o conflito de arquivo entre raias da Ponte. |
| `subagent-driven-development` | executa um plano com um subagente novo por tarefa, revisão após cada uma, revisão ampla no fim. Casa com o método SDD do SpecKit. |
| `writing-plans` e `executing-plans` | disciplina de plano antes de execução |
| `verification-before-completion` | "implementado ≠ funciona" com outro nome. É a regra (j) da nossa constituição, já embalada. |
| `systematic-debugging` | método para o tipo de caçada que o V-26 exigiu |
| `test-driven-development` | o T021 nasceu sem o T020 justamente por falta disso |
| `requesting-code-review` e `receiving-code-review` | revisão como etapa, não como favor |

**Por que este primeiro:** três dos itens acima (`dispatching-parallel-agents`,
`using-git-worktrees`, `subagent-driven-development`) são exatamente a
engenharia que falta para o Arthur rodar várias tarefas simultâneas. Escrever
isso do zero custaria dias e ficaria pior.

Outros plugins do mesmo marketplace que valem avaliação:

- **`claude-session-driver`**: lança e monitora **outras sessões do Claude Code
  como trabalhadoras**, via tmux. É o degrau seguinte da paralelização, acima
  de subagentes. Avaliar depois do lançamento; em Windows o tmux é atrito.
- **`episodic-memory`**: busca semântica nas conversas passadas do Claude Code.
  Este projeto sofre de perda de contexto entre sessões, tanto que mantém
  `docs/historico/` escritos à mão. Candidato forte.
- **`double-shot-latte`**: elimina as interrupções de "quer que eu continue?".
  Relevante para execução longa e autônoma.

### `humanizer` · trailofbits/skills-curated

**492 ★ no marketplace, CC-BY-SA-4.0.** Remove marcas de escrita de IA de um
texto: símbolos inflados, travessão decorativo, os tiques conhecidos.

**É literalmente a ferramenta que o Arthur disse que ia criar** para corrigir o
vício do travessão. Instalar pelo marketplace, nunca copiar o texto dela para
cá, porque CC-BY-SA obriga compartilhar igual.

### `planning-with-files` · OthmanAdi/planning-with-files

**26.343 ★ · MIT · push em 22/08/2026.** Planejamento persistente em markdown,
com recuperação de sessão depois de `/clear` e de compactação, reinjeção por
turno contra perda de contexto, e portão determinístico de conclusão.

É a versão industrializada do que este repositório já faz à mão com os
handoffs. Vale medir contra o que temos antes de adotar: se cobrir o mesmo, os
handoffs manuais viram trabalho poupado.

---

## Camada 2: avaliar depois do lançamento

| Plugin | Números | Licença | Por que não agora |
|---|---|---|---|
| `ring` · LerianStudio | 208 ★ | Apache-2.0 | 89 skills e 38 agentes com ciclo de 10 portões. Bom, mas é uma metodologia inteira e nós já temos uma (SpecKit). Adotar as duas ao mesmo tempo é conflito garantido. |
| `context-engineering-kit` · NeoLabHQ | 1.362 ★ | **GPL-3.0** | Qualidade alta, licença copyleft. Só via marketplace, nunca copiado. |
| `trailofbits/skills` (completo) | 6.837 ★ | CC-BY-SA-4.0 | 40+ skills, mas a maioria é contrato inteligente e engenharia reversa. Aproveitável aqui: `differential-review`, `mutation-testing`, `code-improver`, `entry-point-analyzer`. |
| `alirezarezvani/claude-skills` | 24.923 ★ | MIT | 345 skills. Volume não é curadoria. Garimpar itens específicos, nunca instalar em bloco. |
| `anthropics/skills` | 171.422 ★ | sem licença declarada | Já disponível nesta sessão (`skill-creator`, `frontend-design`, `docx`, `pdf`, `xlsx`, `webapp-testing`). Nada a fazer. |

**Nota sobre `anthropics/skills`:** o repositório não declara licença. Usar as
skills como o produto oferece é uma coisa; redistribuir o texto delas dentro de
um repositório privado é outra, e sem licença declarada o padrão é "todos os
direitos reservados". Mais um motivo para não copiar nada.

---

## Camada 3: o que NÃO importar, e por quê

- **Qualquer marketplace de "345 skills" instalado em bloco.** Cada skill
  carregada consome atenção do modelo. O `docs/harness/README.md` deste projeto
  já tem a regra: *"acúmulo de regras dilui a atenção de todas elas"*. Vale
  igual para skills.
- **Metodologia concorrente completa** (`ring`, e o plugin GSD que já aparece
  nesta sessão). O projeto decidiu por **SpecKit** e a constituição registra o
  fluxo canônico. Duas metodologias ativas significam dois lugares dizendo
  coisas diferentes sobre o mesmo passo.
- **Skills de domínio alheio** (contrato inteligente, engenharia reversa de
  Android, corte de vídeo). Ruído.

---

## Como instalar

Os marketplaces já estão declarados em `.claude/settings.json`, no bloco
`extraKnownMarketplaces`, e os plugins escolhidos em `enabledPlugins`. Isso
deixa a escolha **versionada no repositório**, que era o pedido: qualquer sócio
que clonar o projeto recebe a mesma configuração.

**Ressalva honesta, conferida na pesquisa:** existe uma questão aberta no
repositório do Claude Code (issue #32606) relatando que `extraKnownMarketplaces`
e `enabledPlugins` declarados no projeto **nem sempre disparam a instalação
sozinhos**. Se ao abrir a sessão os plugins não aparecerem, o caminho é rodar
`/plugin` numa sessão interativa de terminal e confirmar a instalação uma vez.
Depois disso a configuração do repositório é que manda.

Comando equivalente, se preferir instalar pelo terminal:

```bash
claude plugin marketplace add obra/superpowers-marketplace
```

```bash
claude plugin install superpowers@superpowers-marketplace
```

---

## O que fica de tarefa

| # | O quê | Quando |
|---|---|---|
| IMP-1 | Instalar `superpowers` e confirmar que as skills aparecem | agora |
| IMP-2 | Instalar `humanizer` e rodá-la nos textos que vão para o grupo | agora |
| IMP-3 | Medir `planning-with-files` contra os nossos handoffs manuais | depois de 08/09 |
| IMP-4 | Decidir entre `episodic-memory` e continuar com handoff escrito | depois de 08/09 |
| IMP-5 | Resolver a coexistência SpecKit e GSD, que hoje estão ambos ativos | antes de escrever a SPEC 004 |
