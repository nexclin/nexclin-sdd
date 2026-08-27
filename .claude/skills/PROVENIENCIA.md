# Proveniência das skills desta pasta

> Atualizado em 25/08/2026. Quem adicionar skill de terceiro **atualiza esta
> tabela no mesmo commit**. Sem isso, em três meses ninguém sabe o que é nosso,
> o que é de fora, e sob qual licença.

## Nossas, escritas neste projeto

| Skill | O que faz |
|---|---|
| `nx-apontamento` | vira relato falado de sócio em registro do Notion |
| `nx-modulo` | porta um dos 15 módulos para a stack nova |
| `nx-ponte` | corrige bug na plataforma ao vivo sem consumir crédito |
| `nx-paralelo` | decide o que roda em paralelo e como isolar |

## Do Spec Kit

`speckit-*`, onze skills. Vieram com a instalação do GitHub Spec Kit
(`.specify/`), são o fluxo canônico do método SDD deste projeto, e a
constituição as referencia por nome.

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
- **Total:** 5 skills, de 22 disponiveis

| Skill | Por que esta |
|---|---|
| `grilling` | entrevista que testa uma decisao antes de ela virar codigo. Entra porque decisoes deste projeto se reverteram em horas: a D-1 foi revogada no mesmo dia pela D-7, e a prioridade inverteu em 26/08 |
| `to-questionnaire` | transforma decisao que nao e minha em questionario para outra pessoa. E literalmente o que `docs/planejamento/perguntas-vinicius-20-08.md` faz a mao |
| `writing-for-agents` | como escrever documento que agente consome. Conversa direto com `.claude/rules/escrita.md` e com a estrutura de harness inteira |
| `wait-what` | pedir que a ultima mensagem seja reformulada quando ela nao chegou |
| `codebase-design` | vocabulario de modulo profundo, para a reescrita em Next.js de outubro |

**O que foi DEIXADO DE FORA, e por que:**

- `to-spec`, `to-tickets`, `implement`, `wayfinder`, `triage`,
  `setup-matt-pocock-skills`: sao o processo ponta a ponta do autor, e ele
  **compete com o Spec Kit**, que a regra (h) da constituicao torna
  obrigatorio. O proprio README dele diz que existe como alternativa a
  "GSD, BMAD e Spec-Kit". Duas metodologias na mesma pasta e pior que uma.
  Alem disso, `triage` colidiria com `nx-apontamento`, que ja faz a triagem
  das baterias no formato do Notion.
- `tdd`, `code-review`, `diagnosing-bugs`, `handoff`,
  `resolving-merge-conflicts`: ja temos equivalente vindo do superpowers, e
  handoff ja e convencao em `docs/planejamento/handoffs/`.
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
