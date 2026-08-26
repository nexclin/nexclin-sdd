# SPEC 003, tarefas

> Escrito em 26/08/2026, quando o Arthur pediu para terminar a execução da spec
> do superadmin. Até aqui a 003 tinha só `spec.md`, e a spec descrevia um estado
> de partida de **16/08**: "2 de 11 telas portadas".
>
> **Esse estado de partida está vencido.** A SPEC 001 avançou muito por cima do
> mesmo terreno em 25/08 (T023 fechou as 11 telas, T024 a seção de Perfis, T025
> a impersonação). Antes de escrever tarefa, eu medi o que existe hoje, e a
> maior parte das Fases 1 e 2 já estava feita por outro caminho.
>
> Por isso este arquivo não é uma lista de trabalho a fazer: é o **resultado da
> auditoria**, com o que foi medido, o que faltava de fato, e o que só o Arthur
> pode fechar.

## O método: medir antes de listar

Cada linha abaixo diz **como** foi verificada. Item sem medida ao lado é item
que eu acreditei, e a constituição não aceita isso como pronto.

---

## Fase 1. Seção de Perfis

| # | Item | Estado | Como foi medido |
|---|---|---|---|
| F1.1 | Bloco Perfis no detalhe da conta | ✅ | `app/superadmin/(panel)/contas/[id]/acoes-de-perfil.tsx` existe |
| F1.2 | Troca de e-mail via edge function, auditada | ✅ | `superadmin-manage-user/index.ts:94` grava `email_change` com `previous_state` e `new_state` |
| F1.3 | Reset por e-mail, e **nenhum** caminho que defina senha | ✅ | A action `set_password` foi removida; o hook `guarda-constituicao.mjs` bloqueia o padrão a cada escrita |
| **F1.4** | **Toda ação grava DUAS linhas** | ✅ **fechado em 26/08** | Ver abaixo |

### F1.4 era o furo real, e ele estava exatamente onde a spec avisou

A spec dizia: *"a referência falhava na segunda; aqui é obrigatória e
verificada"*. Varredura em `app/`, `lib/` e `supabase/functions/`:

```
superadmin_audit_log  ->  1 leitura,  2 escritas
account_timeline      ->  1 LEITURA,  0 escritas
```

A tela de detalhe da conta desenhava uma linha do tempo que **nada
alimentava**. O mesmo defeito da referência, portado junto com o resto.

**Corrigido por trigger, e não por função de aplicação.** O caminho óbvio seria
uma função que insere nas duas tabelas e trocar os dois `INSERT` da edge
function por ela. Resolveria hoje e falharia amanhã, porque depende de todo
chamador futuro lembrar de usá-la, que é como a referência perdeu a segunda
linha: por esquecimento repetido, não por decisão.

Com trigger em `superadmin_audit_log`, a regra vira propriedade da tabela.
Quem escrever auditoria por qualquer caminho produz a linha do tempo sem saber
que ela existe, **inclusive as funções de impersonação**, que escrevem de dentro
do banco e nunca passariam por código da aplicação.

Migração: `20260826010000_toda_acao_de_superadmin_vira_linha_na_timeline.sql`.
Inclui reparo idempotente do histórico já auditado.

---

## Fase 2. As 9 telas restantes

| Item | Estado | Como foi medido |
|---|---|---|
| As 11 telas | ✅ | `app/superadmin/(panel)/` tem contas, detalhe, planos, cupons, faturamento, métricas, comunicação, logs, operadores, configurações e o painel |
| Reagem ao banco vivo | ⏳ | **Não medido.** É código lido, não comportamento provado. Fecha no aceite do Arthur. |

---

## Fase 3. Blindagem

| # | Item | Estado | Como foi medido |
|---|---|---|---|
| F3.1 | Impersonação escopada, banner, saída | ✅ | SPEC 001 T025; policy `Superadmins manage own impersonation sessions` exige `superadmin_user_id = auth.uid()` |
| F3.2 | Dados sensíveis da equipe só por RPC | ✅ | `20260802073330` revoga `SELECT` da tabela e concede coluna a coluna; e-mail, telefone e repasse ficam de fora. A RPC é `get_clinic_team_full` |
| F3.3 | Escrita em `user_roles` só por superadmin | ✅ | `20260802073330` |
| F3.3b | `is_superadmin` só responde sobre o próprio usuário | ⚠️ **aberto, e de propósito** | Ver abaixo |
| F3.4 | `SECURITY DEFINER` com `SET search_path` em toda função | ✅ | **Varredura das 64 migrações: zero funções `SECURITY DEFINER` sem `SET search_path`.** Não é opinião, é contagem |
| F3.5 | Testes nos guards | ✅ | `decidirSuperAdmin` coberto em `lib/auth/__tests__/decisoes.test.ts` |
| F3.5b | Auditor multi-tenant sobre o painel | ⏳ | Pendente |

### F3.3b, e por que eu parei em vez de mexer

`is_superadmin(_user_id uuid)` aceita **qualquer** uuid. Dentro das policies
isso é correto, porque elas sempre passam `auth.uid()`. O risco é o outro
caminho: um usuário autenticado chamando a RPC com o uuid de outra pessoa para
descobrir quem é operador.

A migração `20260802073330` já fez `REVOKE EXECUTE ... FROM PUBLIC, anon`, o
que provavelmente fecha isso, porque `authenticated` não costuma ter concessão
própria. **Provavelmente não é medido.**

E o conserto óbvio é perigoso: revogar de `authenticated` pode derrubar toda
policy que chama a função, e são muitas. Errar aqui tranca o sistema inteiro,
não uma tela.

**A consulta que decide, para rodar no banco antes de qualquer mudança:**

```sql
SELECT grantee, privilege_type
  FROM information_schema.routine_privileges
 WHERE routine_schema = 'public'
   AND routine_name   = 'is_superadmin';
```

Sem `authenticated` na lista, o item já está fechado e a spec precisa é ser
atualizada. Com `authenticated` na lista, vira tarefa própria, com teste de
policy antes e depois. Não é trabalho de véspera.

---

## O que falta, e é do Arthur

Nenhum destes é código. São os aceites da spec, e a constituição não deixa
marcar como pronto o que ninguém executou.

1. **As 11 telas reagindo a dado real.** Entrar no painel e navegar.
2. **A prova do F1.4**, que vale mais que a conferência de schema: trocar o
   e-mail de um usuário pelo painel e ver a entrada aparecer na linha do tempo
   da conta **sem que a aplicação tenha escrito nela**.
3. **Impersonação ponta a ponta:** entrar, ver o banner com o nome certo,
   escrever na clínica alvo, trocar de clínica sem sair, sair, conferir que a
   âncora voltou, e conferir as duas linhas de auditoria.
4. **Usuário comum invocando RPC de superadmin** e recebendo 'Acesso negado'.
5. **T012 da SPEC 001:** definir a senha real do superadmin por recovery no
   painel do Supabase. `last_sign_in_at` continua vazio, ou seja, **o
   superadmin da stack nova nunca logou.** Enquanto isso não acontecer, os
   itens 1 a 4 não têm como ser executados.

O item 5 é o gargalo de todos os outros, e é uma tarefa de cinco minutos.
