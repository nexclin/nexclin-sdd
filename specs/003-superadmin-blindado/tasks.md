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
| **O painel ESCREVE** | ✅ **26/08** | Ver abaixo |
| Reagem ao banco vivo | ⏳ | **Não medido.** É código lido, não comportamento provado. Fecha no aceite do Arthur. |

### O painel era somente leitura, e ninguém tinha reparado

Medição de 26/08, e ela é o achado mais direto desta auditoria:

```
escritas em app/superadmin/  ->  1, e é a impersonação
```

As onze telas existiam e mostravam dado. Dava para **ver** conta, plano e
faturamento, e não dava para **mudar** nada. O superadmin é quem libera plano,
define cobrança e suspende quem não paga, e nenhuma dessas três tinha caminho.

O que entrou, em `lib/superadmin/`:

| O quê | Onde |
|---|---|
| Criar conta: clínica, assinatura com plano e cobrança, linha do dono | `/superadmin/contas/nova` |
| Mudar plano, situação e dia de cobrança | detalhe da conta |
| Criar e editar plano, com mensalidade, limites e as 15 chaves | `/superadmin/planos` |

**A criação de conta tem dois passos, e é desenho e não pendência.** O usuário
de login não nasce ali. A edge function de convite deriva a clínica do perfil de
quem chama, e o comentário dela é explícito: *"é ela que o convidado herda,
nunca uma vinda do body"*. Um caminho privilegiado que aceitasse `clinic_id` de
fora desmontaria essa guarda. Então o segundo passo é entrar na conta, que já é
auditado, e convidar pela tela de equipe. A própria tela explica isso.

**A armadilha que os testes pegaram**, e ela é de calendário: conta cobrada dia
31 não pode ser cobrada em fevereiro. `new Date(ano, mes, 31)` **transborda para
3 de março em silêncio**, porque o JavaScript aceita e ajusta. Na vida real
seria a fatura de fevereiro sumir e duas caírem em março. O dia passou a ser
grampeado ao último do mês, com um teste que varre todos os dias de todos os
meses de 2026. Provado por mutação: tirar o grampeamento derruba 4 testes.

---

## Fase 3. Blindagem

| # | Item | Estado | Como foi medido |
|---|---|---|---|
| F3.1 | Impersonação escopada, banner, saída | ✅ | SPEC 001 T025; policy `Superadmins manage own impersonation sessions` exige `superadmin_user_id = auth.uid()` |
| **F3.1b** | **Sessão de suporte com prazo** | ✅ **26/08**, com dívida declarada | Ver abaixo |
| F3.1c | Trilha de auditoria imutável | ✅ | `superadmin_audit_log` tem policy de SELECT e de INSERT, e **nenhuma** de UPDATE ou DELETE. Por default deny, ninguém edita nem apaga, inclusive o superadmin |
| F3.2 | Dados sensíveis da equipe só por RPC | ✅ | `20260802073330` revoga `SELECT` da tabela e concede coluna a coluna; e-mail, telefone e repasse ficam de fora. A RPC é `get_clinic_team_full` |
| F3.3 | Escrita em `user_roles` só por superadmin | ✅ | `20260802073330` |
| F3.3b | `is_superadmin` só responde sobre o próprio usuário | ⚠️ **aberto, e de propósito** | Ver abaixo |
| F3.4 | `SECURITY DEFINER` com `SET search_path` em toda função | ✅ | **Varredura das 64 migrações: zero funções `SECURITY DEFINER` sem `SET search_path`.** Não é opinião, é contagem |
| F3.5 | Testes nos guards | ✅ | `decidirSuperAdmin` coberto em `lib/auth/__tests__/decisoes.test.ts` |
| F3.5b | Auditor multi-tenant sobre o painel | ⏳ | Pendente |

### F3.1b, o prazo, e o que eu achei ao verificar

Pesquisa sobre controles de impersonação em SaaS trata como básico um tempo
máximo de sessão de suporte. Não tínhamos. Ao ir implementar, achei coisa pior
que a ausência do prazo.

