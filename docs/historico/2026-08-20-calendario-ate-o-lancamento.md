# Calendário até o lançamento — quem faz o quê

**Corte:** 20/08/2026, revisado no fim do dia · **Critério:** `CLAUDE.md` §2.5.

> **Revisão de 20/08, fim do dia.** O Vinícius respondeu as quatro perguntas e
> mandou um áudio que inverte a prioridade: o time dele **não usa o dashboard**,
> puxa as bases pelos **relatórios**, semanalmente. Relatórios passaram a ser o
> que precisa funcionar em 01/09; dashboard desceu. Ver D-8 na triagem.
>
> **A2 saiu da lista** — as perguntas foram respondidas e nenhum item ficou
> bloqueado por dependência externa.

Duas colunas porque há dois tipos de trabalho que não se substituem: o que
**só o Arthur pode fazer** (navegador logado, decisão, ato manual) e o que
**o Claude faz** (código, migração, documento).

---

## HOJE — 20/08

### Arthur

| # | Tarefa | Tempo | Por que agora |
|---|---|---|---|
| A1 | Mover o export para `C:\Users\ahifr\NexClin-Backups\`, tirar o `sha256sum`, subir cópia para nuvem | 5 min | Sem a cópia em nuvem, se o Cloud da Lovable for desabilitado o dump some. |
| ~~A2~~ | ~~Enviar as 4 perguntas ao Vinícius~~ | — | ✅ **Feito.** Respondidas no mesmo dia, sem nenhum item restando em `precisa-decisao`. |
| A3 | Rodar no SQL editor a consulta do V-24 (está na triagem, seção c-2) | 2 min | Decide sozinha se V-24 é faixa A (corrigir) ou C (descartar). |
| A4 | **Reteste do convite de equipe** — convidar alguém, abrir o link, definir senha, entrar | 15 min | Item mais barato da trava: fecha sem uma linha de código. E prova o T017, que hoje é código lido, não comportamento provado. |

### Claude
- **V-22/V-23** — regra de data do recebível + configuração "antecipa crédito?".
  Continua sendo o item nº 1, agora por dois motivos: é faixa A, e o Vinícius
  disse que *"se as **bases de dados** estão erradas, os relatórios vêm
  errados"*. Data de recebível é base de dados.
- Aguardando só **A3** (a consulta do V-24).

**Nova ordem dos relatórios, que agora são obrigatórios em 01/09 (D-8):**

| Ordem | Item | Por quê |
|---|---|---|
| 1 | V-22/V-23 | Pré-requisito. Base errada ⇒ relatório errado. |
| 2 | V-17 + V-28B | **São o mesmo bug** — filtro de data (D-11). Duas telas, uma correção. Suspeito: os três vocabulários de período registrados em `../referencia/INVENTARIO-UI.md §5`. |
| 3 | V-26 + V-27 | Prováveis sintomas do V-22; reconferir depois dele. |
| 4 | V-29 | Separar valor orçado de valor fechado (D-12). |
| 5 | V-25 | Relatório de vendas linha por item, com as 9 colunas (D-10). O maior dos relatórios. |
| 6 | V-28A | Datas personalizadas. |

**Rebaixados:** V-13 e V-21 (dashboard). A regra está escrita; a implementação
espera a stack nova.

---

## 21/08 — último dia da bateria do Vinícius

### Arthur
| # | Tarefa | Por que |
|---|---|---|
| ~~A5~~ | ~~Cobrar a resposta do Vinícius~~ | ✅ Respondeu em 20/08. |
| A5b | Encerrar a bateria e mandar o que aparecer no dia | Último dia dele. |
| A6 | **Disparar novo export do banco** — a tela fica em `More → Cloud → Overview → Advanced settings → Export data` | O último é de **18/08**. Não é urgente hoje (o que se perderia é dado de teste), mas em 22/08, minutos antes das escritas da Fase 2, é o que evita perder tudo que os testes produziram. ⚠️ Logo abaixo do botão estão "Pause Cloud" e **"Remove Lovable Cloud"** — este apaga o banco. |

### Claude
- Fechar V-22/V-23.
- Preparar as migrações da **Fase 2 da SPEC 002** (T005–T009) prontas para
  aplicar, sem aplicar.

---

## 22–23/08 — janela de correção

> **A Fase 2 da SPEC 002 tem prioridade sobre a bateria.** É banco puro
> (`data_audit_log`, trigger, `deleted_at`, policies) e o T014 já prevê o
> backport como migração versionada — atravessa 100%.

### Arthur
| # | Tarefa | Por que |
|---|---|---|
| A7 | Confirmar que o export de 21/08 chegou por e-mail **antes** de qualquer escrita | T004 é gate absoluto. Sem o arquivo na mão, nada começa. |
| A8 | **Publish na Lovable** a cada correção que eu enviar | Só você tem sessão. Não existe CLI. |
| A9 | Aceite manual de cada correção | "Implementado ≠ funciona" (Princípio IV). |

### Claude
- SPEC 002 Fase 2: T005 → T009.
- Bateria, faixa A: V-04B (linha órfã em `team_members`), V-24 se A3 apontar
  banco, e o que a resposta do Vinícius destravar.
- **Ordem obrigatória:** function antes do Publish do front. Foi o erro de
  20/08; está em `ponte-inversa.md`.

---

## 24–26/08 — bateria do Erick

### Arthur
| # | Tarefa |
|---|---|
| A10 | Rodar a bateria e registrar no formato de sempre (onde / o que fiz / o que aconteceu / o que esperava) |
| A11 | Abrir conta para movimentação — **sem ela não há como cobrar** |
| A12 | Apresentação comercial |
| A13 | **Definir canal e tempo de resposta do suporte** — está sem dono e sem data desde 13/08 |

### Claude
- Triar a leva do Erick no mesmo documento (numeração `E-01` já reservada).
- Continuar faixa A.

---

## 27–28/08 — material do cliente

### Arthur
| # | Tarefa |
|---|---|
| A14 | Tutorial em vídeo (27/08) — o vídeo de 16/08 é o onboarding do Vinícius, não este |
| A15 | Base de conhecimento e FAQ (28/08) |
| A16 | Grupo de WhatsApp de suporte (28/08) |

### Claude
- 2ª leva de correção da faixa A.

---

## 29–31/08 — congelamento e ensaio

### Arthur
| # | Tarefa |
|---|---|
| A17 | Aceite da 2ª leva + **congelamento** (29–30/08) |
| A18 | Ensaio de onboarding com clínica fictícia (31/08) |
| A19 | **T012** — definir a senha do superadmin via recovery. Pendente desde a Fase 2; o superadmin nunca logou |

### Claude
- Nada novo entra. Só o que o ensaio de A18 revelar como impeditivo.

---

## 01/09 — abertura

### Arthur
| # | Tarefa | Por que |
|---|---|---|
| A20 | **Ligar o Supabase Pro no mesmo dia** | O tier atual não tem backup diário e pausa em 7 dias de inatividade. Com dado de saúde real, isso não é opcional. |
| A21 | Apontar o domínio | |

---

## Depois de 01/09 — registrado para não sumir

| Item | Prazo | Dono |
|---|---|---|
| **LTV por paciente** — requisito novo, não veio de bug. Soma das compras do mesmo paciente no período. Pedido pelo Vinícius em 20/08 | stack nova | Claude, precisa de spec |
| **Dashboard** (V-13, V-21) — ticket médio por orçamento aprovado, contagem de novos pacientes | stack nova | Claude, regra já escrita (D-9) |
| Financeiro em dois blocos (consulta e prescrição com pagamento próprio) | backlog imediato | Claude, precisa de spec |
| `public_token` da anamnese (T002/T003 da SPEC 002) | decisão datada | Arthur decide |
| `npm audit` — 1 crítica, 5 altas, inclui `next` (`--force` sobe major) | pós-01/09 | Claude |
| **T027 — e2e da cascata de permissão em Playwright** | sem data | Claude |
| **T020 — guards `ProtectedRoute`, `RequirePermission`, `OnboardingGuard`** | sem data | Claude |
| Plano de cópia de dados Lovable → stack nova | 30/09 | Claude, não existe rascunho |
| Stack Next.js substitui a plataforma | outubro | — |

---

## O que NÃO vai ser feito, de propósito

Registrado para ninguém cobrar depois achando que foi esquecido:

- **Faixa B — dashboard, atribuição de tarefa, financeiro.** A regra está
  escrita e datada na triagem; vira critério de aceite na stack nova.
  **Relatórios saíram desta lista** pela D-8: o time do Vinícius opera por eles,
  então têm de funcionar em 01/09.
- **Faixa C** — scroll da lista de especialidades, mensagens de boas-vindas e
  conclusão, botão de ver senha. Vira requisito da stack nova.
  **Os filtros também saíram daqui**: V-17 e V-28B são o mesmo bug de data
  (D-11) e batem direto no relatório, que agora é obrigatório.
- **Zerar a trava de lançamento antes de abrir.** Era a D-1, revogada pela D-7.
  A plataforma vive um mês; não precisa ser perfeita, precisa deixar o fundador
  operar.

## O caminho crítico, em uma linha

**A2 saiu — o Vinícius respondeu no mesmo dia.** O gargalo de hoje virou **A4**
(reteste do convite) e **A3** (a consulta do V-24). **A6 é o gargalo de 22/08** — sem export fresco, a Fase 2 da SPEC 002 não
começa. **A11 é o gargalo do lançamento** — sem conta para movimentação, não há
como cobrar em 01/09.
