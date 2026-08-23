# Tasks: SPEC 004 — Correção da 1ª bateria (Vinícius)

**Feature**: `004-correcao-bateria-vinicius` · **Alvo**: `nexclin/nexclin@main`
**Corte**: 23/08/2026 · **Base medida**: `6b03f6c`

> `[P]` = paralelizável · `[aceite]` = prova manual do Arthur na tela
> `[arthur]` = só o Arthur executa (navegador logado / SQL editor)
> Cada tarefa de código fecha com `npx tsc -p tsconfig.app.json` limpo.

---

## Fase 0 — Gates que abrem o dia

- [ ] T001 [arthur] **A-SEC** — rodar a consulta de `storage.objects`
      (`docs/seguranca/storage-objects-2026-08-20.md`). Depois do commit
      `3c0bcea` do bot, deixou de ser "descobrir" e passou a ser **conferir**
      se as policies estão aplicadas. O pior caso não é RLS desligada: é bucket
      com `public = true`, lido sem autenticação. **Achado do dia:** as policies
      do bot **não filtram por `bucket_id`** — hoje funciona porque só existe o
      bucket de export, mas quando existir bucket de anexo de paciente só o
      superadmin vai conseguir ler/gravar. Registrar como dívida.
- [ ] T002 [arthur] **A3 / V-24** — no SQL editor:
      `select level, count(*) from chart_of_accounts where clinic_id = '<clínica do Vinícius>' and active group by level;`
      **Diagnóstico já feito no código:** `chart-account-select.tsx:49` filtra
      `analyticalOnly → level === 3`. Se não houver linha de nível 3 ativa, o
      combobox vem vazio e o lançamento trava — que é exatamente o relato.
      Zero linhas nível 3 ⇒ o `seed_chart_of_accounts` não rodou para essa
      clínica ⇒ **faixa A, correção por SQL**, não por front.
- [ ] T003 [arthur] **A6** — export do banco antes de qualquer escrita.
      ⚠️ "Remove Lovable Cloud" fica logo abaixo do botão e apaga o banco.
- [ ] T004 [arthur] **A4 / V-04** — reteste do convite de equipe. Item mais
      barato da trava: fecha sem uma linha de código e é a única prova possível
      do T017. Roteiro de 8 passos na triagem, seção V-04.

## Fase 1 — Relatórios  (obrigatórios em 01/09 pela D-8)

- [ ] T005 **V-26 + V-27 — reconferir antes de corrigir.** Hipótese registrada:
      eram sintoma do V-22 (data indo para setembro) somado ao corte de
      materialização de despesa fixa, ambos já corrigidos (`7eff4cf`,
      `88df535`). **Não corrigir antes de reproduzir.** O código de
      `RelatorioContasPagar.tsx` foi lido hoje e a consulta está correta —
      filtra `due_date`/`paid_at` por intervalo, sem erro aparente.
- [ ] T006 **V-29 — separar valor orçado de valor fechado** (D-12).
      **Causa confirmada por leitura:** `RelatorioProdutividade.tsx:59` consulta
      `appointment_items` com `.eq("approval_status", "aprovado")` e soma
      `sold_value` (linha 124). Ou seja: só o **aprovado**, exibido como se
      fosse o orçado. A tabela já tem as duas colunas — `prescribed_value` e
      `sold_value`. Correção: remover o filtro de aprovação, somar
      `prescribed_value` de **todos** os itens como orçado, `sold_value` dos
      aprovados como fechado, e derivar a conversão.
      Caso de teste da D-12: 1.800 orçado / 1.600 fechado.
- [ ] T007 [P] **V-28A — datas personalizadas nos relatórios.** O componente já
      existe: `nx-range-calendar.tsx`, criado em 21/08 (`6b03f6c`) — mas foi
      ligado **só ao `Dashboard.tsx`**. Os relatórios seguem no
      `DateRangeFilter` antigo. Estender aos sete relatórios.
- [ ] T008 **V-25 — Relatório de Vendas por item do orçamento** (D-10). O maior
      item da fase. **Causa confirmada:** `RelatorioVendas.tsx:52` lê de
      `receivables` — uma linha por recebível/parcela. Daí as "vendas quebradas
      em diversas linhas". Deve ler de `appointment_items` (aprovados), com
      `quantity`, e juntar `appointments.doctor` (prescritor) e
      `appointments.responsible` (responsável pela venda), puxando meio de
      pagamento/parcelas/taxa dos recebíveis vinculados.
      Nove colunas na ordem que o Vinícius pediu: data · valor individual ·
      quantidade · valor pago · forma de pagamento · parcelas · médico
      prescritor · responsável pela venda · taxas.
- [ ] T009 [aceite] Baixar os quatro relatórios em xlsx e conferir contra
      lançamento feito à mão.

## Fase 2 — Atribuição e financeiro gravado  (faixa A: muda o que fica gravado)

- [ ] T010 **V-18 + V-20 — a entrada abate a consulta, não a prescrição** (D-3).
      Escopo desta janela, fixado pela D-3 e **não reabrir**: total a receber
      soma consulta + prescrição; a entrada abate a consulta; adiantamento para
      de contar como venda. O redesenho em dois blocos com pagamento
      independente **não entra antes de 01/09**.
