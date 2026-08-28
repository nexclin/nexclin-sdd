# 0005 · O `to-spec` é bifurcado em `nx-regra`

**Situação:** Aceita · **Data:** 27/08/2026 · **Decide:** Arthur Hideo
Reversível, e a reversão é barata: ver §Como reverter.

---

## Contexto

Com a saída do Spec Kit ([`0004`](./0004-o-spec-kit-sai.md)), o projeto precisava
de um caminho para escrever a regra antes da execução. A skill `to-spec`, do
conjunto do Matt Pocock incorporado sob MIT, faz exatamente isso: pega a conversa
corrente e sintetiza uma spec, sem entrevistar de novo.

Ela quase serve. Três coisas atrapalham, e nenhuma é ajustável por configuração:

1. **Ela exige *"A LONG, numbered list"* de user stories**, e diz que a lista
   *"should be extremely extensive"*. Esse é justamente o que a reorganização
   removeu do formato. O dado que sustenta a remoção: as três user stories da
   SPEC 005 custaram **80 linhas** e não aparecem em nenhum `plan.md`, em nenhum
   `tasks.md`, e em nenhuma mensagem de commit. Ninguém as leu depois de
   escritas.
2. **Ela publica em issue**, não escreve arquivo. Neste projeto a regra é
   artefato versionado que se corrige no mesmo commit da mudança de
   comportamento. Issue não se corrige junto com código.
3. **O template dela não tem seção de banco.** Aqui o que muda no banco é
   exatamente o que atravessa para outubro, e a §2.5 do `CLAUDE.md` decide o dia
   a dia por essa distinção. Diluir isso entre os requisitos foi o defeito do
   formato antigo.

## A decisão

**Bifurcar.** Nasce `.claude/skills/nx-regra/`, derivada do `to-spec`, com três
mudanças: as **sete seções** do formato de regra viva em lugar do template
original, **sem** user stories e **com** seção própria de banco e de decisão que
falta; e o destino passa a ser **arquivo em `docs/regras/NNN-nome.md`**, não
issue.

**O `to-spec` original sai** do repositório. Manter os dois lado a lado seria
duas skills que respondem ao mesmo pedido com formatos diferentes, e a escolha
entre elas cairia no acaso de qual a sessão lembrar primeiro.

**Conferido antes de decidir:** `to-tickets` e `implement`, as outras duas do
mesmo conjunto, **não colidem**. `to-tickets` quebra um documento em issues, que
é o passo seguinte, e `implement` executa uma issue. As duas ficam como estão.

## Consequências assumidas

- **`nx-regra` deixa de receber melhoria do upstream.** É o preço da bifurcação,
  e vale porque as três divergências acima são de conteúdo, não de forma: nenhuma
  atualização do `to-spec` as resolveria.
- **A cadeia canônica muda**, e a constituição foi emendada junto:
  `grill-with-docs` para interrogar a ideia, `nx-regra` para escrever a regra,
  `to-tickets` para abrir as issues, `implement` para executar por fases.
- **A proveniência precisa dizer isso.** `nx-regra` é obra derivada de código
  MIT, e `.claude/skills/PROVENIENCIA.md` registra a origem, a licença e o que
  foi mudado.

## Como reverter

O `to-spec` está no repositório do Matt Pocock e é reinstalável por
`/setup-matt-pocock-skills`. Reverter é reinstalá-lo e apagar `nx-regra`. As
regras já escritas em `docs/regras/` continuariam legíveis: elas são markdown com
cabeçalhos, e nenhuma ferramenta as lê por parser.
