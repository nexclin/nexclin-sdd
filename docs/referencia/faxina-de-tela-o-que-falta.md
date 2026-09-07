# Faxina de tela: o padrao, e o mapa do que falta

Atualizado em 07/09/2026. **Isto e referencia, e nao lista de tarefas:** o
estado de execucao vive nas issues. Aqui fica o padrao, para a proxima sessao
nao inventar um terceiro jeito, e a medida do que sobrou.

## O padrao, que saiu de quinze pedidos do Arthur

1. **Numero nao mora em cartao.** Rotulo em cima, em caixa baixa e 11px, numero
   embaixo em 18px. Sem icone. Cartao com icone em cima, numero no meio e
   rotulo embaixo gasta **tres linhas para entregar duas palavras**.
2. **Linha divisoria so existe entre planos diferentes.** Se os dois lados tem
   o mesmo fundo, a linha nao separa nada, so corta a tela.
3. **Selo nao repete o container.** "Agendado" dentro da coluna Agendou, o
   rotulo do setor onde ja esta o nome da pessoa: e ruido com custo de linha.

**Uma quarta regra nasceu na faxina de Consultas, em 07/09:** estado ativo
**MUST NOT** mudar o tamanho da caixa. O `ring-2` do cartao selecionado
engordava so ele e fazia a fila inteira dancar a cada troca de filtro. Ativo se
mostra por **cor de borda e fundo**, que nao ocupam espaco.

## Onde o padrao ja esta escrito em codigo

| Tela | Componente | Commit |
|---|---|---|
| Fluxo de Caixa | `FcTotal`, local | `nexclin/nexclin@6c6a1f2` e seguintes |
| Consultas | `CsValor`, local | `nexclin/nexclin@7e98c98` |

**Os dois sao locais de proposito.** Sao duas telas, e a terceira e que decide
se ha padrao ou coincidencia. Quando a terceira chegar, ai vale um componente
compartilhado, e nao antes.

## O que falta, medido e nao estimado

Contagem de numero grande dentro de cartao, por tela, em 07/09:

| Tela | Ocorrencias | Vale a pena? |
|---|---|---|
| `Precificacao.tsx` | 10 | **e a maior sobra que restou** |
| `Salas.tsx` | 3 | secundaria |
| `Insumos.tsx` | 2 | secundaria |
| `Informativos.tsx` | 2 | secundaria |
| `Funil2.tsx` | 1 | quase nada |
| `Recall.tsx` | 1 | quase nada |
| `AnamnesePublica.tsx` | 2 | **nao mexer**: e a tela que o paciente ve |

`Signup`, `ResetPassword` e `ForgotPassword` tem um cada, e sao telas de acesso,
fora do fluxo diario. Nao entram.

## O que isto e, pela §2.5

**Faixa C.** Front da Lovable sera reescrito, e nenhuma destas mudancas
atravessa como codigo. O que atravessa e o padrao das quatro regras acima, e e
por isso que ele esta escrito aqui em vez de so aplicado.

Entao a ordem de prioridade e clara: **faxina so depois que financeiro,
relatorio e banco estiverem resolvidos.** Ela nao concorre com nada da faixa A.
