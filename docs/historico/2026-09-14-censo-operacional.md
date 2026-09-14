# Censo operacional, 14/09/2026: Fase 0 das frentes 024 e 023, rodada no banco ao vivo

**Frente:** 024 (T305, T306) e 023 (T204, T205) · **Onde:** editor de SQL da
Lovable, `More > Cloud > SQL editor`, pelo Chrome, uma consulta por vez ·
**Quem clicou:** o agente, porque tudo era `SELECT`; nada foi escrito ·
**Bloco:** [`docs/ponte/024-censo-operacional.sql`](../ponte/024-censo-operacional.sql)

> O editor **não** travou depois da primeira consulta, ao contrário do que a
> nota de 19/08 registrou. Seis consultas em sequência, com `Clear` entre
> elas e `Ctrl+Enter` para rodar, todas com resultado novo. A diferença
> provável: em 19/08 a automação digitava sem limpar o editor.

## 1. Premissa 1: quem loga tem `team_members.user_id`? (bloco 1d)

Uma linha por clínica. `com` é `team_members` com `user_id`; `sem` é
`team_members` sem `user_id`; `fora` é `profiles` da clínica sem linha em
`team_members`. **24 clínicas**, quase todas de teste.

| Clínica | com | sem | fora |
|---|---|---|---|
| (sem nome) `eb783ca2` | 0 | 1 | 0 |
| (sem nome) `bd3a3200` | 1 | 0 | 0 |
| Apresentadores Famosos | 1 | 4 | 1 |
| Barros Clinic | 1 | 2 | 0 |
| Clínica Davi Moraes | 1 | 0 | 0 |
| Clínica Dra. Duda Gonçalves (2 clínicas) | 1 e 1 | 0 e 0 | 0 e 0 |
| **Clínica Lançamento** `45f88cf2` | **2** | 0 | **2** |
| Clínica Teste | 1 | 1 | 0 |
| Clínica Teste Bypass | 1 | 0 | 0 |
| Clínica Teste Final `d51ce6c7` | 1 | 1 | 0 |
| Clínica Teste Vinicius 1 | 1 | 1 | 0 |
| Clínica Vazia (Bypass Test) | 0 | 0 | 0 |
| Clínica VB | 1 | 4 | 0 |
| Flamengo (2 clínicas) | 1 e 1 | 6 e 1 | 0 e 0 |
| NexClin | 2 | 1 | 1 |
| teste (3 clínicas) | 1, 1, 1 | 1, 4, 1 | 0, 0, 0 |
| Teste 3 | 1 | 4 | 0 |
| Teste 4 | 1 | 1 | 0 |
| Teste Final V2 | 1 | 4 | 1 |

**O controle positivo passou:** `com` é maior que zero em 22 das 24. A
consulta lê certo.

**A Clínica Lançamento, detalhada:** 4 `profiles` (Dr. Lançamento, admin;
Sra. Joana; Sra. Lancinha; Sra. Maria) e 2 `team_members` com `user_id`
(Dr. Lançamento, `master`, `medico_principal`; **Sra. Maria, `operacional`,
`secretaria`**). Joana e Lancinha logam e não têm `team_members`: são as
duas "fora".

### O que isso decide

- **Portão 1 das duas frentes está aberto.** Maria (operacional) e o
  Dr. Lançamento (master) logam na mesma clínica. A prova "vejo tudo, edito
  só o meu" tem as duas pessoas de que precisa. A issue #50 (os e2e da
  cascata) é outra coisa e continua como está.
- **Portão 3 existe, e é de teste.** `sem_user_id` acima de zero em 17
  clínicas, quase todas de teste: são o dono de agosto sem `user_id` e
  convites pendentes. Joana e Lancinha não conseguem assumir tarefa até
  ganharem linha em `team_members`. **T352 leva o número ao Arthur**; a
  correção não é desta regra.
- **As clínicas fundadoras não aparecem por esses nomes.** Nenhuma linha se
  chama Claros Clinic nem Cezar Essence. Ou a razão social gravada em
  `clinics.name` é outra, ou elas estão em outro projeto. **Fica aberto**, e
  é a primeira pergunta para o Arthur antes de qualquer aceite com clínica
  real.

## 2. O trigger de auditoria (bloco 2)

`audita_mudanca_de_dado` está ligado em **uma tabela só: `patients`**
(`patients_audita_mudanca`, `AFTER INSERT OR DELETE OR UPDATE`). **As cinco
tabelas de configuração da migração de 27/08 não têm o trigger no banco ao
vivo.** A regra 024, seção 3, dizia "hoje cobre `patients`" e estava certa;
o plano dizia sete tabelas e estava errado (corrigido neste commit).

Outros triggers, para o controle positivo: `tasks` tem
`trg_set_task_completed_at` e `update_tasks_updated_at`; `appointments` tem
`trg_auto_complete_appointment_task` e `update_appointments_updated_at`.
Nenhum de auditoria nas duas. **T310 cria, não confere.**

## 3. `tasks.type` (bloco 3)

`type` é `text`, **sem `CHECK`**. A única `CHECK` de `tasks` é
`tasks_origem_check`, `origem IN ('manual', 'automatica')`, que é o controle
positivo e confirma que a migração de 25/08 está no ar. **T312 vira
comentário**: `recall_paciente` entra só pela lista do front (T343).

## 4. As policies (bloco 4)

| Tabela | Policies | Forma |
|---|---|---|
| `tasks` | 1, `Users can manage tasks in their clinic` | `ALL`, `authenticated`, `clinic_id IN (select clinic_id from profiles where user_id = auth.uid())`, `with_check` igual |
| `appointments` | 1, `Users can manage appointments in their clinic` | idêntica |
| `task_comments` | 2, `SELECT` por clínica e `INSERT` com `author_id = auth.uid()` | o bloco b1 da 023 está no ar (T201 confirmada) |
| `team_members` | 4, uma por operação, com `get_my_clinic_id()` e `can_manage_team()` | referência de policy por operação que já existe nesta base |

Nenhuma chama `my_permission`. **T313 quebra a `FOR ALL` de `tasks` em
três**, como o plano dizia. E `get_my_clinic_id()` existe: a migração pode
usá-la em vez de repetir o subselect.

## 5. Realtime, para a 023 (T202)

A publicação `supabase_realtime` existe, `puballtables = false`, **sem tabela
nenhuma**. T241 é `ALTER PUBLICATION supabase_realtime ADD TABLE
public.internal_messages`, não `CREATE`.

## O que não deu para conferir

- Os blocos 1a, 1b e 1c por clínica não foram rodados um a um: o 1d, que os
  resume, bastou para decidir os portões, e o detalhe foi rodado só para a
  Clínica Lançamento e as duas sem nome.
- Os `GRANT`s de `authenticated` em `tasks` (bloco 4b) não foram rodados. A
  policy `FOR ALL` cobre `DELETE`, e é ela que T313 troca; o `GRANT` fica
  para a conferência de T319, depois de aplicar.
