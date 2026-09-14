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

## Uma pasta por funcionalidade, na ordem em que nasceram

> **Emenda de 13/09/2026, decisão do Arthur.** A ADR 0006 dizia que pasta aqui
> só existe para frente em execução. Passa a existir **uma pasta por regra**, no
> número que a regra já tem, para que a lista de funcionalidades se leia na
> ordem cronológica de uma vez. A regra continua em `docs/regras/`; a pasta é
> ponteiro, nunca cópia. Frente sem plano tem só `spec.md` (link) e um
> `README.md` que aponta onde a execução está registrada.

| Pasta | O que é | O que tem |
|---|---|---|
| [`001-fundacao-superadmin/`](001-fundacao-superadmin/) | Fundação: banco, auth, multi-tenant e Super Admin | spec, README |
| [`002-seguranca-anamnese-auditoria/`](002-seguranca-anamnese-auditoria/) | Anamnese pública e auditoria de paciente | spec, README |
| [`003-superadmin-blindado/`](003-superadmin-blindado/) | Super Admin finalizado e blindado | spec, README |
| [`004-correcao-bateria-vinicius/`](004-correcao-bateria-vinicius/) | Correção da 1ª bateria de testes | spec, README |
| [`005-configuracoes-clinica/`](005-configuracoes-clinica/) | Configurações da clínica | spec, README |
| [`006-modelagem-ini/`](006-modelagem-ini/) | Modelagem INI: cobrança, precificação, ocupação, recall | spec, README |
| [`013-residuos-conformidade/`](013-residuos-conformidade/) | Resíduos e conformidade documental | spec, README |
| [`016-endurecimento-seguranca/`](016-endurecimento-seguranca/) | Endurecimento de segurança pré-lançamento | spec, README |
| [`017-superadmin-e-impersonacao/`](017-superadmin-e-impersonacao/) | Superadmin e impersonação | spec, README |
| [`018-funil-de-atendimentos/`](018-funil-de-atendimentos/) | Funil de atendimentos | spec, README |
| [`019-conformidade-lgpd-do-painel/`](019-conformidade-lgpd-do-painel/) | Conformidade LGPD do painel | spec, README |
| [`020-avisos-internos-e-o-dia-do-medico/`](020-avisos-internos-e-o-dia-do-medico/) | Avisos internos e o dia do médico | spec, README |
| [`021-financeiro/`](021-financeiro/) | Financeiro que não erra o caixa | spec, plan, tasks (T001 a T047) |
| [`022-motor-de-rotina/`](022-motor-de-rotina/) | Motor de rotina da clínica | spec, plan, tasks (T101 em diante) |
| [`023-avisos-e-recados-da-equipe/`](023-avisos-e-recados-da-equipe/) | A mensagem interna, seção 8 da regra | spec, plan, tasks (T201 a T250) |
| [`024-perfil-operacional/`](024-perfil-operacional/) | A secretária opera a clínica | spec, plan, tasks (T301 a T377) |
| [`025-importacao-e-exportacao/`](025-importacao-e-exportacao/) | Importação e exportação de dados | spec, README |

**A numeração das tarefas é por centena, uma centena por frente**, na ordem das
regras: a 021 usa T001 em diante, a 022 T101, a 023 T201, a 024 T301. É o que
impede o título de uma issue (`T004: ...`) de colidir com o de outra frente,
porque o `speckit-taskstoissues` pula qualquer `Tnnn` que já exista no GitHub,
aberta ou fechada.

As lacunas (`007` a `012`, `014` e `015`) são históricas: regras absorvidas ou
descartadas antes de virarem arquivo. Não se renumera para fechar lacuna,
porque o número é citado em commit, issue e histórico.

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
fechou. Ela é o registro de como aquilo foi executado, e custa 3 arquivos. Desde
13/09 toda regra tem pasta, então o que não pode acontecer mudou de nome: é
**pasta com `plan.md` e sem frente ativa**, o plano que ninguém executa. Se isso
acontecer, a hipótese a testar primeiro é a da ADR 0004.
