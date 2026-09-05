# 0006 · O Spec Kit volta pela metade

**Situação:** Aceita · **Data:** 04/09/2026
**Decide:** Arthur Hideo. **A recomendação do executor era não reinstalar**, e a
divergência fica visível de propósito.
**Substitui em parte a [`0004`](./0004-o-spec-kit-sai.md)**, que continua de pé
no que ela decidiu sobre onde a regra mora.

---

## Contexto

A [ADR 0004](./0004-o-spec-kit-sai.md), de 27/08/2026, tirou o Spec Kit inteiro:
a pasta `.specify/`, as onze skills `speckit-*`, e o formato de três arquivos por
feature. Naquela decisão o executor recomendou manter e o Arthur decidiu tirar,
por dois motivos medidos:

1. **Token por turno.** 43 descrições de skill somavam 7.213 bytes lidos a todo
   turno, onze delas `speckit-*`, e a pasta `.specify/` ocupava **16 MB**.
2. **Bagunça de estrutura.** Oito features viraram 34 arquivos, e a resposta para
   *"onde está a regra?"* passou a exigir saber qual dos sete.

Em 04/09, com a reunião de 03/09 apurada e o financeiro na frente da fila, o
Arthur pediu o Spec Kit de volta para escrever as specs de execução.

**Dois fatos medidos em 04/09 mudam o peso do primeiro motivo:**

- O `specify-cli` **1.0.4** instala **380 KB**, não 16 MB, e com
  `--integration claude` só escreve scripts em bash. Os PowerShell que ninguém
  invocava não existem mais no pacote.
- As dez skills que ele instala somam **2.590 bytes** de descrição. As seis que
  esta decisão mantém somam **1.594 bytes**.

O segundo motivo, a bagunça, **continua inteiro e não foi resolvido pelo
upstream**. É ele que a decisão abaixo contorna.

## A decisão

**O Spec Kit volta, e a regra continua onde estava.**

1. **Seis skills entram:** `speckit-plan`, `speckit-tasks`, `speckit-analyze`,
   `speckit-checklist`, `speckit-taskstoissues` e `speckit-clarify`. As outras
   quatro ficam de fora porque o projeto já tem substituto para cada uma, e ter
   as duas faria a escolha cair no acaso de qual a sessão lembrar primeiro. A
   tabela está em [`../planos/README.md`](../planos/README.md).

   > **Emenda de 05/09/2026.** Esta decisão nasceu com quatro skills. As outras
   > duas foram acrescentadas por pedido do Arthur, cada uma com o seu motivo,
   > e o registro fica aqui em vez de virar ADR nova porque não mudam o
   > desenho, só a lista:
   >
   > - **`speckit-taskstoissues`** entra porque abre issue **a partir do
   >   `tasks.md`, respeitando a ordem de dependência**, e o `to-tickets`, que
   >   era o substituto previsto, abre a partir de um documento sem essa ordem.
   >   Com 47 tarefas em três fases atrás de portões, a ordem é o que se perde.
   > - **`speckit-clarify`** entra porque o `grilling`, que era o substituto
   >   previsto, **não existe em clone limpo**: ele está em
   >   `.claude/skills-fora/`, que o `.gitignore` exclui na linha 62. O primeiro
   >   degrau da cadeia canônica não sobrevivia a um checkout, e a constituição o
   >   citava pelo nome. Achado de 05/09, ao tentar rodar `/grill-with-docs`
   >   nesta sessão.
2. **A regra viva continua em `docs/regras/`, um arquivo por regra, nas sete
   seções.** Isto é o que a 0004 decidiu e não é revertido.
3. **Plano e tarefas passam a viver em `docs/planos/NNN-nome/`**, com o `spec.md`
   que o Spec Kit exige entrando como **link simbólico** para a regra, e não como
   cópia.
4. **`.specify/memory/constitution.md` é um ponteiro** para
   `docs/constituicao.md`. Duas leis lado a lado divergem no primeiro commit.

**A cadeia canônica ganha um degrau e não perde nenhum:**

```
grill-with-docs → nx-regra → speckit-plan → speckit-tasks → to-tickets → implement
                             (speckit-analyze e speckit-checklist, quando valerem)
```

## Por que o link simbólico, e não uma cópia

