---
description: "Lista de tarefas da frente 023, a mensagem interna (seção 8 da regra)"
---

# Tarefas: a mensagem interna

**Entrada:** [`plan.md`](./plan.md) e [`spec.md`](./spec.md), que é link para a
regra viva. **Só a seção 8 da regra está em execução aqui**; as seções 2 a 5
foram entregues antes do plano existir.

## Formato: `[ID] [P?] [Fase] Descrição com o caminho do arquivo`

- **[P]**: pode rodar em paralelo, arquivo diferente e sem dependência aberta.
- **[Fase]**: `[F0]` a `[F4]`, as fases do plano.

> **Aqui não há user story, e isso é de propósito.** A
> [ADR 0005](../../adr/0005-bifurcar-o-to-spec.md) removeu user story do formato
> deste projeto. O agrupamento é por **fase do plano**, que é o que tem aceite
> próprio pela alínea (h).

> **Issues abertas em 14/09/2026**, pelo `speckit-taskstoissues`, uma por tarefa, e
> transferidas no mesmo dia para `nexclin/nexclin`, onde o código muda,
> no milestone `023 · A mensagem interna`. O número entre parênteses depois do ID
> é a issue no GitHub.

> **O Portão 1 bloqueia aceite, não construção.** Conversa exige duas pessoas;
> sem a segunda, nenhuma prova da seção 8.6 fecha.

> **Teste vermelho antes do código** em `src/lib/conversas.ts`. A tarefa do
> teste vem antes da tarefa da função.

---

## Fase 0 · Conferir o banco antes de acreditar nele

**Objetivo:** três perguntas de uma ida só ao editor.

**Aceite:** o que voltar bate com a seção 8.3 e com a seção 2 da regra. Se
`task_comments` não estiver no banco, a seção 2 está errada ao dizer
"entregue", e isso se corrige antes de T207.

