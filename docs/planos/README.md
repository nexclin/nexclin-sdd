# Planos de execução

> Criado em 04/09/2026, junto com a [ADR 0006](../adr/0006-o-spec-kit-volta-pela-metade.md),
> que traz o Spec Kit de volta pela metade.

## A separação, em uma frase

**A regra vive em [`../regras/`](../regras/). O plano e as tarefas vivem aqui.**

A regra é o artefato durável: é ela que atravessa para a stack nova em outubro,
e é ela que se corrige no mesmo commit em que o comportamento muda. O plano e a
lista de tarefas são andaime: servem enquanto a frente está em execução, e
depois só interessam ao histórico.

Misturar os dois foi o defeito que a [ADR 0004](../adr/0004-o-spec-kit-sai.md)
apontou: oito features viraram 34 arquivos, e a resposta para *"onde está a
regra?"* passou a exigir saber qual dos sete. Aqui a resposta é sempre a mesma,
`docs/regras/`.

## A forma de uma pasta

```
docs/planos/NNN-nome/
├── spec.md      → link simbólico para ../../regras/NNN-nome.md
├── plan.md      gerado por /speckit-plan
├── tasks.md     gerado por /speckit-tasks
└── checklists/  gerado por /speckit-checklist, quando pedido
```

O `spec.md` é **link, não cópia**. O Spec Kit exige esse nome dentro do
diretório da feature, e o link entrega o nome sem criar um segundo arquivo que
diverge do primeiro no dia seguinte.

## Como apontar o Spec Kit para uma frente

O Spec Kit resolve o diretório da feature por `.specify/feature.json`, que é
**estado por checkout e não vai para o git**. Aponte antes de rodar qualquer
skill:

```sh
export SPECIFY_FEATURE_DIRECTORY=docs/planos/021-financeiro
```

A primeira skill que rodar grava o valor em `.specify/feature.json`, e as
seguintes o encontram sozinhas.

## Só quatro skills estão instaladas

`speckit-plan`, `speckit-tasks`, `speckit-analyze` e `speckit-checklist`.

As outras seis ficaram de fora porque este projeto já tem substituto e ter as
duas causaria escolha por acaso:

| Skill do Spec Kit | O que este projeto usa no lugar |
|---|---|
| `speckit-specify` | `nx-regra`, que escreve nas sete seções em `docs/regras/` |
| `speckit-clarify` | `grill-with-docs`, que interroga a ideia antes |
| `speckit-constitution` | `docs/constituicao.md`, emendada à mão com versão |
| `speckit-taskstoissues` | `to-tickets` |
| `speckit-implement` | `implement`, que já para por fase |
| `speckit-converge` | não tem equivalente, e não foi pedido |

## Pasta que fecha

Frente entregue e provada: a pasta do plano **fica**, com a data no commit que a
fechou. Ela é o registro de como aquilo foi executado, e custa 3 arquivos. O que
não pode acontecer é uma pasta aberta sem frente ativa: isso é a bagunça que a
ADR 0004 descreveu voltando pela porta dos fundos.
