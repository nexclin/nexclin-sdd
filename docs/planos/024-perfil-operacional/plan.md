# Plano de implementação: a secretária opera a clínica

**Frente:** `024-perfil-operacional` · **Data:** 13/09/2026
**Regra:** [`spec.md`](./spec.md), que é link para
[`docs/regras/024-perfil-operacional.md`](../../regras/024-perfil-operacional.md)

> Gerado por `speckit-plan` sob a [ADR 0006](../../adr/0006-o-spec-kit-volta-pela-metade.md).
> **A seção 7 da regra não deixa decisão aberta.** O que este plano isola em
> portão são três dependências de fora da regra: o segundo usuário da clínica de
> teste, a seção 8 da regra 023, e uma premissa sobre `team_members.user_id`
> que só o banco confirma.

---

## 1. Resumo

Quinze requisitos, nove deles **faixa A**, sobre um perfil que hoje existe só de
nome: o escopo `own` que a permissão promete vale num painel de três cartões
vazios, e em Tarefas e Consultas a secretária edita tudo, como o médico. O
plano separa por **o que fica gravado**: primeiro as colunas e o trigger que
transformam "quem fez" em dado, porque sem eles nem "edito só o meu" nem
produtividade têm de onde ler; depois o escopo na tela; depois assumir e
devolver; depois a conta; e por último o painel, que só vale quando todos os
blocos têm fonte.

**Sobe para a Lovable inteiro**, pela exceção nomeada no Princípio IV da
constituição 2.1.0: o lote operacional de setembro vai ao ar como
funcionalidade, e não como bug, porque as clínicas fundadoras só dão feedback
sobre o que está no ar. A mecânica da ponte não muda.

**Uma coisa fica declarada e não construída na Lovable:** a policy de escopo. A
regra diz, na seção 3, que "edito só o meu" é checado no front na plataforma ao
vivo, e a policy vai para a stack nova junto com o FR-011 da regra 021. Este
plano repete isso em cada aceite onde importa, para que ninguém leia "recusada
na tela" como "recusada no banco".

---

## 2. Contexto técnico

| | |
|---|---|
| **Banco** | PostgreSQL no Supabase, dois projetos: o da plataforma Lovable, ao vivo, e o da stack nova |
| **Onde se testa banco** | editor de SQL contra o banco ao vivo, com migração autorizada. Sem Docker e sem banco local |
| **Front da Lovable** | React e Vite, clone em `../nexclin-lovable`. Gate de tipos: `npx tsc --noEmit -p tsconfig.app.json`. **Nunca `npx vite build`**: o plugin do MCP reescreve `supabase/functions/mcp/index.ts` e o esvazia |
| **Front da stack nova** | Next.js App Router, TypeScript estrito |
| **Testes** | Vitest, 20 arquivos em `src/lib/__tests__/` na plataforma. Teste vermelho antes do código, em toda tarefa de `src/lib/` |
| **Caminho até o cliente** | ponte inversa, `docs/ponte/ponte-inversa.md`: `git pull` antes, `main` sempre, nunca `--force`, function antes do Publish do front. O Arthur publica; o agente não |
| **Alvo de prazo** | nenhum fixado. As fundadoras estão no ar desde 08/09; a ordem das fases é por dependência de dado, e cada fase é entregável sozinha |
| **Régua de qualidade** | 200%: construído e testado por quem construiu, **mais** validado pela ótica da secretária. Quem valida é a Maria da conta `maria@lancamento.com`, e o Vinícius, com print |

**Fatos conferidos no código em 13/09, que corrigem ou precisam o que a regra diz:**

1. Os totais "Orçado" e "Vendas" do FR-005 estão em
   `src/pages/Acompanhamento.tsx`, linhas 1965 a 1970, na rota
   `/acompanhamento`, módulo `acompanhamento`. **`Consultas.tsx` existe e não os
   tem.** A tela que a regra chama de Consultas é a do módulo `acompanhamento`,
   o que a ADR 0001 já previa ao tirar `consultas` do contrato.
2. `appointments.doctor` e `appointments.responsible` são `TEXT DEFAULT ''`
   desde a migração de 22/03, como a regra diz.
3. `public.tasks` tem uma policy só, `FOR ALL TO authenticated`, de 22/03.
   Remover o `DELETE` do FR-009 exige **quebrar essa policy em três**, e não
   apagar uma quarta que não existe.
