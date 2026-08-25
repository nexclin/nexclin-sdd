# Índice da documentação do NexClin

> Ponto de entrada da árvore `docs/`. Montado em 25/08/2026.
> Se você é uma sessão nova do Claude Code, leia na ordem da seção 1.

---

## 1. A ordem de leitura, para quem chega agora

| # | Arquivo | Por que este primeiro |
|---|---|---|
| 1 | [`../CLAUDE.md`](../CLAUDE.md) | o que é o projeto, o prazo vivo, e a §2.5, que decide o que se corrige |
| 2 | [`orquestracao/mapa-de-execucao.md`](orquestracao/mapa-de-execucao.md) | o que está pendente, em que ordem, o que roda em paralelo |
| 3 | [`planejamento/handoffs/`](planejamento/handoffs/) | o estado real ao fim do último dia de trabalho |
| 4 | [`ponte/ponte-inversa.md`](ponte/ponte-inversa.md) | **obrigatório** antes de tocar a plataforma ao vivo |
| 5 | [`../.specify/memory/constitution.md`](../.specify/memory/constitution.md) | a lei do repositório, vence qualquer preferência |

---

## 2. As pastas, e o que cada uma guarda

### `orquestracao/` · o que fazer e em que ordem
O grafo de dependências, o inventário de specs pendentes, as raias paralelas e
o calendário. É o documento de coordenação.

### `planejamento/` · o histórico datado das decisões de execução
Baterias de teste, triagem de apontamentos, handoffs de fim de dia, calendário,
análises pontuais, mensagens para os sócios. Ordem cronológica, nome com data.

### `harness/` · por que a pasta `.claude/` tem a forma que tem
O princípio da catraca, as camadas, e a lista pesquisada de skills e plugins de
terceiros a importar, com licença de cada um.

### `dominio/` · o vocabulário do produto
As 15 ModuleKeys e as ondas de reconstrução. Os quatro verticais (médico ativo,
psicologia e estética na fila, odontologia fechada).

### `ponte/` · o procedimento da plataforma ao vivo
Como a correção chega ao cliente sem consumir crédito, e as três armadilhas que
já custaram tempo real.

### `seguranca/` · revisões datadas, uma por achado
Auditorias de RLS, achados de vulnerabilidade, registro de exports do banco.
Cada arquivo é um achado com data, evidência e classificação de faixa.

### `marca/` · identidade visual
Paleta, tipografia, padrão de barra lateral.

### `decisions/` · as decisões caras, uma por arquivo
Registro de decisão de arquitetura no formato ADR: contexto, decisão,
consequências assumidas, e **as alternativas descartadas com o motivo**.

### `compartilhavel/` · material que sai do projeto
O que pode ser publicado ou mostrado fora da sociedade.

---

## 3. Onde cada tipo de coisa deve nascer

Erra-se muito aqui, e o custo aparece quando ninguém encontra a decisão de
volta. A regra:

| O que você tem na mão | Onde vai |
|---|---|
| Decisão de arquitetura cara de reverter | `decisions/NNNN-titulo.md` |
| Regra de negócio nova, ou mudança de regra | dentro da spec do módulo, em `specs/` |
| Achado de segurança | `seguranca/<assunto>-<data>.md` |
| Apontamento de bateria de teste | `planejamento/triagem-*.md` |
| Estado ao fim do dia | `planejamento/handoffs/<data>.md` |
| Mudança no que fazer primeiro | `orquestracao/mapa-de-execucao.md` |
| Procedimento longo que se repete | skill em `.claude/skills/` |
| Restrição que vale para uma área de arquivo | rule em `.claude/rules/` |
| Verificação que precisa rodar toda vez | hook em `.claude/hooks/` |

A última linha das três é o critério do [`harness/README.md`](harness/README.md):
*"toda vez que X" vira hook; restrição de área vira rule; procedimento longo
vira skill; trabalho paralelo vira agente.*

---

## 4. O que este índice não cobre

- `specs/` tem índice próprio na [`fila de especificações`](planejamento/fila-especificacoes.md)
  e no [`BACKLOG`](../specs/BACKLOG.md).
- `INVENTARIO.md` e `INVENTARIO-UI.md`, na raiz, são o levantamento do MVP de
  referência. São grandes, são consulta, e não mudam.
- Os dois `.html` na raiz (pesquisa de mercado e plano até o lançamento) são
  entregas fechadas, não documentos vivos.
