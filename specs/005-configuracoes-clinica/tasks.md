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

- [~] **T009** A camada de dados (`lib/config/servidor.ts`) e a listagem única ✅ escritas. **Falta o formulário de edição.** Nunca lança: falha vira lista vazia, porque tela de configuração que estoura impede a clínica de configurar o resto.
- [x] **T010** [P] Rota `[catalogo]` com o parâmetro **validado contra o
      registro** ✅ Catálogo fora da lista é 404. Coberto em duas camadas: teste
      de unidade sobre `catalogoPorSlug` (com `patients`, `profiles` e
      `../services` entre os casos) e teste de navegador sobre a rota.
- [ ] **T011** Tela de regras de negócio (`business_rules`)
- [ ] **T012** [P] Tela de plano de contas (árvore, `parent_id`/`level`)
- [ ] **T013** [P] Tela de contas bancárias
- [ ] **T014** [P] Tela de metas (upsert por mês e ano)
- [ ] **T015** Tela de modelo de anamnese (`fields` jsonb) — a mais cara
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
