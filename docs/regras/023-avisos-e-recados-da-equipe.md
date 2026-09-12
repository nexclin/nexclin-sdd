# 023 · Avisos e recados da equipe

**Data:** 06/09/2026 · **Origem:** pedido do Arthur, áudio de 06/09 ·
**Estado:** parte entregue, parte **aguardando aprovação e emenda**

## 1. O problema

Duas coisas foram pedidas na mesma frase, e elas **não são a mesma coisa**:

> *"eu quero que tenha o campo de notificações e um campo de mensagens onde
> eles possam se comunicar com breves avisos"*, e antes disso *"a ideia de
> implementar um sistema de mensagens entre os funcionários da mesma
> plataforma, pra enviar uma notificação de atraso, dar um alerta"*.

**Aviso** é o sistema falando com a pessoa sobre um fato que ele já conhece.
**Recado** é uma pessoa falando com outra. O primeiro se deriva; o segundo se
guarda. Tratar os dois como um só produziria uma tabela de notificações que
ninguém precisa e uma caixa de mensagens que ninguém confia.

## 2. O que já vale, e é o que foi entregue

- **FR-001** · faixa **C** · alvo **Lovable + stack nova** · **ENTREGUE**
  O sino **MUST** derivar todo aviso de dado que já existe, e **MUST NOT** ter
  tabela própria nesta versão.
  *Porquê:* tarefa atrasada já é tarefa com `due_date` no passado, conta vencida
  já é recebível pendente vencido. Duas consultas custam zero migração, e o
  número não pode dessincronizar porque não há segunda cópia. A dois dias do
  lançamento, tabela nova é risco sem retorno.

- **FR-002** · faixa **C** · **ENTREGUE**
  A ausência de "marcar como lida" **MUST** estar dita na própria interface.
  *Porquê:* interface que finge ter estado que não tem é pior que interface
  honesta e simples. O rodapé do painel diz em uma linha.

- **FR-003** · faixa **C** · **ENTREGUE**
  A contagem **MUST** ficar vermelha só quando houver algo **vencido**.
  *Porquê:* se tudo é vermelho, vermelho para de querer dizer alguma coisa.

- **FR-004** · faixa **B** · **LIMITAÇÃO CONHECIDA**
  O sino respeita o RLS de clínica e **NÃO** respeita permissão de módulo: quem
  tem `contas_receber` negado ainda vê a contagem de contas vencidas.
  *Porquê:* é consequência direta do **FR-011 da regra 021**, as políticas de
  22/03 que não chamam `my_permission`. Some quando aquele for corrigido no
  banco, e não vale um remendo de tela antes disso.

## 3. O que NÃO foi feito, e o que ele exige antes

- **FR-005** · faixa **A** · alvo **stack nova** · **NÃO IMPLEMENTADO**
  Recado entre funcionários da mesma clínica **MUST** ser gravado, com autor,
  destinatário, texto, instante e estado de leitura por pessoa.
  *Porquê não foi feito agora, e a razão não é preguiça:* é uma feature de
  persistência. Ela precisa de tabela, de RLS por clínica **e** por
  destinatário, de índice para não ler tudo, e de um estado de leitura que é
  por par de pessoa e mensagem. Nada disso se prova em dois dias, e mensagem
  perdida ou vazada entre clínicas é o tipo de erro que não se explica a um
  fundador.

- **FR-006** · faixa **A** · **EXIGE EMENDA À CONSTITUIÇÃO**
  Recado não cabe em nenhuma das **15 ModuleKeys**. A alínea (f) é explícita:
  *"Módulo novo exige emenda à constituição"*.
  *A alternativa que evita a emenda, e ela é séria:* prender o recado à
  **tarefa**, como comentário, em vez de criar caixa de mensagens. Aí ele vive
  sob a ModuleKey `tarefas`, herda a permissão dela, e responde ao caso concreto
  que o Arthur descreveu, que foi *"enviar uma notificação de atraso, dar um
  alerta"*. Alerta sobre tarefa atrasada **é sobre uma tarefa**.

## 4. A recomendação, e ela é uma escolha entre duas

| Caminho | O que custa | O que entrega |
|---|---|---|
| **Comentário na tarefa** | uma tabela, uma política, sem emenda | resolve o caso descrito: cobrar quem está atrasado, no lugar onde o atraso aparece |
| **Caixa de mensagens** | tabela, RLS por destinatário, estado de leitura, emenda à constituição, ModuleKey nova | conversa livre entre a equipe, que nenhum dos dois sócios pediu por si só |

**A recomendação é o comentário na tarefa**, e ela vai para depois de 08/09 nos
dois casos. Nada aqui impede o fundador de operar a clínica, que é o critério
da §2.5 para o que entra antes do lançamento.

## 5. O que o banco vai precisar, quando for a hora

