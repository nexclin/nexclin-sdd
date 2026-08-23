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

- [x] T005 **V-26 + V-27 — reconferir antes de corrigir.** Hipótese registrada:
      eram sintoma do V-22 (data indo para setembro) somado ao corte de
      materialização de despesa fixa, ambos já corrigidos (`7eff4cf`,
      `88df535`). **Não corrigir antes de reproduzir.** O código de
      `RelatorioContasPagar.tsx` foi lido hoje e a consulta está correta —
      filtra `due_date`/`paid_at` por intervalo, sem erro aparente.
- [x] T006 **V-29 — separar valor orçado de valor fechado** (D-12).
      **Causa confirmada por leitura:** `RelatorioProdutividade.tsx:59` consulta
      `appointment_items` com `.eq("approval_status", "aprovado")` e soma
      `sold_value` (linha 124). Ou seja: só o **aprovado**, exibido como se
      fosse o orçado. A tabela já tem as duas colunas — `prescribed_value` e
      `sold_value`. Correção: remover o filtro de aprovação, somar
      `prescribed_value` de **todos** os itens como orçado, `sold_value` dos
      aprovados como fechado, e derivar a conversão.
      Caso de teste da D-12: 1.800 orçado / 1.600 fechado.
- [x] T007 [P] **V-28A — datas personalizadas nos relatórios.** O componente já
      existe: `nx-range-calendar.tsx`, criado em 21/08 (`6b03f6c`) — mas foi
      ligado **só ao `Dashboard.tsx`**. Os relatórios seguem no
      `DateRangeFilter` antigo. Estender aos sete relatórios.
- [x] T008 **V-25 — Relatório de Vendas por item do orçamento** (D-10). O maior
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

- [x] T010 **V-18 + V-20 — a entrada abate a consulta, não a prescrição** (D-3).
      Escopo desta janela, fixado pela D-3 e **não reabrir**: total a receber
      soma consulta + prescrição; a entrada abate a consulta; adiantamento para
      de contar como venda. O redesenho em dois blocos com pagamento
      independente **não entra antes de 01/09**.
- [x] T011 **V-12 — consulta avulsa gera as tarefas automáticas.**
      `createAppointmentTasks` (`lib/tasksAutomation.ts`) é chamada pelo
      `LeadToAppointmentWizard`; o caminho avulso não a chama.
- [x] T012 **V-11 — responsável obrigatório na consulta avulsa** (D-2). Sem
      fallback para o médico e sem tarefa órfã. É o que torna T011, T013
      implementáveis com uma regra só.
- [x] T013 **V-15 + V-16 — tarefa de recaptação e de remarcação vão para o
      responsável pela venda, não para o médico.** Mesmo ponto de código
      (`AppointmentStatusDialogs.tsx`); mesmo commit.
- [x] T014 [P] **V-19 — fechamento parcial exibido como "fechamento total".**
- [ ] T015 [aceite] Ciclo completo: consulta avulsa → tarefas nascem com
      responsável certo → comparecer com entrada → orçamento aprovado → tela
      financeira soma consulta + prescrição com a entrada abatendo a consulta.

## Fase 3 — Integridade de cadastro e agenda

- [x] T016 **V-04B — linha órfã em `team_members`.** `ConfigTeamDialog` insere
      antes de confirmar o sucesso do convite; cada tentativa deixa uma
      duplicata. Reordenar: só gravar após sucesso, ou reverter na falha.
- [ ] T017 [arthur] Apagar por SQL as duplicatas já existentes nas clínicas de
      teste, inclusive a do Vinícius.
- [x] T018 **V-32 — fuso na HORA da consulta.** Digitado 10:00, exibe 07:00 —
      deslocamento de 3h (UTC-3) aplicado onde não devia. Bug novo, achado em
      20/08, **não veio de bateria**. Mesma família do fuso já corrigido, mas
      em `datetime`, não em `date`: `appointments.date` carrega data e hora numa
      coluna só. O `dataLocal()` existente resolve só a parte de data — a hora
      precisa do equivalente.
      **Atrapalha muito: hora errada é paciente chegando na hora errada.**
- [ ] T019 **V-24 — plano de contas no lançamento avulso.** Canal decidido pelo
      resultado de T002: sem linha nível 3 ⇒ SQL (seed); com linhas ⇒ front.
- [x] T020 [P] **V-10 — agenda avisa e deixa confirmar** (D-4). Não bloquear:
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

- [x] T027 [P] **V-01** — scroll da lista de especialidades no cadastro do médico.
- [x] T028 [P] **V-03** — botão de ver a senha no login. Classificado backlog
      pela regra, mas o Vinícius marcou "atrapalha muito" e o conserto é de
      minutos.
