# 006 · Modelagem INI: cobrança, precificação, ocupação e recall

> **Regra viva, escrita depois da execução.** Ela é a exceção que deu nome ao
> termo: dez requisitos numerados, onze commits e seis migrações, e a regra
> nasceu no fim. **Isso contraria o Princípio IV**, e está registrado abaixo.
>
> **Estado em 27/08/2026:** implantada na plataforma Lovable. **Sem critérios de
> aceite**, a pedido do Arthur em 26/08.
>
> **Lei:** `docs/constituicao.md` · **Entrada:**
> `../referencia/modelagem-ini.md` ·
> **Origem:** convertida da SPEC 006 em 27/08/2026, formato de sete seções.

---

## 1. O problema

Em 26/08 o Arthur inverteu a prioridade e mandou implantar na Lovable tudo que já
estava definido, com o lançamento em 08/09 como razão. A definição existia, no
documento de modelagem, e a aprovação veio por mensagem, item a item. Não houve
spec. Esta regra é escrita depois porque em outubro alguém vai reescrever isto em
Next.js e vai precisar saber **por que** a régua de cobrança tem cinco faixas e
por que a primeira é antes do vencimento. Hoje esse porquê vive em mensagens de
commit, e mensagem de commit ninguém procura.

**Por que uma modelagem e não uma cópia.** O INI é um software de gestão para
gráficas de comunicação visual, com mais de trinta empresas usando: o layout está
pronto, o comportamento pode ser aberto no navegador e conferido. Não se desenhou
contra um requisito imaginado. O que muda é o domínio: na gráfica a unidade de
custo é a peça produzida, numa clínica é **tempo de cadeira**. Correção de
proveniência que importa: "custo da hora clínica" **não é do INI**. O INI tem
Custos Fixos, Imobilizado e Parâmetros de Precificação. A hora clínica é a
tradução para o domínio de clínica, e vem da pesquisa de mercado.

**A regra que ordenou tudo:** *importar a ideia, não a quantidade.* O INI tem 28
telas de cadastro, e 28 telas antes de operar é um pedágio: a clínica que precisa
preencher todas não preenche nenhuma. Consequência aplicada item a item: **toda
configuração nasce com um padrão que já funciona**, e onde o cadastro ainda não
existe a tela usa o padrão e **diz que está usando padrão**.

## 2. Requisitos

- **FR-001. Régua de cobrança**, cinco faixas por dias de atraso, cada uma com
  modelo de mensagem. *Porquê:* a primeira faixa é **antes do vencimento**, e
  lembrar alguém que vai vencer custa uma mensagem enquanto cobrar depois custa a
  relação. A partir de 8 dias a faixa marca que **precisa de telefonema**, porque
  texto costuma não resolver. A mensagem é **editável antes de enviar**, porque
  cobrança é conversa e não disparo: o modelo economiza começar do zero, ele não
  decide o tom. E **variável sem dado vira vazio**, nunca `undefined` nem o
  literal, porque cobrança que chega escrita "Oi {paciente}" diz ao cliente que o
  sistema está quebrado, e ele para de responder.
- **FR-002. Custo da hora clínica e preço mínimo.**
  `hora clínica = (custo fixo + depreciação) / horas produtivas`;
  `preço mínimo = (hora clínica × duração + insumo) / (1 − repasse% − imposto% − margem%)`.
  *Porquê:* a **ocupação** é o número que quase ninguém põe na conta e é o que
  mais muda o resultado. Ignorá-la subestima a hora clínica em 30% no cenário
  padrão. E "abaixo do custo" e "abaixo da margem alvo" são **situações
  distintas**: a primeira sangra a cada atendimento e é emergência, a segunda
  paga o custo e não o lucro e é decisão, porque pode ser procedimento de porta
  de entrada. Misturar as duas faria a clínica tratar ambas com a mesma urgência.
  A **trava da fatia** existe porque se repasse, imposto e margem somarem 100%
  não sobra nada para o custo e o preço tende ao infinito; passando de 100% a
  divisão vira negativa e a tela diria que está tudo bem.
