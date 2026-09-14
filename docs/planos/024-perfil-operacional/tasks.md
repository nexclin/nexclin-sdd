---
description: "Lista de tarefas da frente 024, perfil operacional"
---

# Tarefas: a secretária opera a clínica

**Entrada:** [`plan.md`](./plan.md) e [`spec.md`](./spec.md), que é link para a
regra viva.

## Formato: `[ID] [P?] [Fase] Descrição com o caminho do arquivo`

- **[P]**: pode rodar em paralelo, arquivo diferente e sem dependência aberta.
- **[Fase]**: `[F0]` a `[F6]`, as fases do plano.

> **Aqui não há user story, e isso é de propósito.** A
> [ADR 0005](../../adr/0005-bifurcar-o-to-spec.md) removeu user story do formato
> deste projeto. O agrupamento é por **fase do plano**, que é o que tem aceite
> próprio pela alínea (h).

> **Nenhuma tarefa virou issue ainda.** O `docs/regras/README.md` diz que tarefa
> vira issue quando entra em execução. Quando a Fase 0 começar, o
> `speckit-taskstoissues` abre as da F0 e da F1, e o número entra entre
> parênteses depois do ID, como na 021.

> **Os três portões são parada dura.** Tarefa depois de um portão **não começa**
> antes de a condição sair. O Portão 1 é diferente dos outros: ele não bloqueia
> construção, **bloqueia aceite**. Sem duas pessoas na clínica de teste, nenhuma
> prova da seção 6 fecha.

> **Teste vermelho antes do código** em toda tarefa de `src/lib/`. A tarefa do
> teste vem antes da tarefa da função, e a função só começa quando o teste
> falhou na frente de quem escreve.

---

## Fase 0 · Conferir o banco antes de acreditar nele

**Objetivo:** responder quatro perguntas de uma ida só ao editor, e derrubar ou
confirmar a premissa 1 da regra.

**Aceite:** o que voltar bate com a seção 3 da regra. Se divergir, **a
divergência é o achado** e a regra se corrige antes de T006.

- [ ] T001 [F0] Escrever o bloco de conferência em `docs/ponte/024-censo-operacional.sql`, contando por clínica os `team_members` com `user_id` nulo e os `profiles` que logam sem linha em `team_members`. É a **premissa 1** da regra e decide o Portão 3
- [ ] T002 [P] [F0] Escrever no mesmo arquivo a consulta a `pg_trigger` que lista em quais tabelas o trigger `audita_mudanca_de_dado` está ligado no banco ao vivo. Esperado: `patients` e as cinco de configuração. **Ele não está no clone da Lovable**: chegou por bloco de SQL, e a Fase 1 só o estende se ele existir
- [ ] T003 [P] [F0] Escrever no mesmo arquivo a consulta a `information_schema.check_constraints` e `pg_constraint` sobre `tasks.type`. Decide se `recall_paciente` exige `ALTER` (T012) ou só entra na lista do front (T028)
- [ ] T004 [P] [F0] Escrever no mesmo arquivo a listagem de `pg_policies` para `tasks` e `appointments`. Esperado em `tasks`: uma policy só, `FOR ALL TO authenticated`, de 22/03
- [ ] T005 [F0] Rodar o bloco no editor de SQL da plataforma, um trecho por vez. O Arthur clica `Run`; o agente para na barreira
- [ ] T006 [F0] Registrar o resultado em `docs/historico/2026-09-NN-censo-operacional.md`, inclusive o que não deu para conferir, e corrigir a seção 3 da regra no mesmo commit se houver divergência

**Ponto de conferência:** premissa 1 confirmada ou derrubada, trigger localizado,
`CHECK` conhecido, policies listadas.

---

## PORTÃO 1 · O segundo usuário · issue #50

**Bloqueia aceite, não construção.** F1 e F2 podem ser escritas antes; nenhuma
fecha antes de haver Maria e um médico logando na mesma clínica de teste.

- [ ] T007 [F0] Cobrar do Arthur o segundo usuário da issue #50, e registrar em `docs/historico/` em que dia passou a existir, com o e-mail de login e o `team_members.id` de cada um. **Sem senha no arquivo**, alínea (g)