**A impersonação troca a ÂNCORA.** `superadmin_enter_clinic` faz
`UPDATE profiles SET clinic_id = <clínica alvo>` no perfil do operador, e
`get_my_clinic_id()` lê `profiles.clinic_id` e mais nada: ela **não consulta** a
tabela de sessões.

Logo, operador que entra numa conta e fecha o navegador sem clicar em sair fica
com o perfil apontando para a clínica do cliente. Não por uma hora: **até alguém
clicar em sair**. E na próxima vez que abrir o sistema, entra direto lá dentro.

Isso também muda qual é o conserto certo. Um prazo só na sessão seria **pior que
nada**: o banner sumiria da tela e o acesso continuaria, porque quem decide o
acesso é a âncora. Esconder o aviso mantendo o acesso é a pior combinação das
duas.

Então o prazo desfaz a troca da âncora. `encerra_impersonacoes_vencidas()`
restaura `profiles.clinic_id` a partir de `original_clinic_id`, fecha a sessão e
audita a saída como qualquer outra. Duas horas de prazo, e a função é chamada no
`layout` do painel, que é a porta de entrada de todas as rotas.

**A dívida, dita na cara:** se o operador nunca mais voltar, ninguém chama a
função. Fechar de vez exige `pg_cron`, e não há nenhuma extensão de cron nas 64
migrações deste banco, ou fazer `get_my_clinic_id()` consultar a sessão, que é a
função que **toda** policy chama. Errar nela derruba o sistema inteiro, não uma
tela.

O que entrou reduz "para sempre" a "até a próxima vez que o operador abrir o
painel". É a diferença entre um problema permanente e um transitório, e não é a
mesma coisa que resolver.

**Ao aplicar, olhe o número que a função devolve.** Maior que zero significa que
havia perfil de operador apontando para a clínica de um cliente sem ninguém
saber. Isso é achado, não detalhe.

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

   **Virou urgente em 26/08:** a senha da conta-mestra foi exposta em texto puro
   num chat, pela segunda vez nesta mesma conta. Registro em
   `docs/seguranca/credencial-exposta-2026-08-26.md`. A troca por recovery
   resolve as duas coisas de uma vez: fecha o vazamento e destrava a spec.

6. **Rodar a limpeza de impersonação uma vez**, depois de aplicar a migração do
   prazo, e **olhar o número devolvido**:

   ```sql
   SELECT public.encerra_impersonacoes_vencidas();
   ```

   Zero é o esperado. Maior que zero é achado, não detalhe.

O item 5 é o gargalo de todos os outros, e é uma tarefa de cinco minutos.

---

## O roteiro de teste do painel, para a bateria

Na ordem, porque cada passo alimenta o seguinte.

1. **Definir a senha do superadmin** por recovery no Supabase, e entrar em
   `/superadmin/login`. Sem isto nada abaixo roda.
2. **Criar um plano** em Planos: nome, mensalidade, limites, e marcar os
   módulos. Confira que os módulos desmarcados aparecem riscados na lista.
3. **Criar uma conta** em Contas, botão Nova conta: clínica, responsável,
   plano, situação Em teste, dia de cobrança **31**. Escolha 31 de propósito.
4. **Abrir a conta** e conferir a data de cobrança calculada. Se hoje for
   depois do dia 31 do mês, ela cai no último dia do mês seguinte, e em
   fevereiro cai no dia 28.
5. **Mudar a situação** para Ativa e salvar. Depois tente ir para Cancelada e,
   em seguida, reativar: a opção de reativar **não deve aparecer**, e forçar
   pela requisição deve ser recusado pelo servidor.
6. **Conferir a linha do tempo** da conta. Cada uma das mudanças acima tem de
   estar lá, **sem que nenhuma tela tenha escrito nela**: quem escreve é a
   trigger.
7. **Entrar na conta** e convidar o dono pela tela de Equipe. Ele define a
   própria senha pelo link.
8. **Sair do modo suporte** e conferir, na linha do tempo, a entrada e a saída.

O passo 5 é o que prova que a regra vive no servidor, e o passo 6 é o que prova
que a auditoria não depende de ninguém lembrar de escrevê-la.
