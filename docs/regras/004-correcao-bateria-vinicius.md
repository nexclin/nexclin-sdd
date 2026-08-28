# 004 · Correção da 1ª bateria de testes (Vinícius, 18–19/08)

> **Regra viva.** Nasceu antes da execução, guiou a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 27/08/2026:** trava com **20 de 23 fechados**, nove commits na
> `main` da plataforma, todos publicados. **Três abertos**, e dois deles dependem
> só de atos do Arthur. Alvo: a plataforma Lovable, via ponte inversa.
>
> **Lei:** `docs/constituicao.md` · **Critério:** `CLAUDE.md` §2.5 ·
> **Fonte dos itens:** `../historico/2026-08-20-triagem-baterias-vinicius.md` (V-01 a
> V-33, D-1 a D-13) · **Narrativa da execução:**
> [`../historico/2026-08-23-execucao-bateria-vinicius.md`](../historico/2026-08-23-execucao-bateria-vinicius.md) ·
> **Procedimento:** `docs/ponte/ponte-inversa.md`, skill `nx-ponte` ·
> **Origem:** convertida da SPEC 004 em 27/08/2026, formato de sete seções.

---

## 1. O problema

A primeira bateria de testes do Vinícius produziu 33 apontamentos numa
plataforma que abre para clientes fundadores em 08/09. Triados, eles não são um
lote homogêneo: alguns mudam o que fica **gravado** no banco, e esses migram
para a stack nova em outubro junto com o dado; outros mudam só como a tela soma
o que já está certo, e morrem com o front que será reescrito. O risco real não é
o bug feio, é o número errado que fica gravado: a estimativa é de R$ 100 a 200
mil de faturamento lançado por clínica no mês da Lovable, e esse lançamento é
importado, não descartado.

## 2. Requisitos

O critério que decide o escopo é a §2.5 do `CLAUDE.md`, com a régua fina de
20/08. Não reabrir.

| Faixa | Pergunta | Ação |
|---|---|---|
| **A** | Muda o que é **persistido**: valor, data, atribuição, a qual conta pertence? | **Corrigir.** O erro migra |
| **B** | Muda só **como a tela soma ou exibe** dado já gravado certo? | Regra escrita basta |
| **C** | Front, layout, mensagem? | Não corrigir, salvo se impedir o fundador de operar |

- **FR-001**: Relatório é **exceção nomeada da faixa C** e **MUST** funcionar em
  08/09. *Porquê:* o time do Vinícius não usa o dashboard. Puxa as bases pelos
  relatórios, toda semana, e decide em cima delas. Relatório errado vira decisão
  errada e perda para a clínica. É o caso literal de impedir o fundador de usar o
  que foi prometido. Decisão D-8.
- **FR-002**: Dashboard **MUST** ser rebaixado a regra escrita, sem
  implementação na plataforma. *Porquê:* nas palavras do próprio Vinícius, é
  "visão simples pro médico". Cálculo de tela sobre dado gravado certo não
  atravessa. Itens V-13 e V-21, decisão D-9.
- **FR-003**: O vencimento do recebível **MUST** seguir o meio de pagamento.
  *Porquê:* faixa A pura. Boleto e dinheiro têm prazos diferentes, e o vencimento
  gravado errado desloca o fluxo de caixa inteiro. Itens V-22 e V-23, fechado em
  `7eff4cf`.
- **FR-004**: Data pura **MUST NOT** passar por UTC, e data-e-hora **MUST**
  carregar o fuso na gravação. *Porquê:* os dois erros existiram em produção e
  deslocavam o dado em um dia e em três horas. Itens V-17 e V-28B, fechado em
  `2e390ff`. Virou dado constitucional.
- **FR-005**: A entrada do paciente **MUST** abater a consulta, e não a
  prescrição. *Porquê:* muda **atribuição gravada**, não exibição. Itens V-18 e
  V-20, faixa A.
- **FR-006**: A despesa fixa **MUST NOT** pular o mês corrente. *Porquê:* despesa
  que não nasce no mês em que existe some do resultado daquele mês, e o resultado
  é importado. Item V-26, fechado em `88df535`.
- **FR-007**: Falha na criação de acesso **MUST NOT** deixar linha órfã em
  `team_members`. *Porquê:* linha órfã conta para o limite de usuários do plano e
  bloqueia um acesso legítimo. Item V-04B, fechado em `1dbf842`.
- **FR-008**: A taxa de maquininha **MUST** entrar como despesa **só com as três
  partes juntas**: Contas a Receber, Fluxo de Caixa e DRE/DFC. *Porquê:* hoje o
  recebível grava `net_value`, já líquido. Criar a despesa por cima disso
  desconta a taxa **duas vezes** e corrompe o resultado. Decisão D-13, isolada de
  propósito, e não entra sem decisão de backfill tomada.

## 3. O que muda no banco

Esta regra corrige comportamento em produção, e a maior parte das correções é de
aplicação. O que toca o banco:

| Item | Mudança |
|---|---|
| V-22, V-23 | cálculo do vencimento do recebível a partir do prazo do meio de pagamento |
| V-17, V-28B | gravação de data em fuso local, nunca UTC |
| V-18, V-20 | atribuição do pagamento: a entrada abate a consulta |
| V-26 | geração da despesa fixa inclui o mês corrente |
| D-13 | taxa de maquininha como despesa, **não aplicada**, com o SQL preparado em `d13-taxa-como-despesa.sql` |

