# Plano de implementação: financeiro que não erra o caixa

**Frente:** `021-financeiro` · **Data:** 05/09/2026
**Regra:** [`spec.md`](./spec.md), que é link para
[`docs/regras/021-financeiro-que-nao-erra-o-caixa.md`](../../regras/021-financeiro-que-nao-erra-o-caixa.md)

> Gerado por `speckit-plan` sob a [ADR 0006](../../adr/0006-o-spec-kit-volta-pela-metade.md).
> **Três decisões da seção 7 da regra continuam abertas**, e este plano as isola
> em vez de assumir resposta: cada uma vira um portão nomeado na seção 5.

---

## 1. Resumo

Dezesseis requisitos, doze deles **faixa A**, sobre um modelo financeiro que hoje
não consegue responder quanto entrou de verdade, quanto há na conta hoje, e se o
lançamento bate com o extrato. O plano separa por **onde o erro dói**, e não por
tamanho: o que muda dado gravado antes de 08/09 vai para a Lovable, porque ele é
importado em outubro; o que é estrutura nova vai para a stack nova, que nasce
sem a dívida.

**A ordem é ditada por uma coisa só:** a Fase 0 não é implementação, é
conferência. Todo o resto deste plano assume que as migrações deste repositório
descrevem o banco ao vivo, e essa é a **premissa 1 da regra, não um fato**.

---

## 2. Contexto técnico

| | |
|---|---|
| **Banco** | PostgreSQL no Supabase, dois projetos: o da plataforma Lovable, ao vivo, e o da stack nova |
| **Onde se testa banco** | editor de SQL contra o banco ao vivo. **Sem Docker e sem banco local**, decisão permanente 1 do contexto de abertura |
| **Front da Lovable** | React e Vite. Gate de tipos: `npx tsc --noEmit -p tsconfig.app.json`, porque `tsconfig.json` puro fica sempre verde |
| **Front da stack nova** | Next.js App Router, TypeScript estrito |
| **Testes** | Vitest. 233 passando na plataforma, 12 arquivos neste repositório |
| **Caminho até o cliente** | ponte inversa, `docs/ponte/ponte-inversa.md`: `main`, sem `--force`, function antes do Publish do front, e `scripts/ponte.sh conferir` ao fim |
| **Alvo de prazo** | 08/09/2026 para o que for faixa A e couber. Restam **três dias** |
| **Régua de qualidade** | 200%: construído e testado por quem construiu, **mais** validado pela ótica do usuário final. O financeiro é uma das duas áreas obrigadas a isso |

**A PRECISAR DE ESCLARECIMENTO, e cada uma vira portão na seção 5:**

1. O destino de `revenues`. Seção 7, decisão 1 da regra.
2. Se o FR-011, o buraco de permissão, entra antes de 08/09. Seção 7, decisão 2.
3. Até onde vai o "igual ao IN", que depende do acesso ou do vídeo que ficou com
   o Erick. Seção 7, decisão 3.

---

## 3. Portão constitucional

Conferido contra `docs/constituicao.md` v2.0.2, pelo ponteiro em
`.specify/memory/constitution.md`.

| Alínea | O que exige | Situação neste plano |
|---|---|---|
| **(a)** | RLS em toda tabela com `clinic_id` | as três tabelas novas nascem com RLS. **Passa** |
| **(b)** | default deny | nenhuma policy nova com `USING(true)`. O hook `guarda-constituicao.mjs` reprova se aparecer. **Passa** |
| **(c)** | segurança no banco, tela só reflete | **VIOLAÇÃO EXISTENTE, e ela é o FR-011.** As policies do financeiro não consultam `my_permission`. Ver seção 6 |
| **(d)** | auditoria de ação administrativa, `old→new` | é o FR-003. **Passa por construção** |
| **(g)** | nenhuma credencial versionada | nada de credencial neste plano. **Passa** |
| **(h)** | nenhuma feature sem regra viva aprovada, e parada humana por fase | a regra 021 existe. **Cada fase abaixo para para aceite.** Passa |
| **(j)** | implementado ≠ funciona | a seção 6 da regra tem oito provas, e nenhuma fecha por teste de unidade. **Passa** |
| **(l)** | mudança de comportamento corrige a regra no mesmo commit | o `spec.md` é link para a regra, então não há segunda cópia para divergir. **Passa** |

