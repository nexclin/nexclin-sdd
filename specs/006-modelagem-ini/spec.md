# SPEC 006 — Modelagem INI

**Feature Branch**: `main` (implantada direto, ver a nota abaixo)

**Created**: 2026-08-26

**Status**: Implementada, spec escrita depois

**Input**: `docs/planejamento/modelagem-ini.md`, o inventário do
**https://ini.app.br** cruzado com pesquisa de mercado sobre gestão de clínica.

---

## A nota que precisa vir antes de tudo

**Esta spec foi escrita depois do código, e isso contraria o Princípio IV da
constituição**, que diz que nenhuma feature entra sem spec aprovada.

O que aconteceu: em 26/08 o Arthur inverteu a prioridade e mandou implantar na
Lovable tudo que já estava definido, com o lançamento em 08/09 como razão. A
definição existia, no documento de modelagem, e a aprovação veio por mensagem,
item a item. Não houve spec.

Ela é escrita agora **como modelagem, sem aceites**, a pedido dele. A razão de
existir mesmo assim: em outubro alguém vai reescrever isto em Next.js, e vai
precisar saber **por que** a régua tem cinco faixas e por que a primeira é antes
do vencimento. Hoje esse porquê vive em mensagens de commit, e mensagem de
commit ninguém procura.

---

## Por que existe uma modelagem, e não uma cópia

O INI é um software de gestão para gráficas de comunicação visual, com mais de
trinta empresas usando. O layout está pronto, a funcionalidade está de pé, e o
comportamento pode ser aberto no navegador e conferido. Não se desenhou contra um
requisito imaginado: modelou-se em cima de algo validado em uso real.

O que muda é o domínio. Na gráfica a unidade de custo é a peça produzida; numa
clínica é **tempo de cadeira**. O veredito item a item está em
`docs/planejamento/modelagem-ini.md`.

**Uma correção de proveniência, porque ela importa:** "custo da hora clínica"
**não é do INI**. O INI tem Custos Fixos, Imobilizado e Parâmetros de
Precificação, com DAS, comissão e lucro. A hora clínica é a tradução para o
domínio de clínica, e vem da pesquisa de mercado.

---

## A regra que ordenou tudo

> **Importar a ideia, não a quantidade.**

O INI tem 28 telas de cadastro. Vinte e oito telas antes de operar é um pedágio:
a clínica que precisa preencher todas não preenche nenhuma.

Consequência aplicada em cada item: **toda configuração nasce com um padrão que
já funciona**, e a tela existe para ajustar, não para criar do zero. Onde o
cadastro ainda não existe, a tela usa o padrão e **diz que está usando padrão**.

---

## O que foi implantado

### FR-001. Régua de cobrança

Cinco faixas por dias de atraso, cada uma com modelo de mensagem.

- **A primeira faixa é ANTES do vencimento.** Lembrar alguém que vai vencer custa
  uma mensagem; cobrar depois custa a relação. A pesquisa aponta o lembrete
  prévio como a etapa que as clínicas mais pulam.
- A partir de 8 dias a faixa marca que **precisa de telefonema**, porque texto
  costuma não resolver.
- A mensagem é **editável antes de enviar**: cobrança é conversa, não disparo. O
  modelo economiza começar do zero; ele não decide o tom.
- **Variável sem dado vira vazio**, nunca `undefined` nem o literal. Cobrança que
  chega escrita "Oi {paciente}" diz ao cliente que o sistema está quebrado, e ele
  para de responder.

**Faixas fixas nesta versão.** Torná-las configuráveis exige coluna nova; o
módulo já está no formato que recebe faixas do banco sem mudar de forma.

### FR-002. Custo da hora clínica e preço mínimo

```
custo fixo + depreciação
------------------------  =  hora clínica
   horas produtivas

(hora clínica × duração) + insumo
---------------------------------  =  preço mínimo
1 − repasse% − imposto% − margem%
```

- **A ocupação é o número que quase ninguém põe na conta**, e é o que mais muda o
  resultado. Ignorá-la subestima a hora clínica em 30% no cenário padrão.
- **Duas situações ruins, e elas são distintas.** "Abaixo do custo" sangra a cada
  atendimento e é emergência. "Abaixo da margem alvo" paga o custo e não o lucro,
  e é decisão: pode ser procedimento de porta de entrada. Misturar as duas faria
  a clínica tratar ambas com a mesma urgência.
