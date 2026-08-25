# Verificação item a item da bateria de 25/08

> Conferido **no código**, item por item, em 25/08/2026. Não é o que eu acho
> que fiz: é o que o `grep` mostra. Onde eu tinha afirmado algo sem verificar,
> está corrigido aqui e a correção está marcada.

---

## Duas coisas que valem antes da tabela

### 1. Nada disto está no ar

Os dois commits (`ae2b37d` e `a356057`) estão em `nexclin/nexclin`, branch
`main`. **Falta o Publish**, que exige navegador logado. Enquanto isso não
acontecer, o Vinícius reteste e vê exatamente o que viu antes.

### 2. As correções valem para o dado NOVO, não para o que já está gravado

Esta é a mais importante, e ela não estava escrita em lugar nenhum.

**O "500,02" que ele viu continua 500,02 no banco.** A correção do FIN-1 impede
que a próxima venda nasça errada; ela não reescreve as parcelas que já foram
gravadas. O mesmo vale para:

| Correção | O que ela conserta | O que ela **não** conserta |
|---|---|---|
| FIN-1 centavos | venda nova | as parcelas já gravadas com resíduo |
| FIN-3 taxa | recebível novo | o `fee_percent` e o `net_value` com ruído já gravados |
| FIN-2 **gravação** | vencimento novo | os `due_date` gravados um dia atrás |
| FIN-5 antecipado | recebimento novo | as parcelas antecipadas já espalhadas por meses |
| FIN-6 macro do avulso | lançamento novo | os recebíveis avulsos sem `macro_category` |

**FIN-2 na exibição é a exceção, e é a boa notícia:** corrigir o `fmtDate`
conserta **os cinco relatórios de uma vez, inclusive para o dado antigo**,
porque ali o problema era de leitura e não de gravação.

**Consequência prática:** se o Vinícius retestar sobre a base atual, ele vai ver
centavos errados nas vendas antigas e datas antigas erradas em contas a pagar.
Para o reteste ser limpo, ou ele lança tudo de novo, ou é preciso uma migração
de correção de dado — que é trabalho próprio, é faixa A, e **não foi feita**.

---

## Pontos positivos que ele confirmou

Nada foi mexido em nenhum deles, e vale checar que continuam de pé depois do
Publish: cadastro de paciente com campos completos, aviso de conflito de
horário, fechamento total e parcial com a entrada indo para o caixa e para o
desconto, faturamento bruto e líquido, relatório de leads, relatório de
produtividade por profissional.

**Um risco a conferir no reteste:** o FIN-6 mexeu no lançamento avulso de
consulta, e o FIN-5 mexeu na geração de parcelas. Os dois tocam o caminho que
ele elogiou ("a entrada da consulta está entrando certinha"). É o primeiro lugar
a olhar depois de publicar.

---

## A tabela

**Legenda:** ✅ corrigido no código · 🟡 corrigido pela metade · ⛔ não
corrigido · 🔒 depende de migração não aplicada