---

## Fase 1 · O que fica gravado · faixa A · Lovable e stack nova

**Objetivo:** FR-002, a parte de banco de FR-007 a FR-010, e a parte de banco do
FR-012. É a fase que atravessa intacta para outubro.

**Aceite independente:** o bloco de T001 a T004 rodado de novo mostra as três
colunas, os dois triggers e as três policies. Mais o `DELETE` recusado **com
controle positivo**: o `UPDATE` de `status` na mesma tarefa passa.

### Banco, e ele vem primeiro

- [ ] T008 [F1] Escrever a migração `supabase/migrations/20260913010000_perfil_operacional_colunas_e_auditoria.sql`, bloco 1: `tasks.responsible_member_id uuid` anulável, `REFERENCES team_members(id) ON DELETE SET NULL`, com `COMMENT` dizendo que o texto `responsible` fica e as duas gravam juntas
- [ ] T009 [P] [F1] No mesmo arquivo, bloco 2: `appointments.responsible_member_id` e `appointments.doctor_member_id`, na mesma forma, com `COMMENT` dizendo que responsável é quem agendou e médico é o delegado
- [ ] T010 [P] [F1] No mesmo arquivo, bloco 3: `CREATE TRIGGER tasks_audita_mudanca` e `appointments_audita_mudanca`, `AFTER UPDATE`, chamando `audita_mudanca_de_dado`, na forma exata dos de `20260827030000_auditoria_nas_tabelas_de_configuracao.sql`. **Nenhuma tabela nova de histórico**
- [ ] T011 [P] [F1] No mesmo arquivo, bloco 4: `business_rules.task_type_weights jsonb NOT NULL DEFAULT '{}'`, na forma de `patient_required_fields` (`20260324033818`), com `COMMENT` dizendo que tipo ausente lê como 1
- [ ] T012 [F1] No mesmo arquivo, bloco 5, **só se T003 mostrou `CHECK`**: `recall_paciente` entra na lista aceita de `tasks.type`. Se não há `CHECK`, o bloco fica como comentário dizendo por quê
- [ ] T013 [F1] No mesmo arquivo, bloco 6: `DROP POLICY "Users can manage tasks in their clinic"` e três policies novas em `tasks`, `SELECT`, `INSERT` e `UPDATE`, com o **mesmo predicado de clínica** da policy de 22/03. **Sem `DELETE`.** Cancelar é `UPDATE` de `status`
- [ ] T014 [F1] Escrever a reversão, bloco a bloco, logo abaixo de cada um, em comentário. Policy de `tasks` é onde erro tranca a lista de tarefas da clínica inteira
- [ ] T015 [F1] Copiar a migração para `docs/ponte/aplicacao-024-fase1/b1-colunas-triggers-pesos-policies.sql`, com a conferência de cada bloco em arquivo separado, na forma de `docs/ponte/aplicacao-021-fase1/`
- [ ] T016 [P] [F1] Rodar o hook `.claude/hooks/guarda-constituicao.mjs` sobre a migração: sem RLS ausente, sem `USING(true)`, sem caminho que define senha, sem segredo versionado
- [ ] T017 [F1] Conferir que o export do banco está feito e com cópia em nuvem, por `docs/seguranca/registro-exports-banco.md`, antes de aplicar
- [ ] T018 [F1] Aplicar os blocos no editor de SQL e conferir cada um. O Arthur clica `Run`

### Aceite, e é onde a fase fecha

- [ ] T019 [F1] Rodar de novo o bloco de T001 a T004 e conferir: três colunas novas, dois triggers novos, três policies em `tasks` e nenhuma `DELETE`
- [ ] T020 [F1] Rodar no editor, em `BEGIN` e `ROLLBACK` com `SET LOCAL ROLE authenticated` e `request.jwt.claims` de Maria: `DELETE FROM tasks WHERE id = <uma da clínica>` devolve zero linha. **Controle positivo no mesmo bloco:** `UPDATE tasks SET status = 'cancelada'` na mesma linha devolve uma
- [ ] T021 [F1] Item que não deu para provar fecha como **"código lido, não comportamento provado"** e continua aberto

