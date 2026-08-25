# Feature Specification: Configurações da clínica

**Feature Branch**: `005-configuracoes-clinica`

**Created**: 2026-08-25

**Status**: Draft

**Input**: Primeira spec da Onda 1, conforme `docs/planejamento/fila-especificacoes.md`. É o substrato: catálogos e regras de negócio que quase toda tela clínica lê.

---

## Por que esta spec vem primeiro

Não é ordem alfabética nem preferência. É **dependência de dado**.

`business_rules.patient_required_fields`, `appointment_required_fields`,
`confirmation_hours`, `followup_days`, `work_saturday`,
`satisfaction_survey_days` e `anamnesis_send_days` são lidos por pacientes,
consultas, tarefas e anamnese. Os catálogos (`channels`, `origins`, `services`,
`payment_methods`, `chart_of_accounts`, `bank_accounts`, `objections`,
`closing_types`, `consultation_types`, `goals`, `acquirers`,
`expense_categories`, `anamnesis_config`) são as listas que todo formulário
oferece.

Sem esse substrato, qualquer módulo posterior escreve cego ou reimplementa
formulário que vai precisar ser refeito.

E há uma segunda razão, que só apareceu ao ler o banco para escrever esta spec.

---

## O achado que muda o desenho: o default de `enabled_modules` está quebrado

**Encontrado em 25/08/2026, por leitura de migração. Não é hipótese.**

A coluna nasce assim, em `20260408034446`:

```sql
enabled_modules jsonb NOT NULL DEFAULT '[]'::jsonb
```

E o trigger que a valida, em `20260725033102`, roda `BEFORE INSERT OR UPDATE` e
começa assim:

```sql
IF jsonb_typeof(NEW.enabled_modules) <> 'object' THEN
  RAISE EXCEPTION 'enabled_modules deve ser um objeto JSON';
END IF;
```

`'[]'` é **array**. O trigger exige **objeto**.

**A consequência é concreta e reproduzível: todo `INSERT` em `plans` que não
informe `enabled_modules` explicitamente falha**, com a mensagem
`enabled_modules deve ser um objeto JSON`. O default da coluna é um valor que a
própria tabela recusa.

Hoje isso não incomoda porque os planos existentes vieram de migração, que
informa o objeto na mão. Incomoda no dia em que alguém criar um plano pela tela.

Três coisas saem daí:

1. **A decisão do BACKLOG já estava tomada, e ninguém percebeu.** O item
   "padronizar `enabled_modules` como `Record<ModuleKey, boolean>`" está lá como
   pergunta aberta. Não é: **o trigger já impõe objeto**. O que falta não é
   decidir, é **alinhar o default**.
2. **É faixa A pela §2.5.** É migração, atravessa intacta para a stack nova, e o
   banco da Lovable migra junto. Corrigir uma vez resolve nos dois lados.
3. **É pré-requisito do editor de planos.** A tela de Planos do T023 ficou de
   leitura em parte por causa desta ambiguidade. Com o default alinhado, ela
   pode escrever.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A clínica configura o que ela oferece e como cobra (Priority: P1)

O administrador abre Configurações e preenche os catálogos que o dia a dia usa:
serviços com preço e custo, formas de pagamento com taxa e prazo, contas
bancárias, plano de contas, canais e origens de captação.

**Why this priority**: sem serviço cadastrado não há o que agendar nem o que
cobrar; sem forma de pagamento não há recebível com taxa e vencimento certos.
É o que transforma o sistema de vazio em operável.

**Independent Test**: cadastrar um serviço, uma forma de pagamento com taxa de
3,5% e prazo de 30 dias, e uma conta bancária; recarregar e conferir que os três
persistiram com os valores exatos.

**Acceptance Scenarios**:

1. **Given** clínica sem catálogo nenhum, **When** o admin cadastra um serviço
   com preço e custo, **Then** ele aparece na lista e persiste após recarregar.
2. **Given** uma forma de pagamento com taxa e prazo, **When** ela for usada em
   um fechamento (módulo 007), **Then** o recebível nasce com o líquido e o
   vencimento calculados por esses valores.
3. **Given** um usuário sem permissão de `configuracoes`, **When** tenta a URL
   direta, **Then** é bloqueado pelo banco, não pela tela.

---

### User Story 2 - As regras de negócio que os outros módulos obedecem (Priority: P1)

O administrador define, em um lugar só: quantas horas antes confirmar a
consulta, em quantos dias fazer o follow-up, se a clínica trabalha sábado, em
quantos dias enviar a pesquisa de satisfação e a anamnese, e quais campos são
obrigatórios no cadastro de paciente e no agendamento.

**Why this priority**: são os parâmetros que a automação de tarefas (008) e as
telas de paciente e consulta leem. Deixá-los para depois significa reescrever
formulário quando eles chegarem.

**Independent Test**: mudar `confirmation_hours` para 2 dias, salvar, recarregar
e conferir que a tela mostra 2 dias; conferir no banco que gravou 48.

