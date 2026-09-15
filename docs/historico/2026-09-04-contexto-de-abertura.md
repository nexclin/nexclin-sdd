# Contexto de abertura para a próxima sessão

**Para que serve:** abrir um chat novo sem reconstruir nada. Tudo que a sessão de
02 a 04/09 sabia e que não está óbvio no código está aqui.

**Como usar:** cole este arquivo inteiro na primeira mensagem do chat novo. A
Seção 0 vence o resto do documento onde houver conflito.

Medido em 04/09/2026, 01h57. A Seção 0 foi preenchida em 04/09 à noite, depois da
reunião de 03/09 e da apuração da transcrição. Toda afirmação abaixo foi
verificada na data indicada, e onde não deu para verificar está escrito que não
deu.

---

## 0. O QUE VALE AGORA

### 0.1 O que saiu da reunião de 03/09

A apuração completa, com marca de tempo em cada decisão, está em
[`2026-09-04-reuniao-03-09-decisoes.md`](2026-09-04-reuniao-03-09-decisoes.md).
Aqui fica só o que muda o trabalho.

- **DECIDIDO: a data é 08/09.** O resumo automático do Gemini diz "8 de outubro"
  três vezes e está errado. A fala, em 00:44:46, é *"tá de pé pro dia 8"*, *"hoje
  é dia 3"*, *"faltam cinco dias"*. Quem ler o resumo sem a transcrição erra por
  um mês.
- **DECIDIDO: o escopo da V1 é financeiro, tarefas, funil, e por último dashboard
  e relatórios.** Paciente e consulta ficaram de fora por decisão explícita dos
  três.
- **DECIDIDO: precificação, insumos e salas ficam ocultos** da visão do usuário.
  Ocultar, não apagar. É a única decisão da reunião que diminui trabalho.
- **DECIDIDO: cadastros e configurações viram uma aba só.** Em aberto, e dois dos
  três queriam: se essa aba volta para o menu principal, hoje ela está no
  dropdown do nome do usuário.
- **DECIDIDO: a regra dos 200%.** 100% é construído e testado por quem
  construiu. 200% é validado pela ótica do usuário final. Ver 0.2 para o recorte
  que vale até 08/09.
- **DECIDIDO: IA é primeiro filtro, humano é decisor final.** *"Não dá pra gente
  entregar nada pro usuário final que não foi testado por alguém que não seja
  uma IA."* Nenhum item da régua fecha só com verificação de sessão.
- **DECIDIDO: uma conta de operador no superadmin, compartilhada pelos três.**
  Ver o preço disso em 0.2.
- **DECIDIDO: as quatro primeiras implantações são em formato de mentoria**, com
  os três juntos.
- **ADIADO para a V2:** Papo AI e WhatsApp por web hook, e nota fiscal via CBR.
- **ADIADO para a V3:** prontuário, planejamento estratégico e camada de
  inteligência.
- **RECUSADO para a V1: remodelar propostas e orçamento.** O resumo do Gemini
  lista isso como tarefa do Arthur. A fala diz *"não é prioridade da V1 a gente
  mexer a esse nível"*. **Não fazer.**
- **RESOLVIDO: as 53 tabelas.** A explicação foi dada em voz e aceita: núcleo
  clínico de cerca de 15, o resto é o que faz disto um SaaS multi-tenant. O item
  sai da Seção 5.
- **CONTINUA ABERTO: o dashboard puxa do lugar errado.** Reafirmado duas vezes na
  reunião, e nas duas sem citar um número. Continua irreprodutível.
- **QUEM FICOU COM O QUÊ:** Erick manda o vídeo do CRM, avalia o superadmin,
  solta um vídeo do financeiro do IN ou dá acesso à conta Lovable dele, e reserva
  blocos semanais de revisão. Vinícius passa o checklist de rotinas inteiro, que
  vira a recorrência de tarefas, e valida dashboard e relatórios na prática.

**Protocolo de trabalho novo, e ele é pré-condição de execução:** antes de cada
frente, o escopo do bloco vai **no grupo**, o Erick aprova ou acrescenta, o
Vinícius comenta, e só então se implementa. **Exceção declarada: o financeiro não
passa por aprovação de escopo**, a referência é o IN e o critério é funcionar
igual.

### 0.2 A próxima orientação, na ordem

Três decisões tomadas em 04/09 sobre o que a reunião deixou aberto:

**1. A régua dos 200% vale para financeiro e tarefas, e só.** Doze áreas a 200%
não cabem em quatro dias. O dia 8 abre com essas duas validadas pela ótica do
usuário, e as demais entram como estão, corrigidas do que trava uso.

