# Kit de engenharia de harness para desenvolvimento com agentes de IA

> **Como usar:** anexe este arquivo à sua ferramenta de IA (Claude Code, Cursor,
> Copilot — o que vocês usarem) na **primeira** sessão do projeto e diga:
> *"Leia este kit e execute o Protocolo de Entrada no meu projeto."*
>
> Ele não é um tutorial para ler e esquecer. É um conjunto de instruções que a
> IA executa, mais os conceitos que explicam por que cada passo existe.

---

## Parte 1 — A ideia central

A maioria das equipes tenta melhorar o resultado da IA **escrevendo prompts
melhores**. Isso tem teto baixo: o prompt morre no fim da sessão.

Engenharia de harness é o contrário — você melhora o **ambiente** em que a IA
trabalha. O ambiente persiste. Um prompt bom serve uma vez; uma regra escrita no
lugar certo serve todas as vezes, inclusive quando quem a escreveu não está na
conversa.

São cinco peças, e a competência está em saber **qual** usar:

| Peça | Para quê | Sinal de que é essa |
|---|---|---|
| **Memória do projeto** | contexto que vale sempre | "a IA sempre esquece que..." |
| **Regra por área** | restrição que vale numa pasta | "em `backend/` nunca se faz X" |
| **Hook** | verificação automática a cada ação | "toda vez que alguém salva Y..." |
| **Skill** | procedimento longo e repetível | "o passo a passo de fazer Z" |
| **Agente** | trabalho paralelo, contexto próprio | "isso é uma investigação inteira" |

Regra de bolso: **"toda vez que X" → hook · restrição de área → regra ·
procedimento longo → skill · trabalho paralelo → agente.**

## Parte 2 — O princípio da catraca

**Nunca crie uma peça de harness por antecipação. Crie depois de um erro real, e
faça com que aquele erro específico não possa acontecer de novo.**

Harness especulativo é pior que nenhum: vira documento morto que ninguém lê e
que a IA ignora porque está desatualizado. Harness com catraca cresce devagar, e
cada peça tem uma cicatriz por trás.

Na prática: quando algo der errado, antes de só consertar, pergunte **"que peça
impediria isso?"** — e escreva a peça junto com o conserto.

## Parte 3 — Protocolo de Entrada (a IA executa isto)

Quando este kit for anexado, a IA deve executar, **nesta ordem**:

### Passo 1 — Reconhecimento, sem escrever nada

- Mapear a estrutura: linguagens, framework, gerenciador de pacotes, scripts.
- Ler README, documentação existente, arquivos de configuração.
- Ler o histórico do versionamento. As mensagens que se repetem revelam onde o
  projeto mais sofre:
  - `git log --oneline -50`
  - `git log --format=%s | sort | uniq -c | sort -rn | head -20`
- Identificar o que **já** existe de harness (memória, regras, hooks).

**Não proponha nada ainda.** Termine com um resumo do que entendeu e uma lista
do que ficou ambíguo.

### Passo 2 — Entrevista curta

Perguntar ao grupo, e só isto:

1. Qual o critério que decide se uma funcionalidade entra? (Se não houver, esse
   é o primeiro problema do projeto.)
2. Onde o projeto já quebrou mais de uma vez pelo mesmo motivo?
3. O que é inegociável — segurança, dado sensível, requisito da disciplina?
4. Quem revisa o quê antes de virar entregável?

### Passo 3 — Propor o mínimo

Escrever **só** o que as respostas justificarem:

- **Memória do projeto** (`CLAUDE.md`, `.cursorrules`, o equivalente da sua
  ferramenta): o que é o projeto, o que já foi decidido e **por quê**, o que é
  inegociável, o estado atual. Datar. Atualizar quando uma decisão mudar.
- **Regras por área**: um arquivo curto por pasta que tenha restrição própria.
- **Um hook** para a verificação mais crítica — só se houver uma óbvia.
- **Nada de skill nem agente** nesta etapa. Eles vêm quando um procedimento se
  repetir pela terceira vez.

### Passo 4 — Fechar com critério de aceite

