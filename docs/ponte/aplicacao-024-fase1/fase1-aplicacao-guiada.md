# 024 fase 1, aplicação guiada

Um bloco, com a conferência ao lado e a reversão embaixo. Nada aqui foi
aplicado: aplicar é do Arthur, no editor de SQL do banco ao vivo (T318).

**Antes de tudo, o portão da T317:** o export do banco tem de estar feito e com
cópia em nuvem, registrado em `docs/ponte/registro-exports-banco.md`. Logo
abaixo do `Export data` ficam `Pause` e `Remove`, os dois em vermelho.

## O que o censo de 14/09 mudou neste bloco

- O trigger de auditoria existe no banco **só em `patients`**. O bloco 3 o
  estende a `tasks` e `appointments`; não cria a função.
- `tasks.type` é texto sem `CHECK`. O bloco 5 é comentário; `recall_paciente`
  entra pela lista do front (T343).
- `tasks` tem uma policy `FOR ALL`. O bloco 6 a troca por três, sem `DELETE`.

Detalhe em `docs/historico/2026-09-14-censo-operacional.md`.

## Bloco 1, colunas, triggers, pesos e policies

Atende **FR-002, FR-007 a FR-010 (banco), FR-012 (banco)** da regra 024.

| Passo | Arquivo | O que esperar |
|---|---|---|
| 1 | `b1-colunas-triggers-pesos-policies.sql`, **inteiro** | seis blocos; o 5 é só comentário. O editor pode pedir "Confirm destructive operation" no `DROP POLICY`: é o esperado, e o `CREATE` vem no mesmo comando |
| 2 | `b1-conferencia.sql` | três consultas, tudo `OK`; as linhas `NAO_EXISTE` em `FALTA`, e `tem policy de DELETE?` em `OK: nenhuma` |
| 3 | só se algo vier `FALTA` ou `FALHA` | `b1-reversao.sql`, inteiro, e avisar |

**O que este bloco não toca:** nenhuma linha existente, nenhuma coluna de
texto (`responsible`, `doctor`), nenhuma policy de `appointments`.

## Depois deste bloco

1. **T320**, a prova do `DELETE` recusado com controle positivo, no editor:

```sql
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<user_id de Maria>","role":"authenticated"}', true);
delete from public.tasks where id = '<uma tarefa da Clínica Lançamento>';   -- esperado: DELETE 0
update public.tasks set status = 'cancelada' where id = '<a mesma>';          -- esperado: UPDATE 1
rollback;
```

2. **Regenerar os tipos** do front: `src/integrations/supabase/types.ts` no
   clone da Lovable ganha as três colunas e a jsonb. Sem isso a Fase 2 grava
   `responsible_member_id` com `as never`, que é o remendo que `NxSino.tsx`
   já carrega para `task_comments`.
3. A Fase 2 (T324 restante, T326 a T337) pode subir.
