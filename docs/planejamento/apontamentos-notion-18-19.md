# Apontamentos triados — prontos para colar no Notion

> Base **Apontamentos**, página da rodada
> `Bateria de testes — Vinícius — 17 a 21/08 — pré-lançamento`.
> Gerado em 20/08/2026 a partir de [triagem-baterias-18-19.md](triagem-baterias-18-19.md),
> no formato da skill `nx-apontamento`. **Um registro por problema.**

O campo **Tipo** aqui é o da triagem, não o rótulo original do relato —
em alguns itens eles divergem, e a triagem segue a regra do plano de
lançamento. O código `V-xx` é o mesmo dos dois documentos: use-o para
cruzar Notion e repositório.

**Trava de lançamento: 23** bugs com Atrapalha muito = sim (após as
decisões de 20/08, que promoveram o V-11).

---

## Bugs

### V-01 — Scroll da lista de especialidades trava no cadastro do médico

**Onde:** cadastro inicial de médico (onboarding, pré-`/configuracoes`)
**O que eu fiz:**
1. Iniciar cadastro de médico (Dr./Dra. + nome).
2. Avançar até o campo de especialidade.
3. Abrir a lista e tentar rolar até o fim.
**O que aconteceu:** o scroll da página trava com a lista de especialidades aberta; parte das opções fica inacessível.
**O que eu esperava:** ver a lista completa de especialidades, navegável por scroll, sem corte — segundo o próprio relato do Vinícius (regra completa e sem ambiguidade, vale como especificação).

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte (CSS/componente de front)

### V-04B — Linha órfã em `team_members` quando a criação de acesso falha

**Onde:** Configurações → Equipe (`ConfigTeamDialog`)
**O que eu fiz:**
1. (histórico, já ocorreu com o código antigo) Tentar salvar uma secretária com "criar acesso" marcado, repetidas vezes, com a function falhando.
2. Verificar em Configurações → Equipe quantas linhas existem para o mesmo nome/e-mail.
**O que aconteceu:** cada tentativa de salvar (mesmo com a function falhando) inseriu uma linha nova em `team_members`, gerando duplicatas da mesma secretária.
**O que eu esperava:** se a criação do acesso falhar, a tentativa não deve deixar uma linha duplicada e órfã em `team_members` a cada nova tentativa — ou a operação é revertida por inteiro, ou fica claramente sinalizada como "sem acesso" sem duplicar.

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte (reordenar o fluxo — só confirmar/gravar `team_members` após sucesso do convite, ou implementar rollback) **+** SQL editor (apagar as linhas duplicadas/órfãs já existentes nas clínicas de teste, inclusive a do Vinícius, antes do lançamento).
**Depende de:** nada (independente do reteste de V-04, mesma área de código)

### V-10 — Agenda permite marcar dois pacientes no mesmo médico, mesmo dia e horário

