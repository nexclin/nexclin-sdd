# 005 · Configurações da clínica

> **Regra viva.** Nasceu antes da execução, e é corrigida no mesmo commit em que
> a execução a contradiz.
>
> **Estado em 28/08/2026:** **executada em doze dos dezesseis requisitos, e sem
> aceite manual.** O FR-015 está corrigido e publicado na plataforma Lovable,
> provado na tela de lá. **O FR-010 e o FR-016 continuam PARCIAIS**, e pela
> mesma razão: o mecanismo durável existe, o consumidor não. A seção 7 detalha.
>
> **Terceira correção deste cabeçalho em três dias, e a mais constrangedora.**
> A versão anterior de hoje dizia "o FR-016 fechou". Os dois eixos da revisão de
> código derrubaram junto: a coluna nasceu, mas nenhum arquivo em `app/` a lê ou
> grava, então o que fechou foi a gaveta, não a persistência. Pela regra (j),
> isto é *código lido, não comportamento provado*. O parágrafo abaixo já
> advertia que esta é a linha mais fácil de deixar mentindo, e ela mentiu de
> novo na linha seguinte à advertência.
>
> Catálogos, regras de negócio, metas, anamnese, plano de contas
> e o progresso do onboarding estão em pé em `app/app/configuracoes/`, sobre
> `lib/config/`, com 157 testes. **Continuam abertos o FR-005 em parte, a
> segunda metade do FR-010 e o consumo do FR-016**, detalhados na seção 7. **O
> FR-006 saiu do impasse em 28/08**, com a decisão do Arthur, e tem migração
> escrita: `20260828030000`. Ela **não foi aplicada a banco nenhum**, então vale
> a regra (j), *código lido, não comportamento provado*. Falta também
> o aceite na tela, que é do Arthur. Alvo: a stack Next.js deste repositório.
>
> **Duas correções de cabeçalho em dois dias, e as duas são a regra (l) em
> ação.** Em 27/08 ele dizia "escrita, não executada", herdado do `Status: Draft`
> da SPEC 005, e estava errado desde a conversão: o código já existia, com o
> comentário `SPEC 005, T016` dentro dele. A correção daquele dia então errou
> para o outro lado, dizendo "executada" sem qualificar, e a revisão de código
> pegou. Regra que descreve estado que não é o real é exatamente o que o termo
> *regra viva* existe para impedir, e errar nas duas direções em 24 horas mostra
> que o cabeçalho é a linha mais fácil de deixar mentindo.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Fila:** `fila-de-regras.md` ·
> **Origem:** convertida da SPEC 005 em 27/08/2026, formato de sete seções.

---

## 1. O problema

`business_rules` e os treze catálogos da clínica são lidos por pacientes,
consultas, tarefas, anamnese e todo o financeiro: são as listas que todo
formulário oferece e os parâmetros que toda automação obedece. Sem esse
substrato, qualquer módulo posterior escreve cego ou reimplementa formulário que
vai precisar ser refeito. E ao ler o banco para escrever esta regra apareceu um
segundo motivo, que não era hipótese: **o default de `plans.enabled_modules` é um
valor que a própria tabela recusa.** A coluna nasce `'[]'::jsonb`, array, e o
trigger que a valida exige objeto. Todo `INSERT` em `plans` que não informe
`enabled_modules` explicitamente falha com `enabled_modules deve ser um objeto
JSON`. Hoje não incomoda porque os planos vieram de migração; incomoda no dia em
que alguém criar um plano pela tela.

## 2. Requisitos

**A correção que abre a regra**

- **FR-001**: O default de `plans.enabled_modules` **MUST** passar de
  `'[]'::jsonb` para `'{}'::jsonb`, por migração versionada. *Porquê:* um default
  que o trigger da própria tabela recusa é defeito, não escolha.
- **FR-002**: O formato de `enabled_modules` **MUST** ser objeto
  `Record<ModuleKey, boolean>`, em banco, app e tela. *Porquê:* o trigger já
  impõe objeto desde `20260725033102`. O BACKLOG tratava isso como pergunta
  aberta por engano: o que falta não é decidir, é alinhar o default.
