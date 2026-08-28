# Research — SPEC 001 (Phase 0)

Decisões e riscos resolvidos antes do design. Formato: Decisão · Justificativa ·
Alternativas consideradas.

## R1 — Fonte da réplica: irmão read-only `../nexclin-lovable`

- **Decisão:** o export do MVP Lovable vive em `../nexclin-lovable` (pasta irmã,
  somente leitura). As 56 migrações são copiadas dali para `supabase/migrations`
  do repo novo na Fase 1.
- **Justificativa:** decisão 6 da arquitetura ("export vive ao lado"); mantém o
  MVP intocado (constituição, Princípio IV) e separa fisicamente referência de
  produto novo. Já executado (move de `nexclin-main/nexclin-main` → sibling).
- **Alternativas:** manter aninhado (rejeitado — mistura referência com repo
  novo, contraria a decisão 6); reclonar do GitHub (desnecessário, o export
  local já é fiel).

## R2 — Exceção do seed de superadmin sem quebrar o REVOKE posterior

- **Decisão:** ao portar as migrações, **manter** a função
  `seed_superadmin_operator()` e **dropar apenas o trigger**
  `on_auth_user_created_superadmin`. O seed real vira `scripts/seed.ts` (Fase 2),
  dirigido por `SUPERADMIN_EMAIL`.
- **Justificativa:** a migração `20260408034946` cria função + trigger com
  e-mail fixo `erpclinicas@gmail.com`; a migração `20260802073330` (última) faz
  `REVOKE EXECUTE ON FUNCTION public.seed_superadmin_operator()`. Remover a
  função quebraria o REVOKE. Dropar só o trigger neutraliza o comportamento
  indesejado (seed automático por e-mail fixo) e preserva a integridade da
  cadeia de migrações.
- **Como implementar:** acrescentar, no fim da réplica, uma migração nova
  `NNNN_drop_superadmin_seed_trigger.sql` com
  `DROP TRIGGER IF EXISTS on_auth_user_created_superadmin ON auth.users;`
  (não editar as migrações originais — elas são fiéis à referência).
- **Alternativas:** editar a migração original removendo o trigger (rejeitado —
  quebra a fidelidade 1:1 e o anti-drift); remover função + a linha de REVOKE
  (rejeitado — mexe em duas migrações e é mais frágil).

## R3 — `ALTER TYPE ... ADD VALUE` fora de transação

- **Decisão:** aplicar as migrações como estão; o único `ADD VALUE`
  (`app_role ADD VALUE 'user'`) já está isolado em `20260725001410`.
- **Justificativa:** o problema do `ADD VALUE` ocorre quando o novo valor é
  **usado na mesma transação**. Aqui está sozinho no arquivo, sem uso imediato,
  então a CLI aplica sem erro. Só dividir se a CLI reclamar.
- **Alternativas:** pré-dividir defensivamente (desnecessário agora).

## R4 — Cliente Supabase no Next.js (App Router)

- **Decisão:** `@supabase/ssr` com clients separados server/browser; sessão via
  cookies; middleware para refresh. RLS no banco é a fonte de verdade; o front
  só consome `my_permission` / `get_my_subscription_state`.
- **Justificativa:** App Router exige SSR-aware auth; `@supabase/ssr` é o padrão
  atual (substitui o `auth-helpers` legado). Alinha com "segurança mora no
  banco" (Princípio I) — nenhum segredo de decisão no cliente.
- **Alternativas:** `auth-helpers-nextjs` (deprecado); chamar REST direto
  (perde o RLS-aware client e a ergonomia de sessão).

## R5 — E-mail transacional: Resend

- **Decisão:** Resend para convites e reset; integração desenhada na Fase 3/4
  para plugar sem retrabalho, mas a entrega ponta a ponta é reteste
  pós-fundação.
- **Justificativa:** o SMTP embutido do Supabase comprovadamente não entrega
  (registrado no CLAUDE.md). `send_password_reset` continua usando
  `resetPasswordForEmail` do Auth; o provedor de entrega é configurado no
  projeto.
- **Alternativas:** SMTP embutido (rejeitado — não entrega); SendGrid/SES
  (viáveis, mas Resend já é a decisão de periferia — decisão 7).

## R6 — Segredos e service role

- **Decisão:** `.env.local` (gitignored) guarda as 4 variáveis; a
  `SUPABASE_SERVICE_ROLE_KEY` é usada **apenas** por `scripts/seed.ts` e pelas
  edge functions (env do projeto), **nunca** no bundle do app nem no cliente.
- **Justificativa:** Princípio V (segredos fora do código) + regra da decisão 7.
  `.gitignore` já criado blindando `.env*`.
- **Alternativas:** nenhuma aceitável — service role no front é vazamento total.

## R7 — Testes mínimos obrigatórios

- **Decisão:** Vitest para o hook de permissão (unit) e Playwright para os
  guards de rota e o fluxo superadmin/impersonação (e2e).
- **Justificativa:** constituição, Princípio V — o perímetro de acesso é o único
  código com teste obrigatório. Reaproveita o setup de Playwright/Vitest que já
  existe na referência.
- **Alternativas:** só e2e (perde granularidade da cascata de permissão); sem
  testes (viola a constituição).

## Itens sem NEEDS CLARIFICATION remanescente

Todos os desconhecidos técnicos do plano foram resolvidos acima. Pendências
restantes (projeto Supabase novo, `.env.local`, CLI, git) são **pré-requisitos
operacionais de Arthur**, não incógnitas de design — bloqueiam a execução da
Fase 1, não este plano.
