---
description: "Lista de tarefas da frente 021, financeiro"
---

# Tarefas: financeiro que não erra o caixa

**Entrada:** [`plan.md`](./plan.md) e [`spec.md`](./spec.md), que é link para a
regra viva.

## Formato: `[ID] [P?] [Fase] Descrição com o caminho do arquivo`

- **[P]**: pode rodar em paralelo, arquivo diferente e sem dependência aberta.
- **[Fase]**: `[F0]` a `[F5]`, as fases do plano.

> **Aqui não há user story, e isso é de propósito.** A
> [ADR 0005](../../adr/0005-bifurcar-o-to-spec.md) removeu user story do formato
> deste projeto: as três da regra 005 custaram 80 linhas e não apareceram em
> nenhum plano, nenhuma tarefa e nenhuma mensagem de commit. O agrupamento aqui é
> por **fase do plano**, que é o que tem aceite próprio pela alínea (h).

> **Os três portões são parada dura.** Tarefa depois de um portão **não começa**
> antes de a decisão sair. Atravessar portão é o que este plano existe para
> impedir.

---

## Fase 0 · Conferir o banco antes de acreditar nele

**Objetivo:** derrubar ou confirmar a premissa 1 da regra, e medir o buraco do
FR-011 antes de decidir sobre ele.

**Aceite:** o resultado bate com a tabela "o que já existe" da seção 3 da regra.
Se divergir, **a divergência é o achado** e a regra se corrige antes de T006.

