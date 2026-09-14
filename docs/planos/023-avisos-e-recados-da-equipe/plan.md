# Plano de implementação: a mensagem interna

**Frente:** `023-avisos-e-recados-da-equipe` · **Data:** 13/09/2026
**Regra:** [`spec.md`](./spec.md), que é link para
[`docs/regras/023-avisos-e-recados-da-equipe.md`](../../regras/023-avisos-e-recados-da-equipe.md)

> Gerado por `speckit-plan` sob a [ADR 0006](../../adr/0006-o-spec-kit-volta-pela-metade.md).
> **Este plano cobre só a seção 8 da regra.** As seções 2 a 5 estão entregues:
> o sino (FR-001 a FR-003) e o comentário na tarefa (FR-005, `task_comments`,
> bloco `docs/ponte/aplicacao-023/b1`). O FR-006 se dissolveu em 12/09: a caixa
> não é módulo, e não há emenda à alínea (f). O que falta é a caixa em si,
> FR-007 a FR-015, e a seção 8.7 não deixa decisão aberta.

---

## 1. Resumo

Nove requisitos, seis deles **faixa A**, sobre uma conversa curta entre duas
pessoas da mesma clínica, com o item de que se fala anexado. O que muda de
verdade é **uma tabela**, `internal_messages`, e a policy dela é diferente de
todas as 79 que o banco tem: é **por participante**, não por módulo. Quem lê
uma mensagem é quem a escreveu ou quem a recebeu, e mais ninguém da clínica.
Por isso a ordem do plano é banco primeiro, com o auditor tentando furar a
policy antes de qualquer tela, porque mensagem carrega nome de paciente e
vazamento entre pessoas da mesma clínica é tão grave quanto entre clínicas.

**Sobe para a Lovable inteiro**, pela exceção nomeada no Princípio IV da
constituição 2.1.0, como a 024 e a 025. A mecânica da ponte não muda.

**Uma coisa esta frente entrega para outra:** o bloco 4 do painel operacional
(regra 024, FR-014) e o botão "falar com" na tarefa e na consulta leem a caixa
daqui. A tarefa T063 da 024 confere se esta frente entregou.

---

## 2. Contexto técnico

| | |
|---|---|
| **Banco** | PostgreSQL no Supabase, dois projetos: o da plataforma Lovable, ao vivo, e o da stack nova |
| **Onde se testa banco** | editor de SQL contra o banco ao vivo, com migração autorizada. Sem Docker e sem banco local |
| **Front da Lovable** | React e Vite, clone em `../nexclin-lovable`. Gate de tipos: `npx tsc --noEmit -p tsconfig.app.json`. **Nunca `npx vite build`** |
| **Tempo real** | Supabase Realtime, pela publicação `supabase_realtime`. **Nenhuma tabela está publicada hoje**: não há `supabase_realtime` em migração nenhuma dos dois repositórios. A Fase 0 confere se a publicação existe no banco |
| **Testes** | Vitest, 20 arquivos em `src/lib/__tests__/` na plataforma. Teste vermelho antes do código |
| **Caminho até o cliente** | ponte inversa, `docs/ponte/ponte-inversa.md`. O Arthur publica; o agente não |
| **Alvo de prazo** | nenhum fixado. A 024 depende desta para o bloco 4 do painel, e já decidiu que nasce sem ele se esta não chegar antes |
| **Régua de qualidade** | 200%: construído e testado, **mais** validado pela ótica de quem opera. Quem valida é a Maria de `maria@lancamento.com` e o médico da mesma clínica, com print |

**Fatos conferidos no código em 13/09:**

1. `task_comments` existe no código da Lovable (`NxSino.tsx`, `Tarefas.tsx`,
   `types.ts`) e o bloco que o criou está em
   `docs/ponte/aplicacao-023/b1-comentario-na-tarefa.sql`, com duas policies:
   `SELECT` por clínica e `INSERT` com `author_id = auth.uid()`. **A migração
   correspondente não está em `supabase/migrations/` de nenhum dos dois
   repositórios.** A Fase 0 confere se a tabela está no banco ao vivo, e a
   Fase 1 traz o bloco para migração, para que a stack nova a herde.
2. O sino é `src/components/layout/NxSino.tsx`, montado em `NxTopHeader.tsx`.
   O balão do FR-011 entra ao lado dele, no mesmo header.
3. `src/components/ui/sheet.tsx` existe. O painel lateral do FR-011 é um
   `Sheet`, e não uma página nem uma rota.
4. `useResponsaveis` (`src/hooks/useResponsaveis.ts`) já entrega a lista de
   membros com nome e `user_id`; `profiles.avatar_url` existe desde a migração
   de 27/08. A lista de destinatários do FR-007 é essa lista filtrada.
