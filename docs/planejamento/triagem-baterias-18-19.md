# Triagem — Baterias de teste do Vinícius (18 e 19/08/2026)

> **Regra de classificação** (do plano de lançamento, não reinterpretada):
> **Bug** = o sistema faz algo errado ou não faz o que deveria. Correção antes
> do lançamento. **Backlog** = o sistema faz certo, mas poderia fazer diferente
> ou a mais. Registrado, entra depois. **Na dúvida, marca-se bug.**
> A **trava de lançamento** é a contagem de bugs abertos com "Atrapalha muito:
> Sim" na base Apontamentos do Notion — precisa chegar a zero antes de abrir
> para cliente.

**Fontes triadas:** `Bateria de testes — 1808.txt` (9 apontamentos) e
`Bateria de testes — 1908.txt` (20 apontamentos + 2 "Extras"). O bloco de
credencial de teste no topo do arquivo de 18/08 foi ignorado e não é
reproduzido em lugar nenhum deste documento.

**Contexto usado para separar desvio de regra funcionando:**
`INVENTARIO-UI.md` (comportamento real das telas), `INVENTARIO.md §3.4`
(regras de negócio embutidas), `docs/planejamento/bateria-testes-vinicius-17-21.md`
(o plano da bateria) e `docs/ponte/ponte-inversa.md` (canais de correção).

## DECISÕES DO ARTHUR — 20/08/2026

Tomadas em sessão, com as consequências à vista. Substituem as perguntas em
aberto da seção `precisa-decisao` no final deste documento; onde houver
divergência, **vale o que está aqui**.

| # | Decisão | Efeito |
|---|---|---|
| ~~**D-1**~~ | ~~**Trava de lançamento = zero absoluto antes de abrir.**~~ **REVOGADA no mesmo dia pela D-7** — ver abaixo. Mantida aqui visível, não apagada, porque a mudança de critério é a informação importante, não a decisão final. | Vale a regra do plano, não a correção gradual. **Consequência aceita explicitamente: com a leva do Erick ainda por vir (24–26/08), a data de 01/09 passa a depender de fechar 23 itens desta leva mais o que ele apontar.** Se a conta não fechar, o que move é a data — não o critério. |
| **D-2** | **ATR-1 → responsável obrigatório na consulta avulsa.** Não existe tarefa órfã nem fallback para o médico. | **Puxa o V-11 do backlog para esta janela.** A trava sobe de 22 para 23. Em troca, resolve V-11, V-15 e V-16 com uma regra só, em vez de conviver com duas regras na mesma tela. |
| **D-3** | **FIN-1 → fix mínimo agora.** Nesta janela: a entrada deixa de virar desconto da prescrição e passa a abater a consulta; o adiantamento para de contar como venda; o total a receber soma consulta + prescrição. | O redesenho em dois blocos com pagamento independente por bloco **não entra antes de 01/09** — vira backlog imediato pós-lançamento, com data. Fecha a trava sem mexer em recebível a 12 dias da abertura, que é onde erro custa dinheiro do cliente. |
| **D-4** | **V-10 (agenda) → avisar, não bloquear.** Ao marcar em horário já ocupado do mesmo profissional, o sistema alerta e permite confirmar. | Cobre o encaixe e o overbooking, que clínica real faz de propósito. Bloqueio duro faria o usuário burlar criando consulta em horário falso — o que corromperia a agenda em vez de protegê-la. |
| **D-5** | **V-22/V-23 (crédito) → antecipação é configuração da clínica.** Um ajuste em Configurações, junto das taxas que já existem: "antecipa recebimento de crédito?". | Vale para todas as vendas, sem clique extra por lançamento e sem mexer no cadastro de taxas agora. A escolha por venda e a escolha por bandeira ficam registradas como evolução possível, não como escopo. |
| **D-6** | **DASH-1 (ticket médio) → BLOQUEADO, pergunta devolvida ao Vinícius.** O relato dele se contradiz: diz "por itens vendidos, não por paciente" e, na sequência, "levasse em consideração a quantidade de orçamentos". | **V-13 e V-21 não começam** até a resposta. A pergunta está escrita em `docs/planejamento/perguntas-vinicius-20-08.md`, pronta para enviar. É o único item da trava parado por dependência externa. |

### D-7 — O critério que substitui a trava de lançamento (20/08/2026)

A D-1 durou algumas horas. O Arthur reformulou o problema, e a formulação nova
é mais precisa:

> A plataforma Lovable é **temporária**. Vive cerca de um mês, até fechar os 30
> dias dos clientes fundadores; a stack Next.js deve estar pronta em outubro. Os
> fundadores entram **de graça**, e o compromisso é entregar o que foi
> prometido — um software de gestão em lançamento, com os problemas de um
> lançamento. **Não precisa ser perfeito.**
>
> Corrigir só vale quando a correção **atravessa** para a stack nova. Fora
> disso é polir o que será descartado.

**A consequência que mais importa:** na maior parte dos itens, o que atravessa
**não é o código — é a regra escrita**. O front React/Vite do Lovable será
reescrito em Next.js de todo jeito. O que sobrevive é a decisão de *como o
sistema deve se comportar*, e essa parte **já está paga**: é este documento.

Por isso a pergunta de cada item deixa de ser *"é bug que atrapalha muito?"* e
passa a ser:

| Faixa | Pergunta | O que fazer na plataforma |
|---|---|---|
| **A — atravessa como banco** | A correção é migração, RLS, trigger ou coluna? | **Corrigir.** As 55 migrações vão intactas para a stack nova (CLAUDE.md §2.4). Aqui o código é o artefato durável. |
| **B — atravessa como regra** | A correção depende de uma regra que a stack nova também vai precisar? | **Escrever a regra** (feito neste documento). Implementar na Lovable só se o fundador esbarrar nela no uso. |
| **C — não atravessa** | É front, layout, mensagem, comportamento de tela? | **Não corrigir**, salvo se impedir o fundador de usar o que foi prometido. Vira requisito da stack nova. |

**E os itens de backlog deixam de ser "depois".** O Arthur quer a stack nova
nascendo sem bug e sem backlog. Então V-05, V-07, V-08, V-09, V-30 e V-31 não
são trabalho adiado: são **requisitos da stack nova**, e devem entrar nas specs
dos módulos correspondentes em vez de dormir numa lista.

**A trava de lançamento (23) deixa de ser critério de abertura.** Continua útil
como termômetro do que o fundador vai encontrar, e para saber o que dizer a ele
— não como portão.

---

**Decisão menor, tomada por mim e registrada para você discordar se quiser:**
o **V-03** (login sem botão de ver a senha) está classificado como backlog pela
regra — o sistema não faz nada errado, falta um recurso. Mas o Vinícius marcou
"Atrapalha muito: Sim", ele relata ter errado a senha sem saber onde, e o
conserto é de minutos. **Vai junto na janela**, apesar do rótulo. Não conta na
trava.

---

## RESPOSTAS DO VINÍCIUS — 20/08/2026, e a inversão que elas provocam

As quatro perguntas voltaram respondidas, e veio junto um áudio que muda a
prioridade do lote inteiro. Isto é mais recente que a seção D-7 e que a
classificação em faixas; **onde divergir, vale o que está aqui.**

### D-8 — Os relatórios saem da faixa B. São o que precisa funcionar em 01/09.

Palavras dele, transcritas:

> "Onde que eles vão buscar informação? No dashboard? Lógico que não, **a gente
> não entra no dashboard**. O dashboard é só a visão ali pro médico, é uma coisa
> simples. A gente vai buscar exatamente nos **relatórios**, a gente vai baixar
> essas bases. Se as bases de dados estão erradas, os relatórios estão vindo
> errados, a gente não tem consistência. (…) Pelo menos os relatórios, cara,
> eles têm que estar rodando muito bem no dia primeiro."

O contexto importa: o time dele **puxa as bases semanalmente** e trabalha em
cima delas. Relatório errado não é incômodo de tela — é decisão errada tomada
em cima de número errado, e ele diz na sequência que isso significa perda para
a empresa dele.

**Consequência direta:** eu classifiquei relatório como faixa B — "a regra
escrita basta, implementar na Lovable é opcional". **Está errado.** A §2.5 do
CLAUDE.md prevê exatamente esta exceção: *"não corrigir, salvo se impedir o
fundador de usar o que foi prometido"*. Puxar base semanal É o que foi
prometido ao time dele.

| Item | Antes | Agora |
|---|---|---|
| V-25, V-26, V-27, V-28A, V-28B, V-29 (relatórios) | faixa B — regra escrita bastava | **Faixa A por exceção. Têm de funcionar em 01/09.** |
| V-13, V-21 (dashboard) | trava, prioridade alta | **Rebaixados.** Ele não usa o dashboard; é "visão simples pro médico". A regra fica escrita, a implementação espera a stack nova. |

E reforça o que já sabíamos: **V-22/V-23 continua sendo o item nº 1**. "Se as
**bases de dados** estão erradas, os relatórios vêm errados" — a data do
recebível é base de dados. Corrigi-la é pré-requisito de relatório certo.

### D-9 — Ticket médio: por orçamento aprovado, valor bruto

Resposta literal: *"Ticket médio deve ser calculado por orçamento aprovado. Se
um mesmo paciente tem 3 orçamentos aprovados, em valores diferentes, tem que
contabilizar 3 vezes."*

O exemplo dele, que vira caso de teste:

- Orçamento 1 (19/08): vitamina D 200 + consulta 1000 + tirzepatida 200 = **1400**
- Orçamento 2 (20/08): soro alfalipoico 500 + nandrolona 200 = **700**
- **Ticket médio = (1400 + 700) / 2 = R$ 1.050**

> "O ticket médio desconsidera que ambos os orçamentos foram aprovados para o
> mesmo paciente. Ele apenas mostra o quanto, em média, é fechado em cada venda
> realizada para a clínica."

**Indicador novo, que não existia em lugar nenhum: LTV.** A soma das compras do
mesmo paciente no período — R$ 2.100 no exemplo. Ele chama de *"outro indicador
importante para acompanharmos também"*. **Não é bug de nenhuma bateria: é
requisito novo.** Vai para a stack nova, não para a janela.

### D-10 — Relatório de vendas: uma linha por item, com as colunas dele

Uma linha para **cada item** do orçamento — não uma linha por orçamento, e não
uma linha por dose. Pelo exemplo: orçamento 1 gera 3 linhas, orçamento 2 gera 2.

Colunas exigidas, na ordem em que ele listou: **data da venda · valor
individual · quantidade vendida · valor pago · forma de pagamento · quantidade
de parcelas · médico prescritor · responsável pela venda · taxas**.

As duas últimas são as que faltam hoje e ele já tinha apontado no relato original.

