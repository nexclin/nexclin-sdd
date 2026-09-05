# Proveniência das skills desta pasta

> Atualizado em 27/08/2026. Quem adicionar skill de terceiro **atualiza esta
> tabela no mesmo commit**. Sem isso, em três meses ninguém sabe o que é nosso,
> o que é de fora, e sob qual licença.
>
> **Em 27/08 a pasta foi de 43 skills para 22.** As 22 que saíram foram
> **movidas** para `.claude/skills-fora/`, que o git ignora: elas continuam no
> disco e voltam movendo de volta. A razão é carga de contexto: cada descrição de
> skill é lida a todo turno, e 43 delas somavam 7.213 bytes por turno. Ver
> `docs/adr/0004-o-spec-kit-sai.md`.

## Nossas, escritas neste projeto

| Skill | O que faz |
|---|---|
| `nx-apontamento` | vira relato falado de sócio em registro do Notion |
| `nx-modulo` | porta um dos 15 módulos para a stack nova |
| `nx-ponte` | corrige bug na plataforma ao vivo sem consumir crédito |
| `nx-paralelo` | decide o que roda em paralelo e como isolar |
| `nx-regra` | escreve a regra viva em `docs/regras/`, nas sete seções. **Obra derivada do `to-spec` do Matt Pocock, sob MIT.** Ver abaixo |

## Do Spec Kit

**Saíram em 27/08 e quatro voltaram em 04/09.**

As onze `speckit-*` vieram com a instalação do GitHub Spec Kit e foram o fluxo
canônico do método SDD deste projeto até 27/08/2026, quando saíram junto com a
pasta `.specify/`. O motivo está em `docs/adr/0004-o-spec-kit-sai.md`.

Em 04/09/2026 o Spec Kit voltou pela metade, pela
`docs/adr/0006-o-spec-kit-volta-pela-metade.md`. **Quatro skills entraram**, e as
seis restantes ficaram de fora porque este projeto já tem substituto para cada
uma.

- **Origem:** `github.com/github/spec-kit`, via `pip install specify-cli`
- **Versão:** `specify-cli 1.0.4`, instalado com `--integration claude --script sh`
- **Data da instalação:** 04/09/2026
- **Licença:** MIT
- **Total:** 164 KB em `.specify/`, e 1.010 bytes de descrição de skill por turno

| Skill | Por que esta |
|---|---|
| `speckit-plan` | o degrau que faltava entre a regra e as issues, e ele pesa quando a frente é grande |
| `speckit-tasks` | lista de tarefas ordenada por dependência, a partir do plano |
| `speckit-analyze` | confere consistência entre regra, plano e tarefas. **Não tem equivalente aqui**, e ataca a classe de erro que já custou meio dia num arquivo órfão |
| `speckit-checklist` | checklist de qualidade sobre o plano, quando valer |

**As seis que ficaram de fora, e o que as substitui:** `speckit-specify` por
`nx-regra`, `speckit-clarify` por `grill-with-docs`, `speckit-constitution` por
`docs/constituicao.md`, `speckit-taskstoissues` por `to-tickets`,
`speckit-implement` por `implement`, e `speckit-converge` por nada, porque não
foi pedido.

**Estas quatro são cópia, não instalação viva.** Vale o mesmo custo assumido das
outras cópias: não recebem atualização sozinhas. A versão está registrada acima
para que a comparação com o upstream seja possível.

## De terceiros, incorporadas

### superpowers, de Jesse Vincent

- **Origem:** `github.com/obra/superpowers`
- **Commit:** `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`
- **Data da cópia:** 25/08/2026
- **Licença:** MIT, em [`LICENSE-superpowers`](LICENSE-superpowers)
- **Total:** 165 KB de markdown, 11 skills

| Skill | Por que esta |
|---|---|
| `dispatching-parallel-agents` | um agente por domínio independente, o motor das raias |
| `using-git-worktrees` | workspace isolado, com detecção do que já está isolado |
| `subagent-driven-development` | subagente novo por tarefa, revisão após cada uma |
| `writing-plans` e `executing-plans` | plano antes de execução, e disciplina de execução |
| `verification-before-completion` | "implementado ≠ funciona", que é a regra (j) daqui |
| `systematic-debugging` | método para caçada como a que o V-26 exigiu |
| `test-driven-development` | o T021 nasceu sem o T020 por falta disto |
| `requesting-code-review` e `receiving-code-review` | revisão como etapa |
| `finishing-a-development-branch` | fechamento de branch, complementa worktrees |

