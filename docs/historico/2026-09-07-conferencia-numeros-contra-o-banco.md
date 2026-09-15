# Conferencia dos numeros contra o banco, 07/09/2026

Fecha o item D dos pedidos de tela de 06/09: *"nao verifiquei o numero do
dashboard pra ver se estao acompanhando"*. Feita no app **publicado**, contra o
banco ao vivo, pelo editor de SQL.

## O controle positivo que evitou um alarme falso

A primeira conta deu diferenca de **R$ 30.262,40** e parecia erro de tela. Nao
era. A conta logada, `erpclinicas@gmail.com`, opera a clinica **NexClin**, e nao
a **Clinica Teste Final**, que e a do censo de 06/09. Rodar a mesma conta para
**todas** as clinicas mostrou as duas lado a lado:

| Clinica | Aberturas | Recebido antes | Pago antes | Saldo inicial |
|---|---|---|---|---|
| Clinica Teste Final | 25.000,00 | 301.137,90 | 180.880,00 | **145.257,90** |
| **NexClin** | 25.000,00 | 270.875,50 | 180.880,00 | **114.995,50** |

**Licao, e ela repete:** antes de chamar divergencia de erro, confira contra
qual clinica a tela esta olhando.

## O que passou

**Saldo do Periodo bate ate o centavo.**

| | |
|---|---|
| Tela | R$ 114.995,50 |
| Banco: 25.000,00 + 270.875,50 - 180.880,00 | **R$ 114.995,50** |

Isso valida em dado real a correcao do `initialBalance`
(`nexclin/nexclin@d10eeb6`). Antes dela o numero seria 25.000,00, so a abertura.

**A aritmetica da tela fecha.** Saldo atual mais entradas previstas da o saldo
do periodo: 114.995,50 + 39.584,30 = 154.579,80, que e o exibido.

**Saidas previstas R$ 0,00 esta certo.** Nao ha despesa paga em setembro nem
despesa pendente com vencimento ate 30/09. O zero e o dado, nao uma consulta
quebrada.

## O que NAO passou, e e achado novo

**Entradas previstas mostram R$ 39.584,30. Pela regra do proprio app, deveriam
mostrar R$ 201.569,20.**

A diferenca e **R$ 161.984,90**, e ela tem nome: sao **91 recebiveis pendentes
com vencimento ANTERIOR a setembro**.

A causa e a consulta, e nao a soma. O Fluxo de Caixa carrega recebiveis assim:

```
.or(due_date dentro do periodo, paid_at dentro do periodo)
```

Um recebivel que venceu em agosto e nao foi pago **nao tem** `due_date` nem
`paid_at` em setembro, entao **nunca chega a tela**. Enquanto isso, a regra
`dataDeCaixa` diz que pendente vencido vale para **hoje**, porque "o dinheiro
ainda vai entrar, e o mais cedo e agora". A regra existe, esta escrita, e nao
alcanca as linhas que deveria: elas foram filtradas antes.

**E a mesma classe do FIN-4**, ja corrigida para despesas, e o comentario dela
no codigo diz exatamente isto: *"o filtro antigo a deixava de fora da consulta,
nenhum ajuste de tela recuperaria uma linha que nem chegou"*.

### A conta que fecha a prova

| Medida | Valor |
|---|---|
| o que a tela exibe | 39.584,30 |
| o que a regra `dataDeCaixa` pede | 201.569,20 |
| diferenca | 161.984,90 |
| vencidos pendentes de antes de setembro, 91 linhas | **161.984,90** |

A diferenca e **identica** ao total dos vencidos. Nao sobra nem falta centavo.

### Por que isto importa para o fundador

O medico abre o Fluxo de Caixa e le que tem **R$ 39,5 mil** a entrar. O sistema
sabe que ha **R$ 201,5 mil**, e que R$ 162 mil disso ja venceu e ninguem pagou.
**A tela esconde a inadimplencia**, que e justamente o numero que uma clinica
precisa ver.

### A correcao, e por que ela nao foi aplicada aqui

Basta somar ao filtro os pendentes vencidos antes do periodo. E pequena.

**Nao foi aplicada porque quadruplica um numero na vespera do lancamento.** O
Arthur ja pediu para ser consultado antes de mudanca que altera numero que ele
acompanha, e esta muda de R$ 39,5 mil para R$ 201,5 mil. **A decisao e dele.**

Se entrar, o certo e entrar junto com um rotulo dizendo que a linha de hoje
inclui vencido, senao o salto vira duvida em vez de informacao.

## Estado

**Codigo lido e numeros conferidos, comportamento das correcoes de hoje ainda
nao provado na tela** para Insights e para a baixa em duas etapas. O que esta
provado contra dado real e o `initialBalance`, e ele passou.
