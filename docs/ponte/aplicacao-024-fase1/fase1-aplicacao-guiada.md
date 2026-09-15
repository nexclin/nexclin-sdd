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

## Bloco 2, escrito em 15/09: `business_rules` só para quem manda, e a contagem de assumidas

Nasce de dois achados do mesmo dia: o auditor (T374) confirmou que a policy de
`business_rules` deixa qualquer membro gravar `task_type_weights` pela API
(nexclin#185), e o `speckit-analyze` apontou que "tarefas assumidas" não
aparece para a secretária, porque a trilha só abre para admin.

**Ordem, e ela importa:** o bloco 2 vai ao banco **antes** do Publish do front
que o chama (`RankingDeProdutividade.tsx` passa a usar
`tarefas_assumidas_por_membro`). É a mesma regra da constituição para edge
function: função antes do front. Publicar o front antes deixa o ranking sem a
coluna até o `Run`.

1. Editor de SQL, `Clear`, colar `b2-business-rules-e-assumidas.sql`, `Run`.
   Um bloco por vez se preferir; o bloco 1 não pode parar entre o `DROP` e o
   primeiro `CREATE`.
2. Colar `b2-conferencia.sql`, `Run`. Esperado em cada consulta está no
   arquivo.
3. Colar `b2-prova.sql`, `Run`. Cinco linhas: Maria lê (1), não grava (0),
   chama a função sem erro, não lê a trilha (0); o Dr grava (1).
4. Se algo sair diferente do esperado, `b2-reversao.sql` volta tudo, palavra
   por palavra, e a issue #185 fica aberta com o resultado colado.
