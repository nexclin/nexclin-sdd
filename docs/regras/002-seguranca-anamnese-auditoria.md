# 002 · Segurança: anamnese pública e auditoria de dado de paciente

> **Regra viva.** Nasceu antes da execução, guiou a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 27/08/2026:** o Achado 1 está fechado na parte grave. A Fase 2
> está **escrita e não aplicada**: a migração existe no repositório e espera o
> ato do Arthur. Alvo primário: a plataforma Lovable ao vivo. Alvo secundário:
> as migrações deste repositório.
>
> **Lei:** `docs/constituicao.md` · **Critério:** `CLAUDE.md` §2.5 ·
> **Origem:** `../historico/2026-08-16-revisao-de-seguranca.md`, Achados 1 e 2. Convertida
> da SPEC 002 em 27/08/2026, formato de sete seções.

---

## 1. O problema

A revisão de segurança de 16/08 encontrou duas exposições de dado de saúde na
plataforma que recebe os primeiros clientes. A primeira era `anon ... USING(true)`
em `anamnesis_responses` e `anamnesis_config`: qualquer pessoa, só com a chave
anon pública, lia e adulterava anamnese de qualquer paciente de qualquer clínica.
A segunda é que ação sobre `patients` não deixa rastro nenhum, sem soft delete e
sem atribuição de quem fez o quê e quando, o que torna a pergunta *"quem apagou
este paciente?"* impossível de responder. Corrigir só a stack nova não protege o
cliente que entra em setembro, e é por isso que esta regra trata primeiro o que
está no ar.

## 2. Requisitos

**Anamnese pública**

- **FR-001**: Nenhuma policy `anon` **MUST** existir em tabela de anamnese. O
  acesso anônimo **MUST** passar por edge function com service role. *Porquê:*
  `USING(true)` não é escopo, é ausência de escopo. Com a function como único
  caminho, a RLS volta a ser default deny para `anon` e a lógica de "só esta
  linha, só se pendente" vive num lugar auditável. **Já cumprido:** zero policies
  `anon` em todo o schema, confirmado por consulta ao banco ao vivo.
- **FR-002**: A function **MUST NOT** devolver as respostas do paciente,
  `patient_id` nem `clinic_id`. Devolve `id`, `status` e a definição do
  formulário. *Porquê:* o formulário público precisa saber o que perguntar, não o
  que já foi respondido.
- **FR-003**: O envio **MUST** recusar com 409 quando `status = 'preenchido'`.
  *Porquê:* uso único. Link que continua servindo depois de enviado é link que
  sobrescreve resposta alheia.
- **FR-004**: A URL pública **SHOULD** carregar um `public_token` dedicado, nunca
  o `id` da linha. *Porquê:* um UUID v4 tem 122 bits e não se adivinha, então o
  risco não é adivinhação, é vazamento de link, por histórico, log de servidor,
  encaminhamento e `Referer`. A diferença é de desenho e é real: chave primária
  **não se rotaciona nem expira** sem mexer na identidade da linha; token
  dedicado se revoga sozinho. **`SHOULD` e não `MUST` porque a entrada disto
  antes de 08/09 é decisão em aberto (seção 7).**

**Auditoria e soft delete de `patients`**

- **FR-005**: `data_audit_log` **MUST** guardar quem (`auth.uid()`), quando, qual
  tabela, qual ação, qual linha, qual clínica, e o **estado anterior completo** em
  jsonb. *Porquê:* estado anterior completo é o que permite reconstruir a linha.
  Guardar só o campo alterado responde "mudou" e não responde "para o quê".
- **FR-006**: `data_audit_log` **MUST NOT** ter policy de INSERT, UPDATE nem
  DELETE. *Porquê:* com RLS ligada e nenhuma policy de escrita, toda escrita por
  sessão de usuário é negada, e quem grava é o trigger, que roda `SECURITY
  DEFINER` e não passa por RLS. É assim que "escrita só pelo trigger" vira
  garantia do banco em vez de confiança no código. A trilha fica imutável
  inclusive para o superadmin.