- [x] T201 (nexclin#4, fechada 14/09) [F0] Escrever o bloco de conferência em `docs/ponte/023-censo-mensagem-interna.sql`: `pg_policies` de `task_comments`, esperando as duas policies do bloco b1 (`SELECT` por clínica, `INSERT` com `author_id = auth.uid()`)
- [x] T202 (nexclin#5, fechada 14/09) [P] [F0] No mesmo arquivo, `pg_publication` e `pg_publication_tables` para `supabase_realtime`. Esperado: publicação existe e nenhuma tabela nossa está nela. Decide se T241 é `ALTER` ou `CREATE`
- [x] T203 (nexclin#6, fechada 14/09) [P] [F0] No mesmo arquivo, e **só se a Fase 0 da 024 ainda não rodou**: `team_members` com login e sem `user_id`, por clínica. Se a 024 já rodou, este trecho vira um comentário apontando para `docs/historico/2026-09-NN-censo-operacional.md`
- [x] T204 (nexclin#7, fechada 14/09) [F0] Rodar o bloco no editor de SQL da plataforma, um trecho por vez. O Arthur clica `Run`
- [x] T205 (nexclin#8, fechada 14/09) [F0] Registrar o resultado em `docs/historico/2026-09-NN-censo-mensagem-interna.md`, e corrigir a seção 2 ou a 8.3 da regra no mesmo commit se houver divergência

**Ponto de conferência:** `task_comments` confirmado no ar, publicação
conhecida, premissa do `user_id` com número.

---

## PORTÃO 1 · O segundo usuário · issue #50

**Bloqueia aceite, não construção.** A prova 1 (duas clínicas) exige, além
disso, uma segunda clínica com dois usuários. Se não houver, ela fecha pela
metade e o aceite diz isso em voz alta.

- [ ] T206 (nexclin#9) [F0] Conferir em `docs/historico/` se a issue #50 já foi fechada pela frente 024 (T307 de lá). Se não, cobrar do Arthur e registrar em que dia passou a existir, com e-mail de login e `team_members.id` de cada pessoa. **Sem senha no arquivo**

---

## Fase 1 · A tabela e a policy por participante · faixa A · Lovable e stack nova

**Objetivo:** FR-007, FR-009, FR-010, FR-013 e FR-014 na parte de banco. É a
fase que atravessa intacta para outubro, e a única em que um erro custa caro.

**Aceite independente:** provas 2 e 3 no editor, **com controle positivo em
cada uma**. Só a metade negativa passa por vacuidade.

### A migração, bloco a bloco

- [x] T207 (nexclin#10, fechada 14/09) [F1] Escrever `supabase/migrations/20260913020000_mensagem_interna.sql`, bloco 1: `CREATE TABLE public.internal_messages` coluna a coluna como a seção 8.3 da regra: `id`, `clinic_id uuid NOT NULL REFERENCES clinics(id)`, `sender_id uuid NOT NULL DEFAULT auth.uid()`, `recipient_id uuid NOT NULL`, `body text NOT NULL CHECK (btrim(body) <> '')`, `ref_type text CHECK (ref_type IN ('task','appointment','lead','patient'))` nulo, `ref_id uuid` nulo **sem chave estrangeira**, `created_at timestamptz NOT NULL DEFAULT now()`, `read_at timestamptz` nulo. `COMMENT` em `ref_id` dizendo por que não há FK
- [x] T208 (nexclin#11, fechada 14/09) [P] [F1] No mesmo arquivo, bloco 2: os dois índices, `(clinic_id, recipient_id, read_at)` e `(clinic_id, sender_id, recipient_id, created_at)`
- [x] T209 (nexclin#12, fechada 14/09) [F1] No mesmo arquivo, bloco 3: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` e a policy de `SELECT`: `clinic_id` da âncora **e** (`sender_id = auth.uid()` ou `recipient_id = auth.uid()`)
- [x] T210 (nexclin#13, fechada 14/09) [F1] No mesmo arquivo, bloco 4: a policy de `INSERT`, `WITH CHECK`: `sender_id = auth.uid()`, `clinic_id` da âncora, `recipient_id <> sender_id`, e `recipient_id` que exista em `team_members` da mesma clínica com `active = true` e `user_id IS NOT NULL`, comparando `team_members.user_id` com `recipient_id`
- [x] T211 (nexclin#14, fechada 14/09) [F1] No mesmo arquivo, bloco 5: a policy de `UPDATE`, `USING` e `WITH CHECK` com `recipient_id = auth.uid()` e `clinic_id` da âncora. **Nenhuma policy de `DELETE`**
- [x] T212 (nexclin#15, fechada 14/09) [F1] No mesmo arquivo, bloco 6: função e trigger `BEFORE UPDATE` `internal_messages_so_read_at` que levanta exceção se `NEW` difere de `OLD` em qualquer coluna além de `read_at`, e se `OLD.read_at IS NOT NULL` (lida não volta a não lida). Policy não vê `OLD`; só o trigger vê
- [x] T213 (nexclin#16, fechada 14/09) [P] [F1] Escrever `supabase/migrations/20260907000000_task_comments.sql` copiando `docs/ponte/aplicacao-023/b1-comentario-na-tarefa.sql`, com `IF NOT EXISTS` em tudo, e `COMMENT` na tabela dizendo que foi aplicada por bloco em 07/09 e que a migração existe para a stack nova herdar. **Não roda de novo no banco ao vivo**
- [x] T214 (nexclin#17, fechada 14/09) [F1] Escrever a reversão, bloco a bloco, em comentário abaixo de cada um. `DROP TABLE internal_messages` só se estiver vazia; senão, a reversão é desligar as policies e parar a tela
- [x] T215 (nexclin#18, fechada 14/09) [F1] Copiar a migração de T207 a T212 para `docs/ponte/aplicacao-023/b5-mensagem-interna.sql`, na forma de b1 a b4, com a conferência de cada bloco
- [x] T216 (nexclin#19, fechada 14/09) [P] [F1] Rodar o hook `.claude/hooks/guarda-constituicao.mjs` sobre as duas migrações: sem RLS ausente, sem `USING(true)`, sem caminho que define senha, sem segredo versionado
- [x] T217 (nexclin#20, fechada 14/09) [F1] Rodar o agente `auditor-multitenant` sobre `b5`, **tentando furar e não só lendo**: ler mensagem de terceiro da mesma clínica; inserir com `sender_id` de outro; mudar `body` por `UPDATE`; enviar para membro sem `user_id`; enviar para membro de outra clínica; enviar para si mesmo
- [x] T218 (nexclin#21, fechada 14/09) [F1] Achado de nível alto do auditor vira correção em `b5` antes de aplicar, e a seção 8.3 da regra se corrige no mesmo commit se a forma da policy mudou
- [x] T219 (nexclin#22, fechada 15/09) [F1] Conferir que o export do banco está feito e com cópia em nuvem, por `docs/seguranca/registro-exports-banco.md`, antes de aplicar
- [x] T220 (nexclin#23, fechada 15/09) [F1] Aplicar `b5` no editor de SQL e conferir cada bloco. O Arthur clica `Run`

### Aceite, e é onde a fase fecha

- [ ] T221 (nexclin#24) [F1] **Prova 2** no editor, em `BEGIN` e `ROLLBACK` com `SET LOCAL ROLE authenticated` e `request.jwt.claims` de Maria: `INSERT` com `sender_id` do médico é recusado. **Controle positivo no mesmo bloco:** o mesmo `INSERT` com `sender_id` de Maria passa
- [ ] T222 (nexclin#25) [F1] **Prova 3** no editor, como Maria: `INSERT` para um `team_members` sem `user_id` é recusado. **Controle positivo:** o mesmo `INSERT` para o médico, com `user_id`, passa
- [ ] T223 (nexclin#26) [F1] No mesmo bloco, como o médico: `SELECT` devolve a mensagem de Maria para ele; como um terceiro membro da clínica, o mesmo `SELECT` devolve zero linha. `UPDATE` de `body` como o médico levanta a exceção do trigger; `UPDATE` de `read_at` passa
- [ ] T224 (nexclin#27) [F1] Item que não deu para provar fecha como **"código lido, não comportamento provado"** e continua aberto

**Ponto de conferência:** a mensagem existe no banco, e só quem a escreveu ou
recebeu a lê, provado com as duas metades.

---

## Fase 2 · A conversa na tela · faixa A e C · Lovable

**Objetivo:** FR-008, FR-010 na tela, FR-011, FR-012, FR-013 na tela.

**Aceite independente:** provas 1, 4 e 5 da seção 8.6, na tela, com Maria e o
médico logados.

> Toda tarefa em `../nexclin-lovable/` segue `docs/ponte/ponte-inversa.md`:
> `git pull` antes, `main`, nunca `--force`, `npx tsc --noEmit -p tsconfig.app.json`,
> **nunca `npx vite build`**, commit com caminho explícito e push no mesmo
> comando.

### A função, com o teste na frente

- [x] T225 (nexclin#28, fechada 14/09) [F2] Escrever `../nexclin-lovable/src/lib/__tests__/conversas.test.ts` para `destinatarios(membros, eu)`: ativo, com `user_id`, menos eu; membro inativo fora; membro sem `user_id` fora. **Ver falhar**
- [x] T226 (nexclin#29, fechada 14/09) [P] [F2] No mesmo arquivo, `agruparEmConversas(mensagens, eu)`: uma conversa por par, ordenada pela mensagem mais recente, com a outra pessoa nomeada; e `naoLidas(mensagens, eu)`: conta só onde `recipient_id` é eu e `read_at` é nulo, por conversa e no total. **Ver falhar**
- [x] T227 (nexclin#30, fechada 14/09) [P] [F2] No mesmo arquivo, `cartaoDaReferencia(ref_type, ref_id, item)`: rótulo e rota para `task`, `appointment`, `lead` e `patient`; item ausente devolve cartão "item não encontrado" e **não** quebra. **Ver falhar**
- [x] T228 (nexclin#31, fechada 14/09) [F2] Escrever `../nexclin-lovable/src/lib/conversas.ts` até T225, T226 e T227 passarem. `npx vitest run` inteiro verde

### A tela

- [x] T229 (nexclin#32, fechada 15/09) [F2] Criar `../nexclin-lovable/src/components/layout/NxConversas.tsx` sobre `src/components/ui/sheet.tsx`: lista de conversas com contagem, conversa aberta, campo de envio (`INSERT` sem `sender_id`, que o `DEFAULT auth.uid()` preenche), cartão da referência quando houver. Abrir a conversa faz `UPDATE read_at = now()` nas mensagens em que sou destinatário e `read_at` é nulo, e é o único `UPDATE` do componente
- [x] T230 (nexclin#33, fechada 15/09) [F2] Em `../nexclin-lovable/src/components/layout/NxTopHeader.tsx`: o balão ao lado de `NxSino`, com a contagem total de `naoLidas`, abrindo `NxConversas`
- [x] T231 (nexclin#34, fechada 15/09) [P] [F2] Em `../nexclin-lovable/src/components/layout/NxSino.tsx`: a contagem de não lidas entra como linha do sino, com o comentário de que é a única contagem que vem de tabela própria (seção 8.4 da regra)
- [x] T232 (nexclin#35, fechada 15/09) [F2] Em `../nexclin-lovable/src/pages/Tarefas.tsx`: a foto (ou o nome) do responsável abre `NxConversas` na conversa com aquela pessoa, com `ref_type = 'task'` e `ref_id` da tarefa preenchidos. Sem botão para membro sem login
- [x] T233 (nexclin#36, fechada 15/09) [P] [F2] O mesmo em `../nexclin-lovable/src/pages/Acompanhamento.tsx` (`ref_type = 'appointment'`) e em `../nexclin-lovable/src/pages/Atendimentos.tsx` (`ref_type = 'lead'`). **O padrão que se repetiu cinco vezes nesta base é conserto aplicado a uma tela e não às irmãs**
- [x] T234 (nexclin#37, fechada 15/09) [F2] Conferir em `../nexclin-lovable/src/lib/__tests__/rotas.test.ts` e em `App.tsx` que a caixa **não** entrou como rota protegida por `RequirePermission`, e que nada em `usePermissions.ts`, `plans` ou `ConfigTeamDialog.tsx` a menciona. FR-013
- [ ] T235 (nexclin#38) [F2] Gate de tipos, `npx tsc --noEmit -p tsconfig.app.json`, `npx vitest run` verde, e publicar pela ponte com `scripts/ponte.sh conferir` e o marcador no bundle

### Aceite, e é onde a fase fecha

- [ ] T236 (nexclin#39) [F2] **Prova 1**, na tela: Maria manda mensagem ao médico; ele vê; um terceiro membro da clínica não vê. Se houver segunda clínica com dois usuários, uma mensagem lá, e nenhuma clínica lê a da outra; se não houver, o aceite escreve "prova 1 pela metade: só dentro da clínica"
- [ ] T237 (nexclin#40) [F2] **Prova 4**, na tela: o médico abre a conversa; no editor, `read_at` gravou; o balão dele zera; o de Maria não muda
- [ ] T238 (nexclin#41) [F2] **Prova 5**, na tela: mensagem com referência a uma tarefa mostra o cartão e o cartão leva à tarefa; cancelar a tarefa (não se apaga, regra 024 FR-009) mantém a mensagem e o cartão
- [ ] T239 (nexclin#42) [F2] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto
- [ ] T240 (nexclin#43) [F2] Avisar a frente 024: a T363 de `docs/planos/024-perfil-operacional/tasks.md` passa a responder "entregue", e o bloco 4 do painel (T367 de lá) pode entrar. **Este plano avisa; não executa a 024**

**Ponto de conferência:** a conversa sai do WhatsApp e volta para dentro do
sistema, com o item anexado.

---

## Fase 3 · Tempo real · faixa C · Lovable

**Objetivo:** FR-015. É a primeira assinatura de Realtime da plataforma.

**Aceite independente:** prova 6, duas abas, **com controle negativo** numa
terceira.

- [ ] T241 (nexclin#44) [F3] Escrever `supabase/migrations/20260913030000_realtime_mensagem_interna.sql`: `ALTER PUBLICATION supabase_realtime ADD TABLE public.internal_messages`, ou `CREATE PUBLICATION` se T202 mostrou que não existe. Copiar para `docs/ponte/aplicacao-023/b6-realtime.sql`
- [ ] T242 (nexclin#45) [F3] Aplicar `b6` no editor. O Arthur clica `Run`
- [ ] T243 (nexclin#46) [F3] Em `../nexclin-lovable/src/components/layout/NxConversas.tsx`: assinar `postgres_changes` em `internal_messages` enquanto o painel está aberto, e cancelar a assinatura ao fechar. Sem assinatura com o painel fechado; o balão continua lendo por consulta
- [ ] T244 (nexclin#47) [F3] Gate de tipos e `npx vitest run` verde, e publicar pela ponte

### Aceite, e é onde a fase fecha

- [ ] T245 (nexclin#48) [F3] **Prova 6**: duas abas, Maria e o médico; a resposta aparece sem recarregar. **Controle negativo:** uma terceira aba, logada como um terceiro membro da clínica, com o painel aberto, **não** recebe o evento. É a policy da F1 valendo na assinatura, provada e não assumida
- [ ] T246 (nexclin#49) [F3] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto

**Ponto de conferência:** a pessoa não recarrega a tela para ver a resposta.

---

## Fase 4 · Fechamento

- [ ] T247 (nexclin#50) [P] [F4] Atualizar a seção 2 de `docs/regras/023-avisos-e-recados-da-equipe.md` com o que está no ar da seção 8, e a seção 5 com a linha de `internal_messages` e a nota de que a migração de `task_comments` passou a existir em T213
- [ ] T248 (nexclin#51) [P] [F4] Atualizar a linha da 023 em `docs/regras/README.md` com o estado real
- [ ] T249 (nexclin#52) [P] [F4] Rodar `/speckit-analyze` sobre regra, plano e tarefas, e resolver a inconsistência que ele apontar
- [ ] T250 (nexclin#53) [F4] Escrever o handoff do dia em `docs/historico/`, com o que ficou aberto dito em voz alta

---

## Dependências e ordem

### Entre fases

- **F0** não depende de nada e **bloqueia F1**.
- **PORTÃO 1** depende de gente. **Bloqueia todo aceite** de F1 em diante, e
  nenhuma construção.
- **F1** depende de F0. O auditor (T217) roda **antes** de aplicar (T220), e
  não depois.
- **F2** depende de F1 aplicada (T220). Tela que grava em tabela inexistente
  quebra o header inteiro, e o header está em toda página.
- **F3** depende de F2 e de T202.
- **F4** depende de tudo que tiver sido feito.

### Com a frente 024

- A 024 **lê** esta: T363 e T367 de lá esperam T240 daqui.
- Esta **não lê** a 024, com uma exceção de conveniência: T203 reaproveita o
  censo de `user_id` se a 024 já o rodou.
- As duas publicam na mesma plataforma, e ela tem **um Publish só**. Uma fase
  de uma frente publica e fecha aceite antes de a outra subir. Antes de tentar
  as duas na mesma janela, ler `nx-paralelo`.

### Dentro de cada fase

- Migração antes de front. **Sempre.**
- Reversão escrita antes de aplicar bloco em produção.
- Auditor antes de aplicar policy nova, e não depois.
- Teste antes do código, e visto falhar, em `conversas.ts`.
- Aceite na tela antes de fechar a fase, com duas pessoas logadas, e print.

### O que roda em paralelo

- T202 e T203 são consultas diferentes no mesmo arquivo. **Rodam em série no
  editor.**
- T208 é bloco distinto de T207; T213 é arquivo distinto.
- T216 não depende de T217.
- T225, T226 e T227 são funções diferentes no mesmo arquivo de teste.
- T231 é `NxSino.tsx`; T230 é `NxTopHeader.tsx`.
- T233 são duas telas que não tocam `Tarefas.tsx`.
- T247, T248 e T249 não se tocam.

---

## Estratégia de entrega

### A primeira entrega que tira a conversa do WhatsApp

**F0, F1 e F2.** Quarenta tarefas, oito delas de aceite. É o recorte em que
Maria e o médico conversam dentro do sistema com o item anexado, ainda
recarregando a tela para ver a resposta.

1. F0 inteira. **Se `task_comments` não estiver no ar, a seção 2 da regra se
   corrige antes de custar trabalho.**
2. Portão 1, que é uma pessoa a mais e não uma implementação.
3. F1 inteira, com o auditor antes de aplicar e as duas provas com as duas
   metades.
4. F2 inteira, com as três provas na tela.
5. **PARAR e validar.** Aceite do Arthur, e a validação pela ótica de Maria.
6. Avisar a 024 (T240).

### Depois

F3 sozinha, quando a conversa já estiver em uso. Se ninguém reclamar de
recarregar, ela pode esperar; se reclamarem, é a prova de que a caixa pegou.

---

## Notas

- `[P]` quer dizer arquivo diferente e sem dependência aberta.
- Commit por tarefa ou por grupo lógico, com caminho explícito e push no mesmo
  comando. `git add -A` é proibido e um hook bloqueia.
- Mudança de comportamento **corrige a regra no mesmo commit**, alínea (l).
- Parar em qualquer ponto de conferência é legítimo. Atravessar portão não é.