O `get_feature_paths` do Spec Kit resolve o diretório da feature por
`SPECIFY_FEATURE_DIRECTORY` ou `.specify/feature.json`, e isso é configurável.
Mas os nomes dentro dele são fixos: `spec.md`, `plan.md`, `tasks.md`. Ou seja, o
diretório é nosso e o nome do arquivo é dele.

Cópia resolveria e criaria o pior defeito possível neste projeto: dois arquivos
com a mesma regra, um deles corrigido e o outro não. A regra (l) da constituição
existe justamente para impedir regra que envelhece calada.

## A recomendação recusada, e por que ela era razoável

O executor recomendou **não reinstalar**, com três argumentos:

- **Faltam quatro dias para 08/09.** A própria 0004 registrou que trocar
  ferramenta que está entregando, a doze dias do lançamento, é risco sem retorno
  imediato. A quatro dias o argumento é mais forte, não menos.
- **A cadeia que substituiu o Spec Kit não tem buraco.** `nx-regra` escreve a
  regra, `to-tickets` abre as issues, `implement` executa por fases. O que o
  Spec Kit acrescenta é o `plan.md`, um degrau intermediário, e os dois auxiliares.
- **A bagunça de estrutura, que foi o motivo que sobreviveu à medição, não foi
  consertada pelo upstream.**

O Arthur decidiu o contrário, e as razões que a recomendação não pesava:

- **O `plan.md` não é degrau vazio quando a frente é grande.** O financeiro tem
  concilação bancária, importação de OFX, recorrência, baixa em duas etapas e a
  régua em Kanban. Ir da regra direto para issues, nessa dimensão, é o tipo de
  salto que produz issue que ninguém sabe executar.
- **`speckit-analyze` não tem equivalente aqui.** Ele confere consistência entre
  a regra, o plano e as tarefas. Este projeto já perdeu meio dia num arquivo
  órfão e teve três checagens do FR-005 lendo OK com a tabela não existindo. Uma
  conferência cruzada automática ataca exatamente essa classe de erro.
- **A estrutura foi contornada, não aceita.** Três arquivos por frente **em
  execução**, contra sete por feature para sempre.

Se em um mês as pastas de `docs/planos/` estiverem abertas sem frente ativa, a
hipótese a testar primeiro é que a 0004 estava certa e que o contorno não segurou.

## Consequências assumidas

- **Volta a haver dois lugares para olhar** quando uma frente está em execução, a
  regra e o plano. O `README.md` de `docs/planos/` existe para que a pergunta
  *"onde está a regra?"* continue tendo uma resposta só.
- **Custo de contexto medido: 1.594 bytes** de descrição de skill por turno, mais
  164 KB em disco. É menos que os 7.213 bytes que a 0004 mediu, e não é zero.
  Eram 1.010 bytes com quatro skills, antes da emenda de 05/09.
- **Link simbólico é frágil em alguns ambientes.** Checkout no Windows sem
  `core.symlinks` transforma o link em arquivo de texto com o caminho dentro.
  Neste projeto o desenvolvimento é em Linux e macOS, e o risco foi aceito.
- **`.specify/feature.json` não vai para o git**, por desenho do próprio Spec Kit.
  Toda sessão nova precisa exportar `SPECIFY_FEATURE_DIRECTORY` antes da primeira
  skill. Está no `README.md` de `docs/planos/`.
- **`speckit-implement` ficou de fora**, então o plano gerado é executado pela
  skill `implement` local, que tem a parada humana por fase da regra (h). Se
  alguém instalar o `speckit-implement` depois, essa parada precisa ser conferida.

## Alternativas descartadas

**Reverter a 0004 inteira.** Traria as dez skills e o formato de sete arquivos
por feature. Custaria 2.590 bytes por turno em vez de 1.594, e devolveria a
bagunça que foi o motivo que sobreviveu à medição de 04/09.

**Não reinstalar e seguir com `nx-regra`, `to-tickets` e `implement`.** Era a
recomendação do executor. Recusada pelas três razões acima.

**Copiar a regra para `spec.md` em vez de linkar.** Recusada: cria duas versões
da mesma regra, e a regra (l) da constituição existe para impedir isso.

## Como reverter

Apagar `.specify/`, as seis skills `speckit-*` e `docs/planos/`. As regras em
`docs/regras/` não são tocadas por nada disto, então a reversão não perde
requisito nenhum. O que se perde são os `plan.md` e `tasks.md` já gerados, e eles
ficam no histórico do git.
