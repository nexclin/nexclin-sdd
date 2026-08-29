# Handoff, 29/08/2026, fim do dia

> **Este é o handoff mais recente do dia 29.** Ele substitui o
> `2026-08-29-handoff.md`, que é da sessão da manhã. Atenção ao nome: o `ls`
> ordena `-` antes de `.`, então o arquivo da manhã aparece DEPOIS deste na
> listagem. Leia este.
>
> Dez dias para o lançamento de 08/09.

---

## 1. O estado, em cinco linhas

A **bateria dos oito relatórios acabou**: sete passam, um reprova. A base da
Clínica Teste Final foi expurgada, repovoada e conferida em produção, com
**oito artefatos do script corrigidos**, cinco deles achados hoje. Dois consertos
de front subiram pela ponte e estão **provados na tela**, não só no código. O
"0% agendam" que estava aberto desde ontem **tem causa e está resolvido**. Restam
o FR-005, três defeitos de front acumulados, e um acento corrompido no banco.

---

## 2. A bateria dos oito, com veredito

| # | relatório | veredito |
|---|---|---|
| 1 | DFC / DRE | passa, validado pelo Arthur em 29/08 de manhã |
| 2 | Contas a Receber | passa, validado pelo Arthur |
| 3 | Contas a Pagar | **passa**, e o conserto do filtro foi provado na tela |
| 4 | Leads | **passa**, e o conserto do rótulo foi provado na tela |
| 5 | **Vendas** | **REPROVA**, dois defeitos, ver seção 4 |
| 6 | Produtividade | passa, todas as colunas somam para a linha TOTAL |
| 7 | Atividades | passa, e as quatro situações aparecem |
| 8 | Repasse | passa, com ressalva de decisão pendente |

O critério aplicado foi o do E-01, os dois lados: **o total bate com o que foi
lançado E o agrupamento classifica de verdade.** Relatório que soma certo e joga
tudo num balde só foi tratado como reprovado, não como aprovado com ressalva.

**A ressalva do Repasse** não é defeito: as duas colunas de imposto são zero
porque não existe tabela de configuração fiscal, e o próprio código diz isso em
comentário. A decisão pendente é de onde sai a alíquota, e se é por clínica, por
serviço ou por profissional. Isso é requisito da stack nova.

---

## 3. Os oito artefatos do script, e o padrão que os une

Todos eram do povoamento, nenhum era do produto. Os três primeiros já eram
conhecidos; do quarto em diante são de hoje.

| # | artefato | como se manifestava |
|---|---|---|
| 1 | despesa sem conta analítica | tudo em "0 - Outros" |
| 2 | serviço de consulta com macro de venda | Total Consultas em R$ 0 |
| 3 | descrição de item que não casa com serviço | "Sem classificação" liderando |
| 4 | recebível com `item` que não é nome de serviço | custo do Repasse zerado em 100% |
| 5 | recebível com macro-categoria única | Total Consultas em R$ 0, de novo |
| 6 | os dois baldes do split sem dinheiro dos dois lados | um lado sempre vazio |
| 7 | estágio de funil fora do vocabulário do produto | **tela vazia**, não número errado |
| 8 | tarefa concluída que nunca atrasa | uma das quatro situações inalcançável |

**O padrão, e ele vale mais que a lista:** inserir direto no banco pula a
validação que mora no formulário, e cada validação pulada vira um número errado
num relatório que alguém vai ler. Oito vezes o mesmo mecanismo.

**Uma correção ao registro de 28/08.** O commit `6bbc06e` disse que o dashboard
separa Total Consultas de Total Vendas por `services.macro_category`. Não separa.
Ele lê `receivables.macro_category`, em `Dashboard.tsx:348`. Por isso a correção
de ontem não mudou aquele número, e ninguém percebeu até hoje.

### O artefato 7 fecha um achado aberto

