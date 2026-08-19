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
- [ ] T005 Migração: tabela `data_audit_log` — `actor` (`auth.uid()`), `created_at`, `table_name`, `action`, `record_id`, `clinic_id`, `previous_state jsonb`. RLS ligada: leitura só para admin da própria clínica e superadmin; escrita só pelo trigger.
- [ ] T006 Trigger `AFTER INSERT/UPDATE/DELETE` em `patients` gravando em `data_audit_log`, com o estado anterior completo em jsonb — é ele que permite reconstruir a linha.
- [ ] T007 [P] Migração: coluna `deleted_at timestamptz` em `patients`.
- [ ] T008 Ajustar as policies de `patients` para não vazar linha apagada: leituras filtram `deleted_at is null`, mantendo o isolamento por `clinic_id`.
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

- [ ] T017 Remover o caminho que define senha de terceiro em `supabase/functions/invite-team-user` (`index.ts:47-51,66-75` aceita `password` do cliente) e acrescentar checagem de `my_permission('equipe')`. Viola a regra (e) da constituição e está **em produção**. Entra aqui porque é a mesma janela e o mesmo tipo de risco.

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