- **FR-003**: Toda linha existente de `plans` **MUST** ser verificada e, se
  estiver em formato de array, normalizada pela mesma migração. *Porquê:*
  corrigir o default sem normalizar o que existe deixa duas formas convivendo, e
  o código passa a ter de aceitar as duas para sempre.

**Catálogos**

- **FR-004**: O sistema **MUST** permitir criar, editar e desativar entradas de
  `channels`, `origins`, `objections`, `services`, `payment_methods`,
  `expense_categories`, `chart_of_accounts`, `bank_accounts`, `closing_types`,
  `consultation_types`, `acquirers`, `goals` e `anamnesis_config`. *Porquê:* sem
  serviço cadastrado não há o que agendar nem o que cobrar. É o que transforma o
  sistema de vazio em operável.
- **FR-005**: A desativação **MUST** ser lógica (`active = false`). Entrada
  desativada **MUST** sair das listas de escolha e **MUST** permanecer legível
  onde já foi usada. *Porquê:* desativar um serviço usado em consultas passadas
  não pode apagar histórico nem quebrar relatório.
- **FR-006**: Entradas marcadas `is_system` **MUST NOT** ser editáveis nem
  removíveis pela clínica. *Porquê:* são as linhas que o sistema pressupõe
  existirem. Apagá-las quebra cálculo em outro módulo, longe de onde o clique
  aconteceu.
- **FR-007**: `payment_methods` **MUST** guardar taxa padrão, taxa de antecipação
  e prazo em dias. *Porquê:* é deles que saem o líquido e o vencimento do
  recebível, e vencimento errado desloca o fluxo de caixa inteiro. Foi o item
  V-22 da bateria do Vinícius.

**Regras de negócio**

- **FR-008**: O sistema **MUST** permitir editar `followup_days`,
  `confirmation_hours`, `recapture_days`, `recall_days`,
  `satisfaction_survey_days`, `anamnesis_send_days` e `work_saturday`. *Porquê:*
  são os parâmetros que a automação de tarefas e as telas de paciente e consulta
  leem. Deixá-los para depois significa reescrever formulário quando chegarem.
- **FR-009**: `confirmation_hours` **MUST** ser exibida em dias e armazenada em
  horas, com ida e volta estável: exibe `max(1, round(h/24))`, grava `dias × 24`.
  *Porquê:* é a armadilha conhecida da referência. Ida e volta instável faz o
  usuário salvar 2 e reler 1, e ele passa a não confiar em nenhum campo da tela.
- **FR-010**: `patient_required_fields` e `appointment_required_fields` **MUST**
  ser configuráveis, e os formulários dos módulos posteriores **MUST** obedecê-los
  sem lista fixa em código. *Porquê:* lista fixa em código transforma
  configuração em mentira: a tela oferece a escolha e o formulário ignora.

**Acesso**

- **FR-011**: Todas as telas desta regra **MUST** ser governadas pela ModuleKey
  `configuracoes`, e a de planos pelo guard de superadmin. *Porquê:* a tela de
  planos edita o teto de outras clínicas. Ela não é da clínica.
- **FR-012**: Toda tabela desta regra **MUST** ter RLS por `clinic_id` ativa e
  verificada. *Porquê:* Princípio I. Catálogo de uma clínica alcançável por outra
  é vazamento, mesmo que "seja só uma lista de serviços": preço e custo estão lá.
- **FR-013**: A edição de catálogo e de regra de negócio **MUST** gerar registro
  de auditoria, pelo mecanismo da regra 002. *Porquê:* mudar a taxa de um meio de
  pagamento muda todo recebível criado depois. Sem rastro, ninguém reconstrói por
  que os números de duas semanas atrás não batem.

**Onboarding**

- **FR-014**: A tela **MUST** mostrar o progresso dos doze passos do onboarding,
  e **MUST NOT** bloquear o uso do sistema enquanto eles não fecharem. *Porquê:*
  os passos são derivados destas mesmas tabelas, e bloquear quem ainda não
  configurou tudo impede exatamente quem mais precisa entrar para configurar.
  **Este requisito foi violado em produção, e o custo foi total:** ver FR-015.
