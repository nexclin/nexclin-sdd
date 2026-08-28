---
paths:
  - "app/**"
  - "tailwind.config.ts"
  - "app/globals.css"
---

# Marca na interface

Fonte: `nexclin.html` (Brand Concept v1.0). Tokens em `../../docs/referencia/marca-tokens.md`.

> **Marca também é como o projeto escreve.** Esta regra cobre a interface. A voz
> escrita (travessão proibido, barra como conector, superlativo sem conta,
> formato de mensagem) vive em `.claude/rules/escrita.md`, que tem escopo de
> caminho mais amplo porque vale para documento, spec, commit e resposta na
> tela, não só para `app/**`.

## Paleta

| Papel | Token | Hex |
|---|---|---|
| Acento (único) | `teal` | `#1F8C8C` |
| Fundo escuro | `navy` | `#141C28` |
| Texto/estrutura | `slate` | `#3A4A5C` |
| Fundo claro | `bone` | `#F4F1EC` |
| Tipografia | `ink` | `#0E1620` |

Verde-água é o **único acento cromático do sistema** — usar com moderação,
senão perde o impacto. Navy e slate substituem o preto puro. Bone é o fundo
preferencial: mais quente que branco, dá caráter editorial.

## Tipografia

- **Outfit** — títulos e momentos de marca (200/400/600/800).
- **Manrope** — texto corrido e interface (300/400/500/700).

## Dois temas, deliberadamente distintos

- **App da clínica:** fundo bone, sidebar navy, acento teal.
- **Painel superadmin:** fundo navy, densidade maior, badges semânticas.

A separação é intencional: o operador precisa saber, num relance, em qual dos
dois mundos está. Não unifique.

## Não faça

Cruz, coração, estetoscópio. A marca é empresa de tecnologia para gestão
clínica, não hospital. Sem preto puro. Sem segundo acento cromático.
