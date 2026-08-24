# Implementation Plan: SPEC 004 — corrigir TODOS os apontamentos

**Branch**: `claude/handoff-execution-2026-08-20-im3rpy` · **Data**: 24/08/2026
**Spec**: `spec.md` · **Estado**: `tasks.md` · **Lei**: `.specify/memory/constitution.md` v2.0.0

## Summary

O Arthur mudou a política em 24/08: **corrigir todos os apontamentos restantes,
não só os que travam o uso.** Isso reverte parte da D-7, que mandava não gastar
esforço no que não atravessa para a stack nova.

Este plano cobre os **3 abertos da trava** (V-24, V-21, V-04) e os **8 que
estavam fora de escopo** (V-02, V-05, V-06, V-07, V-08, V-09, V-30, V-31).

## Technical Context

**Alvo**: plataforma Lovable — React 18 + Vite + TypeScript + Supabase
**Canal**: ponte inversa (`docs/ponte/ponte-inversa.md`) · Publish manual do Arthur
**Gate de tipos**: `tsc --noEmit -p tsconfig.app.json` — o build **não** checa tipos
**Vida útil do alvo**: até outubro/2026, quando a stack Next.js substitui
**Restrição dura**: sem acesso ao app publicado a partir deste ambiente
(`ERR_TUNNEL_CONNECTION_FAILED`); nada é provado por mim

---

## Constitution Check

*GATE antes da execução. A constituição vence o plano.*

### ⚠️ Tensão real com o Princípio VII

O Princípio VII (**O Dado Atravessa; a Tela Não**) diz, na faixa C: *"Front,
layout, mensagem? Não corrigir, salvo se impedir o cliente de operar."* A nova
política manda corrigir tudo — inclusive V-02 e V-06, que são mensagens de tela
numa plataforma que morre em outubro.

**Não estou bloqueando o plano**, e a decisão é do Arthur. Mas a constituição
exige que a divergência seja justificada por escrito, então aqui está o custo,
para ser aceito com os olhos abertos:

| | |
|---|---|
| **O que se ganha** | Menos atrito na bateria do Erick; menos apontamento repetido; percepção de produto acabado — e ele é quem vai vender |
| **O que se paga** | Horas em código descartado em outubro; e cada hora aqui é uma hora que não vai para a stack nova, que **não** é descartada |
| **O risco silencioso** | Mexer em tela estável a 8 dias do lançamento introduz regressão onde não havia bug |

**Mitigação adotada:** os itens de faixa C entram **por último e isolados**, em
commit próprio, para que uma regressão neles não contamine o lote financeiro.
E cada um vira também requisito escrito da stack nova — assim o esforço rende
duas vezes.

### Demais princípios

| Princípio | Situação |
|---|---|
| I — Segurança mora no banco | Nada aqui toca RLS. **S-01 e S-04 seguem abertos** e são de prioridade mais alta que qualquer item deste plano |
| II — LGPD | **S-02** (`.env` versionado) segue aberto. Se houver `service_role`, precede tudo |
| III — 15 ModuleKeys | Não afetado |
| IV — Parada humana | Respeitado: nada fecha sem aceite. Todo `[x]` é "enviado", não "provado" |
| V — Segredos / TS estrito | Gate de tipos em todo envio |
| VIII — Uma regra, uma fonte | **Guia deste plano.** Ver Fase 3 |
| IX — Verificação > build verde | Simulação para aritmética; captura para visual; harness com os wrappers reais |

---

## O que falta em cada item

### V-24 — plano de contas não carrega

| | |
|---|---|
| **Causa** | `chart-account-select.tsx:49` filtra `level === 3`. Sem conta analítica ativa, lista vazia |
| **Já feito** | `551bb12` — a lista vazia agora distingue "sua busca não achou" de "não há o que achar", e diz para onde ir. **O beco sem saída acabou** |
| **Falta** | Saber se a clínica tem conta de nível 3 |
| **Quem** | Arthur — SQL editor, 30 segundos |
| **Se não houver nível 3** | Rodar `seed_chart_of_accounts` para a clínica. **SQL, não front** |
| **Se houver** | Bug de query no diálogo. Eu corrijo em minutos |
| **Prova** | Lançar uma despesa avulsa escolhendo uma conta e salvar |

```sql
select level, count(*), bool_or(active) as tem_ativo
from chart_of_accounts where clinic_id = '<id>' group by level order by level;
```

### V-21 — dashboard

| Faceta | Falta | Quem |
|---|---|---|
| 1, 3, 4 | nada — fechadas | — |
| **5. Top macro / top médicos** | **nada — fechada em `551bb12`** | — |
| 2. Ticket médio | Criar 2 orçamentos aprovados (R$ 1.400 e R$ 700) para o mesmo paciente e conferir se dá **R$ 1.050** | Arthur |
| 6. Gráfico do fluxo de caixa | Abrir o bloco com dado no período e reportar saldo, linha visível e nº de pontos | Arthur |