- [ ] T029 [P] **V-02 / V-06** — mensagem de boas-vindas e de conclusão da
      anamnese. **NÃO FEITO, de propósito.** São os dois únicos itens puramente
      cosméticos do lote (severidade "cosmético", `Atrapalha muito: Não`) e não
      têm dado nem regra atrás. Pela D-7 viram requisito da stack nova. Foram
      mantidos aqui só para constar que a decisão foi tomada, não esquecida.

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


---

## LOG DE EXECUÇÃO — 23/08/2026

Enviado à plataforma em três lotes. **Nenhum publicado ainda** — o Publish é
manual e é do Arthur. Até o aceite na tela, tudo abaixo é *"código lido e
simulado, não comportamento provado"*.

| Commit | Itens | Verificação feita aqui |
|---|---|---|
| `8ad3a15` | V-29, V-25, V-28A | `tsc` limpo + simulação numérica dos dois casos do Vinícius |
| `be92a38` | V-18, V-20 | `tsc` limpo + 4 casos de abatimento simulados |
| `1dbf842` | V-32, V-15, V-16, V-11, V-12, V-04B | `tsc` limpo + round-trip de fuso em `America/Sao_Paulo` |

### As causas raiz, que quase todas diferiam da aposta da triagem

- **V-18 — é estrutural, e é o achado mais grave do dia.**
  `appointments.consultation_type_id` **não tem chave estrangeira**. O seletor
  "Tipo de Consulta" lista `services` (macro_category = Consulta) e grava um
  **`services.id`**; todo o cálculo procurava esse id em **`consultation_types`**.
  O `.find()` nunca casava, `consultationValue` era **sempre 0**, e o "Total a
  pagar" trazia só a prescrição. Sem FK, nada acusava a troca.
  → **Requisito da stack nova:** um conceito, uma tabela, com FK. Duas tabelas
  para "tipo de consulta" não podem renascer. Entra na spec do módulo de
  consultas.

- **V-29 — havia uma segunda cópia da regra, e a certa já existia.**
  `useFinancialBreakdown` já calculava orçado × fechado exatamente como a D-12
  manda. O relatório tinha uma cópia própria, escrita à mão e errada. **É a
  mesma doença do V-22** (a regra de data duplicada dentro de
  `onPaymentMethodChange`). Duas ocorrências do mesmo padrão em um lote já é
  sinal: regra de dinheiro duplicada no front é a fonte recorrente de erro
  deste código.

- **V-25 — a quebra era por PARCELA, não por item.** `receivables` já tem
  `item` e `quantity`; o que multiplica linha é `installment_number`. Uma venda
  em 3x virava 3 linhas. Agrupar por (atendimento, item, meio, parcelas)
  resolve sem tocar em valor — e o Vinícius já dizia que *"os valores batiam
  certinho"*.

- **V-28A — meio caminho já estava andado sem registro.** O `nx-range-calendar`
  foi criado em 21/08 e ligado **só ao Dashboard**. Movido para dentro do
  `DateRangeFilter`, alcança os 7 relatórios **e mais 9 telas**.

### Achados novos, não vieram de bateria

- **V-33 — `tasks.due_date` é `TIMESTAMPTZ` e recebia data pura.** Em três
  pontos (`Tarefas.tsx`, e duas tarefas automáticas em `Acompanhamento.tsx`)
  gravava-se `"2026-08-23"`, que vira meia-noite UTC = **21:00 do dia anterior**
  no Brasil. A tarefa aparecia um dia cedo. Mesma família do V-32, corrigido no
  mesmo lote. **Faixa A: o instante errado fica gravado.**

- **V-34 — centavo perdido no parcelamento.** `perInstallment = itemTotal /
  installments` com arredondamento por parcela: R$ 1.000 em 3x soma R$ 999,99.
  Some um centavo por venda parcelada. Não corrigido — é do caminho de escrita
  e o conserto certo é a última parcela absorver a diferença. **Registrar na
  spec do financeiro da stack nova.**

- **Dívida do storage (do adendo do handoff).** As policies que o bot criou em
  `storage.objects` **não filtram por `bucket_id`**. Hoje funciona porque só
  existe o bucket de export; quando existir bucket de anexo de paciente, só o
  superadmin conseguirá ler ou gravar, e o upload falhará sem explicação.

### Ainda bloqueado no Arthur

`T001` (A-SEC, `storage.objects`) · `T002` (A3, plano de contas do V-24) ·
`T004` (A4, reteste do convite — mais relevante agora, porque o T016 mexeu
nesse fluxo) · `T003` (export, gate da Fase 4).


