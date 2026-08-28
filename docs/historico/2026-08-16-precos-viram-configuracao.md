# Preços aprovados viram configuração no sistema

> **Tarefa do cronograma:** 14/08 · Arthur.
> **Fonte dos números:** `NexClin - Pesquisa de Mercado e Precificacao.html`
> (16/08/2026), Resumo executivo e seção 16, Plano de ação, passo 1.
> **Onde isso acontece:** plataforma Lovable ao vivo (`nexclin.lovable.app`) —
> é ela que recebe cliente em 01/09. A stack nova não entra aqui.

---

## ESTADO — atualizado em 16/08/2026, ~23h

**Etapa 0.2 está feita.** Os três planos foram criados no banco ao vivo pelo
SQL editor do Cloud, com `visibility='hidden'`, `trial_days=30`, os 15 módulos
ligados e `max_users` 3/5/8. O `Trial Padrão` original não foi tocado. Custo:
zero crédito.

**A rota das etapas seguintes está decidida: repositório, não prompt.** A
Verificação A passou — commit no GitHub chega ao editor e publica sem consumir
crédito (ver `2026-08-16-verificacoes-tecnicas.md`). Portanto **os prompts abaixo
não devem ser usados**; valem como especificação da tarefa para quem for
escrever o código.

**Preço anual definido: 1 mês grátis (8,3%).**

| Faixa | Mensal | Anual | Equivale a |
|---|---|---|---|
| Essencial · 3 | R$ 249 | **R$ 2.739** | 11 meses |
| Clínica · 5 | R$ 399 | **R$ 4.389** | 11 meses |
| Corpo Clínico · 8 | R$ 599 | **R$ 6.589** | 11 meses |

Por que 1 mês e não 2: a faixa pedida foi de 5 a 10%, e "pague 11, leve 12" cai
dentro dela (8,3%), tem conta redonda e se explica numa frase. O mercado
próximo pratica 10% (Simples Dental) e 15% (Shosp), então não fica fora do
padrão. E principalmente: **desconto é fácil de dar e quase impossível de
tirar.** Guardando o segundo mês, sobra uma alavanca de fechamento para a
clínica que empacar no preço, em vez de queimá-la na tabela com todo mundo.

Se a conversão anual vier fraca depois dos primeiros clientes, subir para 2
meses (16,7%, a recomendação original da pesquisa) é um `update` de uma linha.

**O que continua com você:**
1. **Publicar os planos** — trocar `visibility` de `hidden` para `public`
   quando a tabela for aprovada (prazo 18/08 no documento de precificação).
2. **Decidir a duração do trial.** `saas_settings` segue em **14 dias**; o
   plano de lançamento prevê 30. Não mudei porque isso afeta todo cadastro
   novo, inclusive a clínica que o Vinícius cria amanhã.
3. **Preencher o e-mail de suporte** em `/superadmin/configuracoes` (Etapa 0.1),
   que continua vazio.

---

## A descoberta que muda o custo desta tarefa

**A tela de planos já existe no painel superadmin, e o formulário de trial
também.** Isso está registrado no walkthrough de 16/08:

- `/superadmin/planos` — botão "+ Novo Plano", tabela com NOME · MENSAL ·
  ANUAL · TRIAL · STATUS · VISIBILIDADE e ações de editar e duplicar. Hoje há
  um único plano: `Trial Padrão · R$ 0,00 · R$ 0,00 · 14 dias · Ativo ·
  Interno` ([../referencia/INVENTARIO-UI.md:199-200](../referencia/INVENTARIO-UI.md)).
- `/superadmin/configuracoes` — bloco "Configurações de Trial" com Duração
  padrão (14), Plano do trial, Máx. extensão e toggle de cartão
  ([../referencia/INVENTARIO-UI.md:224-228](../referencia/INVENTARIO-UI.md)).

**Consequência:** a maior parte desta tarefa é **digitação em tela que já
existe — zero crédito, zero código, zero prompt.** Escrever prompt para o
Lovable criar o que já está criado é queimar crédito à toa.

A regra deste documento, então:

