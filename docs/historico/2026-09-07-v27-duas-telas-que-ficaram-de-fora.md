# V-27 outra vez: duas telas leem `revenues`, e ninguem escreve nela

**07/09/2026, madrugada. Trinta horas para o lancamento.**

Achado enquanto se conferia o financeiro contra dado real. **Nao e bug novo: e o
V-27, que ja foi diagnosticado e corrigido em outras telas.** O comentario que
prova isso esta no proprio codigo, em `src/pages/Dashboard.tsx`, linha 178:

> A tabela `revenues` existe no schema e NENHUM caminho do app escreve nela,
> todo o dinheiro entra em `receivables` (mesma causa do V-27, que zerava o
> DRE). Esta consulta alimenta o drill-down "Receitas"; lendo de revenues, ele
> abria sempre vazio.

A varredura daquela correcao pegou o Dashboard e o Relatorio DFC/DRE. **Duas
telas ficaram de fora**, e as duas sao financeiras.

## A prova de que ninguem escreve em `revenues`

Toda afirmacao negativa precisa de controle positivo, e aqui ele existe.

| Onde se procurou | Resultado |
|---|---|
| `from("revenues")` em `src` | duas ocorrencias, **as duas `.select`** |
| `INSERT INTO revenues` nas 60 migracoes | nenhuma |
| `revenues` nas seis edge functions | nenhuma |

**Controle positivo 1:** o mesmo padrao de busca por `.insert` encontra escrita
em doze tabelas, `tasks` com 11 pontos, `receivables` com 6, `expenses` com 3.
O padrao funciona; `revenues` e que nao aparece.

**Controle positivo 2:** a palavra `revenues` aparece em tres migracoes, entao a
busca alcanca o texto. O que nao existe e escrita.

## De onde vieram as 280 linhas da clinica de teste

Do nosso proprio povoamento, `docs/ponte/povoamento-27-08/2-povoamento.sql`,
linha 288. Ele insere **uma receita por consulta com `status = 'compareceu'`**,
com `gross_value = a.sold_value`. Logo abaixo, na linha 302, insere **um
recebivel pela mesma consulta**, com o mesmo `sold_value`.

**E o mesmo dinheiro gravado em duas tabelas.** O censo de 06/09 mediu 280 em
cada uma, e agora se sabe por que os dois numeros sao iguais.

## Defeito 1, e este atinge TODA clinica real

`src/pages/Insights.tsx`, linha 54. O retrato que vai para a IA tira o
faturamento **so de `revenues`**:

```ts
faturamento_bruto:  revenues.reduce((s, r) => s + Number(r.gross_value || 0), 0),
faturamento_liquido: revenues.reduce((s, r) => s + Number(r.net_value || 0), 0),
```

Numa clinica nova, `revenues` nasce vazia e nunca recebe linha. Entao:

- `faturamento_bruto` = **R$ 0**
- `faturamento_liquido` = **R$ 0**
- `despesas_total` = valor real, porque vem de `expenses`

A IA recebe receita zero contra despesa real e devolve o diagnostico obvio: a
clinica esta no prejuizo em tudo. **O modulo `insights` entrega conselho errado
para todo cliente fundador, desde o primeiro dia.** E o oposto do criterio do
`CLAUDE.md`, que e melhorar a decisao da clinica.

## Defeito 2, e este atinge a clinica de teste, que e a vitrine

`src/pages/FluxoCaixa.tsx`, linhas 136 e 141:

```ts
const dayRevenues = revenues.filter((r) => r.revenue_date === dayStr);
const entradas = dayReceivables.reduce((s, r) => s + valorDeCaixa(r), 0)
  + dayRevenues.reduce((s, r) => s + Number(r.gross_value), 0);
```

Soma as duas tabelas como entrada do mesmo dia. Onde `revenues` tem linha, **o
caixa conta o mesmo dinheiro duas vezes.**

Em clinica de cliente nao aparece, porque `revenues` fica vazia. Aparece na
clinica de teste povoada, que e onde o Vinicius, o Erick e o Arthur olham para
julgar o produto. **Explica a sensacao de "os numeros nao batem" sem que
nenhuma outra conta esteja errada.**

## A correcao, que e a mesma dos dois lados

Ler dinheiro de `receivables`, como o Dashboard ja faz. A cadeia de valor e
`valorDeCaixa`, de `src/lib/dataDeCaixa.ts`: `settled_value`, depois
`net_value`, depois `gross_value`, depois `value`.

### Insights.tsx

Trocar a consulta da linha 54:

```ts
supabase.from("receivables")
  .select("id, gross_value, net_value, value, settled_value, paid_at")
  .eq("clinic_id", clinicId!).eq("status", "pago")
  .gte("paid_at", monthStart).lte("paid_at", monthEnd),
```

E as duas somas:

```ts
faturamento_bruto:   revenues.reduce((s, r) => s + Number(r.gross_value ?? r.value ?? 0), 0),
faturamento_liquido: revenues.reduce((s, r) => s + valorDeCaixa(r), 0),
```

O recorte por `paid_at` com `status = 'pago'` e o mesmo do
`receivablesPaidPeriod` do Dashboard, entao as duas telas passam a contar pela
mesma base, que e **pagamento**.

### FluxoCaixa.tsx

Remover a perna de `revenues`: a consulta das linhas 59 a 68, o `dayRevenues` da
linha 136, a parcela na soma da linha 142, a linha de `items` da 147, e o
`revenues` do array de dependencias da linha 153.

## O que isto resolve alem dos dois defeitos

Fecha uma divergencia que estava aberta entre dois documentos nossos. A secao 7
da regra 021 diz que ha **seis** caminhos de escrita em `revenues`; a fila de
prioridade de 06/09 diz que **nenhum** caminho escreve. **A fila esta certa**, e
a medida acima e a prova. A regra 021 precisa da correcao.

Tambem simplifica o portao 1 (#60): a saida "congelar `revenues` para leitura"
custava "achar e trocar todo caminho de escrita, e ha seis". Nao ha nenhum.

## Faixa, e por que se corrige mesmo sendo calculo de tela

Pela regua fina do `CLAUDE.md` isto e calculo de tela, faixa B. **Entra pela
excecao nomeada:** financeiro na Lovable tem de funcionar como vai funcionar na
stack final, e foi por gestao financeira que o NexClin foi vendido. Entregar
faturamento zero no modulo de insights, e caixa dobrado na tela de fluxo,
destroi exatamente o argumento de venda.

O tamanho tambem pesa: sao cinco linhas numa tela e tres na outra, sem migracao
e sem risco de regressao fora do proprio calculo.

## Estado

**Nao aplicado.** A escrita em `../nexclin-lovable` esta bloqueada pelo
classificador do modo automatico desta sessao, e o bloqueio e do harness, nao
das permissoes do repositorio. As correcoes acima estao escritas com linha e
conteudo exatos para serem aplicadas assim que a escrita for liberada.

**Nada aqui foi provado na tela.** O que se provou foi a leitura do codigo, o
conteudo do povoamento e a ausencia de escrita, esta com dois controles
positivos. O comportamento das duas telas segue **codigo lido, nao comportamento
provado**, e so fecha com a tela aberta na clinica povoada.