4. O trigger `audita_mudanca_de_dado` da migração de 25/08 deste repositório
   cobre `patients`. **Só `patients`**: a migração de 27/08, das cinco tabelas
   de configuração, não está no banco ao vivo (censo de 14/09). O trigger
   chegou ao banco por bloco de SQL, não pelo clone da Lovable, e existe: a
   Fase 1 o estende.
5. `quemPodeEditar` em `src/lib/tiposDeTarefa.ts` já decide edição de tarefa
   por `created_by` e libera tudo que nasceu sem autor. O FR-003 troca o
   critério de autor para responsável, e o `escopo.ts` novo absorve essa
   função em vez de conviver com ela.
6. `DEFAULT_PERMISSIONS_BY_LEVEL.operacional` em `src/hooks/usePermissions.ts`
   é `leads: own`, `anamnese: status_only`, `tarefas: own`. A regra manda
   `leads: all` e `anamnese: full`, e "Apenas status" hoje é rótulo que não
   filtra.
7. `src/lib/recall.ts` calcula o recall na hora e não grava linha, como a regra
   diz. O FR-010 cria tarefa, e é a única escrita que o recall passa a ter.

**A PRECISAR DE ESCLARECIMENTO: nenhuma na regra.** As três dependências de
fora viram portões na seção 5.

---

## 3. Portão constitucional

Conferido contra `docs/constituicao.md` v2.1.0, pelo ponteiro em
`.specify/memory/constitution.md`.

| Alínea | O que exige | Situação neste plano |
|---|---|---|
| **(a)** | RLS em toda tabela com `clinic_id` | nenhuma tabela nova. Colunas em `tasks`, `appointments` e `business_rules`, que já têm RLS. **Passa** |
| **(b)** | default deny | a policy `FOR ALL` de `tasks` vira `SELECT`, `INSERT` e `UPDATE`, sem `DELETE`. Nenhum `USING(true)`. **Passa** |
| **(c)** | segurança no banco, tela só reflete | **VIOLAÇÃO DECLARADA.** "Edito só o meu" e "data e médico só pelo responsável" ficam no front na Lovable, por decisão da seção 3 da regra. A policy vai para a stack nova com o FR-011 da 021. Ver seção 6 |
| **(d)** | auditoria de ação administrativa, `old→new` | o trigger de `data_audit_log` passa a cobrir `tasks` e `appointments`. Assumir, devolver, reatribuir, mudar data e trocar médico ficam com `previous_state`. **Passa por construção** |
| **(e)** | senha só por quem cria o acesso, com auditoria | não tocada. **Passa** |
| **(f)** | as 15 ModuleKeys | nenhum módulo novo. O painel operacional é `dashboard: simplified`, que já existe. **Passa** |
| **(g)** | nenhuma credencial versionada | nada de credencial. **Passa** |
| **(h)** | regra viva aprovada, e parada humana por fase | a regra 024 existe e a seção 7 está fechada. **Cada fase abaixo para para aceite** |
| **(j)** | implementado ≠ funciona | a seção 6 da regra tem onze provas, dez delas na tela. Onde a Lovable não prova o banco, o aceite grava "escopo só no front" |
| **(l)** | mudança de comportamento corrige a regra no mesmo commit | `spec.md` é link para a regra. O fato 1 da seção 2 (a tela é `Acompanhamento.tsx`) entra na regra no commit da Fase 2 |
| **Princípio IV** | o que sobe para a Lovable | pela exceção nomeada de 12/09. Banco é faixa A e atravessa; tela é faixa C e sobe pela mesma exceção. **Passa** |

**Nenhuma violação nova é introduzida.** A única é a que a própria regra
declara, e ela tem destino: a stack nova.

---

## 4. Estrutura

### Desta frente

```text
docs/planos/024-perfil-operacional/
├── spec.md   → link para ../../regras/024-perfil-operacional.md
├── plan.md   este arquivo
└── tasks.md  gerado por /speckit-tasks
```

**Quatro artefatos que o Spec Kit geraria e este plano NÃO gera**, pelo mesmo
motivo da 021: cada um já mora na regra, e a alínea (l) existe para impedir a
segunda cópia.

| O que o Spec Kit geraria | Onde isso já mora |
|---|---|
| `research.md` | seção 4 da regra, e os sete fatos da seção 2 acima, que são a pesquisa feita |
| `data-model.md` | **seção 3 da regra**, a tabela "o que muda no banco" |
| `quickstart.md` | seção 6 da regra, as onze provas |
| `contracts/` | não se aplica: não há interface externa nova. As três funções de `src/lib/` são contrato interno, e o teste é o contrato |

### Do código

