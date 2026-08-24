# Handoff — 24/08/2026 · direcionamento da próxima sessão

> **Cole este arquivo inteiro num chat novo.** Foi escrito para ser
> autossuficiente: uma sessão sem nenhum contexto desta consegue executar.

---

## 0. Leia nesta ordem, antes de tocar em qualquer coisa

1. **`CLAUDE.md`** — memória do projeto.
2. **`.specify/memory/constitution.md` v2.0.0** — a lei. Os princípios **VII, VIII
   e IX** são novos, de 23/08, e cada um foi comprado com um bug real. Ler os
   três leva 3 minutos e evita repetir a semana passada.
3. **`specs/004-correcao-bateria-vinicius/tasks.md`** — o estado de cada item.
4. **`specs/004-correcao-bateria-vinicius/plan.md`** — o plano do que falta.
5. **`docs/ponte/ponte-inversa.md`** — **obrigatório antes de mexer na
   plataforma.** Tem armadilhas que já custaram tempo real.

## 1. Onde estamos, em números

| | |
|---|---|
| Data | 24/08/2026 · **8 dias** para o lançamento |
| Bateria do Vinícius (33 itens) | trava: **20 fechados · 3 abertos** |
| Commits na plataforma em 23–24/08 | **11**, todos publicados. HEAD `551bb12` |
| Bateria do Erick | **24–26/08, começando agora** |
| Constituição | **v2.0.0** |

**Duas plataformas convivem, e confundi-las é o erro mais caro possível:**

| | O que é | Papel |
|---|---|---|
| **Lovable** (`nexclin.lovable.app`) | produto em produção | abre 01/09 para clientes fundadores, **de graça** |
| **Stack nova** (este repositório) | Next.js + Supabase próprio | substitui a Lovable em **outubro** |

## 2. A restrição de ambiente que muda o que dá para prometer

**A sessão remota do Claude Code não alcança `nexclin.lovable.app`.** A política
de rede do ambiente bloqueia o host — `ERR_TUNNEL_CONNECTION_FAILED` no proxy,
testado quatro vezes. Não é login, não é sessão: o pacote não sai de lá.

**Consequência prática, e é grande:** nenhuma correção pode ser *provada* por uma
sessão remota. Tudo que ela entrega é **código enviado**, e o aceite é sempre do
Arthur. Se isso incomodar, a saída é rodar o Claude Code **no terminal da
máquina do Arthur** — aí a sessão usa a rede dele e consegue navegar e testar.

**O que a sessão remota consegue provar:** qualquer coisa que rode localmente.
Harness com Vite + Playwright funciona, e foi assim que o calendário e o layout
foram verificados. **Regra aprendida do jeito caro:** o harness precisa envolver
o componente em `.nx-root > .nx-content`, como o `NxAppShell` faz — sem isso ele
mente. Um calendário testado fora desse wrapper apareceu teal no harness e preto
na tela real.

## 3. As três coisas que só o Arthur pode fazer, em ordem de risco

Nenhuma é código. **Todas estão paradas há dias.**

### S-01 · Consulta de `storage.objects` — **segurança, precede tudo**

Decide se há vazamento de dado de saúde. O bucket guarda o **dump completo do
banco**. Pedida em 20/08, repetida em 23 e 24. Consulta em
`docs/seguranca/storage-objects-2026-08-20.md`.

Não afirmar vazamento sem ela: no Supabase, RLS ligada com zero policies **nega
tudo**, o que é seguro. O scanner não distingue. O pior caso não é RLS
desligada — é bucket com `public = true`, lido sem autenticação nenhuma.

### S-02 · `.env` versionado em `nexclin/nexclin`

Se contiver só `VITE_SUPABASE_URL` e a chave **anon**, está tudo bem — anon é
pública por desenho e quem protege é a RLS. Se contiver **`service_role`**, é
vazamento crítico: ela **ignora RLS**, está no histórico do git e **não sai com
`rm`**. Exige rotação no painel do Supabase.

> A regra de permissão do repositório bloqueou a leitura do arquivo pela sessão,
> **e isso está certo.** Não contornar. É o Arthur que abre e confere.

### S-03 · Região do projeto Supabase novo

**A região não muda depois — migrar é recriar o projeto.** Se estiver fora do
Brasil, é infinitamente melhor descobrir agora, sem cliente, do que em outubro
com dado real. Raciocínio completo em `docs/arquitetura/hospedagem-2026-08-23.md`.

## 4. Os 2 itens da trava que ainda dependem do Arthur

Cerca de 20 minutos, e derrubam os dois.

**V-24 · consulta de 30 segundos.** Decide se a correção é SQL ou front:

```sql
select level, count(*), bool_or(active) as tem_ativo
from chart_of_accounts where clinic_id = '<id da clínica>'
group by level order by level;
```

Sem linha `level = 3` → rodar o seed do plano de contas. Com linhas → é bug de
front e a sessão corrige em minutos.
*(O beco sem saída já foi removido em `551bb12`: a lista vazia agora distingue
"sua busca não achou" de "não há o que achar".)*

