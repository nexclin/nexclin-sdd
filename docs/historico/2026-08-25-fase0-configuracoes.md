# Fase 0 — o que se presumia, e o que o banco de fato diz

**Data:** 25/08/2026 · **Método:** varredura nas 55 migrações, não consulta ao
banco ao vivo.

O plano manda provar antes de escrever tela. A constituição v2.0.0, no Princípio
IX, diz que build verde não é prova; o mesmo vale para "a fundação portou tudo".

---

## 1. RLS nas catorze tabelas: confirmado

Todas as catorze têm `ENABLE ROW LEVEL SECURITY` e pelo menos uma policy.

| Tabela | RLS | Policy |
|---|---|---|
| `business_rules`, `channels`, `origins`, `objections`, `services`, `payment_methods`, `expense_categories`, `chart_of_accounts`, `bank_accounts`, `closing_types`, `consultation_types`, `goals`, `acquirers`, `anamnesis_config` | sim, todas | sim, todas |

**Um falso positivo, e ele vale registro.** A primeira varredura acusou
`consultation_types` com RLS ligada e **zero** policies, o que significaria
tabela inacessível para todo mundo. Era erro do `grep`: naquela migração o
`CREATE POLICY` tem espaço no fim da linha e o `FOR ALL` cai na linha seguinte,
então o padrão não casou.

A policy existe e está correta. **Conferi antes de reportar**, e é por isso que
esta seção diz "confirmado" em vez de abrir uma tarefa que não existia.

## 2. Duas implementações de "qual clínica é a minha"

Este é o achado real da fase 0, e ele é do tipo que o Princípio VIII nomeia.

As policies dos catálogos usam **duas formas diferentes** para a mesma pergunta:

```sql
-- forma A, nas tabelas mais antigas (channels, origins, services, objections…)
USING (clinic_id IN (SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid()))

-- forma B, nas mais novas (consultation_types…)
USING (clinic_id = public.get_my_clinic_id())
```

As duas **devem** ser equivalentes. "Devem" é a palavra que incomoda.

Diferenças que existem de fato entre elas:

- **A forma A é subconsulta correlacionada**, reavaliada por linha; a forma B é
  função `STABLE`, avaliada uma vez. É diferença de custo, não de resultado.
- **A forma A não sobrevive a `clinic_id` nulo do mesmo jeito.** `profiles.clinic_id`
  é anulável (`REFERENCES clinics(id) ON DELETE SET NULL`). Um perfil sem clínica
  faz a forma A comparar contra `IN (NULL)`, que é sempre falso — nega, e nega
  é o lado seguro. A forma B depende do que `get_my_clinic_id()` devolve nesse
  caso, e isso é comportamento de função, não de policy.
- **A forma B respeita a impersonação se a função respeitar**, e a forma A não
  necessariamente. É a diferença que mais importa e a que ninguém verificou.

**Consequência para esta spec:** nenhuma tela muda por causa disso, e nenhuma
policy é reescrita aqui. Fica registrado como dívida, com nome, porque:

1. A migração da SPEC 002 que reescreve as policies de `patients` **troca a
   forma A pela forma B**, e o documento de aplicação guiada já traz reversão
   justamente porque essa equivalência não está provada em produção.
2. Uniformizar as 42 policies é trabalho da SPEC 016 (FR-006), que já prevê
   varrer todas e decidir uma a uma.

## 3. As formas dos catálogos: nove iguais, quatro diferentes

Colunas conferidas nas migrações.

**Os nove que cabem no componente genérico:**

| Tabela | Além de `id, clinic_id, active, created_at, updated_at` |
|---|---|
| `channels` | `name` |
| `origins` | `name` |
| `objections` | `name` |
| `closing_types` | `name`, `is_system` |
| `consultation_types` | `name`, `description`, `price` |
| `services` | `name`, `category`, `macro_category`, `price`, `cost`, `duration_minutes` |
| `payment_methods` | `name`, `brand`, `default_fee_percent`, `anticipation_fee_percent`, `payment_term_days` |
| `expense_categories` | `name`, `subcategory`, `cost_center` |
| `acquirers` | `name`, `bank_account_id`, `credit_fee_percent`, `debit_fee_percent`, `anticipation_fee_percent` |

**Os quatro que não cabem, e por quê:**

- **`business_rules`** — não é lista. Uma linha por clínica, com onze campos
  heterogêneos: `followup_days`, `confirmation_hours`, `recapture_days`,
  `recall_days`, `satisfaction_survey_days`, `anamnesis_send_days`,
  `work_saturday`, `patient_required_fields` (jsonb), `appointment_required_fields`
  (jsonb).
- **`chart_of_accounts`** — hierárquico: `code`, `name`, `parent_id`, `level`,
  `is_system`. É árvore.
- **`bank_accounts`** — `bank_name`, `bank_code`, `agency`, `account`,
  `account_type`. Cabe no genérico em forma, mas os campos não são "nome e
  ativo", e errar dígito de conta tem consequência.
- **`goals`** — chave composta por `month` e `year`, com quatro alvos. É upsert
  por período, não lista.
- **`anamnesis_config`** — tem `fields` jsonb, que é um construtor de
  formulário. A mais cara das quatro.

**Correção ao plano:** o plano dizia "9 no genérico, 4 próprias". São **9 no
genérico e 5 próprias**, contando `bank_accounts`. O plano será corrigido.

## 4. Os campos de `business_rules` que vieram por migração posterior

Confirmado que os cinco campos que a fila cita **existem**, e vieram depois da
criação da tabela:

- `patient_required_fields jsonb DEFAULT '["name"]'`
- `appointment_required_fields jsonb DEFAULT '["patient_id","date"]'`
- `satisfaction_survey_days integer NOT NULL DEFAULT 1`
- `anamnesis_send_days integer NOT NULL DEFAULT 1`
- `work_saturday boolean NOT NULL DEFAULT false`

**Os dois `jsonb` são arrays de nome de campo**, e os defaults mostram o
contrato: `["name"]` e `["patient_id","date"]`. A tela de configuração escolhe
quais campos entram nesses arrays, e os módulos 007 e 008 os obedecem.

## 5. O defeito que a fase 1 corrige

Já documentado na spec e na migração `20260825070000`: o default de
`plans.enabled_modules` é `'[]'::jsonb` (array) e o trigger
`validate_enabled_modules` exige objeto. Todo `INSERT` em `plans` sem informar a
coluna falha.

Nada a pesquisar aqui; a evidência está nas duas migrações.

## 6. O que continua sem prova, e não vai ter prova nesta fase

- **Se as formas A e B de policy são equivalentes em produção.** Só consulta ao
  banco ao vivo resolve, e ela é da SPEC 016.
- **Se as catorze tabelas têm dado hoje.** A varredura lê migração, não linha.
  Uma clínica com catálogo vazio é o estado normal antes do onboarding.
- **Se `get_my_clinic_id()` respeita impersonação.** É leitura de função que vale
  fazer antes da SPEC 007, não antes desta.

Registrado literalmente, como manda o Princípio IV: **código lido, não
comportamento provado.**
