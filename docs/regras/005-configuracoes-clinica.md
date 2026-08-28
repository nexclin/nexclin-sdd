# 005 · Configurações da clínica

> **Regra viva.** Nasceu antes da execução, e é corrigida no mesmo commit em que
> a execução a contradiz.
>
> **Estado em 27/08/2026:** escrita, não executada. É a primeira regra da Onda 1
> e o substrato de todas as outras. Alvo: a stack Next.js deste repositório.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Fila:** `fila-de-regras.md` ·
> **Origem:** convertida da SPEC 005 em 27/08/2026, formato de sete seções.

---

## 1. O problema

`business_rules` e os treze catálogos da clínica são lidos por pacientes,
consultas, tarefas, anamnese e todo o financeiro: são as listas que todo
formulário oferece e os parâmetros que toda automação obedece. Sem esse
substrato, qualquer módulo posterior escreve cego ou reimplementa formulário que
vai precisar ser refeito. E ao ler o banco para escrever esta regra apareceu um
segundo motivo, que não era hipótese: **o default de `plans.enabled_modules` é um
valor que a própria tabela recusa.** A coluna nasce `'[]'::jsonb`, array, e o
trigger que a valida exige objeto. Todo `INSERT` em `plans` que não informe
`enabled_modules` explicitamente falha com `enabled_modules deve ser um objeto
JSON`. Hoje não incomoda porque os planos vieram de migração; incomoda no dia em
que alguém criar um plano pela tela.

## 2. Requisitos

**A correção que abre a regra**

- **FR-001**: O default de `plans.enabled_modules` **MUST** passar de
  `'[]'::jsonb` para `'{}'::jsonb`, por migração versionada. *Porquê:* um default
  que o trigger da própria tabela recusa é defeito, não escolha.
- **FR-002**: O formato de `enabled_modules` **MUST** ser objeto
  `Record<ModuleKey, boolean>`, em banco, app e tela. *Porquê:* o trigger já
  impõe objeto desde `20260725033102`. O BACKLOG tratava isso como pergunta
  aberta por engano: o que falta não é decidir, é alinhar o default.
- **FR-003**: Toda linha existente de `plans` **MUST** ser verificada e, se
  estiver em formato de array, normalizada pela mesma migração. *Porquê:*
  corrigir o default sem normalizar o que existe deixa duas formas convivendo, e
  o código passa a ter de aceitar as duas para sempre.

**Catálogos**

- **FR-004**: O sistema **MUST** permitir criar, editar e desativar entradas de
  `channels`, `origins`, `objections`, `services`, `payment_methods`,
  `expense_categories`, `chart_of_accounts`, `bank_accounts`, `closing_types`,
  `consultation_types`, `acquirers`, `goals` e `anamnesis_config`. *Porquê:* sem
  serviço cadastrado não há o que agendar nem o que cobrar. É o que transforma o
  sistema de vazio em operável.
- **FR-005**: A desativação **MUST** ser lógica (`active = false`). Entrada
  desativada **MUST** sair das listas de escolha e **MUST** permanecer legível
  onde já foi usada. *Porquê:* desativar um serviço usado em consultas passadas
  não pode apagar histórico nem quebrar relatório.
- **FR-006**: Entradas marcadas `is_system` **MUST NOT** ser editáveis nem
  removíveis pela clínica. *Porquê:* são as linhas que o sistema pressupõe
  existirem. Apagá-las quebra cálculo em outro módulo, longe de onde o clique
  aconteceu.
- **FR-007**: `payment_methods` **MUST** guardar taxa padrão, taxa de antecipação
  e prazo em dias. *Porquê:* é deles que saem o líquido e o vencimento do
  recebível, e vencimento errado desloca o fluxo de caixa inteiro. Foi o item
  V-22 da bateria do Vinícius.

**Regras de negócio**

- **FR-008**: O sistema **MUST** permitir editar `followup_days`,
  `confirmation_hours`, `recapture_days`, `recall_days`,
  `satisfaction_survey_days`, `anamnesis_send_days` e `work_saturday`. *Porquê:*
  são os parâmetros que a automação de tarefas e as telas de paciente e consulta
  leem. Deixá-los para depois significa reescrever formulário quando chegarem.
- **FR-009**: `confirmation_hours` **MUST** ser exibida em dias e armazenada em
  horas, com ida e volta estável: exibe `max(1, round(h/24))`, grava `dias × 24`.
  *Porquê:* é a armadilha conhecida da referência. Ida e volta instável faz o
  usuário salvar 2 e reler 1, e ele passa a não confiar em nenhum campo da tela.
- **FR-010**: `patient_required_fields` e `appointment_required_fields` **MUST**
  ser configuráveis, e os formulários dos módulos posteriores **MUST** obedecê-los
  sem lista fixa em código. *Porquê:* lista fixa em código transforma
  configuração em mentira: a tela oferece a escolha e o formulário ignora.

**Acesso**

- **FR-011**: Todas as telas desta regra **MUST** ser governadas pela ModuleKey
  `configuracoes`, e a de planos pelo guard de superadmin. *Porquê:* a tela de
  planos edita o teto de outras clínicas. Ela não é da clínica.
