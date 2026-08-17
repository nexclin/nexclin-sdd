---
status: partial
phase: micro-spec-arthur-16-08
source: docs/planejamento/micro-spec-arthur-16-08.md
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
result: blocked
blocked_by: server
reason: |
  Avançou. `npm install` executado (161 pacotes) — o bloqueio do import caiu, e
  o script agora chega à validação de ambiente, falhando com "variável de
  ambiente ausente: SUPABASE_URL". Isso confirma empiricamente o diagnóstico
  do A1, inclusive a mensagem enganosa (a variável real é
  NEXT_PUBLIC_SUPABASE_URL).
  Resta apenas o `.env.local`, que carrega a service_role key e é ato do
  Arthur — a escrita nesse caminho é bloqueada por regra de permissão do
  próprio repositório, de propósito.
  Estado do banco verificado ao vivo em 16/08: plano Trial e saas_settings já
  existem (criados pelas migrações); `superadmin_operators` = 0 e
  `auth.users` = 0, ou seja, o seed nunca rodou.

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
result: partial
reason: |
  **B: PASSA.** Verificado ao vivo em 16/08. O banco é Lovable Cloud
  gerenciado — não aparece no dashboard pessoal do supabase.com (que tem
  apenas o projeto da stack nova, `bfkghwkhzkimzyiovotj`). Aparece em
  lovable.dev → More → Cloud, com Database (45 tabelas), Users (17 signups),
  Edge functions (4), SQL editor, Logs e Usage. **"Export project data" existe
  e está habilitado** (confirmado sem clicar). Backup prévio à janela de
  correção é viável e não custa crédito.
  **A: PENDENTE.** Exige push de teste em `nexclin/nexclin@main`, que altera o
  produto ao vivo — aguarda decisão do Arthur. Instrumento pronto: diff
  conferido (BrandPanel.tsx:77), baseline main@3b8fc94, permissão de push
  confirmada.
  **Dado novo que aumenta o peso de A:** o workspace da Lovable ("Erick's
  Lovable") está no plano **Free com 5 créditos restantes**, reset diário. Se A
  falhar, a fase de correção de bugs esbarra nesse teto quase imediatamente.

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
  Registro completo em docs/seguranca/confirmacao-fase0-2026-08-16.md.
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
passed: 1
partial: 1
issues: 0
pending: 1
blocked: 2

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