| Rota | Quando usar | Custo |
|---|---|---|
| **Etapa 0 — formulário** | tudo que a tela já suporta | R$ 0 |
| **Etapa 1+ — repositório** | o que falta, se a Verificação A passar | R$ 0 |
| **Etapa 1+ — prompt no Lovable** | o que falta, **só se a Verificação A falhar** | crédito |

Faça a Etapa 0 primeiro e **pare**. Só siga para as etapas seguintes depois de
constatar, na própria tela, o que o formulário não suporta.

---

## Os números aprovados

| Item | Valor |
|---|---|
| Faixa 3 usuários | **R$ 249 / mês** |
| Faixa 5 usuários | **R$ 399 / mês** |
| Faixa 8 usuários | **R$ 599 / mês** |
| Usuário adicional (acima de 8) | **R$ 89 / mês** |
| Implantação remota | **R$ 1.200**, cobrada no ato |
| Implantação presencial | **R$ 2.400**, cobrada no ato |
| Trial | **30 dias**, só grupo fundador |

**Regra do trial, a escrever antes do contato de 18/08:** o trial isenta a
**mensalidade**, nunca a **implantação**. É a primeira pergunta que a clínica
faz.

**Cobrança da implantação:** 50% na assinatura, 50% na sessão final.

**Duas decisões que ainda não estão fechadas** — não invente, confirme com
Erick antes de digitar:

1. **Preço anual.** A pesquisa recomenda "anual com 2 meses de desconto"
   (seção de churn), o que dá **R$ 2.490 / R$ 3.990 / R$ 5.990 por ano**. É
   dedução da recomendação, não número aprovado. Se não houver decisão até a
   digitação, preencha o campo ANUAL com o mesmo mensal × 12 e marque para
   revisar — nunca deixe R$ 0,00, que na tela lê como "grátis".
2. **Prazo de aprovação.** O próprio documento de precificação trata "aprovar
   a tabela e a regra do trial" como tarefa **P1 com prazo 18/08**, e o
   cronograma manda configurar em 14/08. Se a aprovação formal ainda não
   aconteceu, configure os planos como **ocultos** (visibilidade interna) e só
   publique depois do aceite. Assim a tarefa fecha sem antecipar decisão de
   sócio.

---

## Etapa 0 — o que fazer sem gastar nada

### 0.1 · Ajustar o trial padrão

`/superadmin/configuracoes` → bloco **Configurações de Trial**:

- Duração padrão: `14` → **`30`**
- Plano do trial: manter `Trial Padrão`
- Máx. extensão: manter `14` (permite esticar meio mês sem virar decisão nova)
- Exigir cartão no trial: **desligado** (o grupo fundador não vai passar cartão
  antes de usar)
- **Salvar** e recarregar a página para confirmar que gravou.

Ainda nesse formulário, o bloco **Configurações Gerais** está com os três
campos vazios (e-mail de suporte, URL dos Termos, URL da Política). Preencher o
e-mail de suporte agora é gratuito e evita um apontamento previsível do
Vinícius. As duas URLs dependem das cláusulas 9 e 9.2, que fecham entre 18 e
20/08 — deixe para depois.

### 0.2 · Criar os três planos

`/superadmin/planos` → **+ Novo Plano**, três vezes. Valores:

| Campo | Plano 1 | Plano 2 | Plano 3 |
|---|---|---|---|
| Nome | `Essencial · 3 usuários` | `Clínica · 5 usuários` | `Corpo Clínico · 8 usuários` |
| Mensal | `249,00` | `399,00` | `599,00` |
| Anual | ver decisão 1 | ver decisão 1 | ver decisão 1 |
| Trial (dias) | `30` | `30` | `30` |
| Status | Ativo | Ativo | Ativo |
| Visibilidade | ver decisão 2 | ver decisão 2 | ver decisão 2 |
| Máx. usuários | `3` | `5` | `8` |
| Máx. pacientes | vazio = ilimitado | vazio = ilimitado | vazio = ilimitado |
| Máx. leads/mês | vazio = ilimitado | vazio = ilimitado | vazio = ilimitado |
| Módulos habilitados | **os 15, todos ligados** | **os 15** | **os 15** |

