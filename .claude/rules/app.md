---
paths:
  - "app/**"
  - "lib/**"
  - "middleware.ts"
---

# App Next.js — regras de camada

## A tela reflete, não decide

O frontend **espelha** o que o banco já garante. `can(modulo)` no cliente
existe para esconder menu e evitar clique morto — nunca como fronteira de
segurança. A fronteira é RLS + as RPCs `my_permission`,
`get_my_subscription_state`, `superadmin_*`.

Consequência prática: toda rota protegida precisa de RLS por trás. Se você
consegue imaginar um `fetch` direto que traria dado de outra clínica, o
problema está na migração, não no componente.

## Ordem da cascata de acesso (espelha o banco, não invente outra)

1. Impersonando → libera
2. Assinatura `suspended`/`cancelled` → bloqueia
3. Módulo fora do `enabled_modules` do plano → bloqueia
4. Permissão individual do `team_member`
5. Fallback → `none`

**O plano é o teto; a permissão individual distribui abaixo dele.**

## Server vs Client

Padrão: Server Component. Vire client só quando houver estado de interação
real — drag-and-drop do funil, diálogos, filtros com estado, gráficos.
Listagens, tabelas e relatórios são server por default; o filtro de período
viaja em `searchParams`, não em `useState`.

## As 15 ModuleKeys

`dashboard, leads, pacientes, anamnese, consultas, acompanhamento, tarefas,
contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas,
relatorios_demais, configuracoes, equipe, insights`

Strings exatas. Rota, item de menu, plano e permissão usam a mesma chave.
Módulo novo exige emenda à constituição (Princípio III).

## Dívidas conhecidas da referência — não replique

Levantadas no walkthrough de 16/08 (`INVENTARIO-UI.md`, seção 5):

- **Um** componente de período para todo o app. A referência tem três
  vocabulários diferentes convivendo.
- Lista de cadastro (pacientes) **não** filtra por período por padrão — na
  referência isso faz a base parecer vazia.
- Rótulo de enum nunca vai cru para a tela (`confirmacao` → "Confirmação").
- Hooks antes de qualquer early-return nos guards. O shell da referência
  quebra intermitentemente com React #310 por causa disso.
