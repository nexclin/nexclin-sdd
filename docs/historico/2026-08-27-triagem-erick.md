# Triagem: vídeo do Erick, Rev02 (transcrito em 27/08/2026)

> Fonte: `Rev02 - NexClin - Erick Reis.pdf`, transcrição TurboScribe de um dos
> dois vídeos gravados. **O segundo vídeo não foi transcrito** e continua
> pendente. Numeração E-01 em diante, reservada desde 20/08.

## O achado que muda a expectativa deste documento

**Este vídeo não tem nenhum bug.** A lista de pendências vinha esperando uma
bateria de teste, e o que chegou é orientação de método, mais cinco pedidos de
funcionalidade. Nenhum item é "o sistema faz algo errado".

Isso importa por causa da regra de precedência que estava valendo: *bug de quem
testou tem precedência sobre funcionalidade nova*. Com zero bugs aqui, a
precedência não é acionada, e a fila não muda por causa deste vídeo. **Se houver
bateria de bugs, ela está no vídeo que falta.**

## Como este documento classifica

A faixa A, B e C da §2.5 do `CLAUDE.md` decidia *se* corrigir na Lovable. Desde
a inversão de 26/08 essa pergunta está respondida: toda especificação definida é
implementada na Lovable. Então a coluna que resta é **quando**, e a única razão
para adiar é dependência, não plataforma.

---

## E-01. Popular o banco com dados realistas, via SQL

**O que ele pede.** Que o sistema seja povoado com dois meses de operação
simulada antes da próxima bateria, gerada por SQL a partir de um contexto de
mercado. O exemplo que ele deu: *"uma clínica que fatura entre 200 e 300 mil,
dois meses seguidos, ticket médio de X"*.

**Por que ele pede, e a razão é boa.** Sistema vazio esconde a classe de defeito
que só aparece com volume. Ele nomeia três: paginação que não existe, espaço de
tela desperdiçado, e relatório cujos números não fecham com o que foi lançado.
Nenhum dos três é encontrável em base vazia, e os três são caros de descobrir
com cliente dentro.

Ele também condiciona a própria participação a isto: a bateria maior dele só
rende *"quando vier com dados populados"*.

**Classificação:** instrumento de teste, não funcionalidade. Não tem tela, não
tem regra de negócio, e não atravessa para a stack nova como código.

**O risco que precisa ser resolvido antes, e ele é de dado e não de esforço.**
O banco da Lovable é o mesmo que recebe o cliente fundador em 08/09, e o mesmo
que **migra intacto** em outubro (§2.4). Dado falso inserido agora não é
descartado na migração: é importado. A §2.5 já registra a estimativa de
R$ 100 mil a R$ 200 mil de faturamento real lançado por clínica no período, e
misturar simulação com isso contamina exatamente o número pelo qual o produto
foi vendido.

**Condições para executar, e as três são inegociáveis:**

1. **Clínica dedicada.** Todo dado simulado nasce sob um `clinic_id` só, de uma
   clínica marcada como demonstração. O isolamento já existe e é o RLS, que é a
   garantia mais forte disponível aqui.
2. **Expurgo escrito antes do povoamento.** O script que apaga sai junto com o
   que insere, e é testado antes. Povoar sem saber desfazer é o caminho para o
   dado falso sobreviver até outubro.
3. **Nunca sob a clínica de um cliente real.** Nem para demonstração, nem para
   teste rápido.

**Estado:** aceito, com as três condições. Depende de decidir o volume e o
contexto de mercado, que é decisão de negócio e não de engenharia.

---

## E-02. Não se sabe qual usuário está logado

**O que ele relata.** Não há indicação de quem está na sessão. Ele mostra que no
INI isso ficava à direita, e que foi movido para a base da barra lateral.
Pergunta também se é possível configurar foto.

**Classificação:** interface. Pequeno, e é o único item deste vídeo que é reparo
de algo ausente em vez de pedido novo.

**Convergência que vale registrar:** o E-06 abaixo e o pedido de barra lateral
que o Arthur trouxe em 27/08 mexem na mesma região da tela. Os três devem entrar
juntos, porque três alterações separadas na mesma barra custam três revisões.

---

## E-03. Comentário no registro, com citação de departamento

**O que ele descreve.** No painel de produção do INI, abrir um registro abre um
campo de comentários com o histórico inteiro à vista, onde se comenta e se cita
um departamento.