- **FR-003. Imobilizado** com depreciação linear mensal, separado do custo fixo.
  *Porquê:* o aluguel sai do caixa todo mês e a clínica sente; a cadeira saiu do
  caixa **uma vez** e continua se gastando sem ninguém ver. **Vida útil zero
  significa não deprecia**, e é deliberado: obrigar um número faria a pessoa
  inventar um. Zero deixa o bem de fora, o que subestima o custo, e é o lado
  seguro dos dois.
- **FR-004. Insumos, fornecedores e composição de custo.** O insumo **MUST**
  guardar duas coisas e nunca uma: quanto custou a compra, e quantas unidades de
  uso vieram nela. *Porquê:* o erro que a modelagem impede é lançar o preço da
  **compra** como custo do procedimento. Uma caixa de 100 luvas por R$ 30 custa
  R$ 0,30 o par. A composição **não substitui `services.cost`, ela alimenta**:
  trocar a leitura em toda parte obrigaria a reescrever orçamento, fechamento e
  relatório de uma vez, então a tela mostra o composto ao lado do gravado e
  oferece gravar.
- **FR-005. Metas com dias úteis**, traduzidas para quanto falta por dia útil, e
  com o **ritmo**. *Porquê:* 40% do mês decorrido com 20% da meta batida é
  atraso, e o percentual sozinho não conta isso. **Feriados nacionais são
  calculados, não cadastrados**, porque quatro dos onze dependem da Páscoa e
  pedir doze feriados por ano é o pedágio que a regra do topo manda evitar.
  **Dívida declarada:** feriado municipal não entra, e aniversário de cidade
  fecha clínica. O cálculo erra para **mais** dias úteis, ou seja, exige um pouco
  menos por dia, que é o lado seguro.
- **FR-006. Ocupação da agenda e taxa de falta.** *Porquê:* a precificação
  perguntava a ocupação, e o sistema tem os agendamentos e pode medir. Consultas
  marcadas, faltas, canceladas e realizadas são exatas; as horas ocupadas são
  estimadas até o FR-008, porque `appointments` não guardava duração. **A taxa de
  falta é o achado**: a pesquisa aponta entre 20% e 30% nas clínicas brasileiras,
  é o maior ralo de receita da operação, e não aparecia em lugar nenhum do
  sistema. Ela é calculada **sobre quem teve desfecho**, não sobre tudo que foi
  marcado, senão agenda cheia de futuro pareceria ter menos falta. E **cancelada
  não conta como falta**: alguém avisou, e o horário pode ter sido reocupado.
- **FR-007. Recall.** *Porquê:* `business_rules.recall_days` existia, aparecia na
  tela, e **nada no código o consumia**: a clínica configurava e nunca acontecia
  nada. A data que conta é a do **atendimento que aconteceu**, não a do último
  agendamento, porque quem marcou e faltou não voltou. **"Chegando" existe para o
  recall poder ser convite e não resgate**, com janela de 15% do próprio prazo e
  piso de 7 dias, para acompanhar a especialidade em vez de ser número fixo. A
  mensagem **fala em meses, não em dias**, porque "faz 187 dias" soa a cobrança
  de sistema e "faz 6 meses" soa a convite de clínica. E **quem está em dia não
  entra na lista**, porque lista que mistura todo mundo obriga a filtrar antes de
  agir, e a pessoa não filtra: ela fecha a tela.
- **FR-008. Salas, equipamentos e duração da consulta.** *Porquê:* a duração vem
  junto e não é escopo extra, porque conflito é sobreposição de **intervalo** e
  `appointments` guardava um instante. **Sala e equipamento na mesma tabela**,
  porque para a agenda os dois são a mesma coisa, um recurso que só uma consulta
  usa por vez, e separar obrigaria a duplicar a detecção, que é onde uma das
  cópias fica para trás. **O menor estrito**: consulta que termina 10h e outra
  que começa 10h **não** conflitam, porque com `<=` toda agenda encaixada viraria
  alarme, e alarme falso ensina a ignorar a tela. E **o conflito é mostrado, não
  impedido**: a base nasce com conflitos porque a duração nasceu hoje, encaixe é
  rotina, e barrar obrigaria a clínica a mentir a duração, e aí o dado de
  ocupação vira lixo.
