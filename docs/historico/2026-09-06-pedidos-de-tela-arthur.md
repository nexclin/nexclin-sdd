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

## Aberto, e por quê

**A. A aba Leads igual ao funil.** Ele disse *"o funil é pra estar exatamente
igual os leads"* logo depois de dizer que a busca do funil ficou ótima e que a
de leads ficou pior. As duas leituras são opostas, e escolher errado desfaz
trabalho que ele aprovou. **Precisa de uma frase dele**, não de um palpite.

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