### D-11 — V-17 e V-28B são o mesmo bug: o filtro de DATA

As duas respostas foram idênticas: *"Usei somente o filtro de data, mudando os
períodos."* Tarefas e relatório de Contas a Receber, mesmo comportamento.

**Dois itens da trava viram uma correção.** E há uma pista forte no próprio
repositório: `.claude/rules/app.md` e `INVENTARIO-UI.md §5` registram como dívida
conhecida que **existem três vocabulários de período convivendo no app**. É o
suspeito número um — investigar o componente de período antes de olhar cada tela.

### D-12 — V-29: valor orçado e valor fechado são coisas distintas

Exemplo dele: prescrição de vitamina D (2 doses × 200), tirzepatida (2 × 200) e
soro alfalipoico (2 × 500) = **R$ 1.800 orçado**. O paciente aprovou tudo menos
uma dose de vitamina D → **R$ 1.600 fechado**.

> "Hoje está constando o **valor fechado** como se fosse o valor do orçamento,
> mas não é, são coisas distintas."

O relatório deve trazer as duas colunas. Sem isso não dá para calcular conversão
por profissional, que é o motivo de o relatório existir.

### Confirmado sem ressalva

Ele respondeu **"Ok pra tudo"** à lista de regras que eu havia dado como
fechadas: taxa de conversão, fechamento parcial, novos pacientes, agenda que
avisa em vez de bloquear, tarefa para o responsável pela venda com campo
obrigatório na avulsa, antecipação de crédito como configuração da clínica, e
entrada abatendo a consulta com o desenho em dois blocos adiado.

**Nenhum item ficou `precisa-decisao`.** A lista de bloqueios por dependência
externa está vazia.

---

## V-22/V-23 — CORRIGIDO, PUBLICADO E TESTADO em 20/08/2026

Commit `7eff4cf` na plataforma · bundle `index-Beehpt0v` → `index-BB1AQRtG`.

### O que era, de verdade

A triagem supunha "a regra de data não está implementada". **Estava.** Existe um
helper canônico, `src/lib/paymentFees.ts::computeFeeForMethod`, que faz
exatamente o que o Vinícius descreveu. O problema era uma **segunda cópia da
mesma regra**, escrita à mão dentro de `onPaymentMethodChange`, com três
defeitos:

1. **`if (term)` antes de gravar a data.** Dinheiro e pix têm prazo **zero**;
   `if (0)` é falso, o `setDueDate` não rodava e a data **ficava com a do método
   anterior**. Passar por crédito (+30) e trocar para dinheiro deixava o
   recebível vencendo em 30 dias. **É a causa exata do relato** — e, como a
   investigação de 19/08 previu, também a dos "relatórios zerados": o dado ia
   para setembro e sumia de um relatório filtrado em agosto.
2. **Ignorava a antecipação.** Crédito antecipado ia para +30 em vez de D+1,
   enquanto a taxa exibida na tela já vinha do helper, que considera antecipação.
   Tela e dado discordavam.
3. **Só recalculava ao trocar o método.** Marcar "antecipar" ou mudar parcelas
   deixava a data velha.

E em `LaunchReceivableDialog` um quarto: o prazo **nunca** era aplicado e a taxa
da maquininha **não era descontada** — `net_value` sequer era gravado.

### Aceite manual — executado, não presumido

Na plataforma ao vivo, conta-mestra:

| Passo | Esperado | Observado |
|---|---|---|
| Meio = **Boleto** (prazo 3) | 23/08 | **23/08** ✅ |
| Trocar para **Dinheiro** (prazo 0) | volta para 20/08 | **20/08** ✅ |

O segundo passo é o que prova a correção: antes, o `if (term)` deixaria em 23/08.

Dados de teste criados e **removidos** ao final (paciente e consulta).

### A D-5 fica sem efeito

A decisão de criar uma configuração de clínica "antecipa recebimento de
crédito?" **não deve ser implementada**. O banco já tem `anticipation_default`
**por meio de pagamento**, mais um toggle por venda. A configuração de clínica
seria uma **terceira** fonte de verdade para a mesma pergunta — e a que existe é
melhor, porque antecipação é acordo por maquininha/bandeira, não por clínica.
A pergunta que gerou a D-5 partia de uma premissa errada minha.

### Três achados de passagem, registrados como itens novos

- **V-32 — fuso horário na consulta.** Digitado **10:00**, a lista exibe
  **07:00**. Deslocamento de 3 horas = UTC-3 aplicado onde não devia. Não estava
  em nenhuma bateria. **Bug, atrapalha muito**: hora de consulta errada é
  paciente chegando na hora errada.
- **V-18 reproduzido ao vivo.** Com consulta de R$ 300 e prescrição de R$ 250, o
  "Total geral" mostrou **R$ 250**. Confirma o relato: a consulta não entra no
  valor a receber.
- **`Consultas.tsx` é página órfã.** Não está roteada em `App.tsx`; o menu
  "Consultas" aponta para `/acompanhamento`. Logo o `LaunchReceivableDialog` que
  corrigi é **código morto em produção** — a correção está certa, mas não muda
  nada que o usuário alcance hoje. Vale como preparo para a stack nova.

---

## V-26 — corrigido no clone, AGUARDANDO ENVIO (20/08/2026)

A parte **bug** do V-26 (a parte regra é a D-13, abaixo).

**A causa:** a materialização de despesa fixa cortava por `dueDate >= today`, em
granularidade de **dia**. A intenção — não gerar despesa retroativa — é boa, mas
o corte estava no lugar errado: cadastrar um aluguel no dia 20 com vencimento no
dia 10 **pulava agosto inteiro**, e o relatório do mês vinha vazio sem dizer por
quê.

**A correção:** o corte passa a ser por **mês**. Conta que começa hoje ou no
passado vale o mês corrente inteiro; conta que começa no futuro respeita a data
configurada ao dia.

**Simulado antes de confiar** (`ContasPagar.tsx`, `generateFixedExpenses`):

| Caso | Antes | Depois |
|---|---|---|
| Venc. dia 10, cadastrado dia 20 — o caso relatado | 10/09 (agosto pulado) | **10/08** ✅ |
| Venc. dia 25, cadastrado dia 20 | 25/08 | 25/08 — não regrediu ✅ |
| Início futuro 15/09, venc. dia 5 | 05/09 — **antes do início configurado** | 05/10 ✅ |

**Bug de brinde:** o terceiro caso mostra que o código antigo criava lançamento
**antes da data de início** definida pelo usuário. A mesma correção resolve.

**Estado:** no clone, com `tsc` limpo, **não enviado**. O aceite é cadastrar uma
conta fixa com vencimento já passado no mês e conferir que ela aparece — vencida,
que é o que ela é.

---

## D-13 — A taxa de maquininha é DESPESA (20/08/2026)

Decisão do Arthur, com confirmação do Vinícius no mesmo dia. Fecha o V-26 (parte
regra) e o V-27.

### A regra

> **"É porque já é descontado na fonte, mas é uma despesa."** — Arthur
>
> **"Na DRE tem um campo específico de taxas. Tem que ter. Taxas, custos
> bancários, etc."** — Vinícius

A taxa da adquirente **não deixa de ser custo por ser retida antes de o dinheiro
chegar**. Ela tem de aparecer como despesa, com linha própria no DRE.

**Conta contábil:** `8.1.1 — Despesas Bancárias`, dentro de
`8 DESPESAS FINANCEIRAS → 8.1 Custos financeiros`. **Já existe no seed**
(`seed_chart_of_accounts`), é nível 3 e portanto selecionável no combobox. Não
precisa de migração para criá-la.

### A armadilha que torna isso perigoso

Hoje o recebível guarda **`net_value`** — bruto já menos a taxa. Criar a despesa
por cima disso **desconta duas vezes**. Com R$ 250 no crédito a 3,5% (taxa
R$ 8,75):

| Cenário | Entra no caixa | Despesa | Resultado |
|---|---|---|---|
| Hoje | 241,25 (líquido) | — | 241,25 ✅ — mas a taxa é invisível |
| Despesa criada sem mudar o resto | 241,25 (líquido) | 8,75 | **232,50** ❌ dupla contagem |
| **Correto** | **250,00 (bruto)** | 8,75 | 241,25 ✅ e a taxa aparece |

**Consequência:** a taxa só pode virar despesa se, **na mesma mudança**, o
recebimento passar a entrar pelo **bruto**. Implementar metade corrompe o
resultado — e o resultado é justamente o que o time do Vinícius lê para decidir.

### O desenho

1. O recebível entra no fluxo de caixa pelo **valor bruto**.
2. Junto, nasce um lançamento em `expenses`:
   - `chart_account_id` → `8.1.1 Despesas Bancárias`
   - `value` = bruto × `fee_percent` / 100
   - `due_date` = **a mesma data de crédito do recebível** — é quando a
     adquirente retém
   - `status` = **`pago`** e `paid_at` = a mesma data. Não existe pagamento
     separado a fazer: a retenção é na fonte. Nascer "pendente" criaria uma
     conta a pagar que ninguém vai pagar.
   - `origin_type` que identifique a origem, para não ser confundido com
     despesa lançada à mão
3. O saldo bancário final não muda: entra 250, sai 8,75, líquido 241,25 — igual
   a hoje. **O que muda é a visibilidade**, que é o ponto.

### O que isso toca — e o desenho mudou ao preparar

**Seis caminhos** inserem em `receivables` (LaunchReceivableDialog,
ClosingDetailDialog, Acompanhamento ×3, ContasReceber). Remendar os seis no
front garante que o sétimo nasça sem a taxa. **A regra é de domínio: mora no
banco**, como trigger — e assim atravessa para a stack nova como migração, que é
o único artefato que migra intacto.

Código preparado, **não aplicado**, em
`specs/002-seguranca-anamnese-auditoria/preparado/d13-taxa-como-despesa.sql`.

**Três coisas têm de ir junto, ou o número fica errado:**

1. **DRE passa a somar `gross_value`** em vez de `net_value`, senão a taxa
   desconta duas vezes.
2. **Inconsistência que já existe, achada ao preparar:** o Fluxo de Caixa soma
   `r.value`, e `value` não é preenchido igual em todo lugar —
   `ContasReceber.tsx:225` grava o **líquido**, os outros caminhos gravam o
   **bruto**. O caixa já mistura os dois hoje, antes da D-13.
3. **Backfill do histórico — decisão pendente.** O trigger só pega inserção
   nova. Mudar o DRE para bruto sem backfill infla a receita histórica.
   Como hoje só há dado de teste e o primeiro cliente entra em 01/09, a saída
   mais limpa é provavelmente **limpar e começar do zero**.

**Contas a Receber**, **Fluxo de Caixa** e **DRE/DFC** — três telas, todas de
dinheiro. Maior item da faixa A e o de maior risco do lote.

