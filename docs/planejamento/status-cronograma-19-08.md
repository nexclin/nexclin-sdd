# Pente fino do cronograma — estado em 19/08/2026

> **Fonte:** `NexClin _ Plano até o Lançamento.html` (13/08) — seções 03
> (cronograma até 01/09) e 10 (as 15 tarefas vencidas com prazo novo, os 4
> itens que saíram do caminho crítico e os 7 que faltavam no plano).
> **Método:** cada linha abaixo só é marcada como feita se existe **evidência
> verificável neste repositório** — arquivo, commit ou registro datado. Onde a
> tarefa é de sócio e não deixa rastro aqui, está escrito *sem registro no
> repositório* — que não é o mesmo que "não feita".
> **Corte:** 19/08/2026. Faltam **13 dias** para o lançamento.

---

## 1. Feito, com evidência

| Tarefa (origem no plano) | Prazo | Evidência |
|---|---|---|
| Rodar as duas verificações da seção 08 | 16/08 · Arthur | [verificacoes-tecnicas-16-08.md](verificacoes-tecnicas-16-08.md) — **as duas passam**: correção pela ponte custa R$ 0 e o banco do Lovable tem *Export project data* |
| Destravar a carga inicial | 16/08 · Arthur | commit `86a66d3` (senha aleatória de 74 chars estourava o limite de 72 do GoTrue) + `specs/001-fundacao-superadmin/tasks.md` T011: **seed rodado 2× em 18/08 sem duplicar** |
| Criar acesso superadmin | 16/08 · Arthur | tasks.md T009/T011 — usuário em `auth.users` + `superadmin_operators` na stack nova. **Ressalva:** T012 (senha real por recovery) segue pendente — `last_sign_in_at` nunca preenchido |
| Publicar a fila de especificações | 23/08 · Arthur | [fila-especificacoes.md](fila-especificacoes.md), commit `f1539d0` — entregue em 18/08, **5 dias antes** |
| Preços aprovados viram configuração | 14/08 · Arthur | [precos-viram-configuracao.md](precos-viram-configuracao.md) — 3 planos criados no banco do Lovable, `trial_days=30`, `max_users` 3/5/8. **Ainda `hidden`** (ver §2) |
| Fechar planos e preços | 13/08 · Erick | tabela aprovada: Essencial R$ 249 / Clínica R$ 399 / Corpo Clínico R$ 599; anual = 11 meses |
| Planilha de apontamentos distribuída | 14/08 · Arthur | **substituída pelo Notion** — base *Apontamentos*, uma página por rodada. Materiais: [bateria-testes-vinicius-17-21.md](bateria-testes-vinicius-17-21.md), [guia-bateria-vinicius.html](guia-bateria-vinicius.html), [vinicius-orientacao.txt](vinicius-orientacao.txt), skill `nx-apontamento` |
| Bateria de testes do Vinícius | 17–21/08 · Vinícius | **em andamento** — roteiro dia a dia, guia visual e canal de registro entregues; vídeo de 2min30 (16/08) ensina o clone + Claude Code na pasta |
| Auditoria de RLS nas duas plataformas | extra | [auditoria-rls-2026-08-17.md](../seguranca/auditoria-rls-2026-08-17.md) — 44 tabelas em cada banco, zero sem RLS, zero policy `anon`, âncora ativa nos dois |
| Fase 0 da SPEC 002 confirmada ao vivo | extra | [confirmacao-fase0-2026-08-16.md](../seguranca/confirmacao-fase0-2026-08-16.md) — Achado 1 corrigido, Achado 2 vivo |

---

## 2. Escrito, mas **ainda não aplicado em produção**

Três SQLs estão prontos e revisados no repositório e **não rodam daqui** — este
repositório aponta para o Supabase da stack nova. Cada um precisa ser colado no
SQL editor do Lovable Cloud, **com export do banco antes** (não há PITR nesse
tier). É trabalho de minutos, mas é a mão do Arthur.

| O que | Arquivo | Efeito de não fazer |
|---|---|---|
| Publicar os 3 planos (`hidden` → `public`) e mapear a Onda 1 em 10 ModuleKeys | [`scripts/lovable/onda1-publicar-planos.sql`](../../scripts/lovable/onda1-publicar-planos.sql) | **em 01/09 não há plano visível para assinar** |
| Trial padrão 14 → 30 dias (`saas_settings`) | mesmo arquivo | toda clínica nova nasce com trial errado |
| `WITH CHECK` na policy de UPDATE de `profiles` | [`scripts/lovable/endurece-profiles-with-check.sql`](../../scripts/lovable/endurece-profiles-with-check.sql) | a âncora multi-tenant fica apoiada só no trigger, sem a segunda camada |
| Publicar o `v2.4.3` (*Publish → Update* no editor) | — | site publicado segue em `v2.4.2`, resíduo do teste da ponte |