- **FR-007**: A leitura de `data_audit_log` **MUST** ser restrita a admin da
  própria clínica e ao superadmin. *Porquê:* a trilha contém o estado anterior de
  dado de saúde. Ela é tão sensível quanto a tabela que audita.
- **FR-008**: `patients` **MUST** ganhar `deleted_at timestamptz`, e a exclusão
  pelo app **MUST** virar `update ... set deleted_at = now()`. *Porquê:* dado de
  saúde apagado por engano não tem de onde voltar num tier sem PITR.
- **FR-009**: `DELETE` em `patients` **MUST NOT** ter policy. *Porquê:* negado por
  default deny. Se o DELETE continuasse disponível, o soft delete seria convenção
  opcional em vez de garantia.
- **FR-010**: A policy única `FOR ALL` de `patients` **MUST** ser separada por
  operação: o `SELECT` filtra `deleted_at is null`, o `UPDATE` **não** filtra.
  *Porquê:* é pelo UPDATE que a exclusão acontece, e é por ele que a restauração
  acontece. Filtrar nos dois tornaria o paciente apagado irrecuperável pela
  aplicação.
- **FR-011**: O trigger de auditoria **MUST** cobrir INSERT, UPDATE e DELETE.
  *Porquê:* auditar só a exclusão responde metade da pergunta. Alteração de valor
  em cadastro de paciente é a outra metade.

**Backport**

- **FR-012**: As mesmas correções **MUST** existir como migração versionada em
  `supabase/migrations` deste repositório, escritas **aqui primeiro** e levadas à
  plataforma pela ponte. *Porquê:* a constituição diz que `supabase/migrations` é
  a fonte de verdade do schema. Escrever aqui primeiro elimina o passo de
  transcrição, que é onde o erro entra.

## 3. O que muda no banco

| Objeto | Mudança |
|---|---|
| `anamnesis_responses` | remove as policies `anon` de SELECT e UPDATE. `public_token uuid not null default gen_random_uuid()` com índice único, **se a decisão da seção 7 aprovar** |
| `anamnesis_config` | remove a policy `anon` de SELECT |
| `data_audit_log` | **tabela nova.** `id`, `clinic_id`, `table_name`, `record_id`, `action`, `actor`, `previous_state jsonb`, `created_at`. RLS ligada, só policy de SELECT |
| `patients` | coluna `deleted_at timestamptz null`; policy `FOR ALL` separada por operação; sem policy de DELETE |
| `patients` | trigger `AFTER INSERT/UPDATE/DELETE` gravando em `data_audit_log` |

A migração está escrita:
`supabase/migrations/20260825060000_auditoria_de_dado_e_soft_delete_em_patients.sql`.
Ela cobre as quatro mudanças de uma vez.

**Como aplicar na plataforma:**
[`../ponte/aplicacao-002-fase2/`](../ponte/aplicacao-002-fase2/) traz cinco
blocos para colar um por vez no SQL editor, cada um com a consulta de conferência
e o resultado esperado. O bloco 4, que troca as policies de `patients`, tem
reversão palavra por palavra logo abaixo dele.

**Por que colado à mão, e não por automação:**
`../ponte/nota-sql-editor.md` provou que o SQL editor da
Lovable, dirigido por automação, executa uma consulta diferente da que está na
tela. Contra produção, isso é inaceitável.

## 4. Premissas

- **A parte grave do Achado 1 já está fechada.** A anamnese pública é servida
  pela edge function `anamnesis-public`, que valida formato UUID antes de
  consultar, devolve só a definição do formulário e recusa reenvio com 409.
  Ninguém lê resposta alheia. O que sobrou é a dívida de desenho do FR-004.
- **O export do banco é síncrono.** Correção do Arthur, de 25/08: ele **não** é
  assíncrono, **não** chega por e-mail e **não** tem limite de um a cada 24
  horas. É feito na hora, pela função de exportar dados, e pode ser repetido
  quando se quiser. O texto anterior estava errado, e o erro fazia esta fase
  inteira parecer travada por uma espera que não existe.