### Aceite obrigatório

Não fecha sem conferir, com uma venda real no crédito, que:
- o extrato do banco bate com o líquido;
- o DRE mostra a receita bruta e a linha de taxa separadamente;
- a soma não desconta duas vezes.

---

## D-14 — A limpeza do histórico tem janela própria: 27–30/08 (23/08/2026)

Decisão do Arthur, tomada ao definir o escopo do dia 23/08. Fecha o item que a
D-13 tinha deixado em aberto ("backfill — decisão pendente").

**O caminho é limpar, não fazer backfill.** Sem histórico, o backfill deixa de
existir como problema — não há passado em `net_value` para reconciliar com o
futuro em bruto.

**Mas não hoje, e a razão é de calendário:**

> "O Erick roda a bateria dele em 24–26/08 e vai gerar mais dado de teste.
> Limpar agora é trabalho que se refaz. O momento é 27–30/08, no congelamento:
> depois das duas baterias, antes do cliente." — Arthur, 23/08

**Duas condições inegociáveis da limpeza:**

1. **Export confirmado antes.** Não há recuperação no tempo neste tier.
2. **Limpar só o transacional.** Consultas, orçamentos, recebíveis, despesas,
   tarefas, leads. **Configuração fica** — plano de contas, meios de pagamento,
   taxas, tipos de consulta, serviços, equipe. *"Se apagar configuração, o
   fundador recebe um sistema em branco."*

**Consequência para a D-13:** ela sai da janela de 23/08 e passa a 27–30/08,
junto da limpeza, como uma coisa só. A ordem é: export → limpar transacional →
aplicar o trigger → DRE passa a somar bruto → uniformizar `receivables.value`.

**Por que não antecipar mesmo assim:** hoje a taxa é invisível no DRE, mas o
resultado fecha certo. Subir metade da D-13 antes da bateria do Erick faria ele
testar em cima de número financeiro com dupla contagem — e é exatamente a tela
que ele, olhando gestão, vai abrir.

---

## D-3 CONFIRMADA PELO VINÍCIUS — entra na janela de 23/08

A D-3 (entrada abate a consulta; total a receber soma consulta + prescrição)
estava fixada como "fix mínimo nesta janela", mas sem confirmação de quem usa.
Veio em 21/08, sem rodeios:

> "Por mim, entra. Porque **o pagamento da consulta não tá entrando em lugar
> nenhum**. E isso vai fuder com tudo." — Vinícius, 21/08

**O que isso muda:** V-18 e V-20 sobem para o topo da faixa A, ao lado dos
relatórios. E confirma a leitura da régua fina da §2.5 — é **atribuição
gravada**, não cálculo de tela: o pagamento da consulta não está sendo
registrado como receita da consulta em lugar nenhum do banco. Erro que migra
para a stack nova em outubro.

O escopo continua sendo o da D-3, e **não se reabre**: o redesenho em dois
blocos com pagamento independente por bloco fica para depois de 01/09.

---

## D-15 — Corrigir TUDO, não só o que trava (24/08/2026)

Decisão do Arthur. **Reverte parte da D-7**, que mandava não gastar esforço no
que não atravessa para a stack nova.

> "Vamos mudar a política, faremos todas as correções, não somente aquelas que
> travam o uso."

**O que muda:** os 8 itens que estavam fora de escopo — V-02, V-05, V-06, V-07,
V-08, V-09, V-30, V-31 — voltam para a fila.

**O que NÃO muda, e é o ponto:** a D-7 continua certa sobre *por que* corrigir.
O que ela decidia era **prioridade**, não **valor**. Um item de faixa C corrigido
segue sendo código descartado em outubro — a diferença é que agora aceitamos
pagar por isso, e o plano diz o preço em voz alta.

**Custo registrado** (`specs/004-.../plan.md`, seção Constitution Check): cada
hora aqui é uma hora que não vai para a stack nova, que não é descartada. E
mexer em tela estável a 8 dias do lançamento introduz regressão onde não havia
bug.

**Mitigação:** faixa C entra **por último e em commit isolado**, para que uma
regressão nela não contamine o lote financeiro. E cada item vira também
requisito escrito da stack nova — o esforço rende duas vezes.

**Uma exceção à própria D-15, recomendada e não imposta:** V-30 (agenda em
calendário) e V-31 (responsável por tipo de atividade) **não são bugs, são
funcionalidades novas**. V-31 ainda interage com a D-2, que acabou de fixar
responsável único por atendimento. Recomendo que não entrem antes de 01/09 —
não por serem faixa C, mas por serem **escopo novo a 8 dias do lançamento**,
com a bateria do Erick ainda por triar.

---

## Convenção de numeração (para acomodar a leva do Erick)

- **V-01 a V-33** — esta leva, Vinícius, 18–19/08. Numeração fixa: não
  renumerar em revisões futuras, só acrescentar.
- **E-01 em diante** — reservado para a bateria do Erick, 24–26/08. Mesmo
  formato, mesmas seções, anexar ao final de cada bloco de severidade.
- Meta combinada com o Arthur: ~40 itens ao todo. Esta leva fecha em 33;
  sobra espaço para ~7 itens do Erick sem precisar reestruturar o documento.
- Dois apontamentos da bateria original geraram mais de um item porque
  descreviam mais de um problema (V-04/V-04B; V-28A/V-28B) — o número da
  linha "Relato original" indica de qual apontamento do Notion cada um veio.

---

## BUGS — SEVERIDADE TRAVA (Atrapalha muito: Sim)

### V-01 — Scroll da lista de especialidades trava no cadastro do médico
Tipo: bug
Severidade: trava
Tela: cadastro inicial de médico (onboarding, pré-`/configuracoes`)
Relato original: "Na tela de cadastro inicial, por conta do tamanho, não
consigo ver toda a lista de especialidades, pois o scroll da página ao fundo
trava e não dá pra ter acesso a lista completa, que fica cortada."
Comportamento esperado: ver a lista completa de especialidades, navegável por
scroll, sem corte — segundo o próprio relato do Vinícius (regra completa e
sem ambiguidade, vale como especificação).
Comportamento observado: o scroll da página trava com a lista de
especialidades aberta; parte das opções fica inacessível.
Reprodução: 1. Iniciar cadastro de médico (Dr./Dra. + nome). 2. Avançar até o
campo de especialidade. 3. Abrir a lista e tentar rolar até o fim.
Aposta de causa: não investigado a fundo — suspeita de `overflow` mal
configurado no container do dropdown/lista dentro do wizard de onboarding
(conflito entre scroll do dropdown e scroll da página).
Canal de correção: ponte (CSS/componente de front)
Depende de: nada

### V-04 — Erro ao salvar secretária com acesso ("Edge function returned a non-2xx status code")
Tipo: bug
Severidade: trava
Status: **possivelmente resolvido — exige reteste** (não afirmar corrigido)
Tela: Configurações → Equipe (`ConfigTeamDialog`)
Relato original: "Bug ao salvar uma secretária - 'Edge function returned a
non-2xx status code'. Não me deixou salvar a secretária criando acesso.
Quando tirei a opção de criar um acesso, funcionou. E para minha surpresa,
todas as tentativas anteriores estavam lá, salvas na equipe. Apesar do bug,
estava sendo salvo. Mas todas sem o acesso."
Comportamento esperado: "Que o acesso da secretária fosse criado, além dela
ficar salva na equipe." (Vinícius, regra completa.)
Comportamento observado (18/08, código antigo): a function `invite-team-user`
recusava a chamada quando o front tentava criar acesso, retornando status
não-2xx; a secretária ficava salva em `team_members`, mas sem login.
**O que mudou desde então:** a function foi **reescrita e deployada em
produção em 20/08/2026** (`specs/002-seguranca-anamnese-auditoria/tasks.md`
T017, commit `dabf1ef`). O caminho antigo — que aceitava e transportava
`password` vindo do cliente — **não existe mais**: hoje a function só gera um
link de convite (`generateLink`) e quem define a senha é o próprio convidado
em `/nova-senha`. Como o caminho que causou a falha original foi substituído
por inteiro, **a causa raiz da primeira falha não está explicada pelo código
antigo** e não há evidência de que o novo caminho já foi exercitado de ponta
a ponta ("falta o aceite manual", nas palavras do próprio T017).
Reprodução do reteste (a fazer antes de fechar este item):
1. Logar como admin/médico numa clínica de teste.
2. Configurações → Equipe → "+ Novo".
3. Cadastrar uma secretária, definir nível de acesso, marcar "criar acesso".
4. Salvar — confirmar que **não** aparece mais o erro non-2xx e que a
   resposta traz um link de convite (não pede/expõe senha).
5. Abrir o link em janela anônima — deve cair em `/nova-senha`, não em
   `/login`.
6. Definir senha e logar como a secretária.
7. Voltar a Configurações → Equipe e conferir **uma única linha** para essa
   secretária, com o nível de acesso correto (ver V-04B).
8. Conferir em `More → Cloud → Edge functions` que o *Last updated* de
   `invite-team-user` é o do deploy de 20/08 — garante que o reteste não caiu
   na versão antiga.
Aposta de causa: código antigo indisponível para diagnóstico; a causa
original não foi identificada, só contornada pela reescrita.
Canal de correção: já executado via ponte + agente Lovable (redeploy da
function, ver `docs/ponte/ponte-inversa.md`, custo 0,4 do crédito diário de
build) — falta só o reteste manual acima, que não consome crédito.
Depende de: nada

### V-04B — Linha órfã em `team_members` quando a criação de acesso falha
Tipo: bug
Severidade: trava
Tela: Configurações → Equipe (`ConfigTeamDialog`)
Relato original: mesmo apontamento de V-04 — "todas as tentativas anteriores
estavam lá, salvas na equipe... mas todas sem o acesso."
Comportamento esperado: se a criação do acesso falhar, a tentativa não deve
deixar uma linha duplicada e órfã em `team_members` a cada nova tentativa —
ou a operação é revertida por inteiro, ou fica claramente sinalizada como
"sem acesso" sem duplicar.
Comportamento observado: cada tentativa de salvar (mesmo com a function
falhando) inseriu uma linha nova em `team_members`, gerando duplicatas da
mesma secretária.
Reprodução: 1. (histórico, já ocorreu com o código antigo) Tentar salvar uma
secretária com "criar acesso" marcado, repetidas vezes, com a function
falhando. 2. Verificar em Configurações → Equipe quantas linhas existem para
o mesmo nome/e-mail.
Aposta de causa: `ConfigTeamDialog` insere em `team_members` antes de, ou
independentemente de, confirmar sucesso da chamada a `invite-team-user`, sem
transação nem rollback em caso de falha.
Canal de correção: ponte (reordenar o fluxo — só confirmar/gravar
`team_members` após sucesso do convite, ou implementar rollback) **+** SQL
editor (apagar as linhas duplicadas/órfãs já existentes nas clínicas de
teste, inclusive a do Vinícius, antes do lançamento).
Depende de: nada (independente do reteste de V-04, mesma área de código)