**Ponto de conferência:** "quem fez" passa a ser dado gravado, e tarefa deixa de
poder sumir.

---

## Fase 2 · Vejo tudo, edito só o meu · faixa A e C · Lovable

**Objetivo:** FR-001, FR-003, FR-004, FR-005, FR-006.

**Aceite independente:** provas 1, 2 e 8 da seção 6, com Maria e o médico
logados. **A prova 2 fecha com a frase literal "escopo só no front"**: a API da
Lovable aceita o `UPDATE` que a tela recusa, e isso é o esperado até a stack
nova.

> Toda tarefa em `../nexclin-lovable/` segue `docs/ponte/ponte-inversa.md`:
> `git pull` antes, `main`, nunca `--force`, `npx tsc --noEmit -p tsconfig.app.json`,
> **nunca `npx vite build`**, commit com caminho explícito e push no mesmo
> comando.

### A função, com o teste na frente

- [ ] T022 [F2] Escrever `../nexclin-lovable/src/lib/__tests__/escopo.test.ts` para `camposEditaveisDaConsulta(consulta, quemOlha)`: responsável e master editam `date`, `time`, `doctor_member_id`, `status` e fechamento; médico da consulta edita só `status` e fechamento; qualquer outro edita nada. **Ver falhar**
- [ ] T023 [P] [F2] No mesmo arquivo, `podeEditarTarefa(tarefa, quemOlha)`: responsável, master ou gerencial editam; tarefa automática ninguém edita (herda de `ehAutomatica`); tarefa **sem responsável** não é editável por terceiro, é assumível. **Ver falhar**
- [ ] T024 [F2] Escrever `../nexclin-lovable/src/lib/escopo.ts` até T022 e T023 passarem. `quemPodeEditar` de `tiposDeTarefa.ts` sai, e quem a chamava passa a chamar `podeEditarTarefa`. Rodar `npx vitest run` inteiro: os 20 arquivos existentes continuam verdes

### O padrão do perfil

- [ ] T025 [F2] Em `../nexclin-lovable/src/hooks/usePermissions.ts`, `DEFAULT_PERMISSIONS_BY_LEVEL.operacional` passa a `leads: "all"`, `anamnese: "full"`, `tarefas: "own"`, `acompanhamento: "own"`. Só o padrão muda; membro existente mantém o que o dono gravou em `team_members.permissions`

### As telas

- [ ] T026 [F2] Em `../nexclin-lovable/src/pages/Tarefas.tsx`: a lista mostra a clínica inteira para quem tem `tarefas: own`, e o botão de editar obedece `podeEditarTarefa`. Nenhum filtro por "meu" na consulta ao banco
- [ ] T027 [F2] Em `../nexclin-lovable/src/pages/Acompanhamento.tsx`: ao criar consulta, gravar `responsible_member_id` com o `team_members.id` do usuário logado, além do texto; ao delegar, gravar `doctor_member_id` além do texto. Os campos editáveis vêm de `camposEditaveisDaConsulta`
- [ ] T028 [F2] Na mesma tela, linhas 1965 a 1970: os totais "Orçado" e "Vendas" só aparecem com `relatorios_vendas: "all"`. O valor por linha continua para quem lança
- [ ] T029 [P] [F2] Anamnese: `status_only` passa a esconder o conteúdo das respostas e mostrar só o estado, em `../nexclin-lovable/src/pages/Anamnese.tsx` e onde mais a resposta for lida. Hoje é rótulo que não filtra
- [ ] T030 [F2] Na regra, pela alínea (l) e no mesmo commit de T028: o FR-005 de `docs/regras/024-perfil-operacional.md` nomeia `src/pages/Acompanhamento.tsx`, rota `/acompanhamento`, como a tela dos totais. `Consultas.tsx` existe e não os tem
- [ ] T031 [F2] Gate de tipos: `npx tsc --noEmit -p tsconfig.app.json` limpo. `npm run build` **não** confere tipos
- [ ] T032 [F2] Publicar pelo procedimento de `docs/ponte/ponte-inversa.md`: commit com caminho explícito, push no mesmo comando, `scripts/ponte.sh conferir`, e o Arthur faz o Publish
- [ ] T033 [F2] Procurar um marcador de texto das telas novas dentro do bundle publicado, porque o `conferir` sozinho não prova que o código subiu