- **FR-009. Informativos de orçamento, termo e recibo**, blocos de texto
  reutilizáveis. *Porquê:* resolve a **fonte** do texto, e o termo de
  consentimento passa a viver num lugar só em vez de num arquivo do Word com uma
  cópia diferente por recepcionista. **Não resolve assinatura com validade
  jurídica**, que exige certificado digital e é roadmap, e a tela diz isso, porque
  confundir os dois faria a clínica achar que está coberta quando não está.
- **FR-010. Cada tela de configuração diz o que alimenta.** As onze seções de
  Configurações listam **onde cada cadastro é usado**. *Porquê:* custa um campo
  por seção e transforma "tela de configuração" em "sei por que estou preenchendo
  isto". Foi o item de maior retorno por menor custo da pesquisa.

- **FR-011. Com a barra lateral recolhida, o grupo Financeiro **MUST** ser um
  único ícone com seta, e a lista **MUST** sair na horizontal ao passar o
  mouse.** O flyout **MUST** espelhar exatamente os itens do grupo, sem
  acrescentar nem remover nenhum, e **MUST** mostrar o nome inteiro (`title`),
  não o encurtado (`label`). Também **MUST** abrir por foco de teclado e por
  clique, porque em tela sensível ao toque não existe passar o mouse.

  *Porquê:* a modelagem do INI levou o grupo de três para nove itens, e com a
  barra em 80px os nove viravam nove ícones iguais empilhados, sem nada que os
  lesse como conjunto. Relato do Arthur em 28/08/2026: *"quando a barra lateral
  está recolhida, os ícones ficam em forma de [lista] e fica um pouco poluído.
  Pro cliente não ter que ficar abrindo toda hora a barra pra se locomover."*

  **Decisões dele, no mesmo dia, que esta regra fixa:** abre no passar do mouse;
  espelha o grupo existente, sem redesenhar a estrutura (*"é pra redesenhar o
  que já existe, não quero mudar a estrutura de nada"*).

  **Registrado porque contraria a classificação:** isto é faixa C pela §2.5, e
  eu recomendei escrever a regra sem construir, já que o componente será
  reescrito na stack nova. **O Arthur decidiu construir agora**, reafirmando
  duas vezes, pelo ganho de experiência antes de 08/09. A decisão é dele e está
  implementada na plataforma no commit `56dc5d5`. A regra continua valendo como
  requisito da stack nova, que é o que de fato atravessa outubro.

  **A armadilha técnica, para quem reimplementar:** `.nx-sidebar-nav` tem
  `overflow-y: auto`, e caixa posicionada de forma absoluta dentro de container
  que rola **é recortada na horizontal**. O flyout precisa de `position: fixed`
  com as coordenadas lidas do `getBoundingClientRect()` do gatilho. Isso só
  funciona porque nenhum ancestral cria bloco de contenção: a barra é `sticky`,
  que não cria, e não há `transform` no caminho. Um `transform` adicionado ali
  no futuro quebra o flyout **em silêncio**.

  **A segunda armadilha:** entre o ícone e a caixa há um vão de 8px onde o mouse
  não está em nenhum dos dois. Fechar no `mouseleave` sem folga faz o flyout
  piscar e ficar inusável. A implementação usa 140ms de atraso.

## 3. O que muda no banco

Seis migrações, e as decisões de schema que valem para todas elas.

- **D-006.4. `clinic_id` nunca é escrito pela aplicação.** As tabelas novas têm
  `DEFAULT public.get_my_clinic_id()`. *Porquê:* a âncora é do banco. Mandar o id
  vindo do cliente faria a aplicação virar a autoridade sobre qual clínica é a
  minha, e é exatamente isso que o Princípio I proíbe.
- **D-006.2. Toda tela funciona antes da migração.** Onde a tabela não existe, a
  tela avisa qual migração falta em vez de quebrar, e o número sai
  **subestimado**, nunca superestimado. Depois de aplicadas, tabela faltando
  deixa de ser estado normal e o aviso vira **alerta**, dizendo o que está errado
  por causa dela: "a hora clínica abaixo está errada para menos" é mais útil que
  "o cadastro ainda não existe".
- **D-006.3. Nenhuma ModuleKey nova.** Chave nova exige emenda à constituição
  (Princípio III). As telas vivem sob chaves existentes: `contas_receber` para a
  régua, `pacientes` para o recall, `acompanhamento` para salas, e
  **`contas_pagar`** para preço e insumos.
- **D-006.5. O dia é o brasileiro, a conta é em UTC.** Comparar por dia em UTC
  evita que o fuso do servidor mude o resultado, mas "hoje" precisa ser o
  calendário de São Paulo. `hoje.ts` faz a ponte, e nenhuma função pura precisou
  mudar.

## 4. Premissas

- **D-006.1. Núcleo puro, separado da tela.** Cada funcionalidade tem um módulo
  sem banco, sem relógio e sem navegador, e o relógio é **parâmetro**, porque
  função que lê o relógio não se testa. É o que permitiu provar 46 casos sem
  subir nada.
- **O fuso é fixo em São Paulo, e isso é dívida escrita.** Clínica em Manaus está
  a uma hora, em Rio Branco a duas: no Acre, das 19h à meia-noite, o código já
  virou o dia, que é o mesmo defeito que ele conserta, deslocado. Vale agora
  porque o cliente fundador e o time que testa estão em Brasília. A dívida está
  escrita dentro de `hoje.ts`, e quando entrar a coluna de fuso o único lugar a
  mudar é a própria função.
- **O que esta regra deliberadamente não faz:** não cria ModuleKey, não impede
  conflito de agenda por constraint, não substitui `services.cost` na leitura,
  não implementa assinatura digital, e não torna as faixas de cobrança
  configuráveis. Torná-las configuráveis exige coluna nova, e o módulo já está no
  formato que recebe faixas do banco sem mudar de forma.

**Onde cada coisa vive**, no repositório da plataforma (`nexclin/nexclin`):

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

As migrações vivem em `supabase/migrations` **deste** repositório, que é a fonte
de verdade do schema.

## 5. Dependências

- **Regra 001**, pela cascata de permissão que gateia todas as telas novas.
- **Regra 002**, para a dívida da seção 7: `data_audit_log` existe e hoje cobre
  só `patients`.
- **Procedimento da ponte** para qualquer correção que chegue à plataforma.

## 6. Como se prova que funciona

**Esta regra não tem critérios de aceite**, a pedido do Arthur em 26/08. Quando
alguém for testar, os critérios saem dos *porquês* da seção 2, e é para isso que
eles estão escritos ali.

O que existe de prova hoje é automatizado, e ela **passou a morar no
repositório**. As 46 provas originais rodavam por script montado, executado e
apagado: a próxima pessoa que mexesse em `precificacao.ts` quebraria a aritmética
e nada acusaria, porque `tsc` passa, build passa, e o preço sai errado em
silêncio. **Hoje são 76 testes em quatro arquivos**, e cada um explica o que
protege.

## 7. A decisão que falta

**Uma dívida, e ela não é pergunta de desenho: é escopo de outra regra.**

**D-006.4 sob impersonação.** O `DEFAULT` chama `get_my_clinic_id()`, que durante
uma sessão de suporte devolve a clínica do cliente. Está certo tecnicamente, e
significa que o suporte pode cadastrar um bem ou um insumo dentro da conta do
cliente, **indistinguível do que o cliente cadastrou**. A auditoria registra a
entrada e a saída do suporte, **não o que foi criado no meio**.

Isso se resolve quando a auditoria da regra 002 passar de `patients` para as
demais tabelas.

**Parcialmente fechado em 27/08**, pelo FR-013 da regra 005: as catorze tabelas
de configuração ganharam trigger de auditoria, então mexer em preço, taxa ou
parâmetro sob impersonação passa a gravar linha com o `auth.uid()` do suporte.
**O que continua aberto** é exatamente o caso desta dívida: `imobilizado` e
`insumos` ainda não têm trigger, e são tabelas desta regra. Elas entram quando o
módulo delas tiver regra própria.