**Onde:** `/acompanhamento` (Consultas)
**O que eu fiz:**
1. Marcar consulta para o Médico A, Paciente 1, num horário X.
2. Marcar outra consulta para o Médico A, Paciente 2, no mesmo dia e horário X.
3. Ambas são salvas sem erro.
**O que aconteceu:** o sistema aceita duas consultas conflitantes sem aviso.
**O que eu esperava:** "Que houvesse um bloqueio de agenda, que o sistema me informasse que esse horário já não está disponível." (regra completa.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte (validação no salvamento) + SQL editor (constraint/ trigger de unicidade médico+horário, como segunda camada — mesma filosofia de "segurança mora no banco" já usada no resto do produto).

### V-12 — Consulta avulsa não gera as tarefas automáticas (anamnese, confirmação)

**Onde:** `/acompanhamento` (lançamento de consulta avulsa) → `/tarefas`
**O que eu fiz:**
1. Ir em Consultas → "+ Nova Consulta" (fluxo avulso, sem passar pelo Atendimentos/funil).
2. Selecionar um paciente já cadastrado.
3. Salvar a consulta.
4. Ir em Tarefas e conferir que não aparece `confirmar_agendamento` nem `envio_anamnese` para essa consulta.
**O que aconteceu:** nenhuma tarefa automática é criada para consultas lançadas fora do wizard Lead→Consulta.
**O que eu esperava:** "Que as tarefas fossem criadas automaticamente, como no caso dos pacientes que vêm do CRM, com data de realização e responsável definido." (regra completa.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** nada — mas ver ATR-1 (tema "atribuição de tarefa" na seção de decisões) sobre o que fazer quando a consulta avulsa também não tem responsável definido (V-11).

### V-13 — Dashboard: contagem de "novos pacientes" e "novas consultas" incorreta

**Onde:** `/` (Dashboard)
**O que eu fiz:**
1. Cadastrar/mover pacientes pelo CRM e também lançar consultas avulsas.
2. Comparar o card do Dashboard com a contagem manual de consultas marcadas como "1ª vez"/vindas do CRM no período.
**O que aconteceu:** os cards de "novos pacientes" e "novas consultas" do Dashboard contam algo diferente do que o relatório de Vendas usa para a mesma noção.
**O que eu esperava:** "Que a quantidade de novos pacientes se refira apenas às consultas de 1ª vez, ou seja, aquelas que foram geradas a partir do CRM ou que possuam categoria de 1ª consulta. No quadro de consultas realizadas, o mesmo filtro deve ser aplicado para definir a quantidade de novas consultas realizadas." (regra completa — bate com a coluna "1ª VEZ?" que já existe no relatório de Vendas, `INVENTARIO-UI.md`.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** nada, mas ver DASH-1 (tema dashboard) sobre alinhar o cálculo do ticket médio à mesma metodologia.

### V-14 — Dashboard: adiantamento de consulta contabilizado como venda

**Onde:** `/` (Dashboard)
**O que eu fiz:**
1. Marcar consulta como compareceu.
2. Registrar um adiantamento na consulta (sem orçamento de prescrição ainda).
3. Conferir no Dashboard os cards TOTAL CONSULTAS e TOTAL VENDAS.
**O que aconteceu:** o valor do adiantamento soma no total de "vendas", não no total de "consultas".
**O que eu esperava:** "O correto é que esse valor seja atribuído às consultas, não às vendas gerais." (regra completa — coerente com a separação Consulta × Prescrição/Venda já documentada em `INVENTARIO.md`, Anexo.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte

### V-15 — Tarefa de recaptação atribuída ao médico, não ao responsável pela venda

**Onde:** `/tarefas` (gerada a partir de `/acompanhamento`, cancelamento com recaptação)
**O que eu fiz:**
1. Cancelar uma consulta agendada com responsável definido.
2. Marcar para entrar em recaptação.
3. Conferir em Tarefas o campo RESPONSÁVEL da tarefa gerada.
**O que aconteceu:** a tarefa nasce atribuída ao `doctor`/profissional do atendimento.
**O que eu esperava:** "Deveria ser criada uma tarefa atribuída para o responsável pela venda, não ao médico." (regra completa para o caso em que existe um responsável definido.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** ATR-1 (tema "atribuição de tarefa") — o que fazer quando não há responsável definido (caso das consultas avulsas, V-11).

### V-16 — Tarefa de remarcação (não comparecida) atribuída ao médico, não ao responsável pela venda

**Onde:** `/tarefas` (gerada a partir de `/acompanhamento`, "não comparecida")
**O que eu fiz:**
1. Marcar uma consulta agendada como "não comparecida" (motivo ≥3 caracteres, per `INVENTARIO.md §3.4`).
2. Conferir o RESPONSÁVEL da tarefa de remarcação gerada.
**O que aconteceu:** idem V-15, mas no caminho de "não comparecida".
**O que eu esperava:** "Deveria ser criada uma tarefa atribuída para o responsável pela venda, não ao médico." (mesma regra de V-15.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** ATR-1; mesma correção de V-15 (aplicar no mesmo commit).

### V-17 — Tarefas: filtros fazem os dados sumirem

**Onde:** `/tarefas`
**O que eu fiz:**
1. **não reproduzido** — falta saber qual dos 4 filtros (tipo, status, responsável, período) foi usado e com qual valor. Pergunta para devolver: "Qual filtro (ou combinação) você usou quando os dados sumiram — tipo, status, responsável ou período? Que valor selecionou em cada um? O status padrão da tela já é 'Pendente' — você trocou para outro status, ou mudou o período para 'Hoje'?"
**O que aconteceu:** aplicar filtro(s) na tela de Tarefas zera a lista.
**O que eu esperava:** "Que os filtros funcionassem para melhor navegação pelos clientes." (Vinícius não descreve qual filtro, nem os valores usados — insuficiente para reproduzir sem adivinhar.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte (após a resposta)
**Depende de:** resposta à pergunta acima

### V-18 — Financeiro: valor a receber só traz a prescrição, não a consulta

**Onde:** financeiro pós-consulta (tela de recebimento aberta a partir de `/acompanhamento`)
**O que eu fiz:**
1. Marcar consulta como compareceu (gera cobrança da consulta).
2. Criar orçamento de outros itens (prescrição) e aprovar.
3. Abrir a tela do financeiro para esse paciente/atendimento.
**O que aconteceu:** o valor da consulta desaparece da tela quando existe também uma prescrição aprovada.
**O que eu esperava:** "Que aparecesse o total a receber da consulta MAIS a prescrição." O relato vai além do mínimo e descreve um desenho em dois blocos com pagamentos independentes — ver FIN-1 na seção de decisões, porque essa parte não é suficiente para implementar sem escolher escopo.

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** FIN-1 (decisão de escopo)

### V-20 — Valor já pago aparece como desconto na prescrição, deveria descontar da consulta

**Onde:** financeiro pós-consulta
**O que eu fiz:**
1. Marcar consulta como compareceu com entrada/depósito pago.
2. Criar orçamento de prescrição e aprovar tudo.
3. Conferir em qual bloco (consulta ou prescrição) o valor pago aparece descontado.
**O que aconteceu:** o desconto do valor pago é aplicado no bloco errado.
**O que eu esperava:** "Que o valor fosse descontado da consulta, não da prescrição. São coisas distintas." (regra completa.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** V-18 (mesma correção provavelmente resolve os dois; aplicar juntos)

### V-21 — Dashboard: bloco de indicadores financeiros zerado/errado após vendas

**Onde:** `/` (Dashboard)
**O que eu fiz:**
1. Marcar consultas como compareceu.
2. Criar orçamentos, aprovar parte dos itens e reprovar outros.
3. Abrir o Dashboard e conferir cada um dos 6 pontos acima.
**O que aconteceu:** seis problemas no mesmo painel: (1) card TOTAL CONSULTAS zerado; (2) ticket calculado por item vendido; (3) TAXA DE CONVERSÃO em 100% mesmo com item reprovado; (4) quadro Ticket Médio (mais alto/mais baixo) zerado; (5) Top Macro-Categorias e Top Profissionais de Saúde zerados; (6) gráfico do Fluxo de Caixa não aparece, apesar de haver saldo.
**O que eu esperava:** "Que as consultas recebidas constassem com seu valor; que o ticket e o ticket médio levassem em consideração a quantidade de orçamentos, não a quantidade de itens; que a taxa de conversão levasse em consideração o que foi vendido em relação ao total orçado, como consta corretamente no painel de consultas; que os top médicos e macro-categorias trouxessem infos de venda; que o fluxo de caixa tivesse um gráfico." (regra completa para cada sub-item, exceto a definição exata de "quantidade de orçamentos" — ver DASH-1.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** V-13, V-14 (mesma camada de agregação do Dashboard) e DASH-1 (definição do cálculo de ticket médio)

### V-22 — Contas a Receber: valores não aparecem conforme a data automática por meio de pagamento

**Onde:** `/contas-receber`
**O que eu fiz:**
1. Vender um item via pix (ou dinheiro).
2. Vender outro via débito.
3. Vender outro via crédito parcelado sem antecipação.
4. Conferir em Contas a Receber a data de vencimento gerada para cada um.
**O que aconteceu:** o sistema usa um "primeiro vencimento" fixo de 30 dias como padrão para todos os métodos, em vez de aplicar a data automática por meio de pagamento.
**O que eu esperava:** "Se pagamento for dinheiro ou pix, o valor cai no mesmo dia da realização da venda, descontadas as taxas; Se débito ou crédito com antecipação, cai no dia seguinte descontadas as taxas; Se crédito sem antecipação, sempre colocar 30 dias pra frente, com o devido parcelamento. Essa informação de primeiro vencimento só deve ser informada se for boleto ou cheque." (regra completa e específica por método — vale como especificação.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** nada — a regra já está completa e sem ambiguidade (decisão #1)

### V-23 — Fluxo de Caixa: mesmo problema de data automática por meio de pagamento

**Onde:** `/fluxo-caixa`
**O que eu fiz:**
1. mesma de V-22, conferindo a tabela diária do Fluxo de Caixa em vez de Contas a Receber.
**O que aconteceu:** idêntico a V-22, refletido no Fluxo de Caixa.
**O que eu esperava:** idêntico a V-22 — mesma regra por método de pagamento, citada literalmente pelo Vinícius nos dois apontamentos.

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte (mesmo commit de V-22 resolve os dois)
**Depende de:** V-22 — corrigir junto, não em separado

### V-24 — Contas a Pagar: plano de contas não carrega ao lançar despesa avulsa

**Onde:** `/contas-pagar`
**O que eu fiz:**
1. Configurar plano de contas em Configurações → Financeiro.
2. Ir em Contas a Pagar → "Novo Lançamento" (despesa avulsa).
3. Abrir o campo "Plano de Contas".
**O que aconteceu:** o combobox de plano de contas não popula opções, impedindo o lançamento.
**O que eu esperava:** "Que o plano de contas carregasse, conforme o que ficou definido nas configurações, para que eu pudesse selecionar corretamente e fazer um lançamento." (regra completa — e é literalmente "passo da rotina que o sistema não deixa fazer", bug por definição do próprio plano da bateria.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** indefinido até investigar — provável ponte (front); se a causa for RLS/dado ausente, SQL editor.

### V-25 — Relatório de Vendas: linhas quebradas e faltam colunas de médico/responsável

**Onde:** `/relatorios/vendas`
**O que eu fiz:**
1. Aprovar um orçamento com 3 unidades do mesmo item.
2. Gerar/baixar o relatório de Vendas.
3. Conferir quantas linhas o item gerou e se há coluna de médico/responsável.
**O que aconteceu:** cada aprovação/parcela vira uma linha separada, sem agrupar por item do orçamento; não há coluna de médico prescritor nem de responsável pela venda.
**O que eu esperava:** "Precisamos apenas que venha como o paciente aprovou no orçamento - se ele aprovou 3 aplicações de vitamina, por exemplo, isso vai aparecer em uma única linha no relatório... com quantidade = 3 e os respectivos valores, meio de pagamento e taxas. Falta aqui também a informação do médico prescritor e o responsável pela venda." (regra completa: agrupar por item aprovado dentro do mesmo orçamento, e acrescentar duas colunas.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** ATR-1 (mesma definição de "responsável" usada em V-15/V-16)

### V-26 — Relatório de Contas a Pagar vem totalmente zerado

**Onde:** `/relatorios/contas-pagar`
**O que eu fiz:**
1. Lançar uma despesa fixa e uma variável em Contas a Pagar.
2. Gerar o relatório de Contas a Pagar para o período correspondente.
**O que aconteceu:** relatório vazio apesar de haver lançamentos.
**O que eu esperava:** "Que viessem os lançamentos de despesas que fiz (nesse momento as taxas e a despesa fixa)." (regra completa.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** nada, mas mesma investigação de V-27 pode revelar causa comum

### V-27 — Relatório de DRE/DFC vem totalmente zerado

**Onde:** `/relatorios/dfc-dre`
**O que eu fiz:**
1. Ter receitas (consultas/vendas) e despesas lançadas no período.
2. Gerar o relatório DRE/DFC.
**O que aconteceu:** relatório vazio apesar de haver entradas e saídas lançadas na semana.
**O que eu esperava:** "Que viessem os lançamentos ajustados, tanto de entrada quanto de saídas." (regra completa.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte
**Depende de:** nada, mas investigar em conjunto com V-26

### V-28A — Relatório de Contas a Receber: datas personalizadas não funcionam

**Onde:** `/relatorios/contas-receber`
**O que eu fiz:**
1. Abrir o relatório de Contas a Receber.
2. Selecionar "período personalizado" e escolher duas datas.
3. Gerar o relatório.
**O que aconteceu:** o seletor de datas personalizadas não filtra o relatório corretamente (ou não é aceito).
**O que eu esperava:** poder escolher um intervalo de datas personalizado e o relatório respeitar esse intervalo — parte clara e objetiva do relato.

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte

### V-28B — Relatório de Contas a Receber: filtros fazem os dados sumirem

**Onde:** `/relatorios/contas-receber`
**O que eu fiz:**
1. **não reproduzido** — o relatório tem múltiplos filtros (período, por vencimento, status, bancos, +2 outros, conforme `INVENTARIO-UI.md`). Pergunta para devolver: "Qual filtro específico (status, banco, 'por vencimento' etc.) você aplicou quando os dados sumiram, e qual valor selecionou em cada um?"
**O que aconteceu:** aplicar filtro(s) zera o relatório.
**O que eu esperava:** "Que os filtros permitissem uma visualização mais simples do relatório." (não especifica qual filtro nem qual valor — insuficiente para reproduzir.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte (após a resposta)
**Depende de:** resposta à pergunta acima; mesma investigação de V-17 pode revelar causa comum (padrão de filtro quebrado em mais de uma tela)

### V-29 — Relatório de Produtividade por Profissional: valor orçado errado

**Onde:** `/relatorios/produtividade`
**O que eu fiz:**
1. **não reproduzido** — falta saber os números: quanto o relatório mostrou de "valor orçado" para qual profissional, e quanto deveria ser (conferido manualmente pelos orçamentos daquele profissional no período). Pergunta para devolver: "Para qual profissional o valor orçado apareceu errado, qual número o relatório mostrou, e qual é o valor correto que você calculou na mão a partir dos orçamentos dele no período?"
**O que aconteceu:** valor orçado divergente do esperado; não há registro de qual era o valor certo nem o mostrado.
**O que eu esperava:** "Que viesse a informação certa sobre os orçamentos, para que fosse possível verificar o % de conversão de cada profissional." (não diz qual é o valor certo nem o errado observado — insuficiente para reproduzir sem adivinhar o que "errado" significa aqui.)

**Tipo:** Bug
**Atrapalha muito:** sim
**Severidade:** trava
**Canal de correção:** ponte (após a resposta)
**Depende de:** resposta à pergunta acima --- ## BUGS — SEVERIDADE ATRAPALHA (Atrapalha muito: Não, mas afeta dado/leitura)

### V-19 — Financeiro: fechamento parcial exibido como "fechamento total"

**Onde:** financeiro pós-consulta
**O que eu fiz:**
1. Marcar consulta como compareceu.
2. Criar orçamento com vários itens.
3. Aprovar só parte dos itens (reprovar/retirar ao menos um).
4. Conferir o rótulo de fechamento na tela financeira/`/acompanhamento` (coluna FECHAMENTO).
**O que aconteceu:** rótulo mostra "Fechou Completo" mesmo com itens não aprovados.
**O que eu esperava:** "Que aparecesse como fechamento parcial, tendo em vista que não foram aprovados todos os itens da lista. Se tudo foi aprovado, é fechamento completo. Se qualquer coisa foi retirada, é fechamento parcial." (regra completa.)

**Tipo:** Bug
**Atrapalha muito:** não
**Severidade:** atrapalha
**Canal de correção:** ponte
**Depende de:** nada --- ## BUGS — SEVERIDADE COSMÉTICO (Atrapalha muito: Não, sem impacto funcional)

### V-02 — Sem tela de boas-vindas após o cadastro inicial

**Onde:** pós-signup → `/configuracoes`
**O que eu fiz:**
1. Concluir o cadastro de clínica/médico.
2. Fazer login pela primeira vez.
3. Observar a primeira tela após o login.
**O que aconteceu:** login pós-cadastro cai direto em `/configuracoes`, sem tela intermediária.
**O que eu esperava:** "Ideal é ter uma página prévia de boas vindas, do tipo 'Dr. (ou Dra.) seja muito bem vindo(a)... Para iniciar, precisamos configurar a sua clínica. Vamos lá?' Com um botão para início." (regra completa, com texto sugerido.)

**Tipo:** Bug
**Atrapalha muito:** não
**Severidade:** cosmético
**Canal de correção:** ponte

### V-06 — Anamnese: sem mensagem de conclusão ao terminar o cadastro inicial

**Onde:** `/anamnese` (fluxo de onboarding — primeiro formulário)
**O que eu fiz:**
1. Completar o passo a passo de configuração inicial até o cadastro de anamnese (última etapa do onboarding).
2. Salvar.
**O que aconteceu:** só um "salvo" genérico, sem indicar que o onboarding terminou.
**O que eu esperava:** "Esperava uma mensagem de finalização de configurações, indicando que agora o sistema está pronto para uso." (regra completa.)

**Tipo:** Bug
**Atrapalha muito:** não
**Severidade:** cosmético
**Canal de correção:** ponte
**Depende de:** V-02 (mesma área — vale desenhar as duas telas de mensagem juntas: boas-vindas no início, conclusão no fim do onboarding) --- ## BACKLOG (registrado; não entra nesta janela de correção)

### V-04 — Erro ao salvar secretária com acesso ("Edge function returned a non-2xx status code")

**Onde:** Configurações → Equipe (`ConfigTeamDialog`)
**O que eu fiz:**
1. 
**O que aconteceu:** a function `invite-team-user` recusava a chamada quando o front tentava criar acesso, retornando status não-2xx; a secretária ficava salva em `team_members`, mas sem login. **O que mudou desde então:** a function foi **reescrita e deployada em produção em 20/08/2026** (`specs/002-seguranca-anamnese-auditoria/tasks.md` T017, commit `dabf1ef`). O caminho antigo — que aceitava e transportava `password` vindo do cliente — **não existe mais**: hoje a function só gera um link de convite (`generateLink`) e quem define a senha é o próprio convidado em `/nova-senha`. Como o caminho que causou a falha original foi substituído por inteiro, **a causa raiz da primeira falha não está explicada pelo código antigo** e não há evidência de que o novo caminho já foi exercitado de ponta a ponta ("falta o aceite manual", nas palavras do próprio T017).
**O que eu esperava:** "Que o acesso da secretária fosse criado, além dela ficar salva na equipe." (Vinícius, regra completa.)

**Tipo:** Bug
**Atrapalha muito:** não
**Severidade:** trava Status: **possivelmente resolvido — exige reteste** (não afirmar corrigido)
**Canal de correção:** já executado via ponte + agente Lovable (redeploy da function, ver `docs/ponte/ponte-inversa.md`, custo 0,4 do crédito diário de build) — falta só o reteste manual acima, que não consome crédito.

---

## Backlog — registrado, não entra na janela de correção

### V-03 — Login sem opção de visualizar a senha digitada

**Onde:** `/login`
**O que eu fiz:**
1. 
**O que aconteceu:** campo de senha sempre mascarado, sem alternância.
**O que eu esperava:** botão/ícone de "olho" para alternar visibilidade da senha.

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (quando entrar na fila de backlog)

### V-05 — Anamnese: especialidade não vem pré-carregada ao escolher template

**Onde:** `/anamnese`
**O que eu fiz:**
1. 
**O que aconteceu:** é preciso selecionar a especialidade de novo.
**O que eu esperava:** especialidade pré-selecionada a partir do cadastro do médico.

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (quando entrar na fila de backlog)

### V-07 — Formulário público de anamnese sem identidade visual da clínica

**Onde:** `/anamnese-publica/:responseId`
**O que eu fiz:**
1. 
**O que aconteceu:** formulário sempre com a marca NexClin.
**O que eu esperava:** possibilidade de branding (logo/paleta) por clínica.

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (feature futura)

### V-08 — Página de respostas de anamnese sem botão de copiar/resumo por IA

**Onde:** `/anamnese` (aba Respostas)
**O que eu fiz:**
1. 
**O que aconteceu:** só a visualização simples das respostas, campo a campo.
**O que eu esperava:** botão de copiar + resumo gerado por IA.

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (feature futura, maior escopo — integra IA)

### V-09 — Ficha do paciente sem canal de entrada nem anamnese visível

**Onde:** ficha do paciente (`/pacientes/:id`)
**O que eu fiz:**
1. 
**O que aconteceu:** os dados existem (em `patients.origin_id/channel_id` e `anamnesis_responses`), mas não são exibidos juntos na ficha — é consolidação de tela, não dado errado.
**O que eu esperava:** canal de entrada e respostas de anamnese visíveis na própria ficha do paciente.

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (feature futura)

### V-11 — Consulta avulsa não permite definir responsável pelo atendimento/marcação

**Onde:** `/acompanhamento` (lançamento avulso)
**O que eu fiz:**
1. 
**O que aconteceu:** o campo só existe no wizard Lead→Consulta.
**O que eu esperava:** campo de responsável disponível também no lançamento avulso.

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (feature futura)
**Depende de:** nada — mas ver ATR-1: enquanto esse campo não existe, V-15/V-16 precisam de um fallback para consultas avulsas sem responsável.

### V-30 — Extra 1: visão de agenda em calendário, somando-se à lista atual

**Onde:** `/acompanhamento`
**O que eu fiz:**
1. 
**O que aconteceu:** só existe visão em lista/tabela hoje.
**O que eu esperava:** visão adicional em calendário (dia/semana/mês).

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (feature futura, escopo maior — novo componente de calendário)

### V-31 — Extra 2: configurar responsável por tipo de atividade (recaptação, confirmação, anamnese)

**Onde:** Configurações → Regras do Negócio (ou Equipe)
**O que eu fiz:**
1. 
**O que aconteceu:** hoje o sistema só tem o conceito único de "responsável" pelo atendimento/venda (que V-15/V-16 corrigem para as tarefas existentes usarem corretamente).
**O que eu esperava:** configuração granular de responsável por tipo de tarefa automática.

**Tipo:** Backlog
**Atrapalha muito:** não
**Canal de correção:** ponte (feature futura)
**Depende de:** V-15, V-16 (a correção mínima "atribuir ao responsável" entra agora; esta configurabilidade fica para depois — é exatamente o exemplo do plano: "o sistema faz certo [atribui ao responsável], mas poderia fazer a mais [deixar escolher por tipo de tarefa]") --- ## ITENS `precisa-decisao` — perguntas prontas para o Arthur Estado diferente de `precisa-detalhe`: aqui o relato é completo o bastante para entender o problema, mas **não é suficiente para implementar sem escolher entre interpretações diferentes**. Agrupado pelos quatro temas pedidos.