**Sobre os módulos:** as 15 chaves são o contrato único do sistema —
`dashboard, leads, pacientes, anamnese, consultas, acompanhamento, tarefas,
contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas,
relatorios_demais, configuracoes, equipe, insights`. Ligue **todas** nas três
faixas. Diferenciar faixa por módulo agora criaria um teto que ninguém decidiu,
e a diferença entre as faixas é **número de usuários**, não funcionalidade.

**Não** apague nem edite o `Trial Padrão` existente — ele é o plano que a
configuração de trial aponta. Crie os três ao lado dele.

### 0.3 · Conferir, ainda de graça

1. Recarregue `/superadmin/planos`: os 4 planos aparecem com os valores certos?
2. Abra `/superadmin/contas/:id` de uma conta de teste → botão **Alterar
   Plano**: as três faixas novas aparecem na lista?
3. O contador "Acessos: X de Y" reflete o `Máx. usuários` do plano escolhido?
   (Atenção: o walkthrough registra que esse contador **não apareceu** na
   interface — divergência D4. Se continuar ausente, isso é lacuna real, e vira
   Etapa 2.)

**Pare aqui e anote o que o formulário NÃO ofereceu.** É essa lista, e só ela,
que justifica as etapas seguintes.

---

## O que provavelmente vai faltar

Três coisas que o modelo de preço exige e que não há evidência de existirem:

| Lacuna | Por que importa | Gravidade |
|---|---|---|
| **Usuário adicional a R$ 89** | não há conceito de add-on; o plano tem teto fixo | média — dá para contornar |
| **Implantação (R$ 1.200 / R$ 2.400)** | é cobrança única, não assinatura | baixa — ver contorno |
| **Contador de assentos na tela** | divergência D4, o cliente não vê quanto pode usar | média |

**Contorno sem código para o usuário adicional:** duplique o plano da faixa 8
(a tela tem botão ⧉ duplicar) e crie `Corpo Clínico · 9 usuários — R$ 688`,
`· 10 usuários — R$ 777`, e assim por diante conforme a venda pedir. É feio no
catálogo, mas é **grátis, imediato e reversível**, e a matemática bate com
R$ 599 + 89×n. Só vale a pena construir add-on de verdade quando existir o
segundo cliente pedindo.

**Contorno para a implantação:** ela é cobrada no ato, fora da recorrência, com
50% na assinatura. Nos primeiros clientes isso é cobrança manual (PIX ou link),
registrada no contrato — não precisa existir no sistema em setembro. Construir
cobrança avulsa agora competiria com a migração e não desbloqueia nenhuma venda.

---

## Etapa 1 — se, e só se, algo faltar

**Antes de escrever qualquer prompt, decida a rota** pelo resultado da
Verificação A (a do fim de semana):

- **Verificação A passou** → não use prompt nenhum. A mudança vai por commit no
  repositório `nexclin/nexclin`, custo zero. Use o texto dos prompts abaixo como
  especificação da tarefa, não como mensagem para o Lovable.
- **Verificação A falhou** → aí sim, prompt no Lovable, e cada um custa. As
  regras abaixo existem para que custe o mínimo.

### Regras para não desperdiçar crédito

1. **Um prompt = uma entrega fechada.** Nunca mande "e também...". Cada ida ao
   chat custa igual, seja o pedido pequeno ou grande.
2. **Diga o estado atual antes do pedido.** O modelo não sabe o que já existe;
   sem isso ele reescreve tela pronta e você paga por regressão.
3. **Proíba explicitamente o que não pode mudar.** Sem isso, a IA "melhora"
   coisas que ninguém pediu — foi assim que 60 créditos viraram uma
   funcionalidade só.
4. **Peça o critério de aceite dentro do prompt.** Se você não descreve como se
   confere, a resposta volta plausível e errada, e a correção custa outro
   crédito.
5. **Nunca peça mudança de banco e de tela no mesmo prompt.** Migração errada
   custa muito mais caro que tela errada.
6. **Antes de mandar, releia e pergunte:** "isso dá para fazer pelo formulário?"
   Se der, não mande.

### Prompt 1 — campos de limite no formulário de plano

