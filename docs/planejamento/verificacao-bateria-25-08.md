# Verificação item a item da bateria de 25/08

> Conferido **no código**, item por item, em 25/08/2026. Não é o que eu acho
> que fiz: é o que o `grep` mostra. Onde eu tinha afirmado algo sem verificar,
> está corrigido aqui e a correção está marcada.
>
> **Atualizado no fim do dia.** A primeira versão fechava em 14 corrigidos, 4
> pela metade, 8 não tratados. O Arthur mandou fechar os 8, e eles foram
> fechados. **Os 23 itens estão corrigidos no código.** O histórico da primeira
> contagem fica preservado nas notas de cada linha, porque saber o que ficou
> para trás e por quanto tempo é o que ensina a triar melhor da próxima vez.

---

## Duas coisas que valem antes da tabela

### 1. Nada disto está no ar

Os tres commits (`ae2b37d`, `a356057` e `5a229f1`) estao em `nexclin/nexclin`, branch
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
| 1 | Senha fraca sem dizer a regra | ✅ | `src/lib/regraDeSenha.ts` mais o campo que mostra a lista **antes** de digitar. A tela dizia "mínimo 6" e o servidor recusava por outro motivo: a tela mentia. Piso = `NGS1.02.03` da SBIS, mais maiúscula, minúscula e especial. **Era o único item que não entrou em nenhuma onda da triagem.** |
| 2 | "Sem permissão para convidar na equipe" | 🔒 | Causa achada: a clínica nasce sem `account_subscriptions`, `my_permission` devolve `none` para o próprio dono e a edge function responde 403. Migração escrita (`20260825080000`), **não aplicada**. Enquanto não aplicar, o erro continua igual. |
| 3 | Data e hora só por clique | ✅ | Os dois componentes trocaram o gatilho por input com máscara. O calendário continua inteiro, só deixou de ser o único caminho. **20 telas ganham, nenhuma foi tocada.** O parser foi provado em 12 casos: `31/02` recusado, `29/02` aceito só em ano bissexto. |
| 4a | Anamnese fora de ordem | ✅ | `src/lib/respostasOrdenadas.ts`. A leitura passa a percorrer o formulário, e não o objeto salvo. **Causa real:** `jsonb` não preserva ordem de chave. |
| 4b | Ficha do paciente não mostra as respostas | ✅ | A consulta em `Pacientes.tsx` passou a buscar `responses`, e o bloco virou componente compartilhado. |
| 5 | Dashboard "0 novos agendamentos" | ✅ | Passa a usar `leadsAgendouCount`, a mesma base da conversão. |
| 6 | Selecionar paciente sem busca | ✅ | Busca dentro de `PatientSelectWithAdd`. As 4 telas que usam o seletor ganham. |
| 7a | Motivo do cancelamento se perde | ✅ | Nunca se perdeu no banco. `Tarefas.tsx` passou a renderizar `description`. |
| 7b | Recaptação sem distinguir origem | ✅ | Subtipos por origem, **sem migração**: `tasks.type` é `TEXT` sem `CHECK`. E a deduplicação passou a ser **por subtipo**, o que conserta a armadilha pior: se o paciente já viera de recaptação de lead, o cancelamento **não gerava tarefa nenhuma**. |
| 8a | Prescrição lista serviços inativos | ✅ | Trocado de `services` para `servicosAtivos`. |
| 8b | Não deixa adicionar consultas | ✅ | Liberado **depois** de tornar seguro: o hook parou de **descartar** e passou a **atribuir** — consulta prescrita soma em Consultas, o resto em Vendas. Na ordem inversa, teria feito a receita sumir. |
| 9 | Taxa com incontáveis decimais | ✅ | Arredondada **na origem** (`paymentFees.ts`), `net_value` fechado em centavos, exibição formatada. |
| 10 | Antecipado aparecendo parcelado | ✅ | `termDays` deixou de ser descartado. Antecipado vence em hoje + prazo. |
| 11 | Total faturado em consultas errado | ✅ | **A causa real não era o `abateEntrada`**, que já estava correto desde a D-3. Eram **duas rotas gravando recebível sem `macro_category`**, e uma se chama literalmente `"Orçamento aprovado - Consulta"`. Linha sem macro cai em vendas **por ausência**. Explica o relato exato: a entrada tinha macro e contava certo, o resto não tinha nada. |
| 12 | 13 consultas pagas para 2 realizadas | ✅ | `chaveDaVenda.ts`, extraída do relatório que já acertava. **A parcela continua sendo uma linha no contas a receber**, e isso é correto; o que mudou é o dashboard contar venda em vez de linha. |
| 13 | Sem top macro, top profissionais e ticket médio | ✅ | Âncora alternativa nos recebíveis pagos quando a cadeia de `closings` não produz nada, **e** o hook passou a dizer de onde o número veio. As telas vazias agora distinguem "nenhum fechamento" de "fechamentos sem atendimento vinculado" — dois problemas que apareciam com o mesmo vazio. |
| 14a | Tarefa não mostra observações | ✅ | `description` passou a ser renderizada. |
| 14b | Tarefa não edita, não associa paciente | ✅ | Editar, associar paciente e clicar para ler observações. **Sem migração**: `patient_id` sempre existiu, faltava o campo no formulário. Só a metade "pelo criador ou pelo master" depende de `created_by`, e a migração está escrita. A derivação atual erra para **permitir** editar, que é o lado certo. |
| 15 | Dia da conta fixa não deixa digitar | ✅ | O estado aceita texto enquanto se digita e valida no blur. E o `max` virou **31**, não 30. |
| 16 | Fluxo de caixa só olha vencimento | ✅ | `src/lib/dataDeCaixa.ts` com a regra dele, e a consulta passou a alcançar o que foi **pago** no período mesmo vencendo fora. Simulei os 6 casos, incluindo a conta de luz que vence 28 e foi paga 25. |
| 17a | Dashboard sem gráfico de fluxo de caixa | ✅ | `.nx-root svg { width:16px }` vencia por especificidade e desenhava o gráfico com 16 pixels. Exceção declarada por classe. |
| 17b | Saldo final não bate com nenhum lançamento | ✅ | As duas telas passaram a usar `dataDeCaixa` **e** `valorDeCaixa`. A decisão que faltava está tomada: fluxo de **caixa** é o **líquido**, porque é o que entra na conta. Reversível trocando a ordem de um `??`. |
| 18a | Vendas: centavos a mais e a menos | ✅ | `dividirEmParcelas` em centavos inteiros. Aritmética simulada: R$ 500 em 12× soma exatamente 500,00. **Só para venda nova.** |
| 18b | Vendas: data lançada um dia antes | ✅ | Os dois pontos: exibição e gravação. |
| 19a | Contas a pagar: datas um dia a menos | ✅ | Mesma correção de exibição. Vale **inclusive para o dado antigo**. |
| 19b | Faltam competência e forma de pagamento | ✅ | As duas colunas já existiam na tabela e não eram declaradas. |
| 20a | Contas a receber: valores esquisitos | 🟡 | Melhora sozinho para lançamento novo (FIN-1 e FIN-3). O dado já gravado continua estranho. |
| 20b | Só entra a entrada paga | ✅ | **Não era dado faltando, era o recorte invisível.** O seletor existia sem rótulo. Ganhou rótulo e um aviso que explica que uma venda parcelada só mostra as parcelas do período. |
| 21 | DRE/DFC errado por herança | 🟡 | Sem ação própria, por decisão. Melhora conforme as origens são corrigidas, e **só para dado novo**. |
| 22 | Repasse completamente zerado | ✅ | Lia `revenues`, que ninguém escreve. Repontado para `receivables`, recorte por pagamento, e o profissional agora sai do atendimento. **O imposto continua zero**, e agora está escrito por quê: não existe tabela de configuração fiscal. |
| 23 | Novo relatório de produtividade de atividades | ✅ | `RelatorioAtividades.tsx`, com os quatro status derivados. **Nenhuma coluna nova.** A taxa "no prazo" conta só o que foi concluído, porque atividade pendente não cumpriu nem descumpriu prazo. |