| Tabela | Colunas mínimas | FR |
|---|---|---|
| comentário de tarefa | `task_id`, `clinic_id`, autor, texto, instante | FR-005 |
| leitura | quem leu, o quê, quando | FR-005 |

RLS por `clinic_id` como toda tabela do sistema, alínea (a), e **default deny**,
alínea (b). O autor sai de `auth.uid()`, nunca do cliente.

## 6. Como se prova

1. Duas clínicas, um comentário em cada. Nenhuma lê o da outra.
2. Um comentário criado pela tela grava autor igual ao usuário logado, e não o
   que o front mandou.
3. Marcar como lido não marca para os outros.

**Nenhuma dessas provas pode rodar hoje**, pelo mesmo motivo de sempre: a
clínica de teste tem um usuário só. Ver `docs/ponte/50-segundo-usuario-passo-a-passo.md`.

## 7. Aberto

> **Fechado em 12/09/2026.** O comentário na tarefa foi entregue (FR-005,
> `task_comments`). A caixa de mensagens **também entra**, e sem emenda à
> alínea (f): ela não é módulo, é infraestrutura de todo membro com login,
> como o sino. A decisão e os requisitos dela estão na seção 8 desta regra.

- ~~A escolha da seção 4 é do Arthur.~~ Fechada: as duas.
- ~~Se for a caixa, a emenda vem antes do código.~~ Não há emenda à (f); a
  emenda que houve foi ao FR-007 da regra 020, revogado no mesmo commit.

---

## 8. Mensagem interna, a caixa que entrou em 12/09/2026

> **Estado em 12/09/2026:** especificada, nada implementado. Alvo: **Lovable e
> stack nova**, pela exceção nomeada no Princípio IV da constituição (2.1.0).
> **Origem:** ditado pelo Arthur em 11/09 e interrogado em 4 rodadas; a mesma
> conversa revogou o FR-007 da regra 020.

### 8.1 O problema

O recado na tarefa (FR-005) resolve a cobrança e não resolve a conversa que a
cobrança gera. Hoje ela sai para o WhatsApp, onde não tem referência ao
paciente nem à tarefa, e some. A secretária, que agenda e delega o médico, e o
médico, que executa e cobra, não têm como falar dentro do sistema sobre uma
consulta ou um lead. O que se pede é conversa curta, entre duas pessoas da
mesma clínica, com o item de que se fala anexado.

### 8.2 Requisitos

- **FR-007** · faixa **A**
  A mensagem interna **MUST** ser entre **dois membros da mesma clínica que têm
  login**, e **MUST NOT** ter grupo nem canal nesta versão.
  *Porquê:* membro sem `user_id` (o médico da Cezar Essence, listado e sem
  login) não tem como ler; mensagem para quem não lê é o WhatsApp de fora
  voltando pela porta dos fundos. Grupo não tem caso de uso pedido, e o canal
  por tarefa já existe: é o `task_comments`.

- **FR-008** · faixa **A**
  A mensagem **MUST** poder carregar **uma referência** a tarefa, consulta,
  lead ou paciente, e a tela **MUST** mostrá-la como cartão que leva ao item.
  *Porquê:* é o "encaminhar" e o "responder em particular" do WhatsApp, feitos
  dentro do sistema. Conversa sem o item anexado é o que tira o recado do
  contexto em que ele significa alguma coisa.

- **FR-009** · faixa **A**
  Ninguém **MUST** editar nem apagar mensagem, e membro desativado **MUST**
  deixar a conversa legível para o outro lado, sem resposta possível.
  *Porquê:* mensagem carrega nome de paciente e é rastro de comunicação sobre
  ele. Rastro não se apaga por quem escreveu. Se a LGPD pedir eliminação, é
  pelo caminho da regra 019, e não por botão.

- **FR-010** · faixa **A**
  Estado de leitura **MUST** ser por mensagem e por destinatário, gravado
  quando o destinatário abre a conversa.
  *Porquê:* "não lida" alimenta o balão e o sino, e é a única contagem que a
  tela precisa. Marca por clínica faria a secretária "ler" pelo médico.

- **FR-011** · faixa **C**
  A caixa **MUST** abrir de dois lugares: o balão ao lado do sino, e a foto de
  qualquer membro onde ela aparece (tarefa, consulta, lead). **MUST** abrir em
  painel lateral sobre a tela atual, e não em página própria.
  *Porquê:* quem opera está no meio de um agendamento quando a mensagem chega.
  A foto do membro já aparece em `Tarefas` e nas consultas; começar a conversa
  por ela é o caminho de zero cliques a mais.

- **FR-012** · faixa **B**
  A contagem de não lidas **MUST** aparecer no balão e entrar no sino do
  FR-001. Fora do app, **nada** nesta versão: sem e-mail, sem notificação do
  navegador.
  *Porquê:* quem opera o sistema está com ele aberto. Aviso fora do app é regra
  própria, com opt-in por usuário e consentimento.

