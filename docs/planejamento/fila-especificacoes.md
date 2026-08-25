# Fila de especificações — Onda 1 na stack nova

> Escrito em 2026-08-18. Ordena as próximas specs (a partir da **004**) que
> portam para a stack nova (Next.js + Supabase próprio) os módulos da Onda 1 —
> as 7 áreas que o primeiro cliente usa de fato no dia 01/09.
>
> A numeração começa em 004 porque `specs/001-fundacao-superadmin/`,
> `specs/002-seguranca-anamnese-auditoria/` e
> `specs/003-superadmin-blindado/` já existem no repositório. O briefing
> desta sessão dizia "começar em 003"; corrigido pela evidência do repo.
>
> Regra: nenhuma spec começa sem que os pré-requisitos técnicos estejam
> em pé. "Implementado ≠ funciona" — cada critério de pronto abaixo é um
> teste manual real que Arthur executa antes de fechar a spec.
>
> **Nota de 25/08/2026 — os números 004 a 012 continuam reservados a esta
> fila.** A SPEC de resíduos/conformidade, escrita fora da ordem por ter vindo
> de uma pauta comercial, ficou com o número **013**
> (`specs/013-residuos-conformidade/`) justamente para não roubar um lugar
> daqui. Ela **não entra na Onda 1 nem na Onda 2** — depende de `contas_pagar`,
> de emenda à constituição (16ª ModuleKey) e de decisão comercial do grupo.
>
> Esta fila é um **índice**. Os `spec.md` propriamente ditos são escritos
> um por vez, na hora de começar cada um, seguindo o modelo de
> `specs/001-fundacao-superadmin/` (spec + plan + tasks + contracts +
> data-model + quickstart + research).

---

## Método

O princípio único é **dependência de dado** — qual tabela, RLS, RPC,
edge function ou catálogo o módulo LÊ. O que produz dado que outros
consumirão vem primeiro; o que só agrega vem por último.

Consequências práticas dessa regra:

- **`configuracoes` vem antes de `pacientes`** — porque
  `business_rules.patient_required_fields`, `channels`, `origins` e outros
  catálogos são lidos por quase todas as telas clínicas
  ([INVENTARIO.md §1.3](../../INVENTARIO.md), §3.4). Sem esse substrato,
  qualquer outro módulo escreve com dados órfãos.
- **`consultas` vem antes de `leads`** — porque o Lead→Consulta Wizard
  (`components/lead/LeadToAppointmentWizard.tsx` no MVP) escreve em
  `appointments` e dispara `createAppointmentTasks`. Especificar `leads`
  sem alvo é entregar meio módulo.
- **`anamnese` público fica cauterizado por dívida conhecida** — o endpoint
  `anamnesis-public` está no BACKLOG e a Fase 2 da SPEC 002 pediu redesenho
  de `public_token` (rastro em `patients`). A spec de `anamnese` cobre a
  parte interna; a parte pública referencia essa dívida como pré-requisito.
- **`dashboard` fica por último** — só agrega o que os outros produzem.

Todas as tabelas citadas abaixo (`patients`, `leads`, `appointments`,
`tasks`, `receivables`, `business_rules`, `team_members`, catálogos)
**já existem na fundação** — foram portadas nas 55 migrações da SPEC 001
([`supabase/migrations/`](../../supabase/migrations)). Nenhuma spec desta
fila cria essas tabelas do zero; todas apenas ligam o app à estrutura já
existente e adicionam colunas/policies pontuais quando necessário.

---

## Fila

### 004 — configuracoes-clinica

- **Módulo alvo:** `configuracoes`
- **Pré-requisitos:**
  - SPEC 001 concluída (auth, guards, `my_permission`, `RequirePermission`).
  - Tabelas já portadas na fundação: `business_rules`, `channels`, `origins`,
    `objections`, `services`, `payment_methods`, `expense_categories`,
    `chart_of_accounts`, `bank_accounts`, `closing_types`,
    `consultation_types`, `goals`, `acquirers`, `anamnesis_config`
    (ver INVENTARIO §1.3).
  - Decisão de arquitetura do BACKLOG a fechar dentro da spec:
    `enabled_modules` como `Record<ModuleKey, boolean>` (o default `'[]'`
    do MVP descasa do uso).
