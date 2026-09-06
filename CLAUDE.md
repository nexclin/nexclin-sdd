# CLAUDE.md — o contexto que vale a todo turno

> Este arquivo é lido no início de toda sessão, e é cobrado em todo turno. Por
> isso ele guarda **só o que muda uma decisão**: o que é o produto, o prazo, o
> critério que decide o que se corrige, e as regras inegociáveis.
>
> **Tudo que é histórico saiu daqui em 27/08/2026** e vive em `docs/historico/`,
> com a data no início de cada nome. Índice da árvore em
> [`docs/README.md`](docs/README.md).

---

## 1. Por onde começar, nesta ordem

| # | Onde | Para quê |
|---|---|---|
| 1 | o handoff mais recente em [`docs/historico/`](docs/historico/) | **o estado real.** Os nomes começam com a data: pegue o maior |
| 2 | as issues abertas em `nexclin/nexclin-sdd` | o trabalho pendente, tarefa a tarefa |
| 3 | [`docs/regras/README.md`](docs/regras/README.md) | o que o sistema deve fazer, e o que falta decidir |
| 4 | [`docs/ponte/ponte-inversa.md`](docs/ponte/ponte-inversa.md) | **obrigatório** antes de tocar a plataforma ao vivo |
| 5 | [`docs/constituicao.md`](docs/constituicao.md) | a lei, vence qualquer preferência |

**[`CONTEXT.md`](CONTEXT.md)** é o glossário, 58 linhas, só termo que já causou
confusão real. Leia antes de usar palavra do domínio com significado próprio:
âncora, recebível, repasse, faixa, ponte, atravessar, ModuleKey, impersonação,
apontamento, regra viva.

**Se o handoff mais recente não existir**, a sessão anterior não o escreveu, e
você está mais cego do que o normal. Reconstrua pelas issues abertas e pelo
`git log`, e escreva o handoff no fim.

---

## 2. O que é o NexClin

SaaS de gestão para clínicas médicas e odontológicas: uma **plataforma
operacional inteligente**, não um sistema de cadastros. Critério que valida toda
funcionalidade: aumentar receita, reduzir custo, economizar tempo ou melhorar
decisão da clínica. O diferencial é embarcar metodologia real de gestão clínica
como inteligência do produto, não competir feature a feature com sistemas
genéricos (iClinic, Feegow, Clinicorp).

**Sociedade:** Arthur Hideo (operacional e desenvolvimento, o interlocutor deste
repositório), Erick (empresa e go-to-market), e um mentor de gestão clínica
(domínio e canal de distribuição).

**Dados sensíveis de saúde.** LGPD é requisito de arquitetura, não feature.

### O prazo vivo

```
08/09/2026  abre para clientes fundadores, de graça, na plataforma Lovable
set/2       transição gradual começa
out/2026    a stack Next.js deste repositório substitui a Lovable  ← o destino
```

Duas plataformas convivem até outubro, e **confundir as duas é o erro mais caro
que existe aqui**. A Lovable é React e Vite, está no ar, e vive cerca de um mês.
Este repositório é Next.js e Supabase próprio, e é o destino.

**A stack:** Next.js (App Router), TypeScript, Supabase próprio (Postgres, Auth,
RLS, Edge Functions), Vercel. E-mail transacional: Resend, porque o SMTP embutido
comprovadamente não entrega. **`../nexclin-lovable`** é o clone do repositório ao
vivo da plataforma (`nexclin/nexclin`), e **é editável, sob procedimento**: ver a
regra (i).

---

## 3. A §2.5: a Lovable é ponte, não destino, e isso decide o que se corrige

> **Leia isto antes de aceitar qualquer pedido de correção na plataforma ao
> vivo.** Decisão do Arthur, 20/08/2026. Numerada como §2.5 desde então, e
> referenciada assim em dezenas de documentos.

**O compromisso com o fundador** é entregar um software de gestão em lançamento,
com os problemas de um lançamento. **Não precisa ser perfeito.** O que não pode é
decepcionar: ele tem de conseguir operar a clínica.

**O critério, em uma frase:** corrigir na plataforma só vale quando a correção
**atravessa** para a stack nova. Fora disso é polir o que será descartado.

**A consequência que se esquece com facilidade:** na maioria dos casos o que
atravessa **não é o código, é a regra escrita**. O front da Lovable será
reescrito de qualquer jeito. O que sobrevive é a decisão de *como o sistema deve
se comportar*. **Escrever a regra é a entrega; implementar na Lovable é
opcional.**

