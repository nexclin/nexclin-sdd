---
paths:
  - "supabase/**"
  - "scripts/**"
---

# Banco — regras que valem em toda migração, função e seed

A constituição (`.specify/memory/constitution.md`) é a lei; isto é o que ela
significa na prática, dentro de `supabase/`.

## Antes de escrever a migração

- Migração é a **única** via de mudança de schema. Alteração feita à mão no
  painel do Supabase não existe para este repositório e será sobrescrita.
- Nome do arquivo segue o padrão já em uso: `<timestamp>_<slug>.sql`. Não
  renumere migrações aplicadas — a base de produção já as tem.
- `ALTER TYPE ... ADD VALUE` **não roda dentro de transação**. Isole numa
  migração própria.

## Toda tabela nova com `clinic_id`

Três linhas obrigatórias, nesta ordem — ausência de qualquer uma é bug de
segurança, não descuido de estilo:

```sql
alter table <tabela> enable row level security;
create policy "<nome>_select" on <tabela> for select
  using (clinic_id = get_my_clinic_id());
-- idem para insert/update/delete, com with check no que grava
```

Globais que legitimamente não têm `clinic_id`: `clinics`, `plans`, `coupons`,
`saas_settings`, `superadmin_operators`, `user_roles`. Qualquer outra tabela
sem âncora precisa de justificativa escrita no commit.

## Nunca

- `USING (true)` numa tabela de negócio. Se for exceção consciente, escreva
  `-- guarda:permitido <motivo>` na linha acima — o motivo fica no blame.
- Conceder ao papel `anon` leitura de tabela com dado de paciente. Já existe
  um caso assim herdado do MVP (`anamnesis_responses`, migração
  `20260324032228`) e ele está registrado como dívida, não como padrão.
- Qualquer caminho que **defina** senha. Só `resetPasswordForEmail`.
- Segredo no arquivo. Seeds leem de `.env.local`.

## Seeds

Idempotentes por contrato: rodar duas vezes não pode duplicar nada. Use
`on conflict do nothing` ou checagem prévia explícita. O critério de aceite da
SPEC 001 exige a execução dupla.

## Ao portar da referência

`../nexclin-lovable` é somente leitura e está fora do alcance de escrita
(bloqueado em `.claude/settings.json`). Extraia a regra, reescreva com nome e
ordem deste repositório, e registre no commit de qual migração original veio.
