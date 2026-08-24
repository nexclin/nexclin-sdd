# Tasks: SPEC 004 — Correção da 1ª bateria (Vinícius)

**Alvo**: `nexclin/nexclin@main` · **Corte**: 23/08/2026, fim do dia
**Fonte dos itens**: `docs/planejamento/triagem-baterias-18-19.md` (V-01…V-32)
**Auditoria que sustenta os estados**: `docs/planejamento/auditoria-33-itens-23-08.md`
**Como cada causa foi encontrada**: `historico-execucao.md`

> **Este é um documento de ESTADO, não de histórico.** Cada linha diz onde o
> item está agora e o que falta para fechá-lo. A narrativa da investigação
> mudou-se para `historico-execucao.md`.

## Legenda

| Marca | Significado |
|---|---|
| `[x]` | Corrigido **e** enviado à `main` da plataforma |
| `[~]` | Parcial — parte fechou, parte não |
| `[ ]` | Aberto |
| `[-]` | Fora de escopo **por decisão**, não por esquecimento |
| **prova** | O que precisa acontecer para o item fechar de verdade |

> **Nenhum item foi provado na tela por mim.** A política de rede deste ambiente
> bloqueia `nexclin.lovable.app` (`ERR_TUNNEL_CONNECTION_FAILED` no proxy).
> Tudo marcado `[x]` significa **"código enviado"**, não **"comportamento
> provado"** — Princípio IV da constituição. O roteiro de prova está em
> `docs/planejamento/roteiro-verificacao-23-08.md`.

---

## Placar

| | |
|---|---|
| Apontamentos da bateria | 33 |
| Bugs | 25 · Backlog 8 |
| **Trava (23, após a D-2)** | **20 fechados · 3 abertos** (V-24 e V-04 dependem só de atos do Arthur) |
| Achados novos, fora da bateria | 4 — todos corrigidos |
| Melhorias de interface pedidas pelo Arthur | 6 — todas enviadas |
| Fora de escopo por decisão | 8 |

---

## BLOCO 1 — Trava, fechados (20)

Todos enviados. Falta o aceite manual.

- [x] **V-01** Scroll da lista de especialidades · `a239dec`
      `SelectContent` sem teto ligado à altura da janela — o Radix não ativava a
      rolagem. Corrigido no componente compartilhado: vale para todos os selects.
- [x] **V-04B** Linha órfã em `team_members` · `1dbf842`
      A linha nascia antes do convite e ficava quando ele falhava. Agora é
      desfeita na falha.
- [x] **V-10** Agenda aceitava choque de horário · `a239dec`
      Avisa com o nome de quem já está marcado e oferece "Confirmar encaixe".
      **Não bloqueia** (D-4).
- [x] **V-11** Consulta avulsa sem responsável · `1dbf842`
      "Responsável pela Venda" saiu do bloco de fechamento e virou campo do
      formulário principal, obrigatório no submit (D-2).
- [x] **V-12** Consulta avulsa não gerava tarefas · `1dbf842`
      `createAppointmentTasks` só era chamada pelo wizard do CRM.
- [x] **V-13** Contagem de novos pacientes · `799c82d`
      A contagem de 1ª vez saía de todas as consultas, inclusive canceladas, ao
      lado de um card que contava só as realizadas.
- [x] **V-14** Adiantamento contado como venda · `63f87a4`
      Nascia sem `macro_category`; todo lugar que classifica por essa coluna o
      jogava em vendas. **Faixa A** — a classificação fica gravada.
- [x] **V-15 + V-16** Recaptação e remarcação iam para o médico · `1dbf842`
      Fallback `apt.responsible || apt.doctor`. A D-2 diz que ele não existe.
- [x] **V-17 + V-28B** Filtros zeravam os dados · `2e390ff`
      Datas convertidas para UTC. Depois das 21h locais, "hoje" já era amanhã.
- [x] **V-18** Valor a receber só trazia a prescrição · `be92a38`
      **Causa estrutural:** `appointments.consultation_type_id` não tem FK, a
      tela grava ali um `services.id`, e o cálculo procurava em
      `consultation_types`. O valor da consulta era **sempre zero**.
- [x] **V-20** Entrada descontada da prescrição · `be92a38`
      Era rateada por regra de três sobre todas as linhas. Agora abate a
      consulta primeiro (D-3). Regra isolada em `lib/abateEntrada.ts`.