---

## SEGUNDA RODADA — `/speckit-implement`, 23/08/2026

Commit `a239dec`. Gate de tipos limpo. **Não publicado.**

### V-27 é o achado mais grave depois do V-18 — e também não era o que se supunha

A triagem apostava que V-26 e V-27 eram sintomas do V-22 (data indo para
setembro). **Nenhum dos dois era.**

O DRE buscava as entradas realizadas na tabela **`revenues`**. Ela existe no
schema, mas **nenhum caminho do app escreve nela** — nem fechamento, nem
lançamento avulso, nem recebimento. Todo o dinheiro entra em `receivables`.
O bloco de entradas do DRE era **permanentemente zero**, com qualquer período,
para qualquer clínica, desde sempre.

Mais quatro telas leem `revenues` e recebem o mesmo vazio:

| Tela | Efeito | Situação |
|---|---|---|
| `RelatorioDfcDre` | entradas zeradas | **corrigido** |
| `FluxoCaixa` | lê `receivables` **e** `revenues`; funciona pelo primeiro | sem efeito prático |
| `RelatorioRepasse` | zerado | **não corrigido — ver abaixo** |
| `Dashboard` | parte dos cards zerada | rebaixado pela D-8 |
| `Insights` | zerado | fora da Onda 1 |

**Por que não corrigi o repasse:** ele está fora da Onda 1 de propósito — o
plano de lançamento registra que tem *"imposto fixado em zero e atribuição de
profissional estimada"* e que *"para um público de médicos, é o relatório mais
sensível que existe"*. Fazer as entradas aparecerem sem resolver imposto e
atribuição entrega um número **plausível e errado** a médicos que conferem
repasse — pior que um relatório visivelmente vazio. Fica como requisito da
stack nova, com a regra de repasse escrita antes do código.

**E V-26 foi reconferido sem alteração.** `RelatorioContasPagar` está correto:
filtra `expenses` por `due_date`/`paid_at` no intervalo. O vazio vinha da
despesa fixa não materializada no mês corrente — já corrigido em `88df535`.
A instrução da T005 era "não corrija antes de reproduzir"; reproduzi por
leitura e não mexi.

### Os outros três

- **V-19** — o rótulo contava só ITENS aprovados. Aprovar 2 das 3 doses também
  é retirar alguma coisa, e a regra do Vinícius é literal: *"se qualquer coisa
  foi retirada, é fechamento parcial"*. Passa a detectar redução de quantidade.
- **V-10 / D-4** — a agenda avisa com o nome de quem já está marcado e oferece
  "Confirmar encaixe". Não bloqueia: bloqueio duro faz a secretária criar
  consulta em horário falso, corrompendo a agenda em vez de protegê-la.
- **V-01** — `SelectContent` não tinha teto ligado à altura disponível na
  janela, então o Radix não ativava os botões de rolagem. Corrigido no
  componente compartilhado: vale para todos os selects do app.

### Achado de segurança — precisa do Arthur

**Existe um `.env` versionado em `nexclin/nexclin`.** Tentei listar apenas os
NOMES das chaves (sem valores) e a regra de permissão do repositório bloqueou
a leitura — corretamente, e **não contornei**.

Precisa ser conferido à mão. Se contiver só `VITE_SUPABASE_URL` e a chave
**anon**, está tudo bem: a anon é pública por desenho e quem protege é a RLS.
Se contiver `service_role`, é vazamento crítico — essa chave ignora RLS, está
no histórico do git e **não sai com `rm`**: exige rotação no painel do Supabase.

Princípio V da constituição: *"Nenhuma credencial deve aparecer em código, spec
ou arquivo versionado."*

### Inconsistência da constituição, para corrigir num `/speckit-constitution`

O Princípio IV ainda diz que `../nexclin-lovable` é **somente leitura**. Desde
a criação da ponte inversa (17/08) isso deixou de valer — o `CLAUDE.md` §4(i)
já registra a mudança de papel, mas a constituição v1.0.0 não foi atualizada.
Como a constituição vence as rules em conflito, o texto precisa acompanhar,
senão o próximo executor lê a lei e para.


---

## TERCEIRA RODADA — 23/08, fim do dia

Commits na plataforma: `63f87a4`, `799c82d`, `3287cf9`. Gate de tipos limpo nos
três. **Nenhum publicado.**

### O erro de teste que o Arthur pegou, e o que ele ensina

Mandei uma captura do calendário em teal. Ele abriu e viu **preto**. As duas
coisas eram verdade.

