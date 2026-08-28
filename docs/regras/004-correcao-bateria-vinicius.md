# 004 · Correção da 1ª bateria de testes (Vinícius, 18–19/08)

> **Regra viva.** Nasceu antes da execução, guiou a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 28/08/2026:** trava com **22 de 23 fechados**. Resta **um**, o
> V-24, e ele tem causa provada e conserto definido, esperando escrita em
> produção. Alvo: a plataforma Lovable, via ponte inversa.
>
> **A trava caiu de 3 para 1 em 28/08**, com o app finalmente acessível: o V-21
> foi reconferido na tela com base povoada e fechou, e o V-04 saiu por não
> existir. O detalhe de cada um está na seção 7.
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

**Uma, e é uma escrita em produção que precisa da sua mão.**

### V-24, o único aberto: causa provada em 28/08

A bifurcação que esta regra deixou em aberto (*"sem linha `level = 3` é SQL; com
linhas de nível 3 é front"*) **foi resolvida na tela, sem precisar da consulta**.

O que se vê em Configurações, Financeiro, Plano de Contas: a árvore tem **um
único nó**, `1 nexclin`, de nível 1, **sem nenhum filho**. E o diálogo de despesa
avulsa diz, com todas as letras: *"Nenhuma conta analítica disponível. O
lançamento exige uma conta de último nível."*

**É o ramo SQL.** O seed do plano de contas não rodou para esta clínica, e o
front está certo: ele recusa porque não há o que oferecer.

### O achado que impede o conserto óbvio

`semear_clinica(uuid)`, criada em `20260827020000` justamente para reparar
clínica existente, **não conserta esta**. O guarda dela é:

```sql
IF NOT EXISTS (SELECT 1 FROM public.chart_of_accounts WHERE clinic_id = _clinic_id) THEN
  PERFORM public.seed_chart_of_accounts(_clinic_id);
```

Existe **uma** linha, então a condição é falsa e o seed é pulado. *"Tem pelo
menos uma linha"* não é a mesma pergunta que *"o esqueleto está completo"*, e a
clínica com um grupo solto passa pelo guarda e nunca é semeada.

**Isso é defeito da função de reparo, não desta clínica**, e é faixa A: a mesma
armadilha vai pegar qualquer conta que tenha sido expurgada pela metade.

**A correção durável:** o guarda passa a perguntar por conta **analítica**, que é
o que o lançamento exige, em vez de por linha qualquer. Algo como `NOT EXISTS
(... WHERE clinic_id = _clinic_id AND level = 3 AND active)`. Requer migração, e
por isso está aqui e não foi feita.

**A decisão que é sua:** corrigir o guarda e rodar `semear_clinica`, ou rodar
`seed_chart_of_accounts` direto nesta clínica e deixar o guarda para depois. A
primeira conserta a próxima clínica também; a segunda destrava hoje e deixa a
armadilha de pé.

### V-21, fechado em 28/08 na tela

As duas facetas que faltavam foram reconferidas com a base povoada, e **nenhuma
das duas é bug**:

- **Gráfico do fluxo de caixa:** aparece, com saldo acumulado por semana e
  `SALDO FINAL R$ -63.380,00`. Não reproduzido, e agora com dado real na base.
- **Ticket médio zerado:** o cálculo está certo. O quadro mede **por
  fechamento**, e a base povoada **não tem nenhum fechamento**: `FECHAMENTOS 0`,
  `TAXA DE CONVERSÃO 0.0%`, `R$ 0 de R$ 0 orçados`. O que tem dado é venda e
  recebimento, e ali o ticket aparece certo: `R$ 133.700 / 78 vendas = R$ 1.714`.

**O que isso revela, e vale mais que a faceta:** o povoamento criou vendas,
recebimentos e despesas, e **não criou fechamentos**. Toda a família de números
que depende de `closings` fica sem como ser testada, que é justamente o que o
E-01 do Erick queria destravar. Registrado para a próxima rodada de povoamento.

**Achado menor, faixa C:** *Top Macro-Categorias* e *Top Profissionais* mostram
"Nenhum fechamento e nenhum recebimento no período" enquanto o quadro ao lado diz
`Recebimentos efetivados R$ 129.020,50`. A mensagem de vazio contradiz o card
vizinho. Não corrigir agora, vira requisito da stack nova.

### V-04, fora da trava desde 28/08

Retirado por decisão do Arthur, com a razão dele: *"quem cria as contas é o
Superadmin, por isso não tem a opção de se cadastrar no sistema. 1 conta mestra
gerencia tudo isso."* O cenário reportado não existe no produto.

**Fica em aberto a pergunta que colide com a regra (e) da constituição:** quando
a conta mestra cria o acesso de alguém, quem digita a senha é a pessoa, por link,
ou a mestra define e repassa? É a decisão pendente mais antiga do projeto, e ela
não morre com o V-04.

**Fora de escopo por decisão, e não é adiamento:** V-05, V-07, V-08, V-09, V-30 e
V-31 viram **requisito das regras de módulo da stack nova** pela D-7, não item de
lista. O redesenho do financeiro em dois blocos com pagamento independente e o
LTV por paciente seguem o mesmo caminho.
