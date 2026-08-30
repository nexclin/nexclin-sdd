# 018 · Funil de atendimentos

> **Regra viva.** Nasceu em 29/08/2026, de o Arthur operar o Kanban de
> atendimentos **pela primeira vez com base cheia**. Até aquele dia o funil
> estava vazio, e não por acaso: os 240 leads não apareciam em coluna nenhuma
> por causa do artefato 7 do povoamento, corrigido no mesmo dia.
>
> **Faixa das quatro:** todas são **requisito da stack nova**, e nenhuma sobe
> para a Lovable. Pelo corolário da §2.5, item de backlog não é trabalho
> adiado: é requisito da stack nova, e mora na regra do módulo em vez de dormir
> numa lista.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md`

---

## 1. O problema

O funil da tela de Atendimentos organiza o lead em cinco estágios e permite
arrastar entre eles. Ele responde **onde** o lead está. Não responde **há quanto
tempo**, não deixa remover cartão sem fricção, e com volume real empurra os
cartões para baixo da dobra.

**Este texto é de antes de perguntar ao Vinícius, e ficou parcialmente errado.**
O que ele respondeu em 29/08 mudou dois requisitos de lado, e as mudanças estão
marcadas onde acontecem. A parte que sobreviveu é a de densidade, e ela tem uma
ressalva que importa mais que ela mesma.

**A ressalva:** a lista que o Arthur viu gigante tinha **240 leads simulados,
48 por coluna**. Uma clínica fundadora começa em zero e leva semanas para ter
dezenas. Em 08/09 a coluna terá dois ou três cartões. Dimensionar a tela para
240 seria otimizar para um volume que não vai existir, e o custo disso é real:
tela desenhada para muito fica vazia e estranha com pouco.

O que **não** depende de volume é o desperdício de altura no topo, e é só isso
que o FR-006 trata.

---

## 2. Requisitos

### Responder há quanto tempo, e não só onde

- **FR-001**: O funil **MUST** trabalhar por CADÊNCIA, e não por tempo decorrido
  solto. Ele **MUST** dizer qual contato está vencido, e a cadência **MUST** ser
  editável por clínica.

  *Porquê, e isto veio do Vinícius em 29/08, corrigindo o que esta regra dizia
  antes:* a clínica dele não olha "há quantos dias esse lead está parado". Ela
  roda uma régua comercial de **três contatos, nos dias 1, 3 e 7**. Não
  respondeu aos três, encerra.

  A diferença não é de vocabulário. "Há dezoito dias em Novo Contato" é um
  número que a pessoa ainda precisa interpretar. "O segundo contato venceu
  ontem" é uma instrução. A primeira versão desta regra pedia a primeira coisa,
  e ela seria menos útil.

  **E a régua varia de clínica para clínica**, palavras dele. Então o número de
  contatos e os intervalos são **configuração**, e não constante no código. Isso
  tem casa: `business_rules` e a área de configurações da regra 005.

  **O relógio já existe.** `Atendimentos.tsx:250` grava `funnel_move` em
  `lead_history` a cada movimento, com `created_at`. Quando o lead entrou no
  estágio é a data do último `funnel_move`, e a cadência conta a partir dela.
  **Não exige coluna nova.**

- **FR-002**: O funil **MUST** distinguir lead encerrado por **desqualificação**
  de lead encerrado por **não resposta**.

  *Porquê:* são coisas diferentes e hoje caem no mesmo balde. Quando alguém
  procura uma especialidade que a clínica não atende, a atendente encerra na
  hora, e esse lead **nunca deveria entrar na cadência**. Já o que não respondeu
  aos três contatos encerra por esgotamento.

  Misturar os dois estraga as duas leituras: a taxa de conversão fica
  artificialmente baixa por causa de gente que nunca foi público, e o volume de
  "perdidos" deixa de dizer se o problema é o atendimento ou a origem do lead.

- **FR-003**: O histórico de movimentação **MUST** guardar o ESTÁGIO, e não a
  frase.

  *Porquê:* hoje `details` recebe `'Movido para ' || label`, texto livre. Para
  calcular tempo por estágio seria preciso extrair o estágio de dentro de uma
  frase em português, e renomear um rótulo na tela quebraria o cálculo em
  silêncio. É a mesma classe do artefato 3 do povoamento, em que descrição livre
  não casava com nome de serviço.

### Não remover, e é aqui que a regra mudou de lado

> **Esta seção foi INVERTIDA em 29/08/2026**, depois da resposta do Vinícius. A
> versão anterior pedia exclusão fácil no cartão, com desfazer de oito segundos,
> a pedido do Arthur. **Fica registrado que a versão anterior existiu**, porque
> a inversão é a informação, e não o texto final.

- **FR-004**: O funil **MUST NOT** oferecer exclusão de lead no cartão. O que
  ele **MUST** oferecer é **filtro e arquivamento**.

  *Porquê:* perguntado se apagam lead, o Vinícius respondeu que **não apagam
  nada**. Tudo fica na base e serve para análise, e o volume de leads chegando e
  a evolução da qualidade deles são o que a clínica usa **para cobrar do
  marketing**.

  Isso torna a exclusão fácil não apenas desnecessária: torna-a **danosa**. Um
  clique cômodo apagaria a série histórica com que a clínica negocia com o
  fornecedor dela. O problema que o Arthur descreveu, lista longa demais para
  enxergar, é real, e a resposta certa para ele é **filtrar**, e não remover.

  **A exclusão de lead que existe hoje continua sendo um defeito**, e piora com
  o que se sabe agora: `Atendimentos.tsx:268` apaga o `lead_history` antes de
  apagar o lead. Se ninguém deveria apagar, muito menos deveria apagar em
  silêncio a prova do que aconteceu.

- **FR-005**: A exclusão de lead, onde ela existir, **MUST NOT** apagar o
  histórico dele.

  *Porquê, e são dois porquês diferentes.*

  **O desfazer não é desfazer.** Hoje `deleteMutation` faz `DELETE` de verdade
  (`Atendimentos.tsx:266`). Linha apagada não volta. Então "desfazer em oito
  segundos" **não pode ser implementado como desfazer**: tem de ser
  **adiamento**. A tela remove o cartão na hora, segura a exclusão pela janela,
  e só executa quando ela expira. Quem cancela nunca chega a apagar nada.

  Fazer o contrário, apagar e tentar recriar, produziria um registro novo com
  `id` novo, e todo vínculo do antigo já teria cascateado embora.

  **E a exclusão hoje destrói prova.** A linha 268 faz
  `lead_history.delete().eq("lead_id", id)` **antes** de apagar o lead. Isso é
  redundante, porque `lead_history.lead_id` já tem `ON DELETE CASCADE`, e é
  danoso pelo mesmo motivo que o FR-005 da regra 017 recusou chave estrangeira
  para `patients`: **trilha que some junto com o que ela auditava não é
  trilha.**

  Tornar a exclusão mais fácil sem consertar isto multiplica a perda. É por
  isso que os dois estão no mesmo requisito, e não em dois.

### Caber na tela

- **FR-006**: O topo da tela de funil **MUST** caber junto com a primeira linha
  de cartões, sem rolagem.

  *Porquê:* hoje migalha, título, subtítulo e filtros consomem a altura toda, e
  os cartões começam abaixo da dobra. O usuário rola para ver o que a tela
  existe para mostrar.

  **Isto NÃO é sobre o tamanho dos ícones nem sobre o volume da lista.** É
  sobre o cabeçalho. Reduzir ícone para caber mais cartão seria otimizar para os
  240 leads simulados, e em 08/09 a coluna terá três.

---

## 3. O que muda no banco

**Quase nada, e é uma boa notícia.**

O **FR-001** lê `lead_history`, que já existe e já é povoado. O que ele
acrescenta é a CADÊNCIA como configuração: quantos contatos e em que intervalos,
por clínica. Isso mora onde as outras regras editáveis já moram, em
`business_rules`.

O **FR-002** precisa distinguir os dois encerramentos. Hoje `nao_agendou` é um
estágio só. Ou nasce um estágio novo, ou nasce um motivo de encerramento como
coluna. **A segunda é melhor:** motivo é dado, e estágio é posição no funil;
misturar os dois faria o Kanban crescer uma coluna a cada motivo novo.

O **FR-003** acrescenta `to_stage` em `lead_history`. Coluna anulável, então o
histórico antigo continua válido e o cálculo trata nulo como desconhecido.

O **FR-004** e o **FR-005** removem um `DELETE` do código e não acrescentam nada
ao banco.

---

## 4. Premissas

O funil tem cinco estágios, e eles são os do produto:
`novo_contato`, `em_atendimento`, `agendou`, `nao_agendou`, `recaptacao`. A
lista canônica está em `Atendimentos.tsx:179-183`.

**Escrever esses cinco aqui não é redundância.** Em 29/08 o povoamento inventou
outros cinco, e o efeito não foi número errado: foi o funil inteiro aparecer
vazio, com 240 leads na base. Vocabulário de estágio que não está escrito em
lugar nenhum é vocabulário que alguém reinventa.

---

## 5. Dependências

FR-001 depende de `funnel_move` continuar sendo gravado a cada movimento. Se um
caminho novo mover lead sem historiar, o tempo no estágio passa a mentir para
esses leads, e mentira parcial é pior que ausência, porque não se percebe.

---

## 6. Como se prova

- **FR-001:** com a régua de 1, 3 e 7 dias configurada, um lead que entrou há
  quatro dias tem de aparecer com o **segundo contato vencido**, e não com "há
  quatro dias". Trocar a régua para 2, 5 e 10 na configuração tem de mudar o que
  a tela diz, sem tocar em código.
- **FR-002:** encerrar um lead por especialidade não atendida e outro por não
  ter respondido, e os dois aparecerem separados na leitura, não somados.
- **FR-003:** ler `lead_history` e achar o estágio como dado, sem precisar
  interpretar a frase.
- **FR-004:** não existir caminho de exclusão no cartão, e existir filtro que
  esconda o que não interessa sem apagar.
- **FR-005:** apagar um lead por onde ainda der, e o `lead_history` dele
  continuar existindo.
- **FR-006:** abrir o funil numa tela de notebook e ver a primeira linha de
  cartões sem rolar.

---

## 7. O que falta decidir

**O motivo de encerramento é lista fixa ou texto livre?** Lista fixa se analisa e
texto livre não. Mas lista curta demais faz a atendente escolher "outro" sempre,
e aí a lista existe e não informa. Precisa vir de quem atende, e não daqui.

**A cadência é por clínica ou por origem do lead?** O Vinícius disse que a régua
varia de clínica para clínica. Falta saber se dentro da mesma clínica ela varia
por origem: lead de indicação e lead de tráfego pago talvez não mereçam a mesma
insistência.

**O que "arquivar" faz com o lead.** Some do Kanban e continua nos relatórios, ou
some dos dois? O FR-004 diz que não se apaga, e não diz onde o arquivado
aparece.

---

## 8. O que esta regra deixou de pedir, e por quê

Registrado porque a mudança de direção vale mais que o texto final, e porque
alguém vai perguntar por que a lixeira não foi feita.

**Exclusão fácil no cartão, com desfazer de oito segundos.** Pedida pelo Arthur
em 29/08 e escrita nesta regra no mesmo dia. Caiu quando o Vinícius respondeu
que a clínica **não apaga lead nenhum**, porque a base inteira é usada para
cobrar do marketing.

O problema que originou o pedido continua real: com volume, a coluna fica
ilegível. **A resposta mudou de "remover" para "filtrar".** Vale a pena separar
as duas coisas sempre que aparecer um pedido de exclusão: quase sempre o que
incomoda é a presença na tela, e não a existência do registro.
