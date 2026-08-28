---
paths:
  - "supabase/**"
  - "scripts/**"
---

# Banco — regras que valem em toda migração, função e seed

A constituição (`docs/constituicao.md`) é a lei; isto é o que ela
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

**Corrigido em 25/08/2026.** O texto anterior dizia que `../nexclin-lovable` é
somente leitura. **Não é mais**, e não é desde 17/08: a constituição v2.0.0
(Princípio IV) substituiu a cláusula de somente leitura pelo procedimento da
ponte inversa, e é por aquele diretório que a correção chega ao cliente. Esta
regra tinha ficado para trás da lei.

O que vale agora:

- **Extrair a regra e reescrever aqui.** Nome e ordem deste repositório,
  registrando no commit de qual migração original veio. Isso não mudou.
- **Editar lá é permitido, sob procedimento**, e só sob ele: bug apenas,
  conserto mínimo, `git pull` antes, `main` sempre, nunca `--force`, e
  **function antes do Publish do front**. Fonte: `docs/ponte/ponte-inversa.md`.
- **A escrita continua bloqueada em `.claude/settings.json`.** O bloqueio é
  deliberado e permanece: ele obriga a passar pelo `scripts/ponte.sh`, que tem o
  gate de tipos, em vez de editar arquivo solto. Bloqueio de ferramenta não é o
  mesmo que proibição de política.

**A ordem que a constituição fixa, e que inverte o hábito antigo:** a migração
nasce **aqui**, em `supabase/migrations`, que é a fonte de verdade do schema, e
só depois vai para a plataforma. O caminho inverso obriga a transcrever, e é na
transcrição que o erro entra.
