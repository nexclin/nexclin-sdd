# SPEC 002 — Segurança: anamnese pública e auditoria de dado de paciente

> **Status:** proposta · **Executor:** Claude Code · **Aprovador:** Arthur Hideo
> **Origem:** `docs/seguranca/revisao-2026-08-16.md` (Achados 1 e 2)
> **Contexto permanente:** `CLAUDE.md` · **Lei:** `.specify/memory/constitution.md`
> **Método:** SDD — plano por fases, PARADA para aprovação humana antes de cada
> fase; nenhuma fase fecha sem os critérios de aceite executados por Arthur.

---

## OBJETIVO

Fechar duas exposições de dado de saúde encontradas na revisão de 16/08, na
plataforma que recebe os primeiros clientes em 01/09, e garantir que a stack
nova não as herde:

- **Achado 1 (TRAVA):** `anon ... USING(true)` em `anamnesis_responses` e
  `anamnesis_config` permite que qualquer um, só com a chave anon pública, leia
  e adultere anamnese de qualquer paciente de qualquer clínica.
- **Achado 2 (ALTO/LGPD):** ação sobre `patients` não deixa rastro — sem
  `data_audit_log`, sem soft delete, sem atribuição de quem/quando.

**Alvo primário:** a plataforma Lovable ao vivo (projeto `xbnffervqqphgsyeffdz`),
porque é onde o risco corre e onde o cliente entra. **Alvo secundário:** as
migrações deste repositório, para a stack nova nascer limpa.

## POR QUE ESTA SPEC EXISTE ANTES DA STACK NOVA

O lançamento é na plataforma Lovable. O Achado 1 é dado de saúde legível por
qualquer pessoa na internet, a duas semanas de receber pagantes. Corrigir a
stack nova (sem prazo) não protege o cliente que entra em 01/09. Por isso esta
spec trata primeiro o que está no ar.

---

## PRÉ-REQUISITOS

- Acesso ao projeto Lovable (`lovable.dev/projects/09bc3d2d…`) e ao seu SQL.
- Decisão registrada sobre o **canal de correção sem crédito** (Verificação A
  do plano de lançamento — sincronização de mão dupla do repositório
  `nexclin-lovable`). Se não confirmada, a correção vai pelo chat do Lovable e
  consome crédito; isso muda o custo e deve ser dito aos sócios.
- Backup exportado antes de qualquer alteração (Cloud → Advanced → Export),
  já que o tier atual não tem PITR.

---

## FASE 0 — CONFIRMAR AO VIVO (nada se corrige sem isto)

As migrações auditadas são réplica portada; o banco ao vivo pode ter divergido
com as correções recentes do scanner. Antes de tratar como tarefa, confirmar.

1. Rodar, no SQL do Lovable (leitura pura):

   ```sql
   -- Achado 1: acesso anônimo às tabelas de anamnese ainda existe?
   select tablename, policyname, cmd, qual, with_check
   from pg_policies
   where schemaname = 'public' and 'anon' = any(roles) order by tablename;

   -- Achado 2: há auditoria/soft-delete em patients?
   select column_name from information_schema.columns
   where table_name = 'patients' and column_name = 'deleted_at';
   select to_regclass('public.data_audit_log') as tem_audit_log;
   ```

2. Rodar a Verificação A (mudar um texto trivial via repositório e conferir se
   publica) para saber o canal de correção.
3. **Verificação da fase:** relatório curto de uma página — cada achado
   confirmado vivo ou já corrigido, e qual o canal de correção. Se ambos já
   estiverem corrigidos ao vivo, a spec se encerra aqui com esse registro.

## FASE 1 — ACHADO 1: anamnese pública por token (TRAVA)

A intenção do `anon` é legítima (o formulário público é preenchido sem login);
o erro é o escopo `USING(true)`. A correção troca "acesso por id adivinhável"
por "acesso por token de uso único", sem quebrar o formulário.

1. Migração: adicionar a `anamnesis_responses` uma coluna
   `public_token uuid not null default gen_random_uuid()`, com índice único. O
   link público passa a ser `/anamnese-publica/:public_token`, nunca `:id`.
