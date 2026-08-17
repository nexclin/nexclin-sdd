# Confirmação ao vivo — Fase 0 da SPEC 002 (16/08/2026)

> **Origem:** `specs/002-seguranca-anamnese-auditoria/spec.md` (Fase 0) e
> `quickstart.md`. **Achados sob confirmação:** Achado 1 e Achado 2 de
> `docs/seguranca/revisao-2026-08-16.md`.
> **Autor deste registro:** agente A4 (auditor-multitenant), preparando as
> queries e o guia de interpretação. **Execução real das queries: Arthur, no
> SQL do Lovable/Supabase (projeto `xbnffervqqphgsyeffdz`).**
> **Escopo desta tarefa: só leitura.** Nenhuma escrita foi feita no banco por
> este agente — ele não tem acesso ao banco ao vivo. Nada foi corrigido aqui;
> a correção (Fases 1-2 da spec) só acontece na janela de 22-23/08.

---

## Contexto

Achado 1 (`docs/seguranca/revisao-2026-08-16.md:42`) e Achado 2
(`docs/seguranca/revisao-2026-08-16.md:87`) foram levantados por auditoria
estática das migrações portadas (réplica), que pode ter divergido do banco ao
vivo do Lovable. Antes de tratar qualquer um como tarefa de correção, a Fase 0
da SPEC 002 exige confirmar os dois, ao vivo, com leitura pura.

## As duas queries (prontas para colar no SQL do Lovable)

### Query 1 — Achado 1 (superfície anônima em anamnese)

```sql
select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and 'anon' = any(roles)
order by tablename;
```

**Veredito de auditoria:** estritamente `SELECT` sobre a view de catálogo
`pg_policies` — não lê nem toca nenhuma linha de dado de negócio (nenhum PHI),
só metadado de policy. Sem risco algum, pode ser executada sem restrição.
Prova o que promete e é **mais forte** que o mínimo necessário: como não
filtra por `tablename like 'anamnesis%'`, ela também expõe **qualquer outra**
tabela que tenha ganhado policy `TO anon` desde a revisão de 16/08 — o que
cobre o item "superfície anônima" do escopo de auditoria deste time (achado
novo herdado seria pego aqui de graça). Recomendo **não restringir** o filtro,
por esse motivo.

**Ressalva de leitura (não é erro na query, é cuidado na interpretação):**
`pg_policies.qual` só é preenchido para o `USING` de `SELECT/UPDATE/DELETE`;
para o `WITH CHECK` de `INSERT`/`UPDATE` o valor relevante está em
`with_check`. A policy original "Anon can update pending response" tem
`qual = status <> 'preenchido'` (não é `true`) mas `with_check = true` — é
essa coluna que prova a adulteração. Um leitor que olhar só `qual = true`
pode subestimar o achado. O guia abaixo cobre os dois campos.

### Query 2 e 3 — Achado 2 (rastro em `patients`)

```sql
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'patients'
  and column_name = 'deleted_at';

select to_regclass('public.data_audit_log') as tem_audit_log;
```

**Veredito de auditoria:** estritamente `SELECT` sobre `information_schema`
(view de metadado, read-only por definição) e sobre `to_regclass`, função
pura de catálogo que resolve nome→OID sem ler nenhuma linha de tabela. Zero
risco, zero contato com dado de paciente.

**Correção proposta em relação ao original do quickstart:** a query do
`quickstart.md`/`spec.md` original não filtra `table_schema`:

```sql
-- original (spec.md / quickstart.md)
select column_name from information_schema.columns
where table_name = 'patients' and column_name = 'deleted_at';
```

Isso é um ponto cego pequeno mas real: se existir mais de um objeto chamado
`patients` em schemas diferentes (ex.: uma tabela de staging, uma extensão,
um schema de teste), a ausência de `table_schema = 'public'` pode gerar falso
positivo (pega a coluna de outro schema) ou apenas ambiguidade no resultado.
A versão acima, com `table_schema = 'public'`, é a que deve ser colada — ainda
estritamente leitura, só mais precisa. `to_regclass('public.data_audit_log')`
já é inequívoca (nome qualificado por schema).

---

## Guia de interpretação

### Query 1 (policies `anon`)

| Resultado | Leitura |
|---|---|
| Linhas para `anamnesis_responses` e/ou `anamnesis_config` com `cmd = SELECT` e `qual = true`, ou `cmd = UPDATE`/`INSERT` com `with_check = true` | **Achado 1 vivo.** O acesso anônimo irrestrito (leitura e/ou adulteração) continua no ar. |
| Nenhuma linha para `anamnesis_responses` nem `anamnesis_config` | **Achado 1 corrigido.** As três policies `anon` foram removidas (consistente com a Fase 1 da SPEC 002 já ter rodado, ou com correção equivalente). |
| Linhas para `anamnesis_*` existem, mas `qual`/`with_check` referenciam algo diferente de `true` (ex.: comparação com um `public_token`) | **Parcialmente corrigido / em transição.** Não é mais `USING(true)` — registrar o texto exato de `qual`/`with_check` e reavaliar manualmente antes de fechar como corrigido; não presumir. |
| A query retorna vazio | Ambíguo apenas se inesperado: como a query não filtra por tabela, vazio total significa que **nenhuma** tabela do schema `public` tem policy `TO anon` — leitura mais forte de "Achado 1 corrigido", e também indica que nenhuma outra superfície anônima nova apareceu. |
| Linhas para tabelas **fora** de `anamnesis_*` com `TO anon` | Fora do escopo formal do Achado 1, mas é achado novo em potencial (superfície anônima não revisada) — registrar à parte, não descartar. |

