# SPEC 004 — Histórico de execução

> Narrativa das quatro rodadas de 23/08/2026, na ordem em que aconteceram.
> **O estado atual de cada item vive em `tasks.md`** — este arquivo existe para
> preservar *como* cada causa foi encontrada, que é o que não cabe numa tabela
> de estado e é o que evita repetir a investigação.

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


---

## QUARTA RODADA — layout e responsividade (23/08, noite)

Commit `a7531e0`. Dois apontamentos novos do Arthur, fora da bateria.

### O calendário empurrava o dashboard

Era renderizado **inline**, no fluxo do documento. Abrir o "Personalizado"
empurrava o card de faturamento para baixo — o usuário perdia de vista o número
que ia filtrar. Virou popover, com colisão automática, **rascunho e botão
"Aplicar período"**: antes o `onChange` disparava já na primeira ponta, com o
fim igual ao início, e o painel piscava um período de um dia. Uma consulta por
escolha, não uma por clique.

### O layout não era responsivo — era de dois saltos

1.900 linhas de CSS com **duas** media queries (1200 e 800). Entre elas, o
buraco onde vive a maior parte dos notebooks. E a causa direta da queixa da TV
de 32": `.nx-content` tinha `max-width: 1500px` **sem `margin auto`** — numa
tela de 2560 o conteúdo ficava preso à esquerda com um vazio enorme à direita.

Três camadas, na ordem em que resolvem:
1. **Grids intrínsecos** — `repeat(auto-fit, minmax(min(Xpx,100%), 1fr))` nas
   cinco linhas principais. Refluem sozinhos, sem breakpoint.
2. **Tipografia fluida** — `clamp()` no título, no número do herói e nos KPIs.
3. **Media queries só para estrutura** — a barra lateral, com pontos novos em
   1100 (só ícones) e 560 (sai do fluxo).

Mais duas fontes de rolagem horizontal, achadas **medindo**:
- filho de grid tem `min-width: auto` e não encolhe abaixo do conteúdo — no
  celular a coluna `1fr` estourava para 408px numa tela de 390;
- o cabeçalho não quebrava linha e empurrava o seletor de período para fora.

**Medido em cinco resoluções, dentro do esqueleto real do `NxAppShell`:**

| tela | colunas | título | herói | overflow-x | centralizado |
|---|---|---|---|---|---|
| TV 2560 | 6 | 38px | 68px | não | sim |
| Monitor 1920 | 6 | 38px | 68px | não | sim |
| Notebook 1366 | 4 | 37px | 61px | não | sim |
| Tablet 820 | 3 | 29px | 42px | não | sim |
| Celular 390 | 1 | 26px | 38px | não | sim |

### O que NÃO consigo verificar, e por quê

A política de rede deste ambiente bloqueia `nexclin.lovable.app` **e**
`lovable.dev` — ambos respondem `http=000` no CONNECT. Não é sessão nem login:
o pacote não sai daqui. Testado duas vezes, em momentos diferentes.

Então V-21.6 e V-21.2 não têm como ser provados por mim. O que entrego no lugar
é `2026-08-23-roteiro-verificacao.md`: sete testes com números
esperados e tabela de interpretação — inclusive o que cada resultado
*significa*, para o teste não virar "apareceu / não apareceu".