- [x] **V-22 + V-23** Data do recebível por meio de pagamento · `7eff4cf`
      **Único item testado ao vivo** (20/08): Boleto → 23/08; Dinheiro → 20/08.
- [x] **V-25** Relatório de Vendas quebrado · `8ad3a15`
      Um recebível por item × parcela. Venda em 3× virava 3 linhas. Agora uma
      linha por item, com prescritor e responsável (D-10).
- [x] **V-26** Relatório de Contas a Pagar zerado · `88df535`
      Despesa fixa não materializada no mês corrente. O relatório em si estava
      correto — reconferido e **não alterado**.
- [x] **V-27** DRE/DFC zerado · `a239dec`
      Lia entradas de `revenues`, tabela que **nenhum caminho do app escreve**.
      Zero desde sempre, em qualquer período.
- [x] **V-28A** Datas personalizadas · `8ad3a15`
      Dois `<input type="date">` chamando `onChange` a cada tecla.
- [x] **V-29** Valor orçado errado · `8ad3a15`
      Filtrava `approval_status=aprovado` e exibia o fechado como orçado (D-12).
      No caso do Vinícius mostrava R$ 200 onde deveria mostrar R$ 1.400.
- [x] **V-32** Hora da consulta 3h adiantada · `1dbf842`
      Achado novo em 20/08, fora da bateria. `datetime-local` gravado sem fuso
      em coluna `timestamptz`.

## BLOCO 2 — Trava, ABERTOS (3)

### `[ ]` T101 · V-24 — Plano de contas não carrega · **BLOQUEADO**

**O único item da trava que impede uma rotina inteira**: sem plano de contas, o
lançamento de despesa avulsa não salva.

Diagnóstico já feito por leitura: `chart-account-select.tsx:49` filtra
`analyticalOnly → level === 3`. Sem conta de nível 3 ativa, o combobox vem vazio.

**Bloqueado em uma consulta de 30 segundos, pedida em 20/08 (A3) e repetida em
23/08.** Ela decide qual das duas correções fazer:

```sql
select level, count(*), bool_or(active) as tem_ativo
from chart_of_accounts
where clinic_id = '<id da clínica>'
group by level order by level;
```

| Resultado | Correção |
|---|---|
| Sem linha `level = 3` | **SQL** — o seed do plano de contas não rodou para essa clínica |
| Com linhas nível 3 | **Front** — aí é bug de query no diálogo, e eu corrijo |

**prova:** lançar uma despesa avulsa escolhendo uma conta e salvar.

### `[~]` T102 · V-21 — Bloco de indicadores do dashboard · **5 de 6**

| Faceta | Estado |
|---|---|
| 1. Total de consultas zerado | `[x]` `799c82d` — mesma causa raiz do V-18 |
| 2. Ticket por item, não por orçamento | `[ ]` o cálculo já é por orçamento fechado (D-9). Parecia errado porque a consulta valia zero. **Reconferir** |
| 3. Conversão em 100% com item reprovado | `[x]` `3287cf9` — era multiplicação dupla |
| 4. Quadro de ticket médio zerado | `[x]` deve cair junto com a faceta 1 |
| 5. Top macro-categorias e top médicos zerados | `[x]` `551bb12` — a descrição do item carregava o sufixo de desconto e quebrava a busca do serviço. Achado por leitura |
| 6. Gráfico do fluxo de caixa não aparece | `[ ]` **não reproduzido** — já lê de `receivables`, não da tabela vazia |

**Por que não corrigi as três:** dependem de olhar a tela com dado real, e a
regra é não corrigir antes de reproduzir. Chutar aqui produz correção que
conserta o que não estava quebrado.

**prova:** roteiro de verificação, testes 1 e 2.

### `[ ]` T103 · V-04 — Convite de equipe · **código pronto, não provado**

A edge function foi reescrita e está em produção desde 20/08 (`dabf1ef`, T017).
Mas **a causa original nunca foi diagnosticada** — o caminho que falhava foi
substituído por inteiro, então não há como afirmar que a falha não volta por
outro motivo.

É o item mais barato da trava: **8 passos, zero crédito**, e é o único que
prova o T017. Pedido em 20/08 (A4).

**prova:** roteiro de verificação, teste 6.

## BLOCO 3 — Fora da trava, fechados (2)