- **Por que agora:** é o substrato. `patient_required_fields`,
  `appointment_required_fields`, `confirmation_hours`, `followup_days`,
  `work_saturday`, `satisfaction_survey_days`, `anamnesis_send_days` moram
  em `business_rules` e são lidos por pacientes, consultas, tarefas e
  anamnese. Sem esses catálogos e regras, qualquer módulo posterior escreve
  cego ou re-implementa formulários que precisarão ser refeitos.
- **Critério de pronto:** admin da clínica abre os 11 diálogos de
  configuração (business_rules, patient_required_fields,
  appointment_required_fields, channels_origins, services, objections,
  payment_methods, chart_of_accounts, bank_accounts, goals, anamnese),
  edita cada um, salva, recarrega e confirma persistência; usuário sem
  permissão de `configuracoes` (via plano OU team_member) vê "Acesso
  negado" em URL direta; regra "confirmação em dias mas armazenada em
  horas" (`confirmation_hours: max(1, round(h/24))`, salva `days×24`) é
  preservada, medida em ida-e-volta.
- **Referência no MVP:** `src/pages/Configuracoes.tsx` +
  `src/components/config/*` (11 diálogos, ver INVENTARIO §3.4). Rota
  `/configuracoes` do MVP.

### 005 — equipe-e-convites

- **Módulo alvo:** `equipe`
- **Pré-requisitos:**
  - 004 concluída (papéis de repasse e permission_level dependem do plano
    e das regras de negócio).
  - Edge function `invite-team-user` portada na SPEC 001 Fase 3.
  - Decisão do BACKLOG (§Decisões a confirmar) a fechar dentro da spec:
    fluxo de convite por e-mail com definição de senha pelo próprio
    convidado (nunca senha em texto claro pelo admin — regra (e) da
    constituição).
- **Por que agora:** sem cadastrar os 3/5/8 usuários que os planos
  concedem, ninguém opera no dia 1. Depende de 004 porque `permissions`
  jsonb usa o mapa de módulos por ModuleKey e o contador de assentos
  ("Acessos: X de Y") lê `max_users` do plano. O trigger
  `enforce_team_user_limit` já barra o excesso (bug off-by-one foi
  corrigido — CLAUDE.md §3.3), a UI só reflete.
- **Critério de pronto:** admin convida um usuário; convidado recebe
  e-mail via Resend, define senha própria e loga; vira `team_member` com
  `permission_level` escolhido; contador de assentos aparece na sidebar e
  no diálogo Equipe (fecha divergência D4 do INVENTARIO-UI); com
  `max_users=N` esgotado, novo convite é barrado no banco com mensagem
  clara na tela; excluir team_member desliga o acesso.
- **Referência no MVP:** `src/components/config/ConfigTeamDialog.tsx` +
  `supabase/functions/invite-team-user/` (referência funcional; convite
  atual em texto claro precisa ser redesenhado — ver BACKLOG).

### 006 — pacientes

- **Módulo alvo:** `pacientes`
- **Pré-requisitos:**
  - 004 concluída (`channels`, `origins`, `patient_required_fields`).
  - 005 concluída (associação com profissional para `useCanViewAnamnesis` e
    para telas que filtram por médico responsável).
  - Tabela `patients` já existe (fundação). Confirmar RLS por `clinic_id`
    já ativa (INVENTARIO §1.4).
- **Por que agora:** é a âncora clínica de quase tudo que vem depois —
  consultas, tarefas, anamnese, contas a receber ligam a `patient_id`. E
  o formulário de cadastro só se sustenta se `patient_required_fields` e
  os catálogos de origem/canal estiverem prontos (004).
- **Critério de pronto:** admin cadastra um paciente respeitando os
  campos exigidos por `patient_required_fields` (dinâmicos, definidos em
  004); consulta CEP via ViaCEP (paridade com o wizard do MVP); paciente
  aparece na lista sem filtro de período que esconda o cadastro (fecha
  divergência D2 do INVENTARIO-UI — cadastro não deve ter filtro de
  período por padrão); usuário de outra clínica não vê o paciente nem
  por RPC nem por URL direta com ID (verificar RLS).
- **Referência no MVP:** `src/pages/Pacientes.tsx` + diálogos irmãos
  (INVENTARIO §3.1 rota `/pacientes`).