### V-10 — Agenda permite marcar dois pacientes no mesmo médico, mesmo dia e horário
Tipo: bug
Severidade: trava
Tela: `/acompanhamento` (Consultas)
Relato original: "Marquei consultas para o mesmo médico, no mesmo dia e
horário, para pacientes diferentes... Consegui realizar essa marcação."
Comportamento esperado: "Que houvesse um bloqueio de agenda, que o sistema me
informasse que esse horário já não está disponível." (regra completa.)
Comportamento observado: o sistema aceita duas consultas conflitantes sem
aviso.
Reprodução: 1. Marcar consulta para o Médico A, Paciente 1, num horário X.
2. Marcar outra consulta para o Médico A, Paciente 2, no mesmo dia e horário X.
3. Ambas são salvas sem erro.
Aposta de causa: não investigado; nem front nem banco parecem ter checagem de
conflito (nenhuma menção a essa validação em `INVENTARIO.md §3.4`).
Canal de correção: ponte (validação no salvamento) + SQL editor (constraint/
trigger de unicidade médico+horário, como segunda camada — mesma filosofia
de "segurança mora no banco" já usada no resto do produto).
Depende de: nada

### V-12 — Consulta avulsa não gera as tarefas automáticas (anamnese, confirmação)
Tipo: bug
Severidade: trava
Tela: `/acompanhamento` (lançamento de consulta avulsa) → `/tarefas`
Relato original: "Lancei uma consulta avulsa, pelo painel de consultas, para
um paciente que não vinha do CRM... Não foi gerada nenhuma tarefa seguindo as
configurações do sistema, como envio da anamnese e envio da confirmação de
consulta."
Comportamento esperado: "Que as tarefas fossem criadas automaticamente, como
no caso dos pacientes que vêm do CRM, com data de realização e responsável
definido." (regra completa.)
Comportamento observado: nenhuma tarefa automática é criada para consultas
lançadas fora do wizard Lead→Consulta.
Reprodução: 1. Ir em Consultas → "+ Nova Consulta" (fluxo avulso, sem passar
pelo Atendimentos/funil). 2. Selecionar um paciente já cadastrado. 3. Salvar
a consulta. 4. Ir em Tarefas e conferir que não aparece `confirmar_agendamento`
nem `envio_anamnese` para essa consulta.
Aposta de causa: `createAppointmentTasks` (`lib/tasksAutomation.ts`) é
disparada pelo `LeadToAppointmentWizard` (`INVENTARIO.md §3.4`); o caminho de
"Nova Consulta" avulsa aparentemente não chama essa função.
Canal de correção: ponte
Depende de: nada — mas ver ATR-1 (tema "atribuição de tarefa" na seção de
decisões) sobre o que fazer quando a consulta avulsa também não tem
responsável definido (V-11).

### V-13 — Dashboard: contagem de "novos pacientes" e "novas consultas" incorreta
Tipo: bug
Severidade: trava
Tela: `/` (Dashboard)
Relato original: "As consultas marcadas estão corretas, mas a quantidade de
novos pacientes está errada. Também está errada a quantidade de novas
consultas."
Comportamento esperado: "Que a quantidade de novos pacientes se refira apenas
às consultas de 1ª vez, ou seja, aquelas que foram geradas a partir do CRM ou
que possuam categoria de 1ª consulta. No quadro de consultas realizadas, o
mesmo filtro deve ser aplicado para definir a quantidade de novas consultas
realizadas." (regra completa — bate com a coluna "1ª VEZ?" que já existe no
relatório de Vendas, `INVENTARIO-UI.md`.)
Comportamento observado: os cards de "novos pacientes" e "novas consultas" do
Dashboard contam algo diferente do que o relatório de Vendas usa para a mesma
noção.
Reprodução: 1. Cadastrar/mover pacientes pelo CRM e também lançar consultas
avulsas. 2. Comparar o card do Dashboard com a contagem manual de consultas
marcadas como "1ª vez"/vindas do CRM no período.
Aposta de causa: cálculo do Dashboard conta todos os registros do período,
sem aplicar o mesmo filtro de "1ª vez"/origem CRM que o relatório de Vendas já usa.
Canal de correção: ponte
Depende de: nada, mas ver DASH-1 (tema dashboard) sobre alinhar o cálculo do
ticket médio à mesma metodologia.

### V-14 — Dashboard: adiantamento de consulta contabilizado como venda
Tipo: bug
Severidade: trava
Tela: `/` (Dashboard)
Relato original: "Lancei uma venda de uma consulta com um adiantamento... No
dashboard, o valor do adiantamento foi atribuído como venda."
Comportamento esperado: "O correto é que esse valor seja atribuído às
consultas, não às vendas gerais." (regra completa — coerente com a separação
Consulta × Prescrição/Venda já documentada em `INVENTARIO.md`, Anexo.)
Comportamento observado: o valor do adiantamento soma no total de "vendas",
não no total de "consultas".
Reprodução: 1. Marcar consulta como compareceu. 2. Registrar um adiantamento
na consulta (sem orçamento de prescrição ainda). 3. Conferir no Dashboard os
cards TOTAL CONSULTAS e TOTAL VENDAS.
Aposta de causa: agregação do Dashboard (`useFinancialBreakdown` ou
equivalente) classifica o depósito/adiantamento pela origem errada.
Canal de correção: ponte
Depende de: nada

### V-15 — Tarefa de recaptação atribuída ao médico, não ao responsável pela venda
Tipo: bug
Severidade: trava
Tela: `/tarefas` (gerada a partir de `/acompanhamento`, cancelamento com
recaptação)
Relato original: "Cancelei uma consulta que estava agendada e coloquei que
era para ser feita a recaptação... Foi gerada uma tarefa de recaptação para o
médico responsável pelo atendimento."
Comportamento esperado: "Deveria ser criada uma tarefa atribuída para o
responsável pela venda, não ao médico." (regra completa para o caso em que
existe um responsável definido.)
Comportamento observado: a tarefa nasce atribuída ao `doctor`/profissional do
atendimento.
Reprodução: 1. Cancelar uma consulta agendada com responsável definido.
2. Marcar para entrar em recaptação. 3. Conferir em Tarefas o campo
RESPONSÁVEL da tarefa gerada.
Aposta de causa: geração automática de tarefa (`AppointmentStatusDialogs.tsx`
/ automação de cancelamento) usa `doctor_id`/profissional do appointment em
vez do `responsible_id`.
Canal de correção: ponte
Depende de: ATR-1 (tema "atribuição de tarefa") — o que fazer quando não há
responsável definido (caso das consultas avulsas, V-11).

### V-16 — Tarefa de remarcação (não comparecida) atribuída ao médico, não ao responsável pela venda
Tipo: bug
Severidade: trava
Tela: `/tarefas` (gerada a partir de `/acompanhamento`, "não comparecida")
Relato original: "Coloquei uma consulta da agenda como não comparecida...
Foi gerada uma tarefa de remarcação para o médico responsável pelo
atendimento."
Comportamento esperado: "Deveria ser criada uma tarefa atribuída para o
responsável pela venda, não ao médico." (mesma regra de V-15.)
Comportamento observado: idem V-15, mas no caminho de "não comparecida".
Reprodução: 1. Marcar uma consulta agendada como "não comparecida" (motivo
≥3 caracteres, per `INVENTARIO.md §3.4`). 2. Conferir o RESPONSÁVEL da tarefa
de remarcação gerada.
Aposta de causa: mesmo ponto de código de V-15 (provável função única de
geração de tarefas por status de consulta) — corrigir os dois juntos.
Canal de correção: ponte
Depende de: ATR-1; mesma correção de V-15 (aplicar no mesmo commit).

### V-17 — Tarefas: filtros fazem os dados sumirem
Tipo: bug — **precisa-detalhe**
Severidade: trava
Tela: `/tarefas`
Relato original: "Utilizei os filtros para navegar e verificar somente o que
tinha de tarefas para o dia... Todos os dados somem."
Comportamento esperado: "Que os filtros funcionassem para melhor navegação
pelos clientes." (Vinícius não descreve qual filtro, nem os valores usados —
insuficiente para reproduzir sem adivinhar.)
Comportamento observado: aplicar filtro(s) na tela de Tarefas zera a lista.
Reprodução: **não reproduzido** — falta saber qual dos 4 filtros (tipo,
status, responsável, período) foi usado e com qual valor.
Pergunta para devolver: "Qual filtro (ou combinação) você usou quando os
dados sumiram — tipo, status, responsável ou período? Que valor selecionou
em cada um? O status padrão da tela já é 'Pendente' — você trocou para outro
status, ou mudou o período para 'Hoje'?"
Aposta de causa: não investigado — mesma classe de problema do filtro de
período que já esconde listas de cadastro (D2 em `INVENTARIO-UI.md`), mas
essa tela não está na lista de "já sabemos" do plano da bateria, então é caso
novo.
Canal de correção: ponte (após a resposta)
Depende de: resposta à pergunta acima

### V-18 — Financeiro: valor a receber só traz a prescrição, não a consulta
Tipo: bug
Severidade: trava
Tela: financeiro pós-consulta (tela de recebimento aberta a partir de
`/acompanhamento`)
Relato original: "Dei uma consulta como comparecida... Após isso, criei um
orçamento de outros itens e aprovei. Após isso, fui para a tela do
financeiro... O valor a pagar pelo paciente só inclui os dados da
prescrição."
Comportamento esperado (mínimo, literal): "Que aparecesse o total a receber
da consulta MAIS a prescrição." O relato vai além do mínimo e descreve um
desenho em dois blocos com pagamentos independentes — ver FIN-1 na seção de
decisões, porque essa parte não é suficiente para implementar sem escolher
escopo.
Comportamento observado: o valor da consulta desaparece da tela quando existe
também uma prescrição aprovada.
Reprodução: 1. Marcar consulta como compareceu (gera cobrança da consulta).
2. Criar orçamento de outros itens (prescrição) e aprovar. 3. Abrir a tela do
financeiro para esse paciente/atendimento.
Aposta de causa: a tela financeira parece somar só receivables de origem
`fechamento` (prescrição), ignorando o receivable de origem `consulta`
gerado no comparecimento/depósito (`INVENTARIO.md §3.4`).
Canal de correção: ponte
Depende de: FIN-1 (decisão de escopo)

