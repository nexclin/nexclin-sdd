# 023 fase 1, aplicação guiada: a mensagem interna

Um bloco, com a conferência ao lado e a reversão embaixo. Nada aqui foi
aplicado: aplicar é do Arthur, no editor de SQL do banco ao vivo (T220).

**Antes de tudo, o portão da T219:** o export do banco feito e com cópia em
nuvem, registrado em `docs/ponte/registro-exports-banco.md`.

## O que o censo de 14/09 e o auditor fixaram

- `task_comments` está no ar com as duas policies do `b1`. A migração
  `20260907000000_task_comments.sql` existe só para a stack nova herdar; **não
  roda de novo aqui**.
- `supabase_realtime` existe e está vazia. Realtime é a Fase 3, bloco `b6`.
- O `auditor-multitenant` tentou furar a policy por participante em doze
  hipóteses (ler mensagem de terceiro, assinar por outro, enviar para outra
  clínica, para membro sem login, para si mesmo, mudar `body` por `UPDATE`,
  voltar `read_at` a nulo, remetente marcando lida, superadmin sem clínica,
  `DELETE`, `sender_id` nulo) e **nenhuma passou**. Registro em T217 e T218.

## Bloco 5, a tabela e a policy por participante

Atende **FR-007, FR-009, FR-010, FR-013 e FR-014** na parte de banco.

| Passo | Arquivo | O que esperar |
|---|---|---|
| 1 | `b5-mensagem-interna.sql`, inteiro | quatro blocos: tabela, índices, RLS com três policies, trigger `BEFORE UPDATE`. Nada destrutivo; o editor não deve pedir confirmação |
| 2 | `b5-conferencia.sql` | tudo `OK`; `ESTA_COLUNA_NAO_EXISTE` em `FALTA`; `tem policy de DELETE?` em `OK: nenhuma` |
| 3 | só se algo vier `FALTA` | `b5-reversao.sql`. A tabela só cai vazia |

## Depois deste bloco

1. **T221 a T223**, as provas no editor, com controle positivo em cada uma.
   Substitua os `<...>` pelos `user_id` de Maria (`68326ea2…`) e do
   Dr. Lançamento (`73deadca…`), da Clínica Lançamento `45f88cf2…`:

```sql
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<user_id de Maria>","role":"authenticated"}', true);
-- prova 2: assinar por outro e recusado; em nome proprio passa
insert into public.internal_messages (clinic_id, sender_id, recipient_id, body)
  values ('45f88cf2-4440-48df-9a7c-dd46b90d366c', '<user_id do Dr>', '<user_id do Dr>', 'x');   -- esperado: erro de RLS
insert into public.internal_messages (clinic_id, recipient_id, body)
  values ('45f88cf2-4440-48df-9a7c-dd46b90d366c', '<user_id do Dr>', 'Consulta das 10 confirmada?'); -- esperado: INSERT 1
-- prova 3: para membro sem login e recusado
insert into public.internal_messages (clinic_id, recipient_id, body)
  values ('45f88cf2-4440-48df-9a7c-dd46b90d366c', '<user_id de Joana, que nao tem team_members>', 'x'); -- esperado: erro de RLS
rollback;
```

2. **Regenerar os tipos** do front (`src/integrations/supabase/types.ts` no
   clone da Lovable) com `internal_messages`. Sem isso a Fase 2 grava com
   `as never`.
3. A Fase 2 (T229 a T240) pode subir.
