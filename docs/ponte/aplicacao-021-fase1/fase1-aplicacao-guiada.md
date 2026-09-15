# 021 fase 1, aplicação guiada

Um bloco por vez, cada um com a sua conferência ao lado e a reversão embaixo.
Nada aqui foi aplicado: aplicar é do Arthur, no editor de SQL do banco ao vivo.

**Antes de tudo, o portão da T009:** o export do banco tem de estar feito e com
cópia em nuvem, registrado em `docs/ponte/registro-exports-banco.md`. **Cuidado
com a tela:** logo abaixo do `Export data` ficam `Pause` e `Remove`, os dois em
vermelho, num espaço de cerca de 200 pixels.

## A correção que esta fase trouxe antes de escrever uma linha de SQL

A regra 021 dizia, no FR-004, que `bank_accounts` **não tem nenhuma coluna de
saldo**, e classificava isso como o achado que rebaixava o "saldo de hoje" de
faixa B para faixa A.

**Isso está errado.** `opening_balance` e `opening_date` existem desde a
migração `20260427222514`, de 27/04/2026, e o front já as lê em três lugares:
`FluxoCaixa.tsx`, `Dashboard.tsx` e `ConfigBankAccountsDialog.tsx`. A regra foi
escrita a partir de uma leitura incompleta das migrações em 05/09.

Consequência prática: **o FR-004 já está atendido no banco**, e o que falta dele
é de tela, não de schema. A regra foi corrigida no mesmo commit deste arquivo,
como manda a alínea (l).

## Bloco 1, a baixa passa a ter valor recebido, autor e hora

Atende **FR-002** e **FR-003**.

| Passo | Arquivo | O que esperar |
|---|---|---|
| 1 | [`b1-baixa-em-duas-etapas.sql`](b1-baixa-em-duas-etapas.sql) | `ALTER TABLE` sem erro. Seis colunas novas, três em `receivables` e três em `expenses` |
| 2 | [`b1-conferencia.sql`](b1-conferencia.sql) | Todas as linhas `OK`, a última dizendo `CONTROLE POSITIVO OK`, e `linhas` igual a `intactas` |
| 3 | só se der errado | [`b1-reversao.sql`](b1-reversao.sql), que primeiro pergunta se ainda dá para reverter |

**Leia o controle positivo antes do resto.** A última linha da conferência
procura uma coluna que não existe. Se ela vier `OK`, a consulta está quebrada e
o resultado inteiro não vale nada. Essa armadilha já mordeu este projeto:
afirmação negativa passa quando o teste está errado.

**O que as três colunas são, e por que não uma.**

- `settled_value` é o que de fato entrou ou saiu. `value` continua sendo o
  **previsto**. Quando os dois divergem, por tarifa, desconto, juro ou pagamento
  parcial, hoje o sistema grava o previsto como se fosse o realizado, e é assim
  que nasce divergência de caixa.
- `settled_by` é quem decidiu que o dinheiro entrou. Ficou mais urgente com a
  decisão de 04/09 de login de superadmin compartilhado pelos três sócios: sem
  autor, três pessoas viram uma.
- `settled_at` é a hora, em `timestamptz`. **`paid_at` continua sendo a data de
  caixa**, que é o que `dataDeCaixa` lê nas duas telas. São duas perguntas: em
  que dia o dinheiro entrou, e em que instante alguém afirmou isso. Trocar o
  tipo de `paid_at` quebraria as duas telas.

**Toda linha antiga nasce nula, de propósito.** Nulo aqui quer dizer "baixa
anterior a esta regra". Preencher com palpite transformaria ausência de registro
em registro falso, e auditoria com dado inventado é pior que auditoria vazia.

## Depois deste bloco

O front da baixa em duas etapas (**FR-001**, issues #66 e #67) depende destas
colunas e só pode ser escrito depois que o bloco 1 estiver aplicado e conferido.
Enquanto isso não acontecer, as telas continuam trocando `status` direto, que é
o caminho que o FR-001 proíbe.
