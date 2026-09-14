# 024 · Perfil operacional: a secretária opera a clínica

> **Regra viva.** Nasce antes da execução, guia a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 12/09/2026:** especificada, nada implementado. Alvo: **Lovable e
> stack nova**, pela exceção nomeada no Princípio IV da constituição (2.1.0).
> O que é de tela está marcado como faixa C e sobe pela mesma exceção.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Origem:** ditado pelo Arthur em 11/09/2026 depois de criar o perfil da
> secretária de uma clínica fundadora, e interrogado em 4 rodadas. Fatos
> conferidos na conta `maria@lancamento.com` e no código da Lovable.

---

## 1. O problema

O perfil `operacional` nasce com um painel de três cartões vazios ("Minhas
tarefas do dia", "Meus leads ativos", "Consultas de hoje") e com o mesmo menu
do médico, menos o financeiro. O escopo `own` que a permissão promete só é
aplicado nesse painel: em Tarefas, Atendimentos e Consultas a secretária vê e
edita tudo da clínica, como o médico, e a tela de Consultas ainda mostra os
totais "Orçado" e "Vendas" para quem tem financeiro `none`. Não existe botão
para assumir uma tarefa aberta, `tasks.responsible` é texto e 73% aponta para
setor (censo de 05/09, regra 022), e nada mede quem executa o quê. O resultado
é que o médico continua gerenciando a própria agenda e o funil, que é o
trabalho que se queria tirar dele, e o dono não tem como saber quem na
recepção está produzindo.

## 2. Requisitos

### O que a secretária opera

- **FR-001** · faixa **B**
  A secretária **MUST** operar a fila do dia (consultas) e o funil
  (atendimentos) inteiros da clínica: cria a consulta, delega o médico, move o
  lead. O médico **MUST** poder ler tudo isso sem precisar operar.
  *Porquê:* colocar o médico para gerenciar a própria agenda entrega mais
  trabalho a quem deveria estar atendendo. A distribuição entre médicos é por
  preferência do paciente e por disponibilidade, e quem tem essa informação na
  mão é a recepção.

- **FR-002** · faixa **A**
  Em consulta, o **responsável** é quem agendou; o **médico** é o delegado.
  As duas colunas **MUST** referenciar `team_members`, em coluna nova ao lado
  do texto, que fica.
  *Porquê:* `appointments.doctor` e `appointments.responsible` são texto livre.
  Referência é o que permite "editar só o meu", contar produtividade e
  entregar mensagem. O texto não é migrado pela razão registrada na regra 022:
  não está errado, e a migração de verdade é da stack nova.

### Escopo: vejo tudo, edito só o meu

- **FR-003** · faixa **A**
  Para `tarefas` e para consultas, o escopo `own` **MUST** significar "vê
  tudo da clínica, edita só o que é seu". Para `leads`, o perfil operacional
  **MUST** nascer com `all`.
  *Porquê:* a fila só funciona se todo mundo vê a fila. Editar só o próprio
  evita que duas secretárias remarquem a mesma consulta sem se ver. Leads
  passa a `all` porque o funil é da recepção (FR-001), e lead cujo responsável
  é o médico ela precisa mover.

- **FR-004** · faixa **A**
  Na consulta, **status** (confirmada, compareceu, realizada, não compareceu,
  cancelada) e **fechamento** (a venda) **MUST** ser editáveis pelo responsável
  **e** pelo médico da consulta. **Data, horário e troca de médico** **MUST**
  ser editáveis só pelo responsável e pelo master.
  *Porquê:* data e médico são a delegação, e são da secretária. O que acontece
  na sala é do médico: ele marca que atendeu e fecha a venda na cadeira.

- **FR-005** · faixa **C**
  Os totais agregados da tela de Consultas ("Orçado", "Vendas") **MUST**
  aparecer só para quem tem `relatorios_vendas` em `all`. O valor por linha
  **MUST** continuar visível para quem lança.
  *Porquê:* a secretária digita o valor da venda e precisa vê-lo. A soma da
  clínica é outra coisa, e aparecia para financeiro `none` (visto na tela em
  12/09). Mesma lógica do dashboard Simplificado.
  *Onde:* a tela é `src/pages/Acompanhamento.tsx`, rota `/acompanhamento`,
  módulo `acompanhamento`; `Consultas.tsx` existe e não tem os totais
  (conferido em 13/09). **Entregue em 14/09**, commit `a7f488e` da Lovable.

- **FR-006** · faixa **B**
  O perfil operacional **MUST** nascer com anamnese `full`: vê o conteúdo das
  respostas.
  *Porquê:* a secretária cobra a anamnese e confere se foi preenchida direito,
  para alertar o paciente sobre pontos antes da consulta. O rótulo "Apenas
  status" continua disponível para o dono que quiser restringir, e passa a
  ser aplicado de fato. Era só rótulo até 14/09; desde o commit `a7f488e` da
  Lovable, `useCanViewAnamnesis` lê a permissão de módulo: `full` vê o
  conteúdo, `status_only` só o estado, `responsible_only` mantém a regra do
  profissional responsável.

### Assumir tarefa

- **FR-007** · faixa **A**
  Uma tarefa **sem responsável** **MUST** poder ser assumida por qualquer
  membro com login, por um botão. Tarefa com responsável **MUST NOT** ser
  assumida por outro: master e gerencial reatribuem.
  *Porquê:* é o "prontificar-se" pedido em 11/09: a pessoa se coloca na
  tarefa aberta, e isso vira dado de quem executa.

- **FR-008** · faixa **A**
  Quem assumiu **MUST** poder devolver, e assumir e devolver **MUST** ficar
  registrados: quem, quando, de quem para quem.
  *Porquê:* sem o registro de devolução, "tarefa assumida" vira medida que se
  infla. O registro é o que alimenta a produtividade.

- **FR-009** · faixa **A**
  Tarefa **MUST NOT** ser apagada por ninguém: conclui-se ou cancela-se, com
  registro.
  *Porquê:* tarefa apagada some da produtividade, e a medida deixa de ser
  confiável no dia em que alguém descobre isso. Mesmo espírito do FR-004 da
  regra 018 para lead.

- **FR-010** · faixa **A**
  Assumir um item de recall **MUST** criar uma tarefa do tipo novo
  `recall_paciente`, com quem assumiu como responsável e o paciente ligado.
  *Porquê:* recall não é gravado em lugar nenhum, a tela calcula na hora; não
  há linha para assumir. Criar tarefa respeita o FR-001 da regra 020 (nenhuma
  tabela paralela de eventos). O tipo é novo porque `recaptacao_*` é
  vocabulário de funil, de lead que não fechou, e recall é paciente atendido
  que não voltou; misturar os dois estraga a contagem e o relatório.

### Produtividade

- **FR-011** · faixa **A**
  A produtividade **MUST** contar quatro medidas por membro e por período:
  tarefas concluídas no prazo, tarefas assumidas, consultas agendadas (como
  responsável), leads convertidos (como responsável).
  *Porquê:* são as quatro que o banco já permite contar hoje (`completed_at`,
  `due_date`, o registro do FR-008, `appointments.responsible`,
  `lead_history`). "Nota de feedback" e "eficiência" não têm fonte em tabela
  nenhuma e ficam para regra própria quando existir a nota.

- **FR-012** · faixa **A**
  Cada tarefa concluída no prazo **MUST** valer o **peso do seu tipo**,
  configurado pelo dono em Configurações, com padrão 1 para todos os tipos. A
  pontuação é a soma dos pesos.
  *Porquê:* tarefas de dificuldade diferente não podem valer o mesmo, e quem
  cria a tarefa não deve escolher quanto ela vale, senão a medida se infla
  pelo mesmo caminho da devolução. Peso por tipo é uma tabela pequena que o
  dono mexe uma vez.

- **FR-013** · faixa **C**
  O ranking **MUST** listar todo membro da clínica, médicos inclusive, ser
  visível a todo membro, e ser filtrável por função (`team_members.role`).
  Aparece no painel do dono e no relatório de produtividade.
  *Porquê:* as quatro medidas contam para quem executa, e médico que assume
  tarefa conta igual. Se a comparação entre funções ficar injusta, o dono
  filtra. Ver o próprio número é o que faz a medida mover comportamento.

### O painel

- **FR-014** · faixa **C**
  O perfil operacional **MUST** ter painel próprio, alimentado pelo mesmo
  banco, sem nenhum valor financeiro, com estes blocos nesta ordem: (1) fila
  do dia, todas as consultas de hoje por horário, com médico e estado da
  anamnese, com seletor de médico quando houver mais de um; (2) minhas tarefas
  vencidas e de hoje; (3) leads com cadência vencida (FR-001 da 018); (4)
  mensagens não lidas (regra 023, seção 8); (5) tarefas sem dono, com botão
  assumir; (6) recalls vencidos, contagem com link.
  *Porquê:* a ordem é a prioridade de quem abre a tela às 8h, ditada em
  11/09. O bloco 1 é o FR-004 da regra 020 visto pela secretária. Dinheiro
  não entra porque o painel respeita a permissão de módulo, sem exceção.

- **FR-015** · faixa **B**
  A escolha entre painel Completo, Simplificado e Sem acesso **MUST**
  continuar sendo por pessoa, feita pelo dono ao criar ou editar o membro.
  Simplificado **MUST NOT** mostrar dinheiro em nenhum bloco.
  *Porquê:* o dono decide quem vê faturamento, e às vezes só quem assume a
  gestão financeira vê. O mecanismo já existe no diálogo de equipe (código
  lido, não provado na tela); o requisito é garantir que Simplificado não
  vaze valor.

## 3. O que muda no banco

| Objeto | Mudança |
|---|---|
| `tasks.responsible_member_id` | coluna nova, `uuid` anulável, referência a `team_members(id) ON DELETE SET NULL`. O texto `responsible` fica. Assumir grava as duas (id e nome); devolver zera o id e o nome. Já registrada como emenda na 020 (FR-002) e na 022 |
| `appointments.responsible_member_id`, `appointments.doctor_member_id` | mesma forma. A tela de consulta grava as duas colunas ao criar e ao trocar médico; o texto fica para compatibilidade com o que já existe |
| auditoria de `tasks` e `appointments` | o trigger de `data_audit_log` da migração de 25/08, que hoje cobre `patients`, passa a cobrir `tasks` e `appointments`. É o que registra assumir, devolver, reatribuir, mudar data e trocar médico, com `previous_state`. **Nenhuma tabela nova de histórico** |
| `tasks` tipo novo | `recall_paciente` entra na lista de tipos aceitos (`src/lib/tiposDeTarefa.ts` na Lovable; `CHECK` ou enum onde houver) |
| `business_rules.task_type_weights` | `jsonb` novo, `{tipo: peso}`, padrão `{}` lido como 1 para todo tipo ausente. Mesma forma de `patient_required_fields` |
| `tasks` `DELETE` | policy de `DELETE` removida para `authenticated`; cancelar é `UPDATE` de `status` |
| policies de escopo | **declaradas aqui e não construídas na Lovable.** O "edito só o meu" do FR-003 e o FR-004 são checados no front; a policy correspondente (`UPDATE` em `tasks` só quando `responsible_member_id` é o meu ou sou master; `UPDATE` de `date` e `doctor_member_id` em `appointments` só pelo responsável ou master) é escrita na stack nova junto com o FR-011 da regra 021. Na Lovable fica declarado "escopo só no front" |
| `team_members.permissions` padrão | `operacional` passa a `leads: all`, `anamnese: full`, `tarefas: own`, `acompanhamento: own`, com `own` no sentido do FR-003 |

## 4. Premissas

- `team_members.user_id` está preenchido para todo membro que loga. Assumir
  grava `responsible_member_id` a partir do `team_members` do usuário logado,
  e quem não tem `team_members` (o dono das clínicas de agosto, ver a
  migração de 25/08) não consegue assumir até a correção.
- O peso por tipo é lido na hora da soma, não gravado na tarefa. Mudar o
  peso muda o passado, e isso é aceito: é o dono recalibrando a régua, e a
  auditoria de `business_rules` mostra quando.
- "No prazo" é `completed_at::date <= due_date`, no fuso do Brasil, com a
  função de data local que já existe (`dataLocal.ts`).

## 5. Dependências

- **Antes:** regra 023, seção 8, para o bloco de mensagens e o botão "falar
  com". Sem ela o painel nasce com cinco blocos e o sexto entra depois.
- **Antes:** a issue #50 (segundo usuário na clínica de teste). Sem ele não se
  prova "vejo tudo, edito só o meu", nem assumir, nem ranking.
- **Não espera:** o FR-011 da regra 021. A policy de escopo é declarada na
  seção 3 e fica para a stack nova, junto com a cascata.
- **Depende desta:** a regra 025 usa `responsible_member_id` e
  `doctor_member_id` para importar consultas e tarefas com pessoa casada.
- **Conflito resolvido:** a 022, FR-005, dizia que a migração de
  `responsible` não roda na Lovable. Continua não rodando: aqui entra coluna
  nova e o texto não é tocado. Emenda registrada na 022 em 12/09.

## 6. Como se prova que funciona

1. Com Maria (operacional) e o médico logados: Maria cria uma consulta e
   delega ao médico; ele vê a consulta na fila do dia e não consegue mudar
   data nem médico; consegue marcar "realizada" e lançar a venda.
2. Maria vê todas as tarefas da clínica; só edita as que assumiu ou que lhe
   foram atribuídas. Tenta editar a do médico: recusada na tela. **Na Lovable,
   a API aceita, e fica registrado como "escopo só no front".**
3. Tarefa sem dono: botão assumir aparece; depois de assumir, some para os
   outros e aparece "devolver" para Maria. `data_audit_log` tem as duas linhas.
4. Tarefa com dono: nenhum botão de assumir para terceiros; master reatribui.
5. Nenhum caminho apaga tarefa; cancelar grava `status` e auditoria.
6. Recall vencido: assumir cria tarefa `recall_paciente` com paciente ligado
   e Maria como responsável; a tela de recall mostra que já tem dono.
7. Painel de Maria: seis blocos na ordem do FR-014, nenhum valor em reais,
   seletor de médico presente quando a clínica tem dois.
8. Tela de Consultas de Maria: "Orçado" e "Vendas" não aparecem; o valor da
   linha aparece.
9. Dono muda o peso de `recall_paciente` para 3: a pontuação de Maria muda
   na próxima leitura, e o ranking reordena.
10. Ranking visível para Maria, com médicos na lista, e filtro por função.
11. Automatizado, na Lovable, em `src/lib/`: `escopo.ts` (quais campos cada
    membro edita numa consulta; se uma tarefa pode ser assumida ou devolvida
    por quem), `painelOperacional.ts` (a ordem e o conteúdo dos seis blocos a
    partir dos dados brutos), `produtividade.ts` (pontuação e ranking a partir
    de tarefas, pesos e `completed_at`). **O que não cobre:** policy, trigger
    de auditoria e a tela.

## 7. A decisão que falta, e precisa do Arthur

**Nenhuma.** Fechadas em 11/09 e 12/09 (grilling, rodadas 1 a 5): escopo (c),
leads `all`, "meu" é o responsável, status e fechamento também do médico,
anamnese `full`, assumir só sem dono, devolver com registro, tarefa não se
apaga, tipo `recall_paciente`, quatro medidas, peso por tipo com padrão 1,
ranking para todos, painel na ordem 1, 3, 4, 6, 2, 5 da proposta original,
coluna nova em vez de migração. Fora desta versão e com dono para virar regra
própria: bloqueio de agenda do médico, avaliação por nota, escala júnior a
sênior, responsável por setor como entidade (pergunta da 022).