- **FR-013** · faixa **A**
  A caixa **MUST NOT** ser ModuleKey, **MUST NOT** depender de plano, e
  **MUST NOT** depender de permissão de módulo: todo membro com login tem.
  *Porquê:* é infraestrutura da clínica, como o perfil e o sino, e não produto
  vendido por plano. Fecha a decisão 1 da seção 7 da regra 020 sem emenda à
  alínea (f).

- **FR-014** · faixa **A**
  Nenhuma mensagem **MUST** atravessar clínica, e o autor **MUST** sair de
  `auth.uid()`, nunca do cliente.
  *Porquê:* alíneas (a) e (b); e mensagem que não prova autoria não serve para
  cobrar ninguém, que foi a lição do `task_comments`.

- **FR-015** · faixa **C**
  A conversa **MUST** atualizar em tempo real enquanto aberta.
  *Porquê:* o Supabase Realtime já está no banco e custa uma linha de
  publicação. Sem isso a pessoa recarrega a tela para ver a resposta, e volta ao
  WhatsApp.

### 8.3 O que muda no banco

| Objeto | Mudança |
|---|---|
| tabela nova `internal_messages` | `id`, `clinic_id` (âncora, `NOT NULL`), `sender_id uuid NOT NULL DEFAULT auth.uid()`, `recipient_id uuid NOT NULL`, `body text` não vazio, `ref_type text` em (`task`, `appointment`, `lead`, `patient`) ou nulo, `ref_id uuid` nulo, `created_at`, `read_at timestamptz` nulo. Índice `(clinic_id, recipient_id, read_at)` para a contagem, e `(clinic_id, sender_id, recipient_id, created_at)` para a conversa |
| RLS de `internal_messages` | `SELECT` só para `sender_id = auth.uid()` ou `recipient_id = auth.uid()`, na própria clínica. `INSERT` com `sender_id = auth.uid()`, `clinic_id` da própria âncora, e `recipient_id` que pertença a um `team_members` **ativo, com `user_id`, da mesma clínica**. `UPDATE` só do `recipient_id`, e só de `read_at`. **Sem `DELETE`**. Mesma forma das 79 policies, por `clinic_id`, e sem `my_permission`, pelo mesmo motivo registrado no bloco B1 |
| publicação Realtime | `internal_messages` entra em `supabase_realtime` |
| `task_comments` | **nada**. Continua sendo o fio público da tarefa |
| ModuleKey, `plans`, `team_members.permissions` | **nada**, pelo FR-013 |

### 8.4 Premissas

- `team_members.user_id` está preenchido para todo membro que já fez login.
  Se houver membro com login e sem `user_id` (o dono das clínicas de agosto
  entrou em `team_members` sem ele, apontado na migração de 25/08), esse membro
  não aparece como destinatário até a correção.
- A contagem do sino (FR-001) continua derivada, e a de mensagens é a única
  que vem de tabela própria. Isso não fere o FR-001: mensagem não é aviso
  derivado, é dado novo.

### 8.5 Dependências

- **Antes:** nada de banco. `profiles.avatar_url` e `useResponsaveis` já dão a
  foto do membro.
- **Depende desta:** a regra 024 usa o balão no painel operacional (bloco de
  mensagens não lidas) e o botão "falar com" na tarefa e na consulta.
- **Não depende do FR-011 da regra 021:** a policy aqui é por participante, e
  não por módulo, então a cascata não muda nada.

### 8.6 Como se prova que funciona

1. Duas clínicas, uma mensagem em cada. Nenhuma lê a da outra. **Exige o
   segundo usuário da issue #50.**
2. Inserir mensagem pela API com `sender_id` de outra pessoa: recusada.
3. Enviar para membro sem login: recusada pela policy, e ele não aparece na
   lista da tela.
4. O destinatário abre a conversa: `read_at` grava, o balão zera para ele e
   não para o remetente.
5. Mensagem com referência a uma tarefa: o cartão leva à tarefa; apagar a
   tarefa não apaga a mensagem (referência sem chave estrangeira, de propósito,
   pelo mesmo motivo do FR-005 da 017).
6. Duas abas, uma por pessoa: a resposta aparece sem recarregar.
7. Automatizado, em `src/lib/conversas.ts` na Lovable: quem pode ser
   destinatário (membro ativo, com login, menos eu); agrupar mensagens em
   conversas; contar não lidas por conversa e no total; montar o cartão a partir
   do item. **O que ele não cobre:** RLS, Realtime e a tela.

### 8.7 A decisão que falta, e precisa do Arthur

**Nenhuma.** As decisões foram fechadas em 11/09 e 12/09 (grilling, 4 rodadas):
duas pessoas, sem grupo; referência única; ninguém apaga; nada fora do app;
balão mais foto; painel lateral; não é módulo. Fora desta versão e com dono
para virar regra própria: grupo, aviso fora do app, entrega por WhatsApp.