### V-20 — Valor já pago aparece como desconto na prescrição, deveria descontar da consulta
Tipo: bug
Severidade: trava
Tela: financeiro pós-consulta
Relato original: "Dei uma consulta como comparecida de um paciente que havia
pago uma entrada na consulta. Após isso, criei um orçamento de outros itens e
aprovei todos... O valor já pago aparecia como um desconto na prescrição."
Comportamento esperado: "Que o valor fosse descontado da consulta, não da
prescrição. São coisas distintas." (regra completa.)
Comportamento observado: o desconto do valor pago é aplicado no bloco
errado.
Reprodução: 1. Marcar consulta como compareceu com entrada/depósito pago.
2. Criar orçamento de prescrição e aprovar tudo. 3. Conferir em qual bloco
(consulta ou prescrição) o valor pago aparece descontado.
Aposta de causa: mesma área de código de V-18 — a lógica que separa
consulta de prescrição parece não estar propagando a origem do pagamento
corretamente.
Canal de correção: ponte
Depende de: V-18 (mesma correção provavelmente resolve os dois; aplicar
juntos)

### V-21 — Dashboard: bloco de indicadores financeiros zerado/errado após vendas
Tipo: bug
Severidade: trava
Tela: `/` (Dashboard)
Relato original: "total de R$ consultas estava zerado; ticket calculado
estava errado, pois coloca por itens vendidos, não por paciente; Taxa de
conversão em 100%, quando na verdade teve um item que coloquei como não
aprovado; Quadro específico do ticket médio zerado; Top macro-categorias e
top médicos, zerados; fluxo de caixa com valor recebido mas sem gráfico
aparente."
Comportamento esperado: "Que as consultas recebidas constassem com seu valor;
que o ticket e o ticket médio levassem em consideração a quantidade de
orçamentos, não a quantidade de itens; que a taxa de conversão levasse em
consideração o que foi vendido em relação ao total orçado, como consta
corretamente no painel de consultas; que os top médicos e macro-categorias
trouxessem infos de venda; que o fluxo de caixa tivesse um gráfico." (regra
completa para cada sub-item, exceto a definição exata de "quantidade de
orçamentos" — ver DASH-1.)
Comportamento observado — seis facetas no mesmo apontamento:
1. Card TOTAL CONSULTAS zerado.
2. Ticket calculado por item vendido, não por paciente/orçamento.
3. TAXA DE CONVERSÃO mostrando 100% com item reprovado no meio.
4. Quadro "Ticket Médio" (MAIS ALTO/MAIS BAIXO) zerado.
5. "Top Macro-Categorias" e "Top Profissionais de Saúde" zerados.
6. Gráfico do Fluxo de Caixa no Dashboard não aparece, apesar de haver saldo.
Reprodução: 1. Marcar consultas como compareceu. 2. Criar orçamentos,
aprovar parte dos itens e reprovar outros. 3. Abrir o Dashboard e conferir
cada um dos 6 pontos acima.
Aposta de causa: os 6 pontos parecem compartilhar a mesma fonte de
agregação (`useFinancialBreakdown`/base "fechamentos do período" descrita em
`INVENTARIO.md §3.4`) — plausível que o fechamento não esteja sendo
capturado como deveria nesse cenário. Não investigado item a item.
Canal de correção: ponte
Depende de: V-13, V-14 (mesma camada de agregação do Dashboard) e DASH-1
(definição do cálculo de ticket médio)

### V-22 — Contas a Receber: valores não aparecem conforme a data automática por meio de pagamento
Tipo: bug
Severidade: trava
Tela: `/contas-receber`
Relato original: "No quadro de contas a receber apenas consta o valor
recebido da antecipação da consulta, nada mais dos outros valores. Isso
porque por padrão ele coloca o primeiro vencimento para daqui a 30 dias, e os
dados começam a entrar somente lá."
Comportamento esperado: "Se pagamento for dinheiro ou pix, o valor cai no
mesmo dia da realização da venda, descontadas as taxas; Se débito ou crédito
com antecipação, cai no dia seguinte descontadas as taxas; Se crédito sem
antecipação, sempre colocar 30 dias pra frente, com o devido parcelamento.
Essa informação de primeiro vencimento só deve ser informada se for boleto ou
cheque." (regra completa e específica por método — vale como especificação.)
Comportamento observado: o sistema usa um "primeiro vencimento" fixo de 30
dias como padrão para todos os métodos, em vez de aplicar a data automática
por meio de pagamento.
Reprodução: 1. Vender um item via pix (ou dinheiro). 2. Vender outro via
débito. 3. Vender outro via crédito parcelado sem antecipação. 4. Conferir em
Contas a Receber a data de vencimento gerada para cada um.
Aposta de causa: a geração de `receivables` no fechamento
(`ClosingDetailDialog`/`computeFeeForMethod`, `INVENTARIO.md §3.4`) já
calcula taxa por método, mas parece não aplicar a regra de prazo automático
por método — usando sempre o campo manual "primeiro vencimento".
Canal de correção: ponte
Depende de: nada — a regra já está completa e sem ambiguidade (decisão #1)

### V-23 — Fluxo de Caixa: mesmo problema de data automática por meio de pagamento
Tipo: bug
Severidade: trava
Tela: `/fluxo-caixa`
Relato original: "No quadro de fluxo de caixa constam os valores somente de
acordo com a data que foi definida como primeiro vencimento na venda."
Comportamento esperado: idêntico a V-22 — mesma regra por método de
pagamento, citada literalmente pelo Vinícius nos dois apontamentos.
Comportamento observado: idêntico a V-22, refletido no Fluxo de Caixa.
Reprodução: mesma de V-22, conferindo a tabela diária do Fluxo de Caixa em
vez de Contas a Receber.
Aposta de causa: mesma causa de V-22 — Fluxo de Caixa lê a mesma data
gerada incorretamente.
Canal de correção: ponte (mesmo commit de V-22 resolve os dois)
Depende de: V-22 — corrigir junto, não em separado

### V-24 — Contas a Pagar: plano de contas não carrega ao lançar despesa avulsa
Tipo: bug
Severidade: trava
Tela: `/contas-pagar`
Relato original: "Lancei uma despesa avulsa... O plano de contas não carrega
para selecionar, o que impediu o lançamento."
Comportamento esperado: "Que o plano de contas carregasse, conforme o que
ficou definido nas configurações, para que eu pudesse selecionar corretamente
e fazer um lançamento." (regra completa — e é literalmente "passo da rotina
que o sistema não deixa fazer", bug por definição do próprio plano da
bateria.)
Comportamento observado: o combobox de plano de contas não popula opções,
impedindo o lançamento.
Reprodução: 1. Configurar plano de contas em Configurações → Financeiro.
2. Ir em Contas a Pagar → "Novo Lançamento" (despesa avulsa). 3. Abrir o
campo "Plano de Contas".
Aposta de causa: não investigado — suspeita de RLS bloqueando o SELECT na
tabela de plano de contas para esse contexto, ou query mal formada no
diálogo de lançamento avulso.
Canal de correção: indefinido até investigar — provável ponte (front); se a
causa for RLS/dado ausente, SQL editor.
Depende de: nada

### V-25 — Relatório de Vendas: linhas quebradas e faltam colunas de médico/responsável
Tipo: bug
Severidade: trava
Tela: `/relatorios/vendas`
Relato original: "Consegui baixar corretamente o xlsx, os valores batiam
certinho, mas as vendas vieram quebradas em diversas linhas, seguindo uma
lógica que não compreendi."
Comportamento esperado: "Precisamos apenas que venha como o paciente aprovou
no orçamento - se ele aprovou 3 aplicações de vitamina, por exemplo, isso vai
aparecer em uma única linha no relatório... com quantidade = 3 e os
respectivos valores, meio de pagamento e taxas. Falta aqui também a
informação do médico prescritor e o responsável pela venda." (regra
completa: agrupar por item aprovado dentro do mesmo orçamento, e acrescentar
duas colunas.)
Comportamento observado: cada aprovação/parcela vira uma linha separada, sem
agrupar por item do orçamento; não há coluna de médico prescritor nem de
responsável pela venda.
Reprodução: 1. Aprovar um orçamento com 3 unidades do mesmo item.
2. Gerar/baixar o relatório de Vendas. 3. Conferir quantas linhas o item
gerou e se há coluna de médico/responsável.
Aposta de causa: relatório agrupa por linha de recebível/parcela em vez de
por item aprovado do orçamento; colunas de profissional/responsável nunca
foram adicionadas à consulta que monta o relatório (`INVENTARIO-UI.md` já
lista as colunas atuais de `/vendas`, sem essas duas).
Canal de correção: ponte
Depende de: ATR-1 (mesma definição de "responsável" usada em V-15/V-16)

### V-26 — Relatório de Contas a Pagar vem totalmente zerado
Tipo: bug
Severidade: trava
Tela: `/relatorios/contas-pagar`
Relato original: "Puxei o relatório de contas a pagar... Veio totalmente
zerado."
Comportamento esperado: "Que viessem os lançamentos de despesas que fiz
(nesse momento as taxas e a despesa fixa)." (regra completa.)
Comportamento observado: relatório vazio apesar de haver lançamentos.
Reprodução: 1. Lançar uma despesa fixa e uma variável em Contas a Pagar.
2. Gerar o relatório de Contas a Pagar para o período correspondente.
Aposta de causa: não investigado a fundo — mesma classe de bug dos outros
relatórios zerados (V-27); suspeita de filtro de período ou junção que não
encontra os lançamentos recém-criados.
Canal de correção: ponte
Depende de: nada, mas mesma investigação de V-27 pode revelar causa comum

### V-27 — Relatório de DRE/DFC vem totalmente zerado
Tipo: bug
Severidade: trava
Tela: `/relatorios/dfc-dre`
Relato original: "Puxei o relatório de DRE/DFC... Veio totalmente zerado."
Comportamento esperado: "Que viessem os lançamentos ajustados, tanto de
entrada quanto de saídas." (regra completa.)
Comportamento observado: relatório vazio apesar de haver entradas e saídas
lançadas na semana.
Reprodução: 1. Ter receitas (consultas/vendas) e despesas lançadas no
período. 2. Gerar o relatório DRE/DFC.
Aposta de causa: não investigado a fundo — mesma suspeita de V-26 (filtro de
período/junção); avaliar junto, pode ser causa raiz única para os dois.
Canal de correção: ponte
Depende de: nada, mas investigar em conjunto com V-26