**Por que copiar em vez de instalar pelo marketplace:** a licença é MIT, que
permite, e copiar faz as skills funcionarem **em qualquer sessão, sem passo
manual**, inclusive nas não interativas. O aviso de copyright do autor viaja
junto, que é o que o MIT exige.

**O custo assumido:** cópia não recebe atualização. Se o upstream melhorar,
alguém precisa trazer. O commit está registrado acima justamente para que a
comparação seja possível.

## De terceiros, NÃO copiadas de propósito

| Origem | Licença | Por que fica de fora |
|---|---|---|
| `trailofbits/skills-curated` (`humanizer`) | CC-BY-SA-4.0 | share-alike. Instalada por marketplace, nunca copiada. |
| `NeoLabHQ/context-engineering-kit` | GPL-3.0 | copyleft |
| `anthropics/skills` | sem licença declarada | sem licença, o padrão é todos os direitos reservados |
| `Iniciativa-OpenClinic/OpenClinic` | AGPL-3.0 | copyleft de rede, contaminaria o SaaS inteiro |

## A regra, em duas linhas

**Licença permissiva (MIT, Apache, BSD): pode copiar, com o aviso de copyright
junto e o commit registrado aqui.**
**Licença copyleft (GPL, AGPL, CC-BY-SA): nunca copia. Referencia por
marketplace, ou reescreve do zero.**

### skills, de Matt Pocock

- **Origem:** `github.com/mattpocock/skills`
- **Commit:** `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76`
- **Data da copia:** 27/08/2026
- **Licenca:** MIT, em [`LICENSE-mattpocock-skills`](LICENSE-mattpocock-skills)
- **Total:** 27 skills. Em 27/08, `git-guardrails-claude-code` ficou de fora
  (ver abaixo); todas as outras entraram.

| Skill | Por que esta |
|---|---|
| `grilling` | entrevista que testa uma decisao antes de ela virar codigo. Entra porque decisoes deste projeto se reverteram em horas: a D-1 foi revogada no mesmo dia pela D-7, e a prioridade inverteu em 26/08 |
| `to-questionnaire` | transforma decisao que nao e minha em questionario para outra pessoa. E literalmente o que `docs/historico/2026-08-20-perguntas-vinicius.md` faz a mao |
| `writing-for-agents` | como escrever documento que agente consome. Conversa direto com `.claude/rules/escrita.md` e com a estrutura de harness inteira |
| `wait-what` | pedir que a ultima mensagem seja reformulada quando ela nao chegou |
| `codebase-design` | vocabulario de modulo profundo, para a reescrita em Next.js de outubro |

**A avaliacao acima virou de cabeca para baixo em 27/08, e a razao foi o Spec
Kit sair.** O que era "compete com o Spec Kit" virou "e o processo que ficou":
`to-tickets`, `implement`, `wayfinder` e `setup-matt-pocock-skills` **entraram**,
e com eles `code-review`, `diagnosing-bugs`, `handoff` e `ask-matt`. `triage`
continua fora, porque colide com `nx-apontamento`, que ja faz a triagem das
baterias no formato do Notion.

**`to-spec` foi BIFURCADO, nao adotado.** Ele exige *"A LONG, numbered list"* de
user stories, que o formato de sete secoes removeu, e publica em issue em vez de
escrever arquivo. Nasceu `nx-regra` a partir dele, e o original saiu. E obra
derivada de codigo MIT, e o aviso de copyright em
[`LICENSE-mattpocock-skills`](LICENSE-mattpocock-skills) cobre os dois. Motivo
completo em `docs/adr/0005-bifurcar-o-to-spec.md`.

**Nos pares sobrepostos, quem ficou:** superpowers no teste
(`test-driven-development`, que ja produziu os 90 testes), Pocock no bug
(`diagnosing-bugs`, com fases travadas). Na revisao ficaram **os dois**, porque
`code-review` revisa e `receiving-code-review` ensina a receber critica, que nao
e a mesma coisa. Saiu so `requesting-code-review`.
- `git-guardrails-claude-code`: **a ideia foi adotada, o arquivo nao.** Ele
  bloqueia `git push`, que e exatamente como este projeto entrega correcao ao
  cliente pela ponte inversa. Copiar a lista dele quebraria a entrega. O que
  se aproveitou foi a forma, e o conteudo virou a falha real daqui, em
  `.claude/hooks/guarda-ponte.mjs`.

