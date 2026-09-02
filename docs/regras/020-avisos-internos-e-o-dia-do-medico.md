# 020 · Avisos internos e o dia do médico

> **Regra viva.** Nasce antes da execução, guia a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 02/09/2026:** especificada, nada implementado. Alvo: **stack
> nova**. O que for de tela não sobe para a Lovable, pela §2.5.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Origem:** ditado pelo Arthur em 31/08/2026, a partir da mentoria do
> Vinícius, mais pesquisa de mercado feita em 02/09.

---

## 1. O problema

O médico abre a clínica de manhã e **não sabe o que mudou desde ontem**. A
secretária marcou uma consulta, remarcou outra, e um paciente que vai chegar hoje
não preencheu a anamnese. Nada disso alcança o médico dentro do sistema: ele
descobre olhando tela por tela, ou não descobre. Do outro lado, a secretária não
é avisada de que a anamnese de um paciente agendado continua em branco, e a
cobrança do preenchimento acontece por fora, no WhatsApp ou não acontece.

Sem mexer nisso, a plataforma continua sendo um lugar onde a informação está
guardada e ninguém é avisado dela. **O sistema sabe de tudo e não conta nada.**

### 1.1 O que a leitura do banco mostrou, e muda o tamanho do problema

Os eventos **já existem**. A tabela `tasks` já é escrita automaticamente com
nove tipos, e entre eles estão exatamente os que o Vinícius quer ver:
`confirmar_agendamento`, `envio_anamnese`, `remarcacao_consulta`,
`recaptacao` mais três subtipos, `pos_consulta` e `entrada_consulta`.

Ou seja: **não falta o evento, falta a leitura dele.** O que hoje existe é um
quadro pequeno de "Tarefas pendentes" num dashboard que a própria §2.5 já
rebaixou a "visão simples pro médico". A informação está gravada e não é
entregue a ninguém.

`account_timeline` não serve para isto, e vale dizer para ninguém tentar: a
policy dela é `is_superadmin`, é o histórico da conta para quem opera o SaaS, e
não um mural da clínica.

### 1.2 A pesquisa de mercado, e onde está o diferencial

Feita em 02/09/2026, e o resultado separa duas coisas que o pedido misturava.

**Notificação ao paciente é paridade.** É o que os concorrentes documentam e
vendem: confirmação logo após o agendamento, lembrete 48h e 24h antes, botão de
confirmar presença, integração com WhatsApp. A central de ajuda da Feegow
descreve isso passo a passo. Fazer isso não diferencia nada, e por isso **está
fora do escopo desta regra**.

**Notificação interna entre a equipe não aparece documentada.** A página de
funcionalidades da iClinic, consultada como fonte primária, **não menciona**
aviso ao médico sobre marcação ou remarcação feita pela secretária, painel de
tarefas do dia, nem mensagem direta entre profissionais da clínica. O que se
acha sobre coordenação interna em material de terceiros é genérico: "painel
único", "comunicação entre departamentos".

**A ressalva honesta:** ausência numa página de marketing não prova ausência no
produto. O que se pode afirmar é que **nenhum dos dois maiores trata isso como
argumento de venda**, e é isso que sustenta a decisão, não uma afirmação sobre o
que o concorrente tem por dentro.

Isso casa com o critério do `CLAUDE.md`: o diferencial é embarcar metodologia de
gestão clínica, não competir funcionalidade a funcionalidade. Avisar o médico do
que chegou para ele é metodologia, e é o que o Vinícius ensina na mentoria.

---

## 2. Requisitos

**FR-001**: O aviso interno **MUST** ser derivado de `tasks`, e o sistema
**MUST NOT** criar uma tabela paralela de eventos.
*Porquê:* `receivables` é escrita de **seis lugares diferentes** hoje, e isso já
produziu recebível sem `macro_category` caindo no balde errado, registrado em
25/08. Duas moradas para o mesmo fato é como o dashboard passou a mostrar
números que se contradizem. Evento novo em tabela nova repetiria o erro na
véspera de ele ser consertado.

