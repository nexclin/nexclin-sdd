# Calendário até o lançamento — quem faz o quê

**Corte:** 20/08/2026 · **Critério que decide o escopo:** `CLAUDE.md` §2.5 —
corrigir só o que atravessa para a stack Next.js.

Duas colunas porque há dois tipos de trabalho que não se substituem: o que
**só o Arthur pode fazer** (navegador logado, decisão, ato manual) e o que
**o Claude faz** (código, migração, documento).

---

## HOJE — 20/08

### Arthur

| # | Tarefa | Tempo | Por que agora |
|---|---|---|---|
| A1 | Mover o export para `C:\Users\ahifr\NexClin-Backups\`, tirar o `sha256sum`, subir cópia para nuvem | 5 min | Sem a cópia em nuvem, se o Cloud da Lovable for desabilitado o dump some. |
| A2 | Enviar as 4 perguntas ao Vinícius — texto pronto em `perguntas-vinicius-20-08.md` | 2 min | **É o gargalo.** V-13, V-21 e V-29 não andam sem resposta, e depois de 21/08 não cabe na janela. |
| A3 | Rodar no SQL editor a consulta do V-24 (está na triagem, seção c-2) | 2 min | Decide sozinha se V-24 é faixa A (corrigir) ou C (descartar). |
| A4 | **Reteste do convite de equipe** — convidar alguém, abrir o link, definir senha, entrar | 15 min | Item mais barato da trava: fecha sem uma linha de código. E prova o T017, que hoje é código lido, não comportamento provado. |

### Claude
- Aguardando A2 e A3 para destravar os itens correspondentes.
- Pode começar já: **V-22/V-23** — regra de data do recebível + configuração
  "antecipa crédito?". Faixa A, e pela investigação derruba **três** itens
  (V-22, V-23 e provavelmente V-26/V-27).

---

## 21/08 — último dia da bateria do Vinícius

### Arthur
| # | Tarefa | Por que |
|---|---|---|
| A5 | Cobrar a resposta do Vinícius se não vier | Sem ela a spec da stack nova nasce com buraco. |
| A6 | **Disparar novo export do banco** | O de hoje envelhece. É 1 a cada 24h — disparando em 21, você tem ponto de retorno fresco para as escritas de 22–23. |

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

- **Os 13 itens de faixa B** (dashboard, atribuição de tarefa, financeiro,
  relatórios). A regra está escrita e datada na triagem; vira critério de
  aceite na stack nova. Não se implementa na Lovable.
- **A faixa C inteira** (scroll, mensagens, botão de ver senha, filtros). Vira
  requisito da stack nova.
- **Zerar a trava de lançamento antes de abrir.** Era a D-1, revogada pela D-7.
  A plataforma vive um mês; não precisa ser perfeita, precisa deixar o fundador
  operar.

## O caminho crítico, em uma linha

**A2 é o gargalo de hoje** — sem a resposta do Vinícius, três itens da trava não
andam. **A6 é o gargalo de 22/08** — sem export fresco, a Fase 2 da SPEC 002 não
começa. **A11 é o gargalo do lançamento** — sem conta para movimentação, não há
como cobrar em 01/09.