Relatórios **não entram na régua por outro motivo**, e a diferença precisa ser
dita assim ao grupo: eles já passaram pela bateria de 30/08, sete dos oito
passaram, e o de Vendas foi corrigido e publicado. Fica uma pendência nomeada, as
**28 linhas** de diferença entre 252 na tela e 280 na base. Dizer "relatório
ficou de fora" para quem opera por relatório quebra confiança sem motivo.

**2. Uma conta de superadmin, compartilhada pelos três.** O preço: a trilha do
FR-005 grava um nome onde há três pessoas, e deixa de responder *quem abriu este
prontuário*, que é a pergunta para a qual ela foi construída. O que ela continua
provando é que houve acesso, quando, a qual paciente e de qual clínica.

Mitigação, de processo e barata: **demonstração ao vivo só na Clínica Teste
Final**, nunca em conta de clínica real; e registrar por fora quem entrou e
quando, nas quatro implantações em mentoria. Reverter é barato: criar duas contas
depois não refaz nada, a trilha passa a distinguir a partir do dia em que elas
existirem.

Efeito colateral bom: o item 3.1 do handoff de 30/08, os quatro papéis do painel
que não limitam nada, **volta a ser latente e sai da urgência**.

**3. Financeiro primeiro, e não o comercial.** O Erick listou o comercial em
primeiro, mas chamou o comercial de "talentinho" e o financeiro de "preocupação
01". O desempate é da §2.5: o financeiro é o único bloco majoritariamente faixa
A, e a estimativa registrada é de R$ 100 a 200 mil de faturamento por clínica
lançado no mês da Lovable. Lançamento errado em setembro é importado em outubro,
não descartado.

**A ordem de ataque:**

| # | O quê | Onde roda |
|---|---|---|
| 0 | fechar a lista e mandar no grupo | qualquer sessão |
| 1 | empurrar os quatro commits órfãos para o GitHub | **máquina do Arthur** |
| 2 | ocultar precificação, insumos e salas, e unificar a aba de cadastros | plataforma |
| 3 | os três bugs que travam cliente real, mais a migração `20260829030000` | plataforma e banco |
| 4 | **financeiro**, com a regra viva escrita antes | plataforma e banco |
| 5 | tarefas | plataforma e banco |
| 6 | funil e SLA, fundidos na regra 018 | plataforma e banco |
| 7 | dashboard, relatórios e insights | plataforma |
| 8 | tapa visual, os 180px e a barra de rolagem | plataforma |

O passo 2 vem antes do resto de propósito: **é a única coisa da lista que
diminui o trabalho**, porque tira três telas da superfície de teste.

**O que NÃO deve ser tocado:**

- **proposta e orçamento.** Recusado na reunião, e o resumo automático diz o
  contrário.
- **a matriz de quatro papéis do superadmin.** Com uma conta só, ela não compra
  nada.
- **precificação, insumos e salas**, nem para testar. O Erick foi explícito:
  *"eu não gastaria energia nisso até de testar e resolver"*.
- **paciente e consulta.** *"Não, isso está fluindo."*
- **tabela paralela de eventos**, proibida pelo FR-001 da regra 020.

### 0.3 Correções e desmentidos

- **A branch `trabalho/28-08-apresentacao-inicial` nunca foi enviada ao
  GitHub.** Conferido em 04/09 contra `origin`: os quatro commits (`8cf2183`,
  `dc8f500`, `140deef`, `7f911c2`) e os oito da plataforma citados na Seção 3
  não existem no remoto. `origin/main` está em `1a4096d`, o merge de 02/09.
  **Os três documentos de prestação de contas de 03/09 existem só numa máquina.**
  Isto é risco real e o conserto é um comando.
- **O resumo automático da reunião não é fonte.** Ele erra a data do lançamento,
  inverte a decisão sobre precificação e insumos, e lista como tarefa uma coisa
  que foi recusada em voz. Quando divergir da transcrição, a transcrição vence.
- **Os números da prestação de contas ditos na reunião estão desatualizados.** Na
  fala foram "200 commits" e "20 regras de negócio". Os documentos de 03/09 dizem
  **289 commits** e **13 regras vivas**. Se esses números forem para o grupo, que
  vão certos.
- **Sessão remota não alcança a plataforma.** `../nexclin-lovable` só existe na
  máquina do Arthur. De uma sessão em nuvem sai regra, documento, issue e código
  da stack Next.js, e não sai publicação na Lovable.

---

## 1. As três decisões permanentes desta fase

