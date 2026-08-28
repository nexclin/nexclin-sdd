---
status: partial
phase: micro-spec-arthur-16-08
source: 2026-08-16-micro-spec-arthur.md
started: 2026-08-16T21:05:00Z
updated: 2026-08-17T01:50:00Z
---

## Current Test

number: 5
name: A5 — Rascunho do aviso ao Vinícius
expected: |
  O rascunho cobre os três não-bugs e a orientação de clínica nova, e Arthur
  aprova como claro e pronto para enviar.
awaiting: user response

## Tests

### 1. A1 — Seed roda 2x sem duplicar
expected: |
  `npm run seed` executado duas vezes seguidas: plano Trial único,
  `saas_settings` singleton intacto, um único `superadmin_operators`.
  O uuid do plano é o mesmo nas duas rodadas.
result: pass
reason: |
  Executado em 17/08. O seed rodou duas vezes seguidas com sucesso, e as
  contagens provam a idempotência:
    planos com is_default_trial = 1
    linhas em saas_settings     = 1
    linhas em superadmin_operators = 1
    usuários auth com o e-mail do superadmin = 1
  O uuid do plano Trial foi o mesmo nas duas rodadas
  (7e96eaca-57be-46e9-9add-a3f556791df7). O operador nasceu como super_owner,
  active = true, casado com o usuário auth e com e-mail confirmado.

  Três bloqueios foram derrubados nesta ordem, e nenhum era o que a micro-spec
  supunha:
  1. `npm install` nunca havia rodado — o script morria no import.
  2. `.env.local` ausente e, depois, com o nome da variável duplicado dentro do
     valor da service_role key.
  3. **Bug real no seed**: a senha aleatória tinha 74 caracteres (dois UUIDs
     concatenados) e o GoTrue trunca em 72, respondendo 500 com corpo vazio.
     Diagnóstico isolado por bisseção: 18 e 72 caracteres passam, 74 falha.
     Corrigido em scripts/seed.ts para um UUID + sufixo (40 caracteres), com
     comentário para ninguém reintroduzir.

### 2. A2 — Login superadmin funciona e usuário comum é negado
expected: |
  Login em /superadmin/login entra no painel; usuário comum autenticado
  invocando rota/endpoint de superadmin é negado pelo banco.
result: blocked
blocked_by: prior-phase
reason: |
  Confirmado ao vivo que não existe operador nem usuário auth no projeto da
  stack nova (`superadmin_operators` = 0, `auth.users` = 0). Depende de A1.
  Bloqueio estrutural adicional que não é só execução: não há tela para
  concluir o reset de senha (T019, Fase 4, aberta) e a entrega de e-mail não
  está resolvida. Definir senha por código é proibido.
  Verificado por leitura: o guard é server-side (RPC is_superadmin em
  app/superadmin/(panel)/layout.tsx:27-33) e a negação mora em RLS.

### 3. A3 — Texto trivial publica sem crédito; projeto aparece no painel
expected: |
  (A) bump v2.4.1 → v2.4.2 chega ao editor E ao site publicado, com saldo de
  crédito idêntico antes e depois. (B) O projeto aparece no painel do provedor
  que hospeda o banco, com exportação possível.
result: pass
reason: |
  Ambas executadas ao vivo em 16/08 — registro completo em
  2026-08-16-verificacoes-tecnicas.md.
  **A: PASSA** pelas três condições. Commit f8b8578 chegou íntegro ao editor
  (diff conferido no próprio editor: BrandPanel.tsx:77, v2.4.1 → v2.4.2), o
  site publicado passou a exibir V2.4.2 após clique manual em Publish → Update,
  e o crédito ficou em 5 antes e 5 depois — zero consumo.
  **B: PASSA.** O banco é Lovable Cloud gerenciado — não aparece no dashboard
  do supabase.com (que só tem o projeto da stack nova). Aparece em
  lovable.dev → More → Cloud, com Database (45 tabelas), Users (17 signups),
  Edge functions (4), SQL editor e **"Export project data" habilitado**
  (confirmado sem clicar).
  **Canal de correção decidido:** código por commit+push, banco por SQL editor
  do Cloud. Os dois de graça. O chat da Lovable vira último recurso — o que
  importa porque o workspace está no plano Free com 5 créditos diários.
  **Duas ressalvas registradas:** a publicação não é automática (exige o clique
  de Update, que precisa entrar no procedimento de correção); e o editor marcou
  o commit como "Build unsuccessful / Preview is out of date" apesar de o diff
  ter chegado íntegro e o site publicado estar correto e funcional. Não
  determinei se é só o sandbox de preview. Reconferir antes de 22/08.