- **FR-012**: Toda tabela desta regra **MUST** ter RLS por `clinic_id` ativa e
  verificada. *Porquê:* Princípio I. Catálogo de uma clínica alcançável por outra
  é vazamento, mesmo que "seja só uma lista de serviços": preço e custo estão lá.
- **FR-013**: A edição de catálogo e de regra de negócio **MUST** gerar registro
  de auditoria, pelo mecanismo da regra 002. *Porquê:* mudar a taxa de um meio de
  pagamento muda todo recebível criado depois. Sem rastro, ninguém reconstrói por
  que os números de duas semanas atrás não batem.

**Onboarding**

- **FR-014**: A tela **MUST** mostrar o progresso dos doze passos do onboarding,
  e **MUST NOT** bloquear o uso do sistema enquanto eles não fecharem. *Porquê:*
  os passos são derivados destas mesmas tabelas, e bloquear quem ainda não
  configurou tudo impede exatamente quem mais precisa entrar para configurar.

## 3. O que muda no banco

**Nenhuma tabela nova.** As treze de catálogo e `business_rules` já foram
portadas nas 55 migrações. Esta regra liga o app ao que existe e corrige um
default.

| Objeto | Mudança |
|---|---|
| `plans.enabled_modules` | default de `'[]'::jsonb` para `'{}'::jsonb` |
| `plans` (linhas existentes) | normalização de array para objeto, na mesma migração |
| as 14 tabelas de catálogo e regra | nenhuma alteração de schema; RLS já ativa, verificada por varredura em 25/08 |

As entidades, e o que cada grupo carrega:

- **`business_rules`**: uma linha por clínica, com os parâmetros que os outros
  módulos leem.
- **Catálogos simples** (`channels`, `origins`, `objections`,
  `consultation_types`, `closing_types`): nome e ativo.
- **Catálogos com valor** (`services`, `payment_methods`, `acquirers`,
  `expense_categories`): preço, custo, taxa e prazo.
- **Estrutura financeira**: `chart_of_accounts`, hierárquico por `parent_id` e
  `level`, e `bank_accounts`.
- **`goals`**: por mês e ano, com alvo de receita, pacientes novos, fechamentos e
  conversão.
- **`anamnesis_config`**: título, especialidade e campos.
- **`plans`**: o teto. Vive fora da clínica, editado pelo superadmin.

## 4. Premissas

- **Nenhuma tabela nova.** Se aparecer necessidade de uma, a premissa quebrou e a
  regra precisa ser corrigida antes de continuar.
- **A tela de planos é do superadmin.** A clínica vê o teto do próprio plano e
  não o edita.
- **Repasse fica de fora.** `team_members` guarda modelo e percentual, mas o
  relatório de repasse tem imposto fixado em zero e atribuição estimada. É
  ressalva do backlog, não desta regra.
- **Um componente de período para todo o app.** A referência tem três
  vocabulários convivendo, divergência D3 do `INVENTARIO-UI`. Aqui nasce um só.
- **Rótulo de enum nunca vai cru para a tela.** Mesma divergência D3, registrada
  em `.claude/rules/app.md`.

**Casos de borda que a execução vai encontrar:**

- Plano de contas hierárquico: apagar um pai com filhos, e o que acontece com os
  lançamentos pendurados.
- Meta por mês e ano já existente sendo recadastrada: atualiza ou duplica.
- Clínica sem sábado com consulta já agendada num sábado: a regra vale para o
  futuro, não reescreve o passado.

## 5. Dependências

1. **Regra 001**, no que importa: `RequirePermission` e o guard do app existem
   desde 25/08, e são o que protege estas telas.
2. **Regra 002, a auditoria**, para o FR-013. `data_audit_log` está escrito e
   aguarda aplicação.
3. **Nada mais.** Esta regra não espera nenhuma outra.

## 6. Como se prova que funciona

- **SC-001**: Um administrador configura a clínica do zero até fechar os doze
  passos do onboarding em menos de 30 minutos, sem ajuda.
- **SC-002**: A ida e volta de `confirmation_hours` é estável: o valor exibido
  depois de salvar é o mesmo digitado, em 100% dos casos entre 1 e 30 dias.
- **SC-003**: Criar um plano pela tela, sem tocar nos módulos, funciona. Hoje
  falha com erro de tipo.
- **SC-004**: Nenhum catálogo de uma clínica é alcançável por outra, incluindo
  tentativa por URL direta com o ID. Verificado por Arthur.
- **SC-005**: Desativar um serviço usado no passado não altera nenhum relatório
  histórico.
- **SC-006**: Uma chave fora das 15 ModuleKeys é recusada pelo trigger, com o
  nome da chave inválida na mensagem, por qualquer caminho de escrita.
- **SC-007**: Um plano com `contas_pagar` desligado esconde o item do menu e nega
  a URL direta, mesmo para admin da clínica.

## 7. A decisão que falta

**Nenhuma.**

A ambiguidade da ModuleKey `consultas`, que era a pergunta aberta desta regra
quando ela foi escrita em 25/08, **foi decidida** e vive em
[`../adr/0001-consultas-sai-do-contrato-de-modulos.md`](../adr/0001-consultas-sai-do-contrato-de-modulos.md).
As quatro decisões próprias da regra (o formato objeto de `enabled_modules`, o
default `'{}'`, a desativação lógica e o componente único de período) estão
fechadas nos requisitos acima.