### 007 — consultas-acompanhamento

- **Módulo alvo:** `consultas`, `acompanhamento`
- **Pré-requisitos:**
  - 004 (regras: `confirmation_hours`, `work_saturday`,
    `satisfaction_survey_days`, `anamnesis_send_days`;
    `appointment_required_fields`; catálogos `payment_methods`,
    `chart_of_accounts`, `closing_types`, `consultation_types`,
    `bank_accounts`).
  - 006 (pacientes existem para agendar).
  - Tabelas `appointments`, `appointment_items`, `funnel_2_entries`,
    `prescriptions`, `closings`, `receivables` já existem (fundação).
  - `lib/businessDays.ts` (dias úteis) portado nesta spec — usado por
    tarefas depois.
- **Por que agora:** consultas produz a maior parte do dado que Financeiro,
  Tarefas e Dashboard leem depois. A máquina de estados
  `agendada → confirmada → compareceu | nao_compareceu | cancelada` e a
  geração idempotente de `receivables` (origem `consulta`, `fechamento`,
  `deposito`) precisa estar sólida antes que qualquer coisa dependa dela.
  Vem antes de `leads` porque o Lead→Consulta Wizard escreve em
  `appointments`.
- **Critério de pronto:** admin agenda uma consulta para um paciente;
  transiciona `agendada → confirmada → compareceu`; grava prescrição e
  fechamento (crédito 3x); um `receivables` `pendente` aparece em Contas a
  Receber com taxa e prazo corretos por `payment_method`; depósito gera
  um `receivables` `pago`; cancelamento com motivo ≥3 chars grava razão;
  no-show idem; tarefa `follow_up` "Contato de venda" é criada
  automaticamente em `compareceu` com saldo (para 011 e 008 consumirem).
- **Referência no MVP:** `src/pages/Acompanhamento.tsx` (tela ativa —
  rota `/acompanhamento` sob ModuleKey `acompanhamento`) +
  `src/components/appointment/AppointmentStatusDialogs.tsx` +
  `src/components/funil2/ClosingDetailDialog.tsx` +
  `src/hooks/useFinancialBreakdown.ts` + `src/lib/paymentFees.ts` +
  `src/lib/businessDays.ts`. Páginas órfãs `Consultas.tsx` e `Funil2.tsx`
  devem ser lidas para extrair regra, não para copiar layout
  (INVENTARIO §3.1 alerta que são órfãs; INVENTARIO-UI D1 lembra que
  algumas "órfãs" na verdade estão embutidas em outras telas).

### 008 — tarefas

- **Módulo alvo:** `tarefas`
- **Pré-requisitos:**
  - 004 (regras de dias úteis, `confirmation_hours`,
    `satisfaction_survey_days`).
  - 007 (consultas dispara `createAppointmentTasks` e `createSatisfactionTask`;
    triggers `auto_complete_appointment_task` e `auto_complete_anamnese_task`
    já existem no banco).
  - Tabela `tasks` já existe (fundação).
- **Por que agora:** as tarefas são majoritariamente auto-geradas pelo
  consultas (007); a spec `tarefas` é sobretudo a **lista/filtro/edição
  manual** e a normalização dos rótulos de tipo (fecha divergência D3 do
  INVENTARIO-UI — hoje `confirmacao` aparece como enum cru ao lado de
  `Envio de Anamnese` e `Recaptação` formatados). Sem 007 executando a
  automação, a spec tem pouco o que exercitar.
- **Critério de pronto:** ao agendar uma consulta em 007, aparecem em
  Tarefas as entradas `confirmar_agendamento` (due = consulta −
  `confirmation_hours`, snap p/ dia útil) e `envio_anamnese`; ao marcar
  `compareceu`, o `confirmar_agendamento` correspondente fica `concluida`
  (via trigger, não via UI); usuário sem permissão de `tarefas` (plano
  ou individual) não vê o menu; rótulos exibidos são consistentes (todos
  formatados, sem enum cru).
- **Referência no MVP:** `src/pages/Tarefas.tsx` (rota `/tarefas`) +
  `src/lib/tasksAutomation.ts`.

### 009 — atendimentos-leads

