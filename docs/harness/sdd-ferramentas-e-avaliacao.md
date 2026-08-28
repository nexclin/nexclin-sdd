# As ferramentas de SDD que temos, quando usar cada uma, e a avaliação

> Pedido do Arthur em 27/08/2026: a listagem do que cada ferramenta de SDD faz e
> quando usar, mais uma avaliação sobre trocar o Spec Kit pelo
> `mattpocock/skills`.
>
> A recomendação está no fim, e é uma só. As duas primeiras seções existem para
> ela ser conferível.

---

## Parte 1. O fluxo do Spec Kit, na ordem em que se usa

Dez skills. Sete formam a linha principal, três são apoio. A ordem importa:
cada uma consome o artefato que a anterior escreveu.

### A linha principal

| Ordem | Skill | O que faz | Quando usar |
|---|---|---|---|
| 0 | `speckit-constitution` | Cria ou emenda `.specify/memory/constitution.md` | Uma vez por projeto, e depois só para emendar. Aqui já rodou: a constituição está em v1.0.0 |
| 1 | `speckit-specify` | Descrição em linguagem natural vira `spec.md`, com requisitos numerados | No começo de toda feature. É o artefato que a regra (h) exige |
| 2 | `speckit-clarify` | Acha o que ficou vago e faz **até 5 perguntas**, gravando as respostas de volta na spec | Logo depois de escrever a spec, antes do plano. Foi ele que produziu a decisão D-005.5 |
| 3 | `speckit-plan` | Spec vira `plan.md`, mais `research.md`, `data-model.md` e `contracts/` | Depois da spec estar clara. É onde a decisão técnica é registrada com alternativa recusada |
| 4 | `speckit-tasks` | Plano vira `tasks.md`, tarefas ordenadas por dependência | Depois do plano. É o que permite parar entre fases, que é a regra (h) |
| 5 | `speckit-analyze` | Confere spec, plano e tarefas entre si e aponta contradição. **Não escreve nada** | Entre o `tasks` e o `implement`. É barato e pega spec que pede o que o plano não faz |
| 6 | `speckit-implement` | Executa as tarefas do `tasks.md`, em ordem | Depois do aceite humano do plano |

### As três de apoio

| Skill | O que faz | Quando usar |
|---|---|---|
| `speckit-checklist` | Gera um checklist sob medida para a feature | Quando o aceite manual tem muitos passos e esquecer um é provável |
| `speckit-converge` | Compara o código de hoje com spec, plano e tarefas, e **acrescenta ao `tasks.md` o que ainda falta** | Quando a implementação andou fora do fluxo e o `tasks.md` ficou defasado. É o caso da SPEC 006 |
| `speckit-taskstoissues` | Transforma as tarefas em issues do GitHub | Só se o trabalho for distribuído entre pessoas. Aqui nunca foi necessário |

### O que o Spec Kit deste projeto já produziu, em número

Contado nos `tasks.md`, não estimado:

| Spec | Concluídas | Abertas |
|---|---:|---:|
| 001, fundação e superadmin | 24 | 3 |
| 004, correção da bateria do Vinícius | 35 | 16 |
| 005, configurações da clínica | 13 | 3 |
| 002, segurança e auditoria | 2 | 12 |
| 003, 006, 013, 016 | sem `tasks.md` | |

**72 tarefas concluídas pelo fluxo.** Ele não é teatro: entregou.

**E a maior entrega recente não passou por ele.** A SPEC 006, a modelagem INI,
tem só `spec.md`: nenhum plano, nenhuma tarefa. Foram onze commits e seis
migrações, e funcionou. Isso é evidência dos dois lados e precisa ser dita
inteira.

---

## Parte 2. O mercado, e o que cada categoria resolve

A pergunta "qual a melhor ferramenta de SDD do mercado" tem um pressuposto que
não se sustenta: **as coisas comparadas não são da mesma categoria.**

| Ferramenta | O que é | Artefato que deixa |
|---|---|---|
| **GitHub Spec Kit** | Framework de SDD. Fases com artefato obrigatório e parada humana entre elas | `spec.md`, `plan.md`, `tasks.md`, constituição |
| **BMAD** | Framework com papéis de agente (PM, arquiteto, dev, QA) | Documentos por papel |
| **GSD** | Framework de fases com verificação e roadmap | `.planning/` com roadmap e fases |
| **AWS Kiro** | IDE com SDD embutido, requisitos em EARS | Specs no formato da ferramenta |
| **`mattpocock/skills`** | **Não é framework.** Conjunto de práticas de engenharia, composáveis | O que você mandar: ADR, `CONTEXT.md`, tickets |

