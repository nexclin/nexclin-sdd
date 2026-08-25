---
paths:
  - "**/*.md"
  - "docs/**"
  - "specs/**"
  - "CLAUDE.md"
  - ".specify/**"
---

# Escrita: como este projeto escreve

Vale para **todo texto produzido aqui**: documento, spec, commit, mensagem para
o grupo e a resposta na tela. Pedida pelo Arthur em 25/08/2026.

Pelo princípio da catraca do `docs/harness/README.md`, cada item abaixo
rastreia a uma correção real, com data. Nada preventivo, nada genérico.

## 1. Travessão está proibido

Não use `—` nem `–`. Em nenhum contexto: nem para aposto, nem para pausa, nem
para separar cláusula.

Use no lugar: vírgula, ponto, dois-pontos, parêntese, ou duas frases.

- Errado: `A regra é simples — corrigir só o que atravessa.`
- Certo: `A regra é simples: corrigir só o que atravessa.`
- Certo: `A regra é simples. Corrige-se só o que atravessa.`

**Rastreio:** corrigido pelo Arthur em 25/08/2026, e não era a primeira vez que
ele pedia. É o tique de escrita de IA mais visível que existe, e mensagem para
sócio com travessão a cada parágrafo entrega quem escreveu.

## 2. Barra como conector também não

Não use `/` para ligar duas ideias (`gestão/operação`, `custo/benefício`).
Escreva `e`, `ou`, ou separe.

Exceções legítimas, porque não são conector: caminho de arquivo
(`docs/harness/`), data (`25/08`), fração e unidade (`R$/mês`), e sigla
consagrada (`E/S`).

**Rastreio:** mesmo pedido, mesma data.

## 3. Argumento se sustenta em dado, não em quem falou

Não repita o nome de uma pessoa como se fosse a autoridade do argumento
(`o Vinícius derrubou`, `como o Arthur decidiu`, três vezes no mesmo texto).
Cite uma vez para dar contexto, se ajudar, e depois sustente com o dado, a
norma ou o número.

- Errado: `O Vinícius derrubou o argumento do vídeo.`
- Certo: `A pesquisa não sustenta esse argumento: a fiscalização é inconstante
  e a exigência muda por estado.`

**Rastreio:** 25/08/2026, na mensagem para o grupo. Texto que apoia tudo em
"fulano disse" vira discussão sobre pessoas em vez de sobre o problema.

## 4. Superlativo precisa de conta atrás

Nada de `o mais caro possível`, `o maior erro`, `zero risco` sem número que
sustente. Se não há conta, escreva o fato e pare.

**Rastreio:** 25/08/2026. A frase "construir na Lovable é o desperdício mais
caro possível" era falsa: com a ponte inversa não se gasta crédito para
construir, e o banco migra intacto. O superlativo quase matou uma
funcionalidade legítima. A precisão ficou registrada na §2.5 do `CLAUDE.md`.

## 5. Mensagem de WhatsApp tem forma própria

Quando o pedido for "monte uma mensagem para o grupo":

- parágrafo curto, bloco numerado ou com marcador, e negrito só no que decide;
- sem cabeçalho de documento, sem tabela, sem nota de rodapé;
- o essencial nas primeiras linhas, porque ninguém rola até o fim;
- termina com o que a pessoa precisa fazer ou responder.

**Rastreio:** 25/08/2026. A primeira versão tinha forma de relatório e foi
devolvida.

## 6. Vale para a resposta na tela também

Esta regra não é só sobre arquivo `.md`. A resposta que aparece para o Arthur
no terminal segue os mesmos seis itens. É o texto que ele lê mais vezes por dia.