### V-28A — Relatório de Contas a Receber: datas personalizadas não funcionam
Tipo: bug
Severidade: trava
Tela: `/relatorios/contas-receber`
Relato original: "Também não foi possível utilizar as datas personalizadas."
Comportamento esperado: poder escolher um intervalo de datas personalizado e
o relatório respeitar esse intervalo — parte clara e objetiva do relato.
Comportamento observado: o seletor de datas personalizadas não filtra o
relatório corretamente (ou não é aceito).
Reprodução: 1. Abrir o relatório de Contas a Receber. 2. Selecionar "período
personalizado" e escolher duas datas. 3. Gerar o relatório.
Aposta de causa: não investigado — mesma família de filtros problemáticos de
V-17/V-28B.
Canal de correção: ponte
Depende de: nada

### V-28B — Relatório de Contas a Receber: filtros fazem os dados sumirem
Tipo: bug — **precisa-detalhe**
Severidade: trava
Tela: `/relatorios/contas-receber`
Relato original: "Quando utilizei os filtros para baixar o relatório, os
dados sumiram."
Comportamento esperado: "Que os filtros permitissem uma visualização mais
simples do relatório." (não especifica qual filtro nem qual valor —
insuficiente para reproduzir.)
Comportamento observado: aplicar filtro(s) zera o relatório.
Reprodução: **não reproduzido** — o relatório tem múltiplos filtros (período,
por vencimento, status, bancos, +2 outros, conforme `INVENTARIO-UI.md`).
Pergunta para devolver: "Qual filtro específico (status, banco, 'por
vencimento' etc.) você aplicou quando os dados sumiram, e qual valor
selecionou em cada um?"
Aposta de causa: não investigado; mesma classe de V-17.
Canal de correção: ponte (após a resposta)
Depende de: resposta à pergunta acima; mesma investigação de V-17 pode
revelar causa comum (padrão de filtro quebrado em mais de uma tela)

### V-29 — Relatório de Produtividade por Profissional: valor orçado errado
Tipo: bug — **precisa-detalhe**
Severidade: trava
Tela: `/relatorios/produtividade`
Relato original: "O relatório trouxe de forma simplificada o quanto foi
vendido por cada médico prescritor, mas o valor orçado está errado."
Comportamento esperado: "Que viesse a informação certa sobre os orçamentos,
para que fosse possível verificar o % de conversão de cada profissional."
(não diz qual é o valor certo nem o errado observado — insuficiente para
reproduzir sem adivinhar o que "errado" significa aqui.)
Comportamento observado: valor orçado divergente do esperado; não há registro
de qual era o valor certo nem o mostrado.
Reprodução: **não reproduzido** — falta saber os números: quanto o
relatório mostrou de "valor orçado" para qual profissional, e quanto deveria
ser (conferido manualmente pelos orçamentos daquele profissional no
período).
Pergunta para devolver: "Para qual profissional o valor orçado apareceu
errado, qual número o relatório mostrou, e qual é o valor correto que você
calculou na mão a partir dos orçamentos dele no período?"
Aposta de causa: não investigado — pode ser a mesma classe de erro de V-21
(2: "ticket por item, não por orçamento/paciente"), mas sem os números não dá
para confirmar.
Canal de correção: ponte (após a resposta)
Depende de: resposta à pergunta acima

---

## BUGS — SEVERIDADE ATRAPALHA (Atrapalha muito: Não, mas afeta dado/leitura)

### V-19 — Financeiro: fechamento parcial exibido como "fechamento total"
Tipo: bug
Severidade: atrapalha
Tela: financeiro pós-consulta
Relato original: "Dei uma consulta como comparecida. Após isso, criei um
orçamento, dei um desconto e aprovei parcialmente os itens... No topo da
parte de recebimento vinha a informação de que o fechamento foi total."
Comportamento esperado: "Que aparecesse como fechamento parcial, tendo em
vista que não foram aprovados todos os itens da lista. Se tudo foi aprovado,
é fechamento completo. Se qualquer coisa foi retirada, é fechamento
parcial." (regra completa.)
Comportamento observado: rótulo mostra "Fechou Completo" mesmo com itens não
aprovados.
Reprodução: 1. Marcar consulta como compareceu. 2. Criar orçamento com vários
itens. 3. Aprovar só parte dos itens (reprovar/retirar ao menos um). 4.
Conferir o rótulo de fechamento na tela financeira/`/acompanhamento`
(coluna FECHAMENTO).
Aposta de causa: cálculo do rótulo de fechamento não checa
`approval_status` de todos os itens do orçamento, só se algum foi aprovado.
Canal de correção: ponte
Depende de: nada

---

## BUGS — SEVERIDADE COSMÉTICO (Atrapalha muito: Não, sem impacto funcional)

### V-02 — Sem tela de boas-vindas após o cadastro inicial
Tipo: bug
Severidade: cosmético
Tela: pós-signup → `/configuracoes`
Relato original: "Finalizei o cadastro e fiz o login... Não aparece uma
mensagem de boas vindas, vai direto pra a página de configurações."
Comportamento esperado: "Ideal é ter uma página prévia de boas vindas, do
tipo 'Dr. (ou Dra.) seja muito bem vindo(a)... Para iniciar, precisamos
configurar a sua clínica. Vamos lá?' Com um botão para início." (regra
completa, com texto sugerido.)
Comportamento observado: login pós-cadastro cai direto em `/configuracoes`,
sem tela intermediária.
Reprodução: 1. Concluir o cadastro de clínica/médico. 2. Fazer login pela
primeira vez. 3. Observar a primeira tela após o login.
Aposta de causa: roteamento de onboarding não tem etapa de "welcome" antes de
redirecionar para configurações.
Canal de correção: ponte
Depende de: nada

### V-06 — Anamnese: sem mensagem de conclusão ao terminar o cadastro inicial
Tipo: bug
Severidade: cosmético
Tela: `/anamnese` (fluxo de onboarding — primeiro formulário)
Relato original: "Finalizei o cadastro de anamnese... Deu como salvo,
apenas."
Comportamento esperado: "Esperava uma mensagem de finalização de
configurações, indicando que agora o sistema está pronto para uso." (regra
completa.)
Comportamento observado: só um "salvo" genérico, sem indicar que o
onboarding terminou.
Reprodução: 1. Completar o passo a passo de configuração inicial até o
cadastro de anamnese (última etapa do onboarding). 2. Salvar.
Aposta de causa: fluxo de onboarding não tem uma etapa final de "configuração
concluída" após o último passo (anamnese).
Canal de correção: ponte
Depende de: V-02 (mesma área — vale desenhar as duas telas de mensagem
juntas: boas-vindas no início, conclusão no fim do onboarding)

---

## BACKLOG (registrado; não entra nesta janela de correção)

### V-03 — Login sem opção de visualizar a senha digitada
Tipo: backlog
Tela: `/login`
Relato original: "No login, não consigo visualizar a senha, não sabia onde
estava errando... Que tivesse um botão para visualizar a senha."
Comportamento esperado: botão/ícone de "olho" para alternar
visibilidade da senha.
Comportamento observado: campo de senha sempre mascarado, sem alternância.
Aposta de causa: campo `<input type="password">` sem toggle — mudança
pequena, mas é melhoria de UX, não correção de algo que "faz errado"; a tela
funciona como qualquer campo de senha padrão.
Canal de correção: ponte (quando entrar na fila de backlog)
Depende de: nada

### V-05 — Anamnese: especialidade não vem pré-carregada ao escolher template
Tipo: backlog
Tela: `/anamnese`
Relato original: "Tive que achar novamente minha especialidade para carregar
o template de anamnese... No primeiro cadastro o médico já lança uma
especialidade. Na hora de carregar o template da anamnese, essa
especialidade já poderia estar carregada previamente."
Comportamento esperado: especialidade pré-selecionada a partir do cadastro do
médico.
Comportamento observado: é preciso selecionar a especialidade de novo.
Aposta de causa: template loader não lê `profile.specialty` já setado.
Canal de correção: ponte (quando entrar na fila de backlog)
Depende de: nada

### V-07 — Formulário público de anamnese sem identidade visual da clínica
Tipo: backlog
Tela: `/anamnese-publica/:responseId`
Relato original: "Formulário funciona, mas vai com a identidade visual do
sistema Nexclin... Seria legal se pudéssemos editar usando uma logo da
clínica... isso poderia ser acrescentado nas configurações."
Comportamento esperado: possibilidade de branding (logo/paleta) por clínica.
Comportamento observado: formulário sempre com a marca NexClin.
Aposta de causa: `clinics` não tem campos de logo/cor; feature nova, não
correção.
Canal de correção: ponte (feature futura)
Depende de: nada

### V-08 — Página de respostas de anamnese sem botão de copiar/resumo por IA
Tipo: backlog
Tela: `/anamnese` (aba Respostas)
Relato original: "A gente poderia disponibilizar um botão para o médico
copiar o conteúdo e colar no prontuário, com um resumo por IA das respostas e
as respostas completas logo após o resumo... Ter um botão para copiar as
informações facilitaria."
Comportamento esperado: botão de copiar + resumo gerado por IA.
Comportamento observado: só a visualização simples das respostas, campo a
campo.
Aposta de causa: feature nova; dependeria de integração de IA equivalente à
`generate-insights` (já listada como backlog de re-especificação em
`CLAUDE.md §3.5`).
Canal de correção: ponte (feature futura, maior escopo — integra IA)
Depende de: nada

### V-09 — Ficha do paciente sem canal de entrada nem anamnese visível
Tipo: backlog
Tela: ficha do paciente (`/pacientes/:id`)
Relato original: "Em nenhum lugar do cadastro do paciente fica salva a
informação de canal de entrada. Só é possível saber voltando ao funil de
atendimentos. Também não fica disponível a ficha de anamnese para
visualização aqui, somente na página de anamnese. Deveria estar tudo disposto
na ficha do paciente."
Comportamento esperado: canal de entrada e respostas de anamnese
visíveis na própria ficha do paciente.
Comportamento observado: os dados existem (em `patients.origin_id/channel_id`
e `anamnesis_responses`), mas não são exibidos juntos na ficha — é
consolidação de tela, não dado errado.
Aposta de causa: `PacienteDetalhe`/ficha não junta essas duas fontes na
mesma tela.
Canal de correção: ponte (feature futura)
Depende de: nada

### V-11 — Consulta avulsa não permite definir responsável pelo atendimento/marcação
Tipo: backlog
Tela: `/acompanhamento` (lançamento avulso)
Relato original: "Lancei uma consulta avulsa... para um paciente que não
vinha do CRM... Não me deu a opção de colocar um responsável pelo
atendimento/marcação... Que tivesse um colaborador responsável, assim como
ocorre com as consultas marcadas para os novos pacientes que chegam no CRM."
Comportamento esperado: campo de responsável disponível também no
lançamento avulso.
Comportamento observado: o campo só existe no wizard Lead→Consulta.
Aposta de causa: formulário de consulta avulsa não inclui o campo
`responsible_id` que o wizard já tem.
Canal de correção: ponte (feature futura)
Depende de: nada — mas ver ATR-1: enquanto esse campo não existe, V-15/V-16
precisam de um fallback para consultas avulsas sem responsável.

