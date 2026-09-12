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

## As dez skills estão instaladas, desde 12/09/2026

| Skill do Spec Kit | Por que ela está aqui |
|---|---|
| `speckit-clarify` | de-risca a ideia antes do plano. **Entrou em 05/09 no lugar do `grilling`**, que não existe em clone limpo |
| `speckit-plan` | o degrau entre a regra e as issues |
| `speckit-tasks` | lista ordenada por dependência |
| `speckit-analyze` | consistência cruzada entre regra, plano e tarefas |
| `speckit-checklist` | checklist de qualidade sobre o plano |
| `speckit-taskstoissues` | abre issue a partir do `tasks.md`, **preservando a ordem de dependência** |

As quatro que tinham ficado de fora **entraram em 12/09/2026**, por pedido do
Arthur, para usar o SDD no projeto inteiro. Cada uma convive com um substituto
que já existia, e a divisão de trabalho é esta:

| Skill do Spec Kit | O que este projeto usa junto, e como se dividem |
|---|---|
| `speckit-specify` | rascunha a spec no formato do Spec Kit. **A regra continua sendo `docs/regras/NNN-nome.md`**, nas sete seções da `nx-regra`. Se a `speckit-specify` escrever `spec.md` na pasta do plano, o arquivo é rascunho: o conteúdo vai para a regra e o `spec.md` volta a ser link |
| `speckit-constitution` | só lê. `.specify/memory/constitution.md` continua sendo ponteiro para `docs/constituicao.md`, que é emendada à mão, com versão. A skill não cria segunda lei |
| `speckit-implement` | executa o `tasks.md`. **Não tem a parada humana por fase da regra (h).** Use com a parada dita no argumento, ou use a `implement` local |
| `speckit-converge` | sem equivalente. Nova no upstream 1.0.6 |

As seis de 04/09 estão na versão 1.0.4 do Spec Kit; as quatro de 12/09, na
1.0.6, com `create-new-feature.sh`, `spec-template.md` e
`constitution-template.md` que faltavam em `.specify/`.

> **`to-tickets` e `speckit-taskstoissues` convivem, e a divisão é clara.** O
> `to-tickets` quebra um **documento** em issues. O `speckit-taskstoissues` lê o
> **`tasks.md`** e preserva a ordem de dependência. Frente com plano usa o
> segundo; pedido solto usa o primeiro.
>
> **`grill-with-docs` não é substituto de nada, e está quebrado.** Ele delega ao
> `grilling`, que vive em `.claude/skills-fora/`, excluída pelo `.gitignore`.

## Pasta que fecha

Frente entregue e provada: a pasta do plano **fica**, com a data no commit que a
fechou. Ela é o registro de como aquilo foi executado, e custa 3 arquivos. O que
não pode acontecer é uma pasta aberta sem frente ativa: isso é a bagunça que a
ADR 0004 descreveu voltando pela porta dos fundos.
