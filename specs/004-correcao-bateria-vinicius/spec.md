# SPEC 004 — Correção da 1ª bateria de testes (Vinícius, 18–19/08)

> **Status:** proposta · **Executor:** Claude Code · **Aprovador:** Arthur Hideo
> **Alvo:** plataforma Lovable (`nexclin/nexclin`, branch `main`), via ponte inversa
> **Janela:** 23/08/2026 — **último dia antes da bateria do Erick (24–26/08)**
> **Lei:** `.specify/memory/constitution.md` · **Critério:** `CLAUDE.md` §2.5
> **Fonte dos itens:** `docs/planejamento/triagem-baterias-18-19.md` (V-01…V-33, D-1…D-13)
> **Procedimento:** `docs/ponte/ponte-inversa.md` · skill `nx-ponte`

---

## POR QUE ESTA SPEC EXISTE

As specs 001–003 são da **stack nova**. Esta é a primeira que trata da
**plataforma que vai ao ar em 01/09** — e por isso tem regras próprias:
prazo curto, escopo fechado, e um gate que nenhuma outra spec tem (**o Publish
manual do Arthur**, porque não existe CLI para publicar na Lovable).

A bateria do Vinícius produziu **33 apontamentos**, já triados e decididos
(D-1…D-13). O que faltava era um artefato de **execução** — com fases, ordem,
dependências e critério de fechamento por item. É o que este documento é.

## OBJETIVO

Deixar a plataforma em estado de ser testada pelo Erick em 24/08 sem que ele
esbarre nos mesmos problemas que o Vinícius já reportou — com prioridade
absoluta para **relatórios** e para **o que fica gravado no banco**.

## O CRITÉRIO QUE DECIDE O ESCOPO (não reabrir)

Da §2.5 do `CLAUDE.md`, com a régua fina de 20/08:

| Faixa | Pergunta | Ação |
|---|---|---|
| **A — atravessa como banco/dado** | Muda o que é **persistido** (valor, data, atribuição, a qual conta pertence)? | **Corrigir.** O erro migra para a stack nova em outubro. |
| **B — atravessa como regra** | Muda só **como a tela soma ou exibe** dado já gravado certo? | Regra escrita basta (já está na triagem). |
| **C — não atravessa** | Front, layout, mensagem? | Não corrigir, salvo se impedir o fundador de operar. |

**Duas exceções nomeadas, já decididas:**

- **D-8 — RELATÓRIO é exceção da faixa C.** O time do Vinícius não usa o
  dashboard; puxa as bases pelos relatórios, toda semana, e decide em cima.
  Relatório errado = decisão errada = perda para a clínica dele. **Relatórios
  têm de funcionar em 01/09.**
- **Dashboard foi rebaixado** (V-13, V-21). Regra escrita, implementação na
  stack nova.

**Corolário que guia esta spec:** o risco não é o bug feio — é o **número
errado que fica gravado** e é importado em outubro. O Arthur estima R$ 100–200
mil de faturamento lançado por clínica no mês da Lovable.

## ESTADO DE PARTIDA (medido em 23/08, contra `nexclin/nexclin@6b03f6c`)

### Fechado e publicado

| Item | Commit | Prova |
|---|---|---|
| **V-22 / V-23** — vencimento do recebível segue o meio de pagamento | `7eff4cf` | ✅ testado ao vivo (Boleto → 23/08; Dinheiro → volta a 20/08) |
| **V-17 / V-28B** — datas em fuso local, não UTC | `2e390ff` | ✅ verificado por cálculo; falta aceite na tela |
| **V-04 (código)** — convite sem senha de terceiro | `dabf1ef` | código revisado; **falta o reteste (A4)** |
| **V-26 (parte bug)** — despesa fixa não pula o mês corrente | `88df535` | simulado nos 3 casos; falta aceite |

### Aberto — é o que esta spec executa

Detalhe item a item na `tasks.md`.

## PRÉ-REQUISITOS

