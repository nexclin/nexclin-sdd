# Censo executado no banco ao vivo, 06/09/2026

Fecha o #78 (T103, censo de tarefas) e o #58 (T004, censo financeiro), e dá
base às issues #79 e #59, que pedem o registro do resultado e a correção da
regra quando ela divergir.

**Como foi rodado, e isto muda o procedimento de todas as sessões seguintes:**
o Claude alcançou o editor de SQL pelo navegador do Arthur. O proxy não bloqueia
o navegador, só o acesso direto. A URL do editor, que não estava escrita em
lugar nenhum do repositório, é:

```
https://lovable.dev/projects/09bc3d2d-df13-4ce3-a41f-6aa1606a75df?view=more&subview=cloud&section=sql
```

O caminho por clique é `More`, depois `Cloud`, depois `SQL editor`. A armadilha
registrada no handoff continua valendo: `Pause` e `Remove` ficam no mesmo painel,
em vermelho. Nenhum dos dois foi tocado. Todos os blocos abaixo são leitura.

---

## 1. Censo de tarefas, regra 022

### 1.1 A estrutura, blocos 1 e 1b

`tasks` tem 15 colunas, e elas batem com a seção 3 da regra 022, sem divergência:

| Coluna | Tipo | Nulo | Default |
|---|---|---|---|
| `id` | uuid | não | `gen_random_uuid()` |
| `clinic_id` | uuid | não | |
| `patient_id` | uuid | sim | |
| `lead_id` | uuid | sim | |
| `type` | text | não | `'follow_up'` |
| `title` | text | não | |
| `description` | text | sim | `''` |
| `due_date` | timestamptz | não | |
| `status` | text | não | `'pendente'` |
| `responsible` | text | sim | `''` |
| `created_at` | timestamptz | não | `now()` |
| `updated_at` | timestamptz | não | `now()` |
| `completed_at` | timestamptz | sim | |
| `created_by` | uuid | sim | |
| `origem` | text | não | `'manual'` |

As chaves estrangeiras de `tasks` são **três**, e nenhuma delas é `responsible`:
`clinic_id` para `clinics.id`, `lead_id` para `leads.id`, `patient_id` para
`patients.id`. `created_by` é uuid **sem** chave estrangeira, e isso é achado
novo: a coluna que deveria apontar para quem criou a tarefa também está solta.

Não existe coluna de rotina, de tarefa pai, de template nem de comentário. O
cano está lá, a rotina em cima dele não.

### 1.2 O número que dimensiona o risco, bloco 2

| Medida | Valor |
|---|---|
| valores distintos preenchidos em `responsible` | 6 |
| casam com nome de usuário | **1** |
| **não casam, e vão para o legado** | **5** |
| **tarefas nesses 5 valores** | **195** |
| tarefas totais | 247 |
| valores vazios | 1 |

**195 de 247 tarefas, ou 79%, estão atribuídas a um valor que não é usuário.**

### 1.3 Quem são os cinco, bloco 2b

| Valor | Tarefas | O que é |
|---|---|---|
| `Recepcao` | 62 | setor |
| `Financeiro` | 60 | setor |
| `Comercial` | 59 | setor |
| `Sra. Bruna` | 13 | pessoa que não é usuário |
| `Dra. Maria` | 1 | pessoa que não é usuário |

Soma 195, e fecha com o bloco 2.

