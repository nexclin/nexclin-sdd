# Censo parcial de 06/09/2026: um usuário só, e o responsável é setor

Registro de duas saídas que o Arthur rodou no editor de SQL, mais o que elas
provam e o que continua sem prova. Atende em parte T005 (#59) e T104 (#79).
**O que não deu para provar está dito, não arredondado.**

## O que foi rodado

Bloco 4b de `021-censo-financeiro.sql` e bloco 3b de `022-censo-tarefas.sql`,
que são a mesma pergunta em duas telas: quem existe na clínica
`d51ce6c7-582b-469b-a01b-608bd9b38885`.

As duas devolveram **uma linha só**:

| user_id | full_name | permission_level | permissions →> módulo | active |
|---|---|---|---|---|
| `ea68c711-…8ad9e` | Dr. João Silva | `master` | vazio, nos dois módulos | `true` |

## Achado 1: a clínica de teste tem um usuário

Isso **fecha a causa da issue #50**, os cinco e2e pulados da cascata de
permissão. Eles não estão pulados por defeito de teste: **não existe segundo
usuário para negar módulo a ele**. Sem convidar alguém, nenhuma das provas de
permissão pode rodar, nem aqui nem na stack nova.

## Achado 2: `permissions` vem vazio, e isso não prova nada sozinho

`permissions ->> 'contas_receber'` e `permissions ->> 'tarefas'` vieram nulos
para o único usuário. **Há duas explicações e uma linha não distingue entre
elas:**

1. É o esperado. `master` recebe `full` pela cascata de `my_permission`, sem
   passar por permissão individual, então a chave nunca precisou existir.
2. A coluna `permissions` está vazia para todo mundo, e a cascata nunca é
   exercitada porque só há master.

**Distinguir exige o segundo usuário do achado 1.** Fica aberto.

## Achado 3, e é o que explica a foto que não aparece

A imagem que o Arthur mandou em 06/09 mostra a coluna Responsável com
**"Comercial"** e **"Financeiro"**, com as iniciais `C` e `F` no lugar da foto.

**Esses valores não são pessoas, são setores.** E é por isso que a foto não
aparece, e vai continuar não aparecendo: `useResponsaveis` casa
`tasks.responsible` contra `team_members.name`, e nenhum membro se chama
"Comercial". O código faz o que deve; **o dado é que não tem pessoa**.

Combinado com o achado 1, o quadro fecha: a clínica tem um usuário e as tarefas
foram atribuídas a setores, que era exatamente a prática que o **FR-005 da
regra 022** existe para encerrar, ao transformar `tasks.responsible` de texto
livre em referência a usuário.

**Consequência para o prazo:** enquanto a fase 1 da 022 não for aplicada e as
tarefas não forem reatribuídas a pessoas, a foto do responsável é código pronto
sem dado que o exercite. Não é bug para caçar de novo.

## O que continua sem prova

- **O número que destrava a fase 1 da 022**: quantos valores distintos de
  `responsible` não casam com membro, e quantas tarefas estão neles. Sai do
  bloco 1 de `022-censo-tarefas.sql`, que não foi rodado.
- **A divergência de `revenues` contra `receivables`**, blocos 3, 3b e 3c de
  `021-censo-financeiro.sql`, que também não foram rodados.
- **A cascata de permissão**, bloqueada pelo achado 1.
