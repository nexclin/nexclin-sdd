# Tasks: SPEC 002 — Segurança: anamnese pública e auditoria de dado de paciente

**Feature**: `002-seguranca-anamnese-auditoria` · **Alvo primário**: plataforma
Lovable ao vivo · **Janela de execução**: 22–23/08/2026

> Cada fase fecha com gate de aceite manual (Princípio IV). `[P]` =
> paralelizável. `[aceite]` = verificação manual do Arthur.
> Regra transversal: segurança no banco, default deny, nenhuma credencial
> versionada, nenhum caminho define senha.

---

## Estado verificado em 18/08/2026 — leia antes de planejar a janela

A spec foi escrita em 16/08. **Duas das três fases mudaram de tamanho desde
então**, e ignorar isso faria a janela de 22–23 começar com o escopo errado.

| Fase | Escrita na spec | Estado real, verificado |
|---|---|---|
| **Fase 0** — confirmar ao vivo | gate absoluto | **fechada** — executada em 16/08 |
| **Fase 1** — anamnese por token | construir do zero | **substancialmente resolvida**, com dívida residual |
| **Fase 2** — rastro em `patients` | construir | **é o trabalho real da janela** |
| **Fase 3** — backport | construir | depende da Fase 2 |

### Por que a Fase 1 encolheu

O acesso anônimo direto às tabelas **já foi removido** — zero policies `anon`
em todo o schema, confirmado por consulta ao banco ao vivo. A anamnese pública
passou a ser servida pela edge function `anamnesis-public`, que roda com service
role.

E a função é mais conservadora do que a spec supunha. Lendo o código dela no
repositório da plataforma:

- em `get`, devolve **apenas** `id`, `status` e a definição do formulário
  (`title`, `fields`). **Não devolve as respostas do paciente**, nem
  `patient_id`, nem `clinic_id`;
- em `submit`, recusa com 409 se `status = 'preenchido'` — **uso único já
  implementado**;
- valida formato UUID antes de qualquer consulta.

Ou seja: a parte grave do Achado 1 — *"qualquer um lê e adultera anamnese de
qualquer paciente de qualquer clínica"* — **está fechada**. Ninguém lê resposta
alheia.

### A dívida que sobrou

`public_token` **não existe** em nenhuma migração da plataforma (busca no
repositório: zero ocorrências). O link público continua usando o **`id` da
resposta** como credencial de acesso.

Na prática um UUID v4 tem 122 bits e não se adivinha. A diferença é de desenho,
e é real: uma chave primária **não pode ser rotacionada nem expirada** sem mexer
na identidade da linha, e ela vaza por onde URL vaza — histórico, log de
servidor, encaminhamento de link, `Referer`. Um token dedicado se revoga sozinho.

**Isso é decisão, não tarefa** — está em T002.

---

## Fase 1 — Anamnese pública: fechar a dívida residual

- [ ] T001 [aceite] Verificar o formulário público ponta a ponta na plataforma ao vivo: abrir o link de uma resposta pendente, preencher, enviar, e **tentar reabrir** — deve recusar com "já enviado". Sem isso, o comportamento de uso único é código lido, não comportamento provado.
- [ ] T002 [decisão] Definir se o `public_token` dedicado entra antes de 01/09 ou vira backlog. Entrada: o risco é vazamento de link, não adivinhação. Saída: decisão registrada em `docs/seguranca/`. **Sem decisão, T003 não abre.**
- [ ] T003 Se aprovado em T002: migração com `public_token uuid not null default gen_random_uuid()` + índice único em `anamnesis_responses`; edge function passa a aceitar token; front usa `/anamnese-publica/:token`; `id` deixa de ser aceito. Migração no repositório da plataforma, pela ponte inversa.

## Fase 2 — Rastro em dado de paciente  *(o trabalho da janela de 22–23/08)*

- [ ] T004 **Exportar o banco antes de qualquer escrita** — `Cloud → Overview → Advanced settings → Export project data → Export → Start export`. Não há recuperação no tempo neste tier; este é o único ponto de retorno. **Nenhuma tarefa abaixo começa sem isto.**
  - **O export é assíncrono.** A tela confirma com "Database export started" e o link chega **por e-mail**, depois. *Disparar* o export não é *ter* o dump — o gate só fecha quando o link chega e o arquivo baixa. Observado ao vivo em 18/08/2026.
  - **Limite de 1 export a cada 24 horas** (texto do próprio modal). Se a janela de 22–23/08 precisar de dois pontos de retorno no mesmo dia, **não haverá**: planeje as escritas para caber num único ponto, ou distribua entre os dois dias.
  - O arquivo fica no Cloud storage do projeto. Se o Cloud for desabilitado, os exports **deixam de ser baixáveis** — guarde uma cópia fora da Lovable.
