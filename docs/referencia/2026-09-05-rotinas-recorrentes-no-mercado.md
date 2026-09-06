# Rotinas recorrentes no mercado: template, instância, papel, cumprimento e atraso

**Data:** 05/09/2026
**Tipo:** documento de referência. Descreve o que existe em outras ferramentas.
Não recomenda nada para o NexClin, e não decide nada. A recomendação é de outra
etapa.
**Escopo:** como oito ferramentas horizontais de tarefa e um conjunto de
software vertical modelam rotina recorrente, checklist reaplicável, atribuição
por papel, medição de cumprimento e exibição de atraso.

---

## 0. Método, e onde a fonte primária não foi alcançada

Esta pesquisa tinha ordem de usar fonte primária. O ambiente desta sessão
bloqueia por política de rede a maior parte dos domínios de documentação de
fabricante. A tentativa de abrir `developer.atlassian.com`, `developers.asana.com`,
`developer.clickup.com`, `developer.todoist.com`, `developers.notion.com`,
`linear.app`, `support.monday.com`, `help.height.app` e `www.process.st`
devolveu 403 do proxy de egresso em todos os casos. Só `github.com`,
`api.github.com` e `raw.githubusercontent.com` responderam.

Isso divide as afirmações deste documento em **dois níveis de prova**, e cada
seção diz em qual está.

**Nível 1, artefato primário lido na íntegra.** Quatro fabricantes publicam o
contrato da própria API em repositório oficial no GitHub, e esses arquivos foram
baixados e lidos aqui, linha a linha:

| Artefato | Fabricante | Arquivo lido |
|---|---|---|
| Schema GraphQL público | Linear | [`packages/sdk/src/schema.graphql`](https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql) em [linear/linear](https://github.com/linear/linear) |
| Especificação OpenAPI | Asana | [`defs/asana_oas.yaml`](https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml) em [Asana/openapi](https://github.com/Asana/openapi) |
| Modelos do SDK oficial | Todoist | [`todoist_api_python/models.py`](https://raw.githubusercontent.com/Doist/todoist-api-python/main/todoist_api_python/models.py) em [Doist/todoist-api-python](https://github.com/Doist/todoist-api-python) |
| Tipos gerados do SDK oficial | Notion | [`src/api-endpoints/pages.ts`](https://raw.githubusercontent.com/makenotion/notion-sdk-js/main/src/api-endpoints/pages.ts) e [`data-sources.ts`](https://raw.githubusercontent.com/makenotion/notion-sdk-js/main/src/api-endpoints/data-sources.ts) em [makenotion/notion-sdk-js](https://github.com/makenotion/notion-sdk-js) |

Onde este documento diz "verificado no schema", a afirmação vem daí, e a
ausência de um campo também foi verificada por busca no arquivo inteiro.

**Nível 2, página primária citada mas não aberta aqui.** Para Trello, ClickUp,
Monday, Height, para as páginas de ajuda de Linear e Notion, e para o bloco de
software vertical, o conteúdo chegou por excerto de busca sobre as páginas
oficiais do próprio fabricante. A URL citada é a da página do fabricante, e é
onde a afirmação deve ser reconferida. **Não abri essas páginas**, então trate
cada uma como leitura de segunda mão de uma fonte primária, não como leitura
direta.

**Onde não cheguei a nada.** Height não publica referência de API acessível por
este caminho, e a pergunta 4 ficou sem resposta para várias ferramentas. Está
dito item a item, em vez de arredondado.

---

## 1. Quadro-resumo

Leitura das cinco perguntas nas oito ferramentas. Cada célula é detalhada na
seção 2, com fonte.

| | Entidade própria para a recorrência | Quando materializa a instância | Template de checklist | Atribuição por papel | Mede cumprimento no período |
|---|---|---|---|---|---|
| **Trello** | Não no núcleo. Power-Up ou regra de automação | Por agenda, copiando um cartão | Cópia de itens, e checklist dentro de template de cartão | Não | Não encontrado em doc primária |
| **ClickUp** | Campo de configuração na tarefa | Ao fechar, ou na data, conforme opção | Sim, objeto "checklist template" | Não | Não confirmado como métrica nativa |
| **Asana** | Não existe na API | Chamada explícita, assíncrona | Subtarefas dentro do task template | Só por campo personalizado do tipo `people` | Não encontrado na especificação |
| **Monday** | Não. É receita de automação | Por agenda, duplicando um item | Duplicação de item e template de quadro | Coluna People, não papel | Não encontrado em doc primária |
| **Notion** | Não na API. Existe só na interface | Por agenda, copiando o template | Sim, template de database, listável por API | Propriedade Person, não papel | Não encontrado em doc primária |
| **Linear** | Template é entidade, e a instância aponta para ela | Quando a instância anterior vence | Não tem checklist. Usa sub-issues | Não | Filtro por template existe, taxa pronta não |
| **Todoist** | Não. É string dentro do campo de data | Ao concluir a tarefa | Não | Não | Contagem e meta, não taxa por rotina |
| **Height** | Não encontrado em doc primária | Ao marcar como feito | Não encontrado em doc primária | Não encontrado | Não encontrado |

---

## 2. Ferramenta a ferramenta

### 2.1 Linear

**Nível 1 para o modelo de dado.** É a única das 8 em que encontrei, documentado,
um ponteiro da instância para a regra que a gerou, e aqui ele consta do schema
público.

**Recorrência.** `Template` é entidade de primeira classe: declarada como
`type Template implements Node`, com `templateData: JSON!` ("the pre-filled
attributes for the entity type"), `type: String!` ("the entity type this
template is for, such as 'issue', 'project', or 'document'"), `lastAppliedAt`
("the date when the template was last applied to create or update an entity") e
`inheritedFrom: Template`. Verificado no
[schema](https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql).

O elo instância para template existe e é público. O tipo `Issue` traz o campo
`recurringIssueTemplate: Template`, documentado no próprio schema como "the
recurring issue template that created this issue". O payload de webhook
`IssueWebhookPayload` traz `recurringIssueTemplateId: String`. Verificado no
schema.

Não existe no schema público um tipo `RecurringIssue` separado, e a busca por
esse nome no arquivo inteiro não retorna nada. A configuração de agenda aparece
como `schedule: JSONObject`, descrito como "serialized array of JSONs
representing the recurring issue's schedule", e está dentro do tipo
`IssueDraft`, que o próprio schema marca como `[Internal]`. Ou seja: **a regra
de recorrência não é entidade pública, mas o template é, e o vínculo com a
instância é.** Verificado no schema.

**Quando materializa.** Cada nova instância é criada quando a anterior atinge a
data de vencimento, e a configuração fica em Team settings, segundo
[Recurring Issues](https://linear.app/changelog/2024-12-05-recurring-issues)
(nível 2).

**Template muda depois.** A documentação de
[Issue templates](https://linear.app/docs/issue-templates) diz que mudanças
futuras no template não afetam as issues recorrentes já criadas a partir dele, e
que é preciso editar a issue recorrente ou recriá-la a partir do template
atualizado (nível 2).

**Checklist.** Não existe. A palavra `checklist` aparece zero vez no schema
inteiro. O equivalente é sub-issue, e a doc citada acima diz que a conversão em
issue recorrente carrega as propriedades do template, sub-issues incluídas.

**Papel.** Não encontrado. Não há no schema campo de atribuição por papel na
issue.

**Cumprimento.** Os ingredientes existem e a agregação pronta não foi
encontrada. `Issue` tem `dueDate: TimelessDate` e `completedAt: DateTime`, o que
torna "foi feita no prazo" calculável, e os filtros `IssueCollectionFilter` e
`NullableIssueFilter` aceitam `recurringIssueTemplate`, o que permite juntar
todas as instâncias de uma mesma rotina. Verificado no schema. **Não localizei
doc primária de um relatório nativo de taxa de cumprimento por rotina.**

**Atraso na interface.** Não localizei doc primária descrevendo a marcação
visual de atraso.

**Nota lateral.** Em 20/07/2026 a Linear lançou
[Loops](https://linear.app/changelog/2026-07-20-introducing-loops), trabalho
recorrente descrito em linguagem natural e executado por agente, por agenda ou
por evento. É outra categoria: automação com IA, não modelo de dado de rotina
(nível 2).

### 2.2 Asana

**Nível 1 para o modelo de dado**, a partir da especificação OpenAPI oficial.

**Recorrência.** **Não existe na API.** A busca por `recurr` e por `repeat` na
`asana_oas.yaml` inteira retorna apenas dois trechos, ambos sobre paginação de
busca, nenhum sobre tarefa. O objeto `TaskBase` tem `approval_status`,
`assignee_status`, `assigned_by`, `completed`, `completed_at`, `completed_by`,
`created_at`, `dependencies`, `dependents`, `due_at`, `due_on`, `external`,
`html_notes`, `memberships`, `modified_at`, `name`, `notes`, `num_subtasks`,
`start_at`, `start_on` e `actual_time_minutes`, e **nenhum campo de
recorrência**. Verificado na especificação.

**Template de tarefa.** Existe como recurso próprio, com `GET /task_templates`,
`GET /task_templates/{task_template_gid}` e
`POST /task_templates/{task_template_gid}/instantiateTask`. O template guarda
uma "receita" (`TaskTemplateRecipe`) com os campos que definem a instância
futura, entre eles `relative_start_on` e `relative_due_on`, descritos na
especificação como "the number of days after the task has been instantiated on
which that the task will start" e "will be due", mais `due_time`, `subtasks`,
`followers`, `custom_fields`, `dependencies` e `memberships`. Verificado na
especificação.

Três detalhes do contrato que importam para a distinção template versus
instância, todos verificados na especificação:

1. A materialização é **explícita e assíncrona**. O endpoint `instantiateTask`
   é descrito como "creates and returns a job that will asynchronously handle
   the task instantiation", e o resultado chega em `new_task`. Não há agenda:
   alguém ou algo precisa chamar.
2. O corpo do pedido, `TaskTemplateInstantiateTaskRequest`, aceita **um único
   campo**, `name`. Não dá para injetar data nem responsável na hora de
   instanciar.
3. A receita **não tem campo de responsável**. Tem `followers`, que é
   seguidor, não executor.

**Elo de volta.** Não existe. `TaskBase` não tem campo apontando para o task
template que a originou, e a busca por `task_template` dentro dos schemas de
tarefa não retorna nada. Verificado na especificação. Consequência direta:
**pela API, uma tarefa instanciada não sabe de que template veio.**

**Papel.** O tipo mais próximo é campo personalizado com
`resource_subtype: people`, que consta do enum de tipos de campo personalizado
(`text`, `enum`, `multi_enum`, `number`, `date`, `people`, `reference`).
Verificado na especificação. Isso é campo que aponta pessoas, não papel que
resolve para quem ocupa o cargo.

**Cumprimento.** `completed_at` e `due_on` existem no objeto, então o cálculo é
possível a partir dos dados. **Não encontrei na especificação nenhum recurso de
relatório de taxa de cumprimento.**

**Atraso na interface.** A data vencida aparece em vermelho enquanto a tarefa
está ativa, segundo discussão no
[fórum oficial da Asana](https://forum.asana.com/t/overdue-date-remains-red-in-boards-when-task-is-marked-completed/63896)
(nível 2, e fórum é fonte fraca: **não localizei página de ajuda primária que
descreva a regra de cor**).

### 2.3 Todoist

**Nível 1 para o modelo de dado**, a partir dos modelos do SDK oficial.

**Recorrência.** É **campo dentro da tarefa**, e nada mais. O modelo `Due` tem
exatamente cinco campos: `date`, `string`, `lang`, `is_recurring: bool` e
`timezone`. O modelo `Task` referencia `due: Due | None` e não tem nenhum campo
de template, de série ou de instância. Verificado em
[`models.py`](https://raw.githubusercontent.com/Doist/todoist-api-python/main/todoist_api_python/models.py).

A regra de recorrência mora em `string`, texto em linguagem natural como
"tomorrow at 10:00". Não há entidade de agenda, e não há objeto template.

**Quando materializa.** Nunca materializa uma segunda linha. **É a mesma tarefa
que avança de data.** Ao concluir uma tarefa recorrente, ela passa para a
próxima data, segundo
[Complete a task with a recurring date](https://www.todoist.com/help/articles/complete-a-task-with-a-recurring-date-dmI6SVqdP)
(nível 2). A mesma fonte descreve a diferença entre `every`, que avança a partir
da data agendada, e `every!`, que avança a partir da data de conclusão.

Consequência para medição: como só existe 1 linha por rotina, **o histórico de
instâncias vive no log de conclusões, não na tabela de tarefas.** É a única das
8 em que a tabela de tarefas não guarda nenhum registro das ocorrências
passadas.

**Checklist template.** Não encontrado no modelo. Não há objeto de checklist nos
modelos do SDK.

**Papel.** Não encontrado. `Task` tem `assignee_id` e `assigner_id`, ambos
pessoa.

**Cumprimento.** Existe medição, mas de volume, não de aderência a uma rotina
específica. A Productivity view mostra quantas tarefas foram concluídas por dia
e por semana, o progresso contra uma meta diária padrão de 5 e semanal padrão de
25, e a sequência de dias ou semanas em que a meta foi batida, segundo
[Use the Productivity view in Todoist](https://todoist.com/help/articles/use-the-productivity-view-in-todoist-6S63uAa9)
(nível 2). Não é "esta rotina foi cumprida", é "quantas tarefas você fechou".

**Atraso na interface.** Não localizei doc primária que descreva a marcação.

### 2.4 Notion

**Nível 1 para a API**, a partir dos tipos gerados do SDK oficial.

**Template como objeto.** Existe e é endereçável. O SDK expõe
`GET data_sources/{data_source_id}/templates`, cuja resposta traz uma lista de
templates com `id`, `name` e `is_default`. Verificado em
[`data-sources.ts`](https://raw.githubusercontent.com/makenotion/notion-sdk-js/main/src/api-endpoints/data-sources.ts).

**Aplicação do template.** Na criação de página, o parâmetro `template` aceita
três formas: `{ type: "none" }`, `{ type: "default", timezone }` e
`{ type: "template_id", template_id, timezone }`. Na atualização de página,
aceita `default` ou `template_id`, acompanhado de `erase_content`, cujo
comentário no próprio tipo diz: "when used with a template, the template content
replaces the existing content". Verificado em
[`pages.ts`](https://raw.githubusercontent.com/makenotion/notion-sdk-js/main/src/api-endpoints/pages.ts).

A aplicação é **assíncrona**: a chamada retorna uma página em branco e o
conteúdo do template é aplicado depois, em segundo plano, substituindo o
conteúdo e mesclando as propriedades do template, segundo
[Creating pages from templates](https://developers.notion.com/guides/data-apis/creating-pages-from-templates)
(nível 2). A mesma fonte diz que o parâmetro `children` não é permitido junto de
um template.

**Recorrência.** **Não existe na API.** A busca por `recurr` e por `repeat` nos
módulos `pages`, `databases`, `data-sources` e `common` do SDK retorna zero
ocorrência em todos. Verificado nos arquivos.

Na interface existe, e é o caso em que **o template é o portador da
recorrência**: o próprio template de database recebe a opção Repeat, com
frequência diária, semanal, mensal ou anual, e passa a criar cópias de si mesmo
no database, segundo
[Automate work with repeating database templates](https://www.notion.com/help/guides/automate-work-repeating-database-templates)
(nível 2). Não é campo na instância nem entidade separada de agenda: é atributo
do template.

**Template muda depois.** **Não consegui confirmar em fonte primária.** A busca
sobre `notion.com/help` não devolveu trecho que responda explicitamente o que
acontece com páginas já criadas quando o template é editado depois. O resumo que
recebi era inferência, não citação, e por isso não entra aqui como fato. Fica
registrado como pergunta aberta na seção 4.

**Papel.** Existe a propriedade Person, que aponta pessoas. Não encontrei em
doc primária um conceito de papel que resolva para o ocupante do cargo.

**Cumprimento.** Não encontrado em doc primária.

**Atraso na interface.** Não encontrado em doc primária.

### 2.5 ClickUp

**Nível 2 em tudo.** Não consegui abrir `developer.clickup.com` nem
`help.clickup.com`.

**Recorrência.** É configuração dentro da tarefa, acionada por "Add recurring"
sobre uma tarefa que já tem data, segundo
[Use recurring tasks](https://help.clickup.com/hc/en-us/articles/6309885016471-Use-recurring-tasks).

**Quando materializa.** Há 2 políticas configuráveis, e a doc primária descreve
as duas. Na configuração padrão, fechar a tarefa
antes do vencimento cria a próxima instância imediatamente. Com a opção "On
Schedule", a próxima instância só é criada na data devida, e não quando a
anterior foi concluída. Mesma fonte.

Duas consequências registradas na doc do fabricante, ambas relevantes para
medir rotina:

- **Não há retroativo.** Tarefas recorrentes não criam instâncias no passado,
  segundo a mesma página. Rotina que ficou dias sem ser cumprida não deixa uma
  instância por dia perdido.
- A recorrência pode ser condicionada a a tarefa estar em determinado status,
  por exemplo um status de fechamento.

**Na API.** A informação de recorrência **não aparece no payload da tarefa**, e
poder ler ou gravar isso pela API pública é pedido aberto no portal de feedback
do próprio fabricante,
[Get and Set Recurring Tasks](https://feedback.clickup.com/public-api/p/task-api-get-recurring-information).
Portal de feedback do fabricante é primeiro-parte, e essa é a melhor prova que
consegui de que a API não expõe recorrência.

**Checklist template.** Existe como objeto reaplicável, e é o único dos oito com
template de checklist nomeado como tal. Um checklist dentro de uma tarefa pode
virar template, e depois ser aplicado a outras tarefas por "Use Template",
manualmente ou por automação, segundo
[Create checklist templates](https://help.clickup.com/hc/en-us/articles/13455445264663-Create-checklist-templates).

**Template muda depois.** A mesma página descreve a atualização do template por
"Update existing Template", a partir de um checklist editado dentro de uma
tarefa. **A doc não afirma que instâncias já aplicadas sejam atualizadas**, e o
fluxo descrito é o inverso, da instância para o template. Não encontrei
afirmação primária sobre propagação do template para instâncias existentes.

**Papel.** Não encontrado em doc primária.

**Cumprimento.** **Não confirmei métrica nativa de taxa de cumprimento no
prazo.** As páginas de Dashboards que a busca alcançou descrevem cartões de
tempo estimado, tempo registrado, status e listas de tarefas, além de visão de
quem está atrasado, em
[Dashboards](https://help.clickup.com/hc/en-us/sections/6132309544215-Dashboards).
Nenhum trecho primário descreveu um cartão de "percentual concluído no prazo".

**Atraso na interface.** Não encontrado em doc primária.

### 2.6 Trello

**Nível 2 em tudo.** Não consegui abrir `developer.atlassian.com` nem
`support.atlassian.com`.

**Recorrência.** Não está no núcleo do produto. Há dois caminhos, ambos do
próprio fabricante:

1. **Card Repeater**, Power-Up que copia um cartão por dia, semana, mês ou ano,
   e mostra um selo no cartão, segundo
   [Use the Card Repeater Power-Up](https://support.atlassian.com/trello/docs/using-the-card-repeater-power-up/).
   A mesma página registra uma limitação que interessa muito a uma rotina com
   prazo: **"Card Repeater makes an exact copy of the original card, and cards
   with due dates are not updated automatically as a result"**. A cópia herda a
   data antiga, e corrigir isso exige uma regra de automação.
2. **Comandos de calendário do Butler**, com gatilho de intervalo do tipo "todo
   dia" ou "a primeira terça de cada mês", e ação de criar cartão, segundo
   [Create and manage automations](https://help.trello.com/article/1318-creating-and-managing-butler-commands).

Em nenhum dos dois a recorrência é entidade no modelo de dado do cartão: é
configuração de um Power-Up ou de uma regra.

**Checklist template.** Não existe objeto "template de checklist" que permaneça
ligado. O que existe é cópia: ao criar um checklist, "Copy Items From..." traz
itens de outro checklist do quadro, e um checklist pode ser embutido em um
template de cartão, segundo
[Set due dates for checklist items](https://support.atlassian.com/trello/docs/how-to-use-advanced-checklists-to-set-due-dates/).
Cópia não mantém vínculo, então a pergunta "o que acontece com as instâncias
quando o template muda" não se aplica.

**Item de checklist com prazo e responsável.** Existe, e é o único dos oito em
que o item de checklist, e não só o cartão, carrega data e pessoa. Advanced
checklists permite definir data e atribuir pessoa por item, disponível em
workspaces Standard, Premium e Enterprise, e a hora padrão do vencimento do item
é 18h local de quem definiu. Mesma fonte.

**Papel.** Não. A atribuição é por membro.

**Cumprimento.** Não encontrado em doc primária.

**Atraso na interface.** É a única das 8 em que encontrei a regra definida com
limiar numérico em doc primária, e ela é por faixa de tempo, não por contagem de
dias: cinza claro para vencimento a mais de
24 horas no futuro, amarelo dentro das 24 horas anteriores ao vencimento, e
vermelho a partir do vencimento, permanecendo vermelho por 24 horas, segundo
[Add a due date or start date to a card](https://support.atlassian.com/trello/docs/adding-dates-to-cards/).

### 2.7 Monday

**Nível 2 em tudo.** Não consegui abrir `support.monday.com` nem
`developer.monday.com`.

**Recorrência.** Não é entidade nem campo: é **receita de automação**. A receita
"Every time period" cria um item novo conforme a cadência escolhida, segundo
[How to create recurring tasks](https://support.monday.com/hc/en-us/articles/360000221159-How-to-create-recurring-tasks).
Cada disparo cria um item novo, em vez de atualizar um existente, o que
significa que as instâncias existem separadas, mas sem apontar para uma regra
comum.

**Na API.** O que a referência oficial expõe são mutações de duplicação:
`duplicate_board`, que duplica quadro com itens e grupos, e `duplicate_item`,
que duplica item e subitens aninhados, ambas assíncronas, segundo
[Boards](https://developer.monday.com/api-reference/reference/boards) e
[Items](https://developer.monday.com/api-reference/reference/items). **Não
encontrei na referência de API nenhum objeto de recorrência.**

**Checklist template.** Não encontrado como objeto. O caminho documentado é
template de quadro, pelo
[Template Editor](https://support.monday.com/hc/en-us/articles/19105791772690-The-Template-Editor),
e duplicação de item.

**Papel.** Existe a coluna People, que aponta pessoas. Não encontrei papel em
doc primária.

**Cumprimento.** Não encontrei relatório de taxa de cumprimento em doc primária.

**Atraso na interface.** É a única das 8 em que encontrei "no prazo" dependendo
de ligar 2 colunas. O Deadline Mode liga uma coluna de data ou de timeline a
uma coluna de
status, e a barra passa a mostrar se o item foi concluído no prazo, se está
atrasado, ou quantos dias restam, segundo
[Deadline Mode](https://support.monday.com/hc/en-us/articles/360002646059-Deadline-Mode).
No widget de timeline, o marco fica verde quando concluído no prazo e vermelho
quando atrasado, segundo
[The Timeline Widget](https://support.monday.com/hc/en-us/articles/360017206280-The-Timeline-Widget).

Vale registrar o que isso significa em modelagem: no Monday, **"no prazo" não é
derivado sozinho da data.** Depende de configurar qual rótulo da coluna de
status conta como concluído.

### 2.8 Height

**Nível 2, e com lacunas grandes.** Não consegui abrir `help.height.app`, e
**não localizei referência de API pública do Height por este caminho**. As
perguntas 2, 3, 4 e 5 ficam sem resposta.

**Recorrência.** É configuração a partir de um atributo de data da tarefa, com
intervalo semanal, quinzenal, mensal, diário ou anual, segundo
[Creating a recurring or repeating task](https://help.height.app/en/articles/3961405-creating-a-recurring-or-repeating-task).

**Quando materializa.** A tarefa seguinte é recriada **depois que a atual é
marcada como feita**, e a nova data é calculada a partir da data de vencimento
anterior, e não da data de conclusão. Mesma fonte. Que o cálculo parta do
vencimento e não da conclusão é pedido aberto no
[fórum oficial](https://forum.height.app/t/recurring-task-have-next-task-be-created-n-weeks-from-completion-date-rather-than-from-due-date/1401)
(fórum, fonte fraca).

**Modelo de dado.** Não verificado. Sem referência de API, não sei se existe elo
entre a instância nova e a anterior, nem se há entidade de série.

---

## 3. Software vertical e de operação com checklist de rotina embutido

Aqui interessa o conceito, e é neste bloco que template e instância aparecem
como 2 objetos com nomes distintos no produto. **Nível 2 em tudo**, com uma
ressalva de peso no fim.

### 3.1 Process Street: a separação nomeada

É o único caso encontrado em que template e instância têm **nomes distintos no
produto e páginas de ajuda separadas** para explicar a diferença:
Workflow é o template, Workflow Run é a instância, segundo
[What is the Difference Between Workflows and Workflow Runs?](https://www.process.st/help/docs/difference-workflows-and-runs/)
e [What is a Workflow Run?](https://www.process.st/help/docs/what-is-a-workflow-run/).

**Template muda depois: e aqui o comportamento é o oposto dos oito de cima.**
Editar e publicar um workflow **afeta as execuções ativas**, e o fabricante
avisa que remover algo impacta os runs ativos assim que forem atualizados. Há
escolha de propagação: empurrar as mudanças para todos os runs ativos de uma
vez, ou deixar cada usuário atualizar o seu run manualmente, segundo
[Making Changes to Workflows](https://www.process.st/help/docs/editing-workflows/).
A mesma página alerta para pensar antes no efeito sobre lógica condicional,
atribuições por papel e prazos dinâmicos.

**Atribuição por papel.** Existe como recurso nomeado, Role Assignments, e o
mecanismo é: declara-se um campo de formulário do tipo members com um rótulo de
papel, por exemplo "Account Manager" ou "Approver", e no momento em que o
workflow é executado a pessoa escolhida naquele campo é atribuída às tarefas que
dependem daquele papel, segundo
[Role Assignments in Process Street](https://www.process.st/help/docs/role-assignments/).
Há ainda a variável do executor, que atribui automaticamente a quem rodou o
workflow. **O papel é resolvido no momento da instanciação, não no template.**

**Prazo.** Prazos dinâmicos ancorados na data de início do run, na data de
vencimento do run, no momento em que uma tarefa específica é marcada, ou em um
campo de data do formulário, segundo
[Dynamic Due Dates for Tasks](https://www.process.st/help/docs/dynamic-due-dates/).

**Cumprimento.** É o único caso encontrado que publica os 3 elementos de uma
taxa: os estados, o tempo médio e a janela de apuração. O Reports Dashboard
acompanha tarefas atrasadas, contadas como o número de tarefas além do prazo
dentro de um run, segundo
[Reports Dashboard in Process Street](https://www.process.st/help/docs/reports/).
O Workflow Dashboard agrega em quatro estados, no prazo, vencendo em breve,
atrasado e sem prazo, mais tempo médio de conclusão, e a doc registra que essas
estatísticas se baseiam nos **1.000 runs mais recentes** daquele workflow,
segundo
[Process Street's Workflow Dashboard](https://www.process.st/help/docs/workflow-dashboard/).

**Atraso na interface.** A data vencida fica vermelha na lista principal de
tarefas do run, segundo a página de Reports citada acima.

### 3.2 CMMS: a rotina como plano que gera ordem

Manutenção preventiva resolve o mesmo problema de rotina com outro vocabulário,
e a separação também é explícita: existe um **plano de manutenção preventiva**,
que é o template com a cadência, e ele **gera ordens de serviço**, que são as
instâncias.

O gatilho da cadência não é só calendário: pode ser tempo, leitura de medidor
como horas de operação, ou condição, segundo
[How to Create a Preventive Maintenance Schedule](https://limblecmms.com/learn/preventive-maintenance/schedule/).
Ordens recorrentes podem ser configuradas por intervalo de tempo, uso ou
condição, segundo
[Work Order Management](https://www.getmaintainx.com/use-cases/work-order-management).

**Cumprimento é o conceito central desta categoria**, e tem nome próprio:
schedule compliance, definida como comparar as datas reais de conclusão das
ordens com as datas em que deveriam ter sido concluídas, segundo
[6 CMMS Reports to Help You Run Leaner Maintenance](https://www.getmaintainx.com/blog/6-cmms-reports-to-help-you-run-leaner-maintenance).
A mesma fonte nomeia dois relatórios operacionais: "created vs. completed work
orders", para medir aderência à agenda, e "on-time vs. overdue", para avaliar
eficiência da equipe, com recomendação de leitura semanal ou diária.

Detalhe de vocabulário que vale registrar: a mesma fonte diz que uma ordem de
serviço deve conter "names **or roles** of individuals responsible". Papel
aparece como categoria de responsável, ao lado de pessoa.

### 3.3 Execução de operação em rede de unidades

Categoria voltada a equipes de linha de frente em muitas unidades, e o conceito
descrito bate quase termo a termo com "motor de rotina". Uma lista de execução
de operação é definida como lista de tarefas específica por papel e limitada no
tempo, que confirma que os padrões operacionais do dia foram cumpridos, com cada
tarefa atribuída a um papel e com uma janela de conclusão, segundo
[The Operations Execution Checklist for Franchise and Multi-Unit Brands](https://www.xenia.team/articles/operations-execution-checklist).

Três elementos dessa fonte:

- **Atribuição por papel, não por pessoa.** As tarefas são atribuídas por papel
  e migram automaticamente para quem ocupa a posição no momento.
- **Taxa de cumprimento como indicador antecedente.** Painéis de conformidade
  mostram taxa de conclusão diária, semanal e mensal, por unidade e por papel.
- **Visão por template para o mesmo evento.** Atribuição de template por papel
  faz gerente, gerente regional e auditor verem conjuntos de perguntas
  diferentes sobre a mesma unidade.

**Ressalva sobre esta subseção.** As páginas citadas aqui são material de
marketing e de conteúdo do fabricante, não documentação de produto nem
referência de API. Descrevem o conceito com precisão útil, e **não provam como o
dado é modelado**. Tratar como vocabulário, não como contrato.

### 3.4 Software clínico: o que não encontrei

Procurei checklist de rotina embutido em software de gestão de clínica médica e
odontológica, em documentação de fabricante. **Não encontrei.** A busca em
domínios de fabricantes de gestão odontológica devolveu páginas de agenda,
prontuário, prescrição e notificação, e a única aproximação foi notificação
recorrente em intervalo definido. Nenhuma página primária descreveu checklist
diário de abertura ou fechamento, atribuição por papel, ou taxa de cumprimento
de rotina.

Registro isto como resultado, não como lacuna de esforço: **na amostra de
fabricantes que este ambiente conseguiu alcançar, rotina operacional medida não
apareceu como recurso documentado de software clínico.** Uma sessão com acesso
de rede mais amplo deve refazer esta busca antes de tratar a ausência como
conclusão.

---

## 4. Padrões observados

Descrição do que a leitura mostrou. Sem recomendação.

**Sobre template versus instância, o achado central.** Nas oito ferramentas
horizontais, template e recorrência quase nunca são a mesma entidade, e quase
nunca a instância sabe de onde veio. Só a Linear publica no schema o campo que
liga a instância ao template que a gerou, `Issue.recurringIssueTemplate`, e só
ela permite filtrar issues por esse campo. Na Asana existe template de tarefa
completo, com receita e datas relativas, e **não existe elo de volta**. No
Todoist não existe sequer uma segunda linha: a tarefa é uma só e a data avança.

**Três lugares diferentes onde a regra de recorrência pode morar**, e cada
ferramenta escolheu um:

1. **Dentro da instância**, como campo. Todoist, com a regra em texto natural
   no campo `string` do objeto `Due`. ClickUp, como configuração da tarefa.
2. **Dentro do template**, como atributo dele. Notion, em que o template de
   database recebe a opção Repeat e passa a se copiar.
3. **Fora dos dois**, em uma camada de automação. Monday, com a receita "Every
   time period". Trello, com Card Repeater ou comando de calendário do Butler.

**Três momentos diferentes de materialização**, e a escolha muda o que é
possível medir:

- **Ao concluir a anterior.** Todoist, Height, e ClickUp na configuração padrão.
  Rotina não cumprida não gera instância nova, então não há o que contar como
  falha.
- **Na data, por agenda.** Notion, Monday, Trello, ClickUp com "On Schedule", e
  Linear, que cria a próxima quando a anterior vence.
- **Por chamada explícita.** Asana, com `instantiateTask`, sem agenda nenhuma.

**Ninguém encontrado faz retroativo.** A única afirmação primária explícita
sobre isso é do ClickUp, que registra que tarefas recorrentes não criam
instâncias no passado. Nenhuma outra doc primária alcançada afirma o contrário.

**Propagação de mudança do template divide as duas famílias.** Nas ferramentas
horizontais em que consegui resposta primária, o template é cópia de partida e a
instância segue independente: a Linear diz explicitamente que mudanças no
template não afetam as issues recorrentes já criadas. No software de
procedimento operacional, é o oposto: o Process Street propaga a mudança para as
execuções ativas, com escolha entre empurrar para todas ou deixar cada uma
atualizar.

**Atribuição por papel: 0 das 8 ferramentas horizontais, contra recurso nomeado
nas de procedimento operacional.** Nas oito horizontais, não encontrei papel em
nenhuma: o que existe é
pessoa, seja como assignee, como coluna People, como propriedade Person, ou como
campo personalizado do tipo `people` na Asana. Nas ferramentas de procedimento
operacional, papel é recurso nomeado, resolvido no momento da instanciação.

**Medir cumprimento: em 6 das 8 ferramentas horizontais não encontrei doc
primária de relatório de taxa de cumprimento no período.** Linear tem os ingredientes no schema, `dueDate`,
`completedAt` e filtro por template, sem agregação pronta documentada. Todoist
mede volume contra meta, não aderência a uma rotina. Do outro lado, "schedule
compliance" e "on-time vs. overdue" são relatórios nomeados no vocabulário de
CMMS, e o Process Street publica os quatro estados e o tempo médio de conclusão.

**Exibição de atraso, onde houve fonte primária.** Trello usa faixa de tempo com
três cores, cinza, amarelo e vermelho, com o vermelho durando 24 horas a partir
do vencimento. Monday condiciona a leitura de "no prazo" à ligação entre coluna
de data e coluna de status, pelo Deadline Mode. Process Street pinta a data de
vermelho na lista do run. **Nenhuma fonte primária alcançada descreveu contagem
de dias de atraso como número exibido.**

---

## 5. O que isto obriga a decidir

Perguntas de modelagem que a pesquisa deixou em aberto. Ficam sem resposta aqui
de propósito.

1. **A regra de recorrência é entidade própria, campo do template, ou campo da
   instância?** As três formas existem no mercado, e cada uma foi adotada por
   pelo menos uma ferramenta.

2. **A instância guarda ponteiro para a regra que a gerou?** Só a Linear faz
   isso entre as oito. Sem esse elo, não existe "taxa de cumprimento desta
   rotina", só "taxa de cumprimento de tarefas".

3. **Quando a instância é materializada: na conclusão da anterior, na data por
   job, ou sob demanda?** A escolha decide se rotina não cumprida deixa rastro.
   Materializar ao concluir significa que o dia pulado não gera linha nenhuma.

4. **Rotina não cumprida gera instância vencida, ou não gera nada?** Nenhuma
   ferramenta alcançada faz retroativo. Se cumprimento vai ser medido, o
   denominador precisa vir de algum lugar, e "instâncias que deveriam existir"
   não é o mesmo conjunto que "instâncias que existem".

5. **Mudança no template propaga para instâncias abertas?** As duas famílias
   escolheram lados opostos, e o Process Street mostra que, se propagar, é
   preciso decidir também **quem dispara a propagação**, todas as instâncias de
   uma vez ou uma a uma.

6. **Existe entidade Papel, ou papel é só um rótulo sobre pessoa?** E se existir,
   **quando o papel resolve para uma pessoa**: no momento de gerar a instância,
   como no Process Street, ou no momento em que alguém abre a lista.

7. **O que conta como "cumprida no prazo"?** Pela data sozinha, como na Asana e
   na Linear, que têm `completed_at` e `due_on`, ou por uma configuração de qual
   estado conta como concluído, como no Deadline Mode do Monday.

8. **A janela de cumprimento é um instante ou um intervalo?** Os nove tipos de
   evento do NexClin geram tarefa a partir de um fato do dia, e o vocabulário de
   execução de operação usa "janela de conclusão", não data de vencimento.

9. **Checklist dentro da tarefa é entidade, ou é sub-tarefa?** A Linear não tem
   checklist e usa sub-issue. A Asana coloca `subtasks` dentro da receita do
   template. O ClickUp tem template de checklist nomeado. O Trello é o único em
   que o item de checklist carrega prazo e responsável próprios.

10. **Atraso se exibe como faixa de tempo ou como contagem de dias?** Nenhuma
    fonte primária alcançada exibe número de dias. Se o produto exibir, é
    decisão sem precedente documentado nesta amostra.

11. **Qual é o denominador da taxa de cumprimento, e sobre qual janela?** O
    Process Street responde isso com um corte explícito, os 1.000 runs mais
    recentes por workflow. É a única definição de janela encontrada com número.

12. **A medição é por rotina, por pessoa, por papel, ou por unidade?** Os
    painéis de execução de operação cortam por unidade e por papel ao mesmo
    tempo. As ferramentas horizontais alcançadas cortam por responsável.
