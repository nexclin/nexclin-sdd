# Auditoria da 024 (T374): a dívida do escopo, e o buraco em `business_rules`

**Data:** 15/09/2026 · **Origem:** T374 da frente 024 (nexclin#123), agente
`auditor-multitenant` sobre a migração `20260914010000` e sobre `escopo.ts` da
Lovable · **Registro:** leitura de código, não comportamento provado.

## A pergunta da tarefa

A policy de escopo da seção 3 da regra 024 (`UPDATE` em `tasks` só pelo
responsável ou master; `UPDATE` de `date` e `doctor_member_id` em
`appointments` só pelo responsável ou master) foi **declarada e não
construída** na Lovable. A pergunta era: **algum lugar deixa um leitor achar
que o banco impede a secretária de editar tarefa alheia?**

**Resposta: não.** Os seis lugares onde isso poderia ser lido errado dizem a
mesma coisa:

| Onde | O que diz |
|---|---|
| `docs/regras/024-perfil-operacional.md`, seção 3 | "declaradas aqui e não construídas na Lovable" |
| `docs/planos/024-perfil-operacional/plan.md`, linhas 31 a 35 | repete em cada aceite, "para que ninguém leia recusada na tela como recusada no banco" |
| `docs/planos/024-perfil-operacional/tasks.md`, linhas 104 a 106 e 137 | a prova 2 fecha com a frase literal "escopo só no front" |
| `supabase/migrations/20260914010000_...sql`, bloco 6, comentário | "O QUE ESTE BLOCO NÃO FAZ" |
| `nexclin-lovable/src/lib/escopo.ts`, linhas 23 a 28 | "Não é segurança. Quem provar que a API aceita o que a tela recusa está vendo o esperado" |
| `Acompanhamento.tsx` 448 a 450 e `Tarefas.tsx` 398 a 401 | comentário junto do `UPDATE` |

A linha da 024 no `docs/regras/README.md` estava atrasada ("nada
implementado"), e foi corrigida no mesmo dia (T373). A policy para a stack nova
virou a issue nexclin#184 (T376).

## As quatro tentativas de furar a cascata

| Tentativa | Resultado | Por quê |
|---|---|---|
| (a) `operacional` toca `tasks` ou `appointments` de outra clínica | **não achado** | as três policies de `tasks` e a `FOR ALL` de `appointments` filtram por `get_my_clinic_id()`, que lê `profiles.clinic_id`, imutável pelo trigger `prevent_clinic_id_change` |
| (b) `DELETE` em `tasks` por algum caminho | **não achado** | policy de `DELETE` removida e não recriada; nenhum `.delete(` sobre `tasks` em `src/`, nenhuma função `security definer` nem edge function que apague tarefa; cancelar é `UPDATE` de `status` (`Tarefas.tsx` 402 a 413) |
| (c) trigger de auditoria vaza `old→new` de outra clínica | **não achado** | `audita_mudanca_de_dado()` grava `clinic_id` da própria linha; `data_audit_log` só é lido por admin da clínica ou superadmin |
| (d) `task_type_weights` escrito por membro não master | **CONFIRMADO, nível médio** | ver abaixo |

## O achado: `business_rules` aceita escrita de qualquer membro da clínica

A policy de `business_rules` é a de 22/03, nunca trocada:

```sql
CREATE POLICY "Users can manage business_rules in their clinic"
  ON public.business_rules FOR ALL TO authenticated
  USING (clinic_id IN (SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid()));
```

Só confere `clinic_id`. A migração de 14/09 pôs `task_type_weights` nessa
tabela sem acrescentar restrição de papel. No front, quem edita o peso é
`ConfigBusinessRulesDialog.tsx`, atrás do módulo `configuracoes`, que o perfil
`operacional` não tem. Mas isso é portão de tela: Maria, logada, consegue
`supabase.from('business_rules').update({ task_type_weights: {...} })` pelo
console, e a policy aceita. É a pessoa medida escolhendo quanto vale a própria
tarefa, o risco que o FR-012 da 024 descreve.

**Não é desta migração:** o buraco é de 22/03 e vale para `followup_days`,
`recall_days`, `patient_required_fields` e todo o resto da tabela. A coluna
nova só o tornou mais sensível, porque agora a tabela alimenta um ranking.

**Faixa A:** é policy, migra intacta para a stack nova.

**Correção mínima:** manter o `SELECT` para todo membro da clínica (a tabela é
lida em 20 lugares do front, inclusive pela secretária) e restringir `INSERT`,
`UPDATE` e `DELETE` a `has_role(auth.uid(), 'admin')` ou superadmin, na mesma
forma da policy de leitura de `data_audit_log`. Os únicos três lugares que
gravam (`ConfigBusinessRulesDialog`, `ConfigPatientFieldsDialog`,
`ConfigAppointmentFieldsDialog`, todos por `upsert`) já estão atrás de
`configuracoes`, então nenhum caminho do front quebra.

**Issue:** nexclin#185.

## O que esta auditoria não alcança

Rota, cron ou integração fora de `src/` e `supabase/` que grave com credencial
de serviço. Não há nenhuma versionada; se existir fora do git, está fora
desta leitura.
