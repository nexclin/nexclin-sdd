# Handoff: a reorganização de estrutura, specs e método

> **Para a sessão que vai executar.** Este documento é a única coisa que você
> precisa ler para começar. Ele carrega as 32 decisões tomadas numa sessão de
> `grill-with-docs` em 27/08/2026, na ordem em que foram tomadas, com a razão
> de cada uma.
>
> **Nada aqui foi executado ainda.** O passo 0 está feito (o PR #35 foi
> mesclado em `26635e3`); o passo 1 em diante é o trabalho.

---

## Como usar este documento

**Não reabra as decisões.** Elas foram tomadas com os números na mesa, e cada
uma tem a razão escrita ao lado. Se uma delas estiver errada, a correção é
dizer qual e por quê, não refazer a entrevista.

**Não comece pelo meio.** A ordem dos passos existe porque cada um quebra links
que o seguinte conserta. Executar fora de ordem deixa o repositório num estado
em que ninguém sabe o que está quebrado de propósito.

Leia também, nesta ordem, e só depois de terminar aqui:

| Arquivo | Para quê |
|---|---|
| `docs/harness/sdd-ferramentas-e-avaliacao.md` | por que o Spec Kit saiu, com os números |
| `.claude/skills/PROVENIENCIA.md` | o que entrou, o que saiu, e sob qual licença |
| `2026-08-27-pendencias.md` | o trabalho de produto que continua correndo em paralelo |

---

## O que mudou, em um parágrafo

O repositório para de ser organizado por assunto e passa a ser organizado por
**pergunta que o documento responde**, em sete pastas. O Spec Kit sai inteiro,
inclusive da constituição. As specs viram **regras vivas** em `docs/regras/`.
O alvo declarado é **carga de contexto por turno**, e a maior parte da economia
vem de cortar o `CLAUDE.md` pela metade e as skills de 43 para 20.

**Nenhum código é tocado.** `app/`, `lib/`, `e2e/` e `supabase/` ficam intactos.

---

## O termo que nasceu, e vale a primeira linha do `CONTEXT.md`

**Regra viva.** Documento que nasce antes da execução, guia a execução, e é
corrigido no mesmo commit em que a execução o contradiz. Oposto de spec que
envelhece calada.

A SPEC 006 já era isso e ninguém tinha dado nome: ela foi escrita depois da
implementação, tem dez requisitos numerados, e virou onze commits e seis
migrações. A SPEC 005 foi escrita antes e guiou a execução. As duas
funcionaram, e a diferença entre elas é o que este documento resolve.

---

## As 32 decisões

### Alvo e escopo

| # | Decisão | Razão |
|---|---|---|
| 1 | O alvo é **carga de contexto**, não navegação nem confiabilidade | O `CLAUDE.md` tem 25.392 bytes e é lido a todo turno. As 43 descrições de skill somam 7.213. Custo fixo de ~32.600 bytes, ~8.200 tokens por turno |
| 20 | Só `docs/` e `specs/`. **Código não se toca** | `app/` e `lib/` estão congelados desde 26/08 e não dá para verificar que não quebraram até outubro. `supabase/migrations` tem ordem cronológica que é contrato com o banco |

### As specs

| # | Decisão | Razão |
|---|---|---|
| 2, 5 | `specs/` converte. `plan.md` e `tasks.md` **apagados**; os 8 `spec.md` viram `docs/regras/` | O `tasks.md` é estado de execução e vira ticket sem perda. O `spec.md` é a regra escrita, e a §2.5 diz que é ela que atravessa para outubro |
| 25 | Um arquivo por regra, **número preservado**: `docs/regras/005-configuracoes-clinica.md` | "SPEC 006" e "T017" são referência viva em handoffs e commits de agosto. Regra nova continua em 017 |
| 27 | **Reescrever 5** (001, 002, 004, 005, 006) no formato novo. **Mover 3** (003, 013, 016) como estão, com aviso no topo | A 013 está bloqueada por decisão comercial e a 016 nunca começou. Reescrever 800 linhas que ninguém vai reler não paga |
| 31 | `specs/BACKLOG.md` vira `docs/regras/000-backlog.md` | Não é regra (nada decidido) nem histórico (não aconteceu). É a fila de onde as próximas saem |