Toda entrega precisa de uma frase que diga **como se prova que funcionou**,
executável por uma pessoa. Sem isso, "pronto" é opinião.

---

## Parte 4 — Desenvolvimento guiado por especificação

O erro mais caro com IA não é código errado. É **código certo para o problema
errado**, produzido rápido e em volume.

O antídoto tem três movimentos:

1. **Especificação antes de código.** O que o sistema deve fazer, e como se
   verifica. Uma página basta.
2. **Plano por fases, com parada.** A IA gera o plano e **para** para aprovação
   humana antes de cada fase. Sem a parada, você revisa mil linhas de uma vez —
   e, na prática, não revisa.
3. **Critério de aceite executado à mão.** *Implementado ≠ funciona.* Rode o
   caminho do usuário. Se você não executou, não está pronto.

## Parte 5 — Orquestração de agentes: grafo, não esteira

Quando o trabalho comportar paralelismo, a intuição errada é montar uma esteira
em que cada agente consome o resultado do anterior. Isso propaga erro: o engano
do primeiro vira premissa do segundo, e ninguém percebe.

O desenho que funciona:

- **Cada agente isolado**, com contexto próprio, dono de **uma** coisa.
- **Nenhum consome o resultado do outro.** Dependência só quando for inevitável,
  e explícita.
- **Escopo negativo obrigatório.** Diga o que o agente **não** deve fazer. Se
  ele perceber que precisa sair do escopo, **para e reporta** — não age.
- **Revisão individual.** Cada retorno é revisado sozinho, contra a fonte. Não
  se emenda um no outro.
- **Barreira no fim.** Só quando todos voltarem, verifique **contra o critério
  de aceite** — nunca contra "o agente disse que fez".

Esse último ponto é o que mais separa quem sabe de quem não sabe: **agente
descreve com confiança trabalho que não fez.** Peça sempre evidência — arquivo e
linha, saída de comando, resultado de consulta. Sem evidência, é alegação.

## Parte 6 — Verificação: o hábito que salva

Três regras que valem mais que qualquer ferramenta:

1. **Cite a fonte.** Toda afirmação sobre o código aponta para `arquivo:linha`.
2. **Confirme por caminho independente.** Se a IA diz que algo existe, verifique
   por outro método antes de decidir em cima.
3. **Prefira "não sei" a preencher lacuna.** Instrua explicitamente: onde faltar
   informação, deixe um marcador em vez de inventar. E cobre isso na revisão.

## Parte 7 — Erros que este kit existe para evitar

| Erro | Como aparece | Correção |
|---|---|---|
| Harness especulativo | pastas de regras que ninguém lê | catraca: só depois de erro real |
| Memória desatualizada | a IA age por decisão já revogada | datar e revisar ao decidir |
| Esteira de agentes | erro do primeiro contamina tudo | grafo com contextos isolados |
| Aceitar o relato do agente | "está pronto" e não está | verificar contra critério de aceite |
| Skill demais | a IA escolhe a errada | uma skill por procedimento, sem sobreposição |
| Regra só na interface | validação que o servidor não tem | invariante na camada mais baixa que consegue impor |

## Parte 8 — Primeiros sete dias, na ordem

1. Escrever a memória do projeto. Uma página. Datada.
2. Escrever o critério que decide o que entra no escopo.
3. Rodar o Protocolo de Entrada com a IA e discutir o que ela achou.
4. Na primeira coisa que der errado duas vezes, escrever a peça de harness.
5. Na primeira funcionalidade real, escrever a especificação antes.
6. Na terceira repetição de um procedimento, transformar em skill.
7. Só então pensar em agentes paralelos.

**Fora de ordem, nada disso funciona.** Grupo que começa por agentes paralelos,
sem memória e sem critério de aceite, produz volume que ninguém consegue revisar
— que é exatamente o fracasso que se parece com produtividade.

---

*Kit derivado de um projeto real em produção. Cada regra aqui tem um erro por
trás. Adaptem ao contexto de vocês — e apliquem a catraca: acrescentem as regras
dos erros de vocês, não as minhas.*