### Aceite, e é onde a fase fecha

- [ ] T034 [F2] **Prova 1**, na tela: Maria cria uma consulta e delega ao médico; ele a vê na fila do dia e não consegue mudar data nem médico; consegue marcar "realizada" e lançar a venda. Print do Vinícius
- [ ] T035 [F2] **Prova 2**, na tela: Maria vê todas as tarefas da clínica; edita as suas; tenta editar a do médico e a tela recusa. No editor, o mesmo `UPDATE` como Maria **passa**, e o aceite grava a frase literal **"escopo só no front"**
- [ ] T036 [F2] **Prova 8**, na tela: Maria abre a tela de Consultas; "Orçado" e "Vendas" não aparecem; o valor da linha aparece
- [ ] T037 [F2] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto

**Ponto de conferência:** a secretária opera a fila e o funil inteiros, e só
edita o que é dela.

---

## Fase 3 · Assumir, devolver, cancelar · faixa A · Lovable

**Objetivo:** a parte de tela de FR-007, FR-008, FR-009 e FR-010.

**Aceite independente:** provas 3, 4, 5 e 6. Na prova 3, as duas linhas em
`data_audit_log` conferidas no editor, com `previous_state`.

### A função, com o teste na frente

- [ ] T038 [F3] Em `../nexclin-lovable/src/lib/__tests__/escopo.test.ts`, `podeAssumir(tarefa, quemOlha)`: verdadeiro só quando `responsible_member_id` é nulo e quem olha tem `team_members.id`; falso para tarefa com dono, mesmo para master. E `podeDevolver(tarefa, quemOlha)`: verdadeiro só para o responsável. **Ver falhar**
- [ ] T039 [P] [F3] No mesmo arquivo, `podeReatribuir(quemOlha)`: master e gerencial. **Ver falhar**
- [ ] T040 [F3] Estender `../nexclin-lovable/src/lib/escopo.ts` até T038 e T039 passarem

### As telas

- [ ] T041 [F3] Em `../nexclin-lovable/src/pages/Tarefas.tsx`: botão **assumir** em tarefa sem dono, gravando `responsible_member_id` e `responsible` (o nome) de uma vez; botão **devolver** para o responsável, zerando os dois; **reatribuir** só para quem `podeReatribuir`. O trigger da F1 registra sozinho
- [ ] T042 [F3] Na mesma tela: **nenhum caminho chama `DELETE`**. O que apagava passa a `UPDATE` de `status` para cancelada. Buscar por `.delete(` no arquivo e nos componentes de tarefa que ele importa; cada ocorrência sai
- [ ] T043 [P] [F3] Em `../nexclin-lovable/src/lib/tiposDeTarefa.ts`: `recall_paciente` entra em `TIPOS_MANUAIS` e em `ROTULOS_DE_TIPO` como "Recall de paciente", separado de `recall` (automático) e de `recaptacao_*` (funil)
- [ ] T044 [F3] Em `../nexclin-lovable/src/pages/Recall.tsx`: botão assumir no item vencido cria uma tarefa `type = 'recall_paciente'`, `patient_id` do item, `responsible_member_id` e `responsible` de quem assumiu, `due_date` hoje. A linha do recall mostra "com dono" quando existe tarefa aberta desse tipo para esse paciente
- [ ] T045 [F3] Gate de tipos, `npx tsc --noEmit -p tsconfig.app.json`, e `npx vitest run` inteiro verde
- [ ] T046 [F3] Publicar pelo procedimento da ponte, com `scripts/ponte.sh conferir` e o marcador no bundle

### Aceite, e é onde a fase fecha