**Acceptance Scenarios**:

1. **Given** a regra de confirmação exibida em **dias**, **When** o admin salva
   2, **Then** o banco grava **48** e a tela reexibe 2 na volta.
2. **Given** `patient_required_fields` com `name` e `phone`, **When** o cadastro
   de paciente (006) for usado, **Then** ele exige os dois e nada além.
3. **Given** `work_saturday = false`, **When** uma tarefa cair num sábado,
   **Then** ela é empurrada para o dia útil seguinte.

---

### User Story 3 - O superadmin monta um plano novo pela tela (Priority: P2)

O superadmin cria um plano, escolhe quais das ModuleKeys ele libera, define
limites e preço, e salva. O plano passa a valer como teto para as clínicas que o
assinarem.

**Why this priority**: é o que destrava a cobrança por faixa e o que a tela de
Planos do T023 não faz hoje. Fica em P2 porque depende do default corrigido, e
porque hoje dá para criar plano por migração.

**Independent Test**: criar um plano com três módulos ligados; conferir que
`enabled_modules` gravou objeto com três chaves booleanas; conferir que uma
clínica nesse plano recebe `none` em `my_permission` para os módulos apagados.

**Acceptance Scenarios**:

1. **Given** o default da coluna corrigido, **When** o superadmin cria um plano
   **sem** mexer nos módulos, **Then** ele é criado com `{}` e nenhum módulo
   liberado, em vez de falhar com erro de tipo.
2. **Given** uma chave fora das ModuleKeys oficiais, **When** alguém tentar
   gravá-la por qualquer caminho, **Then** o trigger recusa com o nome da chave
   inválida.
3. **Given** um plano com `contas_pagar` desligado, **When** um admin de clínica
   nesse plano abrir o menu, **Then** o item não aparece e a URL direta é negada.

---

### Edge Cases

- **Catálogo em uso sendo desativado.** Desativar um serviço já usado em
  consultas passadas não pode apagar o histórico nem quebrar relatório. Desativa
  para novos usos, permanece para os antigos.
- **Plano de contas hierárquico** (`parent_id`, `level`): apagar um pai com
  filhos, e o que acontece com os lançamentos pendurados.
- **`is_system`** em `chart_of_accounts` e `closing_types`: o que a clínica
  **não** pode editar nem apagar, e por quê.
- **Regra em horas exibida em dias.** `confirmation_hours` é a armadilha
  conhecida: a referência exibe dias e grava horas. Ida e volta tem de ser
  estável, e `max(1, round(h/24))` na exibição.
- **Meta (`goals`) por mês e ano** já existente sendo recadastrada: atualiza ou
  duplica.
- **Clínica sem sábado** com consulta já agendada num sábado: a regra vale para
  o futuro, não reescreve o passado.

---

## Requirements *(mandatory)*

### Functional Requirements

**A correção que abre a spec**

- **FR-001**: O default de `plans.enabled_modules` MUST passar de `'[]'::jsonb`
  para `'{}'::jsonb`, por migração versionada. Um default que o trigger da
  própria tabela recusa é defeito, não escolha.
- **FR-002**: O formato de `enabled_modules` MUST ser objeto
  `Record<ModuleKey, boolean>`, em banco, app e tela. O trigger já impõe;
  o app e a tela passam a assumir um formato só.
- **FR-003**: Toda linha existente de `plans` MUST ser verificada e, se estiver
  em formato de array, normalizada para objeto pela mesma migração.

**Catálogos**

- **FR-004**: O sistema MUST permitir criar, editar e desativar entradas de:
  `channels`, `origins`, `objections`, `services`, `payment_methods`,
  `expense_categories`, `chart_of_accounts`, `bank_accounts`, `closing_types`,
  `consultation_types`, `acquirers`, `goals` e `anamnesis_config`.
- **FR-005**: A desativação MUST ser lógica (`active = false`). Entrada
  desativada MUST sair das listas de escolha e MUST permanecer legível onde já
  foi usada.
- **FR-006**: Entradas marcadas `is_system` MUST NOT ser editáveis nem
  removíveis pela clínica.
- **FR-007**: `payment_methods` MUST guardar taxa padrão, taxa de antecipação e
  prazo em dias, porque é deles que sai o líquido e o vencimento do recebível.

**Regras de negócio**

- **FR-008**: O sistema MUST permitir editar `followup_days`,
  `confirmation_hours`, `recapture_days`, `recall_days`,
  `satisfaction_survey_days`, `anamnesis_send_days` e `work_saturday`.
- **FR-009**: `confirmation_hours` MUST ser exibida em dias e armazenada em
  horas, com ida e volta estável: exibe `max(1, round(h/24))`, grava `dias × 24`.
- **FR-010**: `patient_required_fields` e `appointment_required_fields` MUST ser
  configuráveis, e os formulários dos módulos posteriores MUST obedecê-los sem
  lista fixa em código.

**Acesso**

- **FR-011**: Todas as telas desta spec MUST ser governadas pela ModuleKey
  `configuracoes`, e a de planos pelo guard de superadmin.