Tudo isso atravessa para outubro dentro do próprio dado, não do código.

## 4. Premissas

**As três armadilhas da ponte, que custaram tempo real em 20/08:**

1. **O Publish publica o PREVIEW, não o commit.** Ao ler "Preview is out of
   date", clicar **Update preview**, esperar terminar (cerca de 11 minutos), e só
   publicar ao ler **"Previewing"**.
2. **O Publish NÃO redeploya edge function.** Correção que toca front e function
   exige a **function primeiro**. Publicar o front antes deixou o convite
   quebrado por alguns minutos.
3. **`conferir` não é formalidade.** Duas vezes em 20/08 o painel afirmou sucesso
   sem ter publicado.

Menores, e igualmente reais: "Build unsuccessful" no editor é **falso**, aparece
em todo commit vindo do GitHub. E `Consultas.tsx` é **página órfã**: o menu
"Consultas" aponta para `/acompanhamento`, então conferir o roteamento antes de
corrigir um arquivo.

**Gate de tipos:** `npx tsc -p tsconfig.app.json` limpo antes de qualquer envio.
`npm run build` **não checa tipos**, porque Vite usa esbuild. Foi o que derrubou
o app por 1h35 em 20/08.

**A ressalva que vale mais que o placar:** nada foi provado na tela pelo
executor. A política de rede do ambiente bloqueia `nexclin.lovable.app`. Todo
`[x]` desta regra significa **código enviado**, não **comportamento provado**.

## 5. Dependências

- **Clone da plataforma atualizado:** `bash scripts/ponte.sh preparar`.
- **Export do banco** antes de qualquer escrita em produção. Não há PITR neste
  tier.
- **O Publish é do Arthur.** Não existe CLI para publicar na Lovable, e esse gate
  não existe em nenhuma outra regra.
- **A regra 002** compartilha a janela e o tipo de risco. O T017 dela, que
  removeu o caminho de senha de terceiro, foi publicado em 20/08 pela mesma
  ponte.

## 6. Como se prova que funciona

Executado por Arthur na plataforma ao vivo. Item sem prova na tela fecha como
*"código lido, não comportamento provado"* e permanece aberto.

1. Relatório de Contas a Pagar e DRE/DFC trazem os lançamentos do período.
2. Produtividade mostra **valor orçado** e **valor fechado** em colunas
   distintas, e a conversão bate com o caso do Vinícius: 1.800 orçado, 1.600
   fechado.
3. Relatório de Vendas traz **uma linha por item aprovado** do orçamento, com
   médico prescritor e responsável pela venda.
4. Datas personalizadas filtram o relatório de Contas a Receber.
5. Consulta avulsa gera as tarefas automáticas, atribuídas ao **responsável pela
   venda**.
6. Tela financeira pós-consulta soma **consulta mais prescrição**, e a entrada
   abate a **consulta**.
7. Hora da consulta exibida é a hora digitada.
8. Nenhuma linha órfã em `team_members` após falha de criação de acesso.

**Rastro por item:** commit na plataforma, bundle publicado, linha de aceite, e
apontamento marcado no Notion.

## 7. A decisão que falta

**Três itens abertos, e dois deles esperam o Arthur.**

1. **V-24, plano de contas não carrega.** É o único item da trava que impede uma
   rotina inteira: sem plano de contas, o lançamento de despesa avulsa não salva.
   O diagnóstico por leitura já está feito, `chart-account-select.tsx:49` filtra
   `analyticalOnly` por `level === 3`, e sem conta de nível 3 ativa o combobox vem
   vazio. **Bloqueado numa consulta de 30 segundos**, pedida em 20/08 e repetida
   em 23/08:

   ```sql
   select level, count(*), bool_or(active) as tem_ativo
   from chart_of_accounts
   where clinic_id = '<id da clínica>'
   group by level order by level;
   ```

   Sem linha `level = 3`, a correção é SQL: o seed do plano de contas não rodou
   para essa clínica. Com linhas de nível 3, é bug de query no diálogo, e o
   executor corrige.

2. **V-21, bloco de indicadores do dashboard, 5 de 6.** Faltam duas facetas, e as
   duas dependem de olhar a tela com dado real: o ticket por orçamento (que
   parecia errado porque a consulta valia zero) e o gráfico de fluxo de caixa
   (não reproduzido, já lê de `receivables`). A regra é não corrigir antes de
   reproduzir. Chutar aqui produz correção que conserta o que não estava
   quebrado.

3. **V-04, convite de equipe.** A function foi reescrita e está em produção desde
   20/08, mas **a causa original nunca foi diagnosticada**: o caminho que falhava
   foi substituído por inteiro, então não há como afirmar que a falha não volta
   por outro motivo. É o item mais barato da trava, oito passos e zero crédito, e
   é o único que prova o T017.

**Fora de escopo por decisão, e não é adiamento:** V-05, V-07, V-08, V-09, V-30 e
V-31 viram **requisito das regras de módulo da stack nova** pela D-7, não item de
lista. O redesenho do financeiro em dois blocos com pagamento independente e o
LTV por paciente seguem o mesmo caminho.
