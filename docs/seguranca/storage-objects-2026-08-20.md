# Storage sem RLS — diagnóstico antes do conserto

**Data:** 20/08/2026 · **Origem:** scanner de segurança da Lovable, nível
**Critical** · **Estado: NÃO CONFIRMADO — precisa da consulta abaixo.**

## O que o scanner disse, literalmente

> *"No RLS policies exist on `storage.objects`, so despite the buckets being
> marked private, there is no policy layer enforcing ownership or clinic scoping
> on file uploads/downloads. Add storage.objects policies for
> SELECT/INSERT/UPDATE/DELETE that verify the requesting user's clinic/ownership
> before granting access to objects in these buckets."*

## Por que isso assusta neste projeto

O bucket `database_export…` guarda o **dump completo do banco** — paciente,
consulta e valor de todas as clínicas. Foi gerado em 18/08 pelo gate T004 da
SPEC 002. Se o Storage não tem camada de autorização, esse arquivo é o pior
alvo possível.

## Por que eu NÃO afirmo que está vazando

Há uma nuance que muda tudo, e eu quase a atropelei:

No Supabase, `storage.objects` **já vem com RLS habilitada**. Com RLS ligada e
**nenhuma policy**, o resultado é **negar tudo** para `anon` e `authenticated` —
que é seguro, não inseguro. "Nenhuma policy existe" pode significar duas coisas
opostas:

| Estado | Efeito real | Gravidade |
|---|---|---|
| RLS **ligada**, zero policies | ninguém lê nada pela API | **seguro** (default deny funcionando) |
| RLS **desligada**, zero policies | qualquer autenticado lê qualquer objeto | **crítico** |

O scanner não distingue os dois no texto do achado. **Sem olhar o banco, afirmar
vazamento é chute** — e chute em segurança gasta credibilidade à toa.

## A consulta que decide (30 segundos, SQL editor, não escreve nada)

`More → Cloud → SQL editor`:

```sql
-- 1. A RLS está ligada em storage.objects?
select relname, relrowsecurity as rls_ligada, relforcerowsecurity as rls_forcada
from pg_class
where oid = 'storage.objects'::regclass;

-- 2. Que policies existem?
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
order by policyname;

-- 3. Quem tem permissão de tabela (RLS não protege contra GRANT amplo)
select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'storage' and table_name = 'objects'
order by grantee, privilege_type;

-- 4. Que buckets existem e quais são públicos
select id, name, public, created_at from storage.buckets order by created_at;
```

**Como ler o resultado:**

- **(1) `rls_ligada = true` e (2) sem policies** → está negando tudo. O achado é
  de higiene, não de vazamento. Vira backlog com data.
- **(1) `rls_ligada = false`** → **é crítico de verdade.** Aplique o conserto
  abaixo hoje.
- **(4) algum bucket com `public = true`** → esse é lido **sem autenticação
  nenhuma**, com ou sem RLS. Se for o de export, é o pior cenário e precisa ser
  fechado imediatamente.

## O conserto, se a consulta confirmar

Só rode depois de olhar o resultado acima.

```sql
-- Garante a trava. Se ja estiver ligada, nao faz mal.
alter table storage.objects enable row level security;

-- O bucket de export do banco nao deve ser acessivel por NINGUEM pela API.
-- Ele e gerado e entregue pelo proprio Lovable Cloud; usuario logado nao tem
-- motivo para le-lo. Sem policy para ele, o default deny cuida do resto.

-- Se houver bucket de uso do app (logo da clinica, anexo de paciente etc.),
-- a policy tem de escopar por clinica, usando a mesma ancora do resto do banco:
-- create policy "clinica le os proprios arquivos"
--   on storage.objects for select to authenticated
--   using (
--     bucket_id = '<nome-do-bucket-do-app>'
--     and (storage.foldername(name))[1] = public.get_my_clinic_id()::text
--   );
-- (o padrao acima presume que o app salva em <clinic_id>/arquivo.ext —
--  confirme como o upload monta o caminho antes de aplicar)
```

**Não aplique a policy de escopo por clínica sem antes conferir como o caminho
do arquivo é montado no upload.** Uma policy que não bate com o formato real do
`name` bloqueia o app inteiro em vez de proteger.

## Atravessa para a stack nova?

**Sim, faixa A.** Storage com RLS por clínica é requisito da stack Next.js
também, e a policy escrita aqui vira migração versionada lá. Vale o trabalho
mesmo a plataforma sendo temporária.

## O que ficou sabido de passagem

O mesmo painel reporta **52 pacotes, 13 vulnerabilidades conhecidas** nas
dependências da plataforma. Não é o mesmo `npm audit` da stack nova (1 crítica,
5 altas). São dois inventários distintos; nenhum dos dois entra antes de 01/09.