- **FR-015**: A apresentação inicial **MUST** ser dispensável a qualquer momento,
  **MUST NOT** redirecionar a navegação por conta própria, e **MUST** rodar uma
  vez por usuário, na primeira entrada. *Porquê:* em 28/08/2026 a conta mestra
  ficou **trancada fora do sistema**, e a causa foi a apresentação depender de
  `isComplete`, que é derivado de doze contagens no banco. Sem formulário de
  anamnese cadastrado, a clínica ficava incompleta para sempre, a apresentação
  renascia a cada carga de página e um `useEffect` devolvia qualquer rota para a
  do passo corrente. **A condição de exibição MUST NOT consultar o progresso da
  configuração:** apresentação e progresso são duas perguntas, e juntá-las foi o
  defeito. Decisão do Arthur no mesmo dia: *"não tem que ser obrigatória a
  execução, é só pra mostrar a etapa inicial, e isso só roda uma vez"*.
- **FR-016**: A marca de "já viu a apresentação" **MUST** ser persistida por
  usuário, em coluna do banco. *Porquê:* na plataforma Lovable ela ficou no
  `localStorage` do navegador, e a escolha foi deliberada, porque coluna nova
  exigiria o export do banco e a mão do Arthur no SQL editor enquanto a conta
  estava trancada. O custo aceito é ver a apresentação uma vez a mais num
  navegador novo. **Na stack nova isso é dívida a pagar, não padrão a copiar.**

## 3. O que muda no banco

**Nenhuma tabela nova.** As treze de catálogo e `business_rules` já foram
portadas nas 56 migrações da fundação. Esta regra liga o app ao que existe, corrige um
default e acrescenta rastro.

| Objeto | Mudança | Onde |
|---|---|---|
| `plans.enabled_modules` | default de `'[]'::jsonb` para `'{}'::jsonb` | `20260825070000` |
| `plans` (linhas existentes) | normalização de array para objeto, na mesma migração | `20260825070000` |
| 14 tabelas de configuração | trigger `AFTER INSERT OR UPDATE OR DELETE` chamando `audita_mudanca_de_dado()` | `20260827030000` |
| as mesmas 14 tabelas | nenhuma alteração de schema; RLS já ativa, verificada por varredura em 25/08 | |

**O trigger de auditoria não trouxe função nova.** `audita_mudanca_de_dado()`,
da regra 002, já lê `TG_TABLE_NAME`, `clinic_id` e `id`, então serve a qualquer
tabela de negócio. Uma segunda função seria a divergência que a 002 evitou.

**As três operações, inclusive INSERT.** `previous_state` fica `NULL` no INSERT,
e a linha ainda serve: ela responde **quem** criou a forma de pagamento com 15%
de taxa, e quando. Consequência aceita: o onboarding roda os seeds e escreve
algumas dezenas de linhas de uma vez, o que é ruído barato e distingue o que o
sistema semeou do que a clínica cadastrou depois.

As entidades, e o que cada grupo carrega:

- **`business_rules`**: uma linha por clínica, com os parâmetros que os outros
  módulos leem.
- **Catálogos simples** (`channels`, `origins`, `objections`,
  `consultation_types`, `closing_types`): nome e ativo.
- **Catálogos com valor** (`services`, `payment_methods`, `acquirers`,
  `expense_categories`): preço, custo, taxa e prazo.
- **Estrutura financeira**: `chart_of_accounts`, hierárquico por `parent_id` e
  `level`, e `bank_accounts`.
- **`goals`**: por mês e ano, com alvo de receita, pacientes novos, fechamentos e
  conversão.
- **`anamnesis_config`**: título, especialidade e campos.
- **`plans`**: o teto. Vive fora da clínica, editado pelo superadmin.

## 4. Premissas

- **Nenhuma tabela nova.** Se aparecer necessidade de uma, a premissa quebrou e a
  regra precisa ser corrigida antes de continuar.
- **A tela de planos é do superadmin.** A clínica vê o teto do próprio plano e
  não o edita.
- **Repasse fica de fora.** `team_members` guarda modelo e percentual, mas o
  relatório de repasse tem imposto fixado em zero e atribuição estimada. É
  ressalva do backlog, não desta regra.
- **Um componente de período para todo o app.** A referência tem três
  vocabulários convivendo, divergência D3 do `INVENTARIO-UI`. Aqui nasce um só.
- **Rótulo de enum nunca vai cru para a tela.** Mesma divergência D3, registrada
  em `.claude/rules/app.md`.

