# Issue tracker: GitHub

As issues e specs deste repositório vivem como **issues do GitHub**, em
`nexclin/nexclin-sdd`, que é este mesmo repositório. Use o `gh` para tudo. Como
o clone aponta para lá, o `gh` infere o repositório sozinho e não é preciso
passar `--repo`.

## Convenções

- **Criar issue**: `gh issue create --title "..." --body "..."`. Use heredoc
  para corpo de várias linhas.
- **Ler issue**: `gh issue view <número> --comments`, filtrando comentários com
  `jq` e buscando também os rótulos.
- **Listar issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`,
  com os filtros `--label` e `--state` que couberem.
- **Comentar**: `gh issue comment <número> --body "..."`
- **Rótulos**: `gh issue edit <número> --add-label "..."` e `--remove-label "..."`
- **Fechar**: `gh issue close <número> --comment "..."`

## Pull request como superfície de pedido

**PR como superfície de pedido: não.** *(Mude para `sim` se este repositório
passar a tratar PR externo como pedido de funcionalidade. O `/triage` lê esta
flag, e a skill `triage` não está instalada aqui hoje.)*

Quando estiver em `sim`, o PR percorre os mesmos rótulos e estados da issue,
pelos equivalentes `gh pr`:

- **Ler PR**: `gh pr view <número> --comments`, e `gh pr diff <número>` para o
  diff.
- **Listar PR externo para triagem**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments`,
  guardando só `authorAssociation` igual a `CONTRIBUTOR`,
  `FIRST_TIME_CONTRIBUTOR` ou `NONE`, e descartando `OWNER`, `MEMBER` e
  `COLLABORATOR`.
- **Comentar, rotular, fechar**: `gh pr comment`, `gh pr edit --add-label` e
  `--remove-label`, `gh pr close`.

O GitHub compartilha um só espaço de numeração entre issue e PR, então um
`#42` solto pode ser qualquer um dos dois: resolva com `gh pr view 42` e caia
para `gh issue view 42`.

## Quando uma skill disser "publicar no issue tracker"

Crie uma issue do GitHub.

## Quando uma skill disser "buscar o ticket"

Rode `gh issue view <número> --comments`.

## Operações de wayfinding

Usadas pelo `/wayfinder`, que está instalado. O **mapa** é uma issue única, e os
tickets são issues **filhas** dela.

- **Mapa**: uma issue com o rótulo `wayfinder:map`, que guarda o corpo com
  Notas, Decisões até aqui e Névoa. `gh issue create --label wayfinder:map`.
- **Ticket filho**: issue ligada ao mapa como sub-issue do GitHub (`gh api` no
  endpoint de sub-issues). Onde sub-issue não estiver habilitada, acrescente o
  filho a uma lista de tarefas no corpo do mapa e ponha `Part of #<mapa>` no
  topo do corpo do filho. Rótulos: `wayfinder:<tipo>`, sendo o tipo `research`,
  `prototype`, `grilling` ou `task`. Depois de reivindicado, o ticket fica
  atribuído a quem está tocando.
- **Bloqueio**: use a **dependência nativa de issue** do GitHub, que é a
  representação canônica e visível na interface. Crie a aresta com
  `gh api --method POST repos/<owner>/<repo>/issues/<filho>/dependencies/blocked_by -F issue_id=<id-de-banco-do-bloqueador>`,
  em que o id é o **id numérico de banco** do bloqueador
  (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`), e não o `#número` nem o
  `node_id`. O GitHub reporta `issue_dependencies_summary.blocked_by`, contando
  só bloqueador aberto, que é o portão vivo. Onde dependência não estiver
  disponível, caia para uma linha `Blocked by: #<n>, #<n>` no topo do corpo do
  filho. O ticket destrava quando todo bloqueador estiver fechado.
- **Consulta da fronteira**: liste os filhos abertos do mapa
  (`gh issue list --state open`, limitado às sub-issues ou à lista de tarefas do
  mapa), descarte os que tiverem bloqueador aberto
  (`issue_dependencies_summary.blocked_by > 0`, ou issue aberta na linha
  `Blocked by`) ou responsável atribuído. Vence o primeiro na ordem do mapa.
- **Reivindicar**: `gh issue edit <n> --add-assignee @me`, a primeira escrita da
  sessão.
- **Resolver**: `gh issue comment <n> --body "<resposta>"`, depois
  `gh issue close <n>`, depois acrescente o ponteiro de contexto (gist e link)
  em Decisões até aqui, no mapa.