O `2-povoamento` escrevia `funnel_stage` em
`novo, contato, agendado, compareceu, fechado`. O produto **nunca** escreve
nenhum desses: os cinco válidos estão em `Atendimentos.tsx:179-183`, e são
`novo_contato, em_atendimento, agendou, nao_agendou, recaptacao`.

Repare em `agendado` contra `agendou`. Uma letra. `Dashboard.tsx:330` conta
`funnel_stage === 'agendou'`, a conta dava zero, e o painel mostrava **"0%
agendam" ao lado de 203 agendamentos**. Estava na seção 6 do handoff da manhã
como achado nunca investigado.

O mesmo erro sumia os 240 leads das colunas do funil em `Atendimentos.tsx:327`.
Depois da correção, as cinco colunas têm 48 cada.

**Este é o único dos oito que não se manifestava como número errado.** Ele se
manifestava como ausência, e tela vazia não parece defeito: parece clínica sem
movimento.

---

## 4. O que está aberto, em ordem de prioridade

### 4.1 FR-005, a trilha de leitura de dado clínico

**Único item com prazo legal, e não começou.** Decisão do Arthur já tomada:
registra cada paciente aberto, com operador, clínica, paciente e horário. Exige
tabela própria, RLS, retenção, e o gancho no front que grava a leitura.

**Não comece isto com pouca margem de sessão.** Trilha de auditoria pela metade é
pior que trilha nenhuma, porque dá a sensação de que existe registro quando não
existe.

### 4.2 Os três defeitos de front, para UMA viagem de ponte

Nenhum foi enviado. A decisão de 29/08 é acumular e subir de uma vez, porque cada
viagem custa um build de preview, um Publish manual e um `conferir`.

**(a) O seletor de período não atualiza o próprio estado.** Afeta todos os
relatórios que o usam. Escolher "Este ano" muda os dados na consulta, mas o
rótulo do gatilho continua "Este mês" **e o checkmark dentro do menu continua em
"Este mês"**. Conferido reabrindo o menu, não suposto.

Consequência: a pessoa não sabe qual período está vendo, e clicar em "Este mês"
para voltar parece não fazer nada, porque já está marcado. Num relatório de
decisão isso não é cosmético. Foi ele que me fez comparar Vendas contra a
referência errada na primeira tentativa.

**(b) Vendas: o quadro escrito "Valor Pago" não é o valor pago.**
`RelatorioVendas.tsx:181` soma `gross_value` de todas as linhas do período,
pagas e pendentes, e a linha 213 rotula isso como Valor Pago. Na tela deu
**R$ 449.820,00** onde o pago de verdade é **R$ 312.060,00**: R$ 137.760,00
apresentados como recebidos. É a queixa do E-01 no quadro que se olha primeiro.

**(c) Vendas: o ticket médio divide por paciente, e não por venda.**
`totalGross / uniquePatients`. Com 252 vendas e 118 pacientes, infla 2,1 vezes:
R$ 3.812,03 na tela contra R$ 1.785,00 por venda.

Isto contradiz o próprio projeto. O FIN-7 criou `src/lib/chaveDaVenda.ts`
justamente porque o dashboard calculava ticket por linha de recebível, e o
arquivo diz em comentário que a regra virou função para não ser reimplementada de
outro jeito em outro lugar. Foi reimplementada de outro jeito em outro lugar.

**(a) e (b) são obrigatórios antes de 08/09.** O time do Vinícius opera por
relatório, e os dois fazem o relatório afirmar coisa falsa sobre dinheiro.

### 4.3 Acento corrompido no plano de contas, faixa A

| tabela | corrompidos | total |
|---|---|---|
| `chart_of_accounts`, Clínica Teste Final | 51 | 104 |
| `chart_of_accounts`, todas as 20 clínicas | **204** | 1976 |
| `expense_categories` | 0 | 147 |
| `services` | 0 | 3196 |
| `clinics` | 0 | 20 |

