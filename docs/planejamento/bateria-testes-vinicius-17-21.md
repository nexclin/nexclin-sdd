# Bateria de testes — Vinícius · 17 a 21 de agosto

> **Para quem é:** Vinícius. Anexe este arquivo ao Claude quando começar a
> sessão — ele serve tanto para você seguir quanto para o assistente entender
> o que está sendo testado.
> **Onde testar:** `https://nexclin.lovable.app`
> **Quanto tempo:** cerca de 45 minutos por dia, 5 dias.
> **Onde registrar:** base **Apontamentos** no Notion, na sua página da rodada
> — `Bateria de testes — Vinícius — 17 a 21/08 — pré-lançamento`.

---

## 1. Qual é o seu olhar

Você não está caçando erro de programação. Você está respondendo **uma
pergunta só**:

> **O sistema dá conta da rotina real de uma clínica?**

Falta campo? Falta uma etapa? O fluxo bate com o que você vê na consultoria?
Um sistema pode não ter nenhum erro técnico e mesmo assim ser inútil para
quem atende paciente — é exatamente isso que só você consegue enxergar.

Você é o **primeiro** a testar, e a ordem tem motivo: falha de regra de
negócio muda tela, e não adianta avaliar a beleza de uma tela que ainda vai
mudar. O Erick vem depois, de 24 a 26, olhando fluidez e experiência sobre a
versão já corrigida.

---

## 2. A regra de classificação

Na dúvida, marque **bug**.

| Tipo | Quando usar | O que acontece |
|---|---|---|
| **Bug** | O sistema faz algo errado, ou não faz o que deveria fazer. | Correção imediata, antes do lançamento. |
| **Backlog** | O sistema faz certo, mas você gostaria que fizesse diferente ou a mais. | Fica registrado e entra depois do lançamento. |

Nada novo entra agora. Se é ideia boa mas não impede a clínica de operar, é
backlog — e backlog não é rejeição, é fila.

Existe uma **trava de lançamento**: a contagem de bugs abertos marcados como
"Atrapalha muito" precisa chegar a zero antes de abrirmos para cliente. É por
isso que preencher essa marcação direito importa mais do que escrever bonito.

---

## 3. Antes de começar — leia, são 2 minutos

### 3.1 · Crie uma clínica nova, sua

**Não teste no dado que já está lá.** O ambiente tem cerca de 16 clínicas de
teste antigas, com dado bagunçado de várias tentativas. Testar em cima
daquilo faz você perder tempo entendendo lixo que não é seu.

Faça o cadastro do zero, como uma clínica de verdade faria, e rode tudo
dentro dela. O primeiro cadastro **já é o primeiro teste**: anote quanto tempo
levou e o que te confundiu.

### 3.2 · Três coisas que já sabemos — não precisa apontar

1. **Listas aparecendo vazias.** Pacientes e Consultas já vêm com o filtro de
   período em "Este mês". Se o cadastro é antigo, a tela diz "Nenhum paciente
   encontrado" mesmo tendo gente lá. Troque o período para um mais amplo e
   tudo aparece. Já está na fila de ajuste.
2. **Tela branca no primeiro acesso.** Às vezes a página abre toda branca na
   primeira vez. Recarregue (F5) e funciona. Conhecido.
3. **Filtro de período diferente de uma tela para outra.** O Dashboard oferece
   certas opções, Consultas oferece outras, e o Fluxo de Caixa nem tem — lá são
   duas caixinhas, mês e ano. Conhecido.

Se algo **parecido mas diferente** acontecer, aponte. A dúvida joga a favor de
apontar.

### 3.3 · O que sempre vale apontar

- Travou, deu erro, sumiu, não salvou
- Conta ou valor que não bate
- Passo da rotina da clínica que o sistema **não deixa** fazer
- Campo que falta para registrar algo que toda clínica registra
- Nome de tela, botão ou coluna que confunde
- Qualquer lugar onde o fluxo foge de como uma clínica de verdade trabalha

---

## 4. O roteiro, dia a dia

Siga a ordem. Cada dia monta em cima do anterior, igual à rotina real.

Em cada item: **faça** → **confira** → e responda a **pergunta de gestão**, que
é onde mora o seu valor.

---

### Dia 1 · 17/08 — Nascer a clínica

**Faça:** cadastro da clínica do zero. Depois vá em **Configurações** e
preencha tudo que uma clínica preencheria antes de abrir a porta: dados,
especialidades, procedimentos e preços, formas de pagamento, horários,
profissionais. Por fim, em **Equipe**, convide um segundo acesso (pode ser um
e-mail seu alternativo) no papel de secretária.

**Confira:**
- O que você cadastrou continua lá depois de sair e voltar?
- A secretária que você convidou consegue entrar?
- Com o acesso de secretária, o que ela **vê** e o que ela **não vê**? Ela
  alcança o financeiro? Deveria?

**Pergunta de gestão:**
> Uma clínica consegue se configurar sozinha, sem ninguém explicando? Faltou
> algum cadastro que toda clínica tem — convênio, sala, equipamento, tipo de
> retorno?

---

### Dia 2 · 18/08 — O paciente chega

**Faça:** em **Atendimentos**, cadastre 3 ou 4 interessados como chegam na
vida real (indicação, Instagram, telefone) e mova pelo funil. Leve um deles
até virar consulta agendada. Depois vá em **Pacientes** e cadastre um paciente
completo. Em **Anamnese**, envie um formulário para esse paciente e
**preencha-o como se fosse ele**, pelo link.