**Contagem final: 23 corrigidos no código. 1 depende de migração para o efeito
aparecer (o item 2, "sem permissão para convidar").**

Os 🟡 que restam na coluna são os que melhoram sozinhos com as origens
corrigidas, e **só para dado novo** — ver o aviso no topo.

---

## O item 17b: o erro, e a decisão que ele exigia

Eu afirmei no commit e no handoff que o DASH-3 "sai junto com FIN-4". Conferi e
**não saía**: `Dashboard.tsx` não importava `dataDeCaixa`.

As duas telas divergiam em quatro pontos, e **três eram bug; um era decisão**:

| | Dashboard (antes) | Página Fluxo de Caixa (antes) |
|---|---|---|
| Quais lançamentos | só recebíveis pagos | todos os recebíveis |
| Qual data | `paid_at \|\| due_date` | regra completa |
| **Qual valor** | `gross_value` | `value` |
| Saldo de abertura | sim | não |

**A decisão, tomada e registrada: fluxo de caixa é o LÍQUIDO.**

A razão está no nome da tela. Fluxo de *caixa* é o dinheiro que entra na conta.
Uma venda de R$ 1.000 no cartão com 3% de taxa põe **R$ 970** no banco; os R$ 30
nunca chegam. Projetar caixa com o bruto mostra um saldo que o banco não tem — e
é sobre esse saldo que o dono decide se paga o fornecedor.

O faturamento **bruto** continua existindo e continua certo nos KPIs de
Faturamento, que o próprio Vinícius validou. São perguntas diferentes: *quanto
eu vendi* e *quanto entrou na conta*.

**Reversível em uma linha:** a ordem do `??` em `valorDeCaixa`. As duas telas
chamam a mesma função, então nada mais muda.

## O que fazer, em ordem de retorno

1. **Publicar.** Três commits (`ae2b37d`, `a356057`, `5a229f1`). Sem isso, nada
   acima existe para o Vinícius.
2. **Aplicar as migrações.** `20260825080000` destrava o "sem permissão para
   convidar", que é o único item ainda sem efeito. `20260825090000` fecha a
   metade de "editável pelo criador ou pelo master".
3. **Decidir sobre o dado já gravado.** Se o reteste for sobre a base atual, ele
   vai reencontrar os centavos e as datas antigas. Ou lança tudo de novo, ou
   precisamos de uma migração de correção de dado — que não foi escrita.
4. **Conferir primeiro o que ele elogiou.** FIN-5, FIN-6 e ORC-1 tocaram o
   caminho da entrada da consulta indo para o caixa, que ele validou como
   correto. É o primeiro lugar a olhar depois de publicar.