```text
supabase/migrations/                      migração nova, fonte de verdade do schema
docs/ponte/                               bloco de SQL para colar no editor, e o de conferência
../nexclin-lovable/src/lib/escopo.ts      quais campos cada membro edita; assumir e devolver
../nexclin-lovable/src/lib/painelOperacional.ts   os seis blocos a partir do dado bruto
../nexclin-lovable/src/lib/produtividade.ts       pontuação e ranking
../nexclin-lovable/src/lib/__tests__/     um arquivo por função acima, vermelho antes
../nexclin-lovable/src/hooks/usePermissions.ts    padrão do perfil operacional
../nexclin-lovable/src/pages/Tarefas.tsx          escopo, assumir, devolver, cancelar
../nexclin-lovable/src/pages/Acompanhamento.tsx   campos por papel, totais por permissão
../nexclin-lovable/src/pages/Recall.tsx           assumir cria tarefa
../nexclin-lovable/src/pages/DashboardOperational.tsx   o painel de seis blocos
../nexclin-lovable/src/pages/Configuracoes.tsx    pesos por tipo
../nexclin-lovable/src/components/config/ConfigTeamDialog.tsx   Completo, Simplificado, Sem acesso
```

---

## 5. As fases, e os portões

**Cada fase termina com aceite manual do Arthur**, alínea (h). Fase que não passa
no aceite não libera a seguinte. Toda fase que toca o clone segue a ponte:
`git pull` antes, `main`, `tsc` com `-p tsconfig.app.json`, commit com caminho
explícito e push no mesmo comando.

### Fase 0 · Conferir o banco antes de acreditar nele

**Não implementa nada.** Um bloco de SQL em `docs/ponte/`, para colar no editor,
que responde quatro perguntas de uma ida só:

1. `team_members.user_id` está preenchido para todo membro que loga? Conta os
   nulos por clínica. É a **premissa 1** da regra, e decide o Portão 3.
2. O trigger `audita_mudanca_de_dado` existe no banco ao vivo, e em quais
   tabelas? `pg_trigger` sobre `patients` e as cinco de configuração.
3. `tasks.type` tem `CHECK` ou é texto livre? `information_schema.check_constraints`.
   Decide se `recall_paciente` exige `ALTER` ou só entra na lista do front.
4. As policies de `tasks` e `appointments`, direto do `pg_policies`. Confirma o
   fato 3 da seção 2.

**Aceite:** o que voltar bate com a seção 3 da regra. Se divergir, a divergência
é o achado, e a regra se corrige antes de qualquer migração.

### Portão 1 · O segundo usuário · issue #50

**Sem ele, nenhuma prova da seção 6 fecha.** "Vejo tudo, edito só o meu",
assumir, devolver e ranking exigem duas pessoas na mesma clínica de teste. A
issue é do Arthur. As Fases 1 e 2 podem ser construídas antes; **nenhuma fecha
aceite** antes deste portão.

### Fase 1 · O que fica gravado · faixa A · Lovable e stack nova

FR-002, FR-007 a FR-010 na parte de banco, FR-012 na parte de banco. É a fase
que atravessa intacta para outubro.

Uma migração neste repositório, e o bloco de SQL correspondente em `docs/ponte/`:

1. `tasks.responsible_member_id uuid` anulável, referência a
   `team_members(id) ON DELETE SET NULL`. O texto `responsible` fica.
2. `appointments.responsible_member_id` e `appointments.doctor_member_id`, na
   mesma forma.
3. O trigger `audita_mudanca_de_dado` em `tasks` e em `appointments`, na forma
   dos de 25/08 e 27/08. **Nenhuma tabela nova de histórico**: assumir e
   devolver são linhas de `data_audit_log`.
4. `business_rules.task_type_weights jsonb NOT NULL DEFAULT '{}'`. Ausente lê
   como 1. Mesma forma de `patient_required_fields`.
5. A policy `FOR ALL` de `tasks` quebrada em `SELECT`, `INSERT` e `UPDATE`,
   com o mesmo predicado de clínica. **Sem `DELETE`.** O hook
   `guarda-constituicao.mjs` reprova `USING(true)`; o predicado é o de hoje.
6. `recall_paciente` no `CHECK` de `tasks.type`, **só se a Fase 0 mostrar que o
   `CHECK` existe**.

**Ordem obrigatória:** migração antes de qualquer front. Tela que grava
`responsible_member_id` com a coluna inexistente quebra Tarefas inteira.