- **A trava da fatia.** Se repasse, imposto e margem somarem 100%, não sobra nada
  para o custo e o preço tende ao infinito; passando de 100%, a divisão vira
  negativa e a tela diria que está tudo bem.

### FR-003. Imobilizado

Bens com depreciação linear mensal, separados do custo fixo por uma razão: o
aluguel sai do caixa todo mês e a clínica sente; a cadeira saiu do caixa **uma
vez** e continua se gastando sem ninguém ver.

**Vida útil zero significa não deprecia**, e é deliberado. Obrigar um número faria
a pessoa inventar um. Zero deixa o bem de fora, o que subestima o custo, e é o
lado seguro dos dois.

### FR-004. Insumos, fornecedores e composição de custo

`services.cost` era um número digitado à mão, que ninguém sabia de onde veio e
que nunca era atualizado.

**O erro que a modelagem impede:** lançar o preço da **compra** como custo do
procedimento. Uma caixa de 100 luvas por R$ 30 custa R$ 0,30 o par. Por isso o
insumo guarda duas coisas e nunca uma: quanto custou a compra, e quantas unidades
de uso vieram nela.

**A composição não substitui `services.cost`, ela alimenta.** Trocar a leitura em
toda parte obrigaria a reescrever orçamento, fechamento e relatório de uma vez. A
tela mostra o composto ao lado do gravado e oferece gravar.

### FR-005. Metas com dias úteis

A meta do mês traduzida para **quanto falta por dia útil**. E o **ritmo**: 40% do
mês decorrido com 20% da meta batida é atraso, e o percentual sozinho não conta
isso.

**Feriados nacionais calculados, não cadastrados.** Quatro dos onze dependem da
Páscoa. Pedir doze feriados por ano é o pedágio que a regra do topo manda evitar.

**Dívida declarada:** feriado municipal não entra, e aniversário de cidade fecha
clínica. O cálculo erra para **mais** dias úteis, ou seja, exige um pouco menos
por dia. É o lado seguro.

### FR-006. Ocupação da agenda e taxa de falta

A precificação perguntava a ocupação. O sistema tem os agendamentos e pode medir.

- **Exato:** consultas marcadas, faltas, canceladas, realizadas.
- **Estimado até o FR-008:** as horas ocupadas, porque `appointments` não
  guardava duração.
- **A taxa de falta é o achado.** A pesquisa aponta entre 20% e 30% nas clínicas
  brasileiras, é o maior ralo de receita da operação, e não aparecia em lugar
  nenhum do sistema.
- **A taxa é sobre quem teve desfecho**, não sobre tudo que foi marcado. Incluir
  o futuro diluiria: agenda cheia de futuro pareceria ter menos falta.
- **Cancelada não conta como falta**: alguém avisou, e o horário pode ter sido
  reocupado.

### FR-007. Recall

`business_rules.recall_days` existia, aparecia na tela, e **nada no código o
consumia**. A clínica configurava e nunca acontecia nada.

- **A data que conta é a do atendimento que aconteceu**, não a do último
  agendamento. Quem marcou e faltou não voltou.
- **"Chegando" existe para o recall poder ser convite e não resgate.** A janela é
  15% do próprio prazo, com piso de 7 dias, então acompanha a especialidade em
  vez de ser um número fixo.
- **A mensagem fala em meses, não em dias.** "Faz 187 dias" soa a cobrança de
  sistema; "faz 6 meses" soa a convite de clínica.
- **Quem está em dia não entra na lista.** Lista que mistura todo mundo obriga a
  filtrar antes de agir, e a pessoa não filtra: ela fecha a tela.

### FR-008. Salas, equipamentos e duração da consulta

- **A duração vem junto e não é escopo extra.** Conflito é sobreposição de
  intervalo, e `appointments` guardava um instante. Sem duração não existe
  intervalo.
- **Sala e equipamento na mesma tabela.** Para a agenda os dois são a mesma
  coisa: um recurso que só uma consulta usa por vez. Separar obrigaria a duplicar
  a detecção, e detecção duplicada é onde uma das cópias fica para trás.
