# Mensagem para o grupo, 04/09/2026

> Rascunho para o Arthur enviar. Não foi enviada por mim.
> É a tarefa que a reunião atribuiu a ele: gerar o checklist de prioridades e
> mandar para validação.

---

Fechei a lista a partir da transcrição de ontem. Três coisas antes do checklist,
porque mudam o que a gente faz.

**1. A data é 8 de setembro, não 8 de outubro.** O resumo automático do Gemini
escreveu outubro três vezes. Na gravação está *"tá de pé pro dia 8"*, *"hoje é
dia 3"*, *"faltam cinco dias"*. Quem só ler o resumo erra por um mês. Outubro é a
troca de arquitetura, que é outra coisa.

**2. O resumo tem mais dois erros, e um deles ia me custar dias.** Ele lista
"remodelar propostas" como tarefa minha. Na gravação o Erick diz que mostrou por
curiosidade e que não é prioridade da V1. Não vou mexer. E ele diz para mover
precificação e insumos para uma aba nova, quando a gente decidiu **ocultar** os
três, precificação, insumos e salas, e não criar aba nenhuma.

**3. A régua dos 200% em doze áreas não cabe em quatro dias.** Conciliação
bancária, importação de OFX, recorrência, régua em Kanban e baixa em duas etapas
é trabalho de semanas. Então recortei, e preciso que vocês validem o recorte:

• **financeiro e tarefas entram na régua dos 200%.** São as duas que mais doem se
falharem, uma pelo caixa e a outra porque é o que brilha o olho do médico.
• **dashboard, atendimento, paciente, consulta, anamnese e insights entram como
estão**, corrigidos do que trava uso.
• **relatórios não entram na régua por outro motivo:** eles já passaram por uma
bateria em 30/08. Sete dos oito passaram, e o de Vendas reprovou com dois
defeitos que já foram corrigidos e publicados. Sobra uma pendência que eu ainda
não expliquei: **252 linhas na tela contra 280 na base**, e as 28 de diferença
não são justificadas pelo filtro de data.

---

**O checklist, na ordem que eu vou atacar:**

**1. Ocultar precificação, insumos e salas, e juntar cadastros numa aba só.**
Ponho primeiro porque é a única coisa da lista que **diminui** trabalho, tira
três telas da conta. Pergunta que ficou em aberto ontem: a aba de cadastros volta
para o menu principal? O Vinícius pediu, o Erick concordou, eu não fechei.

**2. Os três bugs que travam cliente de verdade.** Clínica Davi Moraes e Clínica
Dra. Duda Gonçalves não conseguem agendar, cada uma tem um serviço com a macro
categoria em branco. Mais a clínica com assinatura cancelada, cujo dono não abre
nada. Mais aplicar a correção que faz clínica nova já nascer com os cadastros
certos, para não repetir o caso.

**3. Financeiro.** Aqui eu inverti a ordem que o Erick falou, e quero dizer por
quê. Ele listou o comercial primeiro, mas chamou o comercial de "talentinho" e o
financeiro de "preocupação 01". E o financeiro é o único bloco em que **o erro
não é descartado em outubro, é importado**: o banco migra intacto, com tudo que
as clínicas lançarem no mês. O que entra: baixa em duas etapas em vez de trocar o
status direto, importação de OFX com baixa automática, conciliação, recorrência
em contas a pagar e a receber, saldo de hoje em destaque, e a régua de cobrança
em Kanban.

Erick, você disse que nesse eu não preciso provar escopo com você, é modelar
igual ao IN. Então o que eu preciso é **o acesso à conta do IN ou o vídeo**, o que
for mais rápido para você.

**4. Tarefas.** Prazo e dias de atraso escancarados, foto do responsável no card,
comentários, subtarefas e recorrência. Vinícius, a recorrência depende do seu
checklist de rotinas: **me manda inteiro** que eu modelo em cima dele.

**5. Funil.** SLA de prazo por coluna com o card piscando, histórico do card,
colunas editáveis e campo de busca. Boa notícia aqui: metade disso já estava
escrita de uma conversa anterior com o Vinícius, sobre a régua de três contatos
nos dias 1, 3 e 7 variando de clínica para clínica. É a mesma coisa que o SLA por
coluna, então não é frente nova.

**6. Dashboard, relatórios e insights**, por último e juntos, como combinamos.
Vinícius, o dashboard puxando errado eu ainda não consigo reproduzir. Você
apontou duas vezes ontem, e das duas sem citar um número. Me manda um print ou um
número só: **qual valor você viu na tela e qual você esperava**. Com isso eu
fecho em uma sessão.

**7. Tapa visual.** Os 180px de topo, o menu em cascata e a barra de rolagem que
aparece à toa.

---

Erick, ficaram contigo: o vídeo do CRM, o acesso ou vídeo do financeiro do IN, e
avaliar o super admin (é link e login separados, te mando de novo).

**O que eu preciso de vocês dois hoje:** validem o recorte dos 200% do item 3 lá
em cima e me digam se a ordem está certa. O resto eu toco.
