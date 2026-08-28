# As duas verificações técnicas — executadas em 16/08/2026

> **Origem:** "Plano até o Lançamento", seção 08 — *Duas verificações que valem
> o fim de semana*. Tarefa do cronograma de 15–16/08, no nome do Arthur.
> **Executado em:** 16/08/2026, entre ~22h40 e ~23h20 (BRT), no navegador do
> Arthur, com ele logado e tendo autorizado cada passo.
> **Resultado:** **as duas passam.** A ponte até a migração é gratuita.

---

## Verificação A — manutenção sem custo por alteração

**Pergunta:** dá para corrigir os bugs das duas baterias escrevendo código e
enviando pelo repositório, sem consumir crédito?

**Resposta: sim, ponta a ponta.**

### Como foi feito

| Passo | O quê |
|---|---|
| Baseline | `main` em `3b8fc94`. Créditos: **5 restantes** (plano Free, workspace "Erick's Lovable", reset diário à meia-noite UTC). |
| Mudança | `src/components/auth/BrandPanel.tsx:77` — `v2.4.1` → `v2.4.2`. Rodapé decorativo da tela pública de acesso; zero efeito funcional, zero toque em dado. |
| Envio | commit `f8b8578`, push direto em `main`. |
| Chegou ao editor? | **Sim.** Apareceu como entrada "Pushed from GitHub" no histórico do projeto, e o diff mostrado pelo editor é exatamente a linha 77, `v2.4.1` → `v2.4.2`, com o caractere `·` preservado. |
| Publicou sozinho? | **Não.** O site seguiu em `v2.4.1` até um clique manual em **Publish → Update**. |
| Depois do Update | Site publicado passou a exibir `NEXCLIN · ERP · V2.4.2`, verificado em `nexclin.lovable.app/request-access`. |
| Créditos ao final | **5 restantes.** Inalterados após o push **e** após a publicação. |

### Veredito

**A passa** pelas três condições: chegou ao editor, chegou ao site publicado, e
**não consumiu crédito nenhum**.

**Ressalva de procedimento:** a publicação **não é automática**. Todo envio pelo
repositório exige um clique manual em *Publish → Update* para chegar ao cliente.
O clique é gratuito, mas precisa entrar no procedimento de correção — se
esquecerem dele, a correção fica no editor e o cliente continua vendo o bug.

**Ponto em aberto, a reconferir:** o editor marcou o commit como
**"Build unsuccessful / Preview is out of date"**, embora o diff tenha chegado
íntegro e o site publicado esteja correto e funcional (o app carrega e
autentica normalmente). Ou o rótulo se refere só ao sandbox de preview, ou há
uma falha de build que não impediu o deploy. **Não confirmei qual dos dois.**
Vale reconferir antes da janela de correção de 22–23/08 — se o preview do
editor estiver quebrado, quem for corrigir pelo chat vai esbarrar nisso.

### Por que isso muda o número que vai aos sócios

O workspace está no **plano Free, com 5 créditos por dia**. Se A tivesse
falhado, a fase de correção de bugs teria de caber em 5 créditos diários — e o
histórico do projeto é de 30 a 60 créditos por funcionalidade real. Não seria
"orçar crédito": seria ficar sem canal de correção. Com A passando, **a fase de
correção custa R$ 0 e o limite passa a ser só o tempo do Arthur.**

---

## Verificação B — acesso direto ao banco atual

**Pergunta:** a futura cópia de dados é uma exportação direta ou trabalho
manual tabela por tabela?

**Resposta: exportação direta.**

### O que se descobriu

O banco **não** aparece no dashboard pessoal do supabase.com. Lá existe uma
única organização ("nexclin's App", plano Free) com **um único projeto**,
`bfkghwkhzkimzyiovotj` — que é a **stack nova**, não o produto.

O banco do produto é **Lovable Cloud gerenciado**, e seu painel é
`lovable.dev → projeto → More → Cloud`. Procurar no supabase.com produziria um
falso "B falhou".

### O que o painel oferece

| Recurso | Estado |
|---|---|
| Database | 45 tabelas, com edição de dados |
| Users | 17 signups |
| Edge functions | 4 — `generate-insights`, `invite-team-user`, `anamnesis-public`, `superadmin-manage-user` |
| SQL editor | funcional (foi por onde a Fase 0 da SPEC 002 rodou) |
| Logs, Storage, Secrets, Jobs, Usage | presentes |
| **Export project data** | **existe e está habilitado** (Advanced settings) — confirmado sem clicar |
| Disco | 0,29 GB de 8 GB |

### Veredito

**B passa.** O projeto aparece no painel do provedor que de fato o hospeda, e a
exportação é um botão. A migração de dados será exportação e restauração, não
trabalho manual — e dá para ensaiar com antecedência.

**Consequência imediata:** o backup prévio à janela de correção de 22–23/08
está disponível e é gratuito. Isso importa porque não há point-in-time recovery
neste tier: o próprio agente da Lovable já registrou, em teste de 02/08, que um
`DELETE` direto **não é reversível** por lá.

---

## Canal de correção — decidido

| Frente | Canal | Custo |
|---|---|---|
| **Código** | commit + push em `nexclin/nexclin@main`, seguido de *Publish → Update* | **R$ 0** |
| **Banco** | SQL editor do Lovable Cloud, com Export antes de qualquer escrita | **R$ 0** |

O chat do Lovable — que consome crédito — deixa de ser o caminho e passa a ser
o último recurso.

---

## Limpeza pendente

O bump `v2.4.2` está publicado. **Recomendação: manter.** É um incremento de
versão verdadeiro num rodapé, não lixo de teste, e reverter exigiria um segundo
push mais um segundo Publish sem ganho nenhum.