**Nenhuma violação nova é introduzida.** A única violação registrada é
preexistente e está nomeada como requisito.

---

## 4. Estrutura

### Desta frente

```text
docs/planos/021-financeiro/
├── spec.md   → link para ../../regras/021-financeiro-que-nao-erra-o-caixa.md
├── plan.md   este arquivo
└── tasks.md  gerado por /speckit-tasks
```

**Quatro artefatos que o Spec Kit geraria e este plano NÃO gera**, porque cada um
já tem lugar na regra e duplicá-los criaria a divergência que a alínea (l)
existe para impedir:

| O que o Spec Kit geraria | Onde isso já mora |
|---|---|
| `research.md` | seção 4 da regra, premissas, e a Fase 0 abaixo, que é a pesquisa de verdade |
| `data-model.md` | **seção 3 da regra**, que é própria justamente por ser o que atravessa para outubro |
| `quickstart.md` | seção 6 da regra, as oito provas |
| `contracts/` | não se aplica: não há interface externa nova, só schema e tela |

### Do código

```text
supabase/migrations/          migrações novas, fonte de verdade do schema
docs/ponte/                   blocos de SQL para colar à mão no editor
../nexclin-lovable/src/       front da plataforma ao vivo, fora desta sessão
app/ e lib/                   stack nova
```

---

## 5. As fases, e os portões

**Cada fase termina com aceite manual do Arthur**, alínea (h). Fase que não passa
no aceite não libera a seguinte.

### Fase 0 · Conferir o banco antes de acreditar nele

**Não implementa nada.** Existe porque tudo abaixo depende da premissa 1.

Um bloco de SQL em `docs/ponte/`, para colar no editor, que lista as colunas de
`receivables`, `expenses` e `bank_accounts`, e as policies das quatro tabelas
financeiras, direto do `information_schema` e do `pg_policies`.

**Aceite:** o que voltar bate com a tabela "o que já existe" da seção 3 da regra.
**Se divergir, a divergência é o achado**, e a regra se corrige antes de qualquer
implementação.

Junto, e no mesmo bloco porque é a mesma ida: a **prova 3**, contando
`receivables` e `revenues` da Clínica Teste Final e cruzando com os 280
recebíveis da base de referência. É ela que decide o portão 1.

### Portão 1 · O destino de `revenues` · FR-016

**Abre com o resultado da prova 3 da Fase 0.**

- As 28 linhas vêm da duplicação: a decisão 1 da seção 7 volta à mesa **antes** de
  08/09, e a Fase 1 ganha um item.
- Não vêm: a recomendação registrada vale, `revenues` não é tocada agora, e a
  stack nova nasce só com `receivables`.

Enquanto este portão não abre, **nenhuma fase escreve em `revenues`**.

### Fase 1 · O que fica gravado quando alguém recebe · faixa A · Lovable

FR-001, FR-002, FR-003 e FR-004. É a fase que paga o prazo, porque é a que
impede erro de virar importação em outubro.

1. Migração acrescentando: valor recebido e autor da baixa em `receivables` e em
   `expenses`, hora da baixa em `timestamptz`, e saldo inicial mais a data dele
   em `bank_accounts`.
2. O front da baixa passa a duas etapas, e para de escrever `status` direto.
3. `scripts/ponte.sh conferir`, e procurar o marcador no bundle. **O Publish da
   Lovable publica o preview, não o commit.**

**Ordem obrigatória**, armadilha conhecida: migração antes do front. O front novo
com a coluna inexistente quebra a tela de dinheiro.

**Aceite:** provas 4, 5 e 6 da seção 6 da regra, na tela, mais o gate de tipos com
`-p tsconfig.app.json`.

**Cuidado que já custou tempo:** o conserto correto aplicado a uma tela e não às
irmãs se repetiu cinco vezes nesta base. A baixa existe em contas a receber **e**
em contas a pagar. As duas mudam na mesma passada.