> **Estado em 25/08/2026 — T005 a T008 estão ESCRITOS, e NÃO aplicados.**
>
> A migração vive em
> `supabase/migrations/20260825060000_auditoria_de_dado_e_soft_delete_em_patients.sql`
> e cobre as quatro tarefas de uma vez: a tabela `data_audit_log` com RLS, o
> trigger de auditoria em `patients`, a coluna `deleted_at` e as policies
> separadas por operação.
>
> **Foi escrita aqui primeiro, e essa é a ordem certa.** A constituição diz que
> `supabase/migrations` é a fonte de verdade do schema e que nenhuma mudança de
> banco entra por alteração manual no painel. O handoff de 20/08 previa o
> caminho inverso (corrigir na plataforma e fazer o backport depois, no T014);
> escrever no repositório primeiro e levar pela ponte elimina o passo de
> transcrição, que é onde o erro entra.
>
> **O que uma sessão de agente NÃO pode fazer, e não fez:** aplicar. Aplicar
> exige o export (T004) confirmado à mão e é ato do Arthur. Nada foi escrito em
> banco nenhum.
>
> **Três decisões da migração que valem leitura antes de aplicar:**
>
> 1. `data_audit_log` **não tem policy de INSERT, UPDATE nem DELETE.** Com RLS
>    ligada e nenhuma policy de escrita, toda escrita por sessão de usuário é
>    negada, e quem grava é o trigger, que roda `SECURITY DEFINER` e não passa
>    por RLS. É assim que "escrita só pelo trigger" vira garantia do banco em
>    vez de confiança no código da aplicação. A trilha fica imutável inclusive
>    para o superadmin.
> 2. **`DELETE` em `patients` deixa de existir para a aplicação.** Não se cria
>    policy de DELETE, então ele é negado por default deny. Se o DELETE
>    continuasse disponível, o soft delete seria convenção opcional em vez de
>    garantia.
> 3. **A policy única `FOR ALL` foi separada por operação.** O `SELECT` passa a
>    filtrar `deleted_at is null`; o `UPDATE` **não** filtra, porque é por ele
>    que a exclusão acontece e é por ele que a restauração acontece.

- [~] T005 (escrito, não aplicado) Migração: tabela `data_audit_log` — `actor` (`auth.uid()`), `created_at`, `table_name`, `action`, `record_id`, `clinic_id`, `previous_state jsonb`. RLS ligada: leitura só para admin da própria clínica e superadmin; escrita só pelo trigger.
- [~] T006 (escrito, não aplicado) Trigger `AFTER INSERT/UPDATE/DELETE` em `patients` gravando em `data_audit_log`, com o estado anterior completo em jsonb — é ele que permite reconstruir a linha.
- [~] T007 [P] (escrito, não aplicado) Migração: coluna `deleted_at timestamptz` em `patients`.
- [~] T008 (escrito, não aplicado) Ajustar as policies de `patients` para não vazar linha apagada: leituras filtram `deleted_at is null`, mantendo o isolamento por `clinic_id`.
- [ ] T009 Ajustar o app da plataforma: a exclusão de paciente vira `update ... set deleted_at = now()`, e todas as listas filtram. Pela **ponte inversa** (`docs/ponte/ponte-inversa.md`) — commit no repositório, e **não esquecer o Publish**.
- [ ] T010 [aceite] Apagar um paciente de teste deixa registro com **autor, hora e estado anterior**.
- [ ] T011 [aceite] O paciente some das listas, mas a linha existe com `deleted_at` preenchido.
- [ ] T012 [aceite] A reconstrução a partir de `previous_state` devolve os dados originais.
- [ ] T013 [aceite] Usuário de outra clínica **não lê** `data_audit_log` nem o paciente da primeira.

> **Escopo consciente:** esta fase cobre `patients`. Estender a auditoria a
> consultas, recebíveis e anamnese é backlog explícito, com a mesma mecânica.
> Não entra agora para não competir com o lançamento.

## Fase 3 — Backport para a stack nova