**Casos de borda que a execução vai encontrar:**

- Plano de contas hierárquico: apagar um pai com filhos, e o que acontece com os
  lançamentos pendurados.
- Meta por mês e ano já existente sendo recadastrada: atualiza ou duplica.
- Clínica sem sábado com consulta já agendada num sábado: a regra vale para o
  futuro, não reescreve o passado.

## 5. Dependências

1. **Regra 001**, no que importa: `RequirePermission` e o guard do app existem
   desde 25/08, e são o que protege estas telas.
2. **Regra 002, a auditoria**, para o FR-013. `data_audit_log` está escrito e
   aguarda aplicação.
3. **Nada mais.** Esta regra não espera nenhuma outra.

## 6. Como se prova que funciona

- **SC-001**: Um administrador configura a clínica do zero até fechar os doze
  passos do onboarding em menos de 30 minutos, sem ajuda.
- **SC-002**: A ida e volta de `confirmation_hours` é estável: o valor exibido
  depois de salvar é o mesmo digitado, em 100% dos casos entre 1 e 30 dias.
- **SC-003**: Criar um plano pela tela, sem tocar nos módulos, funciona. Hoje
  falha com erro de tipo.
- **SC-004**: Nenhum catálogo de uma clínica é alcançável por outra, incluindo
  tentativa por URL direta com o ID. Verificado por Arthur.
- **SC-005**: Desativar um serviço usado no passado não altera nenhum relatório
  histórico.
- **SC-006**: Uma chave fora das 15 ModuleKeys é recusada pelo trigger, com o
  nome da chave inválida na mensagem, por qualquer caminho de escrita.
- **SC-007**: Um plano com `contas_pagar` desligado esconde o item do menu e nega
  a URL direta, mesmo para admin da clínica.
- **SC-008**: Alterar a taxa de uma forma de pagamento deixa linha em
  `data_audit_log` com autor, hora e o valor **anterior** da taxa.

**Prova automatizada:** 157 testes em Vitest sobre `lib/config/`, e entre eles
`__tests__/auditoria.test.ts`, que é **contrato, não lógica**. Ele lê os `.sql`
de `supabase/migrations/` e o `acoes.ts`, e falha quando os dois discordam.

Provado por mutação em três direções: removido o trigger de `payment_methods` da
migração, um teste falha; acrescentado um catálogo em `CATALOGOS` sem trigger, um
teste falha; trocada uma action para escrever numa tabela fora da lista, um teste
falha. É a catraca que impede a auditoria de ficar para trás em silêncio, porque
esquecer o trigger não quebra `tsc` nem build.

**A revisão de código derrubou dois testes que não podiam falhar**, e vale
registrar por que: conferir a lista de tabelas auditadas contra `CATALOGOS` é
tautologia, porque a lista é *construída* de `CATALOGOS`. O que pode falhar, e
por isso ficou, é conferi-la contra o que as **actions** de fato escrevem. Ela
também derrubou o casamento de `CREATE TRIGGER` dentro de comentário de bloco,
que satisfazia o contrato sem criar trigger nenhum.

**O que a prova automatizada NÃO cobre:** que o trigger de fato grava. Isso exige
banco, e é o SC-008, que é aceite manual.

## 7. A decisão que falta

**Uma, e ela destrava o FR-006.** Levantada pela revisão de código de 28/08,
que mediu os catorze requisitos contra o que existe.

### O FR-006 saiu do impasse: `is_system` deixa só `active` mudar

**Decisão do Arthur em 28/08/2026**, entre as três saídas abaixo: a **segunda**.
Nega a exclusão, e no update exige que todas as demais colunas fiquem iguais.
Entrega o FR-006 e o FR-005 juntos, e é a mais cara de escrever, que era o preço
conhecido.

Virou a migração `20260828030000`, com três decisões que valem registro:

**Gatilho, e não `WITH CHECK`.** A regra é "as demais colunas ficam iguais", e
isso é comparação com o valor anterior. `WITH CHECK` não enxerga `OLD`, só a
linha resultante. Esta regra dizia "por `WITH CHECK` ou trigger"; ao escrever,
só o gatilho serve. Fica corrigido aqui.

