# Índice da documentação do NexClin

> Ponto de entrada da árvore `docs/`. Reorganizada em 27/08/2026: eram dez
> pastas por assunto, hoje são **sete, uma pergunta cada**.
> Se você é uma sessão nova do Claude Code, leia na ordem da seção 1.

---

## 1. A ordem de leitura, para quem chega agora

| # | Arquivo | Por que este primeiro |
|---|---|---|
| 1 | [`../CLAUDE.md`](../CLAUDE.md) | o que é o projeto, o prazo vivo, e a §2.5, que decide o que se corrige |
| 2 | o handoff mais recente em [`historico/`](historico/) | o estado real ao fim do último dia de trabalho. Os nomes começam com a data: pegue o maior |
| 3 | [`regras/README.md`](regras/README.md) | o que o sistema deve fazer, e o que ainda falta decidir |
| 4 | [`ponte/ponte-inversa.md`](ponte/ponte-inversa.md) | **obrigatório** antes de tocar a plataforma ao vivo |
| 5 | [`constituicao.md`](constituicao.md) | a lei do repositório, vence qualquer preferência |

---

## 2. As sete pastas, e a pergunta que cada uma responde

### `regras/` · o que o sistema deve fazer
Uma **regra viva** por arquivo, numerada, no formato de sete seções. Regra viva
nasce antes da execução, guia a execução, e é corrigida no mesmo commit em que a
execução a contradiz. Inclui o `000-backlog.md`, que é a fila.

### `historico/` · o que aconteceu
Tudo que é registro de um momento: handoffs de fim de dia, triagem de baterias,
revisões de segurança, relatórios para os sócios, análises pontuais, verificações.
**Todo nome começa com `AAAA-MM-DD`**, e é isso que faz a pasta se ordenar
sozinha. O arquivo mais recente é o estado mais recente.

### `adr/` · por que é assim, e o que foi descartado
Decisão cara de reverter, uma por arquivo, numerada. Contexto, decisão,
consequências assumidas, e **as alternativas recusadas com o motivo**. Responde a
pergunta que aparece seis meses depois.

### `dominio/` · o que as palavras significam
As 15 ModuleKeys e as ondas de reconstrução. Os quatro verticais: médico ativo,
psicologia e estética na fila, odontologia fechada.

### `ponte/` · como a correção chega à plataforma ao vivo
O procedimento sem consumo de crédito, as três armadilhas que já custaram tempo
real, os blocos de SQL para colar à mão, e o registro de exports do banco.

### `harness/` · como este repositório dirige o Claude Code
O princípio da catraca, as camadas de hook, rule, skill e agente, e a
proveniência do que foi importado de terceiros.

### `referencia/` · o que existe hoje
Consulta, não decisão: o inventário do schema replicado, os contratos de RPC,
guards e edge functions, os tokens de marca, e a modelagem do INI.

---

## 3. Onde cada tipo de coisa deve nascer

Erra-se muito aqui, e o custo aparece quando ninguém encontra a decisão de
volta. A regra:

| O que você tem na mão | Onde vai |
|---|---|
| Decisão de arquitetura cara de reverter | `adr/NNNN-titulo.md` |
| Regra de negócio nova, ou mudança de regra | `regras/NNN-nome.md`, pela skill `nx-regra` |
| Estado de execução de uma tarefa | **issue do GitHub**, não arquivo |
| Achado de segurança | `historico/AAAA-MM-DD-assunto.md` |
| Apontamento de bateria de teste | `historico/AAAA-MM-DD-triagem-*.md` |
| Estado ao fim do dia | `historico/AAAA-MM-DD-handoff-*.md` |
| Levantamento do que existe | `referencia/` |
| Procedimento que toca a plataforma ao vivo | `ponte/` |
| Procedimento longo que se repete | skill em `.claude/skills/` |
| Restrição que vale para uma área de arquivo | rule em `.claude/rules/` |
| Verificação que precisa rodar toda vez | hook em `.claude/hooks/` |