Valem até o lançamento e não precisam ser repetidas a cada sessão.

1. **Sem Docker e sem banco local.** Teste de banco roda no editor de SQL contra
   o banco ao vivo. Migração no banco está autorizada.
2. **Prove antes de afirmar.** Escreva o teste antes do código e veja falhar. Se
   não deu para provar, escreva que não deu, em vez de arredondar. Nas sessões
   anteriores isso pegou defeito no próprio teste duas vezes.
3. **O celular saiu da prioridade**, por decisão consciente, porque não ficou
   adequado. Não é surpresa a corrigir, é escolha registrada.

A reunião de 03/09 acrescentou uma quarta, e ela reforça a segunda: **IA é
primeiro filtro, humano é decisor final.** Ver 0.1.

---

## 2. Onde os dois repositórios estão

### `nexclin-sdd`, este repositório

| | |
|---|---|
| branch | `trabalho/28-08-apresentacao-inicial` |
| commits à frente de `origin/main` | 4, **sem PR aberto e sem push** |
| commits atrás | 1 |
| não versionados | `b.js` (bundle baixado para conferência, descartável) e `docs/ponte/macro-category-dos-servicos.sql` |

Os quatro commits não mesclados:

```
8cf2183  os tres documentos de 03/09: pauta, registro tecnico e participacao
dc8f500  o aceite da guarda tinha defeito, e o defeito era meu
140deef  so o super_owner gere operadores, e a plataforma nao pode ficar sem dono
7f911c2  handoff de 02/09: treze consertos, o erro do arquivo orfao, e a hierarquia
```

**Decidido em 04/09: empurrar para o GitHub antes de qualquer outra coisa.** Ver
0.3.

### `../nexclin-lovable`, a plataforma ao vivo

Limpo, `main`, sincronizado com `origin/main`, zero à frente e zero atrás.
**Existe só na máquina do Arthur.**

---

## 3. O que está no ar, conferido em 04/09

O conferir acusou bundle novo (`index-B1ETZRFu.js`) e cada correção foi procurada
dentro dele por marcador de texto. Os três que estavam em dúvida estão
publicados.

| Commit | Marcador procurado | Resultado |
|---|---|---|
| `48b9e8a` vazio honesto | O que está na tela é o filtro | no ar |
| `b00d684` macro obrigatória | Macro Categoria * | no ar |
| `2e2e9ef` pacientes nasce mostrando a base | neste recorte | no ar |
| `0aba81f` desfazer da tarefa | Desfazer, Tarefa concluída | no ar |

Testes: **233 passando**, 21 arquivos, tudo verde.

Com isso, a fila de publicação está vazia. Nada esperando deploy.

---

## 4. O que continua aberto, por dono

### Arthur, dentro da plataforma

| # | O quê | Por que importa |
|---|---|---|
| 1 | macro categoria de Clínica Davi Moraes e Clínica Dra. Duda Gonçalves | as duas **não conseguem agendar**. Cada uma tem um serviço com a macro em branco. A trava nova impede casos novos, e não conserta os antigos |
| 2 | conferir a clínica com assinatura `cancelled` | o dono dela não abre nada, por desenho. Se for cliente real, está trancado |
| 3 | renomear o operador de "Dr. Erick Reis" para o nome do Arthur | a trilha de leitura de prontuário grava o nome, e hoje atribui a outra pessoa. **Ficou mais urgente com a decisão de login compartilhado** |

### Bloqueado por falta de informação

| Item | O que falta |
|---|---|
| dashboard com números contraditórios (item 8 de 31/08) | um número específico que o Vinícius tenha visto errado. Reafirmado na reunião de 03/09, e de novo sem número |
| plano de contas não carrega (V-24) | uma consulta ao banco pedida duas vezes e nunca respondida |
| convite de equipe (V-04) | código reescrito, comportamento nunca reprovado nem provado em tela |

### Escrito e não aplicado

Duas migrações. A mais importante é
`20260829030000_clinica_nova_nasce_usavel.sql`, que faz clínica nova nascer com
tipos de consulta e categorias de despesa. Sem ela, toda clínica nova repete o
problema da macro em branco.

### Especificado e não implementado

- **regra 020**, avisos internos e o dia do médico. Apurado em 04/09: **só o
  sininho precisa da emenda à constituição**. Prazo, dias de atraso, foto,
  comentário, subtarefa e recorrência são campo e tela dentro do módulo
  `tarefas`, que já está no contrato das 15;
- as duas lacunas de LGPD da **regra 019**;
- anamnese por especialidade no momento da criação da clínica.

### Issues do GitHub