### O formato da regra

| # | Decisão | Razão |
|---|---|---|
| 22 | A regra é **viva**: nasce antes, é corrigida depois | Regra que só existe antes mente assim que a implementação diverge. Regra que só existe depois não guia nada |
| 23 | Leitores: **você e eu**. Sócio não lê spec | Vinícius e Erick leram relatório e mensagem de grupo esta semana, nunca uma spec. Escrever para três públicos não serve a nenhum |
| 24 | **Sete seções**, e user stories saem | As três user stories da SPEC 005 custaram 80 linhas e não aparecem em `plan.md`, `tasks.md` nem em nenhum commit |
| 28 | Decisão **fechada** vira ADR; a regra lista só o que **falta** decidir | Fronteira aplicável sem pensar, e "sem pensar" é o que faz convenção sobreviver |
| 29 | Regra nova só para o que **atravessa para outubro**: banco, RLS, regra de negócio. Front puro não gera regra | É o critério da §2.5, já testado. Explica o dia 27/08 corretamente: `semear_clinica` merecia regra, a barra lateral não |
| 26 | Mudança que altera comportamento descrito numa regra **atualiza a regra no mesmo commit** | Mesma forma que já funciona no `PROVENIENCIA.md`, e que pegou em 27/08 sem hook nenhum |

**As sete seções, na ordem:**

1. O problema, em um parágrafo
2. Requisitos numerados (`FR-001`), **cada um com o porquê**
3. O que muda no banco
4. Premissas
5. Dependências
6. Como se prova que funciona
7. A decisão que falta, e precisa do Arthur

A seção 3 é própria porque é o que atravessa para outubro, e hoje fica diluída
no meio dos requisitos. A seção 7 foi o que impediu a SPEC 005 de travar.

### A árvore

| # | Decisão | Razão |
|---|---|---|
| 10 | **Sete pastas**, uma pergunta cada: `regras/` `historico/` `adr/` `dominio/` `ponte/` `harness/` `referencia/` | `orquestracao`, `arquitetura` e `compartilhavel` têm 1 arquivo cada; `planejamento` tem 32. Elas existem por assunto, não por uso, e é isso que faz escolher errado onde escrever |
| 3 | `../adr/` → `docs/adr/`, e nasce `CONTEXT.md` | É o caminho que as skills novas esperam. Ensinar as duas coisas, o caminho e a skill |
| 12 | Data **`AAAA-MM-DD` no início** do nome | Único formato que ordena sozinho, e `historico/` depende disso. Os handoffs já usam |
| 14 | Constituição vai para `docs/constituicao.md`. **`.specify/` some** (16 MB) | Só `memory/constitution.md` tem uso. Manter a pasta deixa no repositório o nome de um método que não é mais nosso |
| 32 | **Emendar a constituição no mesmo trabalho**: linha 131 e linhas 260-261 | Emenda de endereço, não de princípio. Os cinco princípios ficam intactos. Lei apontando para pasta inexistente corrói as outras linhas |
| 8 | Raiz: **apagar** os 2 HTMLs e o `CLAUDE nexclin.md`; mover o resto | O `CLAUDE nexclin.md` é cópia de 29/07. Os HTMLs já foram absorvidos por `docs/planejamento/` |
| 4 | **`strix/` fica onde está** | Já está no `.gitignore` linha 40, e excluído do `tsconfig` e do `vitest`. Custa disco, não atrito. Mover custaria mais que ganha |

### O `CLAUDE.md`

| # | Decisão | Razão |
|---|---|---|
| 6 | Corte **agressivo, alvo 8 KB**. Histórico vira ponteiro para `docs/historico/` | Economiza ~4.300 tokens por turno. O teste de cada parágrafo é objetivo: *se eu apagar isto, tomo alguma decisão diferente?* |
| 18 | A **§6 sai inteira** e vira uma linha apontando para o handoff mais recente | Ela duplica `pendencias-27-08.md` e ficou errada duas vezes só em 27/08. Estado duplicado não fica desatualizado às vezes, fica sempre |