| # | O que ele relatou | Estado | Evidência e o que falta |
|---|---|---|---|
| 1 | Senha fraca sem dizer a regra | ⛔ | **Não tratado.** `grep` por "maiúscula", "caractere especial" e "mínimo 8" nas telas não devolve nada. É o único item da lista que não entrou em nenhuma onda da triagem. |
| 2 | "Sem permissão para convidar na equipe" | 🔒 | Causa achada: a clínica nasce sem `account_subscriptions`, `my_permission` devolve `none` para o próprio dono e a edge function responde 403. Migração escrita (`20260825080000`), **não aplicada**. Enquanto não aplicar, o erro continua igual. |
| 3 | Data e hora só por clique | ⛔ | **Não tratado.** O gatilho de `nx-datetime-field.tsx` continua sendo um `<Button>`, sem superfície onde digitar. |
| 4a | Anamnese fora de ordem | ✅ | `src/lib/respostasOrdenadas.ts`. A leitura passa a percorrer o formulário, e não o objeto salvo. **Causa real:** `jsonb` não preserva ordem de chave. |
| 4b | Ficha do paciente não mostra as respostas | ✅ | A consulta em `Pacientes.tsx` passou a buscar `responses`, e o bloco virou componente compartilhado. |
| 5 | Dashboard "0 novos agendamentos" | ✅ | Passa a usar `leadsAgendouCount`, a mesma base da conversão. |
| 6 | Selecionar paciente sem busca | ✅ | Busca dentro de `PatientSelectWithAdd`. As 4 telas que usam o seletor ganham. |
| 7a | Motivo do cancelamento se perde | ✅ | Nunca se perdeu no banco. `Tarefas.tsx` passou a renderizar `description`. |
| 7b | Recaptação sem distinguir origem | ⛔ | **Não tratado.** `type: "recaptacao"` continua sendo o mesmo valor para lead, consulta cancelada e orçamento. Precisa de subtipo ou da coluna `origem`, que é mudança de banco. |
| 8a | Prescrição lista serviços inativos | ✅ | Trocado de `services` para `servicosAtivos`. |
| 8b | Não deixa adicionar consultas | ⛔ **de propósito** | `useFinancialBreakdown` faz `if (isConsulta) continue` e descarta item de consulta do orçamento **das vendas e do prescrito**. Habilitar hoje faria a receita **sumir** do dashboard. Devolvido para decisão. |
| 9 | Taxa com incontáveis decimais | ✅ | Arredondada **na origem** (`paymentFees.ts`), `net_value` fechado em centavos, exibição formatada. |
| 10 | Antecipado aparecendo parcelado | ✅ | `termDays` deixou de ser descartado. Antecipado vence em hoje + prazo. |
| 11 | Total faturado em consultas errado | 🟡 | Só a metade fácil: o lançamento avulso passou a gravar `macro_category`. **A causa principal continua**: `abateEntrada` abate a entrada da linha da consulta, e o dashboard classifica pela categoria do valor residual. Separar abatimento de atribuição é mudança de regra. |
| 12 | 13 consultas pagas para 2 realizadas | ✅ | `chaveDaVenda.ts`, extraída do relatório que já acertava. **A parcela continua sendo uma linha no contas a receber**, e isso é correto; o que mudou é o dashboard contar venda em vez de linha. |
| 13 | Sem top macro, top profissionais e ticket médio | ⛔ | **Não tratado, e é o único que exige investigar antes.** Os três painéis existem e caem em "Sem dados no período". Dependem de `useFinancialBreakdown`, que zera se não houver `closings` com `closed_at` no período. As três consultas que dizem qual elo quebrou estão na triagem. |
| 14a | Tarefa não mostra observações | ✅ | `description` passou a ser renderizada. |
| 14b | Tarefa não edita, não associa paciente | ⛔ | **Não tratado.** A regra "editável pelo criador ou pelo master" não tem como existir: `tasks` não tem `created_by` nem marca de origem. É mudança de banco. |
| 15 | Dia da conta fixa não deixa digitar | ✅ | O estado aceita texto enquanto se digita e valida no blur. E o `max` virou **31**, não 30. |
| 16 | Fluxo de caixa só olha vencimento | ✅ | `src/lib/dataDeCaixa.ts` com a regra dele, e a consulta passou a alcançar o que foi **pago** no período mesmo vencendo fora. Simulei os 6 casos, incluindo a conta de luz que vence 28 e foi paga 25. |
| 17a | Dashboard sem gráfico de fluxo de caixa | ✅ | `.nx-root svg { width:16px }` vencia por especificidade e desenhava o gráfico com 16 pixels. Exceção declarada por classe. |
| 17b | Saldo final não bate com nenhum lançamento | ⛔ **correção de afirmação minha** | Eu escrevi que "sai junto com FIN-4". **Não saiu.** Conferido: `Dashboard.tsx` não usa `dataDeCaixa` e continua com o cálculo próprio. Detalhe abaixo. |
| 18a | Vendas: centavos a mais e a menos | ✅ | `dividirEmParcelas` em centavos inteiros. Aritmética simulada: R$ 500 em 12× soma exatamente 500,00. **Só para venda nova.** |
| 18b | Vendas: data lançada um dia antes | ✅ | Os dois pontos: exibição e gravação. |
| 19a | Contas a pagar: datas um dia a menos | ✅ | Mesma correção de exibição. Vale **inclusive para o dado antigo**. |
| 19b | Faltam competência e forma de pagamento | ✅ | As duas colunas já existiam na tabela e não eram declaradas. |
| 20a | Contas a receber: valores esquisitos | 🟡 | Melhora sozinho para lançamento novo (FIN-1 e FIN-3). O dado já gravado continua estranho. |
| 20b | Só entra a entrada paga | ⛔ | **Não tratado.** O relatório já tem alternância entre vencimento e recebimento (`dateField`), e o padrão é vencimento — as parcelas 2 a 12 vencem nos meses seguintes e ficam fora do recorte. Falta deixar isso explícito na tela. |
| 21 | DRE/DFC errado por herança | 🟡 | Sem ação própria, por decisão. Melhora conforme as origens são corrigidas, e **só para dado novo**. |
| 22 | Repasse completamente zerado | ✅ | Lia `revenues`, que ninguém escreve. Repontado para `receivables`, recorte por pagamento, e o profissional agora sai do atendimento. **O imposto continua zero**, e agora está escrito por quê: não existe tabela de configuração fiscal. |
| 23 | Novo relatório de produtividade de atividades | ⛔ | **Não feito.** A triagem confirma que sai quase inteiro do que já existe em `tasks`; só a coluna "criada por" depende do `created_by`. |