### 4. A4 — Registro em docs/seguranca/ com Achado 1 e 2 vivo/corrigido
expected: |
  Página em docs/seguranca/ registrando se o Achado 1 e o Achado 2 seguem
  vivos no banco ao vivo, mais o canal de correção. Nada além de leitura.
result: pass
reason: |
  Executado no SQL editor do Lovable Cloud em 16/08, ~22h40, somente leitura.
  **Achado 1: CORRIGIDO** — a query de policies `anon` retornou "No rows
  returned" para todo o schema public. Sem drift: bate com a migração
  20260723211722, que derruba as três policies.
  **Achado 2: VIVO** — `patients.deleted_at` ausente e `data_audit_log` NULL.
  **Canal de correção** registrado (B passa; A pendente).
  Registro completo em 2026-08-16-confirmacao-fase0.md.
  O gap apontado na revisão (falta do caso de drift no guia) foi resolvido
  pelo próprio resultado e está documentado.

### 5. A5 — Rascunho cobre os 3 não-bugs + orientação de dados
expected: |
  O rascunho cobre os três não-bugs e a orientação de clínica nova, e Arthur
  aprova como claro e pronto para enviar.
result: [pending]
reason: |
  Primeira metade verificada: os três não-bugs estão cobertos e as descrições
  batem com INVENTARIO-UI.md (D2:249, D8:263, D3:251). Falta a aprovação do
  Arthur, que é o critério.

## Summary

total: 5
passed: 3
issues: 0
pending: 1
blocked: 1

## Executado fora dos cinco itens (autorizado pelo Arthur em 16/08)

- **Preços viraram configuração** (tarefa de 14/08 do cronograma). Três planos
  criados no banco ao vivo com `visibility='hidden'`, via SQL editor do Cloud:
  Essencial 3 usuários (R$ 249 / R$ 2.490), Clínica 5 usuários (R$ 399 /
  R$ 3.990), Corpo Clínico 8 usuários (R$ 599 / R$ 5.990) — todos com
  trial_days=30, os 15 módulos ligados e max_users 3/5/8. O `Trial Padrão`
  original não foi tocado.
  **Dois pontos que dependem de decisão de sócio:** o preço anual foi derivado
  da recomendação da pesquisa ("anual com 2 meses de desconto" = mensal × 10) e
  não de aprovação formal; e os planos seguem ocultos porque a tabela tem
  aprovação marcada para 18/08. Publicar é trocar `visibility` para `public`.
  **Não alterado:** a duração padrão de trial em saas_settings segue em 14 dias.
  Mudar para 30 afeta todo cadastro novo — inclusive a clínica que o Vinícius
  vai criar amanhã — então ficou para decisão explícita.

## Gaps

<!-- O gap do A4 (caso de drift ausente no guia de interpretação) foi
     RESOLVIDO: a execução ao vivo mostrou zero policies anon, confirmando que
     não há drift entre as migrações versionadas e o banco do Lovable. O
     documento de segurança registra o achado e o contexto. -->

## Fora do escopo dos cinco itens (registrado, não corrigido)

- `supabase/functions/invite-team-user/index.ts:47-51,66-75` aceita `password`
  do cliente e cria usuário com ela — um admin define a senha de outra pessoa.
  Viola a regra (e) do CLAUDE.md e `.claude/rules/banco.md`. Agravante: a única
  guarda é bearer válido, sem checagem de `my_permission('equipe')`.
  Levantado por A2, confirmado por leitura direta. Tarefa separada.
- 9 vulnerabilidades no `npm audit` após o install (1 crítica em `vitest`, 5
  altas incluindo `next`). As de vitest/vite são dependências de
  desenvolvimento. Não tratadas: `npm audit fix --force` sobe versão major e
  quebraria a fundação na véspera da bateria.
