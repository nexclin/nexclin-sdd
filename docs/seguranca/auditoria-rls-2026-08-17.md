# Auditoria de RLS — Lovable ao vivo × stack nova (17/08/2026)

> **Pergunta que originou:** o RLS das duas plataformas está alinhado, e o
> Lovable está entregável para o mercado em 01/09?
> **Método:** consultas de catálogo (`pg_class`, `pg_policy`, `pg_trigger`,
> `information_schema`) rodadas nos dois bancos ao vivo. Somente leitura.
> **Resposta curta:** no isolamento entre clínicas, **sim** — e as duas
> plataformas têm postura idêntica. A lacuna que permanece é de auditoria
> (Achado 2), não de isolamento.

---

## Quadro comparativo

| Verificação | Lovable (produção) | Stack nova |
|---|---|---|
| Tabelas no schema `public` | 45 | 44 |
| Tabelas **sem RLS** | **0** | **0** |
| Tabelas com RLS mas **sem policy** | **0** | **0** |
| Policies concedidas ao papel `anon` | **0** | **0** |
| Triggers desabilitados | **0** (de 32) | **0** |
| Âncora `prevent_clinic_id_change` ativa | **sim** | **sim** |

A diferença de uma tabela é `teste_restore` — ver "Higiene" abaixo.

## O que foi verificado, em ordem de severidade

### 1. Nenhuma tabela desprotegida

Consulta por tabelas com `relrowsecurity = false` **ou** com zero policies:
retornou **nenhuma linha** nos dois bancos. Não existe tabela de negócio
acessível sem política.

### 2. Isolamento por clínica

Consulta por policies em tabelas que **têm** coluna `clinic_id` mas cuja
expressão `USING` **não** referencia `clinic_id` nem `superadmin`. Três
resultados no Lovable, os três legítimos:

| Tabela | Policy | Por que não é falha |
|---|---|---|
| `profiles` | Users can view own profile (SELECT) | Escopo por `user_id = auth.uid()` — é o próprio perfil, não dado de clínica. |
| `profiles` | Users can update their own profile (UPDATE) | Mesmo escopo. Ver ressalva abaixo. |
| `superadmin_audit_log` | Superadmins can insert audit logs (INSERT) | Policy de INSERT não tem `USING` por definição; usa `WITH CHECK`. |

### 3. A ressalva que exigiu verificação extra

A policy de UPDATE em `profiles` **não define `WITH CHECK`**. Nesse caso o
Postgres reaproveita a expressão do `USING`, que só valida `user_id` — ou seja,
**a policy sozinha não impede o usuário de alterar o próprio `clinic_id`** e
migrar para dentro de outra clínica. Essa é exatamente a brecha crítica que o
`CLAUDE.md` §3.1 registra como já fechada.

A defesa não está na policy, está em trigger. Confirmado ao vivo:

- Trigger `profiles_prevent_clinic_id_change`, `BEFORE UPDATE ON public.profiles`
- Estado: **habilitado** (`tgenabled = 'O'`)
- Nenhum dos 32 triggers do schema está desabilitado

**Conclusão:** a âncora multi-tenant está protegida, mas por uma única camada.
Se alguém desabilitar esse trigger, a policy não segura. Vale endurecer a policy
com um `WITH CHECK` explícito na janela de 22–23/08 — defesa em profundidade,
não urgência.

## Higiene: tabela de teste esquecida em produção

`teste_restore` existe no banco do Lovable. É resíduo do exercício de segurança
de 02/08 (testes de restauração e forense feitos no chat da plataforma). Tem RLS
ligado e 1 policy, não tem `clinic_id`, e está vazia — **não é falha de
segurança**, é lixo em produção. Remover antes de 01/09.

## O que continua NÃO entregável

1. **Achado 2 — ação sobre `patients` não deixa rastro.** Sem `deleted_at`, sem
   `data_audit_log`, sem autor nem momento. Confirmado vivo em 16/08 nos dois
   bancos. É lacuna de LGPD, não de isolamento. Correção na janela de 22–23/08.
2. **Sem recuperação no tempo.** O tier atual não tem PITR; o próprio agente da
   Lovable registrou em 02/08 que um `DELETE` direto é irreversível. Mitigação
   disponível e gratuita: `Cloud → Advanced settings → Export project data`
   antes de qualquer escrita. O Supabase Pro resolve de forma definitiva.

## Método e limites

Esta auditoria é **estrutural**: prova que as policies existem, estão ligadas e
referenciam a âncora certa. Ela **não** substitui o teste funcional — autenticar
como usuário da clínica A e tentar ler dado da clínica B pela API. Esse teste
está no roteiro do Vinícius (dia 5) e é a confirmação empírica que fecha o
assunto.