**Instalado por copia, nao pelo plugin.** O README do autor oferece
`claude plugins install mattpocock-skills`, que atualiza sozinho. Ficou de
fora pela mesma razao ja registrada acima para o superpowers: copia funciona
em qualquer sessao, inclusive nao interativa, sem passo manual. O custo e o
mesmo: copia nao recebe atualizacao, e o commit acima existe para que a
comparacao com o upstream seja possivel.

---

## Adendo de 27/08/2026: a troca de metodo

Decisao do Arthur, tomada depois da avaliacao em
`docs/harness/sdd-ferramentas-e-avaliacao.md`. Eu havia recomendado manter o
Spec Kit; ele reafirmou a troca com uma razao diferente da que eu tinha
respondido: **orientacao bagunçada e consumo de token desotimizado**. Fica
registrado assim, com a discordancia visivel, para ninguem reabrir sem
contexto.

### O que saiu

| O que | Quantidade | Para onde foi |
|---|---:|---|
| Skills do Spec Kit (`speckit-*`) | 10 | apagadas do repositorio, no historico do git |
| Skills de terceiros tiradas de circulacao | 22 | `.claude/skills-fora/`, ignorado pelo git. Voltar e mover de volta |
| Skills do GSD | 67 | `~/.claude/desativado-27-08/skills/` |
| Agentes do GSD | 33 | `~/.claude/desativado-27-08/agents/` |
| Perfil do GSD | 1 | `~/.claude/desativado-27-08/.gsd-profile` |

**O GSD foi MOVIDO, nao apagado, e a razao importa:** ele estava instalado no
usuario (`~/.claude/`), nao neste projeto, entao valia para todos os
repositorios do Arthur. Desfazer e mover de volta.

### O que sobreviveu, e por que

**A constituicao.** Mudou de endereco em 27/08/2026: era `.specify/memory/
constitution.md`, agora e `docs/constituicao.md`, e a pasta `.specify/` foi
apagada junto com o Spec Kit. Ela
guarda os cinco principios (RLS, negacao por padrao, senha, segredo, testes
minimos), que **nao sao do Spec Kit**: sao as regras de seguranca do produto, e
`.claude/hooks/guarda-constituicao.mjs` ainda as le a cada escrita. Apagar o
metodo nao apaga as regras.

**As specs viraram regras vivas.** Em 27/08/2026 `specs/` foi convertido em
`docs/regras/`, um arquivo por regra, com o numero preservado. Cinco foram
reescritas no formato de sete secoes; tres foram movidas como estavam, com aviso
no topo; `plan.md` e `tasks.md` foram apagados, e o estado de execucao virou
issue no GitHub. A §2.5 do `CLAUDE.md` diz que o que atravessa para outubro e a
regra escrita: e ela que sobreviveu. Saiu a ferramenta, nao o que ela escreveu.

**A regra (h) da constituicao foi emendada no mesmo trabalho.** Ela exigia "spec
aprovada em `specs/`" e nomeava o fluxo do Spec Kit; hoje exige regra viva
aprovada em `docs/regras/` e nomeia a cadeia real. Constituicao em v2.0.1, e a
emenda e de endereco: os nove principios ficaram intactos.

### `git-guardrails-claude-code` continua fora

Unica excecao ao "importar tudo". Ela instala um hook que bloqueia envio ao
remoto, e envio ao remoto e exatamente como este projeto entrega correcao ao
cliente pela ponte inversa. Invoca-la quebraria a entrega. A ideia ja foi
aproveitada em `.claude/hooks/guarda-ponte.mjs`, com o conteudo trocado pela
falha real daqui.

### Tres sobreposicoes, e nao ha como remove-las sem escolher

Superpowers e Pocock cobrem o mesmo assunto em tres pares. Ambos os conjuntos
ficaram por decisao do Arthur, entao a escolha e de uso, nao de instalacao:

| Assunto | Superpowers | Pocock |
|---|---|---|
| Teste primeiro | `test-driven-development` | `tdd` |
| Cacar bug | `systematic-debugging` | `diagnosing-bugs` |
| Revisao | `requesting-` e `receiving-code-review` | `code-review` |

A sugestao de qual usar em cada par esta no guia visual.

### O guia

`docs/harness/guia-skills.html`, publicado tambem como artefato. Agrupa as 43
pelo momento do trabalho, com busca. **Ele fica velho quando uma skill entra ou
sai:** quem mexer em `.claude/skills/` regera o guia no mesmo commit, que e a
mesma regra desta tabela.

