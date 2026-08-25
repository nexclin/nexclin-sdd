# Handoff — 25/08/2026 · para continuar em sessão nova

> **Você é a próxima sessão do Claude Code.** Este documento existe para retomar
> exatamente de onde parou, sem refazer descoberta. Leia inteiro antes de tocar
> em qualquer arquivo.

---

## 0. Onde queremos chegar

Três destinos, em prazos diferentes. Confundi-los é o erro mais caro aqui.

| Horizonte | Destino |
|---|---|
| **08/09/2026** | A plataforma **Lovable** abre para os clientes fundadores, de graça. Ela precisa **operar**, não ser perfeita. Relatório correto é obrigatório: o time do Vinícius decide em cima dele. |
| **Outubro/2026** | A **stack Next.js** deste repositório substitui a Lovable. O banco migra intacto; o front é reescrito. |
| **Depois** | Prontuário, prescrição, agenda e estoque — o que o Vinícius apontou como o que "deixa o sistema completinho", e o que a pesquisa de mercado aponta como o nosso limitador de preço. |

**O critério que decide tudo** está na constituição v2.0.0, Princípio VII: *o
dado atravessa, a tela não*. Erro que fica **gravado** migra para outubro e é
importado junto. Erro que é só de exibição morre com a Lozable.

---

## 1. Leia nesta ordem

1. `.specify/memory/constitution.md` — **v2.0.0**, de 23/08. Nove princípios.
2. `docs/orquestracao/mapa-de-execucao.md` — o grafo, as raias, o calendário.
3. `docs/ponte/ponte-inversa.md` — **obrigatório** antes de tocar a plataforma.
4. Este arquivo, da §3 em diante.

---

## 2. O que aconteceu em 25/08

Dia longo. Em ordem:

- SPEC 001 foi de 18 para **24 de 28** tarefas. Guards, login, as 11 telas do
  painel, seção Perfis, banner de impersonação, esqueleto do app da clínica.
  80 testes de unidade e 15 de navegador, todos passando.
- PR #33 **mergeado** na `main`.
- Constituição v2.0.0 veio da `main` no merge, e foi conferida: compatível.
- Duas decisões viraram ADR (`docs/decisions/0001` e `0002`).
- Chegou a **bateria de 25/08 do Vinícius**, com triagem completa por outra
  sessão. **Onze correções foram feitas e commitadas no clone da plataforma**,
  com tipo e build verdes. **O push não saiu** — ver §3.

---

## 3. A PRIMEIRA COISA A FAZER

### O commit existe, e NÃO está no GitHub. Empurre ele.

**Correção importante, e ela é do próprio autor deste documento.** A primeira
versão desta seção dizia que o commit já estava em `nexclin/nexclin`. **Não
está.** Ele está **commitado apenas no clone local**:

- **Onde:** `C:\Users\ahifr\Downloads\nexclin-lovable`
- **Commit:** `ae2b37d`
- **Estado:** `main ahead 1` — commitado, não empurrado

**Por que não subiu:** o remoto `https://github.com/nexclin/nexclin.git` pede
credencial e o Git Credential Manager abre prompt interativo, que uma sessão de
agente não consegue responder. O `gh` **tem** permissão de push nesse
repositório (`"push": true`, conferido pela API), então é só falta de
credencial em cache, não de acesso.

O outro repositório, `nexclin-sdd`, empurra normal — a diferença é só qual
credencial o gerenciador já guardou.

**O trabalho não está perdido**, está commitado. Mas ele mora num diretório só,
e um diretório é um ponto único de falha.

#### Passo 1 — empurrar

```bash
cd "C:/Users/ahifr/Downloads/nexclin-lovable" && git push origin main
```

Se pedir usuário e senha, use o token do `gh`, ou rode uma vez:

```bash
gh auth setup-git
```

#### Passo 2 — publicar