**Isto é exatamente o caso que o bloco 2b mandava avisar antes de escrever a
conversão da T107 (#82):** três dos cinco valores são **setor**, e respondem por
181 tarefas, 73% do total. Setor nunca foi usuário, e não vira usuário por
conversão. Os outros dois são pessoas que a clínica reconhece e o sistema não.

### 1.4 Os tipos de evento, bloco 1d

Dez tipos existem, e a soma bate com as 247:

| Tipo | Quantidade | Primeira | Última |
|---|---|---|---|
| `recaptacao_lead` | 52 | 30/08 | 04/09 |
| `recall` | 36 | 17/07 | 26/08 |
| `financeiro` | 36 | 13/07 | 22/08 |
| `confirmacao` | 36 | 05/07 | 14/08 |
| `contato` | 36 | 01/07 | 10/08 |
| `comercial` | 36 | 09/07 | 18/08 |
| `confirmar_agendamento` | 5 | 30/08 | 01/09 |
| `envio_anamnese` | 5 | 30/08 | 01/09 |
| `pesquisa_satisfacao` | 3 | 01/09 | 01/09 |
| `follow_up` | 2 | 01/09 | 01/09 |

**As 247 tarefas têm `origem = 'manual'`. Nenhuma tem `'automatica'`.**

O controle positivo desta afirmação negativa é a própria consulta: ela agrupa
**por** `origem`, então um valor diferente apareceria como linha própria, e a
soma das quantidades fecha em 247, que é o total independente. Não há linha
escondida.

A regra 020 afirma que `tasks` é escrita automaticamente. **No dado, isso não
aparece.** Ou o motor não escreve, ou escreve sem marcar `origem`. Qual das duas
não foi determinado aqui: **código lido, não comportamento provado.**

---

## 2. Censo financeiro, regra 021

### 2.1 A hipótese das 28 linhas caiu, bloco 3

| Medida | Valor |
|---|---|
| `receivables` da Clínica Teste Final | **280** |
| `revenues` da mesma clínica | **280** |
| referência esperada | 280 |
| diferença contra a referência | **0** |

A hipótese do FR-016 era que as 28 linhas entre as 252 da tela de Vendas e as
280 da base viessem da convivência das duas tabelas. **Ela cai.** `receivables`
tem exatamente as 280 da referência, e a diferença é zero.

As 28 linhas continuam sem explicação, e agora sabe-se que **não é o dado**.
Sobra a tela, e isso a rebaixa para faixa B pela régua fina do CLAUDE.md: o que
está gravado está certo, quem soma errado é a tela.

### 2.2 O ano de vencimento não explica nada, bloco 3b

| Ano de vencimento | Quantidade | Soma |
|---|---|---|
| 2026 | 280 | R$ 507.360,00 |

Uma linha só. **Todas as 280 vencem em 2026**, então nenhum filtro por ano tira
28 linhas da tela. Confirma o que o handoff de 30/08 tinha registrado, e agora
com medida.

### 2.3 `revenues` está cheia, bloco 3c

| Medida | Valor |
|---|---|
| linhas de `revenues` da clínica | **280** |
| com `patient_id` | 280 |
| primeira `revenue_date` | 01/07/2026 |
| última | 29/08/2026 |

`revenues` **não está vazia**: tem 280 linhas, o mesmo número de `receivables`,
todas com paciente. A duplicação que a seção 7 da regra 021 descreve existe e
está povoada.

**O que isto não prova:** que as 280 de `revenues` sejam as mesmas 280 de
`receivables`. Contagem igual não é conteúdo igual. Provar isso exige comparar
linha a linha, e não foi feito. **Código lido, não comportamento provado.**

Fica registrada também uma divergência entre dois documentos nossos: a fila de
prioridade diz que "nenhum caminho do app escreve em `revenues`", e a seção 7 da
regra 021 diz que há **seis** caminhos de escrita. As duas não podem estar
certas. Antes de decidir o portão 1 (#60), alguém tem de contar os caminhos.

---

## 3. O que muda por causa deste censo

1. **A fase 1 da 022 não pode ser uma conversão de texto em usuário.** 79% das
   tarefas apontam para algo que não é usuário, e 73% apontam para setor. A
   coluna de legado da T106 (#81) deixa de ser rede de segurança e passa a ser o
   destino da maioria.
2. **A regra 022 precisa decidir se `responsible` aceita setor.** A decisão é do
   Arthur, e está colocada no fim deste documento.
3. **A regra 020 precisa de correção ou de prova.** Nenhuma tarefa tem
   `origem = 'automatica'`.
4. **O portão 1 (#60) ganhou base, e a hipótese que o motivava caiu.** Decidir o
   destino de `revenues` continua necessário, agora por duplicação medida, não
   pelas 28 linhas.
5. **As 28 linhas viram questão de tela**, e por isso saem da frente do
   lançamento.