**Fica no `CLAUDE.md`:** o que é o produto, as regras inegociáveis, o prazo de
08/09, e a §2.5 inteira, porque ela decide comportamento todo dia.

### As skills

| # | Decisão | Razão |
|---|---|---|
| 7, 11, 13 | **43 → 20.** As 23 vão para `.claude/skills-fora/`, ignorado pelo git | 168 bytes por descrição, a todo turno. Voltar é mover de volta |
| 30 | **Bifurcar o `to-spec`** em `.claude/skills/nx-regra/`, com as sete seções e destino em `docs/regras/`. O `to-spec` original sai | Ele exige *"A LONG, numbered list"* de user stories, que a decisão 24 removeu, e publica em issue em vez de escrever arquivo. **Conferido: `to-tickets` e `implement` não colidem** e ficam como estão |
| 17 | Uma **rule**, `.claude/rules/estrutura.md`, não um hook | Hook recusaria pasta nova legítima e eu passaria a contorná-lo. Se em duas semanas a bagunça voltar, aí o hook nasce com falha real atrás |

**As 20 que ficam:** `grill-with-docs` · `nx-regra` · `to-tickets` · `implement`
· `code-review` · `receiving-code-review` · `verification-before-completion` ·
`diagnosing-bugs` · `test-driven-development` · `ask-matt` · `domain-modeling` ·
`handoff` · `research` · `to-questionnaire` · `wayfinder` · `codebase-design` ·
`writing-for-agents` · `nx-apontamento` · `nx-ponte` · `nx-modulo` ·
`nx-paralelo` · `setup-matt-pocock-skills`.

**Nos pares sobrepostos:** superpowers no teste (já produziu os 90 testes),
Pocock no bug (fases travadas), e na revisão ficam os dois, porque
`code-review` revisa e `receiving-code-review` ensina a receber crítica, que
não é a mesma coisa. Sai só `requesting-code-review`.

### Os tickets

| # | Decisão | Razão |
|---|---|---|
| 9 | **GitHub issues**, revivendo o que existe. Fechar as 28 obsoletas | Existem 28 issues abertas desde 03/08, criadas da SPEC 001, e o `tasks.md` diz que 24 daquelas tarefas estão feitas. O `../harness/workflow-github.md` já descreve o mapeamento |
| 19 | Só **15 issues** nascem agora: as 12 da SPEC 002 e as 3 da 001. As outras 19 ficam como texto na regra | Issue que ninguém toca em duas semanas envelhece igual às 28 que estamos fechando, e aí ninguém olha mais nenhuma. As 16 da bateria do Vinícius dependem do reteste dele |

### O `CONTEXT.md`

| # | Decisão | Razão |
|---|---|---|
| 16 | **Teto de 60 linhas**, só termo que já causou confusão real | Mesmo princípio da catraca do harness. Termo que nunca foi mal-entendido custa token e não evita nada |
| 21 | Otimiza para **execução sem ambiguidade**, com a legibilidade do Arthur como restrição de forma | O sintoma relatado foi "corrigindo etapa por etapa": documento que não fecha decisão faz voltar a perguntar, e cada volta é um turno |

**Os termos que entram:** âncora · recebível · repasse · faixa A/B/C · ponte ·
esqueleto da clínica · atravessar · ModuleKey · impersonação · apontamento ·
**regra viva**. Cada um com uma linha e um exemplo de uso errado.

---

## A ordem de execução

O passo 0 está feito. Não pule, não reordene.

