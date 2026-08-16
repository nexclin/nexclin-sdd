# Tokens de marca

Fonte: `nexclin.html` — NexClin Brand Concept v1.0. Este arquivo é a tradução
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

## Uso incorreto

Cruz, coração, estetoscópio. Preto puro. Segundo acento cromático. Tipografia
fora da dupla Outfit/Manrope.
