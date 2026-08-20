# Quatro perguntas para o Vinícius — 20/08/2026

**Como usar:** copie da linha tracejada para baixo e mande de uma vez. As quatro
juntas, não em quatro mensagens.

**Por que responder rápido:** o valor destas respostas mudou de lugar. Antes
eram para consertar a plataforma Lovable. Agora são para **escrever a regra
certa na stack Next.js**, que nasce em outubro — as respostas viram critério de
aceite das specs dos módulos. Sem elas a spec nasce com buraco, e o buraco custa
muito mais caro depois do que agora.

Prazo útil: **21/08**, antes da janela de correção.

---

Vinícius, terminei de ler suas duas baterias, 18 e 19. São 33 registros no
total, e a grande maioria já tem regra clara o suficiente para eu implementar
sem te incomodar — você descreveu bem o que esperava em quase tudo.

Sobraram quatro coisas que eu não consigo resolver sem você. Em três delas
falta um detalhe para eu conseguir reproduzir; na quarta, o que você escreveu
tem duas leituras possíveis.

Uma observação sobre por que isso importa mais do que parece: a gente vai
reescrever o sistema em outra tecnologia até outubro. A correção na plataforma
atual serve para o mês dos fundadores, mas **a sua resposta serve para sempre** —
é ela que vira a regra escrita do sistema novo. Por isso vale o seu tempo mesmo
naquilo que parece detalhe pequeno.

**1. Ticket médio do dashboard — as duas frases se contradizem**

Você escreveu que o ticket "coloca por itens vendidos, não por **paciente**" e,
logo depois, que ele deveria considerar "a quantidade de **orçamentos**".

Concordamos que dividir por item está errado. A dúvida é por qual dos outros
dois dividir, porque um paciente pode ter dois orçamentos no mesmo período:

- **por orçamento aprovado** responde *"quanto vale cada fechamento que fazemos?"*
  — serve para medir a qualidade da venda;
- **por paciente** responde *"quanto cada pessoa deixa na clínica?"* — serve para
  medir valor por cliente e recompra.

Um detalhe que pode decidir: o **relatório de Vendas** que já existe calcula por
paciente único. Se o dashboard passar a calcular por orçamento, os dois vão
mostrar números diferentes com o mesmo nome — e aí a gente precisa renomear um
dos dois na tela.

Se na metodologia os dois números tiverem nomes próprios e ambos importarem,
me diga também: dá para mostrar os dois, mas com rótulos distintos.

**2. Filtro de tarefas — qual você usou?**

Você disse que na tela de Tarefas, ao filtrar para ver só o dia, "todos os
dados somem". A tela tem quatro filtros (tipo, status, responsável, período) e
eu não consigo reproduzir sem saber qual.

Qual filtro, ou qual combinação, e com qual valor em cada um? O status já
nasce em "Pendente" — você trocou para outro status, ou mexeu só no período
para "Hoje"?

**3. Filtro do relatório de Contas a Receber — mesma coisa**

Você relatou que ao filtrar para baixar o relatório os dados sumiram. Esse
relatório tem vários filtros: período, "por vencimento", status, bancos e mais
dois.

Qual você aplicou, e com qual valor?

*(Se por acaso for o mesmo comportamento da pergunta 2, me diga — pode ser um
problema só aparecendo em duas telas, e aí a correção é uma.)*

**4. Relatório de produtividade — quais números?**

Você disse que o "valor orçado" veio errado. Para eu comparar preciso dos
números:

- para qual profissional?
- que valor o relatório mostrou?
- qual é o valor certo, o que você somou na mão a partir dos orçamentos dele
  no período?

---

**Não precisa responder — só confira se concorda**

Estas eu já dei como fechadas a partir do que você escreveu. Se discordar de
alguma, avise até 21/08 que a gente reabre:

- **Taxa de conversão** — vendido sobre total orçado, como no painel de
  consultas (você mesmo deu a referência).
- **Fechamento parcial** — se qualquer item saiu da lista, é parcial. Só é
  completo se tudo foi aprovado.
- **Novos pacientes** — só consultas de 1ª vez, vindas do CRM ou com categoria
  de 1ª consulta. Mesmo filtro em "novas consultas realizadas".
- **Agenda em horário ocupado** — o sistema vai **avisar e deixar confirmar**,
  não bloquear. A razão: clínica faz encaixe de propósito, e com bloqueio duro
  a secretária burla criando consulta em horário falso — o que estraga a agenda
  em vez de proteger.
- **Recaptação e remarcação** — vão para o responsável pela venda, nunca para o
  médico. E como consulta avulsa hoje não tem responsável, **o campo passa a ser
  obrigatório no lançamento avulso**, para a regra valer sempre.
- **Crédito** — a antecipação vira configuração da clínica, junto das taxas:
  "antecipa recebimento de crédito?". Ligada, cai em D+1; desligada, 30 dias
  parcelado. Dinheiro e pix caem no mesmo dia, com as taxas descontadas.
- **Financeiro** — a entrada passa a abater a **consulta**, não a prescrição, e
  o adiantamento sai de "vendas". A separação em dois blocos com forma de
  pagamento própria para cada um ficou para o sistema novo: é redesenho de tela
  e mexe em recebível, que é onde erro custa dinheiro do cliente.
- **Erro ao salvar secretária com acesso** — o caminho foi reescrito e publicado
  em 20/08. O admin não define mais a senha de ninguém: agora sai um link e a
  pessoa cria a própria senha. **Preciso que você refaça esse teste** e me diga
  se passou.

**E um pedido:** se aparecer mais alguma coisa até 21/08, manda no mesmo
formato que você já usou — onde, o que fez, o que aconteceu, o que esperava.
Está funcionando bem; foi por isso que só quatro dos 33 precisaram voltar.