- Clone da plataforma atualizado (`bash scripts/ponte.sh preparar`).
- **Gate de tipos:** `npx tsc -p tsconfig.app.json` limpo antes de qualquer
  envio. `npm run build` **não checa tipos** — Vite usa esbuild. Foi o que
  derrubou o app por 1h35 em 20/08.
- **Export do banco** antes de qualquer escrita em produção (não há PITR
  neste tier).

## AS TRÊS ARMADILHAS DA PONTE (custaram tempo real em 20/08)

1. **O Publish publica o PREVIEW, não o commit.** Se ler "Preview is out of
   date", clicar **Update preview**, esperar terminar (~11 min), e só publicar
   ao ler **"Previewing"**.
2. **O Publish NÃO redeploya edge function.** Correção que toca front + function
   exige a **function primeiro**.
3. **`conferir` não é formalidade.** Duas vezes em 20/08 o painel afirmou
   sucesso sem ter publicado.

Menores: "Build unsuccessful" no editor é **falso** (aparece em todo commit
vindo do GitHub). E **`Consultas.tsx` é página órfã** — o menu "Consultas"
aponta para `/acompanhamento`; conferir roteamento antes de corrigir um arquivo.

## FASES

| Fase | Conteúdo | Faixa | Risco |
|---|---|---|---|
| **F1** | Relatórios — V-27/V-26 reconferência, V-29, V-28A, V-25 | A (por D-8) | baixo/médio |
| **F2** | Atribuição e financeiro gravado — V-18+V-20, V-12, V-15+V-16, V-19 | **A** | médio |
| **F3** | Integridade de cadastro e agenda — V-04B, V-32, V-24, V-10 | A | baixo |
| **F4** | D-13 — taxa de maquininha como despesa | A | **alto** |
| **F5** | Faixa C barata — V-01, V-02, V-03, V-06 | C | trivial |

**F4 é isolada de propósito.** Ela toca Contas a Receber, Fluxo de Caixa e
DRE/DFC ao mesmo tempo, e implementar metade **corrompe o resultado**: hoje o
recebível grava `net_value` (já líquido); criar a despesa por cima disso
desconta a taxa duas vezes. Só entra com as três partes juntas e com decisão
de backfill tomada.

## CRITÉRIOS DE ACEITE DA SPEC

Executados pelo Arthur na plataforma ao vivo. **"Implementado ≠ funciona":**
item sem prova na tela fecha como *"código lido, não comportamento provado"* e
permanece aberto — foi assim que o T017 ficou, corretamente, em aberto.

1. Relatório de Contas a Pagar e DRE/DFC trazem os lançamentos do período.
2. Produtividade mostra **valor orçado** e **valor fechado** em colunas
   distintas, e a conversão bate com o caso do Vinícius (1.800 orçado / 1.600
   fechado).
3. Relatório de Vendas traz **uma linha por item aprovado** do orçamento, com
   médico prescritor e responsável pela venda.
4. Datas personalizadas filtram o relatório de Contas a Receber.
5. Consulta avulsa gera as tarefas automáticas, atribuídas ao **responsável
   pela venda**.
6. Tela financeira pós-consulta soma **consulta + prescrição**, e a entrada
   abate a **consulta**.
7. Hora da consulta exibida é a hora digitada.
8. Nenhuma linha órfã em `team_members` após falha de criação de acesso.

## O QUE ESTA SPEC NÃO FAZ

- **Dashboard** (V-13, V-21) — rebaixado pela D-8. Regra escrita (D-9), vai
  para a stack nova.
- **Financeiro em dois blocos com pagamento independente** — a D-3 fixou o fix
  mínimo nesta janela; o redesenho é backlog imediato pós-lançamento.
- **LTV por paciente** — requisito novo do Vinícius (20/08), não é bug. Stack
  nova.
- **V-05, V-07, V-08, V-09, V-30, V-31** — backlog que, pela D-7, vira
  **requisito das specs de módulo da stack nova**, não lista adiada.

## RASTRO

Cada item fecha com: commit na plataforma · bundle publicado · linha de aceite
na `tasks.md` · apontamento marcado no Notion.
