# Modelagem INI

> **O que é este arquivo:** o inventário do que o INI (https://ini.app.br) faz,
> o veredito item a item sobre o que serve para clínica, e o destino de cada
> coisa. É a base da spec de modelagem.
>
> Escrito em 25/08/2026 depois de navegar o sistema logado, e cruzar com
> pesquisa de mercado sobre gestão de clínica. O INI é um software de gestão
> para gráficas de comunicação visual, com mais de trinta empresas usando.
>
> **Por que "modelagem" e não "inspiração":** o layout está pronto, a
> funcionalidade está de pé e o comportamento pode ser aberto no navegador e
> conferido. Não se está desenhando do zero contra um requisito imaginado: se
> está modelando em cima de algo validado em uso real. O que muda é o domínio,
> e a tradução de cada peça está na tabela de veredito.
>
> Faixa B pela §2.5 do `CLAUDE.md`: nada aqui é correção na plataforma ao vivo.
> É **requisito da stack nova**, e o artefato durável é esta regra escrita.

---

## Uma correção minha, registrada porque a conclusão dependia dela

A primeira versão deste documento abria com um "achado": a conta que naveguei
estava com o planejamento em 0 de 28 itens, metas não configuradas e 1 dia
preenchido de 21 dias úteis. Concluí daí que profundidade de configuração é
abandonada no uso.

**A conta é de teste, com configuração inicial apenas.** O Arthur corrigiu, e a
correção derruba a evidência: base de teste vazia não é sinal de abandono, é
sinal de base de teste. O sistema tem mais de trinta empresas usando de fato, e
nenhum dado que eu tenha visto diz o que acontece nelas.

Fica registrado porque o erro tem uma forma reconhecível: **eu li o estado de um
ambiente e tratei como comportamento de usuário.** É o mesmo tipo de engano do
campo de horário desta semana, onde provei a função pura e dei a tela por
fechada. Ambiente não é uso.

**O que sobrevive à correção, por mérito próprio e não por aquela evidência:**

> Toda configuração que entrar deve nascer com um padrão que já funciona, e a
> tela existe para *ajustar* o padrão, não para *criar* do zero.

Isso continua valendo por uma razão independente, e ela é do nosso projeto e não
do INI: o onboarding do NexClin tem 12 passos derivados, e o critério da §2.5 é
o que o cliente fundador consegue operar. Configuração obrigatória para começar
atrasa a primeira consulta lançada.

E vale lembrar por onde a clínica do Vinícius opera: pelos **relatórios**, toda
semana. O painel de configuração é meio, não fim.

---

## O que o INI oferece, na íntegra

Cinco áreas na barra lateral: Início, Painel de Gestão (PGV), Judahzinho (IA),
Planejamento, Relatórios e Cadastros.

### Cadastros: 28 telas em cinco blocos

| Bloco | Telas |
|---|---|
| **Empresa** | Dados da Empresa · Empresas (multi-CNPJ) · Equipe e Permissões · Emitentes Fiscais |
| **Operacional** | Departamentos · Máquinas e Equipamentos · Processos |
| **Financeiro** | Plano de Contas · Centros de Custo · Imobilizado · Custos Fixos · Parâmetros de Precificação · Formas de Pagamento · Condições de Pagamento · Contas Bancárias · Cartões de Crédito · Régua de Cobrança |
| **Comercial** | Matérias-Primas · Produtos e Serviços · Fornecedores · Origens de Lead · Clientes · Motivos de Perda · Informativos de Orçamento · Etapas do Funil de Vendas · Etapas do Pós-Venda |
| **Gestão e RH** | Metas Mensais · Modelos de Formulário de Vaga |

### Painel de Gestão (PGV)

Modelo financeiro anual com oito indicadores: Ciclo Financeiro, Custo Fixo
Rateado, Contribuição Marginal, Resultado em R$, Resultado %, Investido %, RDI
em R$ e RDI %. Mais progresso de metas com projeção, gap e valor por dia útil, e
um bloco de "Alertas e Recomendações".

### Planejamento Estratégico Guiado

Oito estágios encadeados, 28 itens, cada um destravando o seguinte:

1. **Destino pessoal e padrão de vida.** Quanto custa a vida do dono, quanto ele
   precisa ganhar por mês, e qual parte disso depende da empresa.
2. **Necessidade real de caixa.** Dívidas, reserva, capital de giro.
3. **Lucro saudável.** Converte a necessidade de caixa em lucro em R$, com três
   cenários.
4. **Quanto precisa entrar.** `recebimento = lucro / margem`.
5. **Meta real de vendas.** Ajusta recebimento para venda pelo ciclo financeiro.
6. **Volume de propostas.** Quantos orçamentos por dia, a partir de conversão e
   ticket médio.
7. **De onde vêm as oportunidades.** Canais, CAC, mix, e um veredito de
   viabilidade.
8. **Leitura estratégica.** Matriz de forças e fraquezas, cruzada.

### Judahzinho, a IA

Chat com três análises nomeadas em vez de campo livre: **Analisar PGV**,
**Diagnóstico Financeiro** e **Análise de Metas**.

---

## As duas ideias que valem mais que a lista

### 1. A configuração é uma corrente de consequência, não uma gaveta

Cada cartão de cadastro do INI **diz o que ele alimenta**:

- *"Departamentos: áreas operacionais, são as colunas do Kanban de Produção"*
- *"Máquinas: alimenta automaticamente o Imobilizado"*
- *"Motivos de Perda: catálogo usado ao marcar orçamentos como rejeitados"*
- *"Etapas do Pós-Venda: faixas de dias usadas no Kanban de Pós-Venda"*

E o hub abre com uma instrução de ordem: *"comece em Dados da Empresa e use o
botão Avançar ao final de cada tela"*.

**Isto é a coisa mais barata de importar e a de maior retorno.** Não é
funcionalidade nova: é um campo de texto por catálogo, dizendo onde aquele dado
reaparece, mais uma ordem sugerida. Custa quase nada e transforma "tela de
configuração" em "sei por que estou preenchendo isto".

**Entra na SPEC 005 agora.** O registro declarativo de `lib/config/catalogo.ts`
já tem um catálogo por entrada; ganha dois campos, `alimenta` e `ordem`.

### 2. O planejamento guiado é literalmente o que o NexClin promete ser

A §1 do `CLAUDE.md` define o diferencial: *"embarcar metodologia real de gestão
clínica como inteligência do produto, não competir feature a feature com
sistemas genéricos"*.

O Planejamento Guiado do INI é exatamente isso, feito para gráfica. E a corrente
dos estágios 1 a 6 **não tem nada de gráfica**: é a aritmética de qualquer
negócio pequeno com dono presente.

Traduzida para clínica, sem inventar nada:

| Estágio | Versão clínica |
|---|---|
| 1 | Quanto o dono precisa retirar por mês |
| 2 | Quanto a clínica precisa gerar de caixa, com dívidas e reserva |
| 3 | Margem saudável, e o lucro em R$ que ela exige |
| 4 | Quanto precisa entrar: `recebimento = lucro / margem` |
| 5 | Meta de faturamento, ajustada pelo prazo de recebimento (cartão, convênio) |
| 6 | Quantas consultas e quantos orçamentos por dia isso significa |
| 7 | De onde vêm os pacientes, e quanto custa cada um |

O estágio 6 é o que fecha o círculo, porque ele devolve o número que o dono da
clínica não sabe: **quantos pacientes por dia**. E o estágio 5 tem uma tradução
clínica que a versão gráfica não tem, o convênio, que paga em 30 a 90 dias e
desloca todo o caixa.

Isso **não é tarefa de código, é tarefa de sócio.** A metodologia tem dono no
grupo, e é o mentor de gestão clínica. Vira spec depois de uma conversa com ele,
não antes.

---

## Item a item: o que serve, o que adapta, o que não serve

Legenda: **importa** vale a pena e traduz direto · **adapta** a ideia serve com
outro nome · **já existe** o NexClin tem · **não serve** é de gráfica.

### Empresa

| INI | Veredito | Nota |
|---|---|---|
| Dados da Empresa | **importa** | `clinics` existe, mas sem CNPJ, endereço e logotipo. O logotipo aparece em orçamento e recibo. |
| Empresas, multi-CNPJ | **adapta** | Clínica com duas unidades é caso real e comum. Backlog, não agora: mexe na âncora `clinic_id`, que é a trava estrutural do multi-tenant. |
| Equipe e Permissões | **já existe** | `team_members` mais as 15 ModuleKeys. O INI não tem nada que o nosso não tenha. |
| Emitentes Fiscais | **adapta** | NFS-e já está no roadmap do `CLAUDE.md`. |

### Operacional

| INI | Veredito | Nota |
|---|---|---|
| Departamentos | **adapta**, e vira outra coisa | Clínica não tem Kanban de produção. O que ela tem é **sala e equipamento**, e a agenda precisa deles para não marcar dois procedimentos na mesma sala. A pesquisa de mercado lista "salas, equipamentos e profissionais" como o trio que a agenda tem de controlar. |
| Máquinas e Equipamentos | **adapta** | Equipamento clínico com depreciação e manutenção: cadeira, autoclave, raio-x, laser. Alimenta o custo da hora clínica. |
| Processos | **não serve agora** | O análogo é etapa de plano de tratamento, e isso é odonto. Odonto está fechado como vertical. |

### Financeiro, e é aqui que está o valor

| INI | Veredito | Nota |
|---|---|---|
| Plano de Contas | **já existe** | `chart_of_accounts`, e já está na SPEC 005. |
| Centros de Custo | **importa** | Custo por especialidade ou por profissional. É o que permite dizer qual especialidade dá lucro. |
| Imobilizado com depreciação | **importa** | Entra no custo da hora clínica. Sem ele, a clínica acha que lucra e está consumindo o próprio equipamento. |
| **Custos Fixos** | **importa, prioridade alta** | É o insumo obrigatório da hora clínica. Sem custo fixo cadastrado, nenhum preço tem base. |
| **Parâmetros de Precificação** | **importa, e é o diferencial** | Na gráfica é DAS, comissão e lucro. Na clínica é **custo da hora clínica**, imposto, repasse do profissional e margem alvo. Ver a seção seguinte. |
| Formas de Pagamento | **já existe** | `payment_methods` e `acquirers` com taxa. |
| Condições de Pagamento | **adapta** | Parcelamento com entrada e juros existe na prática (a correção FIN-1 desta semana mexeu nisso), mas não é configurável. |
| Contas Bancárias | **já existe** | `bank_accounts`. |
| Cartões de Crédito | **baixa** | Cartão da própria clínica, para despesa. Útil, não urgente. |
| **Régua de Cobrança** | **importa, prioridade alta** | Faixas por dias de atraso e template de mensagem. Ver a seção seguinte. |

### Comercial

| INI | Veredito | Nota |
|---|---|---|
| Matérias-Primas | **adapta** | Materiais e insumos: resina, anestésico, luva, descartável. É o custo variável do procedimento, e é a metade que falta para precificar de verdade. Em odonto e estética, pesa. |
| Produtos e Serviços | **já existe, incompleto** | `services` existe sem campo de custo. Sem custo, não alimenta preço. |
| Fornecedores | **importa** | Média. Faz par com insumos. |
| Origens de Lead | **já existe** | `origins` e `channels`. |
| Clientes | **já existe** | `patients`. |
| Motivos de Perda | **já existe** | `objections`. |
| **Informativos de Orçamento** | **importa, e é barato** | Blocos de texto reutilizáveis: garantia, prazo, política de remarcação. Em clínica ganha um uso a mais e mais importante, o **termo de consentimento** e o aviso de LGPD. |
| Etapas do Funil de Vendas | **já existe** | `funnel_2_entries` e `leads`. |
| **Etapas do Pós-Venda** | **importa** | Faixas de dias configuráveis. Hoje a recaptação do NexClin tem regra fixa em código. Ver a seção seguinte. |

### Gestão e RH

| INI | Veredito | Nota |
|---|---|---|
| **Metas Mensais com "Configurar Mês"** | **importa, e é barato** | Fonte da meta, **dias úteis, feriados** e distribuição semanal. Ver a seção seguinte. |
| Modelos de Formulário de Vaga | **não serve** | Recrutamento não é o problema da clínica. |

---

## As cinco que eu levaria, em ordem

### 1. Metas mensais que sabem quantos dias úteis o mês tem

O NexClin tem `goals`. O que falta é o que o INI chama de "Configurar Mês":
dias úteis, feriados e distribuição semanal.

Sem isso, meta é número no fim do mês. Com isso, ela vira **quanto falta por
dia**, e é assim que o INI mostra: *"21 dias úteis, 4 restantes"*, com gap e
valor por dia útil.

É a diferença entre saber que você está atrasado e saber o que fazer hoje. É
barato: uma tabela de feriados e uma de configuração do mês.

### 2. Régua de cobrança

Faixas por dias de atraso, cada uma com um template de mensagem.

A pesquisa é direta a respeito: clínicas que estruturam cobrança recorrente
relatam **queda de até 60% na inadimplência**, e a régua tira a cobrança do
improviso. Hoje o NexClin sabe quem está em atraso e não faz nada com isso.

Encaixa no que já existe: `receivables` tem vencimento, e a régua é uma tabela
de faixas mais um gerador de tarefa. A esteira de tarefas já está de pé.

### 3. Custo da hora clínica

É o análogo de "Parâmetros de Precificação", e a pesquisa de mercado confirma
que é o indicador central da gestão de clínica: **custo fixo total dividido
pelas horas produtivas do mês, mais o custo variável médio do atendimento**.

A cadeia inteira: `custos fixos` mais `imobilizado` dividido por horas
produtivas resulta na hora clínica; hora clínica mais insumo mais repasse
resulta no preço mínimo do procedimento.

É o que transforma o NexClin de "sistema que registra o que a clínica cobrou"
em "sistema que diz se a clínica devia estar cobrando isso". É o diferencial
de venda, escrito na §1, e hoje ele não existe em lugar nenhum do produto.

**Dependência honesta:** exige custo fixo cadastrado e serviço com custo. Uma
coisa não anda sem a outra, e por isso as três entram juntas ou não entram.

### 4. Faixas de pós-venda e recall configuráveis

No INI vi a tarefa que o sistema gerou sozinho:

> *"Acionar Cliente para Recompra. Faixa: 0 a 7 dias sem comprar."*

O NexClin já faz recaptação, com regra fixa em código. Tornar a faixa
configurável é pequeno e muda quem manda: a clínica passa a decidir o próprio
ciclo de retorno, que em odonto é profilaxia a cada seis meses e em estética é
outro completamente diferente.

Isto é o que sustenta o vertical: a mesma máquina, com faixas diferentes por
especialidade.

### 5. Cada tela de configuração diz o que ela alimenta

O item 1 da seção anterior. Dois campos no registro de catálogos da SPEC 005.
É o de menor custo da lista inteira.

---

## O que o mercado pede e o INI não tem, porque não é clínica

A pesquisa devolveu quatro coisas que nenhuma tela do INI cobre, e três delas
o Vinícius já pediu:

1. **Confirmação de agenda e falta.** A taxa média de falta em clínica no Brasil
   fica entre **20% e 30%** das consultas marcadas, e o canal de maior conversão
   para lembrete em 2026 é o WhatsApp. É o maior ralo de receita que existe na
   operação, e não tem análogo em gráfica: encomenda impressa não falta.
2. **Taxa de ocupação da agenda.** O INI mede "alocação de mão de obra,
   produtiva contra administrativa, meta de 60 contra 40". O equivalente clínico
   é hora de agenda ocupada contra hora disponível, e a pesquisa lista ocupação
   entre os indicadores críticos. **A ideia importa; a métrica muda de nome.**
3. **Prontuário e prescrição.** Já apontado como próximo passo pelo Vinícius, e
   já está no roadmap com a exigência regulatória junto (assinatura digital,
   SBIS e CFM).
4. **Estoque com lote e validade.** Insumo clínico vence, e material vencido em
   paciente é problema sanitário, não de custo. O "Matérias-Primas" do INI não
   tem essa dimensão.

---

## O que eu não levaria, e por quê

- **Departamentos como coluna de Kanban de produção.** Clínica não produz em
  esteira. Copiar a metáfora traria uma tela que ninguém preenche.
- **Processos por departamento.** Análogo é plano de tratamento, e é odonto.
  Odonto está fechado como vertical.
- **Modelos de formulário de vaga.** Recrutamento não é a dor.
- **Multi-CNPJ agora.** É caso real, e mexe na âncora `clinic_id`, que é a trava
  estrutural do isolamento entre clínicas. Não na semana do lançamento.
- **A quantidade.** Ver o achado do topo. Vinte e oito telas de cadastro é o
  desenho que fez a própria conta do Arthur ficar em 0 de 28.

---

## Para onde cada coisa vai

| O quê | Onde entra |
|---|---|
| "O que esta tela alimenta" mais ordem sugerida | **SPEC 005**, agora. É campo no registro de catálogos. |
| Custos fixos, imobilizado, serviço com custo | **SPEC 005**, como três catálogos novos |
| Hora clínica e parâmetros de precificação | **spec própria**, depende dos três acima |
| Régua de cobrança | **spec própria**, depois de `contas_receber` |
| Faixas de recall configuráveis | **SPEC 005** como catálogo, consumido por `tarefas` |
| Informativos de orçamento e termo de consentimento | **SPEC 005**, catálogo de texto |
| Metas mensais com dias úteis e feriados | **SPEC 005** estende `goals` |
| Centros de custo | `BACKLOG.md` |
| Salas e equipamentos | vira requisito da spec de `consultas` |
| Insumos, fornecedores, estoque com validade | **spec própria**, vertical odonto e estética |
| Planejamento guiado da clínica, os 8 estágios | **conversa com o mentor primeiro.** Sem a metodologia dele, seria cópia do modelo de gráfica com as palavras trocadas. |
| Confirmação de agenda por WhatsApp | já no roadmap do `CLAUDE.md` |
| IA com análises nomeadas em vez de chat livre | reespecificar `generate-insights`, que está no backlog. **O formato do INI é o certo:** três análises com nome, não campo em branco. |

---

## Fontes

Pesquisa de mercado consultada em 25/08/2026:

- [Sistema de gestão para clínicas, guia 2026](https://www.gestaods.com.br/sistema-de-gestao-para-clinicas/)
- [Qual software ajuda a reduzir faltas de pacientes](https://www.gestaods.com.br/qual-software-ajuda-a-reduzir-faltas-de-pacientes/)
- [Sistema para clínica, 7 funcionalidades indispensáveis em 2026](https://www.ondoctor.app/blog/sistema-para-clinica-7-funcionalidades-indispensaveis-em-2026)
- [Como precificar tratamentos com a hora clínica](https://www.clinicorp.com/post/parceiros-hora-clinica-isadora-infante)
- [Custos fixos e variáveis na odontologia](https://www.clinicorp.com/post/custos-fixos-e-variaveis)
- [Gestão financeira em odontologia, métricas essenciais](https://blog.simplesagenda.com.br/335/gestao-financeira-odontologia-metricas-essenciais)
- [Régua de cobrança na clínica](https://www.clinicorp.com/post/parceiros-regua-de-cobranca-felipe-bahls)
- [Gestão financeira de clínica com cobrança recorrente](https://bydoctor.com.br/blog/gestao-financeira-clinica-medica-cobranca-recorrente)
