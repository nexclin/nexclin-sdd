---
name: nx-modulo
description: Reconstrói um dos 15 módulos do NexClin na stack Next.js, do levantamento da regra até o aceite manual. Use quando for portar uma área da clínica (pacientes, atendimentos, consultas, tarefas, contas a receber/pagar, fluxo de caixa, anamnese, relatórios, configurações, dashboard, insights, equipe) do MVP de referência para o app novo.
---

# Reconstruir um módulo

Esta skill não substitui o Spec Kit — ela **enquadra** o Spec Kit para o caso
específico de portar um dos 15 módulos, acrescentando os portões de domínio
que uma spec genérica não cobre.

> **Ritmo.** O lançamento de 01/09 acontece na plataforma atual. A stack nova
> é obra de fundo, feita com calma, e a migração só ocorre quando ela fizer
> tudo o que a atual faz. Nenhum módulo é apressado para "chegar a tempo" —
> não há tempo a que chegar. Segurança do dado do cliente ganha de velocidade
> em toda decisão.

## Antes de começar — três checagens

1. **O módulo está na onda certa?** Ordem definida no plano de lançamento:
   - **Onda 1** — configuracoes, pacientes, leads (atendimentos), consultas
     (acompanhamento), tarefas, contas_receber, dashboard
   - **Onda 2** — contas_pagar, fluxo_caixa, anamnese, relatorios_vendas
   - **Onda 3** — relatorios_demais, insights, equipe

   Fora de ordem só com motivo escrito. `relatorios_demais` inclui o **repasse**,
   que não sobe enquanto o imposto estiver fixado em zero: para público médico,
   número errado ali custa confiança.

2. **A chave é uma das 15?** String exata, igual em rota, menu, plano e
   permissão. Se a resposta for "quase", pare: módulo novo exige emenda à
   constituição.

3. **Tem cheiro de nicho?** Chame o agente `consultor-vertical` antes de
   escrever a spec.

## O caminho

**1 · Levantar a regra (não o estilo)**

Três fontes, nesta ordem de autoridade:
- `INVENTARIO.md` §3.4 — a lógica embutida, já destilada
- `INVENTARIO-UI.md` — como a tela se comporta e o que ela mostra
- `../nexclin-lovable` — o código, **somente leitura**, quando as duas acima
  não bastarem

Anote as regras que não são óbvias na tela: dias úteis (domingo nunca conta,
sábado só se `work_saturday`), idempotência de recebíveis, `confirmation_hours`
armazenado em horas e exibido em dias, cálculo de taxa por método.

**2 · Spec e plano**

`/speckit-specify` → `/speckit-plan` → `/speckit-tasks`. A spec precisa
declarar, explicitamente:
- a ModuleKey e o guard que protege a rota
- quais tabelas e RPCs o módulo toca
- os estados vazio, carregando, erro e bloqueado-por-plano
- os critérios de aceite manuais (§4 abaixo)

**3 · Executar**

`/speckit-implement`, commits atômicos, parando nas fases. O hook
`guarda-constituicao` roda sozinho a cada escrita; não o contorne.

Dívidas da referência que **não** se replicam estão em `.claude/rules/app.md`
— um só componente de período, cadastro sem filtro temporal, enum nunca cru na
tela, hooks antes de early-return.

**4 · Fechar**

- Agente `auditor-multitenant` sobre o que foi escrito.
- Aceite manual pelo Arthur — "implementado ≠ funciona". Sem isso a fase não
  fecha, mesmo com build verde e teste passando.
- Teste automatizado mínimo no guard e na resolução de permissão do módulo.

## Sinal de que você errou o caminho

Se em algum momento a regra de acesso estiver vivendo no componente React em
vez de no banco, pare e volte à migração. A tela reflete; ela não decide.