**FR-002**: `tasks.responsible` **MUST** referenciar o usuário, e **MUST NOT**
continuar sendo texto livre.
*Porquê:* hoje a coluna é `TEXT DEFAULT ''`. Não se entrega aviso a uma string.
É o mesmo defeito da especialidade no provisionamento, que virou `Input` livre e
por isso não casa com template nenhum: vocabulário não controlado quebra toda
automação que dependa dele.

**FR-003**: O sistema **MUST** guardar, **por usuário**, quando ele viu os
avisos pela última vez, e **MUST NOT** guardar isso por clínica.
*Porquê:* "o que chegou desde que eu olhei" é uma pergunta por pessoa. Uma marca
por clínica faria o médico perder o aviso porque a secretária abriu antes.

**FR-004**: O painel do dia **MUST** mostrar, por item: horário, paciente, quem
criou o registro, e se a anamnese está preenchida.
*Porquê:* é a lista literal que o Vinícius ditou, e cada campo responde a uma
decisão da manhã. Sem quem criou, o médico não sabe a quem perguntar. Sem o
estado da anamnese, ele descobre na cadeira, com o paciente na frente.

**FR-005**: Quando a anamnese de um paciente agendado não estiver preenchida, a
tarefa de cobrança **MUST** ser dirigida à secretária, e **MUST NOT** ficar
apenas no painel do médico.
*Porquê:* o médico não faz a cobrança, e aviso que chega em quem não executa é
ruído. O tipo `envio_anamnese` já existe em `tasks`, então isto é roteamento, e
não evento novo.

**FR-006**: O médico **MUST** poder cobrar a secretária pela própria plataforma,
com mensagens padronizadas e a possibilidade de escrever uma específica.
*Porquê:* é o pedido literal, e o motivo é operacional: a cobrança hoje sai do
sistema e vai para o WhatsApp, onde ela some e não vira registro.

**FR-007**: O canal entre médico e secretária **MUST NOT** virar chat.
*Porquê:* chat exige presença, histórico, busca e notificação em tempo real, e
nada disso foi pedido. O que foi pedido é recado curto preso a um paciente ou a
uma tarefa. Chat solto também tira o recado do contexto em que ele significa
alguma coisa.

**FR-008**: Nenhum aviso **MUST** atravessar clínica.
*Porquê:* regra (a) e (b) da constituição. O aviso carrega nome de paciente, e
nome de paciente é dado de saúde.

**FR-009**: Notificação **ao paciente** está **fora** desta regra.
*Porquê:* é paridade de mercado, é outro destinatário, e tem requisito legal
próprio de consentimento. Misturar as duas faria uma regra decidir sobre LGPD de
titular, que é assunto da 019.

---

## 3. O que muda no banco

| Objeto | Mudança |
|---|---|
| `tasks.responsible` | de `TEXT` para referência ao usuário, com migração de dados do que já está escrito em texto |
| `profiles` | coluna nova, carimbo de quando o usuário viu os avisos pela última vez. Segue o padrão da `20260828020000`, que fez o mesmo para a apresentação inicial, pelas mesmas razões: é um fato por usuário, do tamanho de uma coluna, e `profiles` já tem policy de escrita do próprio dono |
| tabela nova, recado interno | `clinic_id`, autor, destinatário, texto, referência opcional a `task_id` ou `patient_id`, carimbo de leitura. RLS por `clinic_id`, e leitura restrita a autor e destinatário |
| `tasks` | **nada**. Os nove tipos já existem e continuam sendo gerados pelos caminhos atuais |

**O que explicitamente não se cria:** tabela de eventos, tabela de notificações,
e fila. O evento é a tarefa.

---

## 4. Premissas

1. **`tasks` continua sendo gerada pelos caminhos que já a geram.** Se algum for
   removido, o aviso correspondente some junto e ninguém percebe, porque não há
   erro: só deixa de aparecer.
2. **A migração `20260825090000`, que traz `created_by` em `tasks`, está
   aplicada.** O FR-004 depende dela para dizer quem criou o registro. Se não
   estiver, esse campo não tem de onde sair, e a regra para até aplicar.
