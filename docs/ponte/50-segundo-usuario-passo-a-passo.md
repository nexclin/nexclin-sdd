# Issue #50, o segundo usuário: passo a passo

Você perguntou como fazer. É a tarefa mais barata da fila e a que destrava mais
coisa: **cinco provas de permissão, o FR-011 e a foto do responsável**, todas
paradas pela mesma causa.

## Por que ela está parada

O censo de 06/09 devolveu **uma linha**: a clínica
`d51ce6c7-582b-469b-a01b-608bd9b38885` tem um usuário só, Dr. João Silva,
`permission_level = master`.

A cascata de `my_permission` só pode ser provada com alguém que **não** seja
master e que tenha **um módulo negado**. Com um master sozinho, todo caminho
devolve `full` e o teste passa sem testar nada. É a armadilha do teste vazio.

## Os passos

**1. Convide pela própria plataforma**, em Configurações, aba Equipe. Use um
e-mail que você controle e que **não seja** o do superadmin. Um alias serve:
`seuemail+teste@gmail.com` chega na mesma caixa e conta como endereço distinto.

**2. Aceite o convite** no e-mail e defina a senha **você mesmo, digitando**.
Não peça a ninguém para definir por você, e não defina pelo superadmin: a
alínea (e) da constituição proíbe, e a issue #48 existe por causa disso.

**3. Dê a esse usuário um perfil que NEGUE dois módulos.** Sugestão, porque são
os dois que as provas paradas precisam:

| Módulo | O que dar |
|---|---|
| `contas_receber` | **negado** |
| `tarefas` | **negado** |
| o resto | leitura, ou o que fizer sentido |

**4. Rode o bloco 4 de `docs/ponte/021-censo-financeiro.sql`** e o **bloco 3 de
`docs/ponte/022-censo-tarefas.sql`**. Os dois já se viram sozinhos: escolhem o
usuário negado sem você colar UUID nenhum, e trazem o controle positivo junto.

**5. Leia o veredito, e leia o controle positivo primeiro.** Se ele disser que
a consulta está quebrada, o resto do resultado não vale. Se disser
`NÃO TESTADO, E ISSO É ACHADO`, é porque nenhum usuário negado foi encontrado,
ou seja o passo 3 não pegou.

## O que cada resultado significa

- **O usuário negado NÃO lê `receivables` nem `tasks`**: a cascata funciona, e
  cinco issues fecham de uma vez.
- **O usuário negado LÊ**: é a confirmação do **FR-011**, que já está escrito
  por leitura de código. As políticas de `receivables`, `expenses`, `revenues` e
  `fixed_expenses` são as originais de 22/03, `FOR ALL TO authenticated` por
  `clinic_id`, e **nenhuma chama `my_permission`**. Isso viola a alínea (c) da
  constituição, e vira correção de banco, não de tela.

**A segunda hipótese é a mais provável**, pelo que já se leu no código. Vale
executar mesmo assim: leitura de código prova o que está escrito, não o que o
banco faz.

## De quebra, resolve a foto

Com um segundo usuário real cadastrado em `team_members`, dá para reatribuir
uma tarefa a **ele** em vez de a "Comercial" ou "Financeiro", e aí a foto do
responsável aparece pela primeira vez com dado de verdade. É o teste mais
rápido do que a issue #94 entregou.