- [ ] T011 **V-12 — consulta avulsa gera as tarefas automáticas.**
      `createAppointmentTasks` (`lib/tasksAutomation.ts`) é chamada pelo
      `LeadToAppointmentWizard`; o caminho avulso não a chama.
- [ ] T012 **V-11 — responsável obrigatório na consulta avulsa** (D-2). Sem
      fallback para o médico e sem tarefa órfã. É o que torna T011, T013
      implementáveis com uma regra só.
- [ ] T013 **V-15 + V-16 — tarefa de recaptação e de remarcação vão para o
      responsável pela venda, não para o médico.** Mesmo ponto de código
      (`AppointmentStatusDialogs.tsx`); mesmo commit.
- [ ] T014 [P] **V-19 — fechamento parcial exibido como "fechamento total".**
- [ ] T015 [aceite] Ciclo completo: consulta avulsa → tarefas nascem com
      responsável certo → comparecer com entrada → orçamento aprovado → tela
      financeira soma consulta + prescrição com a entrada abatendo a consulta.

## Fase 3 — Integridade de cadastro e agenda

- [ ] T016 **V-04B — linha órfã em `team_members`.** `ConfigTeamDialog` insere
      antes de confirmar o sucesso do convite; cada tentativa deixa uma
      duplicata. Reordenar: só gravar após sucesso, ou reverter na falha.
- [ ] T017 [arthur] Apagar por SQL as duplicatas já existentes nas clínicas de
      teste, inclusive a do Vinícius.
- [ ] T018 **V-32 — fuso na HORA da consulta.** Digitado 10:00, exibe 07:00 —
      deslocamento de 3h (UTC-3) aplicado onde não devia. Bug novo, achado em
      20/08, **não veio de bateria**. Mesma família do fuso já corrigido, mas
      em `datetime`, não em `date`: `appointments.date` carrega data e hora numa
      coluna só. O `dataLocal()` existente resolve só a parte de data — a hora
      precisa do equivalente.
      **Atrapalha muito: hora errada é paciente chegando na hora errada.**
- [ ] T019 **V-24 — plano de contas no lançamento avulso.** Canal decidido pelo
      resultado de T002: sem linha nível 3 ⇒ SQL (seed); com linhas ⇒ front.
- [ ] T020 [P] **V-10 — agenda avisa e deixa confirmar** (D-4). Não bloquear:
      bloqueio duro faz a secretária burlar criando consulta em horário falso.
- [ ] T021 [aceite] Provar cada um na tela.

## Fase 4 — D-13: taxa de maquininha como despesa  (ISOLADA — risco alto)

> **Não fatiar.** As três partes vão juntas ou o número fica errado.

- [ ] T022 [arthur] **Decisão de backfill.** O trigger só pega inserção nova.
      Mudar o DRE para bruto sem backfill infla a receita histórica. Como hoje
      só há dado de teste e o 1º cliente entra em 01/09, a saída mais limpa é
      provavelmente **limpar e começar do zero** — mas é decisão do Arthur.
- [ ] T023 Aplicar o trigger preparado em
      `specs/002-seguranca-anamnese-auditoria/preparado/d13-taxa-como-despesa.sql`
      (conta `8.1.1 — Despesas Bancárias`, já existe no seed; despesa nasce
      `pago`, com `due_date` = data de crédito do recebível).
- [ ] T024 **DRE passa a somar `gross_value`** em vez de `net_value`, senão a
      taxa desconta duas vezes.
- [ ] T025 **Uniformizar `receivables.value`.** Inconsistência que **já existe
      hoje, antes da D-13**: `ContasReceber.tsx:225` grava o **líquido**; os
      outros cinco caminhos gravam o **bruto**. O Fluxo de Caixa soma `r.value`
      — ou seja, já mistura os dois.
- [ ] T026 [aceite] Com uma venda no crédito: o extrato bate com o líquido; o
      DRE mostra receita bruta e linha de taxa separadas; a soma **não**
      desconta duas vezes.

## Fase 5 — Faixa C barata  (só se sobrar dia)

- [ ] T027 [P] **V-01** — scroll da lista de especialidades no cadastro do médico.
- [ ] T028 [P] **V-03** — botão de ver a senha no login. Classificado backlog
      pela regra, mas o Vinícius marcou "atrapalha muito" e o conserto é de
      minutos.
- [ ] T029 [P] **V-02 / V-06** — mensagem de boas-vindas e de conclusão da
      anamnese.

---

## Dependências

```
T001..T004 (Arthur)  ─┬─▶ T019 depende de T002
                      └─▶ T023 depende de T003 (export) e T022 (backfill)

F1 (T005→T009)  ─▶  F2 (T010→T015)  ─▶  F3 (T016→T021)  ─▶  F4 (T022→T026)
                                                          F5 solta
```

T005 vem primeiro de propósito: se V-26/V-27 já caíram, a fase encolhe e sobra
dia para o V-25, que é o maior.

## O gate que não é meu

**Nenhum item chega ao cliente sem o Publish do Arthur.** Não existe CLI para
publicar na Lovable. Eu commito e envio; o clique é dele — e o
`bash scripts/ponte.sh conferir` é o que separa "publiquei" de "achei que
publiquei".