`Água` gravado como `Ãgua`, `AQUISIÇÕES` como `AQUISIÃ‡ÕES`. **Só o plano de
contas**, e ele migra intacto em outubro.

**O reparo padrão NÃO funciona, e os dois erros dizem por quê:**

- `convert_to(name,'LATIN1')` falha em `0xe2 0x80 0xa1`, que é `‡`. LATIN1 não
  tem esse caractere.
- `convert_to(name,'WIN1252')` falha em `0xc2 0x81`, que é `U+0081`. CP1252 não
  define o byte `0x81`.

Os bytes UTF-8 originais foram lidos como CP1252, e os bytes que o CP1252 não
define passaram cru. `Ç` é `C3 87`, e o `87` virou `‡`; `Á` é `C3 81`, e o `81`
virou `U+0081`. **Nenhuma conversão única desfaz**, porque a corrupção usou duas
tabelas ao mesmo tempo.

O caminho é `translate` dos especiais do CP1252 de volta para os bytes `0x80` a
`0x9F`, e só então a volta por LATIN1. Dá para provar com SELECT antes de
qualquer UPDATE. Deve nascer como migração no repositório principal, porque é
faixa A.

### 4.4 Menores, já registrados

- **FR-006**, migração `20260828030000`, escrita e **nunca rodada em banco
  nenhum**. Código lido, comportamento não provado.
- **Vendas mostra 252 onde a base tem 280 recebíveis**, todos com vencimento em
  2026. Faltam 28 e o filtro de data não justifica. **Pendência honesta, não
  acusação:** não investiguei.
- **Lacunas de LGPD do painel**: tela de pedido do titular, retenção, e conferir
  se os quatro papéis de operador realmente limitam. Este último é o que mais
  preocupa, porque só se descobre furando, e ninguém furou.
- **Duas clínicas "Clínica Dra. Duda Gonçalves"**. Decisão do Arthur.
- **`Top Macro-Categorias`** com mensagem de vazio ao lado de quadro com valor.

### 4.5 Cortado, com a razão

- **Converter os `<select>` nativos das oito telas do superadmin.** Refatoração
  de estado, tela a tela, com risco, num painel que só o Arthur usa, numa
  plataforma descartada em outubro. Faixa C pura. Nasce certo na stack nova.
- **A reprodutibilidade do povoamento.** O arquivo afirma em comentário que rodar
  de novo produz a mesma base. É falso para tudo que depende de UUID: o que
  decide se um recebível está pago é `hashtext(a.id::text)`, e o id é novo a cada
  execução. Medido: entradas brutas deram 314.300,00 e 295.820,00 em dois ensaios
  do mesmo script no mesmo dia. Despesa é chaveada no índice da série e reproduz;
  por isso as saídas pagas deram 180.880,00 nas três execuções. **Comentário
  errado em arquivo de simulação, sem impacto em cliente.**

---

## 5. O plano até 08/09

A restrição real não são os dez dias. São o limite de uso do Arthur e o fato de
que **toda mudança de front precisa do clique dele no Publish**.

| quando | o quê |
|---|---|
| próxima sessão, a maior disponível | **só o FR-005**, do início ao aceite |
| sessão curta seguinte | FR-006 aplicado e provado; migração do acento; a viagem única de ponte com os três defeitos de front |
| **05 a 07/09** | **nada planejado**, reserva para o que o fundador achar |

Plano que ocupa até a véspera não tem folga para o problema real, e ele sempre
aparece.

---

## 6. Os números de referência da base

Clínica Teste Final, `d51ce6c7-582b-469b-a01b-608bd9b38885`. A conta
`erpclinicas@gmail.com` está nesta clínica, conferido no banco.

**Conferir sempre em janela anônima.** Cache de navegador já enganou este projeto.

