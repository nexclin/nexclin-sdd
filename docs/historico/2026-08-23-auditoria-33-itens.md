# Auditoria dos 33 apontamentos — corte de 23/08, fim do dia

Cruzamento item a item entre `2026-08-20-triagem-baterias-vinicius.md` e os commits que
estão de fato na `main` de `nexclin/nexclin`. **Não é estimativa** — cada
"corrigido" tem commit ao lado.

> **A pergunta que isto responde:** *todos os bugs do report do Vinícius foram
> corrigidos?* **Não.** Dos 23 da trava, **20 estão corrigidos**, 1 precisa de
> reteste, 1 está parcial e 1 está bloqueado.

## Bugs — severidade TRAVA (23, após a D-2 promover o V-11)

| Item | O que era | Estado | Commit |
|---|---|---|---|
| V-01 | Scroll da lista de especialidades | ✅ corrigido | `a239dec` |
| V-04 | Erro ao salvar secretária com acesso | ⚠️ **falta reteste** | `dabf1ef` |
| V-04B | Linha órfã em `team_members` | ✅ corrigido | `1dbf842` |
| V-10 | Agenda aceita choque de horário | ✅ corrigido | `a239dec` |
| V-11 | Consulta avulsa sem responsável | ✅ corrigido | `1dbf842` |
| V-12 | Consulta avulsa não gera tarefas | ✅ corrigido | `1dbf842` |
| V-13 | Contagem de novos pacientes | ✅ corrigido | `799c82d` |
| V-14 | Adiantamento contado como venda | ✅ corrigido | `63f87a4` |
| V-15 | Recaptação atribuída ao médico | ✅ corrigido | `1dbf842` |
| V-16 | Remarcação atribuída ao médico | ✅ corrigido | `1dbf842` |
| V-17 | Filtros de tarefas zeram os dados | ✅ corrigido | `2e390ff` |
| V-18 | Valor a receber só traz a prescrição | ✅ corrigido | `be92a38` |
| V-20 | Entrada descontada da prescrição | ✅ corrigido | `be92a38` |
| V-21 | Bloco de indicadores do dashboard | ⚠️ **parcial (4 de 6)** | `799c82d`, `3287cf9` |
| V-22 | Data do recebível por meio de pagamento | ✅ corrigido **e testado ao vivo** | `7eff4cf` |
| V-23 | Mesma data no Fluxo de Caixa | ✅ corrigido | `7eff4cf` |
| V-24 | Plano de contas não carrega | ❌ **bloqueado** | — |
| V-25 | Relatório de Vendas quebrado | ✅ corrigido | `8ad3a15` |
| V-26 | Relatório de Contas a Pagar zerado | ✅ corrigido | `88df535` |
| V-27 | DRE/DFC zerado | ✅ corrigido | `a239dec` |
| V-28A | Datas personalizadas | ✅ corrigido | `8ad3a15` |
| V-28B | Filtros zeram o relatório | ✅ corrigido | `2e390ff` |
| V-29 | Valor orçado errado | ✅ corrigido | `8ad3a15` |

## Os três que não fecharam, e por quê

### V-24 — plano de contas não carrega · **BLOQUEADO, e o Erick vai esbarrar**

O combobox de plano de contas filtra contas de **nível 3**. Se a clínica não
tiver nenhuma conta de nível 3 ativa, ele vem vazio e **o lançamento de despesa
avulsa trava** — que é exatamente o relato.

**Não é bug de código: é pergunta ao banco**, e a consulta que decide leva 30
segundos no SQL editor:

```sql
select level, count(*), bool_or(active) as tem_ativo
from chart_of_accounts
where clinic_id = '<id da clínica>'
group by level order by level;
```

- **Sem linha `level = 3`** → o seed do plano de contas não rodou para essa
  clínica. Correção é SQL, não front.
- **Com linhas nível 3** → aí sim é bug de front, e eu corrijo.

Pedida em 20/08 (A3), repetida em 23/08. **Segue sem resposta.** Enquanto isso,
Contas a Pagar → Novo Lançamento continua travado para quem não tiver o plano
semeado.

### V-21 — dashboard · **parcial: 4 de 6 facetas**

| Faceta | Estado |
|---|---|
| 1. Total de consultas zerado | ✅ corrigido (`799c82d`) |
| 2. Ticket médio por item | ⚠️ o cálculo já é por orçamento fechado, como a D-9 pede. Parecia errado porque a consulta valia zero. **Reconferir** |
| 3. Conversão em 100% | ✅ corrigido (`3287cf9`) — era multiplicação dupla |
| 4. Quadro de ticket médio zerado | ✅ deve cair junto com a faceta 1 |
| 5. Top macro-categorias e top médicos zerados | ⚠️ **não verificado** |
| 6. Gráfico do fluxo de caixa não aparece | ❌ **não reproduzido** |

As facetas 2, 5 e 6 dependem de olhar a tela com dado real. A regra da casa é
não corrigir antes de reproduzir — chutar aqui produz correção que conserta o
que não estava quebrado.

### V-04 — convite de equipe · **código pronto, comportamento não provado**

A edge function foi reescrita e está em produção desde 20/08. Mas **a causa
original nunca foi diagnosticada** — o caminho que falhava foi substituído por
inteiro, então não há como afirmar que a falha não volta por outro motivo.

O reteste são 8 passos e não consome crédito. É o item mais barato da trava e o
único que prova o T017. Pedido em 20/08 (A4), ainda aberto.

## Fora da trava

| Item | Categoria | Estado |
|---|---|---|
| V-19 | atrapalha | ✅ corrigido (`a239dec`) |
| V-03 | backlog | ✅ **corrigido mesmo assim** — conserto de minutos |
| V-02, V-06 | cosmético | ⏸️ **não corrigidos, de propósito** — sem dado nem regra atrás; viram requisito da stack nova pela D-7 |
| V-05, V-07, V-08, V-09 | backlog | ⏸️ requisito da stack nova |
| V-30, V-31 | extras (pedido de feature) | ⏸️ requisito da stack nova |
| **V-32** | achado novo, fora da bateria | ✅ corrigido (`1dbf842`) |

## Placar

| | |
|---|---|
| Corrigidos e enviados | **21 dos 25 bugs** |
| Trava: fechados | **20 de 23** |
| Trava: abertos | **3** — V-24 (bloqueado), V-21 (parcial), V-04 (falta reteste) |
| Deliberadamente fora | 8 (cosméticos + backlog → stack nova) |
| Achados novos corrigidos | 4 — V-32, multiplicação dupla, `tasks.due_date`, e a tabela `revenues` |

**Nenhum item foi provado na tela por mim** — a política de rede deste ambiente
bloqueia `nexclin.lovable.app` (`ERR_TUNNEL_CONNECTION_FAILED` no proxy).
Tudo acima é "código enviado", não "comportamento provado". O roteiro de prova
está em `2026-08-23-roteiro-verificacao.md`.