> *Use só se a Etapa 0.2 mostrar que o formulário "+ Novo Plano" não tem os
> campos de limite.*

```
No painel superadmin, tela /superadmin/planos, o formulário de criar e editar
plano hoje não expõe os limites do plano.

Estado atual: a tabela lista NOME, MENSAL, ANUAL, TRIAL, STATUS e
VISIBILIDADE. A tabela plans no banco já tem as colunas max_users,
max_patients, max_leads_month e enabled_modules — elas existem e não devem ser
criadas nem alteradas.

Tarefa: exibir esses quatro campos no formulário de criar e de editar plano,
lendo e gravando nas colunas que já existem.
- max_users, max_patients, max_leads_month: campos numéricos opcionais. Vazio
  significa ilimitado e deve gravar NULL, não zero. Mostrar a dica "vazio =
  ilimitado" ao lado de cada um.
- enabled_modules: lista de 15 interruptores, um por chave, exatamente estas e
  nesta ordem: dashboard, leads, pacientes, anamnese, consultas, acompanhamento,
  tarefas, contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas,
  relatorios_demais, configuracoes, equipe, insights. Gravar como jsonb de
  booleanos. Novo plano nasce com todos ligados.

Não altere: nenhuma migração, nenhuma policy RLS, nenhuma outra tela, e nada
na lógica de permissões que lê essas colunas.

Critério de aceite: criar um plano com max_users = 3 e todos os módulos
ligados; reabrir o plano para edição e ver os mesmos valores; deixar
max_patients vazio e confirmar no banco que gravou NULL.
```

### Prompt 2 — contador de assentos na interface

> *Use só se a Etapa 0.3 confirmar que o contador continua ausente.*

```
Na interface da clínica, não aparece em lugar nenhum quantos acessos o plano
permite e quantos já estão em uso. O cliente descobre o limite só quando é
bloqueado.

Estado atual: o limite já é aplicado pelo banco por trigger em team_members, e
o plano já tem a coluna max_users. Falta apenas exibir.

Tarefa: mostrar "Acessos: X de Y" no diálogo de Equipe, em Configurações, onde
X é o número de membros ativos da clínica e Y é o max_users do plano vigente.
Quando max_users for NULL, escrever "Acessos: X · ilimitado". Quando X for
igual a Y, destacar o texto e desabilitar o botão de convidar, com a explicação
de que o limite do plano foi atingido.

Não altere: o trigger que aplica o limite, nenhuma policy, nenhuma migração. A
tela apenas reflete o que o banco já decide.

Critério de aceite: numa clínica em plano de 3 acessos com 2 membros, ler
"Acessos: 2 de 3"; convidar o terceiro e ver "3 de 3" com o botão desabilitado;
trocar para um plano de max_users NULL e ver "ilimitado".
```

### Prompt 3 — usuário adicional de verdade

> *Não use agora.* Fica escrito para quando existir cliente pedindo. Enquanto o
> contorno de duplicar plano resolver, este prompt é dinheiro gasto sem venda
> desbloqueada.

```
O modelo de preço prevê usuário adicional a R$ 89/mês acima da faixa de 8, e
hoje o plano só tem teto fixo.

Tarefa: permitir que uma assinatura tenha N assentos extras além do max_users
do plano, com preço unitário definido no plano. O limite efetivo passa a ser
max_users + assentos_extras, e o valor cobrado passa a ser mensalidade +
(assentos_extras × preço unitário). Exibir os dois números separados no detalhe
da conta.

Não altere: as 15 ModuleKeys, a cascata de permissões, nenhuma policy RLS.

Critério de aceite: conta na faixa de 8 com 2 assentos extras aceita 10 membros
e mostra R$ 599 + R$ 178 = R$ 777; remover os extras volta a bloquear no 9º.
```

---

## Ordem de execução, em uma linha

Etapa 0 (grátis, hoje) → anotar o que faltou → conferir o resultado da
Verificação A → se passou, repositório; se falhou, Prompt 1 e depois Prompt 2,
um de cada vez, conferindo o critério de aceite antes de mandar o seguinte.

**O Prompt 3 não entra antes do lançamento.**