- **O menor estrito.** Consulta que termina 10h e outra que começa 10h **não**
  conflitam. Com `<=`, toda agenda encaixada viraria alarme, e alarme falso ensina
  a ignorar a tela.
- **O conflito é mostrado, não impedido.** A base nasce com conflitos, porque a
  duração nasceu hoje; e nem toda sobreposição é erro, porque encaixe é rotina.
  Barrar obrigaria a clínica a mentir a duração, e aí o dado de ocupação vira lixo.

### FR-009. Informativos de orçamento, termo e recibo

Blocos de texto reutilizáveis. Resolve a **fonte** do texto: o termo de
consentimento passa a viver num lugar só, em vez de num arquivo do Word com uma
cópia diferente por recepcionista.

**Não resolve assinatura com validade jurídica**, que exige certificado digital e
é roadmap. A tela diz isso, porque confundir os dois faria a clínica achar que
está coberta quando não está.

### FR-010. Cada tela de configuração diz o que alimenta

As onze seções de Configurações passaram a listar **onde cada cadastro é usado**.
Custa um campo por seção, e transforma "tela de configuração" em "sei por que
estou preenchendo isto". Foi o item de maior retorno por menor custo da pesquisa.

---

## Decisões de arquitetura que valem para toda a spec

**D-006.1. Núcleo puro, separado da tela.** Cada funcionalidade tem um módulo sem
banco, sem relógio e sem navegador. O relógio é parâmetro, porque função que lê o
relógio não se testa. É o que permitiu provar 46 casos sem subir nada.

**D-006.2. Toda tela funciona antes da migração.** Onde a tabela não existe, a
tela avisa qual migração falta em vez de quebrar. O número sai **subestimado**,
nunca superestimado.

**D-006.3. Nenhuma ModuleKey nova.** Chave nova exige emenda à constituição
(Princípio III). As telas novas vivem sob chaves existentes: `contas_receber`
para a régua, `pacientes` para o recall, `configuracoes` para preço, insumos e
informativos, `acompanhamento` para salas.

**D-006.4. `clinic_id` nunca é escrito pela aplicação.** As tabelas novas têm
`DEFAULT public.get_my_clinic_id()`. A âncora é do banco, e mandar o id do
cliente faria a aplicação virar a autoridade sobre qual clínica é a minha.

**D-006.5. O dia é o brasileiro, a conta é em UTC.** Comparar por dia em UTC evita
que fuso de servidor mude o resultado, mas "hoje" precisa ser o calendário de São
Paulo. `hoje.ts` faz a ponte, e nenhuma função pura precisou mudar.

---

## O que esta spec deliberadamente NÃO faz

- **Não cria ModuleKey.** Ver D-006.3.
- **Não impede conflito de agenda por constraint.** Ver FR-008.
- **Não substitui `services.cost` na leitura.** Ver FR-004.
- **Não implementa assinatura digital.** Ver FR-009.
- **Não torna as faixas de cobrança configuráveis.** Ver FR-001.
- **Não traz aceites.** A pedido do Arthur em 26/08. Quando alguém for testar,
  os critérios saem dos "porquês" acima, e é para isso que eles estão escritos.

---

## Onde cada coisa vive

| O quê | Arquivo |
|---|---|
| Régua de cobrança | `src/lib/reguaDeCobranca.ts`, `src/pages/Cobranca.tsx` |
| Precificação | `src/lib/precificacao.ts`, `src/pages/Precificacao.tsx` |
| Imobilizado | `src/components/precificacao/Imobilizado.tsx` |
| Insumos e composição | `src/lib/composicao.ts`, `src/pages/Insumos.tsx` |
| Metas e dias úteis | `src/lib/diasUteis.ts`, `src/components/dashboard/MetaDoMes.tsx` |
| Ocupação e falta | `src/lib/ocupacao.ts` |
| Recall | `src/lib/recall.ts`, `src/pages/Recall.tsx` |
| Salas e conflitos | `src/lib/agendaDeRecursos.ts`, `src/pages/Salas.tsx` |
| Informativos | `src/pages/Informativos.tsx` |
| O dia brasileiro | `src/lib/hoje.ts` |

Caminhos do repositório da Lovable (`nexclin/nexclin`). As migrações vivem em
`supabase/migrations/` deste repositório, que é a fonte de verdade do schema.