- [ ] T014 As mesmas correções como **migrações versionadas** em `supabase/migrations` deste repositório. Reescrever com nome e ordem daqui, registrando no commit de qual correção veio. Não copiar à mão da plataforma.
- [ ] T015 [P] O hook `guarda-constituicao` passa nas migrações novas.
- [ ] T016 [P] O agente `auditor-multitenant` revê o trigger e as policies novas, procurando furo na cascata.

## Na mesma janela, fora desta spec

- [x] T017 Remover o caminho que define senha de terceiro em `supabase/functions/invite-team-user` (`index.ts:47-51,66-75` aceita `password` do cliente) e acrescentar checagem de `my_permission('equipe')`. Viola a regra (e) da constituição e está **em produção**. Entra aqui porque é a mesma janela e o mesmo tipo de risco.
  - **Feito em 19/08/2026 na stack nova, antecipado** para não competir com a bateria de correções do Vinícius na janela de 22–23.
  - A função não aceita, não transporta e não gera senha: `generateLink({ type: "invite" })` cria o convidado e devolve o link; quem digita a senha é ele, em `/nova-senha`. Corpo com `password` agora é recusado com 400 — um front desatualizado falha alto em vez de ser ignorado em silêncio.
  - Autorização acrescentada: `my_permission('equipe') = 'full'`, avaliada pelo banco com a identidade do chamador.
  - **Por que o link volta na resposta e não vai por e-mail:** a entrega transacional não está de pé (`specs/001-fundacao-superadmin/research.md` R5 — o SMTP embutido comprovadamente não entrega) e o Resend só entra na SPEC 003. Até lá o admin repassa o link por fora. Quando o Resend entrar: trocar por `inviteUserByEmail` e parar de devolver `action_link`.
  - **Catraca:** o hook `guarda-constituicao` não pegava `admin.createUser({ password })` — foi por essa porta que a violação chegou à produção. Padrão acrescentado e testado contra a versão antiga (bloqueia) e a nova (passa).
  - **Produção fechada em 20/08/2026.** Commit `dabf1ef` pela ponte inversa, em 3 arquivos: a function, o `ConfigTeamDialog` (o campo "Senha provisória" era `type="text"` — senha em claro na tela; virou o link de primeiro acesso com botão de copiar) e o `ResetPassword.tsx`, que **só aceitava `type=recovery`** e chutaria o convidado para o `/login` sem ele nunca definir senha. Publish com crédito mensal 20 → 20.
  - **Furo do procedimento descoberto aqui:** o Publish **não** redeploya edge function, e o CLI do Supabase responde 403 no projeto gerenciado pela Lovable. Publicar o front antes de garantir a function deixou o convite quebrado por alguns minutos. Resolvido pedindo o deploy ao agente do editor (custo: 0,4 do crédito diário de build). Procedimento e ordem obrigatória agora registrados em `docs/ponte/ponte-inversa.md` — **ler antes da janela de 22–23**, que também mexe em function.
  - **Falta o aceite manual:** convidar um membro de verdade na plataforma, abrir o link gerado, definir senha e entrar. Enquanto isso não for feito, é código lido, não comportamento provado (Princípio IV).

## Pré-condição de lançamento

- [ ] T018 **Supabase Pro ligado antes de 01/09**, não no dia. Não é código, é a condição que dá backup diário para operar com dado de saúde real.

---

## Dependências

```
T004 (export) ──▶ T005 ──▶ T006 ──▶ T008 ──▶ T009 ──▶ T010..T013 (aceite)
                     └──▶ T007 [P] ──┘
T010..T013 ──▶ T014 ──▶ T015 [P] · T016 [P]

T001 ──▶ T002 (decisão) ──▶ T003 (só se aprovado)
T017 independente · T018 independente
```

**T004 é gate absoluto da Fase 2.** Nenhuma escrita antes do export.

## Gates de aceite manual

`T001` · `T010` · `T011` · `T012` · `T013` — executados por Arthur. A fase não
fecha sem eles: *implementado ≠ funciona*.

## Como isto se conecta ao lançamento

O critério 4 dos aceites da spec — exclusão deixa rastro — é o que separa
"temos LGPD no papel" de "temos LGPD verificável". Com cliente real entrando em
01/09 e dado de saúde em jogo, a pergunta *"quem apagou este paciente e
quando?"* precisa ter resposta. Hoje não tem: o próprio agente da plataforma
registrou isso em 02/08, ao ser testado e não conseguir responder.