**O critério é sobre RETRABALHO, nunca sobre custo em crédito.** Precisão de
25/08, registrada porque uma sessão errou nisso e escreveu que "construir na
Lovable é o desperdício mais caro possível", o que é falso. Desde a ponte inversa
(`scripts/ponte.sh`) **não se compra crédito para construir**: o trabalho é
commit no repositório e publicação. O que se migra em outubro é banco, front e
hospedagem, e o banco vai intacto. Então, ao recusar trabalho na plataforma,
**diga a razão certa**: "esta tela será reescrita, o artefato durável é a regra".
A razão errada, e proibida, é "isso custa caro".

### As três faixas

| Faixa | Pergunta | Ação |
|---|---|---|
| **A, atravessa como banco** | É migração, RLS, trigger, coluna, regra de recebível? | **Corrigir.** As migrações vão intactas para a stack nova. Aqui o código é o artefato durável |
| **B, atravessa como regra** | Depende de uma regra que a stack nova também vai precisar? | **Escrever a regra**, datada, em `docs/regras/`. Implementar na Lovable só se o fundador esbarrar no uso |
| **C, não atravessa** | É front, layout, mensagem, comportamento de tela? | **Não corrigir.** Vira requisito da stack nova. Exceção única: se impedir o fundador de usar o que foi prometido |

### A régua fina: DADO atravessa, CÁLCULO DE TELA não

**O banco migra intacto**, e com ele vem tudo que as clínicas registrarem no mês
da Lovable. A estimativa é de **R$ 100 a 200 mil de faturamento** lançado por
clínica nesse período. Lançamento errado em agosto **não é descartado em outubro:
é importado**.

> **Financeiro na Lovable tem de funcionar como vai funcionar na stack final.**
> Outras coisas podem passar; financeiro não.

A razão é de produto, não de engenharia: gestão financeira é o diferencial que as
clínicas não têm, e é por ele que o NexClin foi vendido. Entregar número errado
justamente aí destrói o argumento de venda.

**Como aplicar, item a item:** pergunte *o que fica gravado?*

- Muda o que é **persistido** (valor, data, atribuição, a qual conta pertence)?
  **Faixa A, corrigir.** O erro migra.
- Muda só **como a tela soma ou exibe** o que já está gravado certo? Faixa B. A
  regra escrita basta; a stack nova calcula certo desde o começo.

### A exceção da faixa C tem um nome, e ele é RELATÓRIO

O time do Vinícius **não usa o dashboard**: puxa as bases pelos **relatórios**,
toda semana, e decide em cima delas. Relatório errado vira decisão errada e perda
para a clínica. Logo, **relatórios não são faixa B: têm de funcionar em 08/09.**
Dashboard, ao contrário, foi rebaixado: é "visão simples pro médico", nas
palavras dele.

Regra de bolso que sai daí: **antes de classificar em faixa, pergunte por onde o
cliente realmente opera.** A intuição de quem constrói (dashboard é a cara do
produto) não bateu com a de quem usa (a cara é o relatório).

### Corolário sobre backlog

A meta é a stack nova nascer **sem bug e sem backlog**. Então item de backlog não
é trabalho adiado: é **requisito da stack nova**, e entra na regra do módulo
correspondente em vez de dormir numa lista.

---

## 4. Regras inegociáveis

Valem para todo código e todo texto deste repositório.

**(a)** RLS em TODA tabela com `clinic_id`. Sem exceção.
**(b)** Default deny: o que não é explicitamente concedido, é negado.
**(c)** Segurança mora no banco; a tela apenas reflete. Nenhuma regra de acesso
pode existir só no frontend.
**(d)** Toda ação administrativa sobre dado de cliente gera auditoria: quem, o
quê, quando, `old→new`.
**(e)** Senha é definida **só pelo superadmin, e só ao provisionar clínica
nova**, com auditoria. Admin ou membro de clínica **jamais** define senha de
outro usuário: para esses, só reset por e-mail, com o próprio dono digitando.
Emendada em 28/08/2026; o porquê está na Seção II da constituição.
**(f)** As **15 ModuleKeys** são o contrato único de módulos, e planos,
permissões e telas usam as mesmas strings:
`dashboard · leads · pacientes · anamnese · consultas · acompanhamento · tarefas
· contas_receber · contas_pagar · fluxo_caixa · relatorios_vendas ·
relatorios_demais · configuracoes · equipe · insights`.
Módulo novo exige emenda à constituição. A saída de `consultas` está proposta em
[`docs/adr/0001`](docs/adr/0001-consultas-sai-do-contrato-de-modulos.md).
**(g)** Nenhuma credencial em código, regra ou arquivo versionado. Sempre
variável de ambiente, fora do git.
**(h)** Nenhuma feature sem **regra viva** aprovada em `docs/regras/`. O executor
gera plano por fases e PARA para aprovação humana antes de cada fase.
**(i)** `../nexclin-lovable` é editável **só sob procedimento**: bug apenas,
conserto mínimo, `git pull` antes, `main` sempre, nunca `--force`, e a ordem
obrigatória **function antes do Publish do front**. Procedimento em
[`docs/ponte/ponte-inversa.md`](docs/ponte/ponte-inversa.md).
**(j)** "Implementado ≠ funciona": toda fase fecha com critérios de aceite
executados manualmente pelo Arthur. Quando não der para provar o comportamento na
tela, registre literalmente *"código lido, não comportamento provado"* e deixe o
item aberto.
**(k)** TypeScript estrito. Testes automatizados mínimos em guards e permissões.
**(l)** Mudança que altera comportamento descrito numa regra **atualiza a regra
no mesmo commit**.

