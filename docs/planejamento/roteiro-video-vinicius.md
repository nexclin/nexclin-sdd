# Roteiro do vídeo — preparar o Vinícius para a bateria

> **Para quem grava:** Arthur. **Duração alvo:** 7 a 9 minutos.
> **Objetivo:** o Vinícius termina o vídeo com a ferramenta instalada, o
> roteiro de teste anexado e sabendo o que fazer na segunda de manhã.
> **Grave com a tela do jeito que ele vai ver** — não use atalho de
> desenvolvedor, não abra terminal.

---

## Decisão antes de gravar

**Ele não precisa do Claude Code.** Claude Code é ferramenta de terminal, feita
para programar — instalar aquilo nele é criar dificuldade sem retorno. O que ele
precisa é do **Claude no aplicativo de computador** (ou pelo navegador), onde
anexar um arquivo e conversar é arrastar e escrever.

Se ele já usa o Claude pelo navegador e não quiser instalar nada, o vídeo
continua valendo — pule o bloco 2 e diga isso em voz alta.

---

## Bloco 1 · Por que ele está fazendo isso (40 s)

Fale por cima da tela do NexClin aberto.

> "Vinícius, de segunda a quinta você vai usar o NexClin como se fosse a rotina
> de uma clínica sua. Não é para caçar erro de programador — é para responder
> uma pergunta: **o sistema dá conta da rotina real de uma clínica?** Falta
> campo, falta etapa, o fluxo bate com o que você vê na consultoria. Isso só
> você enxerga. São uns 45 minutos por dia."

Diga também, porque economiza uma hora dele:

> "Você é o primeiro a testar. O Erick vem depois, olhando outra coisa. Por isso
> não se preocupe com beleza de tela — foque em se a clínica consegue operar."

---

## Bloco 2 · Instalar o Claude (2 min)

Mostre a tela inteira, devagar.

1. Abrir o navegador e ir em **claude.ai**
2. Clicar em criar conta ou entrar — mostre que o plano gratuito serve
3. Baixar o aplicativo de computador (menu de download no próprio site)
4. Instalar e abrir
5. Entrar com a mesma conta

> "Pode usar direto pelo navegador se preferir. O aplicativo só é mais
> confortável porque fica na barra de tarefas."

**Não mostre** chave de API, terminal, nem configuração técnica. Nada disso é
necessário.

---

## Bloco 3 · Anexar o roteiro de teste (1 min 30 s)

Este é o bloco mais importante do vídeo. Vá devagar.

1. Mostre o arquivo **`bateria-testes-vinicius-17-21.md`** na pasta de downloads
   dele (mande o arquivo antes de gravar, para ele já ter)
2. Abrir uma conversa nova no Claude
3. **Arrastar o arquivo** para dentro da conversa (ou usar o clipe de anexo)
4. Escrever a primeira mensagem junto com o anexo. Dite esta, devagar, e deixe
   na descrição do vídeo para ele copiar:

> Este é o roteiro da bateria de testes que eu vou rodar no NexClin de 17 a 21
> de agosto. Leia e me diga o que eu faço hoje, no Dia 1. Vá me acompanhando um
> passo por vez e, quando eu encontrar alguma coisa, me ajude a escrever o
> apontamento do jeito que a planilha pede.

5. Mostre a resposta chegando e diga: "pronto, é assim que funciona — ele já
   sabe tudo que você precisa fazer na semana."

> "Toda vez que você abrir uma conversa nova, anexe esse arquivo de novo. Ele
> não lembra da conversa anterior."

---

## Bloco 4 · Criar a clínica dele no NexClin (2 min)

Mostre na tela, fazendo você mesmo um cadastro de exemplo.

1. Abrir **nexclin.lovable.app**
2. Fazer o cadastro **do zero**, como uma clínica de verdade faria
3. Dizer, com todas as letras:

> "Não teste na clínica que já está lá. Tem uma penca de clínica de teste antiga
> com dado bagunçado, e você vai perder tempo tentando entender lixo que não é
> seu. Crie a sua, do zero. **O próprio cadastro já é o primeiro teste** — anote
> quanto tempo levou e o que te confundiu."

---

## Bloco 5 · Os três já-sabemos (1 min)

Mostre cada um acontecendo, se der. Se não der, só descreva.

1. **Lista aparecendo vazia** — o filtro vem em "Este mês" e o cadastro some.
   Trocar o período resolve.
2. **Tela branca no primeiro acesso** — recarregar com F5 resolve.
3. **Filtro de período diferente de uma tela para outra.**

> "Esses três a gente já anotou. Se acontecerem, não precisa registrar. Qualquer
> outra coisa, registra — na dúvida, registra."

---

## Bloco 6 · A planilha e a regra (1 min 30 s)

Abra a planilha na tela e mostre as abas.

> "Tudo que você achar vai aqui. E tem uma regra só, que o Erick definiu:"

- **Bug** — o sistema faz errado, ou não faz o que deveria. Corrijo antes do
  lançamento.
- **Backlog** — funciona, mas você faria diferente ou queria mais. Fica na fila
  para depois do lançamento.
- **Na dúvida, marque bug.**

Mostre a coluna de "atrapalha muito" e explique:

> "Essa coluna alimenta um contador de trava de lançamento. É o número de bugs
> que impedem a clínica de operar, e ele precisa chegar a zero antes de a gente
> abrir para cliente. Então marcar direito aqui é o que decide o que eu corrijo
> no fim de semana."

---

## Bloco 7 · Fechamento (30 s)

> "Comece segunda. Se travar de vez em algum ponto, pula para o dia seguinte e
> registra o travamento — não perca o dia tentando contornar. Qualquer dúvida me
> chama direto. E se aparecer alguma coisa que pareça grave de verdade, tipo
> você ver dado de uma clínica que não é a sua, **me liga**, não escreve na
> planilha."

---

## Antes de apertar gravar — conferir

- [ ] O arquivo `bateria-testes-vinicius-17-21.md` já foi enviado a ele
- [ ] A planilha de apontamentos já foi distribuída no grupo
- [ ] Você tem uma clínica de exemplo para mostrar o cadastro sem expor dado real
- [ ] A mensagem inicial do Bloco 3 está copiada na descrição do vídeo
