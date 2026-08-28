---
name: nx-regra
description: Escreve uma regra viva em docs/regras/, no formato de sete seções, a partir da conversa que já aconteceu. Use quando uma decisão de produto ou de banco estiver madura e precisar virar documento antes de virar código, e sempre antes de abrir issue ou escrever migração. Não entrevista de novo: sintetiza o que já foi discutido.
---

# nx-regra: a conversa vira regra viva

Bifurcada do `to-spec` do conjunto Matt Pocock (MIT) em 27/08/2026. As
divergências e o motivo de cada uma estão em
`docs/adr/0005-bifurcar-o-to-spec.md`. Em resumo: sem user stories, com seção
própria de banco, e o destino é **arquivo versionado**, não issue.

## O que é regra viva

Documento que **nasce antes da execução, guia a execução, e é corrigido no mesmo
commit em que a execução o contradiz.** O oposto de spec que envelhece calada.

## Antes de escrever: a regra passa no filtro?

Regra nova só para o que **atravessa para outubro**: banco, RLS, regra de
negócio. É o critério da §2.5 do `CLAUDE.md`.

**Front puro não gera regra.** Vira requisito da stack nova, e o lugar dele é
`docs/regras/000-backlog.md` ou a regra do módulo correspondente.

Se você não souber dizer *o que fica gravado no banco por causa disto*, pare e
pergunte antes de escrever.

## Processo

1. **Não entrevistar de novo.** Sintetize o que a conversa já estabeleceu. Se
   faltar algo que muda o desenho, ele vai para a **seção 7**, não para uma
   rodada de perguntas.

2. **Ler o banco antes de escrever a seção 3.** As migrações em
   `supabase/migrations` são a fonte de verdade do schema, e mais de uma vez o
   que se supunha sobre uma coluna estava errado. A regra 005 nasceu de um achado
   assim: o default de `plans.enabled_modules` era um valor que o trigger da
   própria tabela recusa. **Achado de leitura vale mais que suposição de
   conversa.**

3. **Escolher o número.** Preserve a sequência de `docs/regras/`. Regra nova
   continua a partir de **017**; os números 007 a 012, 014 e 015 estão reservados
   à fila em `docs/regras/fila-de-regras.md`.

4. **Escrever em `docs/regras/NNN-nome-curto.md`**, no formato abaixo. Vocabulário
   do projeto: use `docs/dominio/` e o `CONTEXT.md`, e respeite os ADRs da área
   que você está tocando.

5. **Atualizar a tabela de `docs/regras/README.md`** no mesmo commit.

6. **Não abrir issue aqui.** Isso é o `to-tickets`, e ele roda depois, quando a
   regra entrar em execução. Issue que nasce cedo envelhece: 28 delas foram
   fechadas em 27/08 por isso.

## O formato: sete seções, nesta ordem

```markdown
# NNN · Título curto

> **Regra viva.** Nasce antes da execução, guia a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em DD/MM/AAAA:** <uma linha honesta>. Alvo: <Lovable ou stack nova>.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Origem:** <de onde veio>

---

## 1. O problema

Um parágrafo. O que dói hoje, e o que acontece se ninguém mexer. Sem solução
aqui.

## 2. Requisitos

`FR-001` em diante, com **MUST** e **MUST NOT**, e **cada um com o porquê**.

- **FR-001**: O sistema **MUST** … *Porquê:* …

O porquê não é enfeite: é o que permite alguém em outubro decidir se o requisito
ainda vale. Requisito sem porquê vira cargo cult.

## 3. O que muda no banco

Tabela: objeto, mudança. Coluna, trigger, policy, RPC, migração.

Se a resposta for "nada", escreva **nada**, e diga o que a regra liga ao que já
existe. Esta seção é própria porque **é o que atravessa para outubro**.

## 4. Premissas

O que se está assumindo como verdade. Cada premissa que quebrar é motivo para
parar e corrigir a regra, não para improvisar.

## 5. Dependências

O que precisa estar de pé antes. O que depende desta. Gates e pré-condições que
não são código.

## 6. Como se prova que funciona

Critérios verificáveis, executados por gente. "Implementado ≠ funciona": item sem
prova na tela fecha como *"código lido, não comportamento provado"* e continua
aberto.

Prova automatizada entra aqui também, com o que ela **não** cobre dito em voz
alta.

## 7. A decisão que falta, e precisa do Arthur

A pergunta em aberto, com o que pesa de cada lado e o que fica bloqueado sem ela.

Se não houver nenhuma, escreva **Nenhuma** e diga onde as decisões foram
fechadas. Decisão fechada e cara de reverter vira ADR em `docs/adr/`, não fica
aqui.
```

## O que esta skill não faz

- **Não escreve user story.** Foram removidas do formato em 27/08: as três da
  regra 005 custaram 80 linhas e não apareceram em nenhum commit.
- **Não publica em issue.** O artefato é arquivo, porque arquivo se corrige no
  mesmo commit da mudança de comportamento.
- **Não decide.** O que falta decidir vai para a seção 7, com o custo de cada
  lado escrito. Regra que esconde a decisão pendente trava calada.

## Escrita

Vale `.claude/rules/escrita.md`, e ele vale para o arquivo e para a resposta na
tela: sem travessão, sem barra como conector, sem superlativo sem conta atrás, e
argumento sustentado em dado, não em quem falou.