- **Módulo alvo:** `leads`
- **Pré-requisitos:**
  - 004 (catálogos `channels`, `origins`, `objections`).
  - 006 (upsert de paciente na conversão).
  - 007 (o wizard escreve em `appointments` e dispara automação de tarefas).
  - Tabelas `leads`, `lead_history` já existem (fundação).
- **Por que agora:** o funil de leads é o topo do funil comercial, mas
  seu ápice é o Lead→Consulta Wizard, que só faz sentido quando 006 e
  007 estão prontos. Antes disso, `leads` seria um kanban isolado sem
  saída.
- **Critério de pronto:** admin cria lead, movimenta pelo kanban
  (`novo_contato → em_atendimento → nao_agendou / recaptacao / agendou`);
  arrastar p/ `agendou` abre o wizard que valida campos dinâmicos de 004,
  faz upsert de paciente herdando origem/canal do lead, cria appointment
  `agendada`, grava `lead_history` e dispara `createAppointmentTasks`
  (verificar em Tarefas — 008); relatório do lead mostra objeção quando
  `nao_agendou`.
- **Referência no MVP:** `src/pages/Atendimentos.tsx` (rota
  `/atendimentos`) + `src/components/lead/LeadToAppointmentWizard.tsx` +
  `src/pages/Leads.tsx` e `src/pages/Funil.tsx` (órfãs — decidir
  intenção antes de portar, ver BACKLOG e INVENTARIO §3.1).

### 010 — anamnese