### V-30 — Extra 1: visão de agenda em calendário, somando-se à lista atual
Tipo: backlog
Tela: `/acompanhamento`
Relato original: "Extra 1: Poderíamos ter a visão de agenda em um calendário
simples, somando-se à opção de visão em lista, como a atual."
Comportamento esperado: visão adicional em calendário (dia/semana/mês).
Comportamento observado: só existe visão em lista/tabela hoje.
Aposta de causa: feature nova, não correção.
Canal de correção: ponte (feature futura, escopo maior — novo componente de
calendário)
Depende de: nada

### V-31 — Extra 2: configurar responsável por tipo de atividade (recaptação, confirmação, anamnese)
Tipo: backlog
Tela: Configurações → Regras do Negócio (ou Equipe)
Relato original: "Extra 2: ...poderíamos colocar para o próprio Dr. atribuir
um colaborador cadastrado na parte da equipe como responsável por atividades
específicas, ou deixar como o padrão de 'responsável'... Assim, se ele tiver
mais de uma pessoa do operacional na equipe, ele pode definir quem é a
responsável por recaptação e quem é por confirmação e anamnese, por
exemplo."
Comportamento esperado: configuração granular de responsável por tipo de
tarefa automática.
Comportamento observado: hoje o sistema só tem o conceito único de
"responsável" pelo atendimento/venda (que V-15/V-16 corrigem para as tarefas
existentes usarem corretamente).
Aposta de causa: feature nova — evolução do modelo atual de responsável
único.
Canal de correção: ponte (feature futura)
Depende de: V-15, V-16 (a correção mínima "atribuir ao responsável" entra
agora; esta configurabilidade fica para depois — é exatamente o exemplo do
plano: "o sistema faz certo [atribui ao responsável], mas poderia fazer a
mais [deixar escolher por tipo de tarefa]")

---

## ITENS `precisa-decisao` — perguntas prontas para o Arthur

Estado diferente de `precisa-detalhe`: aqui o relato é completo o bastante
para entender o problema, mas **não é suficiente para implementar sem
escolher entre interpretações diferentes**. Agrupado pelos quatro temas
pedidos.

### Tema: atribuição de tarefa

**ATR-1.** V-15 e V-16 têm resposta clara para o caso comum ("atribuir ao
responsável pela venda, não ao médico"). Mas V-11 mostra que consultas
avulsas hoje **não têm** responsável definido. Pergunta: quando uma tarefa de
recaptação/remarcação nasce de uma consulta avulsa sem responsável
cadastrado, o que o sistema deve fazer?
- **(a)** manter a atribuição ao médico nesse caso específico (comportamento
  atual, só como exceção documentada) — mais rápido, mas mistura duas
  regras diferentes na mesma tela;
- **(b)** tornar o campo "responsável" obrigatório também no lançamento
  avulso antes do lançamento (força V-11 a sair do backlog e entrar nesta
  janela) — mais consistente, mas aumenta o escopo de 22–23/08;
- **(c)** deixar a tarefa **sem responsável** (aparece para qualquer um da
  equipe assumir) — não inventa dono, mas pode ficar "perdida" na lista.

Consequência de cada opção: (a) é a mais rápida de implementar mas contraria
a regra que o próprio Vinícius pediu sempre que houver responsável; (b) é a
mais correta mas transforma um item de backlog (V-11) em bug de última hora;
(c) é neutra, mas pode gerar tarefa que ninguém vê como sua.

### Tema: financeiro/recebíveis

**FIN-1.** V-18 (e por tabela V-20) descreve dois níveis de correção. O nível
mínimo — "o valor a receber deve somar consulta + prescrição" — é claro e
sem ambiguidade. Mas o relato vai além: "em blocos distintos e inclusive com
pagamentos específicos... um primeiro bloco com o valor da consulta
(retirando eventuais adiantamentos, entrando como desconto); e um outro
bloco com os itens aprovados da prescrição, com outro bloco de pagamento."
Pergunta: para a janela de 22–23/08, implementamos
- **(a)** o fix mínimo — somar os dois valores num só total a receber, sem
  redesenhar a tela (rápido, resolve o "não funciona", mas não separa formas
  de pagamento por bloco); ou
- **(b)** o redesenho completo em dois blocos com pagamento independente por
  bloco, como descrito (comportamento correto e mais próximo da operação
  real de clínica que aceita só pix para consulta, por exemplo, mas é
  redesenho de tela, não é garantido caber no tempo até 01/09)?

Consequência: (a) fecha a trava de lançamento rápido, mas registra o desenho
completo como backlog imediato pós-lançamento; (b) entrega o produto certo
mas compete por tempo com os outros ~20 bugs trava desta mesma janela.

### Tema: dashboard

**DASH-1.** V-13 e V-21 pedem que o ticket médio do Dashboard passe a
considerar "a quantidade de orçamentos", não a quantidade de itens. Só que o
relatório de Vendas já existente calcula ticket como
`bruto / pacientes únicos` (`INVENTARIO.md`, Anexo). "Quantidade de
orçamentos" e "pacientes únicos" **não são a mesma coisa** quando um paciente
fecha mais de um orçamento no período. Pergunta: o ticket médio do Dashboard
deve ser
- **(a)** por **paciente único** — alinha o Dashboard ao que o relatório de
  Vendas já faz hoje, sem tocar no relatório; ou
- **(b)** por **orçamento/fechamento** — segue a literalidade do que o
  Vinícius escreveu, mas aí o relatório de Vendas também precisa mudar para
  os dois números baterem entre si?

Consequência: (a) é a correção mais barata e evita dois números de "ticket
médio" divergentes no produto; (b) segue o pedido ao pé da letra mas
implica revisar também o relatório de Vendas, que hoje não está na lista de
bugs desta bateria.

### Tema: relatórios

Nenhum item desta leva caiu em `precisa-decisao` neste tema — os pontos
vagos de relatório (V-28B, V-29) viraram `precisa-detalhe` (falta de
reprodução), não decisão de escopo. V-25 (relatório de vendas) depende da
definição de "responsável" em ATR-1, mas isso é dependência, não uma nova
pergunta de decisão.

---

## FECHAMENTO

### a) Contagem por tipo e severidade

| Categoria | Quantidade |
|---|---|
| Bugs — severidade **trava** | 22 (V-01, V-04, V-04B, V-10, V-12, V-13, V-14, V-15, V-16, V-17, V-18, V-20, V-21, V-22, V-23, V-24, V-25, V-26, V-27, V-28A, V-28B, V-29) |
| Bugs — severidade **atrapalha** | 1 (V-19) |
| Bugs — severidade **cosmético** | 2 (V-02, V-06) |
| **Total de bugs** | **25** |
| Backlog | 8 (V-03, V-05, V-07, V-08, V-09, V-11, V-30, V-31) |
| **Total geral** | **33** |
| Dos quais `precisa-detalhe` (sem repro suficiente) | 3 (V-17, V-28B, V-29) |
| Dos quais `precisa-decisao` (escopo ambíguo) | 3 perguntas (ATR-1, FIN-1, DASH-1), afetando 6 itens (V-11/15/16, V-18/20, V-13/21) |

### b) Número da trava de lançamento

**23 bugs abertos com "Atrapalha muito: Sim"** nesta leva, após as decisões
de 20/08. Eram 22 na triagem; a **D-2** promoveu o V-11 do backlog para a
janela. Esse é o número que precisa chegar a **zero** antes de 01/09, somado
ao que sair da bateria do Erick (24–26/08) — critério confirmado pelo Arthur
na **D-1**, incluindo a consequência de que a data cede antes do critério.

Ressalva sobre esse número: ele inclui **V-04**, marcado com status
"possivelmente resolvido — exige reteste". Se o reteste (passos descritos em
V-04) confirmar que o novo fluxo de convite funciona ponta a ponta, esse
item cai e a trava desta leva passa a **21** — mas até o reteste acontecer,
ele conta como aberto, por instrução explícita de não presumir correção.

### c) Itens `precisa-decisao`, por tema

- **Atribuição de tarefa** — ATR-1: fallback de responsável para tarefas
  automáticas quando a consulta é avulsa e não tem responsável definido
  (afeta V-11, V-15, V-16).
- **Financeiro/recebíveis** — FIN-1: fix mínimo (somar consulta + prescrição
  num total só) vs. redesenho completo em dois blocos com pagamento
  independente (afeta V-18, V-20).
- **Dashboard** — DASH-1: ticket médio por paciente único (alinhado ao
  relatório de Vendas existente) vs. por orçamento/fechamento (literal ao
  pedido do Vinícius, mas exige tocar também no relatório) (afeta V-13,
  V-21).
- **Relatórios** — nenhuma decisão pendente nesta leva.

### c-2) Classificação pela D-7 — o que atravessa para a stack nova

Esta é a lista que decide o trabalho, e ela **substitui** a ordem de execução
da seção (d), escrita sob o critério antigo.

#### Faixa A — atravessa como banco. Corrigir na plataforma.

O artefato é a migração, e migração vai intacta para a stack nova.

| Item | O que é | Por que atravessa |
|---|---|---|
| **V-22 + V-23** | Data do recebível por meio de pagamento (dinheiro/pix no dia, crédito antecipado em D+1, crédito sem antecipação em 30 dias) + a configuração "antecipa crédito?" da **D-5** | Regra de recebível vive no banco e na geração de parcelas. A coluna de configuração é migração literal. É o item de maior retorno do lote. |
| **V-04B** | Linha órfã em `team_members` quando a criação de acesso falha | Ordem de transação: só gravar o membro depois do acesso existir. Erro de modelagem que se repetiria na stack nova se não fosse escrito agora. |
| **V-24** | Plano de contas não carrega | **Investigado em 20/08: três hipóteses descartadas.** Falta uma consulta ao banco para decidir entre faixa A e C — a query está abaixo e leva dois minutos no SQL editor. |
| ~~**V-26 + V-27**~~ | Relatórios zerados | **Investigado em 20/08: provavelmente sintoma do V-22**, não bug próprio — o relatório filtra o mês corrente e a despesa nasce vencendo em 30 dias. Não são itens separados. Ver a investigação abaixo. |

#### Investigação de 20/08 — os três indefinidos, resolvidos no código

Os três itens que estavam "faixa A **se** a causa for banco" foram investigados
lendo o clone da plataforma. Resultado:

**V-26 e V-27 (relatórios zerados) — provavelmente NÃO são relatório quebrado.**

`RelatorioContasPagar.tsx:38` inicializa o período em **mês corrente**
(`startOfMonth(now)` → `endOfMonth(now)`) e a query filtra
`due_date` dentro desse intervalo (linha 56). O Vinícius testou em **19/08**.
Se a despesa que ele lançou nasceu com vencimento 30 dias à frente — que é
**exatamente o que o V-22 descreve** ("por padrão ele coloca o primeiro
vencimento para daqui a 30 dias") — ela cai em **setembro** e some de um
relatório filtrado em agosto.

Ou seja: **V-26 e V-27 são provavelmente sintoma do V-22**, não bugs próprios.
Corrigir a regra de data do vencimento deve fazer os dois desaparecerem.

Isso reforça a prioridade: **V-22/V-23 deixa de valer por si e passa a valer por
três**. É o item de maior retorno da janela inteira, e é faixa A.

Fica de pé um defeito menor e real: um relatório vazio por causa do filtro
**parece quebrado**. Deveria dizer "nenhum lançamento neste período" em vez de
exibir zeros — mas isso é faixa C, e vira requisito da stack nova.

**V-24 (plano de contas não carrega) — não é determinável pelo código.**

Foram descartadas três hipóteses, todas verificadas:
1. *O REVOKE de 02/08 quebrou o seed* — **não**. `handle_new_user` é
   `SECURITY DEFINER`; roda como dono da função, que mantém o EXECUTE.
2. *As contas nascem inativas e o filtro `.eq("active", true)` as descarta* —
   **não**. A coluna é `active boolean NOT NULL DEFAULT true`.
3. *RLS bloqueia o SELECT* — **não**. A policy usa
   `clinic_id = get_my_clinic_id()`, e essa função segue concedida a
   `authenticated`.

O que sobra: ou a clínica dela não tem linhas em `chart_of_accounts`, ou tem
mas nenhuma de **nível 3** — e `chart-account-select.tsx:50` mostra **só nível
3** (`analyticalOnly` é `true` por padrão).

**Uma consulta decide, e é grátis** (SQL editor do Lovable, que precisa da sua
sessão — não é dirigível por automação, conforme `docs/seguranca/`):

```sql
select level, count(*)
from chart_of_accounts
where clinic_id = (select clinic_id from profiles
                   where user_id = (select id from auth.users
                                    where email = '<e-mail da conta de teste>'))
group by level order by level;
```

- **Sem linhas, ou sem nível 3** → o seed não rodou para ela: **faixa A**,
  conserto no banco, atravessa para a stack nova.
- **Com nível 3** → o problema é do front: **faixa C**, não corrige.

---

#### Faixa B — atravessa como regra. **Já está feito neste documento.**

Para estes, o trabalho durável terminou quando a regra foi escrita. Implementar
na Lovable é opcional: só se o fundador esbarrar no uso.

V-10 (avisar em vez de bloquear) · V-11 + V-15 + V-16 (dono da tarefa é o
responsável pela venda; campo obrigatório na avulsa) · V-12 (avulsa gera as
tarefas automáticas) · V-13 + V-14 (contagem de novos pacientes; adiantamento
não é venda) · V-18 + V-20 (entrada abate a consulta) · V-19 (parcial vs
total) · V-21 (definições do dashboard) · V-25 (uma linha por item aprovado,
com prescritor e responsável) · V-29 (valor orçado na produtividade).

**São 13 itens da trava que saem da janela de 22–23/08** sem perda: a regra
está escrita, datada e vai virar critério de aceite na spec do módulo
correspondente na stack nova.

Ressalva honesta: V-13, V-21 e V-29 ainda dependem de resposta do Vinícius.
Como agora o valor está na regra e não no conserto, **a resposta dele importa
mais do que antes**, não menos — sem ela a spec da stack nova nasce com buraco.

#### Faixa C — não atravessa. Não corrigir.

V-01 (scroll da lista de especialidades) · V-02 e V-06 (mensagens de boas-vindas
e de conclusão) · V-03 (botão de ver senha) · V-17, V-28A, V-28B (filtros —
**verificar antes**: se os dados somem por causa da query e não do componente,
sobem para faixa A).

Todos viram requisito da stack nova, não lixo.

**Exceção de reputação:** se algum destes impedir o fundador de usar o que foi
prometido, ele sobe de faixa. Pela leitura de hoje, o candidato é **V-17**
(filtro de tarefas some com os dados) — tarefa é rotina diária; se o filtro
inutiliza a tela, o fundador não consegue trabalhar, e aí conserta-se apesar de
não atravessar.

#### Fora de faixa — o item mais barato do lote

**V-04** (reteste do convite de equipe) não é correção: é **verificação manual
de 15 minutos** de algo que já foi corrigido e deployado em 20/08. Continua
sendo a primeira coisa a fazer, porque custa quase nada e fecha um item.

#### O que isso faz com o conflito de 22–23/08

O conflito existia porque 23 itens de bateria disputavam a janela com a Fase 2
da SPEC 002. Sob a D-7 ele praticamente se desfaz:

- A **Fase 2 da SPEC 002** (`data_audit_log`, trigger de auditoria, `deleted_at`,
  policies) é **faixa A pura** — é banco, e o T014 já prevê o backport como
  migração versionada na stack nova. Atravessa 100%.
- Da bateria, sobra a **faixa A**: V-22+V-23, V-04B, e a investigação de V-24 e
  V-26+V-27. Mais o reteste V-04.
- Os 13 itens de faixa B **saem da janela** com o trabalho já entregue.

**A Fase 2 da SPEC 002 passa a ter prioridade sobre a bateria**, porque é o
maior bloco de faixa A que existe hoje — e continua valendo que o **T004
(export do banco) é gate absoluto**, assíncrono e limitado a 1 por 24h. Ele
deveria ser disparado antes de 22/08.

---

### d) Ordem de execução sugerida — janela de 22–23/08

> **OBSOLETA.** Escrita sob o critério da D-1, revogada pela D-7. Mantida
> como registro do raciocínio; a lista válida é a da seção **c-2** acima.

**Pode começar já (sem decisão pendente), em ordem de "o que não
funciona" primeiro:**
1. V-04 — reteste do convite de equipe (não é código, é 15 minutos de
   verificação manual; prioridade zero porque pode fechar um item da trava
   sem nenhum desenvolvimento).
2. V-24 — plano de contas não carrega (bloqueia rotina básica de lançar
   despesa).
3. V-10 — bloqueio de agenda duplicada (risco operacional direto: duas
   consultas no mesmo horário).
4. V-22 + V-23 — datas automáticas de recebível por método de pagamento
   (regra completa, único commit resolve as duas telas).
5. V-12 — tarefas automáticas para consulta avulsa (fix independente de
   ATR-1: só precisa chamar `createAppointmentTasks`; a questão do
   responsável é separada).
6. V-19 — rótulo de fechamento parcial/total (isolado, rápido).
7. V-26 + V-27 — relatórios de Contas a Pagar e DRE/DFC zerados (investigar
   junto, suspeita de causa comum).
8. V-13 + V-14 — contagens e classificação do Dashboard (parte que não
   depende de DASH-1: total de consultas, adiantamento como consulta,
   filtro de "1ª vez").
9. V-25 — agrupamento do relatório de vendas (a parte de agrupar linhas por
   item aprovado não depende de ATR-1; as colunas de médico/responsável
   podem entrar depois que ATR-1 for respondida).
10. V-28A — datas personalizadas no relatório de contas a receber.
11. V-01 — scroll da lista de especialidades.
12. V-02 + V-06 — mensagens de boas-vindas e de conclusão do onboarding
    (cosméticos, mas baratos — encaixar se sobrar tempo).
13. V-04B — parar de gerar linha órfã em `team_members` + limpar
    duplicatas via SQL editor.

**RECONCILIAÇÃO COM AS DECISÕES DE 20/08** — esta ordem foi escrita antes
delas. Onde divergir, vale o que está abaixo:

- **Desbloqueados pela D-2** (responsável obrigatório na avulsa): V-11, V-15
  e V-16 saem do "aguardando" e **entram na janela**. Ordem entre eles: V-11
  primeiro (o campo obrigatório é pré-requisito), depois V-15 e V-16, que
  passam a ser a mesma correção — a tarefa nasce do responsável pela venda,
  sempre, sem exceção para o médico.
- **Desbloqueados pela D-3** (fix mínimo no financeiro): V-18 e V-20 **entram
  na janela** no escopo reduzido — somar consulta + prescrição no total a
  receber, entrada abatendo a consulta, adiantamento fora de "vendas". O
  redesenho em dois blocos **não entra**: virou backlog pós-01/09.
- **Definido pela D-4** (agenda): V-10 é **aviso com confirmação**, não
  bloqueio. Muda a implementação do item 3 da lista acima.
- **Definido pela D-5** (crédito): V-22 e V-23 dependem de uma configuração
  nova da clínica — "antecipa recebimento de crédito?" — junto das taxas.
  Isso **acrescenta um item de Configurações** ao escopo do bloco 4, que a
  ordem original não previa.
- **Continua bloqueado, agora por dependência externa e não por decisão
  interna (D-6):** V-13 e V-21 na parte de ticket médio. A pergunta está
  pronta em `perguntas-vinicius-20-08.md` e precisa de resposta até
  **21/08**. As outras facetas do V-21 (total de consultas zerado, taxa de
  conversão, tops zerados, gráfico do fluxo de caixa) seguem liberadas.
- **Entra fora da trava, por decisão menor:** V-03 (botão de ver senha no
  login). Rótulo de backlog, conserto de minutos, e o Vinícius marcou
  "Atrapalha muito: Sim".

**Precisa da resposta do Vinícius antes de virar tarefa de código:**
- V-17, V-28B, V-29 — enviar as três perguntas de `precisa-detalhe` assim
  que possível (idealmente ainda em 20 ou 21/08, para não perder a janela de
  22–23).

**Fora da janela de 22–23/08 (backlog, sem prazo definido):**
- V-05, V-07, V-08, V-09, V-30, V-31.
- **Backlog com data, criado pela D-3:** o redesenho do financeiro em dois
  blocos com forma de pagamento independente por bloco. É o maior item
  adiado desta leva e precisa de spec própria antes de implementar.
- *(V-03 e V-11 saíram desta lista — ver reconciliação acima.)*

**Atenção de procedimento (não é item de bug, é risco de execução):** pelo
menos V-04 (reteste de edge function) e qualquer correção que toque
`supabase/functions/` nesta janela precisam seguir a ordem de
`docs/ponte/ponte-inversa.md` — **function primeiro, Publish do front depois**
— e o deploy de function não é gratuito (consome crédito diário de build,
não o mensal). A janela de 22–23/08 também compete com a Fase 2 da SPEC 002
e outras pendências técnicas já registradas em
`docs/planejamento/status-cronograma-19-08.md` — vale confirmar prioridade
relativa antes de começar.