**Uma função para as três tabelas.** `chart_of_accounts`, `closing_types` e
`bank_accounts` carregam `is_system`. Listar as colunas protegidas tabela a
tabela apodreceria no primeiro `ADD COLUMN`, porque ninguém lembraria de voltar.
A função compara `to_jsonb` da linha inteira menos as colunas liberadas, então
coluna nova já nasce protegida. É o Princípio VIII.

**Exclusão por policy restritiva**, e não reescrevendo a permissiva que já
existe. Restritiva entra em E lógico com as demais, então subtrai permissão sem
que eu precise saber o que a outra concede, e sem risco de afrouxar o isolamento
por `clinic_id` ao reescrever.

**O que ainda falta:** aplicar a migração e provar na tela que a clínica
consegue desativar um tipo de fechamento e não consegue renomeá-lo. Enquanto
isso não acontecer, o FR-006 é código lido.

### As três saídas que estavam sobre a mesa

**O estado hoje viola a regra (c) da constituição.** O FR-006 diz que entrada
`is_system` **MUST NOT** ser editável nem removível pela clínica, e isso existe
**só na tela**: `formulario.tsx` desabilita o botão e `page.tsx` mostra o selo,
mas a policy é `FOR ALL USING (clinic_id = get_my_clinic_id())` e nenhuma action
lê `is_system`. Uma chamada direta à API edita e apaga linha de sistema. Pior, as
mensagens de erro em `acoes.ts` já descrevem um bloqueio que não existe.

Segurança que mora na tela não é segurança, e é literalmente a regra (c).

**Por que isto não foi corrigido junto:** a correção óbvia, uma policy que negue
`UPDATE` e `DELETE` onde `is_system = true`, **conflita com o FR-005**. A
desativação é lógica, ou seja, é um `UPDATE` de `active`. Negar todo `UPDATE`
impediria a clínica de **desativar** um tipo de fechamento que ela não usa, e
esconder da lista o que não se oferece é justamente o que o FR-005 pede.

São três saídas, e a escolha é de produto:

1. **Sistema é intocável.** Nega `UPDATE` e `DELETE` na linha `is_system`. Mais
   simples de garantir no banco, e a clínica convive com catálogo poluído.
2. **Só `active` é editável em linha de sistema.** Nega `DELETE`, e no `UPDATE`
   exige que as demais colunas fiquem iguais, por `WITH CHECK` ou trigger.
   Entrega os dois requisitos, e é a mais cara de escrever.
3. **`is_system` protege só contra exclusão.** Nega `DELETE`, deixa `UPDATE`
   livre, e o selo na tela vira aviso, não trava. A mais barata, e a que menos
   entrega o que o FR-006 diz hoje.

Qualquer uma delas era migração, faixa A, e atravessa para outubro. A escolhida
foi a segunda.

### O FR-016, com a gaveta pronta e ninguém guardando nada nela

A dívida foi contraída e quitada no mesmo dia. A marca de "já viu a
apresentação" ficou no `localStorage` na Lovable porque coluna nova exigiria o
export do banco e a mão do Arthur no SQL editor **enquanto a conta mestra estava
trancada fora do sistema**. Aqui ela é `profiles.onboarding_tour_seen_at`,
migração `20260828020000`.

**`timestamptz`, não `boolean`:** um booleano responde "viu?"; um carimbo
responde "viu?" e "quando?", pelo mesmo espaço. O "quando" serve ao suporte,
para saber se a pessoa passou pela apresentação antes ou depois de uma mudança
de tela, e ao produto, para decidir se um redesenho grande justifica
reapresentar. `NULL` é "nunca viu".

**Em `profiles`, sem policy nova:** a policy *"Users can update their own
profile"* (`20260817021500`) já usa `USING (user_id = auth.uid())`, então cada
um escreve a própria marca e a de mais ninguém. Tabela nova custaria RLS,
policy e um join para guardar um carimbo.

**Fora da auditoria, de propósito:** a regra (d) cobre ação administrativa sobre
dado de cliente. Marcar que se viu a própria apresentação não é nenhuma das
três, e auditar isso encheria a trilha de ruído.

