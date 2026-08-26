# Tarefas — SPEC 005, Configurações da clínica

**Branch**: `spec/005-configuracoes` · **Plano**: [plan.md](./plan.md)

> Documento de **estado**, não de histórico. Uma tarefa marcada aqui é uma
> tarefa cujo comportamento foi provado, ou que traz escrito literalmente
> *"código lido, não comportamento provado"* (Princípio IV).

**Legenda:** `[x]` feito e provado · `[~]` escrito, não provado · `[ ]` aberto
· `[P]` pode correr em paralelo · `[aceite]` só o Arthur fecha

---

## Fase 0 — Verificar o que se presume

- [x] **T001** Varrer as catorze tabelas: RLS, policy, colunas, `is_system`
      ✅ `research.md`. Todas com RLS e policy. **Um falso positivo conferido
      antes de virar tarefa:** o `grep` acusou `consultation_types` sem policy,
      e era quebra de linha na migração.
- [x] **T002** Confirmar as colunas de `business_rules` acrescentadas depois
      ✅ as cinco existem, com os defaults que revelam o contrato:
      `patient_required_fields` nasce `["name"]` e
      `appointment_required_fields` nasce `["patient_id","date"]`.
- [x] **T003** Registrar a dívida achada no caminho
      ✅ **duas implementações de "qual clínica é a minha"** nas policies:
      subselect em `profiles` nas tabelas antigas, `get_my_clinic_id()` nas
      novas. Não são provadamente equivalentes. É Princípio VIII, e o conserto
      é da SPEC 016 (FR-006).

## Fase 1 — A correção de faixa A

- [~] **T004** Migração do default de `enabled_modules`
      Escrita: `supabase/migrations/20260825070000_...sql`. Normaliza as linhas,
      corrige o default de `'[]'` para `'{}'` e acrescenta `CHECK` para o
      defeito não voltar. **Não aplicada.**
- [ ] **T005** [aceite] Provar que o defeito sumiu
      `INSERT INTO plans (name, monthly_price) VALUES ('teste', 0);` — antes da
      migração isso **falha** com `enabled_modules deve ser um objeto JSON`.
      Depois, cria com `{}`. A prova está no rodapé da própria migração.

## Fase 2 — O núcleo puro e testado

Sem tela nenhuma. É o que permite testar a regra sem navegador.

- [x] **T006** `lib/config/regras.ts` — conversões puras ✅
      `confirmation_hours` exibida em dias e gravada em horas
      (`max(1, round(h/24))` na exibição, `dias × 24` na gravação); validação de
      campo obrigatório contra `patient_required_fields`.
- [x] **T007** [P] `lib/config/catalogo.ts` — a definição declarativa ✅ nove catálogos
      Os 9 catálogos que cabem no componente genérico, cada um com tabela,
      rótulo, colunas, tipo e obrigatoriedade. **Acrescentar catálogo passa a
      ser acrescentar uma entrada**, não escrever uma tela.
- [x] **T008** Testes em Vitest, **provados por mutação** ✅ 24 testes novos, 104 no total. Duas mutações aplicadas de propósito (tirar o piso dos campos obrigatórios; aceitar slug desconhecido) derrubaram **3 testes**. Teste que não falha quando o código quebra não protege nada.
      A ida e volta de `confirmation_hours` para 1 a 30 dias; a validação de
      campo obrigatório; e a trava de que todo catálogo do registro aponta para
      tabela que existe.

## Fase 3 — As telas

- [x] **T009** A camada de dados, a listagem e **o formulário** ✅ Fechado em 25/08. A escrita ficou em três peças: `entrada.ts` (pura, decide o que o formulário produziu), `acoes.ts` (grava) e `formulario.tsx` (um formulário para os nove catálogos, com os campos vindo da definição). 26 testes novos, provados por mutação: o `Number()` ingênuo derruba 11, a fronteira de coluna aberta derruba 1. Nunca lança: falha vira lista vazia, porque tela de configuração que estoura impede a clínica de configurar o resto.
- [x] **T010** [P] Rota `[catalogo]` com o parâmetro **validado contra o
      registro** ✅ Catálogo fora da lista é 404. Coberto em duas camadas: teste
      de unidade sobre `catalogoPorSlug` (com `patients`, `profiles` e
      `../services` entre os casos) e teste de navegador sobre a rota.
