# Registro de decisões de arquitetura (ADR)

> Criado em 25/08/2026. Uma decisão por arquivo, no formato ADR.
> Prática importada, sem copiar texto, do projeto OpenClinic. O raciocínio está
> em [`../historico/2026-08-25-openclinic-analise.md`](../historico/2026-08-25-openclinic-analise.md) §3.3.

## Por que esta pasta existe

O projeto tomou decisões caras e as espalhou por quatro lugares: as decisões
`D-1` a `D-13` dentro da triagem de baterias, o `BACKLOG.md`, os handoffs de
fim de dia, e o `CLAUDE.md`. Funciona, e já cobrou o preço: a §2.5 do
`CLAUDE.md` precisou ser escrita em 20/08 porque o critério anterior não estava
registrado em lugar nenhum com data, e ninguém conseguia reconstruir por que
ele era aquele.

Um ADR responde a pergunta que aparece seis meses depois: **por que é assim, e
o que foi descartado.**

## O que entra aqui

Só decisão que é **cara de reverter**. Escolha de stack, critério de correção,
modelo de dado, contrato de módulo, licença.

Não entra: regra de negócio (vive na spec do módulo), achado de segurança (vive
em `docs/historico/`, com a data no nome do arquivo), nem preferência de
implementação.

## Formato

```
# NNNN · Título curto no indicativo

**Situação:** Proposta | Aceita | Substituída por NNNN
**Data:** DD/MM/AAAA
**Decide:** quem tem a palavra final

## Contexto
O que era verdade quando a decisão foi tomada.

## Decisão
Uma frase no indicativo. O que passa a valer.

## Consequências assumidas
O que fica pior por causa desta escolha. Se não houver nenhuma, a
análise não terminou.

## Alternativas descartadas
Cada uma com o motivo. Esta seção é obrigatória.
```

## Três regras de conduta

Valem porque o projeto tem três sócios e nem sempre os três estão na conversa.

1. **Tese vencida não é apagada.** O arquivo de uma decisão substituída ganha
   um aviso no topo apontando para quem a substituiu. Não se reescreve.
2. **O número não se reaproveita**, mesmo que a decisão caia depois.
3. **Decisão não se fecha com sócio ausente.** Encaminhamento verbal no fim de
   uma conversa, com alguém fora dela, não vale como decisão tomada.

## Situação atual

| # | Decisão | Situação | Onde está o texto hoje |
|---|---|---|---|
| 0001 | Sair do Lovable e adotar Next.js, Supabase próprio e Vercel | Aceita | `CLAUDE.md` §2.2 e §2.3, a migrar para cá |
| 0002 | A Lovable é ponte, não destino. Corrigir só o que atravessa | Aceita | `CLAUDE.md` §2.5, a migrar |
| 0003 | Dado atravessa, cálculo de tela não. A régua fina da §2.5 | Aceita | `CLAUDE.md` §2.5, a migrar |
| 0004 | Ponte inversa: correção via repositório, sem consumir crédito | Aceita | `docs/ponte/ponte-inversa.md`, a migrar |
| 0005 | As 15 ModuleKeys são contrato único | Aceita | constituição, Princípio III |
| 0006 | Nada de terceiro sob licença copyleft entra no repositório | Aceita | análise do OpenClinic §2 |
| 0007 | Cobrança por faixa de usuário, e não por profissional de saúde | Aceita | pesquisa de precificação §10.2 |
| 0008 | 16ª ModuleKey `residuos` exige emenda à constituição | **Em aberto** | `docs/regras/013-residuos-conformidade.md` |

> A numeração acima era um **índice de onde cada decisão vive**, montado antes de
> existir arquivo. Os arquivos começaram a ser escritos em 25/08 e usam a sua
> própria sequência, abaixo. Quando as decisões da tabela acima virarem arquivo,
> elas entram na sequência de baixo e a tabela some.

## Decisões com arquivo próprio

| # | Decisão | Situação |
|---|---|---|
| [0001](./0001-consultas-sai-do-contrato-de-modulos.md) | A ModuleKey `consultas` sai do contrato | Proposta, **preparada e não aplicada** |
| [0002](./0002-sem-cifra-em-coluna-por-enquanto.md) | Nenhuma coluna de dado de saúde é cifrada na aplicação | Proposta |
| [0003](./0003-onde-o-nexclin-roda.md) | Ficar em Supabase e Vercel, não migrar de provedor | Aceita |
| [0004](./0004-o-spec-kit-sai.md) | O Spec Kit sai do projeto, contra a recomendação | Aceita |
| [0005](./0005-bifurcar-o-to-spec.md) | O `to-spec` é bifurcado em `nx-regra` | Aceita |

**As duas primeiras foram decididas pelo executor em 25/08, sob delegação
explícita do Arthur**, que pediu para decidir pela documentação em vez de
interromper. As duas trazem a seção *Como reverter*, e nenhuma alterou banco,
constituição ou código.

**A 0003 é o documento de hospedagem de 23/08**, que morava em
`docs/arquitetura/` e virou ADR na reorganização de 27/08, sem mudar uma palavra
do corpo. **A 0004 e a 0005 nasceram na própria reorganização.**

**Estado desta pasta:** cinco arquivos; as decisões da tabela de cima ainda não
foram migradas, e a numeração delas não conversa com a dos arquivos.
Migrar o texto de cada linha para o seu próprio ADR é a tarefa OC-4 da análise
do OpenClinic, e ela é trabalho de depois do lançamento. Até lá, esta tabela é
o índice de onde cada decisão vive.