| | |
|---|---|
| entradas brutas (pago) | R$ 312.060,00 |
| entradas líquidas (pago) | R$ 301.137,90 |
| bruto de todos os recebíveis | R$ 507.360,00 |
| saídas pagas | R$ 180.880,00 |
| balde consulta / balde venda | R$ 56.280,00 / R$ 255.780,00 |

Volume: 180 pacientes, 420 consultas, 165 fechamentos, 280 recebíveis, 70
despesas, 79 contas analíticas, 240 leads, 90 tarefas, 2 na equipe.

**Despesas por conta de nível 1**, que é a referência do agrupamento:

| nível 1 | | despesas | total |
|---|---|---|---|
| 1 | IMPOSTOS, TAXAS E AFINS | 17 | 86.140,00 |
| 2 | DESPESAS ADMINISTRATIVAS | 14 | 21.480,00 |
| 3 | DESPESAS OPERACIONAIS | 12 | 34.040,00 |
| 4 | INFRAESTRUTURA | 6 | 8.970,00 |
| 5 | SERVIÇOS TERCEIRIZADOS | 10 | 16.520,00 |
| 6 | PESSOAL | 7 | 8.510,00 |
| 10 | AQUISIÇÕES | 4 | 5.220,00 |

O `1` contra o `10` é o caso de teste do conserto do filtro: escolher
`1 - IMPOSTOS` tem de dar **17 e R$ 86.140,00**. Com o defeito dava 21 e
R$ 91.360,00.

**Leads:** 240, com 48 em cada um dos cinco estágios.
**Tarefas:** 90, sendo 8 pendentes, 52 em atraso, 14 realizadas no prazo e 16
fora do prazo.
**Atendimentos por profissional:** Marina 140, Helena 70, Rodrigo 70.
**Repasse pago por profissional:** Marina R$ 168.140,00, Helena R$ 79.660,00,
Rodrigo R$ 64.260,00, somando os R$ 312.060,00.

---

## 7. Onde as coisas estão

- **Branch:** `trabalho/28-08-apresentacao-inicial`, árvore limpa.
- **Commit do repositório principal:** `2c00a32`, os oito artefatos e o bloco de
  conferência.
- **Commit da plataforma:** `0ba4ac2`, em `main` de `nexclin/nexclin`,
  **publicado e conferido**. Bundle no ar `index-BBCPyeMK.js`.
- **Crédito da Lovable:** 20 mensais e 4,7 de build diário. O mensal não se moveu
  com esta viagem, então a ponte continua valendo o que promete.
- **A corrente de povoamento** tem 1133 linhas e um bloco de conferência final
  com 17 verificações. Ele existe porque o editor de SQL devolve só o resultado
  do último comando: sem ele, uma corrente que começa por expurgo termina sem
  mostrar nada, e "rodou sem erro" não é o mesmo que "a base ficou certa".
- **`correcao-vocabulario-29-08.sql`** conserta os artefatos 7 e 8 numa base já
  gravada, só com UPDATE, para não repetir o expurgo por causa de duas colunas.
  Já foi rodado.
- **Gates:** `npx tsc --noEmit` e `npx vitest run` no principal. No clone,
  `npx tsc --noEmit -p tsconfig.app.json`, que é o que `scripts/ponte.sh enviar`
  roda, e não o `tsconfig.json`, que checa zero arquivos e responde verde.

---

## 8. Duas armadilhas novas, aprendidas hoje

**`due_date` e `completed_at` em `tasks` são TIMESTAMPTZ, não DATE.** Postgres
define `date + integer` e não define `timestamptz + integer`. Somar dias direto
falha com `operator does not exist`. Converter os dois lados com `::date` antes
de qualquer conta ou comparação. Comparação sem cast até funciona, por conversão
implícita, e é justamente isso que a torna perigosa: funciona por acidente até o
fuso mudar.

**Conferir em qual clínica a sessão está antes de comparar qualquer número.** A
conta mestra podia estar em outra clínica, e eu teria concluído que sete
relatórios estavam quebrados. Um `select` de trinta segundos evitou isso.