### Query 2 e 3 (`patients.deleted_at`, `data_audit_log`)

| Resultado | Leitura |
|---|---|
| Query 2 vazia **e** Query 3 retorna `null` | **Achado 2 vivo.** Nem soft delete nem tabela de auditoria existem. |
| Query 2 retorna a linha `deleted_at` **e** Query 3 retorna `data_audit_log` (não-nulo) | **Achado 2 corrigido**, quanto à existência dos objetos. Não confirma sozinho que o trigger grava `old→new` nem que a RLS da tabela de auditoria está correta — isso exige o teste funcional do quickstart (apagar um paciente de teste e inspecionar a linha), fora do escopo de leitura desta Fase 0. |
| Só uma das duas existe (ex.: `deleted_at` presente, `data_audit_log` ausente, ou vice-versa) | **Parcialmente corrigido.** Registrar exatamente qual metade falta — não arredondar para "corrigido" nem para "vivo". |

---

## Registro do resultado — EXECUTADO

- **Data/hora da execução:** 16/08/2026, ~22h40 (BRT)
- **Onde:** SQL editor do Lovable Cloud (More → Cloud → SQL editor), banco ao
  vivo do projeto `09bc3d2d-df13-4ce3-a41f-6aa1606a75df`.
- **Executado por:** sessão do Claude Code no navegador do Arthur, com ele
  logado e tendo autorizado a execução. **Somente leitura** — as duas queries
  são SELECT sobre catálogo; nenhuma escrita, nenhuma correção aplicada.

### Achado 1 — **CORRIGIDO**

Query 1 retornou **`Query succeeded. No rows returned.`**

Zero policies concedidas ao papel `anon` em **todo** o schema `public` — não
só em `anamnesis_*`. Pela tabela de interpretação acima, este é o caso de
leitura mais forte de "corrigido": além de as três policies originais terem
sumido, **nenhuma superfície anônima nova apareceu** em nenhuma outra tabela.

**Não há drift.** O resultado bate com as migrações versionadas: a migração
`20260723211722` derruba as três policies (`Anon can read anamnesis config`,
`Anon can read response by id`, `Anon can update pending response`) e a
anamnese pública passou a ser servida por edge function com service role. O
banco ao vivo reflete exatamente isso.

> Contexto adicional observado no mesmo dia: o agente de segurança da própria
> Lovable rodou uma varredura em 16/08 (commits `cdbb038` e `3b8fc94 "Fixed
> security findings"`, 20:11 e 20:12 UTC) e relatou "Fixed: 1 issue /
> Remaining: 0 issues". Isso é relato da ferramenta, não prova — a prova é a
> query acima.

### Achado 2 — **VIVO**

Query 2/3 retornou:

| pat_deleted_at | audit_log | tabelas |
|---|---|---|
| `0` | `NULL` | `45` |

`patients` não tem coluna `deleted_at` e a tabela `data_audit_log` não existe.
Ação sobre paciente segue **sem rastro**: sem soft delete, sem atribuição de
autor e momento, sem estado anterior para reconstruir. Achado ALTO/LGPD
confirmado no ar, a duas semanas de receber clientes pagantes.

### Estado da stack nova (alvo secundário), para comparação

Rodado no SQL Editor do Supabase próprio (`bfkghwkhzkimzyiovotj`), mesma data:

| planos | saas_settings | operadores | usuarios_auth | policies_anon | pat_deleted_at | data_audit_log | tabelas |
|---|---|---|---|---|---|---|---|
| 1 | 1 | 0 | 0 | **0** | **0** | **NULL** | 44 |

Leitura: a stack nova **já nasce limpa do Achado 1** (zero policies `anon`),
mas **herda o Achado 2** — a correção da Fase 2 precisa ser aplicada nos dois
lados, não só no Lovable.

### Canal de correção

**Verificação B: passa.** O projeto aparece no painel do provedor que de fato
hospeda o banco — o **Lovable Cloud** (More → Cloud), não o dashboard pessoal
do supabase.com, onde só existe o projeto da stack nova. O painel tem
Database (45 tabelas), Users, Edge functions (4), SQL editor, Logs, e
**"Export project data" habilitado** (confirmado sem clicar). Correção de
banco e backup prévio, portanto, **não dependem de crédito**.

**Verificação A: pendente.** Exige o push de teste ao repositório
`nexclin/nexclin`. Enquanto não for feita, o canal de correção de **código**
segue indefinido. Dado relevante levantado na mesma sessão: o workspace
("Erick's Lovable") está no **plano Free, com 5 créditos restantes** e reset
diário — se a Verificação A falhar, a fase de correção de bugs esbarra nesse
teto quase imediatamente.

### Conclusão da Fase 0

A SPEC 002 **não** se encerra na Fase 0. O Achado 1 está fechado e a **Fase 1
sai do escopo**; a **Fase 2 (rastro em `patients`) segue necessária** e entra
na janela de 22–23/08, agora com backup prévio viável pelo Export do Cloud.

## Nota de método

Nenhuma escrita foi feita no banco ao vivo nem localmente por este agente.
As duas queries acima leem apenas metadado de catálogo (`pg_policies`,
`information_schema.columns`, `to_regclass`) — nunca uma linha de dado de
paciente. A correção proposta na Query 2/3 (acrescentar `table_schema =
'public'`) também é estritamente leitura; não é uma escrita disfarçada.