- **FR-012**: Toda tabela desta spec MUST ter RLS por `clinic_id` já ativa e
  verificada; nenhuma leitura pode alcançar catálogo de outra clínica.
- **FR-013**: A edição de catálogo e de regra de negócio MUST gerar registro de
  auditoria, pelo mecanismo da Fase 2 da SPEC 002.

**Onboarding**

- **FR-014**: A tela MUST mostrar o progresso dos doze passos do onboarding, que
  são derivados destas mesmas tabelas, e MUST NOT bloquear o uso do sistema
  enquanto eles não fecharem.

### Key Entities

Todas já existem na fundação. Esta spec liga o app a elas; não cria tabela nova,
com a única exceção de nenhuma.

- **Regras de negócio** (`business_rules`): uma linha por clínica, com os
  parâmetros que os outros módulos leem.
- **Catálogos simples** (`channels`, `origins`, `objections`,
  `consultation_types`, `closing_types`): nome e ativo.
- **Catálogos com valor** (`services`, `payment_methods`, `acquirers`,
  `expense_categories`): carregam preço, custo, taxa e prazo.
- **Estrutura financeira** (`chart_of_accounts` hierárquico, `bank_accounts`).
- **Metas** (`goals`): por mês e ano, com alvo de receita, pacientes novos,
  fechamentos e conversão.
- **Modelo de anamnese** (`anamnesis_config`): título, especialidade e campos.
- **Plano** (`plans`): o teto. Vive fora da clínica, editado pelo superadmin.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um administrador configura a clínica do zero até fechar os doze
  passos do onboarding em menos de 30 minutos, sem ajuda.
- **SC-002**: A ida e volta de `confirmation_hours` é estável: o valor exibido
  depois de salvar é o mesmo digitado, em 100% dos casos entre 1 e 30 dias.
- **SC-003**: Criar um plano pela tela, sem tocar nos módulos, funciona. Hoje
  falha com erro de tipo.
- **SC-004**: Nenhum catálogo de uma clínica é alcançável por outra, incluindo
  tentativa por URL direta com o ID, verificado por Arthur.
- **SC-005**: Desativar um serviço usado no passado não altera nenhum relatório
  histórico.

---

## Assumptions

- **Nenhuma tabela nova.** Todas as treze tabelas de catálogo e a
  `business_rules` já foram portadas nas 55 migrações. Esta spec liga o app ao
  que existe e corrige o default quebrado.
- **A tela de planos é do superadmin**, não da clínica. A clínica vê o teto do
  próprio plano, e não o edita.
- **Repasse fica de fora.** `team_members` guarda modelo e percentual de
  repasse, mas o relatório de repasse tem imposto fixado em zero e atribuição
  estimada. É a spec 005 e as ressalvas do BACKLOG.
- **Um componente de período para todo o app.** A referência tem três
  vocabulários convivendo (INVENTARIO-UI, divergência D3). Aqui nasce um só.
- **Rótulo de enum nunca vai cru para a tela.** Divergência D3 do INVENTARIO-UI,
  registrada em `.claude/rules/app.md`.

---

## Dependências

1. **SPEC 001** concluída no que importa: `RequirePermission` e o guard do app
   existem desde 25/08 e são o que protege estas telas.
2. **Fase 2 da SPEC 002** para o FR-013. A auditoria de ação dentro da clínica
   depende de `data_audit_log`, que está escrito e aguarda aplicação.
3. **Nada mais.** Esta spec não espera nenhuma outra.

---

## Decisões que esta spec fecha

| # | Decisão | Estado |
|---|---|---|
| **D-005.1** | `enabled_modules` é objeto `Record<ModuleKey, boolean>` | **Fechada pela evidência**: o trigger já impõe desde `20260725033102`. O BACKLOG a tratava como pergunta aberta por engano. |
| **D-005.2** | O default da coluna passa a `'{}'::jsonb` | **Proposta**, com migração dentro desta spec |
| **D-005.3** | Desativação é lógica, nunca exclusão | **Proposta** |
| **D-005.4** | Um componente de período para todo o app | **Proposta** |

## Decisão que esta spec NÃO fecha, e precisa de você

**A ambiguidade da ModuleKey `consultas`.** `docs/dominio/modulos.md` registra
que a chave existe no contrato das 15, mas a tela rotulada "Consultas" aponta
para `/acompanhamento`, protegida por outra chave. O documento é explícito:
*"ambiguidade em contrato de permissão é dívida de segurança"*.

São duas saídas, e as duas são baratas hoje e caras depois:

- **`consultas` ganha destino próprio**, e aí o menu passa a ter dois itens
  distintos, o que exige decidir o que cada tela faz;
- **`consultas` sai do contrato por emenda**, e o contrato passa a ter 14
  chaves.

Vale notar a simetria: se `consultas` sair e `residuos` (SPEC 013) entrar, o
contrato volta a ter 15 chaves e as duas emendas viram uma só.