- [x] **V-19** Fechamento parcial exibido como total · `a239dec`
      O rótulo contava só itens. Aprovar 2 de 3 doses também é retirar algo.
- [x] **V-03** Login sem ver a senha · `a239dec`
      Classificado backlog pela regra, mas custava minutos e o Vinícius marcou
      "atrapalha muito". Foi junto.

## BLOCO 4 — Achados novos, fora da bateria (4)

Nenhum foi reportado por ninguém. Aparecem aqui porque **atravessam**.

- [x] **N-01 — Multiplicação dupla no financeiro** · `3287cf9`
      `appointment_items` guarda unidades diferentes no mesmo par de colunas:
      `prescribed_value` é **unitário**, `sold_value` é **total**. Três leitores
      multiplicavam `sold_value` por quantidade de novo — **e um deles fui eu**,
      no V-29. Com quantidade 2 o fator é exatamente 2×: fechado 3200 em vez de
      1600, conversão 177,8% em vez de 88,9%. Explica a "conversão em 100%".
- [x] **N-02 — `tasks.due_date` caía um dia antes** · `1dbf842`
      Coluna `timestamptz` recebendo data pura vira meia-noite UTC = 21:00 do
      dia anterior no Brasil. Três pontos corrigidos.
- [x] **N-03 — Tabela `revenues` sem escritor** · `a239dec`, `799c82d`
      Existe no schema; nada no app escreve. Zerava o DRE e o drill-down de
      receitas. `RelatorioRepasse` **continua lendo dela** — ver T204.
- [x] **N-04 — Preço de consulta some ao desativar o tipo** · `be92a38`
      A busca filtrava `active`, então desativar um tipo zerava a receita de
      todo atendimento passado que o usava.

## BLOCO 5 — Interface, pedidos do Arthur em 23/08 (6)

- [x] **I-01** Calendário da marca em toda data do app · `2948c7f`
      20 campos usavam o calendário **nativo do sistema**. Novo `NxDateField`,
      com janela de anos configurável — nascimento usa 100 anos, senão a troca
      pioraria o cadastro.
- [x] **I-02** Seleção do calendário saía preta · `63f87a4`
      Regra global `.nx-content button.bg-primary` pintava de navy, e em modo
      intervalo **todos** os dias recebem `selected`.
- [x] **I-03** Calendário empurrava o dashboard · `a7531e0`
      Era inline, no fluxo do documento. Virou popover.
- [x] **I-04** Cada clique refazia a consulta · `a7531e0`
      O intervalo virou rascunho, com "Aplicar período".
- [x] **I-05** Layout não encaixava entre resoluções · `a7531e0`
      `.nx-content` tinha `max-width` **sem `margin auto`**. Grids intrínsecos +
      tipografia fluida + breakpoints só para estrutura. Medido em 5 resoluções.
- [x] **I-06** Rolagem horizontal no celular · `a7531e0`
      Filho de grid sem `min-width: 0`, e cabeçalho que não quebrava linha.

## BLOCO 5B — Achados de 24/08, dos prints do Arthur (2) + desbloqueios (3)

- [x] **A-01** Campo "Data e Hora" ainda usava o seletor nativo · `2b90912`
      A troca anterior cobriu `type="date"`; ficaram cinco `datetime-local`, e um
      deles é o campo mais usado da tela mais usada. Novo `NxDateTimeField`,
      com `lang="pt-BR"` no campo de hora — `<input type="time">` segue o locale
      do **navegador**, e numa máquina em en-US mostraria "08:47 PM".
- [x] **A-02** "Erro ao excluir consulta" · `2b90912`
      `receivables.appointment_id` referencia `appointments(id)` **sem
      `ON DELETE`**. A correção é uma **regra**: recebível **pago** recusa a
      exclusão e diz o valor que trava; **pendentes** saem junto. Apagar
      recebimento pago destruiria um registro de caixa que aconteceu.
- [x] **N-05** Descrição com desconto quebrava a busca do serviço · `551bb12`
      Fecha **V-21.5**. Ver Bloco 2, T102.
- [x] **N-06** V-24 deixou de ser beco sem saída · `551bb12`
      A lista vazia distingue "sua busca não achou" de "não há o que achar".
      Não resolve a causa — resolve o abandono.
