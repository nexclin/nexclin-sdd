# 0001 · A ModuleKey `consultas` sai do contrato

**Situação:** Proposta, decidida pelo executor em 25/08/2026 sob delegação
**Data:** 25/08/2026
**Decide:** Arthur Hideo. Decidida aqui pela documentação, a pedido dele, com
autorização prévia para não interromper. **Reversível: ver §Como reverter.**

---

## Contexto

O contrato de módulos tem 15 chaves exatas, e `docs/dominio/modulos.md` registra
que **uma delas não tem destino**:

> **Nota sobre `consultas`.** A chave existe no contrato, mas a tela rotulada
> "Consultas" no menu aponta para `/acompanhamento`, protegida pela chave
> `acompanhamento`. A referência tem um `Consultas.tsx` órfão, não roteado. Ao
> reconstruir, decida: ou `consultas` ganha destino próprio, ou sai do contrato
> por emenda. **Ambiguidade em contrato de permissão é dívida de segurança.**

O mesmo documento registra `consultas` sem rota e sem onda, com um traço nas
duas colunas. O `INVENTARIO.md` confirma: `Consultas.tsx` é página órfã, não
roteada.

Ou seja: **a chave existe no banco, entra no `enabled_modules` de todo plano, é
validada pelo trigger, e não protege nada.**

## A decisão

**`consultas` sai do contrato de módulos.** O contrato passa a ter 14 chaves.

A tela de consultas continua existindo, continua chamada de "Consultas" no menu,
e continua protegida por `acompanhamento`, que é o que já acontece hoje.

## Por que esta saída, e não a outra

As duas alternativas eram dar destino próprio ou remover. A documentação decide
sozinha, se for lida por inteiro:

**1. Dar destino próprio exigiria inventar um produto.** Não existe tela de
"consultas" separada de "acompanhamento" em lugar nenhum: o `Consultas.tsx` da
referência é órfão, nunca foi roteado, e nenhuma spec descreve o que ele faria.
Criar a rota significaria decidir agora o que duas telas fazem de diferente,
sem nenhum apontamento de usuário pedindo, e a `fila-especificacoes.md` já trata
os dois como **uma spec só** (`consultas-acompanhamento`, que cobre os módulos
`consultas` e `acompanhamento` juntos).

**2. A chave em aberto tem custo, e ele cresce.** O Princípio III diz que
planos, permissões e telas usam as mesmas strings. Uma chave que nenhuma tela
usa é uma linha em todo `enabled_modules`, em toda `permissions` de membro, que
alguém pode ligar acreditando que libera algo. Ligar `consultas` num plano hoje
não faz absolutamente nada, e desligar também não. Isso é pior que ausência: é
um controle que mente.

**3. O Princípio VIII (Uma Regra, Uma Fonte), da constituição v2.0.0, empurra
para o mesmo lado.** Duas chaves para o mesmo conceito, sendo que só uma decide,
é a mesma classe de problema que o documento descreve em `consultation_type_id`
gravando `services.id`.

## Consequências assumidas

- **É emenda à constituição** (Princípio III), e portanto exige incremento de
  versão e Sync Impact Report. Fica **preparada, não aplicada**: ver §Estado.
- **Toca o banco.** O trigger `validate_enabled_modules` lista as 15 chaves em
  `allowed text[]`, e sair do contrato significa alterar essa lista. É migração,
  faixa A, atravessa intacta.
- **Toca linhas existentes.** Todo plano que tenha `"consultas"` no jsonb passa
  a ter uma chave que o trigger recusa. A migração precisa remover a chave das
  linhas **antes** de estreitar a lista, ou o próximo `UPDATE` em qualquer plano
  falha.
- **Perde-se a opção de granularidade futura.** Se um dia consultas e
  acompanhamento virarem telas distintas com acessos distintos, a chave volta
  por emenda. Isso é barato: acrescentar chave é aditivo.

## A simetria com a SPEC 013

Se `consultas` sai e `residuos` (SPEC 013) entra, o contrato volta a ter 15
chaves e **as duas emendas viram uma só**. Isso não é motivo para decidir, mas é
motivo para **agendar juntas**: duas alterações no mesmo `allowed text[]`, na
mesma migração, com um único Sync Impact Report.

Como a SPEC 013 está bloqueada por decisão comercial, a emenda espera por ela.

## Estado: preparada, não aplicada

**Nada foi alterado no banco, na constituição nem em `lib/auth/modulos.ts`.**

O motivo é a semana em que estamos. A regra que o próprio projeto fixou em
25/08 vale aqui: **não se troca regra de permissão na véspera do lançamento.**
Sair do contrato altera o trigger que valida `enabled_modules` na plataforma que
recebe cliente em 08/09, e o ganho é higiene, não correção de falha.

**O que existe hoje:** este documento, e a migração preparada em
`specs/005-configuracoes-clinica/preparado/` quando ela for escrita.

**Quando aplicar:** junto com a emenda de `residuos`, depois de 08/09.

## Como reverter

Se o Arthur discordar, não há o que desfazer no código: **nada foi aplicado**.
Basta trocar a Situação deste arquivo para *Substituída*, escrever o ADR 0002
com a decisão contrária, e a chave `consultas` continua onde está.

Se ele preferir **dar destino próprio**, o trabalho que isso abre é: definir o
que a tela de consultas faz que a de acompanhamento não faz, escrever isso na
spec `consultas-acompanhamento`, e criar a rota. Não é reversão, é um projeto.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| **Dar rota própria a `consultas`** | Exigiria inventar o que a tela faz, sem nenhum pedido de usuário. A fila já trata os dois módulos como uma spec só. |
| **Deixar como está** | É exatamente a dívida que `docs/dominio/modulos.md` manda encerrar, e ela cresce a cada plano criado. |
| **Aplicar a emenda agora** | Altera o trigger de permissão na plataforma que recebe cliente em 08/09, por higiene e não por falha. |
