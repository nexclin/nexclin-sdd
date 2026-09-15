# Tokens de marca

Fonte: `brand-book.html` — NexClin Brand Concept v1.0. Este arquivo é a tradução
do brand book para o código; em divergência, o brand book manda.

## Posicionamento, em uma frase

> O nexus operacional da clínica moderna.

Healthtech / ERP · B2B premium · estética "tech + cuidado". A marca não tenta
parecer médica — tenta parecer **empresa de tecnologia para gestão clínica**.
Mais sistêmica que hospitalar.

## Cor

```css
:root {
  --nx-teal:  #1F8C8C;  /* acento único — cuidado, inovação, tecnologia */
  --nx-navy:  #141C28;  /* fundos escuros */
  --nx-slate: #3A4A5C;  /* texto e estrutura institucional */
  --nx-bone:  #F4F1EC;  /* fundo claro preferencial */
  --nx-ink:   #0E1620;  /* tipografia */
}
```

Apoio observados no brand book: `#2BA8A8` e `#186F6F` (variações do teal),
`#FAF8F4` (paper), `#E5E0D8` (borda sobre bone), `#6B7A8C` (texto secundário),
`#1E2A3A` (superfície sobre navy).

Três princípios que não se negociam:

1. **Verde-água é o único acento cromático do sistema.** Usado com moderação
   para manter impacto. Um segundo acento descaracteriza.
2. **Navy e slate substituem o preto puro** — evitam agressividade visual.
3. **Bone e paper são os fundos preferenciais** — mais quentes que branco,
   dão caráter editorial.

## Tipografia

| Papel | Família | Pesos |
|---|---|---|
| Display — títulos e marca | **Outfit** (geometric sans, variable) | 200 · 400 · 600 · 800 |
| Corpo — texto e interface | **Manrope** (modern grotesque, variable) | 300 · 400 · 500 · 700 |

Rótulos de seção em caixa alta com espaçamento largo (`letter-spacing`), como
no app publicado: `OPERAÇÃO / DASHBOARD`, `01 / FINANCEIRO`.

## Dois temas

| | App da clínica | Painel superadmin |
|---|---|---|
| Fundo | `--nx-bone` | `--nx-navy` |
| Sidebar | `--nx-navy` | navy mais escuro |
| Acento | teal | azul + badges semânticas |
| Densidade | respirada, editorial | compacta, operacional |

A distinção é intencional: o operador precisa saber num relance em qual dos
dois mundos está. Não unifique os temas "por consistência".

## Orçamento de tela

> Acrescentado em 05/09/2026. Origem: a reunião de 03/09, em 00:14:08, mais o
> pedido do Arthur em 05/09. O termo **área inútil** está no `CONTEXT.md`.
>
> **Isto é token, e não regra viva, de propósito.** Aproveitamento de tela é
> front puro, e pela §2.5 front puro não gera regra: vira requisito da stack
> nova. Um teto de pixels, ao contrário de "menos poluído", é verificável, e é
> por isso que ele cabe aqui.

```css
:root {
  --nx-topo-max:      180px;  /* topo até a primeira linha de conteúdo */
  --nx-topo-max-dash: 280px;  /* idem, quando a tela tem mini dash */
}
```

**A conta que define o teto:** tudo acima da primeira linha de conteúdo é área
que o operador não usa. Cabeçalho, título, respiro e a barra de ação somados
**MUST NOT** passar de `--nx-topo-max`. Tela com mini dash, ou seja com números
resumidos no topo, ganha até `--nx-topo-max-dash`, e não mais.

**Três padrões que estouram o teto, e os três já foram vistos no produto:**

1. **Botão sozinho numa linha inteira**, com o resto da largura vazia. Botão
   solto **MUST** dividir a linha com o título ou com o filtro. Uma linha de
   40 a 50px para um controle só é o caso mais barato de corrigir e o mais
   frequente.
2. **Seletor de período numa faixa própria**, quando ele cabe na linha do
   título.
3. **Submenu com ícone em cada item.** No menu lateral em cascata, o subitem
   **SHOULD** vir sem ícone: o ícone do pai já orienta, e o do filho só adiciona
   ruído. Observado no sistema de referência da reunião.

**Como se confere, e não é no olho:** medir do topo do conteúdo até a primeira
linha útil, no navegador, com a janela em 1280px de largura. Tela que passar do
teto entra na lista com o nome da tela, porque conserto sem nome de tela já foi
aplicado a uma e não às irmãs cinco vezes nesta base.

## Orçamento de altura da barra lateral

Medido em 06/09/2026, num Chromium sem sessão, com o DOM real da barra e o CSS
de produção. **A barra lateral MUST NOT rolar com o grupo financeiro aberto em
janela de 720px de altura ou mais**, que é o que sobra num notebook de 768px
depois da barra do navegador.

A conta, com o financeiro aberto, são quinze linhas: cinco de operação, o botão
do grupo, seis do financeiro, uma de anamnese e duas de análise.

| Peça | Antes | Depois | Ganho |
|---|---|---|---|
| Respiro do cabeçalho, `padding-bottom` mais `margin-bottom` | 24 mais 24 | 14 mais 14 | 20px |
| Respiro de cada grupo, `padding` vertical | 7px | 5px | 16px, quatro grupos |
| Altura do item, `.nx-nav-item` | 36px | 32px | 56px, catorze itens |
| Altura do botão de grupo | 36px | 32px | 4px |

O conteúdo caiu de 624px para 548px. **Cabe até 720px de janela. Em 640 ainda
faltam 79px, e isso está aberto.**

**Por que isso é regra e não detalhe de tela:** a barra esconde a própria barra
de rolagem desde 27/08/2026, então overflow aqui não produz uma barra visível,
produz um item que some sem aviso. Dois testadores relataram exatamente isso em
27/08, por caminhos independentes. A stack nova herda o mesmo menu e o mesmo
número de itens, então herda o mesmo teto.

**O que NÃO foi provado, e por quê:** se a barra de rolagem em si aparece na
tela do Arthur. O Chromium sem cabeça deste ambiente usa barra sobreposta, que
ocupa zero de largura, então `offsetWidth` menos `clientWidth` dá zero mesmo com
a barra ligada. O controle positivo passou quando devia falhar, o que invalida a
medição de visibilidade. A de rolagem continua válida, e é a que sustenta a
tabela acima. Código lido, não comportamento provado.

## Uso incorreto

Cruz, coração, estetoscópio. Preto puro. Segundo acento cromático. Tipografia
fora da dupla Outfit/Manrope.
