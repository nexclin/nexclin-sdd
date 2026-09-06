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

- **A escolha da seção 4 é do Arthur.** Comentário na tarefa, ou caixa de
  mensagens com emenda.
- Se for a caixa, **a emenda vem antes do código**, e não depois.