- **Na mesma tela do export ficam `Pause` e `Remove`.** Os dois em vermelho, num
  espaço de cerca de 200 pixels, e `Remove` apaga a instância em definitivo.
- **Este tier não tem PITR.** Sem export, um erro amplo é irreversível.
- **O escopo desta regra é `patients`, e só.** Estender a auditoria a consultas,
  recebíveis e anamnese é backlog explícito, com a mesma mecânica. Não entra
  agora para não competir com a trava.
- **Sob impersonação, o suporte grava indistinguível do cliente.** A auditoria
  registra a entrada e a saída da sessão de suporte, **não o que foi criado no
  meio**. Dívida herdada da regra 006, D-006.4, e é aqui que ela se resolve
  quando a auditoria passar de `patients`.

## 5. Dependências

- **Gate absoluto:** export do banco antes de qualquer escrita em produção. Feito
  em 25/08 (`nexclin_260825.backup.zip`, sha256 `b56d8d5f...`, registrado em
  `../ponte/registro-exports-banco.md`). **Falta a cópia em nuvem** exigida
  por aquele registro: enquanto ela não existir há **um** ponto de retorno, num
  disco só.
- **Procedimento da ponte** (`docs/ponte/ponte-inversa.md`) para qualquer
  alteração que chegue à plataforma. Ordem obrigatória: function antes do Publish
  do front.
- **A regra 005 depende desta**, no FR-013 dela: a auditoria de ação dentro da
  clínica precisa de `data_audit_log`.
- **Pré-condição de lançamento, e não é código:** Supabase Pro ligado **antes** de
  08/09, não no dia. É o que dá backup diário para operar com dado de saúde real.

## 6. Como se prova que funciona

Executado por Arthur, na plataforma ao vivo. O trabalho pendente vive em doze
issues, sob a milestone [Regra 002](https://github.com/nexclin/nexclin-sdd/milestone/2).

1. **Zero policy `anon` com `qual = true`** em qualquer tabela de anamnese, pela
   consulta a `pg_policies`.
2. **Requisição anônima direta** a `GET /rest/v1/anamnesis_responses?select=*`
   volta vazia ou negada.
3. **Formulário público ponta a ponta:** abrir o link de uma resposta pendente,
   preencher, enviar, e **tentar reabrir**. Deve recusar com "já enviado". Sem
   isto, o uso único é código lido, não comportamento provado.
4. **Auditoria no DELETE:** apagar um paciente de teste deixa linha em
   `data_audit_log` com autor, hora, ação e estado anterior.
5. **Soft delete:** o paciente some das listas, e a linha existe com `deleted_at`
   preenchido.
6. **Reconstrução:** a partir de `previous_state`, os dados originais voltam.
7. **Isolamento:** usuário de uma clínica não lê `data_audit_log` nem paciente da
   outra.
8. **Backport:** as mesmas correções existem como migração aqui, o hook
   `guarda-constituicao` passa nelas, e o agente `auditor-multitenant` revê o
   trigger e as policies novas sem achado alto.

## 7. A decisão que falta

**O `public_token` dedicado entra antes de 08/09, ou vira requisito da stack
nova?**

O que está em jogo está no FR-004: o risco não é adivinhação, é vazamento de
link. Entrada da decisão: a plataforma vive cerca de um mês, e a mudança toca
migração, edge function e front ao mesmo tempo, o que pela armadilha conhecida
exige a function antes do Publish. Saída: decisão registrada em
`docs/historico/`, com a data no nome do arquivo.

**Sem essa decisão, o trabalho do FR-004 não abre.** A decisão é a issue
[#37](https://github.com/nexclin/nexclin-sdd/issues/37); a implementação que
depende dela é a [#38](https://github.com/nexclin/nexclin-sdd/issues/38).
