# Domain Docs

Como as skills de engenharia devem consumir a documentação de domínio deste
repositório ao explorar o código.

## Antes de explorar, leia isto

- **`CONTEXT.md`** na raiz. São 58 linhas, e só entram termos que já causaram
  confusão real: âncora, recebível, repasse, faixa, ponte, atravessar,
  ModuleKey, impersonação, apontamento, regra viva.
- **`docs/adr/`**: leia os ADRs que tocam a área em que você vai mexer.
- **`docs/regras/`**: leia a **regra viva** da área. Este item não vem do
  gabarito, e é o mais importante dos três aqui. Neste repositório o artefato
  durável é a regra escrita, não o código: a §2.5 do `CLAUDE.md` diz que o front
  da plataforma ao vivo será reescrito e o que sobrevive é a decisão de como o
  sistema deve se comportar. Quem lê só o `CONTEXT.md` e o código perde a regra
  inteira, e a regra é o requisito.

Se algum desses arquivos não existir, **siga em silêncio**. Não sinalize a
ausência e não proponha criar antes da hora. O `/domain-modeling`, alcançado
pelo `/grill-with-docs`, cria quando um termo ou uma decisão de fato precisa ser
resolvida. Regra nova nasce pelo `/nx-regra`.

## Estrutura de arquivos

Este repositório é de **contexto único**:

```
/
├── CONTEXT.md
├── docs/
│   ├── adr/
│   │   ├── 0001-consultas-sai-do-contrato-de-modulos.md
│   │   └── 0004-o-spec-kit-sai.md
│   ├── regras/          ← as regras vivas, numeradas
│   └── historico/       ← handoffs e relatórios, com a data no nome
├── app/
└── lib/
```

Não há `CONTEXT-MAP.md`, porque não há monorepo. Se um dia houver, ele aponta
para um `CONTEXT.md` por contexto, e os ADRs de contexto vivem em
`src/<contexto>/docs/adr/`.

## Use o vocabulário do glossário

Quando a sua saída nomear um conceito do domínio, seja em título de issue, em
proposta de refatoração, em hipótese ou em nome de teste, use o termo como o
`CONTEXT.md` define. Não escorregue para sinônimo que o glossário evita de
propósito.

Se o conceito de que você precisa ainda não está no glossário, isso é sinal: ou
você está inventando linguagem que o projeto não usa, e aí reconsidere, ou existe
lacuna real, e aí anote para o `/domain-modeling`.

## Sinalize conflito com ADR

Se a sua saída contradiz um ADR existente, diga isso na cara em vez de
atropelar em silêncio:

> *Contradiz o ADR-0001 (consultas sai do contrato de módulos), mas vale
> reabrir porque...*

## Sinalize conflito com a constituição

A `docs/constituicao.md` e as regras inegociáveis da seção 4 do `CLAUDE.md`
vencem qualquer ADR, qualquer regra viva e qualquer preferência. Se a sua saída
esbarra numa delas, pare e diga qual, em vez de propor exceção.
