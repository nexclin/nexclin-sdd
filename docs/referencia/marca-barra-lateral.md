# Barra lateral — o padrão de cartão flutuante

**Data:** 20/08/2026 · **Referência estudada:** INI (`ini.app.br`), software de
gestão que o Arthur usa. **O que foi copiado: o padrão de interação e a
geometria. Não a identidade visual** — cor, tipografia e ícones seguem
`marca-marca-tokens.md`.

## O que faz a barra parecer "leve"

Três coisas, e só juntas:

1. **Respiro de 8px em volta.** Ela não encosta em nada. É o que a transforma de
   *divisão de tela* em *objeto sobre a tela*.
2. **Canto de 24px.** Raio grande o bastante para ler como cartão; menor que
   isso lê como painel com quina arredondada.
3. **Sombra em duas camadas** — `0 25px 60px -12px rgba(0,0,0,.18)` para o
   "flutua" e `0 12px 24px -6px rgba(0,0,0,.10)` para ancorar a base. Uma
   camada só achata o efeito.

Some-se a **lavagem de luz do topo** (`rgba(255,255,255,.08)` até transparente
em 60%): é o que impede o fundo chapado de parecer plástico.

## O botão de recolher pousa NA borda

Metade dentro, metade fora (`right: -10px`), 20px de diâmetro, branco
translúcido com `backdrop-filter`. Opacidade 50% em repouso, 100% no hover.

Duas razões, e a segunda importa mais:
- ele só faz sentido cavalgando uma borda — e agora existe uma borda;
- **ele não muda de lugar** entre recolhido e expandido. A versão anterior o
  jogava para o rodapé ao recolher, obrigando a procurar o alvo de novo a cada
  clique.

## O que NÃO copiamos do INI, de propósito

- **A transição.** O INI usa `0.15s ease-out`. O NexClin já tinha
  `0.35s cubic-bezier(0.16, 1, 0.3, 1)` — uma curva com desaceleração longa,
  que lê como algo *assentando* em vez de *saltando*. É melhor; ficou.
- **Cor, tipografia e ícones.** Identidade é nossa.

## Medidas

| | Valor |
|---|---|
| Largura expandida | 220px (coluna do grid) |
| Largura recolhida | 80px |
| Respiro | 8px |
| Raio | 24px |
| Altura do item | 44px |
| Transição | `0.35s cubic-bezier(0.16, 1, 0.3, 1)` |

## Onde isso vale

**Faixa C na Lovable** — front puro, seria reescrito de qualquer forma. Foi
aplicado lá porque o custo era CSS e o ganho é percebido no primeiro segundo de
uso. **Mas o artefato durável é este documento**: é ele que a stack Next.js
consome, e é onde o padrão sobrevive à migração.