- [ ] T001 (#55) [F0] Escrever o bloco de censo de schema em `docs/ponte/021-censo-financeiro.sql`, listando por `information_schema.columns` as colunas de `receivables`, `expenses` e `bank_accounts`, e por `pg_policies` as policies de `receivables`, `expenses`, `revenues` e `fixed_expenses`
- [ ] T002 (#56) [P] [F0] Escrever no mesmo arquivo a **prova 3**, contando `receivables` e `revenues` da Clínica Teste Final (`d51ce6c7-582b-469b-a01b-608bd9b38885`) e cruzando com os 280 recebíveis da base de referência
- [ ] T003 (#57) [P] [F0] Escrever no mesmo arquivo a **prova 2**, o bloco `BEGIN`/`ROLLBACK` com `SET LOCAL ROLE authenticated` e `request.jwt.claims`, medindo o que um usuário com `contas_receber` negado consegue ler de `receivables`. **Com controle positivo**: o mesmo bloco para um usuário com o módulo liberado
- [ ] T004 (#58) [F0] Rodar os três blocos no editor de SQL da plataforma, um por vez. **Clicar por referência e não por coordenada**: o botão Run muda de altura conforme o painel do chat rola
- [ ] T005 (#59) [F0] Registrar o resultado em `docs/historico/2026-09-NN-censo-financeiro.md`, inclusive o que não deu para conferir, e corrigir a seção 3 da regra no mesmo commit se houver divergência

**Ponto de conferência:** premissa 1 confirmada ou derrubada, e o tamanho do
buraco do FR-011 medido em número.

---

## PORTÃO 1 · O destino de `revenues` · FR-016

**Abre com T002.** Se as 28 linhas vierem da duplicação, a decisão 1 da seção 7
volta à mesa antes de 08/09 e nascem tarefas novas aqui. Se não vierem, a
recomendação registrada vale e `revenues` não é tocada.

- [ ] T006 (#60) [F0] **FR-016**: levar o resultado de T002 ao Arthur com as três saídas da seção 7 da regra, e registrar a decisão em `docs/historico/`

**Enquanto este portão não abrir, nenhuma tarefa escreve em `revenues`.**

---

## Fase 1 · O que fica gravado quando alguém recebe · faixa A · Lovable

**Objetivo:** FR-001 a FR-004. É a fase que paga o prazo de 08/09, porque é a que
impede erro de virar importação em outubro.

**Aceite independente:** provas 4, 5 e 6 da seção 6 da regra, na tela, mais
`npx tsc --noEmit -p tsconfig.app.json` limpo.

### Banco, e ele vem primeiro

- [ ] T007 (#61) [F1] Escrever a migração `supabase/migrations/2026090NNNNNNN_baixa_em_duas_etapas_e_saldo_inicial.sql`: valor recebido e autor da baixa em `receivables` e `expenses`, hora da baixa em `timestamptz`, e saldo inicial mais a data dele em `bank_accounts`
- [ ] T008 (#62) [F1] Escrever o bloco guiado de aplicação em `docs/ponte/aplicacao-021-fase1/`, um bloco por vez, **cada um com a sua consulta de conferência ao lado e a reversão palavra por palavra abaixo**
- [ ] T009 (#63) [F1] Conferir que o export do banco está feito e com cópia em nuvem, por `docs/seguranca/registro-exports-banco.md`. **Cuidado com a tela:** logo abaixo do `Export data` ficam `Pause` e `Remove`, os dois em vermelho, num espaço de cerca de 200 pixels
- [ ] T010 (#64) [F1] Aplicar os blocos no editor de SQL e conferir cada um
- [ ] T011 (#65) [P] [F1] Rodar o hook `.claude/hooks/guarda-constituicao.mjs` sobre a migração nova: sem RLS ausente, sem `USING(true)`, sem caminho que define senha, sem segredo versionado

### Front, e só depois do banco

> **Ordem obrigatória.** Front novo com a coluna inexistente quebra a tela de
> dinheiro. E o Publish da Lovable publica o **preview**, não o commit.

- [ ] T012 (#66) [F1] Trocar a baixa de contas a receber por duas etapas em `../nexclin-lovable/src/`, registrando pagamento com apontamentos e depois confirmando, e parar de escrever `status` direto
- [ ] T013 (#67) [F1] Fazer a mesma troca em contas a **pagar**. **O padrão que se repetiu cinco vezes nesta base é conserto aplicado a uma tela e não às irmãs**
- [ ] T014 (#68) [F1] Gate de tipos com `npx tsc --noEmit -p tsconfig.app.json`. `npm run build` **não** confere tipos, porque Vite usa esbuild, e foi isso que derrubou o app por 1h35 em 20/08
- [ ] T015 (#69) [F1] Publicar pelo procedimento de `docs/ponte/ponte-inversa.md`, e rodar `scripts/ponte.sh conferir`
- [ ] T016 (#70) [F1] Procurar um marcador de texto das telas novas dentro do bundle publicado, porque o `conferir` sozinho não prova que o código subiu

### Aceite, e é onde a fase fecha

- [ ] T017 (#71) [F1] **Prova 4** na tela: dar baixa e conferir no banco o valor recebido, a hora com fuso e o autor
- [ ] T018 (#72) [F1] **Prova 5** na tela: baixar um recebível de R$ 100 recebendo R$ 97. O previsto continua 100, o recebido é 97, e o fluxo de caixa usa 97
- [ ] T019 (#73) [F1] **Prova 6** na tela: com saldo inicial gravado, o saldo de hoje bate com a soma feita à mão
- [ ] T020 (#74) [F1] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto. Sem arredondar

**Ponto de conferência:** o dinheiro que entra passa a ser gravado como entrou,
e não como estava previsto.

---

## PORTÃO 2 · O FR-011 entra antes de 08/09?

**Abre com T003, que já mediu o buraco.** A decisão é da seção 7, item 2, e é do
Arthur.

- [ ] T021 [F1] Levar o número de T003 ao Arthur, com os dois lados escritos: é violação da alínea (c) e puxa para agora; no dia 8 quem opera são clínicas em que a mesma pessoa é dona e secretária, com o módulo liberado de qualquer jeito

---

## Fase 2 · A permissão volta para o banco · faixa A

**Objetivo:** FR-011 e FR-012.

**Aceite independente:** prova 2 **com as duas metades**. Usuário com o módulo
negado volta zero linha, e usuário com o módulo liberado volta linha. Só a
primeira metade passa por vacuidade, que é o que quase deixou o **FR-005 da
regra 017**, a trilha de leitura, fechar por engano. `FR-005` sem o número da
regra é ambíguo: nesta frente ele é a transferência entre contas.

- [ ] T022 [F2] Escrever a migração que troca as policies de `receivables`, `expenses`, `revenues` e `fixed_expenses`: separadas por operação e consultando `my_permission` do módulo correspondente, em vez de `FOR ALL` só por `clinic_id`
- [ ] T023 [P] [F2] Escrever no mesmo arquivo a mudança de `expenses.payment_method` para referência a `payment_methods`, com a conversão dos valores em texto que existirem
- [ ] T024 [F2] Escrever a reversão palavra por palavra logo abaixo de cada bloco. Policy de tabela financeira é onde erro tranca a clínica inteira
- [ ] T025 [F2] Rodar o agente `auditor-multitenant` sobre a migração, **tentando furar a cascata** e não só lendo
- [ ] T026 [F2] Achado de nível alto do auditor vira issue própria antes de a fase fechar
- [ ] T027 [F2] Aplicar e rodar a prova 2 completa, com controle positivo

**Ponto de conferência:** módulo negado passa a negar no banco, e não só no menu.

---

## PORTÃO 3 · A referência do IN

**Sem o acesso à conta ou o vídeo, este plano para aqui.** Foi a condição sob a
qual o escopo do financeiro dispensou aprovação de escopo.

- [ ] T028 [F2] Cobrar do Erick o acesso ou o vídeo, e registrar em qual dia chegou

---

## Fase 3 · Extrato e conciliação · faixa A · stack nova

**Objetivo:** FR-005 a FR-009.

**Aceite independente:** provas 7 e 8.

- [ ] T029 [F3] Modelar a tabela de **linha de extrato** e escrever a migração em `supabase/migrations/`: conta, identificador da transação no banco, data, valor, descrição, com RLS por `clinic_id` e default deny
- [ ] T030 [F3] Criar o **índice único por conta mais identificador da transação**. A idempotência do FR-008 mora no banco, não no código: trava no banco não depende de quem chama
- [ ] T031 [P] [F3] Modelar a tabela de **vínculo de conciliação**, ligando linha de extrato a recebível ou despesa, com RLS e default deny
- [ ] T032 [P] [F3] Modelar a tabela de **transferência entre contas** (FR-005): origem, destino, valor, data e autor, com RLS e default deny
- [ ] T033 [F3] **FR-007**: fazer `receivables.conciliated` derivar do vínculo em vez de ser booleano que qualquer escrita liga
- [ ] T034 [F3] Escrever o leitor de OFX na stack nova, gravando linha de extrato e **nada além disso**
- [ ] T035 [F3] **FR-009 e FR-015**: ligar a baixa automática ao **mesmo caminho da Fase 1**. Não abrir o sétimo caminho de escrita em `receivables`: são seis hoje, e é assim que o mesmo fato entra em formatos distintos
- [ ] T036 [F3] Teste de unidade do leitor de OFX em `lib/`, antes do leitor, e **ver falhar**
- [ ] T037 [F3] **Prova 7**: importar o mesmo OFX duas vezes. A segunda não cria linha nem baixa
- [ ] T038 [F3] **Prova 8**: desfazer uma conciliação. A marca de conciliado cai junto, porque deriva do vínculo

**Ponto de conferência:** conciliar passa a casar duas listas, e não a marcar uma
caixinha.

---

## Fase 4 · Recorrência a receber · faixa A · stack nova

**Objetivo:** FR-010.

- [ ] T039 [F4] Ler o desenho de recorrência de `fixed_expenses` (`recurrence`, `start_date`, `end_date`, de `20260322185846`) antes de escrever qualquer coisa
- [ ] T040 [F4] Escrever a migração que dá as mesmas colunas a `receivables`, **copiando o desenho que existe** em vez de inventar outro
- [ ] T041 [F4] Aceite na tela: cadastrar uma receita mensal e conferir as linhas geradas, inclusive a última antes do fim

---

## Fase 5 · Tela · faixa B · stack nova

**Objetivo:** FR-013 e FR-014. Por último de propósito: é a camada que só vale
depois dos dados certos, que foi o acordo da reunião.

- [ ] T042 [F5] Destacar o **saldo de hoje** no fluxo de caixa, e deixar de apresentar o saldo do fim do período com rótulo que sugira o de hoje. **Depende de T007**, porque sem saldo inicial a conta não fecha
- [ ] T043 [P] [F5] Apresentar a régua de cobrança em Kanban por faixa de atraso, com a mensagem pré-cadastrada por faixa
- [ ] T044 [F5] Aceite na tela pela ótica de quem usa, e não pela do backend. **A régua dos 200% é o que fecha esta fase**

---

## Fase 6 · Fechamento

- [ ] T045 [P] [F6] Atualizar a tabela de `docs/regras/README.md` com o estado real da regra 021
- [ ] T046 [P] [F6] Rodar `/speckit-analyze` sobre regra, plano e tarefas, e resolver a inconsistência que ele apontar
- [ ] T047 [F6] Escrever o handoff do dia em `docs/historico/`, com o que ficou aberto dito em voz alta

---

## Dependências e ordem

### Entre fases

- **F0** não depende de nada e **bloqueia todo o resto**.
- **PORTÃO 1** depende de T002. Bloqueia qualquer escrita em `revenues`.
- **F1** depende de F0. É a única fase com prazo em 08/09.
- **PORTÃO 2** depende de T003. Bloqueia F2.
- **F2** depende do portão 2.
- **PORTÃO 3** depende de gente, não de código. Bloqueia F3, F4 e F5.
- **F3, F4 e F5** dependem do portão 3. F5 depende também de T007.
- **F6** depende de tudo que tiver sido feito.

### Dentro de cada fase

- Migração antes de front. **Sempre.**
- Reversão escrita antes de aplicar bloco em produção.
- Teste antes do código, e visto falhar, onde houver teste.
- Aceite na tela antes de fechar a fase.

### O que roda em paralelo

- T002 e T003 são blocos de SQL diferentes no mesmo arquivo, e escrevem em
  paralelo. **Rodam em série no editor**, um por vez.
- T023 é bloco distinto de T022, na mesma migração.
- T031 e T032 são tabelas independentes entre si.
- T045 e T046 não se tocam.

**O que NÃO roda em paralelo, e é o erro tentador:** nada da F1 com nada da F2.
As duas mexem nas mesmas quatro tabelas financeiras, e a plataforma tem **um
Publish só**. Antes de tentar, ler `nx-paralelo`.

---

## Estratégia de entrega

### O que precisa estar de pé em 08/09

**Fase 0 e Fase 1, e é só.** São dez tarefas de aplicação mais quatro de aceite,
e é o recorte que a decisão de 04/09 fixou: financeiro e tarefas a 200%, o resto
entra como está.

1. F0 inteira. **Se a premissa 1 cair aqui, o resto do plano muda antes de custar
   trabalho.**
2. Portão 1, que é uma conversa e não uma implementação.
3. F1 inteira, com as três provas na tela.
4. **PARAR e validar.** Aceite do Arthur, e a validação pela ótica de quem usa.

### Depois de 08/09

F2 assim que o portão 2 abrir. F3, F4 e F5 quando o portão 3 abrir, e elas são
alvo da stack nova, então não disputam o Publish com correção de cliente.

---

## Notas

- `[P]` quer dizer arquivo diferente e sem dependência aberta.
- Commit por tarefa ou por grupo lógico, e a mensagem registra **o porquê**, que
  neste repositório é o que sobrevive.
- Mudança de comportamento **corrige a regra no mesmo commit**, alínea (l).
- Parar em qualquer ponto de conferência é legítimo. Atravessar portão não é.
