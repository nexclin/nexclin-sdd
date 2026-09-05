# 0004 · O Spec Kit sai do projeto

> **Substituída em parte pela [`0006`](./0006-o-spec-kit-volta-pela-metade.md),
> de 04/09/2026.** O Spec Kit voltou com quatro das dez skills, e a medição de
> 04/09 desmentiu um dos dois motivos abaixo: o pacote passou de 16 MB para
> 380 KB. **O que esta decisão diz sobre onde a regra mora continua de pé**: a
> regra viva fica em `docs/regras/`, um arquivo por regra, nas sete seções. O
> plano e as tarefas passaram a viver em `docs/planos/`. Nada aqui foi
> reescrito.

**Situação:** Aceita · **Data:** 27/08/2026
**Decide:** Arthur Hideo. **A recomendação do executor era manter**, e a
divergência fica visível de propósito. Reversível: ver §Como reverter.

---

## Contexto

O GitHub Spec Kit entrou no projeto em 02/08/2026 e trouxe três coisas: a pasta
`.specify/` com templates e scripts, onze skills `speckit-*`, e o método de
`spec.md` mais `plan.md` mais `tasks.md` por feature.

**O que ele produziu, medido e não estimado:** oito specs escritas, e **72
tarefas concluídas** rastreadas nos `tasks.md`. A fundação inteira, o banco
replicado, o painel superadmin, os 80 testes e a correção da bateria do Vinícius
passaram por ele. A avaliação item a item, com os números, está em
[`../harness/sdd-ferramentas-e-avaliacao.md`](../harness/sdd-ferramentas-e-avaliacao.md).

Contra isso, dois custos concretos:

1. **Token por turno.** As 43 descrições de skill somavam 7.213 bytes lidos a
   todo turno, e onze delas eram `speckit-*`. A pasta `.specify/` ocupava 16 MB
   de templates e scripts PowerShell que ninguém invocava havia semanas.
2. **Bagunça de estrutura.** Cada feature virava uma pasta com até sete arquivos
   (`spec`, `plan`, `tasks`, `research`, `data-model`, `contracts/`,
   `quickstart`). Oito features viraram 34 arquivos, e a resposta para *"onde
   está a regra?"* passou a exigir saber qual dos sete.

## A decisão

**O Spec Kit sai inteiro:** a pasta `.specify/`, as onze skills `speckit-*`, e o
formato de três arquivos por feature. As specs viram **regras vivas** em
`docs/regras/`, um arquivo por regra, no formato de sete seções. A constituição
foi emendada no mesmo trabalho, de v2.0.0 para v2.0.1, para deixar de apontar
para `specs/` e para comandos `/speckit-*` que não existem mais.

**A exigência de método não saiu.** Nenhuma feature nasce de código: nasce de
regra aprovada, com parada humana por fase. O Princípio IV continua inteiro,
palavra por palavra. O que mudou foi a ferramenta e o endereço.

## A recomendação recusada, e por quê ela era razoável

O executor recomendou **manter**, com o argumento de que 72 tarefas concluídas
são evidência forte de que o método funciona neste projeto, e que trocar
ferramenta que está entregando, a doze dias do lançamento, é risco sem retorno
imediato.

O Arthur decidiu o contrário, por duas razões que a recomendação não pesava
direito:

- **A carga de contexto é cobrada em todo turno, e o benefício do Spec Kit já
  foi capturado.** As 72 tarefas estão feitas. O que resta é o formato, e o
  formato é a parte que se pode reescrever sem perder nada.
- **A bagunça compõe.** Uma pasta com sete arquivos por feature é aceitável em
  oito features. Nas quinze regras da Onda 1 seria a estrutura dominante do
  repositório, e o momento barato de mudar é agora, com oito, não depois com
  vinte e três.

Registrar a discordância é o ponto deste ADR. Se em três meses a qualidade das
regras cair, a hipótese a testar primeiro é que a estrutura do Spec Kit estava
segurando algo que o formato novo não segura.

## Consequências assumidas

- **`plan.md` e `tasks.md` de cinco specs foram apagados.** O conteúdo fica no
  histórico do git, mas deixa de ser navegável, e 19 tarefas em aberto passaram a
  existir como parágrafo dentro da regra, não como item marcável.
- **Commits de agosto apontam para caminhos mortos.** Toda referência a
  `specs/NNN/spec.md` em mensagem de commit e em documento datado deixou de
  resolver. Não tem conserto, e o custo foi aceito.
- **Perde-se a manutenção do upstream.** As skills `speckit-*` recebiam melhoria
  de terceiros. A cadeia nova (`grill-with-docs`, `nx-regra`, `to-tickets`,
  `implement`) é nossa, e `nx-regra` em particular é uma bifurcação que não
  recebe mais nada de fora. Ver [`0005`](./0005-bifurcar-o-to-spec.md).
- **Ganha-se cerca de 4.600 tokens por turno**, somando o corte do `CLAUDE.md`, a
  redução de 43 para 20 skills, e o fim da pasta `.specify/`.

## Como reverter

`pip install specify-cli` e `specify init` reinstalam a pasta e as skills. As
regras em `docs/regras/` continuariam sendo `spec.md` válidos: o formato de sete
seções é compatível com o que o `speckit-plan` lê. O que **não** volta são os
`plan.md` e `tasks.md` apagados, e eles teriam de ser regerados a partir das
regras e das issues.