- [x] **N-07** Falha do convite passa a ser diagnosticável · `551bb12`
      `invErr.message` de edge function não-2xx é **sempre** a string genérica;
      o corpo era descartado. Era literalmente a frase que apareceu na tela do
      Vinícius.

## BLOCO 6 — Antes fora de escopo, AGORA NA FILA (D-15, 24/08)

A **D-15** reverteu a D-7 para estes itens: entram todos. O plano de execução,
com fases e ordem, está em `plan.md`.

- [ ] **V-02, V-06** — boas-vindas e mensagem de conclusão da anamnese.
      Cosméticos, sem dado nem regra atrás.
- [ ] **V-05** — especialidade não pré-carregada no template de anamnese.
- [ ] **V-07** — formulário público sem identidade visual da clínica.
- [ ] **V-08** — respostas de anamnese sem copiar / resumo por IA.
- [ ] **V-09** — ficha do paciente sem canal de entrada nem anamnese.
- [~] **V-30** — visão de agenda em calendário.
- [~] **V-31** — responsável configurável por tipo de atividade.

## BLOCO 7 — Adiado com data (D-13 + D-14)

- [ ] T201 [arthur] **Export do banco** antes de qualquer escrita.
- [ ] T202 [arthur] **Limpeza do transacional** — 27–30/08, no congelamento.
      Só transacional: consultas, orçamentos, recebíveis, despesas, tarefas,
      leads. **Configuração fica** — senão o fundador recebe um sistema em
      branco.
- [ ] T203 **D-13 — taxa de maquininha como despesa.** Trigger preparado em
      `specs/002-.../preparado/d13-taxa-como-despesa.sql`. **Não fatiar:** o
      recebível grava `net_value`, então criar a despesa por cima desconta a
      taxa duas vezes. Vão juntos: trigger + DRE somando bruto + uniformizar
      `receivables.value`.
- [ ] T204 **`RelatorioRepasse` ainda lê `revenues`** (N-03), logo vem zerado.
      **Deixado assim de propósito:** o repasse tem imposto fixado em zero e
      atribuição de profissional estimada. Fazer as entradas aparecerem sem
      resolver isso entrega número **plausível e errado** a médicos que conferem
      repasse — pior que um relatório visivelmente vazio.

## BLOCO 8 — Dívidas de MODELO · requisito da stack nova

Não são bugs de tela. São decisões de banco que a stack nova não pode repetir.

- [ ] D-M1 **`appointment_items` guarda unidades diferentes no mesmo par de
      colunas.** Violação do Princípio VIII. Consertar muda o que fica gravado e
      exige migração com backfill. Hoje os leitores estão alinhados e há nota em
      `Dashboard.tsx`.
- [ ] D-M2 **`appointments.consultation_type_id` sem FK, apontando para duas
      tabelas.** Causa raiz de V-18 e V-21.1. Na stack nova: um conceito, uma
      tabela, com FK.
- [ ] D-M3 **`revenues` existe e ninguém escreve.** Ou passa a ser alimentada,
      ou é removida. Coluna morta que alimenta relatório falha em silêncio.

## BLOCO 9 — Segurança e infraestrutura, pendentes com o Arthur

- [ ] S-01 **A-SEC — consulta de `storage.objects`.** Decide se há vazamento de
      dado de saúde. O pior caso não é RLS desligada: é bucket com
      `public = true`. Pedida em 20/08, **sem resposta**.
- [ ] S-02 **`.env` versionado em `nexclin/nexclin`.** Se contiver
      `service_role`, é vazamento crítico — a chave ignora RLS e **não sai do
      histórico com `rm`**: exige rotação. A regra de permissão do repositório
      bloqueou minha leitura e **eu não contornei**.
- [ ] S-03 **Região do projeto Supabase novo.** A região **não muda depois** —
      migrar é recriar. Se estiver fora do Brasil, descobrir agora, sem cliente.
- [ ] S-04 **Policies de storage não filtram por `bucket_id`.** Funciona hoje
      porque só existe o bucket de export; quebra em silêncio quando nascer o
      bucket de anexo de paciente.

---

## O caminho mais curto para zerar a trava

Dois atos, cerca de 20 minutos, derrubam **dois dos três** abertos:

1. Rodar a consulta do V-24 (T101) — 30 segundos.
2. Reteste do convite (T103) — 8 passos, sem crédito.

O terceiro (T102) fecha com os testes 1 e 2 do roteiro de verificação.
