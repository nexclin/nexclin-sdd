---
paths:
  - "docs/**"
  - "CLAUDE.md"
  - "README.md"
---

# Estrutura: onde cada documento nasce

Vale para todo arquivo que você criar dentro de `docs/`, e para qualquer coisa
que você pensar em criar na raiz. Escrita em 27/08/2026, junto da reorganização
que levou `docs/` de dez pastas por assunto para **sete por pergunta**.

**Isto é uma rule, e não um hook, de propósito.** Hook recusaria pasta nova
legítima, e a resposta natural a um hook que atrapalha é contorná-lo. Se em duas
semanas a bagunça voltar, aí o hook nasce, com uma falha real atrás.

## As sete pastas, e a pergunta de cada uma

| Pasta | Pergunta que ela responde |
|---|---|
| `docs/regras/` | o que o sistema deve fazer |
| `docs/historico/` | o que aconteceu |
| `docs/adr/` | por que é assim, e o que foi descartado |
| `docs/dominio/` | o que as palavras significam |
| `docs/ponte/` | como a correção chega à plataforma ao vivo |
| `docs/harness/` | como este repositório dirige o Claude Code |
| `docs/referencia/` | o que existe hoje |

**Não crie a oitava.** Antes de criar pasta, escreva em uma frase a pergunta que
ela responde e confira se alguma das sete já responde. Na prática, sempre
responde. `orquestracao`, `arquitetura` e `compartilhavel` tinham **um arquivo
cada**, e existiam porque parecia arrumado dar um lugar a cada assunto. Foi isso
que fez as pessoas escolherem errado onde escrever.

Se você concluir que precisa mesmo de uma pasta nova, isso é uma decisão de
estrutura: **pare e pergunte ao Arthur**, não crie e siga.

## Antes de criar arquivo, três perguntas

**1. Isto é registro de um momento?** Handoff, triagem, revisão de segurança,
relatório, análise, verificação, mensagem para os sócios. Então é
`docs/historico/`, e **o nome começa com `AAAA-MM-DD`**. Sem exceção: é o
prefixo de data que faz a pasta se ordenar sozinha, e é por ele que o handoff
mais recente é encontrado sem índice.

**2. Isto diz como o sistema deve se comportar?** Então é `docs/regras/`, no
formato de sete seções, pela skill `nx-regra`. Um arquivo por regra, numerado.
Regra nova continua a partir de **017**.

**3. Isto é uma decisão cara de reverter?** Então é `docs/adr/NNNN-titulo.md`,
com as alternativas recusadas e o motivo. Decisão fechada sai da regra e vem
para cá; a regra fica só com o que **falta** decidir.

Nenhuma das três? Consulte a tabela da seção 3 de
[`docs/README.md`](../../docs/README.md), que é mais completa.

## Estado de execução não é arquivo

Tarefa pendente vive em **issue do GitHub**, em `nexclin/nexclin-sdd`. Não crie
`tasks.md`, nem lista de pendências dentro de uma regra, nem arquivo de estado
paralelo ao handoff. Foi exatamente isso que a reorganização desfez: 28 issues
pararam de ser tocadas porque o estado real estava num `tasks.md`, e ninguém
mais olhou nenhuma delas.

**Estado duplicado não fica desatualizado às vezes, fica sempre.**

## A raiz do repositório é fechada

Ficam lá três arquivos, e só: `README.md`, a porta de entrada de quem clona;
`CLAUDE.md`, lido a todo turno; e `CONTEXT.md`, o glossário, que mora na raiz
porque é onde as skills o procuram. Documento novo na raiz vai para `docs/`.

**`CONTEXT.md` tem teto de 60 linhas, e ele é a regra.** Entra só termo que **já
causou confusão real**, com uma linha de definição e um exemplo de uso errado.
Termo que nunca foi mal-entendido custa token e não evita nada. É o princípio da
catraca aplicado ao vocabulário. Ele é glossário, e não spec, rascunho nem
depósito de decisão de implementação.

## Quando você move ou renomeia

**Conserte os links no mesmo commit**, incluindo os de `.claude/`. E se o arquivo
movido era citado por comentário de código, **não edite o código para consertar**:
`app/`, `lib/`, `e2e/`, `scripts/` e `supabase/` estão fora do alcance de trabalho
de documentação. Acrescente a linha na tabela da seção 4 de `docs/README.md`, que
é a tradução de caminho antigo para caminho novo.

## O nome do arquivo

Minúsculas, hífen entre palavras, sem acento e sem espaço. Em `historico/`, a
data primeiro. O nome deve dizer **o que o documento é**, não o assunto genérico:
`2026-08-20-triagem-baterias-vinicius.md`, não `notas.md`.