5. Nenhum uso de `channel(` ou de Realtime no `src/` da Lovable. O FR-015 é a
   primeira assinatura de tempo real da plataforma, e é por isso que ele é a
   última fase.

**A PRECISAR DE ESCLARECIMENTO: nenhuma na regra.** As duas dependências de
fora viram portões na seção 5.

---

## 3. Portão constitucional

Conferido contra `docs/constituicao.md` v2.1.0, pelo ponteiro em
`.specify/memory/constitution.md`.

| Alínea | O que exige | Situação neste plano |
|---|---|---|
| **(a)** | RLS em toda tabela com `clinic_id` | `internal_messages` nasce com `clinic_id NOT NULL` e RLS ligado no mesmo bloco. **Passa** |
| **(b)** | default deny | quatro policies, `SELECT`, `INSERT`, `UPDATE`, e **nenhuma `DELETE`**. Nenhum `USING(true)`. **Passa** |
| **(c)** | segurança no banco, tela só reflete | **passa, e é o ponto forte desta frente**: quem lê e quem escreve é decidido pela policy por participante, e a tela só mostra o que a policy devolve. A lista de destinatários da tela é conveniência; a recusa real é o `WITH CHECK` do `INSERT` |
| **(d)** | auditoria de ação administrativa | não há ação administrativa: mensagem não se edita nem se apaga (FR-009), e a única escrita depois do `INSERT` é `read_at`, pelo destinatário. **Passa** |
| **(f)** | as 15 ModuleKeys, módulo novo exige emenda | **passa pela leitura fechada em 12/09** (seção 7 da regra): a caixa não é módulo, é infraestrutura de todo membro com login, como o sino e o perfil. Não entra em `plans` nem em `team_members.permissions`. Se alguém a ler como módulo, a emenda vem antes do código, e este plano para |
| **(g)** | nenhuma credencial versionada | nada de credencial. **Passa** |
| **(h)** | regra viva aprovada, e parada humana por fase | a seção 8 existe e a 8.7 está fechada. **Cada fase abaixo para para aceite** |
| **(j)** | implementado ≠ funciona | sete provas na seção 8.6, seis na tela ou no editor. Onde não der, "código lido, não comportamento provado" |
| **(l)** | mudança de comportamento corrige a regra no mesmo commit | `spec.md` é link. O fato 1 da seção 2 (a migração de `task_comments` não existe) entra na seção 5 da regra no commit da Fase 1 |
| **LGPD** | requisito de arquitetura | mensagem carrega nome de paciente. Leitura só por participante, ninguém apaga, eliminação pelo caminho da regra 019. **Passa por construção** |
| **Princípio IV** | o que sobe para a Lovable | pela exceção nomeada de 12/09. **Passa** |

**Nenhuma violação é introduzida, e nenhuma é herdada.** É a primeira frente
deste lote em que a alínea (c) passa sem ressalva.

---

## 4. Estrutura

### Desta frente

```text
docs/planos/023-avisos-e-recados-da-equipe/
├── spec.md   → link para ../../regras/023-avisos-e-recados-da-equipe.md
├── plan.md   este arquivo
└── tasks.md  gerado por /speckit-tasks
```

**Quatro artefatos que o Spec Kit geraria e este plano NÃO gera**, pelo motivo
da 021 e da 024: cada um já mora na regra, e a alínea (l) existe para impedir a
segunda cópia.

| O que o Spec Kit geraria | Onde isso já mora |
|---|---|
| `research.md` | seção 8.4 da regra, e os cinco fatos da seção 2 acima |
| `data-model.md` | **seção 8.3 da regra**, a tabela `internal_messages` coluna a coluna |
| `quickstart.md` | seção 8.6 da regra, as sete provas |
| `contracts/` | não se aplica: `conversas.ts` é contrato interno, e o teste é o contrato |

### Do código

```text
supabase/migrations/                          a migração de internal_messages, e a de task_comments que faltava
docs/ponte/aplicacao-023/b5-mensagem-interna.sql   o bloco para colar, na sequência de b1 a b4
../nexclin-lovable/src/lib/conversas.ts       destinatários, agrupar, contar, cartão
../nexclin-lovable/src/lib/__tests__/conversas.test.ts
../nexclin-lovable/src/components/layout/NxTopHeader.tsx   o balão ao lado do sino
../nexclin-lovable/src/components/layout/NxSino.tsx        a contagem de não lidas entra no sino
../nexclin-lovable/src/components/layout/NxConversas.tsx   o painel lateral, novo
../nexclin-lovable/src/components/ui/sheet.tsx             já existe
../nexclin-lovable/src/hooks/useResponsaveis.ts            a lista de membros
../nexclin-lovable/src/pages/Tarefas.tsx                   a foto abre conversa
../nexclin-lovable/src/pages/Acompanhamento.tsx            a foto abre conversa
../nexclin-lovable/src/pages/Atendimentos.tsx              a foto abre conversa
```

