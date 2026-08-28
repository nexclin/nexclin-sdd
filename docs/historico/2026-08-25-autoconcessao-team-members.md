# Autoconcessão de permissão em `team_members` — 25/08/2026

> Achado por leitura de migração, ao usar a régua NGS1 da certificação SBIS
> como espelho (ver `2026-08-25-openclinic-analise.md` §3.1,
> requisito `NGS1.03.11` — "ninguém altera as permissões do próprio usuário").
> **Não foi explorado em ambiente ao vivo.** É leitura de código, e precisa de
> confirmação prática antes de virar correção.

---

## O que a migração diz

`supabase/migrations/20260324015403_...sql`, linhas 38–45 — **única** policy
que existe sobre a tabela:

```sql
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage team_members in their clinic"
ON public.team_members
FOR ALL
TO authenticated
USING (clinic_id = public.get_my_clinic_id())
WITH CHECK (clinic_id = public.get_my_clinic_id());
```

E `supabase/migrations/20260802073330_...sql`, linha 39:

```sql
GRANT INSERT, UPDATE, DELETE ON public.team_members TO authenticated;
```

Nenhuma migração posterior restringe UPDATE a admin. Conferido por varredura
das 55 migrações: existe exatamente uma policy nessa tabela.

## A consequência

`FOR ALL` cobre UPDATE. A condição é **só** o `clinic_id`. Portanto qualquer
usuário autenticado da clínica pode dar UPDATE em **qualquer linha de
`team_members` da própria clínica** — inclusive a dele.

As colunas que isso alcança:

- `permission_level` (`master` / `gerencial` / `operacional` / `configuravel`)
- `permissions` (o jsonb por módulo que a `my_permission` lê)
- `repasse_percent`, `modelo_repasse`, `calcula_sobre`, `valor_fixo_sublocacao`

Ou seja, na leitura do código: **uma secretaria pode se promover a `master`, e
um profissional pode aumentar o próprio percentual de repasse.**

## O que este achado NÃO é

Importa dizer, para não virar alarme falso:

- **Não é vazamento entre clínicas.** O `clinic_id` é checado no `USING` e no
  `WITH CHECK`, e a âncora é protegida pelo trigger `prevent_clinic_id_change`.
  O isolamento multi-tenant (Princípio I) continua de pé.
- **Não fura o teto do plano.** A cascata da `my_permission` avalia
  `enabled_modules` do plano **antes** da permissão individual. Módulo fora do
  plano continua `none`, por mais `master` que a linha diga.
- **Não alcança o papel global.** As escritas em `user_roles` são
  superadmin-only desde `20260802073330`. Ninguém se torna `admin` global assim.

O que ele fura é a camada do meio — **a permissão individual dentro da
clínica** — e a regra de negócio do repasse, que é dinheiro.

## Por que isso vale correção mesmo sendo "interno"

O modelo declarado do projeto é *"o plano é o teto; a permissão individual
distribui abaixo do teto"*. Se qualquer membro distribui para si mesmo, a
segunda metade da frase não existe: o teto do plano vira o **piso** de todo
mundo. Para uma clínica com secretária, estagiário e médico dividindo acesso a
financeiro, isso é exatamente o que o dono comprou e não está recebendo.

## Direção de correção (não aplicada)

Separar a policy única em quatro, com o `WITH CHECK` de UPDATE exigindo
`is_admin` **ou** a linha ser de outra pessoa que não `auth.uid()` — e barrar
por trigger a alteração de `permission_level`, `permissions` e das colunas de
repasse quando `user_id = auth.uid()`. Trigger, e não só policy, porque a
regra é "não pode mudar **estas colunas** em si mesmo", que policy expressa
mal.

## Classificação pela §2.5 do `CLAUDE.md`

**Faixa A — atravessa como banco.** É migração e RLS; vai intacta para a stack
nova. Mas **não é urgência de 08/09**: exige um usuário mal-intencionado
*dentro* da clínica fundadora, que hoje é uma clínica conhecida, com equipe
conhecida, em uso gratuito.

**Encaminhamento:** entra como tarefa da SPEC 002 ou da spec de `equipe`
(005 da fila), **não** como correção de véspera na Lovable. Mexer em policy de
permissão na semana do lançamento é trocar um risco teórico por um risco real.