O README dele é explícito sobre isso: existe **como alternativa** a
"GSD, BMAD e Spec-Kit", porque na visão dele esses "tomam o controle e tornam
bugs no processo difíceis de resolver".

Ele está certo sobre o defeito. E o defeito é o preço de uma coisa que este
projeto usa.

---

## Parte 3. A avaliação, e a recomendação

### Não trocar. E a razão não é apego ao Spec Kit.

**A razão é a §2.5 do `CLAUDE.md`,** e ela é a decisão mais importante já tomada
aqui:

> na maioria dos casos o que atravessa **não é o código, é a regra escrita**. O
> front React/Vite do Lovable será reescrito em Next.js de qualquer jeito. O que
> sobrevive é a decisão de *como o sistema deve se comportar*.

Em outubro, todo o front da Lovable é jogado fora. O que atravessa é o banco e
**as specs**. Uma metodologia cujo produto final são tickets fechados e ADRs
avulsos entrega menos para essa travessia do que uma cujo produto é
`spec.md` numerado por requisito.

Dito de outro jeito: neste projeto a spec **não é documentação do código, é o
substituto dele**. Trocar por um fluxo sem esse artefato obrigatório é vender a
única coisa que sobrevive a outubro.

### Três razões menores, mas concretas

1. **A constituição.** A regra (h) exige regra viva aprovada em `docs/regras/`, e o guarda
   em `.claude/hooks/guarda-constituicao.mjs` aplica outras regras dela. Trocar
   o método é emenda constitucional, não escolha de ferramenta.
2. **A numeração é referência viva.** "SPEC 006", "T017", "D-005.5" aparecem em
   handoffs, registros diários e commits. São endereços que já foram usados.
3. **`triage` colidiria com `nx-apontamento`**, que já faz a triagem das
   baterias no formato da base do Notion.

### Onde ele é melhor, e isso é real

O Spec Kit tem um buraco no começo do fluxo, e o `mattpocock/skills` o preenche
melhor do que qualquer outra coisa que eu tenha lido.

**`speckit-clarify` faz até 5 perguntas, uma vez.** O `grilling` trabalha uma
árvore de decisões em rodadas, e só termina quando a fronteira esvazia. Não é a
mesma ferramenta com nome diferente: uma tem teto, a outra tem critério de
parada.

Este projeto tem o histórico que justifica isso. A **D-1** foi decidida e
revogada no mesmo dia pela D-7. A prioridade inverteu em 26/08 contra o que a
§2.5 vinha orientando. Hoje mesmo eu construí um cabeçalho de grupo que foi
recusado na primeira olhada. Nenhuma dessas foi falta de spec: foi falta de
alguém apertar a decisão antes de virar código.

### A recomendação, em uma frase

**Spec Kit continua sendo a espinha. O `grilling` vira a porta de entrada.**

O fluxo passa a ser:

```
grilling  →  speckit-specify  →  speckit-clarify  →  speckit-plan
          →  speckit-tasks    →  speckit-analyze  →  speckit-implement
```

O `grilling` antes da spec, não no lugar dela. Ele produz o entendimento; o
`speckit-specify` produz o artefato que atravessa para outubro.

### O que NÃO fazer, e é o risco real desta conversa

**Não clonar as 22.** Já existem, alcançáveis nesta sessão, o Spec Kit, o
superpowers e uma suíte completa de GSD. Somar uma quarta metodologia inteira
não dá mais método: dá mais respostas concorrentes para "como se começa uma
feature", e a pergunta seguinte vira "qual eu uso agora", que é exatamente o
custo que o `writing-for-agents` chama de **carga cognitiva**.

O princípio da catraca do `docs/harness/README.md` já dizia isso: cada peça
entra por uma falha real, nomeada e datada. Cinco entraram por esse critério em
27/08. As outras dezessete não têm falha para mostrar.

---

## Resumo em uma tabela

| Situação | Use |
|---|---|
| Ideia nova, ainda vaga | **`grilling`** |
| Entendimento fechado, virar artefato | `speckit-specify` |
| Spec escrita, achar o que ficou no ar | `speckit-clarify` |
| Spec clara, decidir a técnica | `speckit-plan` |
| Plano aprovado, quebrar em tarefas | `speckit-tasks` |
| Antes de executar, conferir coerência | `speckit-analyze` |
| Executar | `speckit-implement` |
| Código andou fora do fluxo | `speckit-converge` |
| Aceite manual com muitos passos | `speckit-checklist` |
| Decisão que não é minha | `to-questionnaire` |
| Escrever skill, regra ou CLAUDE.md | `writing-for-agents` |
| Desenhar módulo para a stack nova | `codebase-design` |
| A mensagem não chegou | `wait-what` |
