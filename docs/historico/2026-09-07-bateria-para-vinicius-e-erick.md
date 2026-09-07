# Bateria de teste para o Vinicius e o Erick, 07/09/2026

**Tudo que esta aqui ja esta publicado e no ar.** Sao onze verificacoes, e
nenhuma exige conhecimento tecnico. Leva cerca de vinte minutos.

**Como responder cada item:** escreva **PASSOU** ou **FALHOU**. Em caso de
falha, diga **o que apareceu na tela**, e nao o que voce acha que causou. O
numero errado e a informacao; o palpite sobre a causa atrapalha a busca.

**Um aviso que evita reprovar coisa certa:** a clinica de teste foi povoada com
dados de **julho e agosto**. Setembro esta quase vazio de proposito. Numero
baixo em setembro nao e defeito por si so; os itens abaixo dizem quando o zero
e esperado.

---

## Bloco 1, Fluxo de Caixa. E o que mais mudou

**1. Os dois modos existem e trocam.**
Abra Financeiro, depois Fluxo de Caixa. No alto a direita ha dois botoes,
**Realizado** e **Previsto**. Realizado vem marcado.
*Passa se:* clicar em um e no outro muda os numeros e o grafico.

**2. Realizado nao inventa dinheiro.**
Com **Realizado** marcado, olhe "Entradas recebidas".
*Passa se:* o numero estiver **perto de zero** em setembro, com a nota "so o
que foi baixado" embaixo do rotulo.
*Falha se:* aparecer valor alto. Isso significaria que promessa esta entrando
como caixa, que e exatamente o que esta correcao removeu.

**3. Previsto mostra o que Realizado esconde.**
Clique em **Previsto**.
*Passa se:* "Entradas previstas" subir para a casa das **centenas de milhares**,
com a nota "inclui vencido".
*Isto e o esperado, e nao um erro:* ali entram os recebiveis que venceram e
ninguem pagou.

**4. O calendario e o unico seletor.**
*Passa se:* nao existirem mais as caixas de **mes** e de **ano**, e o periodo
for escolhido so pelo botao com a data.
Escolha uma semana qualquer. *Passa se:* grafico e tabela passarem a mostrar so
aquela semana, e o botao **Este mes** aparecer para desfazer.

**5. Saldo atual nao muda com o periodo.**
Troque o periodo duas ou tres vezes.
*Passa se:* o quadro **Saldo atual** ficar parado. Ele responde quanto ha na
conta agora, e nao pode depender do mes que voce escolheu olhar.

## Bloco 2, o dinheiro que entra

**6. A baixa registra o que o banco creditou.**
Va em Contas a Receber, escolha uma linha pendente e de baixa. Onde diz **Valor
efetivamente recebido**, troque o valor sugerido por um **menor**, por exemplo
de R$ 100,00 para R$ 97,00. Confirme.
*Passa se:* na lista, a linha continuar mostrando **R$ 100,00** com um
**"recebido R$ 97,00"** embaixo, em letra menor.
*Por que assim:* R$ 100 e o que a clinica tinha a receber, R$ 97 e o que entrou.
Os dois sao verdade e a tela mostra os dois.

**7. A taxa de antecipacao nao se digita mais.**
Na mesma tela de baixa, ligue **Antecipacao de valores**.
*Passa se:* a taxa aparecer como **texto, sem campo para digitar**, dizendo que
vem da forma de pagamento cadastrada. Se nao houver taxa cadastrada, tem de
aparecer um aviso dizendo onde cadastrar.
*Falha se:* ainda der para digitar um percentual ali.

**8. O relatorio concorda com a tela.**
Depois do item 6, abra Relatorios, depois Contas a Receber.
*Passa se:* o **Total Liquido** usar o valor recebido de verdade, os R$ 97,00, e
nao o previsto.

## Bloco 3, o resto

**9. Insights para de dizer que a clinica esta no prejuizo.**
Abra Insights IA e gere um insight.
*Passa se:* o texto **nao** afirmar que a clinica teve receita zero ou que esta
no prejuizo por falta de faturamento.
*Falha se:* ele falar em receita zero. Era o defeito principal, e atingia toda
clinica.

**10. A barra lateral nao pula ao abrir.**
Clique na setinha que abre e fecha a barra lateral, umas tres vezes, olhando
para os icones.
*Passa se:* os icones ficarem **parados no lugar**, so aparecendo o nome ao
lado. Abra tambem o grupo Financeiro.
*Passa se:* **nenhuma barra de rolagem** aparecer dentro da barra lateral, mesmo
que a lista fique maior que a tela. Rolar com a roda do mouse tem de funcionar.

**11. Recall mudou de lugar.**
*Passa se:* **Recall** aparecer no menu logo abaixo de **Pacientes**, e **nao**
mais dentro do grupo Financeiro.

---

## O que NAO precisa ser testado agora

- **Precificacao, Insumos e Salas** estao ocultas no menu de proposito.
- **Numeros do dashboard contra o banco**: ja foram conferidos em 07/09, um a
  um, e o registro esta em
  [`2026-09-07-conferencia-numeros-contra-o-banco.md`](2026-09-07-conferencia-numeros-contra-o-banco.md).
- **Permissao por modulo no financeiro**: sabidamente incompleta, e depende de
  um segundo usuario que ainda nao existe. E o FR-011, e ja esta registrado.