---

## 5. As fases, e os portões

**Cada fase termina com aceite manual do Arthur**, alínea (h). Fase que não passa
no aceite não libera a seguinte. Toda fase que toca o clone segue a ponte.

### Fase 0 · Conferir o banco antes de acreditar nele

**Não implementa nada.** Um bloco de SQL em `docs/ponte/`, que responde três
perguntas de uma ida só:

1. `task_comments` está no banco ao vivo, com as duas policies do bloco b1?
   `pg_policies`. Se não está, a seção 2 da regra está errada ao dizer
   "entregue", e isso se corrige antes de tudo.
2. A publicação `supabase_realtime` existe, e com quais tabelas?
   `pg_publication` e `pg_publication_tables`. Decide se a Fase 3 cria a
   publicação ou só acrescenta a tabela.
3. `team_members` com login e sem `user_id`, por clínica. É a premissa da
   seção 8.4, e é a **mesma pergunta 1 da Fase 0 da 024**: se aquela já rodou,
   o número serve aqui, e o bloco não a repete.

**Aceite:** o que voltar bate com a seção 8.3 e com a seção 2 da regra.

### Portão 1 · O segundo usuário · issue #50

**Bloqueia aceite, não construção.** Conversa exige duas pessoas. A prova 1
(duas clínicas) exige, além disso, uma segunda clínica com dois usuários; se
não houver, a prova 1 fecha pela metade e o aceite diz isso.

### Fase 1 · A tabela e a policy por participante · faixa A · Lovable e stack nova

FR-007, FR-009, FR-010, FR-013, FR-014 na parte de banco. É a fase que atravessa
intacta para outubro, e a única em que um erro custa caro.

Uma migração neste repositório, e o bloco `b5` em `docs/ponte/aplicacao-023/`:

1. `internal_messages`, coluna a coluna como a seção 8.3: `clinic_id NOT NULL`,
   `sender_id uuid NOT NULL DEFAULT auth.uid()`, `recipient_id uuid NOT NULL`,
   `body text` com `CHECK (btrim(body) <> '')`, `ref_type` com `CHECK` em
   (`task`, `appointment`, `lead`, `patient`) ou nulo, `ref_id uuid` nulo **sem
   chave estrangeira**, `created_at`, `read_at` nulo.
2. Os dois índices: `(clinic_id, recipient_id, read_at)` para a contagem, e
   `(clinic_id, sender_id, recipient_id, created_at)` para a conversa.
3. RLS ligado. `SELECT`: participante, na própria clínica. `INSERT`:
   `sender_id = auth.uid()`, `clinic_id` da âncora, e `recipient_id` que exista
   em `team_members` **ativo, com `user_id`, da mesma clínica**, e diferente
   do remetente. `UPDATE`: só o `recipient_id`, e o `WITH CHECK` garante que
   nada além de `read_at` muda, comparando as demais colunas com as antigas por
   trigger `BEFORE UPDATE` que rejeita qualquer outra diferença. **Sem
   `DELETE`.**
4. A migração de `task_comments`, copiada do bloco b1, entra em
   `supabase/migrations/` com a data de quando foi aplicada, para que a stack
   nova a herde. Não roda de novo no banco ao vivo: é `IF NOT EXISTS`.

**Ir junto, antes de aplicar:** o agente `auditor-multitenant`, com a pergunta
certa: a policy por participante é nova nesta base. Ele tenta ler mensagem de
terceiro da mesma clínica, inserir com `sender_id` de outro, mudar `body` por
`UPDATE`, e enviar para membro sem login.

**Aceite:** provas 2 e 3 no editor, em `BEGIN` e `ROLLBACK` com
`SET LOCAL ROLE authenticated`, **com controle positivo em cada uma**: o
`INSERT` recusado com `sender_id` de outro e o mesmo `INSERT` aceito com o
próprio; o envio recusado para membro sem login e o mesmo envio aceito para
membro com login.

### Fase 2 · A conversa na tela · faixa A e C · Lovable

FR-008, FR-010 na tela, FR-011, FR-012, FR-013 na tela.

1. `src/lib/conversas.ts`, com teste vermelho antes: `destinatarios(membros,
   eu)` (ativo, com `user_id`, menos eu), `agruparEmConversas(mensagens, eu)`
   (por par de pessoas, ordenado pela última), `naoLidas(mensagens, eu)` (por
   conversa e no total, só onde sou destinatário e `read_at` é nulo), e
   `cartaoDaReferencia(ref_type, ref_id, item)` (o rótulo e a rota do item).
2. `NxConversas.tsx`, o painel lateral em `Sheet`: lista de conversas com a
   contagem, a conversa aberta, o campo de envio, e o cartão da referência
   quando houver. Abrir a conversa grava `read_at` nas mensagens em que sou
   destinatário: é o FR-010, e é o único `UPDATE` que a tela faz.