Existe em `nx-dashboard.css` uma regra global de botão de ação —
`.nx-content button.bg-primary { background: var(--navy-deep) }` — com
especificidade maior que qualquer utilitário do Tailwind. O dia do calendário é
um `<button>`. E em modo **intervalo** o react-day-picker marca **todos** os
dias do período como `selected`, então todos herdavam `bg-primary` e o intervalo
inteiro saía navy `#141C28`.

**Meu harness não reproduziu porque não envolvia o componente em
`.nx-root > .nx-content`** — que é o que o `NxAppShell` faz em todo o app.
Testei o componente fora do lugar onde ele vive.

> **Regra que sai daí, e vale para o Princípio IX:** harness que não replica os
> wrappers reais do app não é verificação — é uma segunda opinião sobre o mesmo
> palpite. O sinal de que ficou fiel foi a tipografia: depois de corrigido, a
> captura passou a mostrar o cabeçalho em maiúsculas, igual à tela dele.

A correção evita a classe **literal** `bg-primary`, usando o mesmo token por
valor arbitrário. Há comentário no arquivo avisando para não voltar atrás.

### O achado financeiro mais grave do dia

Investigando por que a conversão dava 100% com item reprovado (V-21.3),
apareceu uma **multiplicação dupla**.

`appointment_items` guarda unidades diferentes no mesmo par de colunas:

| Coluna | O que guarda |
|---|---|
| `prescribed_value` | valor **unitário** |
| `sold_value` | **total**, já multiplicado pela quantidade aprovada |

Então `prescribed_value * quantity` está certo e `sold_value * quantity`
multiplica duas vezes. **Três leitores faziam isso — e um deles fui eu**, no
V-29 de hoje mais cedo.

Simulado com o caso do Vinícius (vit D 2×200, tirzepatida 2×200, soro 2×500,
uma dose reprovada):

| | valor |
|---|---|
| orçado | 1800 ✓ |
| fechado **com** a multiplicação | **3200** ✗ |
| fechado **sem** a multiplicação | 1600 ✓ |
| conversão errada | **177,8%** |
| conversão certa | 88,9% |

Com quantidade 2 o fator é exatamente 2×. Estourando o teto, a taxa aparecia
achatada em 100% — literalmente o que foi relatado.

### Dashboard entrou, e a razão é o Erick

A D-8 rebaixou o dashboard porque o time do Vinícius não usa. Mas a bateria do
Erick é **visão geral de gestão**: ele abre o dashboard primeiro. Deixá-lo
quebrado queima a passada dele.

- **V-21.1** (TOTAL CONSULTAS zerado) — mesma causa raiz do V-18 propagando:
  `useFinancialBreakdown` procurava `consultation_type_id` só em
  `consultation_types`, mas a tela grava ali um `services.id`. O comentário no
  topo do próprio arquivo já dizia *"consultation_type (ou service
  equivalente)"* — a intenção estava certa, o código não.
- **V-13** — a contagem de 1ª vez saía de **todas** as consultas do período,
  inclusive canceladas, mas é exibida como contexto do card CONSULTAS, que
  conta só as realizadas. Duas bases no mesmo número.
- **V-14** — a entrada nascia sem `macro_category`, então todo lugar que
  classifica receita por essa coluna a jogava em VENDAS. Faixa A: a
  classificação fica gravada.
- Drill-down "Receitas" lia de `revenues` (a tabela que ninguém escreve).

### Dívidas de modelo para a stack nova — não são backlog, são requisito

1. **`appointment_items` guarda unidades diferentes no mesmo par de colunas.**
   Violação direta do Princípio VIII. Consertar muda o que fica **gravado** e
   exige migração com backfill — não se faz na véspera da bateria. Por ora, os
   leitores foram alinhados e há nota grande em `Dashboard.tsx`.
2. **`appointments.consultation_type_id` sem FK, apontando para duas tabelas.**
   Causa raiz de V-18 e V-21.1. Na stack nova: um conceito, uma tabela, com FK.
3. **`revenues` existe e ninguém escreve.** Ou passa a ser alimentada, ou é
   removida. Coluna morta que alimenta relatório é pior que coluna ausente:
   falha em silêncio.

### Não corrigido, e por quê

- **V-21.6** (gráfico do fluxo de caixa) — o gráfico já lê de `receivables`, não
  de `revenues`. Sem dado ao vivo não consigo reproduzir, e a T005 me diz para
  não corrigir antes de reproduzir. Fica para o aceite do Arthur dizer se ainda
  ocorre.
- **V-21.2** (ticket médio por orçamento, D-9) — o cálculo já é
  `consolidado / nº de closings`, que é por orçamento fechado. Provavelmente
  parecia errado só porque `consultaGross` era zero. Reconferir no aceite.