15 abertas em `nexclin/nexclin-sdd`, 11 marcadas P0. A maioria é critério de
aceite das regras 001 e 002 que nunca foi executado em tela.

---

## 5. Dívida estrutural, e ela não se conserta aqui

`receivables` é escrita por **seis caminhos diferentes**. É assim que o mesmo
fato financeiro entra em formatos distintos. Não se conserta na plataforma atual
sem risco alto, e é a primeira coisa que a stack nova precisa nascer sem.

O item das 53 tabelas **saiu daqui em 04/09**: a explicação foi dada na reunião e
aceita. Ver 0.1.

---

## 6. As armadilhas desta base, todas pagas com tempo real

Cada uma custou trabalho perdido. Ler isto antes de mexer vale mais que ler o
código.

1. **`pages/Consultas.tsx` não é roteado.** A tela que o menu chama de
   "Consultas" é `pages/Acompanhamento.tsx`. Meio dia de conserto foi para o
   arquivo órfão. Antes de consertar uma tela, confirme por qual rota se chega
   nela. Três testes em `rotas.test.ts` guardam isso hoje.
2. **Leitura pela API mente sobre o banco inteiro.** O RLS esconde as outras
   clínicas, e a contagem sai errada sem erro nenhum. Medição de banco vai no
   editor de SQL, onde não há RLS. Um alarme falso de "21 de 22 clínicas sem tipo
   de consulta" quase saiu por causa disso.
3. **O Publish da Lovable publica o PREVIEW, e não o commit.** O único jeito de
   saber se o código novo está no ar é `scripts/ponte.sh` conferir, e depois
   procurar um marcador de texto dentro do bundle.
4. **`tsconfig.json` puro não confere nada e fica sempre verde.** Use
   `npx tsc --noEmit -p tsconfig.app.json`.
5. **Asserção negativa passa por vacuidade.** "Fulano não consegue" fica
   verdadeiro se o teste estiver errado. Todo bloco de aceite precisa de um
   controle positivo. Foi assim que o FR-005 quase passou por engano, com três
   checagens lendo OK com a tabela não existindo.
6. **Guarda de fonte quebra com formatação.** Delimite pelo elemento, e não por
   janela de tamanho fixo. Uma janela de 600 caracteres cortou no meio de
   `!form.macro_ca` e reprovou código correto duas vezes seguidas.
7. **O padrão que se repetiu cinco vezes:** conserto correto aplicado a uma tela
   e não às irmãs. Ao consertar qualquer coisa, procure as telas da mesma família
   antes de fechar.

---

## 7. Os números da prestação de contas

Estão nos três documentos de 03/09, em `docs/historico/`, com o comando para
reproduzir cada um. **Atenção:** esses três documentos ainda não estão no
GitHub. Ver 0.3.

| | |
|---|---|
| período | 23/07 a 03/09/2026, 42 dias |
| commits diretos de pessoa, antes | 0 em 568 dias |
| commits diretos de pessoa, depois | 289 |
| testes automatizados | 233, eram zero |
| migrações novas | 39 |
| regras vivas | 13 arquivos |
| handoffs | 52 |
| defeitos corrigidos | 66 na soma bruta, e "mais de 60" é o número que não se contesta |

A ressalva do 66: alguns itens da rodada de 25/08 são o fechamento de coisas que
ficaram abertas na bateria de agosto, e contam uma vez, não duas.

Os três documentos:

- `2026-09-03-registro-tecnico.md`, neutro, é a base de prova dos outros dois;
- `2026-09-03-participacao-arthur.md`, o argumento dos 20%;
- `2026-09-03-pauta-da-reuniao.md`, os onze itens que a reunião tinha de fechar.

Existe também um artefato em HTML para transmitir na tela: **O Que Foi Consertado
no NexClin**.

---

## 8. Assuntos que estavam na mesa, e o que a reunião fez com eles

| Assunto | O que a reunião decidiu |
|---|---|
| Papo AI, API de Meta Developers por web hook | **fechado: V2.** E a régua de cobrança do NexClin já abre o WhatsApp com mensagem carregada, igual à do IN. O gap da régua é o formato Kanban, não o WhatsApp |
| login compartilhado ou um por pessoa | **fechado: um só, compartilhado.** O preço e a mitigação estão em 0.2 |
| a impersonação avalia como o cliente? | **continua aberto.** O operador vê módulo fora do plano do cliente, o que numa demonstração mostra o que a pessoa não comprou |
| emenda à constituição para o sininho de avisos | **continua aberto, e encolheu.** Só o sininho precisa dela. Ver Seção 4 |
