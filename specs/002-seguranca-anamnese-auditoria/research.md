# Research — decisões de design (SPEC 002)

Três decisões que o plano depende. Cada uma com o que foi escolhido, por quê, e
o que foi descartado.

## Decisão 1 — Como servir o formulário público sem `USING(true)`

**Escolhido:** token de uso único (`public_token`) + **Edge Function com service
role**. O paciente acessa `/anamnese-publica/:token`; a edge function valida o
token e devolve/grava só aquela linha. As policies `anon` na tabela são
**removidas** — nenhum acesso anônimo direto permanece.

**Por quê:** elimina a superfície inteira. Com a edge function como único caminho,
não há como um anônimo enumerar a tabela — o RLS volta a ser default deny para
`anon`, e a lógica de "só esta linha, só se pendente" vive num lugar auditável
com service role, não numa policy que precisa acertar o escopo.

**Descartado:**
- *Policy RLS escopada por header/parâmetro* (manter `anon` mas trocar
  `USING(true)` por `USING(id = current_setting(...))`). Rejeitado: continua
  expondo a tabela ao papel `anon`; qualquer erro futuro na policy reabre o furo.
  A edge function tira o `anon` da tabela de vez.
- *Só remover as policies* — quebraria o formulário público, que é legítimo.

## Decisão 2 — Profundidade da auditoria de `patients`

**Escolhido:** trigger `AFTER INSERT/UPDATE/DELETE` gravando o **estado anterior
completo** (linha inteira em jsonb) em `data_audit_log`, além de autor, hora,
ação e `clinic_id`.

**Por quê:** o TESTE 4 do Arthur mostrou que sem isso não há como responder "quem
apagou e o quê havia". Guardar a linha inteira anterior permite **reconstruir** o
paciente apagado — resolve o cenário forense e o de restauração num só mecanismo,
sem depender de PITR (que o tier atual não tem).

**Descartado:**
- *Só diff de campos alterados* — não reconstrói uma linha apagada por DELETE.
- *pgaudit / log do Postgres* — não está ativo, não captura DML bem-sucedido, e
  não amarra ao `auth.uid()` da aplicação.

## Decisão 3 — Exclusão destrutiva vs soft delete

**Escolhido:** **ambos** — soft delete (`deleted_at`) como comportamento padrão do
app, e o trigger de auditoria cobrindo também o DELETE real (caso ocorra por fora).

**Por quê:** soft delete torna a exclusão do dia a dia reversível e mantém o
histórico; o trigger no DELETE real é a rede de segurança para exclusão fora do
app. Dado de saúde não deve sumir sem rastro nem sem volta.

**Descartado:**
- *Só soft delete* — não protege contra DELETE direto no banco.
- *Só auditoria* — o dado ainda some da operação; recuperar exige ler o log.

## Nota transversal — dois bancos, uma correção

A correção nasce no banco Lovable (ao vivo, lança 01/09) e é **backportada** como
migração nesta stack. Não se copia SQL à mão entre os dois: reescreve-se com nome
e ordem deste repo, registrando a origem no commit. O `guarda-constituicao` valida
o backport; o `auditor-multitenant` revê a edge function e os triggers.