As três últimas linhas são o critério do
[`harness/README.md`](harness/README.md): *"toda vez que X" vira hook; restrição
de área vira rule; procedimento longo vira skill; trabalho paralelo vira agente.*

**A regra que fecha o ciclo:** mudança que altera comportamento descrito numa
regra **atualiza a regra no mesmo commit**. Não no fim do dia, não no handoff.

---

## 4. Onde as coisas foram parar em 27/08/2026

Se você seguiu um link antigo e ele não abre, é por isto. Nenhum arquivo foi
apagado, exceto os `plan.md` e `tasks.md` das specs, que viraram issue.

| Era | Virou |
|---|---|
| `specs/NNN-nome/spec.md` | `docs/regras/NNN-nome.md` |
| `specs/NNN-nome/plan.md` e `tasks.md` | **apagados**; o estado vive nas issues |
| `specs/BACKLOG.md` | `docs/regras/000-backlog.md` |
| `.specify/memory/constitution.md` | `docs/constituicao.md` |
| `docs/decisions/` | `docs/adr/` |
| `docs/planejamento/` | `docs/historico/`, com data no início do nome |
| `docs/planejamento/handoffs/` | `docs/historico/AAAA-MM-DD-handoff-*.md` |
| `docs/seguranca/` | `docs/historico/`, com data no início do nome |
| `docs/orquestracao/mapa-de-execucao.md` | `docs/historico/2026-08-25-mapa-de-execucao.md` |
| `docs/arquitetura/hospedagem-*.md` | `docs/adr/0003-onde-o-nexclin-roda.md` |
| `docs/marca/` | `docs/referencia/marca-*.md` |
| `docs/compartilhavel/` | `docs/harness/kit-compartilhavel.md` |
| `INVENTARIO.md` e `INVENTARIO-UI.md`, na raiz | `docs/referencia/` |
| `nexclin.html`, na raiz | `docs/referencia/brand-book.html` |
| `RELATORIO-SEMANAL.md`, na raiz | `docs/historico/2026-08-03-relatorio-semanal.md` |
| `WORKFLOW-GITHUB.md`, na raiz | `docs/harness/workflow-github.md` |
| os dois `.html` de pesquisa e de plano, na raiz | **apagados** |
| `CLAUDE nexclin.md`, na raiz | **apagado**, era cópia de 29/07 |

**Duas exceções, e as duas são deliberadas.** O `docs/seguranca/nota-sql-editor`
e o `registro-exports-banco` foram para `ponte/`, porque são procedimento da
plataforma ao vivo e não registro do passado. E **nenhum arquivo de código foi
tocado**: `app/`, `lib/`, `e2e/`, `scripts/` e `supabase/` ficaram intactos, então
comentários de código que citam caminhos antigos continuam citando. A tabela
acima é a tradução.

---

## 5. O que este índice não cobre

- `docs/historico/2026-08-25-mapa-de-execucao.md` **está desatualizado de
  propósito**: ele contava tarefas nos `tasks.md`, que não existem mais. Ficou
  como registro. Quem responde "o que faço agora" hoje é o handoff mais recente,
  mais as issues abertas.
- [`referencia/INVENTARIO.md`](referencia/INVENTARIO.md) e
  [`referencia/INVENTARIO-UI.md`](referencia/INVENTARIO-UI.md) são o levantamento
  do MVP de referência. São grandes, são consulta, e não mudam.
- **Os dois `.html` da raiz foram apagados em 27/08:** a pesquisa de mercado e o
  plano até o lançamento. Eram 240 KB de página salva do navegador, com pasta de
  assets junto, e o conteúdo deles já tinha sido absorvido pelos documentos
  datados de `historico/`. Continuam no histórico do git. O brand book, esse
  ficou: virou [`referencia/brand-book.html`](referencia/brand-book.html).