2. Mover o acesso anônimo para uma **Edge Function** com service role que:
   - recebe o token, valida, e devolve **apenas** aquela resposta + a config do
     formulário (sem expor `patient_id`/`clinic_id` de outras linhas);
   - grava a submissão validando `status != 'preenchido'`, e marca
     `status = 'preenchido'` ao concluir (token deixa de servir).
3. **Remover** as três policies `anon` de `anamnesis_responses` e
   `anamnesis_config`. Nenhum acesso anônimo direto à tabela permanece.
4. Ajustar o front do formulário público para consumir a edge function.
5. **Verificação:** (a) as queries da Fase 0 não retornam mais policy `anon`
   com `qual = true`; (b) `GET` anônimo direto na tabela retorna vazio/negado;
   (c) o formulário público abre por token, preenche e envia ponta a ponta; (d)
   token já preenchido não permite reabrir nem sobrescrever.

## FASE 2 — ACHADO 2: rastro em dado de paciente

1. Migração: tabela `data_audit_log` (quem `auth.uid()`, quando, tabela, ação,
   `clinic_id`, estado anterior completo em jsonb) com RLS — leitura só para
   admin da própria clínica e superadmin.
2. Trigger `AFTER INSERT/UPDATE/DELETE` em `patients` gravando em
   `data_audit_log`. O estado anterior completo permite reconstruir a linha.
3. Soft delete: coluna `deleted_at` em `patients`; a exclusão do app vira
   `update ... set deleted_at = now()`, e as leituras filtram `deleted_at is null`.
   RLS e políticas ajustadas para não vazar linha "apagada".
4. **Verificação:** (a) apagar um paciente de teste deixa registro com autor,
   hora e estado anterior; (b) o paciente some das listas mas a linha existe
   com `deleted_at`; (c) a reconstrução a partir do log devolve os dados
   originais; (d) usuário de outra clínica não lê o `data_audit_log`.

> Escopo consciente: esta fase cobre `patients`. Estender a auditoria a outras
> tabelas sensíveis (consultas, recebíveis, anamnese) é backlog explícito, com
> a mesma mecânica — não entra agora para não competir com a trava.

## FASE 3 — BACKPORT PARA A STACK NOVA

1. As mesmas correções das Fases 1 e 2, como **migrações versionadas** em
   `supabase/migrations` deste repositório — para a stack nova nascer sem a
   dívida. Não copiar à mão do Lovable: reescrever com nome e ordem deste repo,
   registrando no commit de qual correção veio.
2. **Verificação:** o hook `guarda-constituicao` passa nas migrações novas; a
   varredura de policies `anon` no schema do repo não acusa `USING(true)` em
   tabela de negócio; o `auditor-multitenant` revê a edge function e os triggers.

---

## REGRAS TRANSVERSAIS (da constituição — valem em todas as fases)

Segurança mora no banco; nenhuma regra só no front; **nenhuma action define
senha**; toda ação administrativa sobre dado de cliente é auditada; nenhuma
credencial em código, spec ou arquivo versionado; a referência
`../nexclin-lovable` é somente leitura.

## CRITÉRIOS DE ACEITE (executados manualmente por Arthur)

1. As queries da Fase 0 confirmam: **zero** policy `anon` com `qual = true` em
   qualquer tabela de anamnese, ao vivo.
2. Requisição anônima direta a `anamnesis_responses` retorna vazio/negado.
3. Formulário público de anamnese funciona por token, ponta a ponta; token
   consumido não reabre.
4. `DELETE`/`UPDATE` em `patients` gera linha em `data_audit_log` com autor,
   timestamp e estado anterior; exclusão é soft.
5. Usuário de uma clínica não lê auditoria nem paciente de outra.
6. As mesmas correções existem como migração no repositório e passam no hook.
7. Supabase Pro (backup diário) **ligado antes de 01/09**, não no dia — não é
   código, mas é pré-condição de segurança para operar com cliente real.
