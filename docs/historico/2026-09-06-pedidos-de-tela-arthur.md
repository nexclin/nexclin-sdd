# Os pedidos de tela do Arthur, 06/09/2026

Extraído do áudio dele de 06/09, com duas imagens de referência do INI (fluxo
de caixa e funil de vendas). O critério que ele repetiu quatro vezes: **ganhar
área útil sem virar poluição visual**, e não precisar rolar para ver o que
importa.

Cada item vira uma linha, com o estado real. Commits são de `nexclin/nexclin`.

## Feito

| # | Pedido, nas palavras dele | Onde | Commit |
|---|---|---|---|
| 1 | "onde você estende o financeiro e arrasta pra embaixo, você não removeu" | barra lateral | `060c73c` |
| 2 | "o número que está mais claro seja maior do que o número de centavos" | herói do dashboard | `060c73c` |
| 3 | "além do saldo do período, eu quero saber o saldo atual, como está naquele dia" | fluxo de caixa | `f68afb7` |
| 4 | "diminuir porque está muito grande o espaço branco dessas caixas" | fluxo de caixa | `f68afb7` |
| 5 | "o responsável tem que vir primeiro do que tipo" | tarefas | `0dad6af` |
| 6 | "o paciente não acho que precisa estar tão evidente" | tarefas | `0dad6af` |
| 7 | "o vencimento você ainda não colocou informação da contagem regressiva" | tarefas | `0dad6af` |
| 8 | "aquela tarefa piscando vai ser muito útil pra evidenciar" | tarefas | `0dad6af` |
| 9 | "não acho que tem que ter essa linha dividindo, ocupa muito espaço" | cabeçalho, todas as telas | `d8f0fff` |
| 10 | "deixar o de usuário sem estar posicionado dentro de um retângulo" | cabeçalho | `d8f0fff` |
| 11 | "a divisão de colunas deve ficar mais evidente, com destaque maior das caixas" | funil | `d8f0fff` |
| 12 | "o agendado ocupa muito espaço" | cartão do funil | `d8f0fff` |
| 13 | "na área de consultas eu também quero a foto, vem data, responsável" | consultas | `a96861a` |
| 14 | "o tamanho dos quadrados de informações, isso não está muito legal" | consultas | `a96861a` |
| 15 | "régua de cobrança tem um quadrado gigantesco, o layout está bem ruim" | cobrança | `d68d949` |

## Segunda rodada, depois de ele publicar e olhar

| # | O que ele viu | Commit |
|---|---|---|
| 16 | "você ainda não colocou o quadro piscando em alerta" | `b708283` |
| 17 | "em vez do tanto de horas restantes você somente informou hoje" | `b708283` |
| 18 | "do tipo eu não vejo como prioridade exibir dessa maneira" | `b708283` |
| 19 | "o modelo seria o funil, deixa os leads igual a ele" | `b708283` |
| 20 | "a linha pode ser mais fina, aparecendo mais por tela" (consultas) | `b708283` |
| 21 | "no profissional deve aparecer a foto também" | `b708283` |
| 22 | "somente dois aparecendo na tela inicial" (cobrança) | `b708283` |
| 23 | "podia ser um pouco maior a aba do faturamento" | `b708283` |
| 24 | "se o dado tiver realmente correspondente, queria que você verificasse" | `537016b` |

### O que a verificação do saldo atual encontrou

Ele pediu a conferência antes de validar, e ela achou **dois erros na versão
que eu mesmo tinha entregue** em `f68afb7`.

**O pendente vencido entrava como se tivesse entrado.** A conta reaproveitava
`dailyData`, e `dailyData` usa `dataDeCaixa`, que joga o pendente vencido no
dia de hoje. Essa é a regra certa para **projetar** e a regra errada para dizer
quanto há na conta **agora**. Numa clínica com inadimplência o número saía
alto, que é o pior erro possível para quem decide se paga o fornecedor.

**O saldo atual mudava com o mês escolhido.** Ele partia do saldo inicial do
período, então olhar julho e olhar setembro davam saldos atuais diferentes.

A conta nova é independente do período e só soma fato consumado: abertura de
toda conta ativa já aberta, mais recebível pago até hoje, menos despesa paga
até hoje.

**Um terceiro erro foi evitado antes de subir:** a consulta pedia `net_value` e
`gross_value` de `expenses`, e essas colunas não existem lá. Coluna inexistente
devolve 400 no PostgREST, não zero, e a tela quebraria.

### E um achado que fica aberto, porque muda número que ele já olha

`initialBalance`, que alimenta **Saldo do Período**, soma só a abertura das
contas e **ignora todo movimento anterior ao período**. O saldo do período só
está certo quando a abertura da conta coincide com o início do período. Em
qualquer outro mês ele está deslocado pelo acumulado que ficou de fora.
Corrigir exige uma consulta ao histórico anterior ao período, e a decisão é
dele porque muda um número que ele já usa.

## Aberto, e por quê

**A. RESOLVIDO em 06/09.** Ele decidiu: *"o modelo seria o funil, deixa os
leads igual a ele"*. Feito em `b708283`.

**B. Tipo de tarefa continua na lista.** Ele levantou a hipótese: *"se ainda é
necessário ter o tipo, porque quando você adequa um responsável você já sabe
que é daquele tipo"*. Não é verdade no dado: o mesmo responsável tem tarefa de
confirmação, de anamnese e de recall. Manter a coluna, e revisitar se ele
insistir depois de ver a tela com a nova ordem.

**B2. Profissional e responsável convivem em Consultas.** Ele disse *"tem ali o
profissional e responsável, eu tenho muita informação"*. São duas pessoas
diferentes, e quem atende não é sempre quem cuidou. Mantidas as duas, e a
decisão de fundir fica para ele.

**C. A janela de cobrança do INI.** Ele não achou a imagem. O que chegou foram
fluxo de caixa e funil de vendas, e as duas já foram usadas como modelo.

**D. Conferência dos números do dashboard contra dado real.** Ele mesmo disse
*"não verifiquei o número do dashboard pra ver se estão acompanhando"*. A
auditoria de código está em
[`2026-09-06-auditoria-numeros-dashboard.md`](2026-09-06-auditoria-numeros-dashboard.md);
o que falta é abrir a clínica e comparar tela a tela.

## O padrão que saiu daqui, e vale para a stack nova

Três formas resolveram quinze pedidos, e a stack nova nasce com elas em vez de
descobri-las de novo:

1. **Número não mora em cartão.** Rótulo e valor na mesma linha do filtro que
   os governa. Cartão com ícone em cima, número no meio e rótulo embaixo gasta
   três linhas para entregar duas palavras.
2. **Linha divisória só existe entre planos diferentes.** Se os dois lados têm
   o mesmo fundo, a linha não separa nada, só corta a tela.
3. **Selo não repete o container.** "Agendado" dentro da coluna Agendou, o
   rótulo do setor onde já está o nome da pessoa: é ruído com custo de linha.