**Confira:**
- A origem do paciente ficou registrada de forma que dê para saber, depois,
  de onde vem quem fecha?
- O que o paciente respondeu na anamnese aparece na ficha dele?
- Dá para ver a lista de quem ainda não respondeu?

**Pergunta de gestão:**
> O funil corresponde a como uma clínica realmente capta? Faltou etapa —
> orçamento enviado, em negociação, perdido com motivo? A anamnese cobre o que
> a especialidade precisa perguntar?

---

### Dia 3 · 19/08 — A agenda gira

**Faça:** agende consultas para os pacientes criados — inclusive uma para
**amanhã** e uma para **semana que vem**. Passe uma consulta por todos os
estados: confirmada, compareceu, não compareceu, cancelada. Registre o que foi
feito e o valor. Em **Tarefas**, veja o que o sistema gerou sozinho e crie uma
tarefa manual (ligar para confirmar).

**Confira:**
- Dá para ver o dia de amanhã de forma útil para quem vai confirmar por
  WhatsApp de manhã?
- Um "não compareceu" muda alguma coisa no resto do sistema, ou morre ali?
- A consulta atendida virou dinheiro a receber automaticamente?

**Pergunta de gestão:**
> A agenda serve para **operar o dia**, ou só para registrar depois? O que a
> secretária precisa ver às 8h da manhã está numa tela só? Falta bloqueio de
> horário, encaixe, retorno, lista de espera?

---

### Dia 4 · 20/08 — O dinheiro

**Faça:** em **Contas a Receber**, encontre o que as consultas geraram; receba
uma à vista, deixe outra vencer e parcele uma terceira. Em **Contas a Pagar**,
lance uma despesa fixa (aluguel) e uma variável (material). Abra o **Fluxo de
Caixa** e leia o mês.

**Confira:**
- A soma bate com o que você registrou? Confira na mão.
- Uma consulta cancelada sumiu do que há para receber, ou ficou cobrando?
- O que a clínica deve ao médico parceiro (repasse) aparece em algum lugar?

**Pergunta de gestão:**
> Esta é a área mais importante para o nosso posicionamento. O dono da clínica
> consegue responder, olhando estas telas: **quanto entrou, quanto falta
> entrar, quanto sai, e o que sobra?** Se não consegue, aqui é o apontamento
> mais valioso da bateria inteira.

---

### Dia 5 · 21/08 — A leitura e o veredito

**Faça:** abra o **Dashboard** e depois **Relatórios**, um por um. Leia
**Insights IA**. Por último, volte ao **começo**: entre com o acesso de
secretária e tente fazer o dia dela.

**Confira:**
- Os números do Dashboard batem com o que você lançou a semana inteira?
- Algum relatório mostra número que você sabe que está errado?
- A secretária consegue trabalhar sem esbarrar em bloqueio que não faz sentido
  — e sem alcançar o que não deveria?

**Pergunta de gestão final — escreva a resposta no Notion, na sua página:**
> Você entregaria este sistema para uma clínica cliente sua na segunda-feira?
> Se não, **o que exatamente** impede? Se sim, o que você avisaria antes?

---

## 5. Um item de segurança, do seu jeito

Não precisa entender de tecnologia para testar o que mais importa aqui:
**uma clínica jamais pode ver o dado de outra.**

Faça este teste no Dia 5, leva 3 minutos:

1. Anote o endereço (URL) de um paciente seu — a parte final, com números e
   letras.
2. Saia da sua clínica e entre com um acesso de outra clínica de teste.
3. Cole aquele endereço na barra do navegador.

**O esperado é não achar nada** — erro, tela vazia ou "sem permissão". Se
aparecer o seu paciente, **pare o teste e me avise imediatamente**, por
telefone. Não registre no Notion: isso é a coisa mais grave que pode
acontecer neste produto e não deve ficar escrito em lugar compartilhado.

---

## 6. Como registrar

Tudo vai para a base **Apontamentos** no Notion. Cada rodada de teste ganha a
sua própria página lá dentro, com nome que identifique o evento e a data — a
sua é `Bateria de testes — Vinícius — 17 a 21/08 — pré-lançamento`. É isso que
permite saber depois de onde veio cada apontamento e priorizar a correção.

Dentro da sua página, registre o que encontrar. Cada apontamento precisa de
quatro coisas, e só:

| Campo | O que escrever |
|---|---|
| Onde aconteceu | a tela (ex.: Contas a Receber) |
| O que eu fiz | os passos, na ordem |
| O que aconteceu | o que você viu |
| O que eu esperava | o que deveria ter acontecido |

Depois classifique — **Bug** ou **Backlog**, na dúvida Bug — e marque se
**atrapalha muito**. É essa marcação que alimenta a trava de lançamento.

Você pode escrever direto no Notion, ou descrever o problema para o **Claude
Code na pasta do projeto** e pedir que ele escreva o registro: a skill
`nx-apontamento` já conhece o sistema e devolve o bloco no formato certo,
pronto para colar. Ele também te avisa quando o que você viu é um dos três
não-bugs conhecidos.

**Print ajuda muito.** Se der, cole na página.

Se travar de vez e não conseguir seguir, pule para o dia seguinte e registre o
travamento — não perca o dia tentando contornar.

## 7. O que acontece depois

- **22 e 23/08** — Arthur corrige tudo que virou bug.
- **24 a 26/08** — Erick roda a bateria dele sobre a versão já corrigida.
- **01/09** — lançamento.

Sua bateria é a que define o que é corrigido. Um apontamento seu que ninguém
mais faria vale mais que dez erros de digitação que qualquer um acharia.
