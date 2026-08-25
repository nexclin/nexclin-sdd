# Mensagem para o grupo, 25/08/2026

> Rascunho para o Arthur enviar. Não foi enviada por mim.
> Anexar junto: `docs/planejamento/openclinic-analise-2026-08-25.md`.

---

Pessoal, fechando o que ficou de ontem.

**1. Lançamento em 08/09.** Concordo com o adiamento. Com os fundadores em
evento e viajando essa semana, abrir dia 01 seria gastar a primeira impressão
com quem não ia olhar. A bateria do Erick segue nos dias 24 a 26, sem mudança.

**2. Gestão de resíduos e MTR. A especificação já está escrita.**

O que o levantamento das normas confirmou, e é o que dá pé no assunto:

• O MTR é obrigação de quem gera o resíduo, não da empresa que coleta. Cada
coleta precisa do seu.
• Existe uma declaração trimestral, a DMR, com data fixa em abril, julho,
outubro e janeiro. Enquanto ela fica pendente, o sistema do órgão **bloqueia a
emissão de qualquer documento novo**. Isso trava a papelada da clínica inteira.
• O CDF, que é o comprovante de destinação final, é justamente o que some.
Chega por e-mail do coletor e ninguém guarda.
• A guarda de tudo isso é de 5 anos.

Mudei uma coisa da proposta do vídeo, e acho importante explicar por quê. O
vídeo vende medo, "R$ 200 por mês pra não tomar multa da vigilância". A
pesquisa não sustenta esse argumento: a fiscalização é inconstante, a
exigência muda de estado pra estado, e o médico não sente essa dor. Então
tirei o medo e deixei o que sobra, que é operação pura: papelada que ninguém
acha na hora, custo mensal de coleta que ninguém acompanha, e um prazo federal
com data certa que ninguém lembra.

Sobre custo de fazer: **zero de crédito**. Hoje o nosso fluxo é commit direto
no repositório e depois publicação, e o banco migra inteiro pro sistema novo.
Então não é trabalho jogado fora, é trabalho feito uma vez só. A questão não é
se dá pra fazer, é a ordem.

**3. A ordem que eu proponho.** Fechar os módulos financeiros primeiro, que é
do que essa funcionalidade depende e é o nosso diferencial de verdade, e
emendar direto na execução da spec de resíduos.

**4. A pergunta que eu quero discutir com vocês: o que faz um plano valer mais
caro?**

Fui reler a nossa pesquisa de precificação e ela já tinha respondido parte
disso:

• 9 dos 10 concorrentes cobram por profissional de saúde e dão secretária de
graça. A gente cobra por usuário total. Na comparação direta, isso faz a
clínica achar que a gente cobra pela recepcionista.
• O nosso teto hoje é uns R$ 700 na faixa de 8 usuários. Acima disso a clínica
começa a comparar com Feegow VIP, que tem TISS, glosa e IA.
• O que derruba o nosso teto não é a falta de resíduos. É a falta de
**prescrição digital assinada**, que o iClinic entrega já no plano de R$ 99, e
a falta de prontuário.
• A própria pesquisa recomendou: no lançamento diferencia só por usuário
mesmo, e **depois do lançamento as funções novas entram como plano superior**.
É exatamente o encaixe do módulo de resíduos.

Então resíduos serve, mas como **um** degrau, não como o degrau. Se a gente
quer um plano caro que se sustente sozinho, a fila por valor de mercado é
prescrição digital, prontuário, TISS, e resíduos junto com eles.

Respondendo a mim mesmo sobre divulgação: não tem a quem divulgar ainda. Nesse
momento eu prefiro focar em fazer, e depois montar uma prospecção mais ampla,
pra gente conseguir conversão direta.

**5. O OpenClinic que o Erick lembrou.**

Li o repositório inteiro. Sendo direto: **não tem uma linha de código.** É um
projeto de 14 dias, com 3 pessoas no histórico do GitHub e 13 estrelas. Os 40
desenvolvedores são o tamanho do grupo de WhatsApp deles, não do projeto.

Mesmo assim a documentação é muito boa e já rendeu duas coisas:

• Eles mapearam os 256 requisitos da certificação SBIS, que é a certificação
de prontuário. Usei a lista como espelho e achei brechas nossas. A mais séria
eu já confirmei no código: hoje qualquer pessoa da equipe consegue alterar as
próprias permissões e o próprio percentual de repasse. Não vaza dado entre
clínicas e não passa do que o plano libera, mas na prática a secretária pode se
dar acesso de dono. Está registrada e vai ser corrigida no sistema novo. Não
vou mexer nisso na semana do lançamento.
• Eles têm controle de estoque ligado ao procedimento e pacote de sessões com
saldo. Estética e odonto vendem quase tudo em pacote, e material é custo direto
que ninguém mede. Na minha leitura isso vale mais dinheiro que resíduos.

Um cuidado que vale pra todos nós: a licença deles é AGPL. Na prática, se
qualquer linha de código ou trecho de texto deles entrar no nosso sistema, a
gente fica obrigado a abrir o nosso código inteiro. Então a regra é ler,
aprender e refazer com as nossas palavras. Copiar nada.

Vou anexar aqui o documento completo da análise que montei do OpenClinic.
Queria que vocês lessem e avaliassem comigo o que dá pra aproveitar sem nos
colocar em saia justa, e o que a gente descarta de vez.