1. Abrir o [projeto](https://lovable.dev/projects/09bc3d2d-df13-4ce3-a41f-6aa1606a75df)
2. Conferir que o commit aparece como **"Pushed from GitHub"**. Se não aparecer
   em uns 2 minutos com recarga, **pare e avise**: a ponte caiu.
3. **Publish → Update**
4. Anotar o crédito antes e depois. Tem de ser o mesmo número.
5. `bash scripts/ponte.sh conferir` para provar que o bundle mudou

**Bundle no ar quando esta sessão fechou:** `/assets/index-DVD9OEUx.js`.
Se ele mudou, o deploy saiu.

---

## 4. O que foi corrigido e enviado, item a item

Todas com `tsc --noEmit -p tsconfig.app.json` limpo e `vite build` verde.
**Nenhuma foi provada na tela** — na linguagem da constituição, Princípio IV:
**código lido, não comportamento provado.**

| Item | O que era | O que foi feito |
|---|---|---|
| **FIN-1** | R$ 500 em 12× somava 500,04 | `src/lib/parcelas.ts`: divisão em centavos inteiros, resíduo reconciliado. **Aritmética simulada** com 6 casos, incluindo borda |
| **FIN-2** | Todas as datas um dia a menos | Dois pontos: `exibeDataLocal` em `dataLocal.ts` corrige os **cinco relatórios de uma vez**; `vencimentoDaParcela` corrige a gravação |
| **FIN-3** | Taxa com decimais infinitos | Arredondada **na origem** (`paymentFees.ts`), `net_value` fechado em centavos, exibição formatada |
| **FIN-4** | Fluxo de caixa ignorava `paid_at` | `src/lib/dataDeCaixa.ts` com a regra do Vinícius. **6 casos simulados**, incluindo a conta de luz que ele descreveu |
| **FIN-5** | Antecipado continuava parcelado | `termDays` deixou de ser descartado; antecipado vence em hoje + prazo |
| **FIN-6** | Consulta virava venda | **Metade**: o lançamento avulso passou a gravar `macro_category`. A outra metade é regra, ver §5 |
| **FIN-7** | 13 consultas pagas para 2 realizadas | `src/lib/chaveDaVenda.ts`, extraída do relatório que já acertava. As duas telas passam a usar a mesma |
| **DASH-2** | Gráfico invisível | `.nx-root svg { width:16px }` vencia por especificidade. Exceção declarada por classe de gráfico |
| **DASH-3** | Saldo não batia | Sai junto com FIN-4 |
| **ORC-1** | Serviços inativos na prescrição | **Metade**: passou a usar `servicosAtivos`. A outra metade é regra, ver §5 |
| **UX-3** | Não dava para digitar o dia | Estado aceita texto, valida no blur. E `max` virou **31**, não 30 |

**Quatro arquivos novos**, todos com a regra em **uma** fonte só, como manda o
Princípio VIII: `parcelas.ts`, `dataDeCaixa.ts`, `chaveDaVenda.ts`, mais o
`exibeDataLocal` dentro de `dataLocal.ts`.

---

## 5. O que NÃO foi feito, e por quê

### 5.1 Duas metades devolvidas para decisão

**ORC-1, habilitar consulta no orçamento.** O Vinícius pediu. Não fiz, e o
motivo está verificado no código: `useFinancialBreakdown` faz
`if (isConsulta) continue` e **descarta** o item de consulta do orçamento tanto
das vendas quanto do prescrito. `consultaValue` vem da consulta do próprio
atendimento, não dos itens. **Habilitar hoje faria a receita sumir do
dashboard** — pior que o bug atual, e faixa A porque afeta número gravado.

**FIN-6, a atribuição de receita.** A correção certa é *"separar abatimento
financeiro de atribuição de receita: a linha carrega a categoria de origem e o
total contratado"*. Isso muda o que fica gravado em `receivables`, é faixa A, e
é mudança de regra — que pela ponte deixa de ser bug.

### 5.2 As duas migrações, escritas e não aplicadas

Estão em `supabase/migrations/`, prontas, **não aplicadas em banco nenhum**:

- `20260825080000_assinatura_de_trial_no_cadastro_da_clinica.sql` — **EQP-1**, a
  causa do "sem permissão para convidar". Clínica nasce sem
  `account_subscriptions`, `my_permission` devolve `none` para o próprio dono e
  a edge function responde 403. Trigger em `clinics` mais reparo das existentes.
- `20260825060000_auditoria_de_dado_e_soft_delete_em_patients.sql` — Fase 2 da
  SPEC 002. Guia de aplicação em cinco blocos em
  `specs/002-seguranca-anamnese-auditoria/preparado/fase2-aplicacao-guiada.md`.
- `20260825070000_corrige_default_de_enabled_modules.sql` — o default da coluna
  é `'[]'` e o trigger exige objeto. **Todo `INSERT` em `plans` sem informar a
  coluna falha.**

**Por que não apliquei:** `docs/seguranca/nota-sql-editor-lovable-2026-08-19.md`
provou que o SQL editor da Lovable, dirigido por automação, **executa consulta
diferente da que está na tela**. Contra produção isso é inaceitável. É limitação
de capacidade, não de permissão.

### 5.3 O resto da bateria

Ondas 3, 4 e 5 da triagem: DASH-1, DASH-4, ANA-1, ANA-2, TAR-1, TAR-2, UX-1,
UX-2, REL-1, REL-2, REL-3, REL-5. **Nenhuma tocada.**

A triagem completa está no artefato
`https://claude.ai/code/artifact/19e0233d-d431-42a2-bfa8-a3d4fe3a7a64`, com
causa-raiz de cada uma localizada no código.

Duas dependem de mudança de banco: **TAR-1** precisa de `tasks.created_by` e
`tasks.origem`. **DASH-4** é o único que a triagem manda investigar com dados
antes de corrigir, e traz as três consultas que dizem qual elo quebrou.

---

## 6. Pendências do Arthur

| # | O quê | Por que importa |
|---|---|---|
| **1** | **Empurrar E publicar `ae2b37d`** | Onze correções verificadas, paradas num diretório local. Ver §3 |
| **2** | **Trocar a senha do Vinícius** | Veio em texto claro no `.txt` da bateria. `docs/seguranca/credencial-exposta-2026-08-25.md`. É o mesmo erro da conta-mestra, três semanas depois |
| **3** | Aplicar as três migrações, pelos blocos guiados | Destrava EQP-1, a Fase 2 e o editor de planos |
| **4** | T012, senha do superadmin por recovery | O superadmin nunca logou |
| **5** | Credenciais de e2e (`.env.example` tem a receita) | Destrava os 5 testes que faltam |
| **6** | Supabase Pro antes de 08/09 | Sem backup diário não se opera com dado de saúde |
| **7** | Decidir ORC-1 e FIN-6 (§5.1) | Duas metades esperando |

---

## 7. Onde a stack nova parou

- **SPEC 005** (`specs/005-configuracoes-clinica/`): `spec.md`, `plan.md` e
  `research.md` escritos. **Falta `tasks.md` e a implementação.** O plano tem
  quatro fases e a decisão de desenho que governa tudo: **um** componente para
  nove catálogos, cinco telas próprias.
- **SPEC 016** (`endurecimento-seguranca`): auditoria dos 20 itens, 8 aplicados,
  6 parciais, 6 ausentes. Sem `tasks.md`.
- **SPEC 013** (resíduos): bloqueada por decisão comercial.

**Atenção à numeração:** duas sessões em paralelo criaram cada uma a sua SPEC
004. A `main` ficou com `004-correcao-bateria-vinicius`; configurações virou
**005** e a fila deslocou. **Antes de criar spec nova:** `git fetch` e
`git ls-tree -d --name-only origin/main specs/`.

---

## 8. Armadilhas que custaram tempo hoje

1. **`git show origin/main:arquivo` quebra no Git Bash do Windows** — o MSYS
   converte o caminho. Use PowerShell.
2. **Heredoc do Bash quebra com crase no conteúdo.** Para escrever arquivo com
   JSX ou template string, use o Write tool ou um script `.py` intermediário.
3. **O `typecheck` deste repositório estava permanentemente vermelho** porque
   `strix/` é gitignored e estava no `tsconfig`. Corrigido.
4. **`npm run build` não checa tipo.** O gate é
   `tsc --noEmit -p tsconfig.app.json`. Derrubou o app por 1h35 em 20/08.
5. **Na tela do export**, `Pause` e `Remove` ficam a 200 pixels do botão, os
   dois em vermelho. `Remove` apaga a instância.

---

## 9. O primeiro comando da sessão nova

```bash
cd "C:/Users/ahifr/Downloads/NexClin" && git fetch origin && git log --oneline origin/main -3 && git status -sb
```

Depois: `bash scripts/ponte.sh preparar`, para saber o que está no ar.