> "Definir o que o plano inaugural libera" tem prazo **20/08 — amanhã**. O
> mapeamento já está decidido (10 chaves: dashboard, leads, pacientes, anamnese,
> consultas, acompanhamento, tarefas, contas_receber, configuracoes, equipe); o
> que falta é executar.

---

## 3. Não feito — dos sócios, sem registro no repositório

| Tarefa | Quem | Prazo novo | Situação |
|---|---|---|---|
| Cláusulas 9 e 9.2 do contrato de uso e dos termos | Todos | **18/08** | **vencida ontem**, sem registro |
| Fechar contrato societário | Todos | 20/08 | amanhã, sem registro |
| Novo contato com o grupo inaugural | Vinícius | **18/08** | **vencida ontem**, sem registro |
| Criar Instagram e LinkedIn da marca | Erick | 25/08 | no prazo |
| Abrir conta para movimentação | Erick | 26/08 | no prazo — **sem ela não há como cobrar em 01/09** |
| Criar apresentação comercial | Erick | 28/08 | no prazo |
| Bateria de testes de experiência | Erick | 24–26/08 | no prazo, depende da correção de 22–23/08 |
| Definir canal e tempo de resposta do suporte | Todos | sem data | **sem data e sem dono** — é o item mais órfão do plano |
| Quantas clínicas entram no grupo inaugural, e quais | Todos | sem data | continua em aberto desde 13/08 |

---

## 4. Não feito — do Arthur, com prazo à frente

| Tarefa | Prazo | Situação |
|---|---|---|
| Janela de correção: bugs da bateria do Vinícius | 22–23/08 | depende do que sair até 21/08 |
| SPEC 002 Fase 2 — trilha de auditoria (Achado 2) | 22–23/08 | quebra pronta em `specs/002-.../tasks.md`; **T004 é gate: exportar o banco antes** |
| `invite-team-user` aceita `password` do cliente, **em produção** | 22–23/08 | viola a regra "nenhum caminho define senha de terceiro" |
| T021 da SPEC 001 — testes de permissão em Vitest | — | **em zero**; é mínimo obrigatório da constituição |
| Criar tutorial em vídeo (do cliente) | 27/08 | não iniciado — o vídeo de 16/08 é o onboarding do Vinícius, não este |
| Criar base de conhecimento e FAQ | 28/08 | não iniciado |
| Criar grupo de WhatsApp de suporte | 28/08 | não iniciado |
| 2ª leva de correção + congelamento | 29–30/08 | — |
| Ensaio de onboarding com clínica fictícia | 31/08 | — |
| Ligar o Supabase Pro | 01/09 | no dia do primeiro cliente — backup diário; o tier atual não tem |
| Escrever e ensaiar o plano de cópia de dados | 30/09 | **não existe** nenhum rascunho no repositório |

---

## 5. Decisões ainda abertas que têm data

- **`public_token` da anamnese (T002 da SPEC 002)** — hoje o `id` da resposta
  serve de credencial. Trocar antes de 01/09 **ou** virar backlog com data. O
  risco real é vazamento de link: chave primária não rotaciona nem expira.
- **"Build unsuccessful"** marcado no editor da Lovable apesar de o deploy
  funcionar — reconferir antes da janela de 22/08.
- **`npm audit`** — 1 crítica e 5 altas, incluindo `next`. `--force` sobe major;
  fica para depois de 01/09.

---

## 6. Fora do caminho crítico (confirmado na seção 10)

Controle de vendas interno no painel (vira o Notion por enquanto) · roadmap de
versão 2 e 3 (30/09) · depoimentos em vídeo (15/10) · registro de marca (corre
em paralelo, não trava o lançamento).

---

## 7. A leitura em uma linha

O que depende de **código** está adiantado — a fila de especificações chegou 5
dias antes, a auditoria de RLS não achou buraco de isolamento e a ponte de
correção custa zero. O que trava o lançamento hoje não é técnico: são **quatro
execuções de minutos no banco do Lovable** (§2), **duas tarefas de sócio já
vencidas** (§3) e **um canal de suporte sem dono**.