**A âncora multi-tenant é `profiles.clinic_id`**, e o trigger
`prevent_clinic_id_change` impede que qualquer um a altere, exceto superadmin ou
service role. Foi uma brecha real: usuário podia trocar o próprio `clinic_id` e
ver dados de outra clínica.

**A cascata de acesso vive em `my_permission(_module)`**, no banco: superadmin dá
`full`; assinatura `suspended` ou `cancelled` dá `none`; módulo fora do plano dá
`none`; admin da clínica dá `full`; senão a permissão individual; fallback
`none`. **O plano é o teto; a permissão individual distribui abaixo do teto e
nunca o excede.**

---

## 5. Como este repositório dirige o Claude Code

Cada peça rastreia a uma falha real (princípio da catraca). Leia
[`docs/harness/README.md`](docs/harness/README.md) antes de mexer nela.

- **hooks** rodam a cada escrita: `guarda-constituicao.mjs` bloqueia RLS
  ausente, `USING(true)`, caminho que define senha e segredo versionado;
  `guarda-ponte.mjs` bloqueia `git add -A`.
- **rules** são restrições por área, pelo `paths:`. **`escrita.md` é a voz do
  projeto:** travessão proibido, barra como conector proibida, superlativo exige
  conta atrás. Vale para a resposta na tela também.
- **skills** são procedimentos longos. As nossas: `nx-regra`, `nx-modulo`,
  `nx-ponte`, `nx-paralelo`, `nx-apontamento`. De terceiros, seis do Spec Kit:
  `speckit-clarify`, `speckit-plan`, `speckit-tasks`, `speckit-taskstoissues`,
  `speckit-analyze` e `speckit-checklist`.
- **agents**: auditor-multitenant, triador-apontamentos, consultor-vertical,
  relator-semanal.

"Toda vez que X" vira hook; restrição de área vira rule; procedimento longo vira
skill; trabalho paralelo vira agente. A constituição vence qualquer uma delas.

**A cadeia canônica de trabalho:** `speckit-clarify` para interrogar a ideia,
`nx-regra` para escrever a regra em `docs/regras/`, `speckit-plan` e
`speckit-tasks` para o plano e as tarefas em `docs/planos/`,
`speckit-taskstoissues` para abrir as issues na ordem de dependência, e
`implement` para executar por fases.

**Não use `grill-with-docs`.** Ele delega a uma skill `grilling` que está em
`.claude/skills-fora/`, fora do git: existe só na máquina do Arthur e falha em
qualquer clone. Saiu da cadeia em 05/09/2026.

**O Spec Kit voltou pela metade em 04/09**, com quatro skills e a regra
continuando em `docs/regras/`. O porquê está na
[ADR 0006](docs/adr/0006-o-spec-kit-volta-pela-metade.md), e como se aponta o
diretório da frente está em [`docs/planos/README.md`](docs/planos/README.md).

---

## Agent skills

Onde as skills de engenharia buscam configuração deste repositório. Não apague
os títulos em inglês: é por eles que o `setup-matt-pocock-skills` se reencontra
numa re-execução, em vez de criar bloco duplicado.

### Issue tracker

As issues vivem no GitHub, em `nexclin/nexclin-sdd`, que é este mesmo
repositório, então o `gh` infere sozinho. Ver
[`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md).

### Domain docs

Contexto único: `CONTEXT.md` e `docs/adr/` na raiz. E antes de explorar
qualquer área, a **regra viva** dela em `docs/regras/`, porque aqui o requisito
mora na regra e não no código. Ver
[`docs/agents/domain.md`](docs/agents/domain.md).
