# 022 · Motor de rotina da clínica

> **Regra viva.** Nasce antes da execução, guia a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 15/09/2026:** Entrega 1 no ar (FR-010 e FR-011, `0dad6af` e
> `a7ce299`); FR-005 redecidido em 06/09 (seção 7, 1b) e coberto pela 024 com
> `responsible_member_id`; FR-006 entregue pela 023 (`task_comments`); FR-008
> metade entregue pela 024 (policies por operação, sem `DELETE`) e metade à
> espera do FR-011 da 021. O motor (FR-001 a FR-004, FR-009, FR-012) é da stack
> nova e espera as decisões 2 e 3 da seção 7 e o checklist do Vinícius.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` §2.5 ·
> **Origem:** reunião de 03/09, apurada em
> [`../historico/2026-09-04-reuniao-03-09-decisoes.md`](../historico/2026-09-04-reuniao-03-09-decisoes.md)
> §4.2; decisão do Arthur de 05/09 pelo motor de rotina; e a pesquisa de mercado
> em [`../referencia/2026-09-05-rotinas-recorrentes-no-mercado.md`](../referencia/2026-09-05-rotinas-recorrentes-no-mercado.md).

---

## 1. O problema

O que faz o olho do médico brilhar, segundo quem vende para ele, é **controle de
tarefa da equipe**, e é isso que a clínica hoje resolve em planilha e grupo de
WhatsApp. O NexClin já grava tarefa automaticamente a partir de nove tipos de
evento, então não falta o evento: falta a **leitura** dele, e falta a rotina que
a clínica tem de cumprir toda semana e que hoje só existe na cabeça de quem
treina a equipe. Sem isso, a pergunta que a gestão faz (*a secretária fez os três
contatos nos dias 1, 3 e 7?*) não tem resposta no sistema, e a clínica continua
comprando gestão em consultoria e executando em planilha.

**A decisão de produto que separa isto de um Trello:** o que a clínica abre de
manhã é a lista **do que a rotina manda fazer**, com cumprimento medido, e não um
quadro onde as pessoas escrevem cards. Card escrito à mão continua existindo, e é
o caso menor.

---

## 2. Requisitos

Faixa pela pergunta da §2.5, *o que fica gravado?*.

### O que o mercado não faz, e é o que decide

- **FR-001** · faixa **A** · alvo **stack nova**
  A instância de uma rotina **MUST** guardar ponteiro para a **regra que a
  gerou**.
  *Porquê:* sem esse elo não existe "taxa de cumprimento **desta** rotina", só
  "taxa de cumprimento de tarefas", que é outro número e não serve para gestão.
  A pesquisa mediu: **das oito ferramentas horizontais, só uma** publica esse
  campo no contrato (`Issue.recurringIssueTemplate`, na Linear), e é a mesma que
  permite filtrar por ele.

- **FR-002** · faixa **A** · alvo **stack nova**
  A instância **MUST** ser materializada **na data, por agenda**, e **MUST NOT**
  depender da conclusão da anterior.
  *Porquê:* materializar ao concluir a anterior é o padrão de Todoist, Height e
  ClickUp, e ele tem uma consequência que mata a medição: **o dia pulado não gera
  linha nenhuma**. Rotina não cumprida que não deixa rastro não pode ser contada
  como falha.

- **FR-003** · faixa **A** · alvo **stack nova**
  Rotina não cumprida **MUST** deixar instância vencida, e o cumprimento **MUST**
  ser medido sobre **as instâncias que deveriam existir**, não sobre as que
  existem.
  *Porquê:* é o corolário do FR-002 e é onde o produto diverge da amostra
  inteira. A pesquisa não achou **nenhuma** das oito fazendo materialização
  retroativa, e o ClickUp documenta explicitamente que não cria instância no
  passado. Denominador errado produz taxa de cumprimento que só melhora quando a
  equipe para de trabalhar.

- **FR-004** · faixa **A** · alvo **stack nova**
  A rotina **MUST** poder ser atribuída a **papel**, e o papel **MUST** resolver
  para pessoa **no momento em que a instância é gerada**.
  *Porquê:* rotina de clínica é "a secretária faz", não "a Ana faz". Se for por
  pessoa, a rotina quebra quando a Ana sai de férias. A pesquisa mediu **0 das 8**
  ferramentas horizontais com atribuição por papel: todas atribuem a pessoa.
  Papel como recurso nomeado só apareceu em software de procedimento operacional.
  Resolver na geração, e não na leitura, é o que torna a instância auditável
  depois: fica gravado quem era o responsável naquele dia.

### O que o banco não tem hoje

- **FR-005** · faixa **A** · alvo **Lovable + stack nova**
  `tasks.responsible` **MUST** referenciar o usuário ou o membro da equipe, e
  **MUST NOT** continuar sendo texto livre.
  *Porquê:* **achado da leitura de 05/09.** A coluna é `TEXT DEFAULT ''`, sem
  chave estrangeira nenhuma. O apontamento da reunião, *"a coluna responsável
  mostra setor e deveria mostrar usuário"*, não é defeito de exibição: **não
  existe referência a usuário ali**. É o mesmo defeito de
  `expenses.payment_method`, registrado no FR-012 da regra 021.

- **FR-006** · faixa **A** · alvo **stack nova** · **ENTREGUE em 12/09 pela
  regra 023** (`task_comments`, migração `20260907000000`, no ar)
  A tarefa **MUST** aceitar comentário, com autor e hora, em tabela própria.
  *Porquê:* pedido na reunião, e é dado novo que passa a existir. É também o que
  registra a cobrança do gestor sem ela virar conversa de WhatsApp que ninguém
  encontra depois.

- **FR-007** · faixa **A** · alvo **stack nova**
  A tarefa **MUST** aceitar subtarefa.
  *Porquê:* pedido na reunião. A pesquisa mostra que a amostra se divide entre
  sub-tarefa e checklist nomeado, e que **só o Trello** dá prazo e responsável
  próprios ao item de checklist. Subtarefa que é tarefa resolve os dois casos com
  uma estrutura só.

- **FR-008** · faixa **A** · alvo **stack nova** · **metade entregue em 14/09
  pela 024** (três policies por operação em `tasks`, sem `DELETE`); a consulta a
  `my_permission('tarefas')` espera nexclin#127
  As policies de `tasks` **MUST** consultar `my_permission('tarefas')`, e **MUST
  NOT** conceder `FOR ALL` apenas por pertencer à clínica.
  *Porquê:* mesmo buraco que o FR-011 da regra 021, e a policy é a original de
  22/03. Aqui ele é pior de um jeito específico: tarefa carrega `patient_id`, e a
  alínea (c) diz que regra de acesso não pode viver só no frontend.

### Mudança de rotina, e o que ela não pode desfazer

- **FR-009** · faixa **A** · alvo **stack nova**
  Mudar a rotina **MUST NOT** alterar instância já gerada.
  *Porquê:* a pesquisa mostra as duas famílias em lados opostos: a Linear não
  propaga, o Process Street propaga para as execuções ativas. Aqui vence não
  propagar, e a razão é de auditoria e não de gosto: **instância que muda depois
  do fato torna o cumprimento infalsificável**. Se em outubro alguém quiser saber
  o que a rotina pedia em setembro, a instância tem de responder sozinha.

### Prazo, atraso e a leitura da manhã

- **FR-010** · faixa **B** · alvo **Lovable + stack nova**
  A tarefa em atraso **MUST** exibir a **contagem de dias** de atraso, e não só
  cor ou faixa.
  *Porquê:* pedido literal na reunião, *"o vencimento dela tá aqui, mas não tá
  escancarado que ela tá atrasada x dias"*. **Vale registrar que isto não tem
  precedente na amostra:** nenhuma das fontes primárias alcançadas exibe número
  de dias. Trello usa três cores, Monday condiciona ao Deadline Mode, Process
  Street pinta a data. É divergência deliberada, não desconhecimento.

- **FR-011** · faixa **B** · alvo **Lovable + stack nova**
  O card **MUST** mostrar a foto do responsável.
  *Porquê:* pedido na reunião. A migração `20260827010000_foto_de_perfil.sql` já
  existe, então é exibição sobre dado gravado. Depende do FR-005: sem referência
  a usuário não há foto a buscar.

- **FR-012** · faixa **B** · alvo **stack nova**
  A tela **MUST** abrir na rotina do dia, e **MUST NOT** abrir num quadro vazio à
  espera de que alguém escreva card.
  *Porquê:* é a decisão de produto do parágrafo 2 da seção 1, dita como
  requisito de tela. Sem ela, o motor existe no banco e a clínica não o encontra.

### O que esta regra proíbe

- **FR-013** · **MUST NOT** nascer tabela paralela de eventos.
  *Porquê:* é a mesma proibição do FR-001 da regra 020 e do FR-015 da regra 021.
  `tasks` já é escrita automaticamente com nove tipos, e a coluna `origem`, com
  `CHECK ('manual','automatica')`, já existe desde 25/08. **O alicerce está de
  pé:** o que falta é a rotina em cima dele, não um segundo cano.

- **FR-014** · **MUST NOT** ser construído um gerenciador de tarefas genérico.
  *Porquê:* Trello e ClickUp têm mais de dez anos de vantagem em quadro de card.
  O critério do `CLAUDE.md` é embarcar metodologia real de gestão clínica, e a
  pesquisa mostra exatamente onde a metodologia cabe: papel, materialização por
  agenda e medição de cumprimento são os três lugares em que a amostra inteira
  não entrega.

---

## 3. O que muda no banco

### O que já existe, conferido nas migrações em 05/09

| Objeto | Estado |
|---|---|
| `tasks.type` | `TEXT DEFAULT 'follow_up'`, e o produto usa nove tipos |
| `tasks.origem` | existe desde `20260825090000`, com `CHECK ('manual','automatica')` |
| `tasks.created_by` | existe, referencia `auth.users` |
| `tasks.due_date` | **`TIMESTAMPTZ`**, não `DATE` |
| `tasks.completed_at` | existe desde `20260510230029`, com trigger `set_task_completed_at` |
| `tasks.responsible` | **`TEXT DEFAULT ''`, sem chave estrangeira nenhuma** |
| `tasks.patient_id`, `.lead_id` | existem |
| policy de `tasks` | `FOR ALL TO authenticated` por `clinic_id`, **sem `my_permission`** |
| recorrência, subtarefa, comentário, template | **não existem** |

### O que o censo de 06/09 mediu, e o que ele corrigiu

O censo rodou no banco ao vivo em 06/09. O registro completo está em
[`docs/historico/2026-09-06-censo-executado.md`](../historico/2026-09-06-censo-executado.md).
Três resultados mudam esta regra.

**1. A tabela acima está certa, com uma linha a acrescentar.** As 15 colunas
conferem uma a uma. As chaves estrangeiras de `tasks` são três, `clinic_id`,
`lead_id` e `patient_id`, e **`created_by` também não tem nenhuma**, ao
contrário do que a linha da tabela afirma. Ela referencia `auth.users` na
intenção, não na definição.

**2. `responsible` aponta para setor em 73% das tarefas.**

| Valor | Tarefas | O que é |
|---|---|---|
| `Recepcao` | 62 | setor |
| `Financeiro` | 60 | setor |
| `Comercial` | 59 | setor |
| `Sra. Bruna` | 13 | pessoa que não é usuário |
| `Dra. Maria` | 1 | pessoa que não é usuário |

Somam 195 de 247 tarefas. Um único valor casa com usuário, e leva 52 tarefas.

**A consequência para o FR-005:** converter texto em usuário não é migrar
formato, é **descartar a informação de 195 tarefas**, porque setor não vira
pessoa por conversão. A conversão do FR-005 só é segura depois que a clínica
tiver os usuários que os três setores representam, e o #50 é o primeiro deles.

**3. O alicerce do FR-013 está de pé e ninguém sobe nele.** A coluna `origem`
existe, e o `CHECK` aceita `'manual'` e `'automatica'`, conferido pela
definição da constraint `tasks_origem_check`. Mas **as 247 tarefas têm
`origem = 'manual'`, e nenhuma tem `'automatica'`**.

O controle positivo é a própria consulta: ela agrupa por `origem`, então outro
valor apareceria como linha, e a soma fecha em 247, que é o total medido à
parte.

A causa está no front, e foi lida linha a linha: existem **onze** pontos que
inserem em `tasks`, dez deles automáticos, e **nenhum dos dez grava `origem`**.
O único que grava é o formulário de Nova Tarefa, em `pages/Tarefas.tsx`, que
escreve `origem: "manual"` corretamente. Os dez caem no default da coluna, que
também é `'manual'`.

Então o motor **escreve**, ao contrário do que o número sozinho sugere, e o que
está errado é o rótulo. A afirmação do FR-013 de que "o alicerce está de pé"
continua verdadeira; o que ela não previa é que a coluna que distingue as duas
origens **hoje não distingue nada**.

### O que precisa nascer

| Objeto | Mudança | FR |
|---|---|---|
| tabela **rotina** | a regra: título, tipo, periodicidade, janela, papel responsável, e ativa ou não. **Entidade própria**, e não campo dentro da tarefa | FR-001 a FR-004 |
| `tasks` | coluna apontando para a **rotina que gerou** a instância, indexada, e nula para tarefa manual | FR-001 |
| `tasks` | coluna de **competência**: a que dia da rotina esta instância se refere, distinta de `due_date` | FR-002, FR-003 |
| índice único | rotina mais competência, para o job ser idempotente e não gerar a mesma instância duas vezes | FR-002 |
| `tasks.responsible` | vira referência a usuário ou a membro da equipe | FR-005 |
| `tasks` | coluna de **papel resolvido**, gravando qual papel originou a atribuição naquele dia | FR-004, FR-009 |
| tabela **comentário de tarefa** | tarefa, autor, texto, hora | FR-006 |
| `tasks` | coluna de **tarefa pai**, para subtarefa | FR-007 |
| policies de `tasks` | separadas por operação e consultando `my_permission('tarefas')` | FR-008 |

**Toda tabela nova nasce com RLS por `clinic_id` e default deny**, alíneas (a) e
(b), e sem `USING(true)`.

**Armadilha conhecida, e ela morde aqui:** `due_date` e `completed_at` são
`TIMESTAMPTZ`, e o Postgres não define `timestamptz + integer`. Toda conta de
atraso converte os dois lados com `::date`. Já custou tempo antes.

---

## 4. Premissas

1. **As migrações deste repositório descrevem o banco ao vivo.** É premissa, e a
   armadilha 2 diz por que a conferência vai no editor de SQL e não pela API.
2. **Os nove tipos de evento continuam sendo escritos por quem os escreve hoje.**
   Esta regra lê o que já existe e não muda quem grava.
3. **A rotina é da clínica, e varia de clínica para clínica.** É a mesma
   conclusão que a regra 018 já tinha tirado do funil: a cadência de três
   contatos nos dias 1, 3 e 7 varia, logo é configuração e não constante.
4. **A pesquisa de mercado tem limite declarado.** A política de rede bloqueou a
   documentação de vários fabricantes, e o documento marca cada afirmação como
   artefato lido ou como página citada e não aberta. Requisito que se apoia numa
   afirmação de nível 2 cai se a fonte for aberta e disser outra coisa.

---

## 5. Dependências

**Antes desta regra:**

- **O checklist de rotinas do Vinícius.** Ele se ofereceu para passar inteiro na
  reunião, o Arthur pediu, e **não chegou**. Sem ele, a tabela de rotina nasce
  vazia e o produto entrega um motor sem combustível. É a dependência mais
  barata de resolver e a que mais trava.
- A conferência do schema ao vivo, premissa 1.

**Depende desta regra:** a regra 020, avisos internos, cuja metade que não
precisa de emenda à constituição é justamente a leitura de `tasks`.

**Não é dependência:** a décima sexta ModuleKey. Apurado em 04/09: prazo, dias de
atraso, foto, comentário, subtarefa e recorrência vivem **dentro do módulo
`tarefas`**, que já está no contrato das 15. **Só o sininho de avisos precisa da
emenda.**

---

## 6. Como se prova que funciona

Tarefas é uma das duas áreas obrigadas à **régua dos 200%** em 08/09. Ver a
seção 7, decisão 1, porque o motor inteiro não cabe em três dias.

| # | O que se prova | Como |
|---|---|---|
| 1 | o schema ao vivo é o que as migrações dizem | censo por `information_schema` e `pg_policies`, no editor de SQL |
| 2 | **FR-008**, o buraco de permissão | `BEGIN`/`ROLLBACK` com `SET LOCAL ROLE authenticated`, usuário com `tarefas` negado. **Com controle positivo**, senão passa por vacuidade |
| 3 | **FR-002 e FR-003**, o que separa isto do mercado | criar rotina diária, **não cumprir por três dias**, e conferir que existem três instâncias vencidas. Se existir zero, o motor está materializando ao concluir e o requisito falhou |
| 4 | **FR-002**, idempotência | rodar o job duas vezes no mesmo dia. A segunda **não** cria instância |
| 5 | **FR-004** | trocar a pessoa do papel e gerar a instância seguinte. A nova aponta para a pessoa nova, **e a antiga continua apontando para a antiga** |
| 6 | **FR-009** | mudar o título da rotina. Instância já gerada **não muda** |
| 7 | FR-010 | tarefa vencida há três dias mostra o número 3, e não só a cor |
| 8 | FR-005 e FR-011 | o responsável é usuário, e a foto dele aparece |

**O que a prova automatizada não cobre:** o job de materialização dá para testar
em unidade, e a leitura da manhã não. E a reunião fechou que nada vai ao usuário
final sem ter sido testado por gente. Item sem prova na tela fecha como **"código
lido, não comportamento provado"** e continua aberto.

---

## 7. A decisão que falta, e precisa do Arthur

**1. RESPONDIDA em 05/09: a regra vai em duas entregas.** Tarefas está na régua
dos 200% para 08/09 e o motor de rotina não cabe em três dias. As duas coisas
foram decididas com um dia de diferença e se batiam. O Arthur fechou pela
partição.

| Entrega 1, até 08/09, na Lovable | Entrega 2, stack nova |
|---|---|
| FR-005, responsável vira usuário | FR-001 a FR-004, o motor |
| FR-010, dias de atraso | FR-006, FR-007, FR-009 |
| FR-011, foto no card | FR-008, a permissão |
| | FR-012, a tela que abre na rotina |

A Entrega 1 é o que a reunião pediu em voz alta e cabe em três dias. O motor é o
que diferencia, e diferenciação feita em três dias vira demonstração ruim.

**O FR-005 é a dobradiça, e por isso ele está na Entrega 1.** Sem responsável
como referência a usuário não há foto a buscar (FR-011), e não há para onde o
papel resolver (FR-004). Ele é a única coluna que as duas entregas precisam.

**1b. REABERTA e REDECIDIDA em 06/09: o FR-005 sai da Entrega 1.** O censo de
06/09 mediu o que a decisão de 05/09 não tinha: **195 das 247 tarefas, 79%,
apontam para algo que não é usuário, e 181 delas apontam para setor.**

A partição de 05/09 supunha que converter texto em usuário fosse mudança de
formato, barata e sem perda. Não é. Com este dado a conversão descarta a
atribuição de 195 tarefas de uma clínica que já opera, ou inventa usuário para
representar setor, dois dias antes de abrir para o fundador.

**O que fica decidido:**

- A migração de `responsible` **não roda na Lovable**. Ela roda na stack nova,
  em outubro, junto com o port, com os usuários já criados e sem clínica
  operando em cima.
  *Precisão de 12/09/2026:* o que entra na Lovable é uma **coluna nova**,
  `tasks.responsible_member_id`, anulável, referência a `team_members`, gravada
  pelo botão de assumir tarefa da regra 024. O texto não é migrado nem apagado.
  A migração de verdade continua sendo da stack nova, como está escrito acima.
- O texto que está gravado hoje **não está errado**. `Comercial` é o registro
  verdadeiro de quem cuida daquela tarefa numa clínica que se organiza por
  setor. Não há erro de dado a corrigir, há um modelo a ampliar.
- O artefato que esta sessão entrega é **esta regra**, não a migração. É a
  faixa B do `CLAUDE.md` aplicada ao pé da letra: o que atravessa é a decisão
  de como o sistema deve se comportar, e o front da Lovable será reescrito.

**A pergunta que a stack nova precisa responder, e que este censo levanta:**
responsável é sempre pessoa, ou pode ser setor? Três setores respondem por 181
tarefas, o que diz que a clínica atribui por setor **por escolha**, não por
falta de cadastro. Um modelo que só aceita pessoa obriga a clínica a mudar como
trabalha para caber no software, e o critério do `CLAUDE.md` é o inverso disso.
A decisão fica para a regra do módulo na stack nova, com o dado deste censo
como base.

**2. Papel: entidade nova, ou o `app_role` que já existe?** O banco tem o enum
`app_role` com `admin`, `medico`, `secretaria` e `user`. Reusar custa quase nada
e resolve as rotinas que a clínica tem hoje. Entidade nova permite papel próprio
por clínica, que é mais fiel ao FR-004 de "varia de clínica para clínica", e
custa uma tabela mais RLS.

**Cuidado que vale dizer:** papel novo **não** é ModuleKey nova, e as duas não se
misturam. Papel diz quem executa a rotina; ModuleKey diz quem vê o módulo. Já
houve confusão parecida, e a regra 019 achou quatro papéis de painel que não
limitavam nada.

**3. A janela de cumprimento é instante ou intervalo?** A pesquisa deixou isso
cru de propósito. "Ligar para o lead no dia 3" é um dia; "conferir o caixa toda
segunda" é uma janela que a pessoa cumpre em qualquer hora do dia. Se for
intervalo, `due_date` sozinho não basta e a tabela de rotina precisa de início e
fim da janela.

**4. O checklist do Vinícius, e ele não é decisão, é insumo que falta.** Sem ele
a tabela de rotina nasce vazia. Vale perguntar quantas rotinas são: se forem
cinco, cabe na tela de configuração; se forem cinquenta, precisa de importação, e
isso é outra tarefa.
