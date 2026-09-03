# Pauta da reunião, 03/09/2026

> **Cinco dias para o lançamento de 08/09.**
>
> Documento para conduzir a reunião, e não para ser lido em voz alta. Cada bloco
> tem uma pergunta que precisa sair da sala respondida, e um responsável.

---

## Como conduzir

A reunião tem três partes, nesta ordem, e a ordem importa:

1. **o estado real do sistema**, com número, porque é o que alinha expectativa;
2. **o que cada um precisa entregar até 08/09**, com nome e prazo;
3. **a participação societária**, por último, porque ela se apoia nas duas
   primeiras e não no contrário.

**Não abra pela participação.** Quem chega cobrando prazo dos outros já está na
mesa como sócio; quem chega defendendo o próprio percentual está pedindo.

---

## Parte 1: onde o sistema está, de verdade

### O que mudou desde 23/07

| | Antes de 23/07 | Depois |
|---|---|---|
| commits diretos de pessoa na plataforma | **1** em 1205 | **73** |
| repositório de especificação | não existia | **198 commits** |
| testes automatizados | praticamente zero | **233** |
| regras de negócio escritas | zero | **20** |
| migrações de banco | 42, todas geradas por prompt | **+39** |
| trilha de auditoria de prontuário | não existia | existe e foi provada |

### A frase que alinha a expectativa

O sistema parecia **90% pronto** porque tinha todas as telas. O que faltava não
era tela: era **tudo que só aparece quando alguém usa e confere o número**.

Mais de **sessenta defeitos** apareceram desde 23/07, entre os relatados nas
baterias e os achados na varredura. Nenhum deles era visível abrindo o sistema.

### O que está pronto, e para quê

| Pronto para | Estado |
|---|---|
| demonstrar a um cliente | **alto** |
| um fundador operar a clínica por um mês | **quase**, e o que falta está na Parte 2 |
| ser o produto final | **baixo, e por desenho.** A Lovable é ponte e será substituída em outubro |

**A terceira linha é a que evita a discussão errada.** A plataforma atual não
precisa ficar pronta: precisa **atravessar um mês**. Medi-la contra "produto
final" foi o erro de expectativa original.

---

## Parte 2: o que cada um entrega até 08/09

### Arthur

| # | O que | Por quê |
|---|---|---|
| 1 | corrigir a macro categoria dos serviços de **Clínica Davi Moraes** e **Clínica Dra. Duda Gonçalves** | as duas **não conseguem agendar** hoje. Cada uma tem um serviço com a macro em branco |
| 2 | conferir a clínica com assinatura **`cancelled`** | o dono dela não abre nada, por desenho. Se for cliente real, está trancado |
| 3 | trocar o nome do operador de "Dr. Erick Reis" para o seu | a trilha de leitura de prontuário registra o nome, e hoje atribui a outra pessoa |

### Vinícius

| # | O que | Por quê |
|---|---|---|
| 4 | **provar os três consertos financeiros** com números reais: entrada mais restante sem a pergunta, 3x no cartão espalhando no caixa, e o lançamento fechando a tela | ele achou os três porque sabe qual número deveria aparecer. Ninguém mais consegue provar isso |
| 5 | **provisionar uma clínica nova** e conferir que ela nasce usável | é o único jeito de saber se o provisionamento entrega conta que funciona |
| 6 | dizer **quais são as clínicas reais** entre as 22 do banco | metade tem nome de teste, e eu não sei distinguir |

### Erick

| # | O que | Por quê |
|---|---|---|
| 7 | **a questão contratual**, por escrito | é o item mais antigo em aberto, e o único que não depende de código |
| 8 | confirmar **preço e política de trial** | as 22 clínicas estão todas em "Trial Padrão". Ninguém definiu o que acontece quando o trial termina |

### Decisões que precisam sair da sala

| # | Decisão | Bloqueia |
|---|---|---|
| 9 | **a impersonação avalia como o cliente?** Hoje o operador vê módulo fora do plano do cliente | demonstração ao vivo mostrando o que a pessoa não comprou |
| 10 | **login compartilhado ou um por pessoa?** | com um login só, a trilha de prontuário não distingue quem acessou, e ela existe por exigência legal |
| 11 | **emenda à constituição** para o sininho de avisos | metade da regra 020 não pode ser construída sem ela |

---

## Parte 3: a participação

Ver [`2026-09-03-participacao-arthur.md`](2026-09-03-participacao-arthur.md),
que traz os números e o comando para reproduzir cada um.

**Uma linha para abrir o assunto:** *"antes de eu assumir havia um commit humano
direto em 1205. Hoje são 274, e 273 são da minha gestão."*

---

## Ressalvas, e elas protegem quem as diz

Levar isto de propósito é o que separa prestação de contas de venda.

**O que ainda não foi provado na tela:** os três consertos financeiros estão
publicados e cobertos por 18 testes, e ninguém confirmou o comportamento com
dado real. É o item 4 acima.

**O celular não ficou bom**, e foi tirado da prioridade por decisão consciente.
Não é surpresa, é escolha.

**O dashboard continua com um relato aberto** do Vinícius, sem número específico
para investigar.

**Duas migrações estão escritas e não aplicadas**, e uma delas é a que faz
clínica nova nascer com tipos de consulta.

---

## O que entrar como assunto novo

**Papo AI, API oficial de Meta Developers, conectada ao cloud.** Levantada pelo
Arthur. Entra como **pauta de exploração**, e não como decisão desta reunião: o
que se decide hoje é se alguém fica responsável por avaliar, e até quando.

A pergunta que a avaliação precisa responder, e que vale escrever antes de
qualquer teste: **o que ela resolve que o WhatsApp já integrado não resolve?**
Notificação ao paciente é paridade de mercado, e os concorrentes já entregam.
Se a resposta for "o mesmo, melhor", o custo de integrar não se paga antes de
outubro.
