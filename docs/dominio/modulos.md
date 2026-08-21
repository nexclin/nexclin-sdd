# As 15 ModuleKeys — contrato único

Strings exatas. Plano, permissão individual, rota e item de menu usam as
mesmas. Módulo novo exige emenda à constituição (Princípio III).

| ModuleKey | Rota | Grupo | Onda |
|---|---|---|---|
| `dashboard` | `/` | Operação | 1 |
| `configuracoes` | `/configuracoes` | Sistema | 1 |
| `pacientes` | `/pacientes` | Operação | 1 |
| `leads` | `/atendimentos` | Operação | 1 |
| `acompanhamento` | `/acompanhamento` | Operação | 1 |
| `tarefas` | `/tarefas` | Operação | 1 |
| `contas_receber` | `/contas-receber` | Financeiro | 1 |
| `contas_pagar` | `/contas-pagar` | Financeiro | 2 |
| `fluxo_caixa` | `/fluxo-caixa` | Financeiro | 2 |
| `anamnese` | `/anamnese` | Clínico | 2 |
| `relatorios_vendas` | `/relatorios/vendas` | Análise | 2 |
| `relatorios_demais` | `/relatorios/*` | Análise | 3 |
| `insights` | `/insights` | Análise | 3 |
| `equipe` | dentro de `/configuracoes` | Sistema | 3 |
| `consultas` | — | — | ver nota |

**Nota sobre `consultas`.** A chave existe no contrato, mas a tela rotulada
"Consultas" no menu aponta para `/acompanhamento`, protegida pela chave
`acompanhamento`. A referência tem um `Consultas.tsx` órfão, não roteado. Ao
reconstruir, decida: ou `consultas` ganha destino próprio, ou sai do contrato
por emenda. Ambiguidade em contrato de permissão é dívida de segurança.

## As ondas

Ordem de reconstrução na stack nova, definida no plano de lançamento. Como as
15 chaves já são contrato dentro do banco e o plano liga e desliga cada uma,
**a distribuição por onda é configuração, não programação** — dá para
controlar o que o cliente vê sem escrever código.

- **Onda 1 — o que o primeiro cliente usa.** Configurações (catálogos, equipe,
  regras), pacientes, atendimentos (funil), consultas (fechamento e geração de
  recebíveis), tarefas (automação por dias úteis), contas a receber, dashboard.
- **Onda 2 — 30 a 60 dias depois.** Contas a pagar (fecha o ciclo financeiro),
  fluxo de caixa (depende das duas pontas), anamnese (inclui o formulário
  público), relatório de vendas (o mais pedido).
- **Onda 3 — consolidação.** Demais relatórios, insights, equipe.

## Três ressalvas que seguem valendo

1. **Repasse não entra na Onda 1.** O imposto está fixado em zero e a
   atribuição do profissional é estimativa. Para público médico, é o relatório
   mais sensível que existe.
2. **Insights depende de provedor externo** que não acompanha a troca de
   estrutura. Precisa ser reescrito antes de valer na plataforma nova.
3. **A auditoria cobre só ação administrativa de nível SaaS.** O que o dono da
   clínica faz dentro da própria conta ainda não deixa rastro. Com dado de
   saúde, isso é dívida a pagar, não item de backlog.

## Resolução de acesso

Cascata, na ordem, igual no banco e no app:

1. superadmin → `full` sempre
2. impersonando → libera
3. assinatura `suspended`/`cancelled` → `none`
4. módulo ausente ou `false` no `enabled_modules` do plano → `none`
5. admin da clínica → `full`
6. permissão individual do `team_member`
7. fallback → `none`

**O plano é o teto; a permissão individual distribui abaixo do teto e nunca o
excede.**