A faceta 5 **saiu da lista de bloqueados hoje**: a causa era a descrição do item
carregando o sufixo de desconto e quebrando a busca do serviço. Achada por
leitura, sem precisar da tela.

### V-04 — convite de equipe

| | |
|---|---|
| **Causa original** | Nunca diagnosticada — mas agora sei **por quê**: `invErr.message` de edge function não-2xx é sempre a string genérica, e o corpo da resposta era descartado |
| **Já feito** | `551bb12` — o corpo é lido antes de desistir. Falha futura volta dizendo o motivo |
| **Falta** | O reteste de 8 passos, com uma pessoa real |
| **Quem** | Arthur — 15 minutos, zero crédito |
| **Prova** | Link de convite → janela anônima → `/nova-senha` → login → **uma única linha** na equipe |

---

## Fases

### Fase 6 — Fechar a trava (prioridade máxima)

Depende só de atos do Arthur. **Nenhum código meu pendente.**

1. Consulta do V-24 → eu executo a correção que ela indicar.
2. Reteste do V-04.
3. Testes 1 e 2 do roteiro → fecham V-21.2 e V-21.6.

### Fase 7 — Anamnese (V-05, V-07, V-08)

O bloco mais coerente: três itens na mesma área, e o **V-07 é a única tela que
o paciente vê** — logo é a única com peso de imagem para fora da clínica.

- **V-05** — especialidade pré-carregada ao escolher o template. Front, pequeno.
- **V-07** — identidade visual da clínica no formulário público. Nome e cor.
  ⚠️ **Cuidado:** é endpoint público. Só pode expor o que já é público — nome e
  identidade visual da clínica, nada de dado operacional (Princípio II,
  minimização).
- **V-08** — copiar respostas / resumo por IA. **Fatiar:** o *copiar* é trivial;
  o *resumo por IA* depende de provedor externo e **não sobrevive à migração**
  (o gateway de IA é do Lovable). Fazer só o copiar; o resumo vira spec própria.

### Fase 8 — Ficha do paciente (V-09)

Canal de entrada e anamnese visíveis na ficha. É agregação de dado que já
existe. Médio.

### Fase 9 — Cosméticos (V-02, V-06)

Mensagem de boas-vindas e de conclusão da anamnese. **Isolados em commit
próprio, por último**, pela mitigação acima.

### Fase 10 — Features pedidas (V-30, V-31)

**Não são bugs — são pedidos de funcionalidade**, e a diferença importa:

- **V-30** — agenda em visão de calendário. É uma tela nova, não um conserto.
- **V-31** — responsável configurável por tipo de atividade. Muda o modelo de
  configuração e **interage com a D-2**, que acabou de fixar responsável único
  por atendimento.

**Recomendação:** estes dois **não** entram antes de 01/09, mesmo com a política
nova. Não por serem faixa C — por serem **escopo novo a 8 dias do lançamento**,
com a bateria do Erick ainda por triar. Se entrarem, entram depois do
congelamento de 29–30/08, o que na prática significa outubro, na stack nova.

---

## Ordem e dependências

```
Fase 6 (Arthur)  ─── independente, pode correr a qualquer momento
      │
      └── V-24 me devolve trabalho conforme o resultado

Fase 7 ──▶ Fase 8 ──▶ Fase 9        (minha fila, nesta ordem)

Fase 10  ── fora da janela, por recomendação
```

**O que decide a ordem:** anamnese antes de ficha do paciente porque o V-07 é a
tela do paciente; cosméticos por último porque são os únicos que podem regredir
sem ninguém notar.

---

## Artefatos de Fase 0 e 1 — por que não existem

O template prevê `research.md`, `data-model.md`, `contracts/` e `quickstart.md`.
**Nenhum se aplica**, e forçá-los seria cerimônia:

| Artefato | Por quê |
|---|---|
| `research.md` | Não há incógnita técnica. As causas estão diagnosticadas item a item em `tasks.md` |
| `data-model.md` | Nenhum item desta política altera schema. As mudanças de modelo estão no **Bloco 8** e são requisito da stack nova, não deste plano |
| `contracts/` | Uma exceção: o **V-07** toca o endpoint público de anamnese, cujo contrato já vive em `specs/002-.../contracts/anamnesis-publica.md`. Atualizar **lá**, na Fase 7 |
| `quickstart.md` | Substituído por `docs/planejamento/roteiro-verificacao-23-08.md`, que já é o guia de validação — com números esperados |

## Re-checagem constitucional pós-desenho

Nenhuma fase toca RLS, permissão ou credencial. A única tensão registrada é a do
Princípio VII, aceita e mitigada acima.

**Uma coisa que este plano não resolve, e é a de maior risco:** S-01, S-02, S-03
e S-04 continuam abertas. São segurança e infraestrutura, não bugs de tela — e
pelo Princípio I e II precedem tudo que está aqui. Corrigir mensagem de
boas-vindas com um `.env` de conteúdo desconhecido versionado é inverter a
prioridade.