3. **`responsible` hoje guarda nome digitado, e não identificador.** A migração
   do FR-002 precisa decidir o que fazer com texto que não casa com usuário
   nenhum, e o padrão é deixar nulo em vez de adivinhar.
4. **A anamnese tem estado consultável por paciente e por consulta.** Existe
   `anamnesis_responses` e `anamnesis_config`, e o FR-004 assume que dá para
   responder "preenchida ou não" sem varredura cara.

---

## 5. Dependências

**A regra (f) da constituição fixa 15 ModuleKeys, e módulo novo exige emenda.**
Isto parte o pedido em dois:

- o **painel de tarefas do dia** cabe em `tarefas`, que já é ModuleKey. Não
  precisa de emenda, e pode ser feito;
- o **sininho de avisos** e o **recado entre médico e secretária** atravessam o
  sistema inteiro e não pertencem a nenhum dos 15. **Precisam de emenda**, e a
  emenda vem antes do código.

Depende também de o FR-002 estar feito antes de qualquer roteamento, porque
enquanto `responsible` for texto não há a quem entregar.

**O que depende desta regra:** a regra 018, do funil, pediu alerta de
atendimentos em aberto e recaptações a fazer na tela de Atendimentos. É o mesmo
mecanismo com outro conteúdo, e as duas devem usar o mesmo caminho em vez de
cada uma inventar o seu.

---

## 6. Como se prova que funciona

| # | Critério | Como se prova |
|---|---|---|
| 1 | a secretária marca uma consulta e o médico é avisado | entrar como médico depois, e o item aparece como novo |
| 2 | o mesmo aviso não aparece como novo duas vezes | abrir, sair, entrar de novo. Some da contagem de novos e continua na lista |
| 3 | o carimbo é por pessoa | a secretária abre primeiro, e o médico ainda vê o aviso como novo |
| 4 | anamnese em branco vira cobrança **da secretária** | agendar sem anamnese e conferir que a tarefa chega nela, e não no médico |
| 5 | o painel mostra os quatro campos | horário, paciente, quem criou, estado da anamnese, na mesma linha |
| 6 | recado do médico chega na secretária | enviar um padronizado e um escrito à mão |
| 7 | nada atravessa clínica | duas clínicas, com `SET LOCAL ROLE authenticated` e claim trocado, e cada uma vê só os seus |

**Prova automatizada:** o roteamento do FR-005 e a conta de "novos desde a
última visita" do FR-003 são funções puras e entram em teste. O critério 7 é
`BEGIN`/`ROLLBACK` com troca de claim, como no FR-005 da regra 017.

**O que o teste não cobre:** se o médico de fato olha o painel de manhã. Isso só
a bateria com o Vinícius responde, e é o que decide se a regra serviu.

---

## 7. A decisão que falta, e precisa do Arthur

**1. A emenda à constituição, para o sininho e o recado interno.** Sem ela,
metade desta regra não pode ser construída. O que pesa de cada lado: uma
ModuleKey nova significa que plano, permissão e tela passam a falar dela, e as
15 deixam de ser 15, o que já foi tratado como contrato estável. Do outro lado,
pendurar aviso e recado dentro de `tarefas` faz a permissão de tarefas controlar
quem recebe recado, o que é errado por outro motivo. **Bloqueado sem resposta:**
FR-006 e o sininho. O painel do dia não fica bloqueado.

**2. O recado entre médico e secretária entra na primeira versão, ou fica para
depois?** Ele é a única parte que cria tabela nova e o único que precisa da
emenda. Tirá-lo da primeira versão deixa a regra inteira construível dentro de
`tarefas`, e entrega o que o Vinícius chamou de essencial, que é o médico saber
o que chegou. **Recomendação, e é do Claude:** primeira versão sem o recado.

**3. Alvo.** A regra está escrita para a stack nova. Se algo aqui tiver de
aparecer na Lovable antes de 08/09, precisa ser dito, e a §2.5 pede a razão
certa: nada aqui impede o fundador de operar hoje, então a recomendação é não
subir nada.
