# Implementation Plan: Configurações da clínica

**Branch**: `spec/005-configuracoes` | **Date**: 2026-08-25 | **Spec**: [spec.md](./spec.md)

**Input**: `specs/005-configuracoes-clinica/spec.md`

---

## Summary

Ligar o app Next.js às catorze tabelas de catálogo e regra de negócio que já
existem na fundação, e corrigir o default quebrado de `plans.enabled_modules`.

Nenhuma tabela nova. O trabalho é de **camada de aplicação sobre schema
existente**, mais uma migração de correção.

## Technical Context

**Linguagem**: TypeScript estrito, Next.js 15 App Router, React 18
**Dependências**: `@supabase/ssr`, `@supabase/supabase-js`, Tailwind
**Armazenamento**: Postgres da Supabase, catorze tabelas já migradas
**Testes**: Vitest para regra pura, Playwright para guard de rota
**Plataforma**: Vercel, renderização dinâmica (as telas leem cookie de sessão)
**Tipo**: aplicação web multi-tenant
**Escala**: uma clínica tem dezenas a centenas de linhas por catálogo. Não há
problema de volume aqui; há problema de **quantidade de formulários**.

**Restrição que molda o plano**: são **13 catálogos + 1 tabela de regras**.
Escrever catorze telas à mão é onde a divergência visual nasce, e o
`INVENTARIO-UI.md` já registra três vocabulários de período convivendo na
referência por exatamente esse motivo.

## Constitution Check

Verificado contra a v2.0.0.

| Princípio | Como este plano atende |
|---|---|
| **I. Segurança mora no banco** | Nenhuma tela decide acesso. Todas as catorze tabelas já têm RLS por `clinic_id`; a fase 1 **verifica** isso antes de escrever tela, em vez de presumir. |
| **II. Privacidade e auditoria** | A edição de catálogo passa a gerar trilha pelo mecanismo da SPEC 002. Como ele ainda não está aplicado, a fase 4 fica **dependente** e não é declarada pronta sem ele. |
| **III. Contrato único de módulos** | Tudo sob a chave `configuracoes`. A tela de planos, sob guard de superadmin. Nenhuma chave nova. |
| **IV. SDD com parada humana** | Quatro fases, cada uma com critério de aceite. Onde o executor não puder provar comportamento na tela, registra literalmente *"código lido, não comportamento provado"*. |
| **V. Segredos e qualidade** | Nada de credencial. `tsc --noEmit` e Vitest são gate de cada fase. |
| **VI. Valor operacional** | Configuração não gera receita sozinha: ela **destrava** os módulos que geram. É substrato, e o plano não finge o contrário. |
| **VII. O dado atravessa; a tela não** | A correção do `enabled_modules` é **faixa A** e vem primeiro, sozinha, porque é a única coisa aqui que migra intacta. As catorze telas são stack nova e não existem na Lovable. |
| **VIII. Uma regra, uma fonte** | É o princípio que decide o desenho: **um** componente de catálogo genérico, **um** de período, **uma** conversão de horas para dias. Catorze cópias do mesmo formulário é a falha que este princípio nomeia. |
| **IX. Verificação vale mais que build verde** | Cada fase fecha com `tsc`, Vitest e, onde houver tela, captura. A ida e volta de `confirmation_hours` é simulada com número antes de ser declarada certa. |

**Nenhuma violação. Nenhuma justificativa de complexidade necessária.**

## Project Structure

### Documentação

```text
specs/005-configuracoes-clinica/
├── spec.md          ✅ escrita
├── plan.md          ✅ este arquivo
├── data-model.md    fase 1
├── contracts/       fase 1
├── quickstart.md    fase 1
└── tasks.md         /speckit-tasks
```

### Código

```text
supabase/migrations/
└── 20260825070000_corrige_default_de_enabled_modules.sql   ✅ escrita

lib/config/
├── catalogo.ts        # a definição declarativa dos 13 catálogos
├── regras.ts          # conversões puras (horas↔dias), testável
└── __tests__/

app/app/configuracoes/
├── page.tsx           # índice das seções
├── catalogo-tabela.tsx    # UM componente, parametrizado
├── regras-form.tsx
└── [catalogo]/page.tsx    # rota genérica por catálogo
```

## A decisão de desenho que governa tudo: um componente, treze catálogos

Onze dos treze catálogos têm a mesma forma: `id`, `clinic_id`, `name`, `active`,
`created_at`, `updated_at`. Alguns acrescentam colunas de valor (`price`,
`cost`, `default_fee_percent`, `payment_term_days`).

**Escrever treze telas seria treze lugares para a mesma regra divergir.** O
Princípio VIII nomeia isso, e o INVENTARIO-UI documenta o resultado quando
acontece.

Então: **um** componente de tabela, alimentado por uma **definição declarativa**
por catálogo (nome da tabela, rótulo, colunas, quais são obrigatórias, qual o
tipo). Acrescentar catálogo passa a ser acrescentar uma entrada na definição, e
não uma tela.

O que **não** entra no genérico, e por quê:

- **`business_rules`**: não é lista, é uma linha por clínica com campos
  heterogêneos. Tela própria.
- **`chart_of_accounts`**: é hierárquico (`parent_id`, `level`). Árvore, não
  tabela. Tela própria.
- **`goals`**: é por mês e ano, com upsert. Tela própria.
- **`anamnesis_config`**: tem `fields` jsonb, que é um construtor de formulário.
  Tela própria, e a mais cara das quatro.

Ou seja: **9 catálogos no genérico, 4 telas próprias, 1 tela de regras.**

## Fases

### Fase 0 — Verificar o que se presume

Antes de escrever tela, provar que as catorze tabelas estão como o plano supõe.
A fundação diz que estão; a constituição diz que build verde não é prova.

Sai: `research.md` com o resultado real da varredura de RLS, colunas e
`is_system` nas catorze tabelas.

**Aceite:** o relatório existe e nenhuma tabela diverge do esperado. Divergência
encontrada vira tarefa antes de qualquer tela.

### Fase 1 — A correção de faixa A, sozinha

A migração do `enabled_modules`, aplicada e conferida, **antes** de qualquer
tela. É a única parte que atravessa e a única que corrige um defeito.

**Aceite:** criar um plano sem informar `enabled_modules` funciona. Hoje falha.

### Fase 2 — O núcleo puro e testado

`lib/config/regras.ts` e `lib/config/catalogo.ts`, com testes. Conversão de
horas para dias, validação de campo obrigatório, definição dos 9 catálogos.

**Sem tela nenhuma nesta fase.** É o que permite testar a regra sem navegador.

**Aceite:** Vitest cobrindo a ida e volta de `confirmation_hours` para os
valores de 1 a 30 dias, e provado por mutação.

### Fase 3 — As telas

O componente genérico, os 9 catálogos, as 4 telas próprias e a de regras.

**Aceite:** o roteiro de `quickstart.md`, executado por Arthur.

### Fase 4 — Auditoria

Ligar a edição de catálogo à trilha da SPEC 002.

**Bloqueada** até a Fase 2 da SPEC 002 estar aplicada. Declarada assim desde
já, em vez de descobrir no meio.

## Complexity Tracking

Nenhum desvio da constituição a justificar.

O único ponto que mereceria discussão é a rota genérica `[catalogo]`, que troca
treze rotas explícitas por uma paramétrica. A troca é favorável porque o
parâmetro é validado contra a definição declarativa: catálogo fora da lista é
404, e não uma consulta a uma tabela arbitrária escolhida pela URL. **Isso é
requisito, não detalhe** — sem essa validação, a rota vira leitura de tabela
por nome vindo do cliente.