- [ ] T047 [F3] **Prova 3**: tarefa sem dono mostra assumir; depois de Maria assumir, some para o médico e mostra devolver para ela. No editor, `data_audit_log` tem as duas linhas (assumir e devolver), com `previous_state`
- [ ] T048 [F3] **Prova 4**: tarefa com dono não mostra assumir para o médico; master reatribui
- [ ] T049 [F3] **Prova 5**: nenhum botão apaga tarefa; cancelar grava `status` e a linha de auditoria. No editor, `SELECT count(*) FROM tasks` da clínica antes e depois é o mesmo número
- [ ] T050 [F3] **Prova 6**: recall vencido assumido cria tarefa `recall_paciente` com paciente ligado e Maria como responsável; a tela de recall mostra que tem dono
- [ ] T051 [F3] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto

**Ponto de conferência:** prontificar-se vira dado, e dado que se devolve fica
registrado.

---

## PORTÃO 3 · O dono sem `team_members`

**Abre com T001.** Se o dono das clínicas de agosto não tem linha em
`team_members`, ele não consegue assumir até a correção, e a prova 3 rodada
com ele lê como "botão não aparece" quando é premissa não atendida.

- [ ] T052 [F3] Levar o número de T001 ao Arthur, com os dois caminhos escritos: migração que cria a linha de `team_members` do dono a partir de `profiles`, ou tela do superadmin. **Não é desta regra decidir.** A decisão vira issue própria e não entra aqui

---

## Fase 4 · Produtividade · faixa A e C · Lovable

**Objetivo:** FR-011, FR-012, FR-013.

**Aceite independente:** provas 9 e 10. Na 9, o peso muda e a pontuação muda na
próxima leitura, sem tocar em tarefa nenhuma.

### A função, com o teste na frente

- [ ] T053 [F4] Escrever `../nexclin-lovable/src/lib/__tests__/produtividade.test.ts` para `pontuacao(tarefas, pesos, periodo)`: só tarefa concluída conta; "no prazo" é `completed_at` em data local menor ou igual a `due_date`, pelo `dataLocal.ts`; cada uma vale o peso do seu tipo; tipo ausente em `pesos` vale 1; concluída fora do prazo vale 0. **Ver falhar**
- [ ] T054 [P] [F4] No mesmo arquivo, `ranking(membros, tarefas, assumidas, consultas, leadsConvertidos, pesos, periodo, filtroDeFuncao?)`: as quatro medidas por membro, ordenado por pontuação, médicos incluídos, filtrável por `team_members.role`. **Ver falhar**
- [ ] T055 [F4] Escrever `../nexclin-lovable/src/lib/produtividade.ts` até T053 e T054 passarem. As fontes são as da regra: `tasks`, `data_audit_log` para assumidas, `appointments.responsible_member_id`, `lead_history`

### As telas

- [ ] T056 [F4] Em `../nexclin-lovable/src/pages/Configuracoes.tsx`: a tabela de pesos por tipo, um número por tipo de `ROTULOS_DE_TIPO`, gravando em `business_rules.task_type_weights`. Padrão visível: 1
- [ ] T057 [P] [F4] Ranking no painel do dono, em `../nexclin-lovable/src/pages/Dashboard.tsx`, lendo `produtividade.ts`, com filtro por função
- [ ] T058 [P] [F4] Ranking no relatório de produtividade, em `../nexclin-lovable/src/pages/relatorios/`, visível a todo membro, com o mesmo filtro. Relatório é por onde o Vinícius opera, e não pode nascer diferente do painel
- [ ] T059 [F4] Gate de tipos e `npx vitest run` verde, e publicar pela ponte

### Aceite, e é onde a fase fecha

- [ ] T060 [F4] **Prova 9**: dono muda o peso de `recall_paciente` para 3; a pontuação de Maria muda na próxima leitura e o ranking reordena. No editor, nenhuma linha de `tasks` mudou, e `data_audit_log` de `business_rules` tem a mudança
- [ ] T061 [F4] **Prova 10**: Maria vê o ranking com médicos na lista, e o filtro por função funciona
- [ ] T062 [F4] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto

**Ponto de conferência:** o dono sabe quem na recepção está produzindo, com
número.

---