**Contagem: 14 corrigidos, 4 pela metade, 8 não tratados, 1 dependendo de migração.**

---

## O item 17b, em detalhe, porque foi erro meu

Eu afirmei no commit e no handoff que o DASH-3 "sai junto com FIN-4". Conferi
agora e **não sai**. `Dashboard.tsx` não importa `dataDeCaixa` e mantém o
cálculo próprio.

As duas telas continuam calculando coisas diferentes:

| | Dashboard | Página Fluxo de Caixa |
|---|---|---|
| Quais lançamentos | só recebíveis **pagos** | **todos** os recebíveis |
| Qual data | `paid_at || due_date` | `dataDeCaixa()` (com a regra do vencido → hoje) |
| Qual valor | `gross_value` | `value` |
| Saldo de abertura | **sim**, das contas bancárias | não |

**Por que eu não corrigi de uma vez:** a terceira linha é uma **decisão de
regra**, não um bug. A triagem já apontava: *"a página soma `value` (bruto), o
dashboard soma `gross_value`, e nenhum dos dois usa `net_value`. Três
definições de entrada no mesmo produto."*

Num fluxo de **caixa**, o que entra na conta é o **líquido**, depois da taxa da
maquininha. Mudar para líquido muda todos os números da tela, e pela regra da
ponte isso deixa de ser bug e vira decisão.

**A pergunta que precisa de resposta, e é de uma linha:** o fluxo de caixa
mostra o que foi faturado (bruto) ou o que entra na conta (líquido)?

Com a resposta, as duas telas passam a usar `dataDeCaixa` e o mesmo conceito de
entrada, e o item fecha.

---

## O que fazer, em ordem de retorno

1. **Publicar.** Sem isso, nada acima existe para o Vinícius.
2. **Aplicar a migração do EQP-1.** É o único item da lista que **bloqueia o
   uso**, e o único 🔒.
3. **Responder a pergunta do 17b** (bruto ou líquido). Uma linha, e fecha um
   ⛔.
4. **Decidir sobre o dado já gravado.** Se o reteste for sobre a base atual, ele
   vai reencontrar os centavos e as datas. Ou lança tudo de novo, ou precisamos
   de uma migração de correção de dado.
5. **Rodar as três consultas do DASH-4.** É o único item que a triagem manda
   investigar antes de corrigir.
