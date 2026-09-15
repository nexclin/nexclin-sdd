# O que foi instalado em 11/09/2026, e como usar na fase final

> Instalação feita em **11/09/2026**, a partir dos repositórios listados no
> último slide da aula de SDD (`aula-sdd-engenharia-de-software-2026.html`).
> Tudo foi para **`~/.claude/skills`**, no Claude do Arthur, e **nada entrou
> neste repositório**: é a regra de 25/08, e continua valendo.

---

## O que entrou, e onde

| Pacote | Como foi instalado | Onde vive |
|---|---|---|
| Skills do Matt Pocock, 36 | cópia das pastas `engineering`, `productivity` e `misc` | `~/.claude/skills/` |
| caveman, 24 skills | cópia da pasta `skills/` | `~/.claude/skills/` |
| gsap-skills, 8 skills oficiais da GreenSock | cópia da pasta `skills/` | `~/.claude/skills/` |
| ui-ux-pro-max, 7 skills | cópia de `.claude/skills/`, com os scripts e o banco CSV | `~/.claude/skills/` |
| img2threejs, 1 skill | cópia do repositório inteiro, como o README manda | `~/.claude/skills/img2threejs/` |
| codegraph 1.6.0 | `npm i -g`, depois `codegraph install --target claude,codex --location global` | servidor MCP em `~/.claude.json`, telemetria **desligada** |

**Sessenta e cinco skills** ao todo. O menu do Claude Code as listou no mesmo
turno, sem reiniciar, o que prova que a pasta é lida.

**Por que cópia de pasta, e não `claude plugin`:** o `claude` de linha de
comando não está nesta máquina. O Arthur usa o app de desktop, que lê
`~/.claude/skills` diretamente. É o caminho que funciona sem instalar mais
nada.

## O que NÃO entrou, e por quê

| Item | Motivo |
|---|---|
| **claude-mem** | Captura tudo que o agente faz e grava. Este projeto lida com dado de saúde. **Decisão do Arthur pendente**, ver a pergunta no fim |
| **headroom** | `pip install "headroom-ai[all]"` puxou **14 GB** de dependências e encheu o disco antes de terminar. Fica para instalar com o extra `[proxy]`, que é o que se usa, depois de o disco ter espaço |
| Pocock, pasta `in-progress`, 9 skills | O próprio autor as marca como inacabadas. Skill inacabada no menu é erro esperando acontecer |
| find-skills | É site, não repositório. Usa-se pelo navegador |
| SpecKit | Já está aqui: `.specify/` e as skills `speckit-*` em `.claude/skills/` |
| AdoptPlace | É o exemplo da aula, não uma ferramenta |
| `caveman/skills/generated` | Saída de build para outros agentes. Entrou na cópia e foi removida |

## Como cada uma entra na fase final do NexClin

A fase final é: **stack Next.js substituindo a Lovable em outubro**, sem bug e
sem backlog. O passo a passo é o do slide "Oito passos, uma skill em cada", e
aqui está ele com o que já existe neste repositório:

| # | Passo | Aqui | Skill |
|---|---|---|---|
| 1 | Constituição | já existe, `docs/constituicao.md` | não mexer sem emenda |
| 2 | Interrogar a ideia | antes de toda regra nova | `grilling` ou `grill-me`, agora instaladas. O `grill-with-docs` do projeto volta a funcionar, porque a `grilling` de que ele depende passou a existir |
| 3 | Regra viva | `nx-regra`, em `docs/regras/` | `nx-regra`, depois `speckit-clarify` |
| 4 | Plano e tarefas | `docs/planos/` | `speckit-plan`, `speckit-tasks` |
| 5 | Issues | `nexclin/nexclin-sdd` | `speckit-taskstoissues` |
| 6 | Implementar com TDD | `nx-modulo`, um módulo por vez | `tdd` do Pocock, ou `test-driven-development` do projeto. **Teste vermelho antes, sempre** |
| 7 | Verificar e commitar | `npx tsc --noEmit -p tsconfig.app.json`, nunca o config puro | `verification-before-completion`, `verify-and-stop` |
| 8 | PR e deploy | Vercel | `handoff` ao fim de toda sessão |

**Onde as novas ajudam de verdade, e onde não:**

- **caveman**: liga em sessão longa de correção, em que se lê dezenas de
  respostas. **Não** use para escrever regra, handoff nem commit: a
  `.claude/rules/escrita.md` é a voz do projeto, e caveman a contradiz.
- **codegraph**: rode `codegraph init` **uma vez** na raiz de cada
  repositório, este e o `../nexclin-lovable`. Depois disso o agente acha
  função e chamador sem varrer o repositório. Só vale a pena a partir de
  algumas centenas de arquivos, e os dois passam disso.
- **ui-ux-pro-max**: antes de desenhar qualquer tela da stack nova, rode o
  `--design-system` com o tipo de produto. Agora o script está instalado, o
  que não acontecia em 09/09.
- **gsap**: só quando a animação tem significado. A regra da faxina de tela
  continua: pixel que não informa, sai.
- **img2threejs**: não tem uso previsto aqui. Está instalado porque veio no
  pacote da aula.
- **Pocock, `wizard`**: para o que só o Arthur pode fazer, como provisionar
  credencial ou clicar no Publish. Gera o roteiro em bash, com pausas.

## O que falta para fechar

1. **Decidir o claude-mem.** Se entrar, ele grava o que o agente vê, e o
   agente vê dado de clínica. A alternativa que já existe é o handoff datado,
   que é decisão humana do que fica. Recomendação: **não instalar** enquanto
   houver dado real no banco que o agente alcança.
2. **Instalar o headroom com `[proxy]`**, depois de liberar disco. Antes,
   conferir com `pip download --no-deps` o tamanho, para não repetir os 14 GB.
3. **Rodar `codegraph init`** nos dois repositórios, e conferir com
   `codegraph status`.
4. **Reiniciar o Claude Code** para o servidor MCP do codegraph subir. As
   skills não precisam, o MCP precisa.
