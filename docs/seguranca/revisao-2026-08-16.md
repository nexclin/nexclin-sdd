# Revisão de segurança — plataforma Lovable (pré-lançamento 01/09)

> Revisão em 16/08/2026 sobre a plataforma que recebe os primeiros pagantes.
> Combina: auditoria estática das 57 migrações portadas, histórico de
> correções do scanner do Lovable, e os 4 testes de invasão que o Arthur rodou
> em 02/08. **Nada foi escrito no banco de produção nesta revisão.**

## Veredito em uma linha

A **fundação está sólida** e o scanner do Lovable fechou falhas reais. Mas ele
tem um ponto cego no que é específico deste produto: **duas exposições de dado
de saúde continuam de pé** e nenhuma delas aparece na lista "corrigidas". Uma é
trava de lançamento.

## O que o scanner do Lovable corrigiu (confirmado)

Do histórico do projeto Lovable, dois lotes:

**02/08 — 5 falhas:**
- Execução de funções `SECURITY DEFINER` restrita (sem anon, sem função interna
  para logado comum).
- Sessões de impersonação escopadas ao próprio superadmin.
- Dados sensíveis da equipe (e-mail, telefone, registro, repasse) só para admin
  via RPC dedicada.
- Escrita em `user_roles` limitada a superadmins.

**16/08 — 1 falha:**
- Acesso direto de logado comum a funções privilegiadas revogado;
  `is_superadmin` só responde sobre o próprio usuário. 1 marcada "não aplicável".

A auditoria estática confirma a base: **44 tabelas, todas com RLS; nenhuma com
`clinic_id` sem RLS; nenhum `SECURITY DEFINER` sem `search_path`; nenhum
caminho que defina senha.** Isso é um bom banco.

## O que o scanner NÃO viu — e importa mais

O próprio agente do Lovable avisa: *"encontra as falhas mais comuns, mas não
tem ferramentas para teste de invasão avançado."* Os dois achados abaixo são
exatamente o que escapa de um scanner genérico, porque dependem de entender
**este** produto.

### 1 · [TRAVA] Anamnese de qualquer paciente legível (e adulterável) por anônimo

**Migração `20260324032228`**, ainda presente:

```sql
CREATE POLICY "Anon can read response by id" ON anamnesis_responses
  FOR SELECT TO anon USING (true);
CREATE POLICY "Anon can update pending response" ON anamnesis_responses
  FOR UPDATE TO anon USING (status != 'preenchido') WITH CHECK (true);
CREATE POLICY "Anon can read anamnesis config" ON anamnesis_config
  FOR SELECT TO anon USING (true);
```

`anamnesis_responses` guarda `responses jsonb` — as respostas clínicas do
paciente, vinculadas a `patient_id` e `clinic_id`. A intenção é legítima: o
formulário público (`/anamnese-publica/:id`) precisa ser preenchido sem login.
O **erro** é o escopo: `USING (true)`, não um token.

**Cenário de exploração** (só com a chave anon, que é pública por design e vive
no bundle de todo navegador):

- `GET /rest/v1/anamnesis_responses?select=*` — sem filtro, o `USING(true)`
  devolve **todas as respostas de anamnese de todas as clínicas**. Não é "ler
  por id que eu já tenho": é enumerar a base inteira de dado de saúde.
- `PATCH` numa resposta com `status != 'preenchido'` — o `WITH CHECK (true)`
  permite **sobrescrever o conteúdo** de qualquer anamnese pendente de qualquer
  clínica. Adulteração, não só leitura.

Por que o scanner não pegou: ele provavelmente leu "anon SELECT by id" como
recurso intencional do formulário público e marcou como não aplicável. Um
scanner de padrões não distingue "anon lê a linha certa por token" de "anon lê
qualquer linha". Um pentest sim.

**Correção (não trivial — merae remoção quebra o formulário público):**
1. Adicionar `public_token uuid unique default gen_random_uuid()` a
   `anamnesis_responses`, indexado. O link vira `/anamnese-publica/:token`, não
   `:id`.
2. Trocar o acesso anônimo direto por uma **Edge Function** com service role
   que valida o token e devolve/grava só aquela linha. Remover as três policies
   `anon` da tabela e da config.
3. Expirar o token no `status = 'preenchido'`.