**O que o código garante, e é a lição do defeito:** `lib/config/apresentacao.ts`
decide olhando **só** o carimbo do usuário. O defeito de 28/08 não foi de
armazenamento, foi de lógica: a apresentação consultava `isComplete`, derivado
de doze contagens, e uma clínica sem formulário de anamnese ficava incompleta
para sempre. **Quem garante isso é a assinatura da função, que não aceita outra
entrada.** Houve aqui a alegação de que um teste travava a reintrodução; a
revisão derrubou, o teste foi retirado, e a razão está escrita no arquivo de
teste. Teste que dá segurança falsa é pior que teste nenhum.

**O que falta para o FR-016 fechar:** alguém que leia e grave a coluna. A
apresentação inicial não existe nesta stack, então não há tela que dispense nem
que marque. O requisito fecha junto com ela.

**Sem backfill, de propósito.** A revisão apontou que todo usuário existente
fica `NULL` e veria a apresentação de novo. A objeção valeria para uma coluna
que descreve algo já acontecido, e esta não descreve: ninguém viu a apresentação
desta stack, porque ela não foi construída. `NULL` é o valor verdadeiro para
todos hoje, e preencher com `now()` é que criaria o defeito, afirmando que
dezessete pessoas viram uma tela que não existe.

### O FR-010 continua parcial, e o que falta não dá para escrever hoje

O requisito tem duas metades. **A primeira está de pé:** a tela configura
`patient_required_fields` e `appointment_required_fields`, e `lerRegras()` as
traz. **A segunda diz que os formulários dos módulos posteriores obedecem sem
lista fixa em código, e esses formulários não existem nesta stack.** `app/app/`
tem `configuracoes` e `conta-suspensa`, e mais nada. Não há o que fazer
obedecer.

**O que foi feito em 28/08, depois de a revisão cortar o excesso:** o par
(catálogo, piso) passou a ser escrito num lugar só. `normalizaCamposObrigatorios`
pede três argumentos, e dois deles andam sempre juntos; esse par aparecia à mão
em quatro lugares, e um catálogo novo obrigaria a lembrar dos quatro.
`lib/config/campos-obrigatorios.ts` o fixa, e **`acoes.ts` já grava por ele**,
o que dá à peça um chamador real hoje.

**A primeira versão foi maior, e era especulativa.** Ela tinha também
`camposObrigatoriosDePaciente(regras)` e `faltamNoPaciente(dados, regras)`, para
consumidores que não existem, e a segunda ia além do FR-010: validar cadastro é
do módulo que tiver o formulário, não deste arquivo. O eixo Spec da revisão
chamou de abstração especulativa, com razão, e as quatro funções viraram duas.

**O FR-010 só fecha quando os módulos de pacientes e de consultas nascerem e
usarem essas funções.** Fica registrado aqui para que a regra do módulo
correspondente já nasça citando-as.

### Dois defeitos menores que a mesma revisão achou, e não dependem de decisão

- **`bank_accounts` tem `is_system`**, e `contas-bancarias` em `catalogo.ts` não
  marcava `temIsSystem`: a conta "Caixa (dinheiro)", semeada em toda clínica
  nova, aparecia sem selo e parecia editável. **Corrigido em 28/08**, junto com
  o FR-006, porque trava no banco sem selo na tela produz erro sem explicação.
  Há teste travando isso, e ele cobre os dois catálogos com `is_system`.
- **FR-005 está parcial em `chart_of_accounts`.** A tela lê `active`
  (`plano-de-contas/page.tsx`), e nenhuma action escreve: não há como desativar
  uma conta. É trabalho de app, não decisão.

### O que já estava fechado, e continua

A ambiguidade da ModuleKey `consultas`, que era a pergunta aberta desta regra
quando ela foi escrita em 25/08, **foi decidida** e vive em
[`../adr/0001-consultas-sai-do-contrato-de-modulos.md`](../adr/0001-consultas-sai-do-contrato-de-modulos.md).
As quatro decisões próprias da regra (o formato objeto de `enabled_modules`, o
default `'{}'`, a desativação lógica e o componente único de período) estão
fechadas nos requisitos acima.

A segunda metade do **FR-010**, que manda os formulários dos módulos posteriores
obedecerem a `patient_required_fields`, não é decisão nem defeito: os módulos que
a cumpririam ainda não existem. Ela fecha com eles.
