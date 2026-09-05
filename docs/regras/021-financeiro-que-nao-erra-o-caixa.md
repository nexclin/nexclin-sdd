# 021 · Financeiro que não erra o caixa

> **Regra viva.** Nasce antes da execução, guia a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 05/09/2026:** especificada, nada implementado. Os achados da seção
> 3 foram **lidos nas migrações deste repositório**, e não conferidos no banco ao
> vivo. Alvo: **Lovable até 08/09 no que é faixa A**, stack nova no resto.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` §2.5 ·
> **Origem:** reunião de 03/09/2026, apurada em
> [`../historico/2026-09-04-reuniao-03-09-decisoes.md`](../historico/2026-09-04-reuniao-03-09-decisoes.md)
> §4.1, mais leitura de `supabase/migrations` em 05/09.

---

## 1. O problema

O financeiro é o que a clínica não tem e é por ele que o NexClin foi vendido: na
reunião de 03/09 o sócio comercial o chamou de **preocupação 01** e disse que
*"ninguém que contrata sistema fica satisfeito de perder controle por falha do
sistema"*. Só que o modelo de hoje não consegue responder três perguntas que
qualquer clínica faz toda semana: **quanto entrou de verdade**, **quanto tenho
hoje na conta**, e **este lançamento bate com o extrato do banco**. Não é
questão de tela: as colunas que responderiam não existem. E, pela §2.5, o que
está gravado errado em setembro **não é descartado em outubro, é importado**,
sobre uma estimativa de R$ 100 a 200 mil de faturamento por clínica no mês da
Lovable.

---

## 2. Requisitos

A coluna **faixa** aplica a §2.5 pela pergunta que classifica, *o que fica
gravado?*. A coluna **alvo** diz onde o requisito precisa existir.

### O que fica gravado quando alguém recebe

- **FR-001** · faixa **A** · alvo **Lovable + stack nova**
  A baixa de um recebível **MUST** acontecer em duas etapas: registrar o
  pagamento com os seus apontamentos, e **depois** confirmar. Trocar o campo
  `status` direto para `recebido` **MUST NOT** continuar sendo o caminho.
  *Porquê:* hoje a tela troca o status e o sistema infere o resto. O que se
  infere não se audita, e foi o próprio autor do desenho original quem o
  classificou como ultrapassado, em 00:29:11 da reunião.

- **FR-002** · faixa **A** · alvo **Lovable + stack nova**
  O recebível **MUST** guardar o **valor efetivamente recebido** em coluna
  própria, separada do valor previsto.
  *Porquê:* hoje existe `value` e não existe onde pôr o que o banco creditou.
  Quando os dois divergem, por tarifa, desconto, juro ou pagamento parcial, o
  sistema grava o previsto como se fosse o realizado. **É assim que nasce
  divergência de caixa**, que é exatamente o que a reunião apontou como o erro
  que não pode acontecer.

- **FR-003** · faixa **A** · alvo **Lovable + stack nova**
  A baixa **MUST** gravar **quem** a fez e **quando**, com a hora e não só a
  data.
  *Porquê:* a alínea (d) da constituição exige auditoria de ação administrativa
  sobre dado de cliente, e dar baixa é decidir que dinheiro entrou. Hoje só
  existe `paid_at`, que é `DATE`, e nenhuma coluna de autor. Ficou mais urgente
  com a decisão de 04/09 de login de superadmin compartilhado pelos três sócios.

- **FR-004** · faixa **A** · alvo **Lovable + stack nova**
  A conta bancária **MUST** ter **saldo inicial** e a data a que ele se refere.
  *Porquê:* **este requisito corrige uma classificação errada.** Na apuração de
  04/09 o "saldo de hoje em destaque" foi posto na faixa B, como cálculo de
  tela. A leitura de `bank_accounts` em 05/09 mostrou que a tabela **não tem
  nenhuma coluna de saldo**, nem inicial nem corrente. Sem um ponto de partida
  gravado, saldo de hoje não é exibição que falta: é **conta que não fecha**. Foi
  por isso que a tela passou a mostrar "saldo do período", que é o que dá para
  calcular sem saldo inicial.

- **FR-005** · faixa **A** · alvo **stack nova**
  Transferência entre contas da clínica **MUST** ser gravada como movimento
  próprio, com conta de origem, conta de destino, valor e data.
  *Porquê:* não existe hoje nenhum lugar para ela. Sem isso, quem tem duas
  contas vê o dinheiro sair de uma e nunca entrar na outra, e o saldo consolidado
  mente.

### O extrato do banco, e a conciliação

- **FR-006** · faixa **A** · alvo **stack nova**
  O extrato importado **MUST** existir como linhas próprias, uma por transação
  do banco, com identificador da transação, data, valor, descrição e conta.
  *Porquê:* conciliar é casar duas listas. Sem a lista do banco gravada, não há
  o que casar.

- **FR-007** · faixa **A** · alvo **stack nova**
  A conciliação **MUST** ser o **vínculo** entre uma linha de extrato e um
  recebível ou despesa. A marca de conciliado **MUST** derivar desse vínculo, e
  **MUST NOT** continuar sendo booleano que qualquer escrita liga.
  *Porquê:* `receivables` já tem `conciliated` e `conciliated_at` desde 22/03, e
  **não tem contraparte nenhuma**. Hoje é uma caixinha que alguém marca, o que
  responde "alguém disse que conferiu" e não responde "bate com o banco".

- **FR-008** · faixa **A** · alvo **stack nova**
  A importação de OFX **MUST** ser idempotente: reimportar o mesmo arquivo
  **MUST NOT** duplicar linha nem baixa.
  *Porquê:* reimportação acontece, por erro ou por arquivo que se sobrepõe ao
  anterior. Sem chave do banco por transação, a segunda importação dobra o caixa.

- **FR-009** · faixa **A** · alvo **stack nova**
  A baixa automática vinda da conciliação **MUST** passar pelo mesmo caminho do
  FR-001, e **MUST NOT** escrever direto no recebível.
  *Porquê:* a dívida estrutural registrada é que `receivables` é escrita por
  **seis caminhos diferentes**, e é assim que o mesmo fato financeiro entra em
  formatos distintos. Somar um sétimo caminho é o erro barato de cometer agora e
  caro de desfazer em outubro.

### Recorrência

- **FR-010** · faixa **A** · alvo **stack nova**
  Contas a receber **MUST** aceitar recorrência, com início, fim e periodicidade,
  no mesmo desenho que `fixed_expenses` já usa.
  *Porquê:* a assimetria é gratuita. `fixed_expenses` ganhou `recurrence`,
  `start_date` e `end_date` em 22/03, e o lado de receber ficou sem. Mensalidade,
  plano e acompanhamento são receita recorrente na clínica.

### O que a permissão de módulo não está guardando

- **FR-011** · faixa **A** · alvo **stack nova**
  As policies de `receivables`, `expenses`, `revenues` e `fixed_expenses`
  **MUST** consultar `my_permission` do módulo correspondente
  (`contas_receber`, `contas_pagar`, `fluxo_caixa`), e **MUST NOT** conceder
  `FOR ALL` apenas por pertencer à clínica.
  *Porquê:* **achado da leitura de 05/09, e é o mais grave desta regra.** As
  quatro tabelas carregam a policy original de 22/03, `FOR ALL TO authenticated`
  filtrando só por `clinic_id`, e nenhuma migração posterior a substituiu. A
  função `my_permission` existe e é a cascata central, mas **nenhuma policy do
  financeiro a chama**. Na prática, qualquer usuário com login na clínica lê e
  escreve todo o financeiro dela, mesmo com o módulo negado: o que o nega é o
  menu. Isso é a alínea (c) da constituição ao contrário, *"nenhuma regra de
  acesso pode existir só no frontend"*, e é o mesmo defeito que a auditoria de
  29/08 achou nos quatro papéis do painel.

- **FR-012** · faixa **A** · alvo **stack nova**
  `expenses.payment_method` **MUST** virar referência à tabela
  `payment_methods`, como já é do lado de receber.
  *Porquê:* hoje é `TEXT` livre de um lado e chave estrangeira do outro. Fluxo de
  caixa por forma de pagamento não fecha quando metade dos dados é texto digitado.

### O que é tela, e a regra escrita basta

- **FR-013** · faixa **B** · alvo **stack nova**
  O fluxo de caixa **MUST** destacar o **saldo de hoje**, e **MUST NOT**
  apresentar o saldo do fim do período selecionado com rótulo que sugira o de
  hoje. Depende do FR-004.
  *Porquê:* apontado ao vivo na reunião, de 00:30:12 a 00:31:04. O rótulo "saldo
  do período" está correto e é lido como saldo atual.

- **FR-014** · faixa **B** · alvo **stack nova**
  A régua de cobrança **SHOULD** ser apresentada em Kanban por faixa de atraso.
  *Porquê:* pedido na reunião. É exibição sobre dado já gravado, e a régua atual
  já abre o WhatsApp com a mensagem preenchida, o que foi confirmado em 00:50:22.
  A mensagem pré-cadastrada **por faixa** é configuração, e essa parte é faixa A.

### O que esta regra proíbe

- **FR-015** · **MUST NOT** nascer tabela paralela de eventos financeiros.
  *Porquê:* é a mesma proibição do FR-001 da regra 020, e pela mesma razão:
  `receivables` já é escrita de seis lugares, e foi assim que recebível sem
  `macro_category` caiu no balde errado.

- **FR-016** · **MUST NOT** haver dois lugares gravando o mesmo faturamento.
  *Porquê:* `revenues` e `receivables` guardam hoje **os mesmos campos**.
  Em 22/03 o `receivables` absorveu `payment_method_id`, `gross_value`,
  `net_value`, `fee_percent`, `item`, `category`, `macro_category`, `quantity` e
  `brand`, que já existiam em `revenues`, e a tabela `revenues` **continuou de
  pé**. Duas tabelas para o mesmo fato é candidata forte a explicar a pendência
  aberta das **28 linhas** de diferença entre 252 na tela de Vendas e 280 na
  base. Isto é hipótese de leitura, **não está provado**, e a seção 6 diz como se
  prova.

---

## 3. O que muda no banco

### O que já existe, e foi conferido nas migrações em 05/09

| Objeto | Estado |
|---|---|
| `receivables.bank_account_id`, `.acquirer_id` | existem, desde `20260325144059` |
| `receivables.conciliated`, `.conciliated_at` | existem desde `20260322185846`, **sem contraparte nenhuma** |
| `receivables.payment_method_id`, `.gross_value`, `.net_value`, `.fee_percent` | existem, absorvidos de `revenues` em `20260322201904` |
| `expenses.bank_account_id` | existe |
| `fixed_expenses.recurrence`, `.start_date`, `.end_date` | existem |
| `bank_accounts` | **não tem coluna de saldo**, nem inicial nem corrente |
| `revenues` | continua existindo, com os mesmos campos que o `receivables` absorveu |
| policies de `receivables`, `expenses`, `revenues`, `fixed_expenses` | `FOR ALL TO authenticated` por `clinic_id`, **sem `my_permission`** |

### O que precisa nascer

| Objeto | Mudança | FR |
|---|---|---|
| `receivables` | coluna de **valor recebido**, distinta de `value` | FR-002 |
| `receivables` | **autor da baixa** e **hora da baixa** em `timestamptz` | FR-003 |
| `expenses` | as mesmas duas de cima | FR-002, FR-003 |
| `bank_accounts` | **saldo inicial** e a data a que ele se refere | FR-004 |
| tabela nova de **transferência entre contas** | origem, destino, valor, data, autor | FR-005 |
| tabela nova de **linha de extrato** | conta, identificador da transação no banco, data, valor, descrição, com **índice único** por conta mais identificador | FR-006, FR-008 |
| tabela nova de **vínculo de conciliação** | linha de extrato e o recebível ou a despesa que ela quita | FR-007 |
| `receivables.conciliated` | passa a derivar do vínculo | FR-007 |
| `receivables` | colunas de recorrência, no desenho de `fixed_expenses` | FR-010 |
| policies das quatro tabelas | separadas por operação e consultando `my_permission` | FR-011 |
| `expenses.payment_method` | vira referência a `payment_methods` | FR-012 |
| `revenues` | decidir o destino. Ver seção 7 | FR-016 |

**Toda tabela nova nasce com RLS por `clinic_id` e default deny**, alíneas (a) e
(b). **Nenhuma policy com `USING(true)`**, e o hook
`guarda-constituicao.mjs` reprova se aparecer.

---

## 4. Premissas

1. **As migrações deste repositório descrevem o banco ao vivo da Lovable.** É
   premissa, não fato conferido. A armadilha 2 do contexto de abertura diz que
   leitura pela API mente sobre o banco inteiro por causa do RLS, então a
   conferência vai no editor de SQL. **Se divergir, a divergência é o achado** e
   esta regra se corrige antes de qualquer implementação.
2. **O fato financeiro tem um dono só.** Um recebível pertence a uma clínica e a
   uma conta bancária no momento em que é baixado.
3. **O extrato do banco é a verdade** quando ele e o lançamento divergem. A
   conciliação existe para expor a diferença, não para escondê-la.
4. **A referência funcional é o sistema IN**, por decisão da reunião, e o sócio
   comercial dispensou aprovação de escopo neste módulo com a condição de que o
   comportamento seja igual ao de lá.

---

## 5. Dependências

**Antes desta regra:**

- **O acesso ao IN, ou o vídeo.** Ficou com o Erick na reunião. Sem uma das
  duas coisas, "funcionar igual ao IN" não é critério verificável, e os FR-006 a
  FR-009 são os que mais dependem disso.
- **A conferência do schema ao vivo**, premissa 1.
- **Supabase Pro ligado antes de 08/09**, issue #47. Mexer em modelo financeiro
  sem backup diário é a combinação que não se faz com dado de cliente real.

**Depende desta regra:**

- O relatório de Vendas e a pendência das 28 linhas.
- O dashboard, cuja acusação de "puxar do lugar errado" continua sem número que
  a reproduza.
- A stack nova, que precisa nascer sem a dívida dos seis caminhos de escrita.

**Não é dependência, e vale dizer:** a régua de cobrança **já abre o WhatsApp**
com a mensagem preenchida. O Papo AI foi para a V2 na reunião e não bloqueia
nada aqui.

---

## 6. Como se prova que funciona

Pela alínea (j) e pela **regra dos 200%** fechada na reunião: 100% é construído e
testado por quem construiu, 200% é validado pela ótica do usuário final. O
financeiro é uma das duas áreas que **precisam chegar a 200% em 08/09**, por
decisão de 04/09.

**Cada bloco abaixo precisa de controle positivo.** A armadilha 5 do contexto de
abertura: asserção negativa passa por vacuidade, e "fulano não consegue" fica
verdadeiro quando o teste está errado.

| # | O que se prova | Como |
|---|---|---|
| 1 | o schema ao vivo é o que as migrações dizem | consulta a `information_schema` no editor de SQL, listando colunas de `receivables`, `expenses`, `bank_accounts` e as policies das quatro tabelas |
| 2 | **FR-011**, o buraco de permissão | dentro de `BEGIN`/`ROLLBACK`, com `SET LOCAL ROLE authenticated` e `request.jwt.claims` de um usuário com `contas_receber` negado, tentar `select` em `receivables`. **Hoje o esperado é que volte linha, e isso é o defeito.** O controle positivo é o mesmo bloco com um usuário que tem o módulo liberado |
| 3 | **FR-016**, a hipótese das 28 linhas | contar `receivables` e `revenues` da Clínica Teste Final no editor de SQL, e cruzar com os 280 recebíveis da base de referência. Se a diferença aparecer aqui, a hipótese ganha; se não, ela cai e fica registrado que caiu |
| 4 | FR-001 e FR-003 | dar baixa pela tela e conferir no banco: valor recebido, hora com fuso, e o autor |
| 5 | FR-002 | dar baixa de um recebível de R$ 100 recebendo R$ 97. O previsto continua 100, o recebido é 97, e o fluxo de caixa usa 97 |
| 6 | FR-004 e FR-013 | com saldo inicial gravado, o saldo de hoje na tela bate com a soma feita à mão |
| 7 | FR-008 | importar o mesmo OFX duas vezes. A segunda **não** cria linha nem baixa |
| 8 | FR-007 | desfazer uma conciliação. A marca de conciliado cai junto, porque deriva do vínculo |

**O que a prova automatizada não cobre:** nada disto fecha por teste de unidade.
São comportamento de banco e de tela, e a reunião fechou que *"não dá para
entregar nada pro usuário final que não foi testado por alguém que não seja uma
IA"*. Item sem prova na tela fecha como **"código lido, não comportamento
provado"** e continua aberto.

---

## 7. A decisão que falta, e precisa do Arthur

**1. O que fazer com `revenues`.** Ela guarda hoje os mesmos campos que
`receivables` absorveu em 22/03, e as duas continuam de pé. Três saídas:

| Saída | O que custa | O que ganha |
|---|---|---|
| aposentar `revenues` e migrar o que estiver nela | migração de dado com clínica real em cima, a três dias do lançamento | mata a duplicação na origem, e a stack nova nasce sem ela |
| congelar `revenues` para leitura e escrever só em `receivables` | precisa achar e trocar todo caminho de escrita, e há seis | reduz o dano sem migrar dado |
| **não mexer agora**, e a stack nova nascer só com `receivables` | a duplicação continua até outubro, e o que for gravado errado é importado | risco zero de quebrar o que está no ar a três dias |

**Recomendação do executor, e é recomendação, não decisão:** a terceira, **com a
prova 3 da seção 6 feita antes de 08/09**. Se as 28 linhas vierem daí, a
resposta muda e vale reabrir. Mexer em duas tabelas de dinheiro a três dias do
lançamento é o tipo de conserto que a §2.5 não pede.

**2. O FR-011 entra antes de 08/09 ou é requisito da stack nova?** É faixa A e é
violação da alínea (c), o que puxa para agora. Contra: trocar policy de quatro
tabelas financeiras na véspera, e no dia 8 quem opera são clínicas fundadoras em
que **todo mundo é a dona e a secretária**, com o módulo liberado de qualquer
jeito. O dano real aparece quando a clínica tiver equipe com permissão parcial.

**3. Até onde vai o "igual ao IN".** A reunião dispensou aprovação de escopo
neste módulo, o que só funciona se houver uma referência para comparar. **Sem o
acesso ou o vídeo, esta regra para no FR-005.** É a dependência mais barata de
resolver e a que mais trava.