## PORTÃO 2 · A seção 8 da regra 023

**Não bloqueia a Fase 5.** O bloco 4 do painel lê a caixa de mensagens que a
seção 8 da 023 especifica e que ainda não existe. A regra 024 já decidiu: o
painel nasce com cinco blocos, e o sexto entra quando a 023 entregar.

- [ ] T063 [F5] Conferir em `docs/planos/023-avisos-e-recados-da-equipe/tasks.md` se a caixa da seção 8 já está entregue. Se sim, T067 entra na mesma passada de T066; se não, o aceite da F5 escreve "cinco blocos, o quarto espera a 023"

---

## Fase 5 · O painel · faixa C · Lovable

**Objetivo:** FR-014, FR-015.

**Aceite independente:** prova 7. Painel de Maria com seis blocos (ou cinco, e
isso fica escrito), nenhum valor em reais, seletor de médico presente quando a
clínica tem dois.

### A função, com o teste na frente

- [ ] T064 [F5] Escrever `../nexclin-lovable/src/lib/__tests__/painelOperacional.test.ts` para `montaPainel(entrada)`: devolve os blocos **na ordem exata do FR-014** (fila do dia, minhas tarefas vencidas e de hoje, leads com cadência vencida, mensagens não lidas, tarefas sem dono, recalls vencidos); a fila do dia vem por horário com médico e estado da anamnese; **nenhum bloco carrega campo em reais**, e o teste percorre cada bloco afirmando isso. **Ver falhar**
- [ ] T065 [F5] Escrever `../nexclin-lovable/src/lib/painelOperacional.ts` até T064 passar. A cadência vencida vem do FR-001 da regra 018; o recall, de `recall.ts`; tarefa sem dono, de `podeAssumir`

### A tela

- [ ] T066 [F5] Em `../nexclin-lovable/src/pages/DashboardOperational.tsx`: os três cartões vazios ("Minhas tarefas do dia", "Meus leads ativos", "Consultas de hoje") saem; entram os blocos de `montaPainel`, com seletor de médico quando `team_members` da clínica tem mais de um médico, e o botão assumir do bloco 5 chamando o mesmo caminho de T041
- [ ] T067 [F5] Bloco 4, mensagens não lidas, **só se T063 disse que a 023 entregou**: lê a caixa da seção 8 e mostra a contagem com link
- [ ] T068 [P] [F5] Em `../nexclin-lovable/src/components/config/ConfigTeamDialog.tsx`: conferir que Completo, Simplificado e Sem acesso continuam por pessoa, e que Simplificado leva ao painel de T066. Hoje é "código lido, não provado na tela"; esta tarefa prova
- [ ] T069 [F5] Gate de tipos e `npx vitest run` verde, e publicar pela ponte

### Aceite, e é onde a fase fecha

- [ ] T070 [F5] **Prova 7**, na tela, pela ótica de Maria às 8h: os blocos na ordem do FR-014, nenhum valor em reais em bloco nenhum, seletor de médico presente na clínica de dois médicos e ausente na de um. **A régua dos 200% é o que fecha esta fase**
- [ ] T071 [F5] Dono troca Maria de Simplificado para Completo e de volta; o painel muda de acordo, e Simplificado não mostra dinheiro em bloco nenhum
- [ ] T072 [F5] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto

**Ponto de conferência:** a secretária abre a tela e vê o dia dela, na ordem em
que ele acontece.

---

## Fase 6 · Fechamento

- [ ] T073 [P] [F6] Atualizar a linha da 024 em `docs/regras/README.md` com o estado real: o que está no ar, o que ficou "escopo só no front", o que espera a 023
- [ ] T074 [P] [F6] Rodar o agente `auditor-multitenant` sobre a migração de T008 a T013 e sobre `escopo.ts`, com a pergunta certa: a policy de escopo declarada e não construída está **declarada em todo lugar onde alguém poderia lê-la como construída**?
- [ ] T075 [P] [F6] Rodar `/speckit-analyze` sobre regra, plano e tarefas, e resolver a inconsistência que ele apontar
- [ ] T076 [F6] Abrir a issue da policy de escopo na stack nova, ligada ao FR-011 da 021, com o texto da seção 3 da regra 024: `UPDATE` em `tasks` só quando `responsible_member_id` é o meu ou sou master; `UPDATE` de `date` e `doctor_member_id` em `appointments` só pelo responsável ou master
- [ ] T077 [F6] Escrever o handoff do dia em `docs/historico/`, com o que ficou aberto dito em voz alta