| # | Passo | O que quebra, e é esperado |
|---|---|---|
| ~~0~~ | ~~Mesclar o PR #35~~ | **feito em `26635e3`** |
| 1 | Criar as 4 pastas novas. Constituição para `docs/constituicao.md`, `.specify/` apagado, emenda das linhas 131 e 260-261 | 5 referências ao caminho antigo: o hook `guarda-constituicao.mjs`, `rules/banco.md`, `rules/escrita.md` (o `paths:` inclui `.specify/**`), `PROVENIENCIA.md` e `docs/harness/README.md` |
| 2 | `specs/` vira `docs/regras/`. 5 reescritas, 3 movidas com aviso, `plan.md` e `tasks.md` apagados, `BACKLOG` vira `000-backlog.md`, `specs/` some | Todo link para `specs/`. **Commits de agosto passam a apontar para caminhos mortos, e isso não tem conserto.** Custo aceito |
| 3 | Fechar as obsoletas das 28 issues, abrir as 15 | nada |
| 4 | `docs/` de 10 pastas para 7. Datas renomeadas. `docs/README.md` reescrito | Links entre documentos, muitos. Consertar todos no mesmo commit |
| 5 | Raiz limpa: apagar 2 HTMLs e o duplicado, mover `INVENTARIO*` e `../referencia/brand-book.html` e `RELATORIO-SEMANAL` e `WORKFLOW-GITHUB` | Links para a raiz |
| 6 | `CLAUDE.md` de 25 KB para ~8 KB | **Sessão nova para de receber o histórico automaticamente.** Mitigar com uma linha nomeando `docs/historico/` e quando abrir |
| 7 | Skills de 43 para 20. `to-spec` vira `nx-regra`. Guia HTML regerado | `nx-regra` deixa de receber melhoria do upstream |
| 8 | `.claude/rules/estrutura.md` | nada |
| 9 | `CONTEXT.md`, 60 linhas | Sobe a carga fixa em ~1,5 KB, deliberadamente |
| 10 | Conferir todo link interno, rodar o hook, confirmar `tsc` e testes intactos | |

**Resultado esperado:** custo fixo por turno de ~32.600 bytes para ~14.000.
Perto de 4.600 tokens economizados a cada turno.

---

## Três avisos que o Arthur pediu para ficarem escritos

**O passo 2 não tem volta.** `plan.md` e `tasks.md` de cinco specs somem. O
conteúdo fica no histórico do git mas deixa de ser navegável, e 19 das 34
tarefas abertas passam a existir só como parágrafo dentro da regra, não como
item marcável.

**O passo 6 tira a rede de segurança da sessão nova.** A §6 do `CLAUDE.md` é
onde toda sessão lê "o que fazer agora". Passa a estar no handoff. **Se um dia
o handoff não for escrito, a sessão seguinte começa mais cega do que hoje.**

**Isto não se fatia.** São quatro a cinco horas, e durante elas o repositório
fica com links quebrados antes de serem consertados. Não intercale com trabalho
de produto.

---

## Dois ADRs a escrever, e já aprovados

Ambos passam nos três testes: caros de reverter, surpreendentes sem contexto, e
resultado de alternativa real recusada com razão declarada.

- **`0003-o-spec-kit-sai.md`**: registra que a recomendação foi **manter** o
  Spec Kit, com o dado de 72 tarefas concluídas por ele, e que a decisão
  contrária foi do Arthur por bagunça e custo de token. A discordância fica
  visível de propósito.
- **`0004-bifurcar-o-to-spec.md`**: com o dado das user stories da SPEC 005 que
  custaram 80 linhas e não entraram em nenhum commit.

---

## O que continua correndo em paralelo, e não é desta reorganização

Pendências de produto, em `2026-08-27-pendencias.md`. As que estão
com o Arthur:

- **Publicar na Lovable** o commit `0feb8b0` (tour não paira sobre o formulário,
  retorno vai para o topo) e rodar a migração `20260827020000` antes.
- **Criar `teste@nexclin.com`** pelo cadastro. A conta vai **limpa** para o
  amigo cuja família tem distribuidora, para avaliar a interface. **Não povoar.**
- Trocar a senha da conta-mestra. Domínio, que destrava o SMTP.
- Transcrever o segundo vídeo do Erick. **Se houver bateria de bugs lá, ela tem
  precedência sobre tudo**, inclusive sobre esta reorganização.

A decisão pendente mais antiga: **conta mestra definindo usuários da clínica.**
O Arthur quer que a mestra crie e repasse as credenciais; isso é a regra (e) da
constituição. A alternativa que entrega o mesmo fluxo sem a emenda é senha
temporária gerada pelo sistema com troca obrigatória no primeiro acesso. **Ele
ainda não escolheu entre as duas, e a spec espera essa escolha.**