**Por que existe:** comunicação entre departamentos sem sair do registro que a
motivou.

**Classificação:** funcionalidade nova, transversal. Não pertence a nenhuma das
15 ModuleKeys de forma óbvia, e é aí que mora a decisão: comentário em registro
serve consulta, tarefa, orçamento e conta a pagar ao mesmo tempo.

**Estado:** precisa de spec própria. Não entra antes de 08/09 sem cortar outra
coisa, e o corte é decisão do Arthur.

---

## E-04. Relatório que explode custo por centro de custo

**O que ele descreve.** DRE por centro de custo, com capacidade de abrir cada
despesa e ver o custo atribuído, para auditar a qualidade do próprio relatório.

**Por que este é o item mais bem posicionado da lista.** Ele encontra duas
coisas que já estão em fila:

- **Centros de custo** é o único item "importa" da modelagem ainda não
  implantado, já registrado como pendência.
- A §2.5 tem uma exceção nomeada para **relatório**: o time do Vinícius não usa
  o dashboard, puxa as bases pelos relatórios toda semana e decide em cima
  delas. Relatório errado vira decisão errada.

Ou seja, dois testadores diferentes chegaram ao relatório por caminhos
independentes, um pedindo estrutura de custo e o outro operando por ele.

**Classificação:** banco mais relatório. Atravessa inteiro para a stack nova.

**Estado:** é o candidato mais forte da lista para entrar antes de 08/09.

---

## E-05. Plano de carreira e tabela salarial por cargo

**O que ele descreve.** Gestão de colaboradores com plano de carreira, cargos,
níveis e tabela salarial por nível, já povoada no INI dele.

**Classificação:** funcionalidade nova sobre `team_members`, que hoje guarda
papel operacional e repasse médico, e não remuneração fixa.

**Observação de escopo, e ela é a que decide.** Isto é folha e cargo, que é
gestão de pessoas e não gestão clínica. O critério do produto (§1) é aumentar
receita, reduzir custo, economizar tempo ou melhorar decisão da clínica. Tabela
salarial passa no critério pela via do custo, e é justamente o que alimenta o
E-04: sem custo de pessoa por cargo, o rateio do centro de custo é digitado à
mão.

**Estado:** depende do E-04. Especificar os dois juntos ou nenhum.

---

## E-06. A tela perde espaço

**O que ele diz:** *"quando você precisar fazer um trabalho numa tela, qualquer,
olhar essa tela aqui, você percebe que você tá perdendo muito espaço"*.

**Classificação:** interface, e é o item deste vídeo com a maior convergência
externa. No mesmo dia, sem ter visto o vídeo, o Arthur relatou o efeito concreto
disso na barra lateral: o grupo financeiro passou de 3 itens para 9 com a
modelagem, e a barra estendeu.

Dois relatos independentes do mesmo problema mudam a natureza dele. Deixa de ser
preferência de layout e passa a ser defeito observado por quem usa.

**Estado:** entra junto com o E-02, na mesma alteração da barra lateral.

---

## E-07. Varredura de erros por IA sobre a base povoada

**O que ele propõe.** Depois de povoar, pedir uma varredura automatizada de erros
e de lógica sobre o sistema cheio, e a conta que ele faz é explícita: a varredura
acha quinze dos vinte, os mais simples, e sobra ao humano os cinco que exigem
julgamento.

**Classificação:** método de trabalho, não item de produto. Depende do E-01,
porque varrer base vazia não produz nada.

**Estado:** registrado. Não consome janela agora.

---

## Resumo

| Item | O quê | Natureza | Depende de |
|---|---|---|---|
| E-01 | Povoar o banco via SQL | Instrumento | Decisão de volume, e as três condições de isolamento |
| E-02 | Quem está logado | Interface | Entra com E-06 |
| E-03 | Comentário com citação | Funcionalidade nova | Spec própria |
| E-04 | DRE por centro de custo | Banco e relatório | Centros de custo |
| E-05 | Plano de carreira | Funcionalidade nova | E-04 |
| E-06 | Perda de espaço na tela | Interface | Entra com E-02 |
| E-07 | Varredura por IA | Método | E-01 |

**Bugs nesta leva: zero.** A trava de lançamento não se move por este vídeo.

**Pendente:** a transcrição do segundo vídeo. Se a bateria de bugs existe, está
lá, e ela tem precedência sobre tudo nesta tabela.