### Portão 2 · O FR-011 entra antes de 08/09?

Decisão 2 da seção 7. Puxa para agora por ser violação da alínea (c); puxa para
depois porque no dia 8 quem opera são clínicas fundadoras em que a mesma pessoa é
dona e secretária, com o módulo liberado de qualquer jeito.

**A prova 2 da Fase 0 não depende deste portão e roda antes dele**: ela mede o
tamanho do buraco, e é com o número na mão que a decisão fica barata.

### Fase 2 · A permissão volta para o banco · faixa A

FR-011 e FR-012. Policies separadas por operação, consultando `my_permission`, e
`expenses.payment_method` virando referência.

**Ir junto:** o agente `auditor-multitenant`, antes do aceite, tentando furar a
cascata em vez de só lê-la.

**Aceite:** prova 2 com controle positivo. Usuário com o módulo negado volta zero
linha, e usuário com o módulo liberado volta linha. **As duas metades, senão a
asserção negativa passa por vacuidade**, que é o que quase deixou o
**FR-005 da regra 017**, a trilha de leitura, fechar por engano. Cuidado com a
colisão: `FR-005` sem o número da regra é ambíguo, e nesta frente ele é a
transferência entre contas.

### Portão 3 · A referência do IN

Decisão 3 da seção 7. **Sem o acesso ou o vídeo, este plano para aqui.** Foi a
condição sob a qual o escopo do financeiro dispensou aprovação: "funcionar igual
ao IN" só é critério se houver o que comparar.

### Fase 3 · Extrato e conciliação · faixa A · stack nova

FR-006 a FR-009. Três tabelas: linha de extrato, vínculo de conciliação, e
transferência entre contas (FR-005).

A idempotência do FR-008 é **índice único por conta mais identificador da
transação no banco**, e não conferência no código. Trava no banco não depende de
quem chama.

A baixa automática do FR-009 chama o mesmo caminho da Fase 1. **Não abre o
sétimo caminho de escrita em `receivables`.**

**Aceite:** provas 7 e 8.

### Fase 4 · Recorrência a receber · faixa A · stack nova

FR-010, no desenho que `fixed_expenses` já usa desde 22/03. Copiar o desenho que
existe custa menos que inventar outro, e mantém as duas pontas simétricas.

### Fase 5 · Tela · faixa B · stack nova

FR-013, o saldo de hoje, que **depende do FR-004 da Fase 1**, e FR-014, a régua
em Kanban.

Fica por último de propósito: é a camada que só vale depois dos dados certos, que
foi o acordo da reunião, e é a única faixa B da regra.

---

## 6. Complexidade a justificar

| Violação | Por que ela existe | Alternativa mais simples, e por que não serve |
|---|---|---|
| **Alínea (c)**: regra de acesso do financeiro só na tela | preexistente. As policies são de 22/03 e nenhuma migração posterior as trocou. O plano a nomeia como FR-011 em vez de herdá-la calada | deixar como está seria aceitar que o menu é a segurança. Não serve, e é a alínea que a auditoria de 29/08 já achou violada nos quatro papéis do painel |
| **Três tabelas novas** na Fase 3 | conciliar é casar duas listas, e a lista do banco não existe gravada em lugar nenhum | marcar `conciliated` como hoje. Não serve: responde "alguém disse que conferiu", e não "bate com o banco" |
| **Dois alvos**, Lovable e stack nova | a §2.5. O que muda dado gravado é importado em outubro; o resto é descartado | fazer tudo só na stack nova. Não serve para as fases 1 e 2, porque o erro delas migra |

---

## 7. O que este plano deliberadamente não faz

- **Não toca `revenues`** enquanto o portão 1 não abrir.
- **Não mexe em proposta e orçamento.** Recusado na reunião, e o resumo
  automático do Gemini diz o contrário.
- **Não cria tabela paralela de eventos financeiros.** FR-015.
- **Não trata dashboard.** A acusação de que ele puxa do lugar errado continua
  sem um número que a reproduza, e sem isso não há o que consertar.
