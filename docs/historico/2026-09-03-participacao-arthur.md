# Participação de Arthur Reis no desenvolvimento do NexClin

> **Base:** [`2026-09-03-registro-tecnico.md`](2026-09-03-registro-tecnico.md),
> que traz os mesmos fatos sem argumento de valor.
>
> **Período:** 23/07/2026, data em que assumiu o desenvolvimento, a 03/09/2026.
>
> Todo número deste documento é reproduzível por qualquer sócio, com o comando
> indicado ao lado. Nada aqui depende de acreditar em quem escreveu.

---

## 1. O número que resume

| | Antes de 23/07/2026 | Desde 23/07/2026 |
|---|---|---|
| duração | 568 dias | **42 dias** |
| **commits diretos de pessoa** | **0** | **289** |
| commits gerados por bot | 1210 | 83 |
| repositório de especificação | não existia | 198 commits |
| testes automatizados | 0 | 233 |

**Em dezenove meses de projeto, nenhuma pessoa havia commitado código
diretamente. Em quarenta e dois dias, foram 289 commits diretos.**

Como reproduzir, no repositório da plataforma:

```bash
git shortlog -sn origin/main --before=2026-07-23   # 1210 bot, 1 Lovable, zero pessoa
git shortlog -sn origin/main --since=2026-07-23    # 79 thurreis7, 12 Claude, 83 bot
```

E no repositório de especificação, que nasceu em 23/07:

```bash
git rev-list --count HEAD    # 198
```

---

## 2. O que foi construído, não só corrigido

Correção de bug é a parte visível. O que sustenta a participação é o que passou
a existir:

**Fundação de segurança.** RLS em toda tabela com dado de clínica, âncora
multi-tenant protegida por gatilho, e a trilha de leitura de prontuário exigida
por lei, com os cinco critérios de aceite provados contra o banco de produção.

**Governança de código.** Uma constituição com regras inegociáveis, hooks que as
aplicam automaticamente a cada escrita, e 13 regras vivas que registram o que o
sistema deve fazer e por quê. Antes, o requisito não existia em lugar nenhum
fora da cabeça de quem pediu.

**Processo de correção sem custo.** A ponte inversa permite corrigir a plataforma
ao vivo por commit no repositório, com consumo de crédito medido em zero. Sem
ela, a fase de correção não ficaria cara: ficaria inviável.

**Rede de proteção.** 233 testes automatizados onde não havia nenhum, incluindo
seis guardas de fonte que impedem a volta de uma classe inteira de defeito que
se repetiu cinco vezes.

**Histórico auditável.** 52 handoffs que registram o estado real ao fim de cada
sessão, com o que foi provado e o que não foi.

---

## 3. O que a verificação revelou sobre o estado anterior

O sistema era tratado como **90% pronto**. A verificação encontrou **mais de
sessenta defeitos**, entre eles:

- um caminho que **apagava dinheiro já recebido** do registro financeiro;
- parcelas de cartão entrando **todas no caixa do mesmo dia**;
- uma cortina invisível que **trancava a conta inteira**, sem saída;
- a agenda **escondendo consultas que ela mesma havia gravado**;
- oito clínicas **impossibilitadas de agendar**;
- a rota de cadastro público ainda viva, **criando contas que não abrem**.

Nenhum deles era visível abrindo o sistema. Todos foram encontrados abrindo o
código, medindo o banco, ou usando a plataforma com atenção ao número.

---

## 4. Como apresentar isto, e o que não dizer

**A frase que sustenta:** *"antes de eu assumir, nenhuma pessoa havia commitado
diretamente neste sistema em dezenove meses. Em quarenta e dois dias foram 289
commits, 233 testes e 39 migrações de banco."*

**A frase que não sustenta:** "escrevi 89% do sistema". Uma parte relevante dos
commits registra co-autoria de ferramenta de IA, e isso está no histórico, ao
alcance de qualquer um. Reivindicar autoria exclusiva derruba o argumento no
primeiro `git log`, e leva junto a credibilidade do resto.

**O enquadramento correto, e ele é verdadeiro e verificável:** a direção técnica,
as decisões de arquitetura, a tradução das regras de negócio e a execução são
de Arthur, com ferramenta de IA como instrumento. Ferramenta não decide que
`receivables` não pode ter seis caminhos de escrita, nem que a impersonação
precisa de trilha auditável, nem que o financeiro tem de funcionar na plataforma
ponte porque é o diferencial que sustenta a venda.

**Uma ressalva a levantar antes que alguém a levante:** dos 83 commits de bot no
período, parte é varredura automática da própria Lovable, e não trabalho
dirigido. Isso não retira nada, e reivindicá-los seria criar um alvo.

---

## 5. O que este documento não mede

Honestidade sobre o escopo é o que dá peso ao resto.

**Este documento mede desenvolvimento, e não o projeto inteiro.** Ficam de fora,
por não estarem no repositório e por não pertencerem a esta contribuição:

- o aporte financeiro, a hospedagem e as ferramentas;
- a estruturação comercial e o go-to-market;
- **a metodologia de gestão clínica**, que o próprio `CLAUDE.md` registra como o
  diferencial do produto: *"embarcar metodologia real de gestão clínica como
  inteligência do produto"*. É ela que faz o sistema valer mais que um genérico;
- o canal de distribuição e a relação com os clientes fundadores.

**Nenhum percentual societário decorre automaticamente destes números.** Eles
dizem o tamanho da contribuição técnica, com precisão e de forma auditável. O
quanto isso vale em participação depende do acordo, do aporte e do que cada
sócio traz, e é decisão da sociedade.