---

## Dependências e ordem

### Entre fases

- **F0** não depende de nada e **bloqueia F1**.
- **PORTÃO 1** depende de gente, não de código. **Bloqueia todo aceite** de F2 em
  diante, e nenhuma construção.
- **F1** depende de F0. Migração antes de qualquer front: T026, T027 e T041
  gravam colunas que só existem depois de T018.
- **F2** depende de F1 aplicada (T018).
- **F3** depende de F2: `podeAssumir` mora em `escopo.ts`, que nasce em T024, e
  o botão de T041 vive na lista que T026 reorganiza.
- **PORTÃO 3** abre com T001 e só pesa no aceite de F3.
- **F4** depende de F1 (pesos e `responsible_member_id`) e de F3 (assumidas em
  `data_audit_log`). Não depende de F2.
- **PORTÃO 2** não bloqueia F5; decide se T067 entra.
- **F5** depende de F3 (assumir no bloco 5) e de F1. Não depende de F4.
- **F6** depende de tudo que tiver sido feito.

### Dentro de cada fase

- Migração antes de front. **Sempre.**
- Reversão escrita antes de aplicar bloco em produção.
- Teste antes do código, e visto falhar, em toda função de `src/lib/`.
- Aceite na tela antes de fechar a fase, com Maria logada, e print.

### O que roda em paralelo

- T002, T003 e T004 são consultas diferentes no mesmo arquivo. **Rodam em
  série no editor.**
- T009, T010 e T011 são blocos distintos da mesma migração.
- T022 e T023 são funções diferentes no mesmo arquivo de teste.
- T029 não toca `Tarefas.tsx` nem `Acompanhamento.tsx`.
- T043 é `tiposDeTarefa.ts`; T041 e T042 são `Tarefas.tsx`.
- T057 e T058 são telas diferentes lendo a mesma função.
- **F4 e F5 podem andar juntas** depois de F3, por gente diferente: não dividem
  arquivo. Antes de tentar, ler `nx-paralelo`.

**O que NÃO roda em paralelo, e é o erro tentador:** duas fases publicando na
mesma janela. A plataforma tem **um Publish só**, e o Arthur é quem clica. Uma
fase publica e fecha aceite antes de a próxima subir.

---

## Estratégia de entrega

### A primeira entrega que muda o dia da secretária

**F0, F1 e F2.** É o recorte em que Maria passa a operar a fila e o funil
inteiros, e só edita o que é dela. Trinta e sete tarefas, sete delas de aceite.

1. F0 inteira. **Se a premissa 1 cair aqui, o Portão 3 vira item antes de custar
   trabalho.**
2. Portão 1, que é uma pessoa a mais na clínica de teste e não uma implementação.
3. F1 inteira, com o `DELETE` recusado e o `UPDATE` aceito no mesmo bloco.
4. F2 inteira, com as três provas na tela.
5. **PARAR e validar.** Aceite do Arthur, e a validação pela ótica de Maria.

### Depois

F3 é a que gera o dado de produtividade, e vem sozinha. F4 e F5 podem andar em
paralelo depois dela. Cada uma publica e fecha aceite antes da outra subir.

---

## Notas

- `[P]` quer dizer arquivo diferente e sem dependência aberta.
- Commit por tarefa ou por grupo lógico, com caminho explícito e push no mesmo
  comando. `git add -A` é proibido e um hook bloqueia.
- Mudança de comportamento **corrige a regra no mesmo commit**, alínea (l).
- Onde a Lovable aceita no banco o que a tela recusa, o aceite escreve
  **"escopo só no front"**, e não "passou".
- Parar em qualquer ponto de conferência é legítimo. Atravessar portão não é.