3. `NxTopHeader.tsx`: o balão ao lado do sino, com a contagem total.
   `NxSino.tsx`: a contagem de não lidas entra como linha do sino, e é a única
   contagem do sino que vem de tabela própria, como a seção 8.4 explica.
4. A foto do membro em `Tarefas.tsx`, `Acompanhamento.tsx` e
   `Atendimentos.tsx` abre `NxConversas` já na conversa com aquela pessoa, com
   a referência ao item preenchida. Onde a foto ainda não aparece, entra o nome
   com o mesmo clique.
5. **Nada de ModuleKey, `plans` ou `permissions`**: o balão aparece para todo
   membro com login. O teste de `rotas.test.ts` que já existe é conferido para
   garantir que a caixa não entrou como rota protegida por módulo.

**Aceite:** provas 1, 4 e 5 da seção 8.6, na tela, com Maria e o médico.

### Portão 2 · A regra 024 precisa desta

Não é portão desta frente; é o inverso. Quando a Fase 2 fechar, a tarefa T063
da 024 muda de resposta, e o bloco 4 do painel operacional (T067 da 024) pode
entrar. **Este plano avisa; não executa a 024.**

### Fase 3 · Tempo real · faixa C · Lovable

FR-015. Por último porque é a primeira assinatura de Realtime da plataforma, e
porque a conversa já funciona sem ela, recarregando.

1. A publicação: `ALTER PUBLICATION supabase_realtime ADD TABLE
   internal_messages`, ou `CREATE PUBLICATION` se a Fase 0 mostrou que não
   existe. Bloco `b6` em `docs/ponte/aplicacao-023/`, e migração.
2. `NxConversas.tsx` assina `postgres_changes` em `internal_messages` enquanto
   está aberto, e cancela ao fechar. **O RLS vale na assinatura**: o Realtime
   do Supabase filtra pelo `SELECT` do assinante, então a policy da Fase 1 é o
   que impede terceiro de receber o evento. O aceite prova isso, e não só
   assume.

**Aceite:** prova 6, duas abas, uma por pessoa. **Com controle negativo:** uma
terceira aba, logada como um terceiro membro da clínica, **não** recebe o
evento.

### Fase 4 · Fechamento

A seção 2 da regra passa a dizer o que está no ar; a seção 5 ganha a linha da
migração de `task_comments`; a 024 é avisada; o handoff registra o que ficou
"código lido, não comportamento provado".

---

## 6. Complexidade a justificar

| Violação | Por que ela existe | Alternativa mais simples, e por que não serve |
|---|---|---|
| **Tabela nova**, quando o FR-001 desta mesma regra proíbe tabela própria para o sino | o FR-001 é sobre **aviso**, que se deriva. Mensagem é **dado novo**, que não existe em lugar nenhum para ser derivado. A seção 8.4 registra a distinção | guardar mensagem em `task_comments`. Não serve: comentário é público na tarefa, e mensagem é entre duas pessoas; e mensagem sobre lead ou paciente não tem tarefa para se prender |
| **Policy por participante**, diferente das 79 por clínica | mensagem entre duas pessoas lida por qualquer um da clínica não é mensagem, é mural. O `SELECT` por participante é o requisito, e é o único jeito de o FR-014 passar sem depender da tela | policy por clínica e filtro na tela. Não serve: alínea (c), e é exatamente o defeito que o FR-011 da 021 já paga |
| **`ref_id` sem chave estrangeira** | a mensagem sobrevive ao item: apagar a tarefa não apaga a conversa sobre ela (prova 5). Mesmo motivo do FR-005 da 017 | FK com `ON DELETE SET NULL`. Não serve: perde a referência e a mensagem passa a falar de nada |
| **Trigger `BEFORE UPDATE`** para travar tudo menos `read_at` | policy de `UPDATE` não consegue comparar valor novo com valor antigo coluna a coluna; só o trigger vê `OLD` e `NEW` | confiar que a tela só manda `read_at`. Não serve: alínea (c) |

---

## 7. O que este plano deliberadamente não faz

- **Não cria grupo nem canal.** FR-007. Grupo tem dono para virar regra própria.
- **Não avisa fora do app.** FR-012. E-mail e notificação do navegador são
  regra própria, com opt-in e consentimento.
- **Não toca `task_comments`**, além de trazer para migração o bloco que já
  está no ar.
- **Não toca ModuleKey, `plans` nem `permissions`.** FR-013.
- **Não apaga mensagem por nenhum caminho.** FR-009. Eliminação é pela regra
  019.
- **Não executa a 024.** Avisa que o bloco 4 pode entrar, e para.
- **Não decide a correção do membro sem `user_id`.** Mesmo Portão 3 da 024;
  a decisão tem dono fora daqui.