Isto é uma spec pequena, não um remendo. Enquanto não entrar, o formulário
público de anamnese **não deveria estar habilitado para cliente real**.

### 2 · [ALTO / LGPD] Ação sobre paciente não deixa rastro

Achado do **TESTE 4** do Arthur (02/08), confirmado pelo próprio agente: um
`DELETE` em `patients` não tem como ser atribuído — não há `data_audit_log`, não
há trigger de auditoria em `patients`, não há soft delete, e o log do Postgres
não grava DML bem-sucedido. `superadmin_audit_log` cobre só ação de superadmin.

A constituição, Princípio II, exige auditoria de **toda** ação administrativa
sobre dado de cliente, com `old→new`. Hoje a clínica dona apaga um paciente e
não sobra rastro de quem, quando, nem o quê. Com dado de saúde, isto é lacuna
de LGPD real — e o plano de lançamento já a nomeia como *"dívida a pagar, não
item de backlog"*.

**Correção:** `data_audit_log` + trigger `AFTER INSERT/UPDATE/DELETE` nas
tabelas sensíveis (patients primeiro), gravando `auth.uid()`, timestamp,
`clinic_id` e estado anterior completo (que também permite reconstruir a linha).
Somar `deleted_at` (soft delete) para exclusão nunca ser destrutiva. Os chips
"Implementar auditoria de pacientes" e "Ativar soft delete" já estão sugeridos
no Lovable — é decisão de puxar, não de descobrir.

## Sobre os TESTES 1–3 do Arthur (02/08)

- **TESTE 1 (pedir service_role/connection string):** o Lovable recusou
  corretamente — a chave não é acessível nem pelo painel. **Passou.**
- **TESTE 2/3 (UPDATE/DELETE direto, restaurar no tempo):** confirmaram que o
  tier atual **não tem point-in-time recovery**. Um DELETE amplo é
  irreversível. Isto não é falha de código: é o motivo pelo qual o
  `CLAUDE.md` manda assinar o **Supabase Pro no dia do primeiro cliente**
  (backup diário; o tier grátis pausa em 7 dias e não tem backup). Reforço:
  fazê-lo **antes** de 01/09, não no dia.

## Ressalva importante: repo × ao vivo

As migrações auditadas estão neste repositório (`nexclin-sdd`), que é uma
**réplica portada** do Lovable num momento passado. O banco ao vivo do Lovable
(`xbnffervqqphgsyeffdz`) pode ter divergido com as correções recentes. Os dois
achados acima **precisam de confirmação no banco ao vivo** antes de virar
tarefa — e a confirmação leva 30 segundos.

### Verificação que você mesmo roda (leitura pura, sem crédito)

No SQL do Lovable/Supabase:

```sql
-- Achado 1: ainda existe acesso anônimo às tabelas de anamnese?
select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and 'anon' = any(roles)
order by tablename;

-- Achado 2: existe auditoria/soft-delete em patients?
select column_name from information_schema.columns
where table_name = 'patients' and column_name in ('deleted_at');
select to_regclass('public.data_audit_log') as tem_audit_log;
```

Se o primeiro devolver linhas de `anamnesis_*` com `qual = true`, o Achado 1
está vivo. Se o segundo devolver vazio/nulo, o Achado 2 está vivo.

## Prioridade para os 16 dias até 01/09

1. **Rodar as duas queries acima** — 30 segundos, confirma os dois achados.
2. **Achado 1** — trava. Ou corrige (token + edge function), ou desabilita o
   formulário público de anamnese para o grupo inaugural.
3. **Supabase Pro ligado** antes do lançamento, não no dia.
4. **Achado 2** — auditoria + soft delete em `patients`. Se não couber antes de
   01/09, entra como o primeiro item pós-lançamento, com data.
5. Re-scan do Lovable de novo perto do dia — ele pega regressão comum, e é de
   graça.

## Nota de método

Esta revisão não substitui pentest profissional. Ela cobre o que a auditoria
estática do schema e o histórico de correções revelam. O scanner do Lovable e
esta revisão são complementares: ele pega o padrão comum e a regressão; esta
pega o específico do domínio (dado de saúde, multi-tenant, o formulário
público). Nenhum dos dois dispensa, no futuro, um olhar externo antes de
escalar a base de clientes.