- **Módulo alvo:** `anamnese`
- **Pré-requisitos:**
  - 004 (templates em `anamnesis_config` são configuráveis pela clínica).
  - 006 (respostas ligam a `patient_id`).
  - **Dívidas de pré-requisito para a parte pública:**
    - Edge function `anamnesis-public` está no
      [`specs/BACKLOG.md`](../../specs/BACKLOG.md#edge-functions-não-portadas-na-spec-001) —
      não foi portada em 001.
    - Redesenho do `public_token` com rastro em `patients` é a Fase 2
      da [SPEC 002](../../specs/002-seguranca-anamnese-auditoria/tasks.md)
      e não está pronta. O fluxo público só entra depois que essa
      dívida for paga.
- **Por que agora:** a parte interna (templates + visualização das
  respostas + envio via link/WhatsApp) depende só de pacientes e
  configuracoes; entregar isso destrava o dia-a-dia clínico. A parte
  pública fica cauterizada — a spec **entrega o fluxo interno**;
  o fluxo público é explicitamente marcado como "depende da dívida
  X, entra em spec posterior".
- **Critério de pronto:** admin edita template em `anamnesis_config`;
  ao agendar uma consulta em 007 é opcionalmente criado um
  `anamnesis_responses` `pendente`; admin gera link e envia via
  `wa.me` (integração já usada no MVP); trigger `auto_complete_anamnese_task`
  fecha a tarefa `envio_anamnese` correspondente quando a resposta chega
  ao status `preenchida` (mesmo que o preenchimento seja simulado por
  UPDATE direto do admin, até o endpoint público existir).
- **Referência no MVP:** `src/pages/Anamnese.tsx` (rota `/anamnese`) +
  `src/pages/AnamnesePublica.tsx` (referência do fluxo público, para
  spec posterior) + `supabase/functions/anamnesis-public/` (no MVP;
  neste repo aguarda porte).

### 011 — contas-receber

- **Módulo alvo:** `contas_receber`
- **Pré-requisitos:**
  - 004 (`payment_methods`, `bank_accounts`, `chart_of_accounts`).
  - 007 (a maior parte dos `receivables` nasce de consultas/fechamentos).
  - Tabelas `receivables` e `appointment_items` já existem (fundação).
    A tabela `revenues` está morta desde `20260408031859` e é ignorada
    (INVENTARIO §1.3).
- **Por que agora:** contas a receber consome quase inteiramente o que
  o módulo consultas escreve (`receivables` com `origin ∈ {consulta,
  fechamento, deposito}`). Especificá-lo antes de 007 é escrever contra
  ar. Antes de dashboard (012) porque o Dashboard lê valores agregados
  de `receivables`.
- **Critério de pronto:** cadastros gerados por 007 aparecem em Contas
  a Receber com data de vencimento, líquido/bruto e taxa corretos por
  `payment_method`; conciliação com `bank_account` funciona (marca
  `conciliated=true` e liga à conta certa); baixa manual (`status=pago`,
  `paid_at`) reflete no saldo da `bank_account` (`opening_balance +
  recebidos − pagos`); usuário sem permissão `contas_receber` não vê o
  menu nem acessa por URL direta.
- **Referência no MVP:** `src/pages/ContasReceber.tsx` (rota
  `/contas-receber`) + `src/lib/paymentFees.ts`.

### 012 — dashboard

- **Módulo alvo:** `dashboard`
- **Pré-requisitos:**
  - 005 a 011 concluídas (dashboard só agrega o que os outros produzem).
  - 004 (`goals` do mês/ano).
- **Por que agora:** por definição, agregação de tudo que os outros
  módulos produziram. Especificá-lo antes seria projetar métricas sobre
  dados que não existem. Também é a chance de fechar as divergências
  visuais de dashboard já registradas (INVENTARIO-UI D3: três
  vocabulários de período; D9: eixo de 12 meses sem julho — ambos são
  problemas do dashboard do superadmin, mas o padrão de seletor de
  período único vale para o dashboard da clínica).
- **Critério de pronto:** dashboard carrega em <2s com 6 meses de dados
  sintéticos de uma clínica de teste; mostra faturamento, consultas,
  ticket médio, conversão e ranking macro (INVENTARIO §3.4); seletor de
  período é **único** e reutilizado (fecha D3); acesso é sempre concedido
  (dashboard não tem gate por `RequirePermission` — INVENTARIO §3.1
  observa "— (interno)"); nenhuma métrica quebra quando um módulo do
  plano está desabilitado (ex.: clínica sem `contas_pagar` habilitado
  não vê aquele bloco, mas o resto renderiza).
- **Referência no MVP:** rota `/` do MVP (Dashboard) +
  `DashboardOperational.tsx` (escopo `simplified`, usada internamente).

---

## Fora da Onda 1 — para registro

Não entram nesta fila: `contas_pagar`, `fluxo_caixa`,
`relatorios_vendas`, `relatorios_demais`, `insights`.

Motivo:

- **`insights`** depende de provedor de IA externo (a edge function
  `generate-insights` está no [BACKLOG](../../specs/BACKLOG.md) — usava
  o gateway do Lovable e precisa ser re-especificada com provedor
  próprio).
- **Repasse** tem imposto fixo em zero e atribuição de profissional
  estimada (BACKLOG §Decisões a confirmar — "Aproximações do MVP a
  especificar de verdade"). Como é o relatório mais sensível para
  médicos, entregá-lo com aproximações queima confiança; adiar é
  correto.
- **`contas_pagar`, `fluxo_caixa`, `relatorios_vendas`,
  `relatorios_demais`** — a Onda 1 foi definida como o mínimo que o
  primeiro cliente usa no dia 01/09; esses agregados/relatórios entram
  na Onda 2, junto com as decisões de repasse e insights.

---

## O que esta fila NÃO cobre

Dívidas técnicas conhecidas, com dono próprio, que serão trabalhadas em
paralelo ou como parte de outras specs — **não** aparecem nesta fila:

- **Fase 2 da SPEC 002** — redesenho de `public_token` com rastro em
  `patients` (é pré-requisito citado dentro da spec 010, mas é dívida
  independente).
- **Correção do `invite-team-user`** — hoje aceita senha em texto claro
  pelo admin, contra a regra (e) da constituição. Migração para convite
  por definição de senha pelo próprio convidado é decisão do BACKLOG a
  fechar dentro da spec 005.
- **T021 da SPEC 001** — testes automatizados de guards de permissão.
- **Migração de dados Lovable→stack nova** — quando (e se) o primeiro
  cliente migrar do MVP em produção para a stack nova.
- **Automação de cobrança/suspensão** — os parâmetros já vivem em
  `saas_settings`, mas a régua D+1/3/7/15/30 não está implementada
  (backlog do superadmin, não da Onda 1).
- **Retenção/expurgo LGPD** — política de retenção por tabela, com
  destaque para `anamnesis_responses` e `superadmin_audit_log`.

Cada uma dessas dívidas terá — ou já tem — sua própria spec.