- [x] **T011** Tela de regras de negócio (`business_rules`) ✅ Fechada em 26/08. Seis prazos, o sábado e as duas listas de campos obrigatórios, com `salvarRegras` fazendo INSERT no primeiro salvamento e UPDATE depois. Dois desenhos que valem registro: **cada campo diz o que muda quando você mexe nele**, e **o piso aparece marcado e travado em vez de escondido**, porque esconder faria parecer que o nome do paciente é opcional. `lib/config/rotulos.ts` é um `Record` completo, então campo novo sem rótulo é erro de compilação, e não um `zip_code` cru vazando para a tela.
- [x] **T012** Tela de plano de contas ✅ 26/08. O único catálogo fora do registro declarativo, porque é árvore. `lib/config/arvore.ts` com 19 testes: ordenação por código entendendo número (1.10 depois de 1.9), corte de ciclo, e `paisPossiveis`, que impede o ciclo antes de ele existir. O nível é **derivado do pai** na gravação, nunca aceito do formulário.
- [x] **T013** Tela de contas bancárias ✅ 26/08, e saiu quase de graça: virou a décima entrada do registro declarativo. Ela pôs o desenho à prova e achou uma suposição, porque `bank_accounts` chama a coluna de nome de `bank_name`. A lista passou a usar a primeira coluna `naLista` em vez de assumir `name`, e o teste que exigia `name` foi corrigido para exigir a **regra** e não o nome.
- [x] **T014** Tela de metas ✅ Fechada em 26/08, e ela virou mais que upsert: traz dias uteis, feriados nacionais calculados e quanto falta POR DIA UTIL. E o item 1 da modelagem do INI. Os feriados moveis saem da Pascoa, com o algoritmo conferido contra oito anos reais e uma varredura de 200 anos. Provado por mutacao: deslocar a Pascoa em um dia derruba 11 testes.
- [x] **T015** Tela de modelo de anamnese ✅ 26/08. Era a mais cara pelo motivo certo: `anamnesis_config.fields` guarda **duas formas diferentes** conforme a época da linha, array plano de campos ou array de seções. `lib/config/anamnese.ts` lê as duas e grava só a nova, então o modelo se converte sozinho no primeiro salvamento, **sem migração de dado**. 21 testes. O que eles protegem: o `id` do campo é a chave das respostas do paciente, e regenerá-lo não dá erro em lugar nenhum, só faz a anamnese antiga perder aquela resposta. Provado por mutação: regerar id derruba 3 testes, e tratar `active` ausente como desligado derruba 1.
- [~] **T016** O índice de Configurações ✅ escrito, com os catálogos, o progresso dos doze passos e as regras em leitura. **Código lido, não comportamento provado.**
- [ ] **T017** [aceite] O roteiro de `quickstart.md`, executado por Arthur

## Fase 4 — Auditoria

- [ ] **T018** Ligar a edição de catálogo à trilha da SPEC 002
      **BLOQUEADA** até `data_audit_log` estar aplicado. Declarado desde já, em
      vez de descobrir no meio.

---

## O que esta spec NÃO faz, e está escrito para ninguém procurar

- **Não cria tabela.** As catorze já vieram nas 55 migrações.
- **Não mexe em repasse.** `team_members` guarda modelo e percentual, mas o
  relatório tem imposto fixado em zero e atribuição estimada. É a spec 006 e as
  ressalvas do BACKLOG.
- **Não uniformiza as 42 policies.** A dívida do T003 é real e é da SPEC 016.
- **Não decide de onde vem a alíquota de imposto.** Apareceu no REL-3 da
  bateria e continua pendente.
