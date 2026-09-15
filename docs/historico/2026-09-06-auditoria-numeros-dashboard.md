# Auditoria número a número do dashboard, 06/09/2026

**Pedido:** Arthur, 05/09: *"faça uma verificação se todos os dados do dashboard
estão correspondentes, a última análise do Vinícius tinha dito que não"*.

**Método:** para cada número exibido, li a consulta que o alimenta em
`src/pages/Dashboard.tsx` e comparei com a consulta da tela que é a fonte dele.
Sem acesso ao banco ao vivo, então **nenhum número foi conferido contra dado
real**: o que se prova aqui é se duas telas contam a mesma coisa, não se a conta
bate com a clínica. Isso continua aberto e depende do Arthur.

**Resultado:** dos quinze números, doze conferem, um estava errado, um listava
base diferente da que somava, e um é zero fixo. Além disso há uma divergência de
critério que não é erro, e é o que produz a sensação de "não bate".

---

## Funil, quatro cards

| Card | De onde sai | Lista ao clicar | Confere |
|---|---|---|---|
| Novos Leads | `leads` criados no período | os mesmos leads | sim |
| Agendamentos | consultas **marcadas** no período | as mesmas | sim |
| Consultas | `status = compareceu` entre as que **ocorrem** no período | as mesmas | sim |
| Fechamentos | compareceu com item aprovado que não é consulta | as mesmas | sim |

O contexto do card Agendamentos ("N novos no período") conta leads em
`funnel_stage = agendou`, que é base diferente da do card. É decisão registrada
de 30/08, e está comentada no código: o contador anterior exigia
`appointments.lead_id`, gravado por um único caminho, e por isso dava zero
permanente.

O denominador do comparecimento é o que **ocorre** no período, não o que foi
**marcado**. Consulta marcada hoje para o mês que vem ainda não teve chance de
acontecer, e derrubaria a taxa sem que nada tivesse dado errado.

## Dinheiro, oito números

| Número | De onde sai | Confere |
|---|---|---|
| Total Consultas | recebível pago no período, `macro_category = consulta`, valor bruto | sim |
| Total Vendas | idem, categoria diferente de consulta | sim |
| Total Consolidado | soma dos dois | sim |
| Faturamento Bruto, herói e painel | bruto dos recebíveis pagos no período | sim |
| Recebimentos efetivados | líquido dos mesmos recebíveis | sim |
| Despesas operacionais | despesa paga **no período** | **corrigido em 06/09** |
| Comissões e repasses | zero fixo | **não é número, é ausência** |
| Saldo do período | recebimentos menos despesas menos repasses | passa a fechar |

### Achado 1, erro de valor, corrigido

"Despesas operacionais" somava toda despesa com `status = pago` do conjunto
carregado. Esse conjunto traz **duas janelas de propósito**: vence no período ou
foi paga no período. Sem voltar a olhar a data, **despesa que vence em setembro
e foi paga em outubro entrava no setembro**.

Do outro lado do mesmo painel, "Recebimentos efetivados" já era estrito por
`paid_at`. As duas pernas do saldo com regras diferentes fazem o saldo não ser
de período nenhum.

Corrigido em `nexclin/nexclin@6c6a1f2`: as duas contam por data de pagamento
dentro do período. `paid_at` é `DATE` em `receivables` e em `expenses` (migração
`20260322140448`), então comparar `YYYY-MM-DD` é comparação de data e o último
dia do período entra. **Não há o erro clássico de perder o último dia**, que
aconteceria se a coluna fosse `timestamptz`.

### Achado 2, a lista não somava o cartão, corrigido

Clicar em "Despesas operacionais" abria a tabela de despesas inteira, com
pendente e com despesa paga fora do período, enquanto o cartão contava só as
pagas. Quem somasse a coluna não chegava ao número de cima. A lista passa a ser
a mesma base do cartão.

### Achado 3, não é erro, é falta de rótulo, e é o que produz "não bate"

**O painel conta por DATA DE PAGAMENTO. Contas a Receber e Contas a Pagar
filtram o período por VENCIMENTO.**

Recebível que vence em 30/08 e é pago em 02/09 entra no faturamento de setembro
e **não aparece** em Contas a Receber filtrada por setembro. Os dois números
estão certos, e são de coisas diferentes: regime de caixa no painel, carteira
por vencimento na tela.

Isso vinha sem rótulo nenhum, e o drill-down ainda convida o médico a abrir a
tela e conferir. Cada linha do painel passa a dizer por qual data ela conta.

**Para a stack nova:** todo número financeiro exibido **MUST** declarar sua base
ao lado, em uma de duas palavras, *pagamento* ou *vencimento*. Duas telas que
contam bases diferentes sem dizer qual é a origem número um de "o sistema está
errado" quando nenhuma das duas está.

### Achado 4, o zero fixo

"Comissões e repasses" é `0` escrito no código, com um `TODO`, porque não existe
tabela de repasses. Passa a exibir a nota dizendo isso. Enquanto for zero, o
saldo do período é receita menos despesa, e **superestima o que sobra em toda
clínica que paga percentual a profissional**.

Isso é requisito da stack nova, não bug da Lovable: a tabela nunca existiu.

## Tarefas, dois números

Pendentes e atrasadas saem de `tasks` com `status = pendente`, **sem recorte de
período**, ao contrário de todo o resto do dashboard. Está certo assim:
pendência é estado de agora, não fato do mês. Fica registrado porque parece
inconsistência e não é.

## Código morto encontrado no caminho

`balance`, `netRevenue`, `totalExpensesPaid` e `totalExpensesAll` eram
calculados e nunca exibidos. `balance` usava despesa **pendente**, ao contrário
do saldo que aparece na tela. Removidos, porque um segundo saldo com outra regra
dormindo no arquivo é armadilha para a próxima sessão.

## O que continua aberto

1. **Nenhum número foi conferido contra dado real.** Depende de o Arthur abrir a
   clínica de teste e comparar o painel com as telas, agora que os rótulos dizem
   a base de cada um.
2. **A divergência dos 252 contra 280** levantada em `docs/regras/021`, que é
   sobre `revenues` e `receivables` guardarem os mesmos campos, não foi tocada
   aqui.
3. **Comissões e repasses** exige tabela, e é da stack nova.