**V-04 · reteste do convite de equipe.** 8 passos, zero crédito, e é o único que
prova o T017. Roteiro no teste 6 de `docs/planejamento/roteiro-verificacao-23-08.md`.

## 5. O que a próxima sessão deve executar, em ordem

### Prioridade 1 — triar a bateria do Erick (24–26/08)

É o trabalho principal da janela. Ele testa como **visão geral de gestão**, não
como quem opera — vai achar coisa diferente do Vinícius.

- Numeração **E-01 em diante**, já reservada.
- Triar no mesmo `docs/planejamento/triagem-baterias-18-19.md`, mesmo formato.
- Skill `nx-apontamento` transforma relato falado no formato do Notion.
- **A D-15 (24/08) mudou a política:** corrigir **tudo**, não só o que trava.
  Mas a triagem em faixas continua valendo para decidir **ordem**, não valor.

### Prioridade 2 — o que a resposta do Arthur destravar

V-24 e V-04, conforme §4.

### Prioridade 3 — as fases 7 a 9 do `plan.md`

Anamnese (V-05, V-07, V-08) → ficha do paciente (V-09) → cosméticos (V-02, V-06).
**Cosméticos por último e em commit isolado**, para que uma regressão neles não
contamine o lote financeiro.

⚠️ **V-08 tem de ser fatiado:** o *copiar respostas* é trivial; o *resumo por IA*
depende do gateway de IA da Lovable e **não sobrevive à migração**. Fazer só o
copiar.

### Prioridade 4 — 27–30/08, no congelamento

Limpeza do transacional (**D-14**) + D-13 (taxa como despesa). **Nesta ordem, e
não fatiar a D-13** — ela toca Contas a Receber, Fluxo de Caixa e DRE ao mesmo
tempo, e meio caminho desconta a taxa duas vezes.

### Fora da janela, por recomendação registrada

**V-30 e V-31 não são bugs, são funcionalidades novas**, e o V-31 interage com a
D-2, que acabou de fixar responsável único por atendimento. Escopo novo a 8 dias
do lançamento é risco de outra natureza. A recomendação está no `plan.md`; a
decisão é do Arthur.

## 6. As armadilhas da ponte — leia antes de publicar

1. **O Publish publica o PREVIEW, não o commit.** Se ler *"Preview is out of
   date"*, clicar **Update preview**, esperar (~11 min numa mudança de 15
   arquivos) e só publicar ao ler **"Previewing"**.
2. **O Publish NÃO redeploya edge function.** Correção que toca front +
   function precisa da **function primeiro**. O CLI do Supabase responde **403**
   nesse projeto.
3. **`conferir` não é formalidade.** O painel já disse "sucesso" sem ter
   publicado, duas vezes no mesmo dia.
4. **"Build unsuccessful" no editor é falso** — aparece em todo commit vindo do
   GitHub, inclusive nos que publicaram.
5. **`npm run build` NÃO checa tipos.** Vite usa esbuild. O gate é
   `tsc --noEmit -p tsconfig.app.json` — **`tsconfig.json` não serve**: ele usa
   `references` com `"files": []` e checa zero arquivos, sempre verde. Isso
   derrubou o app por 1h35 em 20/08.
6. **`Consultas.tsx` é página órfã** — não roteada; o menu aponta para
   `/acompanhamento`. Conferir roteamento antes de corrigir um arquivo.

## 7. Dívidas de MODELO — requisito da stack nova, não backlog

Não são bugs de tela. São decisões de banco que a stack nova **não pode repetir**.

1. **`appointment_items` guarda unidades diferentes no mesmo par de colunas** —
   `prescribed_value` é unitário, `sold_value` já é o total. Causou inflação de
   2× no financeiro. Hoje os leitores estão alinhados; consertar o modelo exige
   migração com backfill.
2. **`appointments.consultation_type_id` sem FK, apontando para duas tabelas** —
   a tela grava `services.id`, o cálculo procurava em `consultation_types`. O
   valor da consulta era **sempre zero**, e nada acusava.
3. **`revenues` existe e ninguém escreve** — zerava o DRE. `RelatorioRepasse`
   ainda lê dela, **de propósito**: o repasse tem imposto fixado em zero e
   atribuição estimada, e mostrar número plausível e errado a médicos que
   conferem repasse é pior que um relatório visivelmente vazio.
4. **A descrição do item carrega apresentação** — o sufixo de desconto quebra a
   busca do serviço. Na stack nova, desconto é **coluna**, não texto.

## 8. Estado do repositório

- Branch `claude/handoff-execution-2026-08-20-im3rpy`, **PR #32 aberto (draft)**.
- Plataforma `nexclin/nexclin@main`, HEAD `551bb12`, tudo publicado.
- Clone da plataforma: `bash scripts/ponte.sh preparar` (respeita `PONTE_CLONE`).

## 9. A regra que não se negocia

**"Implementado ≠ funciona".** Quando não der para provar o comportamento na
tela, escrever literalmente **"código lido, não comportamento provado"** e deixar
o item aberto. Relatar como concluído o que não foi verificado é a única falha
desta constituição que não tem conserto técnico — depois ninguém sabe mais o que
confere.