**Aceite:** o bloco de conferência da Fase 0 rodado de novo, mostrando as
colunas, os dois triggers e as três policies. Mais: um `DELETE FROM tasks` como
`authenticated` no editor devolve zero linha apagada. **Com controle positivo:**
o mesmo `UPDATE` de `status` passa.

### Fase 2 · Vejo tudo, edito só o meu · faixa A e C · Lovable

FR-001, FR-003, FR-004, FR-005, FR-006.

1. `src/lib/escopo.ts`, com teste vermelho antes: `camposEditaveisDaConsulta`
   (responsável e master editam tudo; médico da consulta edita status e
   fechamento; os demais nada) e `podeEditarTarefa` (responsável, ou master, ou
   gerencial). Absorve `quemPodeEditar` de `tiposDeTarefa.ts`, que deixa de
   existir. A regra de tarefa sem autor (libera) vira tarefa **sem
   responsável** (libera para assumir, não para editar).
2. `usePermissions.ts`: `operacional` passa a `leads: all`, `anamnese: full`,
   `tarefas: own`, `acompanhamento: own`. É padrão para membro novo; membro
   existente mantém o que o dono gravou.
3. `Tarefas.tsx`: a lista mostra a clínica inteira para `own`; o botão de editar
   obedece `podeEditarTarefa`.
4. `Acompanhamento.tsx`: data, horário e médico só para responsável e master;
   status e fechamento também para o médico da consulta. A tela grava
   `responsible_member_id` ao criar e `doctor_member_id` ao delegar, a partir
   do `team_members` do usuário logado. Os totais das linhas 1965 a 1970 só com
   `relatorios_vendas: all`; o valor por linha continua.
5. Anamnese: `status_only` passa a filtrar as respostas de fato.
6. **Na regra, no mesmo commit, pela alínea (l):** o FR-005 nomeia
   `Acompanhamento.tsx` como a tela.

**Aceite:** provas 1, 2 e 8 da seção 6, com Maria e o médico logados. **A prova
2 fecha com a frase literal "escopo só no front"**: a API da Lovable aceita o
`UPDATE` que a tela recusa, e isso é o esperado até a stack nova.

### Fase 3 · Assumir, devolver, cancelar · faixa A · Lovable

FR-007, FR-008, FR-009, FR-010 na parte de tela.

1. `escopo.ts` ganha `podeAssumir` (tarefa sem `responsible_member_id`, e quem
   olha tem `team_members`) e `podeDevolver` (é o responsável). Teste vermelho
   antes.
2. `Tarefas.tsx`: botão assumir em tarefa sem dono; devolver para quem assumiu;
   reatribuir só para master e gerencial. Assumir grava id e nome; devolver zera
   os dois. O trigger da Fase 1 faz o registro sozinho.
3. `Tarefas.tsx`: nenhum caminho chama `DELETE`. Cancelar é `UPDATE` de
   `status`. Se a Fase 1 quebrou a policy, o `DELETE` que sobrou no código
   falharia em silêncio; por isso ele sai do código também.
4. `Recall.tsx`: assumir item vencido cria tarefa `recall_paciente` com o
   paciente ligado e quem assumiu como responsável; a linha do recall mostra que
   tem dono lendo a tarefa aberta desse paciente e tipo.
5. `tiposDeTarefa.ts`: `recall_paciente` entra em `TIPOS_MANUAIS` e em
   `ROTULOS_DE_TIPO`, separado de `recall` (automático) e de `recaptacao_*`.

**Aceite:** provas 3, 4, 5 e 6. Na prova 3, as duas linhas em `data_audit_log`
conferidas no editor, com `previous_state`.

### Portão 3 · O dono sem `team_members`

Abre com a pergunta 1 da Fase 0. Se o dono das clínicas de agosto (migração de
25/08) não tem linha em `team_members`, ele **não consegue assumir** até a
correção, e a Fase 3 precisa de um item a mais: a linha dele. **Não é desta
regra decidir se a correção é migração ou tela do superadmin**; o portão
existe para que o aceite da Fase 3 não seja lido como "botão não aparece,
bug", quando é premissa não atendida.

### Fase 4 · Produtividade · faixa A e C · Lovable

FR-011, FR-012, FR-013.

1. `src/lib/produtividade.ts`, teste vermelho antes: `pontuacao` (tarefas
   concluídas com `completed_at::date <= due_date` no fuso do Brasil via
   `dataLocal.ts`, cada uma valendo o peso do tipo, ausente lê 1) e `ranking`
   (as quatro medidas por membro e por período, ordenado, filtrável por
   `team_members.role`). Fontes: `tasks`, `data_audit_log` para assumidas,
   `appointments.responsible_member_id`, `lead_history`.
