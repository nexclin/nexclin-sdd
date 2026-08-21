---
name: nx-apontamento
description: Transforma o relato falado de um sócio testando o NexClin em um registro pronto para colar no Notion, no formato da base Apontamentos (4 campos + Tipo + Atrapalha muito). Use sempre que alguém descrever um problema, estranheza ou ideia encontrada usando a plataforma — nas baterias de teste de Vinícius (17–21/08) e Erick (24–26/08), ou a qualquer momento antes do lançamento de 01/09.
---

# Registrar um apontamento da bateria de testes

Alguém está **usando** o NexClin e te contou uma coisa. Seu trabalho é
transformar esse relato em um registro que o Arthur consiga corrigir sem
precisar telefonar de volta perguntando "o que exatamente você fez?".

Você não está aqui para consertar o problema. Está aqui para **registrar
direito**. Não abra código para investigar a causa a não ser que peçam.

---

## 1. Antes de escrever — os três não-bugs

Se o relato for **exatamente** um destes, não gere registro. Diga que é
conhecido, explique a volta e siga:

| O que a pessoa viu | O que é | A volta |
|---|---|---|
| Lista vazia em Pacientes ou Consultas | o filtro nasce em "Este mês" e o cadastro é mais antigo | trocar o período para um mais amplo |
| Tela branca no primeiro acesso | crash intermitente no carregamento frio | recarregar com F5 |
| Filtro de período diferente de uma tela para outra | três vocabulários de período convivendo | nenhuma — é conhecido |

**Cuidado:** parecido não é igual. Lista vazia **depois** de trocar o
período é bug. Tela branca que não volta com F5 é bug. Na dúvida, registre.

---

## 2. Se for grave, pare

Se o relato descreve **dado de uma clínica aparecendo para outra** —
paciente, consulta, valor, qualquer coisa —, não escreva registro nenhum.
Responda apenas: *"Isso é grave. Não registre no Notion. Ligue para o
Arthur agora."* Vazamento entre clínicas não fica escrito em lugar
compartilhado.

---

## 3. Complete o que faltar antes de escrever

O registro só serve com quatro coisas. Se o relato não trouxer alguma,
**pergunte** — uma pergunta curta por vez, não um questionário:

1. **Onde aconteceu** — a tela (ex.: Contas a Receber, Consultas, Configurações)
2. **O que você fez, na ordem** — os passos, do jeito que dá para repetir
3. **O que aconteceu** — o que apareceu na tela
4. **O que você esperava que acontecesse**

Se a pessoa não souber precisar os passos, escreva o que ela disse e marque
no fim `⚠️ passos incompletos`. **Nunca invente passo que ela não fez.**

---

## 4. Classifique

| Tipo | Critério |
|---|---|
| **Bug** | O sistema faz algo errado, ou não faz o que deveria fazer. |
| **Backlog** | O sistema faz certo, mas ela gostaria que fizesse diferente ou a mais. |

**Na dúvida, Bug.** É a instrução literal do plano de lançamento: é melhor o
Arthur descartar um item do que perder um problema real.

Depois marque **Atrapalha muito: sim / não**. Sim quando impede a pessoa de
seguir a rotina, ou obriga a fazer por fora do sistema. Essa marcação é o que
alimenta a **trava de lançamento** — a contagem de bugs abertos com
"Atrapalha muito = sim" precisa chegar a zero antes de 01/09. Por isso ela
importa mais do que a redação bonita.

---

## 5. A saída

Produza exatamente este bloco, em português, pronto para colar no Notion.
Sem preâmbulo, sem "aqui está o registro":

```
### <título curto, o problema em uma linha>

**Onde:** <tela>
**O que eu fiz:**
1. <passo>
2. <passo>
3. <passo>
**O que aconteceu:** <o que apareceu>
**O que eu esperava:** <o que deveria ter acontecido>

**Tipo:** Bug | Backlog
**Atrapalha muito:** sim | não
```

Se a pessoa contar dois problemas na mesma fala, gere **dois blocos
separados**. Um registro por problema — misturados, o Arthur corrige um e
perde o outro.

---

## 6. Onde isso vai parar

Na base **Apontamentos** do Notion, dentro da página da rodada — uma página
por bateria, nomeada pelo evento e pela data. Exemplo:
`Bateria de testes — Vinícius — 17 a 21/08 — pré-lançamento`.

É essa página que permite saber depois de onde veio cada apontamento. Se a
pessoa ainda não criou a dela, lembre — uma vez, sem insistir.

---

## 7. Contexto que vale carregar (só se precisar)

Antes de dizer a alguém que o comportamento observado está certo, confira —
pode ser regra funcionando, não defeito:

- `INVENTARIO-UI.md` — como cada tela se comporta hoje
- `INVENTARIO.md` §3.4 — regras de negócio embutidas (dias úteis,
  idempotência de recebíveis, confirmação em horas exibida em dias)
- `docs/planejamento/bateria-testes-vinicius-17-21.md` — o roteiro da bateria

Mas o padrão é registrar. Quem testa não precisa provar que achou um bug.
