---
name: nx-paralelo
description: Executa várias frentes do NexClin ao mesmo tempo sem que elas colidam. Use quando houver duas ou mais tarefas independentes na fila (correção na Ponte, Fase 2 do banco, spec da stack nova, código do app novo) e o Arthur quiser avançar em paralelo em vez de uma de cada vez. Também use antes de disparar qualquer subagente, para decidir se as tarefas realmente são independentes.
---

# Executar em paralelo no NexClin

Este projeto tem três frentes com ritmos diferentes e prazos diferentes.
Elas **não disputam o mesmo tempo**, mas disputam os mesmos arquivos quando
mal despachadas. Esta skill decide o que pode correr junto e como isolar.

**Anuncie ao começar:** "Usando a skill nx-paralelo para separar as raias."

---

## Passo 1: o único teste que importa

Duas tarefas podem correr ao mesmo tempo se, e somente se:

1. **não escrevem no mesmo arquivo**, e
2. **não escrevem no mesmo banco antes do export estar feito**, e
3. **nenhuma depende do resultado da outra**.

Falhou qualquer um dos três, é sequencial. Não existe quarto critério, e não
existe "provavelmente dá certo".

## Passo 2: identificar a raia de cada tarefa

| Raia | Diretório que ela escreve | Prazo |
|---|---|---|
| **P** Ponte | `../nexclin-lovable/src` | 08/09 |
| **B** Banco | `supabase/migrations` nos dois repositórios | 08/09 |
| **N1** Regra viva | `docs/regras/` | sem prazo |
| **N2** App novo | `app/`, `lib/` | sem prazo |
| **D** Documento | `docs/` | sem prazo |
| **H** Arthur | painel Supabase, plataforma ao vivo | varia |

**A regra de bolso:** N1, N2 e D são sempre seguras de disparar junto com
qualquer coisa, porque a stack nova e a plataforma Lovable são árvores de
arquivo diferentes. É paralelismo de graça, e é onde começar.

**P com P exige conferir o arquivo.** Duas correções de relatório de vendas
tocam o mesmo `.tsx` e vão brigar. Duas correções em telas diferentes, não.

**B não começa antes do export.** O `T004` da SPEC 002 é gate absoluto: o
export é assíncrono, chega por e-mail e só pode ser pedido **uma vez a cada
24 horas**. Escrever no banco antes dele é apostar sem ponto de retorno.

## Passo 3: escolher o isolamento

Três níveis, do mais barato ao mais caro. Use o mais barato que resolva.

**Nível 0, sem isolamento.** Raias diferentes já escrevem em diretórios
diferentes. Não crie worktree para isso; é cerimônia sem ganho.

**Nível 1, subagente com contexto construído.** Para tarefas de leitura,
investigação ou escrita de documento. O subagente não herda esta conversa:
monte a instrução dele com exatamente o que a tarefa precisa, incluindo o
caminho dos arquivos e o critério de pronto. Contexto herdado é o que faz
subagente sair do escopo.

**Nível 2, worktree git.** Só quando duas tarefas **precisam** escrever no
mesmo repositório em arquivos que podem se cruzar. Antes de criar, confira se
já não está isolado:

```bash
test "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" && echo "repo normal" || echo "já em worktree"
```

Se já estiver em worktree, **não crie outro**.

## Passo 4: o que nunca paraleliza

Isto não é preferência, é consequência de incidente real deste projeto:

- **Publicação na Lovable.** O `Publish` é global e sequencial. Duas raias
  publicando ao mesmo tempo sobrescrevem uma à outra. E a ordem obrigatória
  continua sendo **edge function antes do front**, conforme
  `docs/ponte/ponte-inversa.md`.
- **Migração de banco.** Uma por vez, sempre, e só depois do export.
- **Aceite manual.** Só o Arthur executa, e ele é um.
- **Correção de policy de permissão na semana de lançamento.** Decidido em
  25/08 e vale para a autoconcessão em `team_members`.

## Passo 5: o gate de tipo antes de qualquer envio à Ponte

Herdado do incidente de 20/08, que derrubou o app por 1h35. Vale mesmo em
paralelo, e vale mais ainda em paralelo, porque com várias raias ninguém
lembra qual mexeu no quê.

`npm run build` **não basta**: o Vite usa esbuild, que remove tipo sem
checar. E `tsc -p tsconfig.json` também não serve, porque o projeto usa
`references` com `"files": []` e esse comando checa zero arquivos, sempre
verde. O certo é **`tsconfig.app.json`**, e o gate já está em
`scripts/ponte.sh enviar`.

## Passo 6: fechar a raia

Cada raia fecha com três coisas, na ordem:

1. **O que foi feito**, em uma linha, no commit.
2. **A prova**, que é a saída do teste ou o passo manual executado, nunca
   "deve funcionar".
3. **A linha atualizada** em `docs/historico/2026-08-25-mapa-de-execucao.md`, no mesmo
   commit. Mapa desatualizado dá confiança falsa, que é pior que mapa nenhum.

---

## Onde isto veio de

O grafo de dependências e as raias vivem em
`docs/historico/2026-08-25-mapa-de-execucao.md`. Consulte-o antes de decidir a ordem;
esta skill diz **como** despachar, ele diz **o quê**.

A técnica de despacho paralelo e de worktree tem versão madura e de licença
permissiva no `superpowers` (`dispatching-parallel-agents`,
`using-git-worktrees`, `subagent-driven-development`). Quando ele estiver
instalado, use as três e trate esta skill como a camada específica do NexClin
que decide **as raias** e **o gate da Ponte**, que nenhuma skill genérica
conhece. Lista e critério de importação em
`docs/harness/importacoes-2026-08-25.md`.
