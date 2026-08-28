# `storage.objects`: o achado do scanner é falso. Fechado em 27/08/2026

> Fecha a pendência aberta em `storage-objects-2026-08-20.md`, que estava
> parada há sete dias esperando a consulta. Executada em 27/08 no editor de SQL
> da plataforma, com o Arthur presente, sem escrever nada no banco.

## O que o scanner da Lovable afirmou, em nível Critical

> *"No RLS policies exist on `storage.objects`, so despite the buckets being
> marked private, there is no policy layer enforcing ownership or clinic
> scoping."*

## O que o banco respondeu

### 1. A RLS está ligada

```
relname   | rls_ligada | rls_forcada
objects   | true       | false
```

Este era o ponto que decidia entre higiene e vazamento. O documento de 20/08 já
antecipava a ambiguidade: no Supabase, `storage.objects` nasce com RLS
habilitada, e "nenhuma política existe" pode significar **negar tudo**, que é
seguro, ou **RLS desligada**, que é crítico. É `true`, então nem sequer se
chegou ao caso ruim.

### 2. Existem quatro políticas, e não zero

A afirmação central do scanner está errada. `pg_policies` devolve **4**, uma
para cada verbo, e todas com a mesma condição:

| Política | Comando | Papel | Condição |
|---|---|---|---|
| Superadmins can view export objects | SELECT | authenticated | `bucket_id LIKE 'database_export%' AND is_superadmin(auth.uid())` |
| Superadmins can upload export objects | INSERT | authenticated | idem, em `WITH CHECK` |
| Superadmins can update export objects | UPDATE | authenticated | idem |
| Superadmins can delete export objects | DELETE | authenticated | idem |

### 3. Os três buckets são privados

```
database_export_19_08_26   public = false
database_export_20_08_26   public = false
database_export_25_08_26   public = false
```

## A conclusão, e por que ela é mais forte do que "está tudo bem"

O dump completo do banco, com paciente, consulta e valor de todas as clínicas, é
legível **apenas** por quem passa em `is_superadmin(auth.uid())`. Não é
"ninguém configurou nada e por sorte nega": é uma regra escrita, com o mesmo
padrão de função `SECURITY DEFINER` que o resto do projeto usa.

**E ela falha para o lado seguro.** As quatro políticas só concedem quando o
nome do bucket casa com `database_export%`. Um bucket futuro com outro nome não
casa com nenhuma delas, e com a RLS ligada o resultado é negar tudo. Ou seja,
esquecer de escrever política para um bucket novo bloqueia o bucket, em vez de
o expor. É o default deny da regra (b) funcionando na camada de arquivo.

## O que fica de lição, e não é sobre storage

**O scanner errou a afirmação, não só a gravidade.** Ele disse que zero
políticas existiam, e existem quatro, escritas e corretas. Sete dias de uma
pendência classificada como Critical vieram de uma frase que ninguém tinha
conferido contra o banco.

A decisão de 20/08 de não afirmar vazamento antes de olhar se provou certa, e
vale manter: **achado de scanner é hipótese, não fato.** A consulta custou dois
minutos; a suposição custou uma semana de um item Critical aberto na lista.

## Estado

**Fechado.** Sai da lista de pendências do nível 0. Não gera correção, não gera
migração, e não bloqueia mais a SPEC 013, que tinha esta dívida como um dos três
bloqueios.