2. `Configuracoes.tsx`: a tabela de pesos por tipo, gravando em
   `business_rules.task_type_weights`. O peso é lido na soma, não gravado na
   tarefa: mudar o peso muda o passado, e a auditoria de `business_rules`
   mostra quando.
3. Ranking no painel do dono e em `src/pages/relatorios/`, visível a todo
   membro, médicos na lista.

**Aceite:** provas 9 e 10. Na 9, o peso muda e a pontuação muda na próxima
leitura, sem tocar em tarefa nenhuma.

### Portão 2 · A seção 8 da regra 023

O bloco 4 do painel, mensagens não lidas, lê a caixa que a seção 8 da 023
especifica e que **ainda não existe**. A regra 024 já decide: sem ela o painel
nasce com cinco blocos e o sexto entra depois. A Fase 5 não espera; o bloco 4
entra quando a 023 entregar, como uma tarefa a mais.

### Fase 5 · O painel · faixa C · Lovable

FR-014, FR-015.

1. `src/lib/painelOperacional.ts`, teste vermelho antes: recebe consultas de
   hoje, tarefas, leads com cadência (FR-001 da 018), recalls e mensagens, e
   devolve os seis blocos **na ordem do FR-014**, sem nenhum campo em reais.
   O teste afirma a ordem e afirma que nenhum bloco carrega valor.
2. `DashboardOperational.tsx`: os três cartões vazios saem; entram os seis
   blocos, com seletor de médico quando a clínica tem mais de um. O bloco 5 usa
   o mesmo `podeAssumir` da Fase 3.
3. `ConfigTeamDialog.tsx`: Completo, Simplificado e Sem acesso continuam por
   pessoa; conferir na tela que Simplificado não mostra dinheiro em bloco
   nenhum. Hoje é "código lido, não provado na tela".

**Aceite:** prova 7. Painel de Maria com seis blocos (ou cinco, se o Portão 2
não abriu, e isso fica escrito no aceite), nenhum valor em reais, seletor
presente quando a clínica tem dois médicos.

---

## 6. Complexidade a justificar

| Violação | Por que ela existe | Alternativa mais simples, e por que não serve |
|---|---|---|
| **Alínea (c)**: escopo de edição só na tela, na Lovable | decisão da seção 3 da regra: a policy de escopo é escrita na stack nova com a cascata do FR-011 da 021, porque nenhuma das 79 policies do banco ao vivo chama `my_permission` hoje, e uma policy de escopo em cima de uma base sem cascata seria a única de sua espécie | escrever a policy agora na Lovable. Não serve: exige a cascata inteira, que é o FR-011, e o FR-011 está fora da véspera de qualquer coisa por decisão de 07/09 |
| **Coluna nova ao lado de texto** em `tasks` e `appointments` | o texto não está errado, e a migração de texto para pessoa é da stack nova (regra 022, FR-005, emenda de 12/09). Duas colunas por um mês custa menos que uma conversão que pode casar a pessoa errada | migrar o texto agora. Não serve: 73% de `tasks.responsible` aponta para setor, e não há pessoa para casar |
| **Quebrar a policy `FOR ALL`** em três | é o único jeito de tirar `DELETE` sem `USING(false)` numa quarta policy, que o hook leria como esquisitice e o próximo leitor como erro | manter `FOR ALL` e só tirar o botão. Não serve: alínea (c), e a tela não é segurança |
| **Dois alvos**, Lovable e stack nova | o Princípio IV, exceção de 12/09: sem o perfil no ar, a stack nova nasce com o perfil que não serve | só stack nova. Não serve pela razão da própria exceção: feedback só existe sobre o que está no ar |

---

## 7. O que este plano deliberadamente não faz

- **Não escreve policy de escopo na Lovable.** Declarada, com destino.
- **Não migra `responsible` nem `doctor` de texto para referência.** Coluna ao
  lado, texto fica.
- **Não cria tabela de histórico de tarefa.** `data_audit_log` já é isso.
- **Não grava recall.** O recall continua calculado na hora; o que se grava é a
  tarefa de quem assumiu.
- **Não inventa nota de feedback nem eficiência.** As quatro medidas são as que
  o banco permite contar; o resto fica para regra própria quando houver fonte.
- **Não toca bloqueio de agenda, escala júnior a sênior, nem responsável por
  setor como entidade.** Fora desta versão, com dono para virar regra.
- **Não decide o Portão 3.** Quem não tem `team_members` não assume, e a
  correção tem dono fora daqui.
