# Regras vivas

**Regra viva:** documento que nasce antes da execução, guia a execução, e é
corrigido no mesmo commit em que a execução o contradiz. O oposto de spec que
envelhece calada.

Um arquivo por regra. **O número é preservado** de quando isto se chamava
`specs/`, porque "SPEC 006" e "T017" são referência viva em commits e handoffs de
agosto. Regra nova continua a partir de 017.

## O que está aqui

| # | Regra | Estado |
|---|---|---|
| [000](000-backlog.md) | Backlog: a fila de onde as próximas regras saem | fila |
| [001](001-fundacao-superadmin.md) | Fundação: banco, auth, multi-tenant e Super Admin | executada, **3 provas abertas** |
| [002](002-seguranca-anamnese-auditoria.md) | Segurança: anamnese pública e auditoria de paciente | Fase 2 **escrita, não aplicada** |
| [003](003-superadmin-blindado.md) | Super Admin finalizado e blindado | proposta · formato antigo |
| [004](004-correcao-bateria-vinicius.md) | Correção da 1ª bateria de testes | 20 de 23 fechados |
| [005](005-configuracoes-clinica.md) | Configurações da clínica | escrita, não executada |
| [006](006-modelagem-ini.md) | Modelagem INI: cobrança, precificação, ocupação, recall | implantada na Lovable |
| [013](013-residuos-conformidade.md) | Resíduos e conformidade documental | **parada** · formato antigo |
| [016](016-endurecimento-seguranca.md) | Endurecimento de segurança pré-lançamento | auditoria · formato antigo |

Os números 007 a 012, 014 e 015 seguem reservados à fila em
`fila-de-regras.md`.

## O formato, em sete seções

1. O problema, em um parágrafo
2. Requisitos numerados (`FR-001`), **cada um com o porquê**
3. O que muda no banco
4. Premissas
5. Dependências
6. Como se prova que funciona
7. A decisão que falta, e precisa do Arthur

A seção 3 é própria porque é o que atravessa para outubro. A seção 7 é o que
impede uma regra de travar em silêncio: decisão que falta e não está escrita vira
uma volta de pergunta, e cada volta é um turno.

**Decisão fechada não fica aqui.** Ela vira ADR, em `../adr/`. Esta pasta lista
só o que **falta** decidir.

## Onde mora o estado de execução

Nas **issues do GitHub**, em `nexclin/nexclin-sdd`, não dentro destes arquivos.
As 28 issues abertas em 03/08 a partir do `tasks.md` da SPEC 001 foram fechadas
em 27/08, e nasceram 15 no lugar: doze da regra 002 e três da 001. As demais
tarefas em aberto continuam como **texto dentro da regra**, e viram issue quando
entrarem em execução. Issue que ninguém toca em duas semanas envelhece igual às
28 que foram fechadas, e aí ninguém olha mais nenhuma.

## Quando escrever uma regra nova

Só para o que **atravessa para outubro**: banco, RLS, regra de negócio. Front
puro não gera regra, vira requisito da stack nova. É o critério da §2.5 do
`CLAUDE.md`.

Use a skill `nx-regra`. Ela escreve nas sete seções, direto neste diretório.

## Quando corrigir uma que existe

Mudança que altera comportamento descrito numa regra **atualiza a regra no mesmo
commit**. Não no fim do dia, não no handoff. É o que separa regra viva de spec
que envelheceu.

## Três documentos estão no formato antigo

003, 013 e 016 foram **movidos, não reescritos**, em 27/08/2026, e trazem aviso
no topo dizendo por quê. Cada um volta ao formato de sete seções quando voltar à
fila, antes de virar execução.
