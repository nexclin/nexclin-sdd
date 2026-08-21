# INVENTÁRIO-UI — walkthrough do MVP `nexclin.lovable.app`

> **O que é este arquivo:** o par visual do [INVENTARIO.md](INVENTARIO.md). Aquele
> descreve a lógica (banco, RLS, permissões, regras); este descreve **a tela** —
> o que existe, como é montada, o que o usuário vê e opera. Insumo para a
> reescrita do frontend em Next.js.
>
> **Levantado em:** 16/08/2026, navegando o app publicado no Chrome, logado como
> `erpclinicas@gmail.com` (superadmin + clínica "NexClin").
>
> **Leia com esta ressalva:** o painel superadmin do Lovable **não está
> terminado**. O que falta lá não é regressão — é obra inacabada. Quem manda na
> execução é [specs/001-fundacao-superadmin/spec.md](specs/001-fundacao-superadmin/spec.md);
> este documento serve para mostrar o que existe de fato e onde a spec pede
> "paridade" com algo que não foi construído (ver D5).
> **Método:** somente leitura — nenhum registro criado, editado ou excluído.
> Verificado ao final: `superadmin_audit_log` continua com 27 linhas, a mais
> recente de 28/07/2026. A sessão não escreveu nada.

---

## 0. LINGUAGEM VISUAL

Dois temas distintos, deliberadamente separados:

| | App da clínica | Painel superadmin |
|---|---|---|
| Fundo | creme claro (`#F5F3EF`) | navy escuro (`#0F1729`) |
| Sidebar | navy escuro, fixa, ~220px | navy mais escuro, ~256px |
| Acento | teal | azul + badges semânticas |
| Marca | logo NexClin + "GESTÃO CLÍNICA" | escudo + "SuperAdmin" |

**Padrões repetidos em toda tela do app da clínica:**
- **Breadcrumb** no topo em caixa alta espaçada: `GRUPO / TELA` (grupos: OPERAÇÃO, FINANCEIRO, CLÍNICO, ANÁLISE, SISTEMA).
- **Cabeçalho** com eyebrow numerado (`01 / OPERAÇÃO`), `<h1>` grande em serifada/display, subtítulo descritivo, e botão de ação primário preto à direita.
- **Barra de filtros** logo abaixo: busca + comboboxes.
- **Faixa de KPIs** em cards, depois o conteúdo (tabela, kanban ou grid de cards).
- **Avatar/e-mail** do usuário no canto superior direito.
- Tipografia display para números grandes; rótulos em caixa alta espaçada.

**Sidebar do app (12 itens, ordem exata):** Dashboard `/` · Atendimentos `/atendimentos` · Pacientes `/pacientes` · Consultas `/acompanhamento` · Tarefas `/tarefas` — separador — Contas a Receber · Contas a Pagar · Fluxo de Caixa — separador — Anamnese · Insights IA · Relatórios · Configurações — rodapé: Sair. Colapsável pelo botão `‹`.

**Sidebar do superadmin (10 itens):** Dashboard · Contas · Planos · Cupons · Faturamento · Métricas · Comunicação · Logs · Operadores · Configurações — rodapé: nome do operador + Sair.

---

## 1. FLUXOS PÚBLICOS

### `/login` — não observável
`PublicRoute` redireciona para `/` quando há sessão. Com o usuário logado, não foi possível ver a tela. **Não coberto** — exige janela anônima.

### `/signup` — não observável
Mesmo caso: redirecionou para `/`.

### `/forgot-password` — coberto
Renderiza mesmo com sessão ativa (não está sob `PublicRoute`). Card centrado: marca "NexClin", título "Recuperar senha", subtítulo "Enviaremos um link para redefinir sua senha", campo Email, botão "Enviar link", link "Voltar ao login".

### `/request-access` — coberto
Layout split-screen, o único do produto com cara de landing:
- **Esquerda (navy):** logo, mandala/ícone da marca em teal sobre grid sutil, eyebrow "SISTEMA DE GESTÃO CLÍNICA", headline "O nexus operacional da clínica moderna.", subtítulo, rodapé técnico "NEXCLIN · ERP · V2.4.1 / SISTEMA OPERACIONAL".
- **Direita (creme):** eyebrow "Solicitar demonstração", título "Em breve.", parágrafo e link "← Voltar para o login".
- **É um stub:** não há formulário de solicitação. Só a promessa.

### `/anamnese-publica/:responseId` — não coberto
Exige um id real de resposta pendente; nenhum apareceu na navegação.

---

## 2. APP DA CLÍNICA

### `/` — Dashboard
Módulo: interno (sem `RequirePermission`). Guard: `ProtectedRoute` + `OnboardingGuard`.

Densíssima — a tela mais complexa do produto. De cima para baixo:
1. Cabeçalho `/ Visão geral · agosto 2026` + seletor **PERÍODO** (Hoje, Esta Semana, Este Mês, Mês Anterior, Últimos 3 Meses, Personalizado).
2. **Card hero escuro** (largura total): FATURAMENTO BRUTO em número gigante, com PROJEÇÃO / PERÍODO / RECEBIMENTOS embaixo; à direita META DO PERÍODO + barra de progresso e "R$ X restante · N%".
3. **4 cards de funil** com ilustração fantasma: NOVOS LEADS, AGENDAMENTOS, CONSULTAS, FECHAMENTOS — e entre eles duas pílulas de conversão (`0% agendam`, `0% comparecem`).
4. **4 cards de receita:** TOTAL CONSULTAS, TOTAL VENDAS, TOTAL CONSOLIDADO, TAXA DE CONVERSÃO (com "R$ X de R$ Y orçados").
5. **Financeiro do Período** (link VER DETALHES): Faturamento Bruto, Recebimentos efetivados, Despesas operacionais, Comissões e repasses, Saldo do período.
6. **Ticket Médio** (link ANÁLISE) com MAIS ALTO / MAIS BAIXO.
7. **Top Macro-Categorias** e **Top Profissionais de Saúde** — rankings com empty state instrutivo ("Aprove orçamentos para popular o ranking").
8. **PRIMEIRA CONSULTA** (progresso vs meta 30) e **TAREFAS PENDENTES** (barra vermelha de atrasadas).
9. **Fluxo de Caixa** — gráfico de área semanal, "vermelho indica saldo negativo", SALDO FINAL destacado.
10. **Alertas** (lista com botão VER por item) e **Atalhos Rápidos** (Novo Lead, Ver Tarefas, Nova Receita, Nova Despesa).
11. **Insights IA** (VER TODOS →) — 2 cards com categoria e texto.

Reescrita: o corpo é Server Component com um `searchParams.periodo`; só o seletor de período e os gráficos precisam ser client.

### `/atendimentos` — Kanban de leads
Módulo `leads`. Ação primária "+ Novo Lead". Filtro de período. **6 KPIs:** Total de Leads, Em Atendimento, Agendados, Não Agendados, Recaptação, Taxa Conversão.

Abas **Funil | Leads** (board × lista). O board tem **4 colunas** com bolinha colorida, título e contador: `Novo / Em Atendimento` (azul), `Agendou` (verde), `Recaptação` (roxo), `Não Agendou (Encerrado)` (vermelho).

Card de lead: nome em destaque, telefone com ícone, interesse com ícone de balão, e chips de origem/canal (ex.: `Google` + `Whatsapp`); quando agendado, chip verde `Agendado` com ícone de calendário.

Reescrita: drag-and-drop é obrigatoriamente client. O arraste para `Agendou` abre o wizard Lead→Consulta (ver [INVENTARIO.md §3.4](INVENTARIO.md)) — o wizard não foi aberto nesta passagem para não arriscar escrita.

### `/pacientes`
Módulo `pacientes`. "+ Novo Paciente", busca por nome/telefone, filtro de período. Estado observado: **vazio** — card grande centrado com ícone de pessoa e "Nenhum paciente encontrado", por efeito do filtro "Este mês" (ver §5, divergência D2).

### `/acompanhamento` — Consultas / Vendas
Módulo `acompanhamento`. Rotulada "Consultas" no menu. "+ Nova Consulta", busca ("Buscar paciente, profiss…"), filtro de status ("Todos os status"), filtro de período.

**8 KPIs com ícone:** Total, Pendente Conf., Confirmadas, Compareceu, Não Compareceu, Canceladas, Total Orçado (R$), Total Vendas (R$).

**Tabela de 11 colunas com scroll horizontal:** ▸ (expandir) | STATUS | DATA | HORÁRIO | PACIENTE | PROFISSIONAL | FECHAMENTO | V. PRESCRITO | V. APROVADO | RESPONSÁVEL | FINANCEIRO | AÇÕES.
- **STATUS é um combobox inline na linha** — é por ali que a máquina de estados `agendada → confirmada → compareceu | nao_compareceu | cancelada` é operada.
- FECHAMENTO traz rótulos como "Fechou Completo"; FINANCEIRO traz "Receber" / "Lançado" / "—".
- **Linha expandida** mostra os itens do orçamento: `Vitamina D3 - 600.000ui | Qtd: 4 | R$ 200,00 | [Aprovado] | R$ 400,00`.

Reescrita: a linha inteira é interativa — client component com mutação otimista. Os diálogos de no-show/cancelamento (motivo ≥3 chars) não foram abertos.

### `/tarefas`
Módulo `tarefas`. "+ Nova Tarefa". **4 filtros:** tipo, status (default "Pendente"), responsável, período.

Duas seções empilhadas: **"Tarefas Atrasadas (6)"** com cabeçalho vermelho e ícone de alerta, e **"Tarefas Pendentes"**.

Tabela: checkbox | TÍTULO ⇅ | TIPO ⇅ | PACIENTE | RESPONSÁVEL ⇅ | VENCIMENTO ⇅ | STATUS ⇅ | 🗑. Colunas ordenáveis (ícone ⇅). Tarefas de anamnese trazem um botão secundário **"Copiar Link"** dentro da célula de título. Badges: `Atrasada` (vermelha) e `Pendente` (neutra).

Tipos vistos: `confirmacao`, `Envio de Anamnese`, `Recaptação` — inconsistentes entre si (ver divergência D3).

### `/contas-receber`
Módulo `contas_receber`. "+ Nova Conta", busca, status, período. Observado **vazio**: "Nenhuma conta encontrada".

### `/contas-pagar`
Módulo `contas_pagar`. Subtítulo "Gerencie despesas e contas fixas". **Abas: Contas a Pagar | Contas Fixas** — ou seja, `ContasFixas.tsx` **não é tela órfã**, é uma aba (ver divergência D1). Filtros de status e período; botão "Novo Lançamento".

Tabela: STATUS | VENCIMENTO | DESCRIÇÃO | PLANO DE CONTAS | FORNECEDOR | VALOR | ORIGEM | AÇÕES. Exemplo real: `Pendente · 25/08/2026 · Aluguel · 4.1.1 - Aluguel · — · R$ 4.000,00 · Conta Fixa`.

### `/fluxo-caixa`
Módulo `fluxo_caixa`. Seletores independentes de **mês** e **ano** (não usa o combobox de período das outras telas). **3 cards:** Entradas Previstas (verde), Saídas Previstas (vermelho), Saldo do Período.

**Gráfico "Evolução do Saldo Acumulado"** — área com legenda "Áreas em vermelho indicam períodos com risco de furo de caixa" e SALDO INICIAL no canto.

**Tabela diária do mês inteiro** (31 linhas): DATA (com dia da semana entre parênteses: `25/08 (terça)`) | ENTRADAS | SAÍDAS | SALDO DO DIA | ACUMULADO. Células sem valor viram `—`.

### `/anamnese`
Módulo `anamnese`. Abas **Formulários | Respostas**. "+ Novo Formulário". Tabela: TÍTULO | ESPECIALIDADE | CAMPOS | PADRÃO | 🗑. Registro existente: `Anamnese — Geral · Outra · 15 campos · —`.

### `/insights` — Insights IA
Módulo `insights`. Breadcrumb `ANÁLISE / INSIGHTS IA`. Combobox de janela ("Semanal") + botão **"Gerar Insights"** com ícone de faísca (não acionado — dispara a edge function de IA). Filtro "Todas categorias".

**Grid de 2 colunas de cards:** ícone de lâmpada + título, chip de categoria (Comercial · Marketing · Financeiro · Operação), chip de severidade (Alta · Média), timestamp `19/07 00:02`, parágrafo com o diagnóstico, e 🗑 para descartar. Havia 8 cards, de duas gerações (19/07 e 15/05).

### `/relatorios` — índice
Módulo `relatorios_*`. Grid de **7 cards** em 3 colunas, cada um com ícone, título, chip de categoria (Comercial / Financeiro / Produtividade), descrição de uma linha e link "Gerar relatório →".

### `/relatorios/*` — as 7 telas
**Template comum:** ← voltar · eyebrow `/ RELATÓRIO` · título · subtítulo · botões **CSV** e **XLSX** à direita · linha de filtros · KPIs · tabela. Empty state: "Nenhum registro encontrado para o período selecionado".

| Rota | Filtros | Colunas |
|---|---|---|
| `/leads` | período, origens, canais, status, responsável, objeções | DATA 1º CONTATO · NOME · ORIGEM · CANAL · INTERESSE · STATUS FINAL · OBJEÇÃO · RESPONSÁVEL · OBSERVAÇÃO |
| `/vendas` | período, categorias, +4 | DATA DA VENDA · PACIENTE · 1ª VEZ? · DESCRIÇÃO DA VENDA · CATEGORIA · MACRO-CATEGORIA · QTD · VALOR PAGO · MEIO DE PGTO · BANDEIRA · % TAXA · VALOR LÍQUIDO · OBSERVAÇÕES |
| `/contas-pagar` | período, por vencimento, status, agrupamentos, bancos, natureza | DT. VENCIMENTO · DT. PAGAMENTO · ITEM/DESCRIÇÃO · AGRUPAMENTO (PLANO DE CONTAS) · VALOR · STATUS · BANCO · RECORRÊNCIA · NATUREZA PF/PJ |
| `/contas-receber` | período, por vencimento, status, bancos, +2 | DT. VENCIMENTO · DT. RECEBIMENTO · ITEM/DESCRIÇÃO · CATEGORIA · MACRO-CATEGORIA · VALOR BRUTO · VALOR LÍQUIDO · STATUS · BANCO · FORMA DE PGTO |
| `/dfc-dre` | período, "Realizado + Projetado" | 5 KPIs (ENTRADAS BRUTAS, ENTRADAS LÍQUIDAS, SAÍDAS PAGAS, RESULTADO REALIZADO, RESULTADO PROJETADO) + tabela "Entradas por Macro-Categoria" + "Saídas por Plano de Contas" + dois cards de resultado + nota de rodapé ("não substitui uma DRE contábil completa") |
| `/produtividade` | período, profissional | PROFISSIONAL · ATENDIMENTOS · FAT. CONSULTAS · QTD VENDAS · FAT. VENDAS (PRESC.) · % CONVERSÃO · FATURAMENTO TOTAL · TICKET MÉDIO |
| `/repasse` | período, +3 | DATA · PACIENTE · RESPONSÁVEL · TIPO · PRODUTO/SERVIÇO · QTD · VALOR FATURADO · MODO DE PGTO · IMPOSTOS (%) · IMPOSTOS (R$) · TAXA CARTÃO (%) · TAXA (R$) · CUSTO DIRETO · CUSTO SALA · LÍQUIDO FINAL |

### `/configuracoes`
Módulo `configuracoes`. Não é formulário: é um **hub de 11 cards em 3 grupos**, cada card abrindo um diálogo. Cada grupo tem um cabeçalho com ícone em pastilha teal.

- **Clínica:** Equipe e Permissões · Cadastro de Pacientes · Cadastro de Consultas · Regras do Negócio
- **Vendas:** Canais e Origens · Serviços / Procedimentos · Objeções
- **Financeiro:** Meios de Pagamento · Plano de Contas · Contas Bancárias · Metas

**Diálogo "Equipe" (aberto e fechado sem salvar):** título, busca "Buscar membro…", filtro segmentado Todos | Ativos | Inativos, botão "+ Novo", tabela NOME | FUNÇÃO | REGISTRO | ATIVO. Resultado: "Nenhum membro encontrado" — e **nenhum contador de assentos** visível (ver divergência D4).

Os outros 10 diálogos não foram abertos (evita risco de escrita); a lógica de cada um está em [INVENTARIO.md §3.4](INVENTARIO.md).

---

## 3. PAINEL SUPERADMIN

### `/superadmin` — Dashboard
**8 KPIs** em duas fileiras de 4, cada um com ícone colorido: MRR · ARR · Contas Ativas · Em Trial (16) · Churn do Mês · ARPU · Inadimplentes · Total Contas (16).

**4 gráficos** em grid 2×2: Evolução do MRR (linha) · Crescimento de Contas (linha) · Churn Mensal (barras) · Distribuição por Plano.

### `/superadmin/contas`
Busca ("Buscar por nome, responsável ou CNPJ…") + **filtro segmentado de status:** Todas · Trial · Ativa · Inadimplente · Suspensa · Cancelada.

Tabela: CLÍNICA | RESPONSÁVEL | STATUS (badge) | DESDE | AÇÕES → **"Ver"** (olho) e **"Acessar conta"** (seta, em âmbar). 16 contas, todas em Trial, quase todas de teste.

### `/superadmin/contas/:id` — detalhe
Cabeçalho: ← · nome da clínica · CNPJ · botão "Acessar conta" (âmbar) · **badge de risco** (coração + score + rótulo, ex.: `5 Risco`).

**3 cards:** Dados Cadastrais (Especialidade, Desde) · Responsável (Nome, Telefone) · Assinatura (Plano, Status, Trial até).

**Faixa "Uso do Sistema"** com 6 contadores: Equipe · Leads · Pacientes · Consultas · Tarefas · Recebíveis.

**Painel "Ações" — 7 botões**, cada um com sua cor: Alterar Plano (azul sólido) · Estender Trial · Aplicar Desconto · Registrar Reembolso · Nota Interna (desabilitado) · Suspender (âmbar) · Cancelar (vermelho).

**Timeline** no rodapé — "Nenhum evento registrado" nas duas contas inspecionadas.

Duas contas foram abertas (uma sem responsável, outra com) e **nenhuma das duas oferece editar perfil, trocar e-mail ou disparar reset de senha** (ver divergências D5 e D6).

### `/superadmin/planos`
"+ Novo Plano". Tabela: NOME (com chip `Trial padrão`) | MENSAL | ANUAL | TRIAL | STATUS | VISIBILIDADE | AÇÕES (✏️ editar, ⧉ duplicar). Um único plano: `Trial Padrão · R$ 0,00 · R$ 0,00 · 14 dias · Ativo · Interno`.

### `/superadmin/cupons`
"+ Novo Cupom". Tabela vazia: CÓDIGO | DESCONTO | APLICA EM | DURAÇÃO | USO | VALIDADE | STATUS | AÇÕES → "Nenhum cupom cadastrado".

### `/superadmin/faturamento`
Abas **Cobranças | Inadimplência (0)**. Filtro segmentado: Todas · Pendente · Pago · Falhou · Reembolsado. Tabela: DATA | CONTA | PLANO | VALOR | STATUS | TENTATIVAS | AÇÕES → vazia.

### `/superadmin/metricas`
**3 KPIs:** Conversão Trial → Pago (`0.0%`, "0 de 16") · Contas em Risco (score <50) = 15 · Score Médio = 11.

**2 gráficos de barra horizontal:** "Uso por Módulo (total de registros)" (Tarefas, Leads, Pacientes, Consultas, Recebíveis) e "Distribuição por Especialidade" (Não informado, Outra, Urologia, Gastroenterologia, Clínica Geral).

**Tabela "Health Score por Conta":** CONTA | PLANO | SCORE (badge) | STATUS | LEADS | PACIENTES | CONSULTAS | EQUIPE. 15 contas com score 5 (`Risco`) e a conta "NexClin" com **93 (`Saudável`)** — leads 5, pacientes 5, consultas 4, equipe 3.

### `/superadmin/comunicacao`
"Nova Comunicação" (azul). Card **"Variáveis disponíveis"** com chips monoespaçados: `{nome_clinica}`, `{nome_responsavel}`, `{plano_atual}` — cada um com sua legenda. Empty state ilustrado: "Nenhuma comunicação enviada ainda / Use o botão acima para criar uma nova comunicação em massa."

### `/superadmin/logs`
"Audit Logs — Registro de todas as ações administrativas". Botão **Exportar CSV** + filtro "Todas as ações". Tabela: DATA | OPERADOR | AÇÃO | CONTA | MOTIVO. 27 linhas; ações observadas: `impersonation start`, `impersonation end`, `profile edit`, `email change`, `password reset sent` e **`password set`**. Coluna MOTIVO sempre `—`.

### `/superadmin/operadores`
Tabela: NOME | EMAIL | PERFIL | STATUS | ÚLTIMO LOGIN | AÇÕES. Um operador: `Dr. Erick Reis · erpclinicas@gmail.com · Super Owner · Ativo · —`. **ÚLTIMO LOGIN nunca é preenchido**, mesmo com a sessão ativa.

### `/superadmin/configuracoes`
Formulário de página inteira com botão **Salvar** no topo, em 3 blocos:
- **Configurações Gerais:** Email de suporte (placeholder `suporte@nexclin.com.br`), URL Termos de Uso, URL Política de Privacidade — **os três vazios**.
- **Configurações de Trial:** Duração padrão (14) · Plano do trial (Trial Padrão) · Máx. extensão (14) · toggle "Exigir cartão no trial" (desligado).
- **Régua de Inadimplência:** Emails de aviso (dias) · Suspensão automática (D+) · Cancelamento automático (D+) · Tentativas de recobrança.

### `/superadmin/login` — não coberto
Não visitada para não arriscar a sessão ativa.

---

## 4. DELTA CONTRA O QUE JÁ FOI PORTADO

O repo tem hoje, em [app/superadmin](app/superadmin): `login/page.tsx`, `(panel)/layout.tsx`, `(panel)/page.tsx` (dashboard) e `(panel)/contas/page.tsx` + `enter-clinic-button.tsx`.

Portado: **2 de 11** telas do painel. Faltam: detalhe da conta (`contas/:id`, a mais densa), planos, cupons, faturamento, métricas, comunicação, logs, operadores, configurações do SaaS. E o app da clínica inteiro — 12 rotas + 7 sub-relatórios + 11 diálogos de configuração — está em zero.

Como o superadmin do Lovable também está inacabado, a conta é de duas frentes: das 9 telas que faltam portar, 8 têm modelo pronto para copiar; a **seção de Perfis** (D5) não tem, e precisa ser desenhada antes de executada.

---

## 5. DIVERGÊNCIAS ENCONTRADAS

**D1 — `ContasFixas.tsx` não é tela órfã.** [INVENTARIO.md §3.1](INVENTARIO.md) a lista entre as páginas "NÃO roteadas nem no menu". Ela é a segunda aba de `/contas-pagar`, alcançável pela UI. Vale reconferir o mesmo para as outras cinco "órfãs".

**D2 — filtro "Este mês" esconde cadastro.** `/pacientes` mostra "Nenhum paciente encontrado" e `/acompanhamento` "Nenhuma consulta encontrada" com o filtro padrão, embora existam 5 pacientes e 4 consultas (trocando para "Este ano", tudo aparece). Aplicar recorte temporal a uma lista de cadastro faz a base parecer vazia. Decidir na reescrita: cadastro não deveria ter filtro de período por padrão.

**D3 — três vocabulários de período convivendo.** Dashboard: `Hoje / Esta Semana / Este Mês / Mês Anterior / Últimos 3 Meses / Personalizado`. Consultas: `Hoje / Últimos 7 dias / Este mês / Mês passado / Último trimestre / Este ano / Personalizado`. Fluxo de Caixa: seletores separados de mês e ano. Na reescrita isso tem de ser **um** componente. Mesmo problema nos rótulos de tipo de tarefa: `confirmacao` (enum cru) ao lado de `Envio de Anamnese` e `Recaptação` (formatados).

**D4 — contador de assentos ausente.** [CLAUDE.md §3.4](CLAUDE.md) afirma que as telas mostram "Acessos: X de Y". Não aparece nem na sidebar nem no diálogo Equipe.

**D5 — a seção de Perfis não existe no build publicado (esperado: o superadmin do Lovable não está terminado).** Duas contas foram abertas (com e sem responsável) e o painel Ações tem só os 7 botões de assinatura — nada de editar perfil, trocar e-mail ou enviar reset. O audit log, porém, **registra** `profile edit`, `email change` e `password reset sent` em 26–28/07: o backend foi exercitado, a tela é que não ficou pronta. Bate com a ressalva de [INVENTARIO.md §3.6](INVENTARIO.md) sobre a etapa 3c-2.

> **Consequência prática para a execução.** A Fase 4 da spec pede, no item 3, "a seção de Perfis com edição auditada, troca de e-mail e envio de reset — **paridade com a referência**" ([specs/001-fundacao-superadmin/spec.md:87](specs/001-fundacao-superadmin/spec.md#L87)), e o critério de aceite 6 cobra o comportamento. Só que **não há referência visual a copiar** — a tela nunca existiu no build. O executor vai chegar nesse item sem modelo. Ou se define o desenho dessa seção na spec (campos, onde mora no detalhe da conta, confirmação da troca de e-mail), ou se troca "paridade com a referência" por um contrato explícito. Este é o ajuste mais acionável que a passagem produziu.

**D6 — `password set` no audit log (histórico; já neutralizado no porte).** Linha de 28/07/2026 15:37, operador Dr. Erick Reis, conta "Clínica Teste Bypass" — prova de que o ambiente Lovable teve um caminho que definia senha diretamente, contra a regra (e) de [CLAUDE.md §4](CLAUDE.md). **Já está resolvido deste lado:** a edge function portada removeu a action explicitamente por conformidade ([supabase/functions/superadmin-manage-user/index.ts:129](supabase/functions/superadmin-manage-user/index.ts#L129)), restando só `update_email` e `send_password_reset`. Fica registrado como evidência de que a trava é necessária — e como lembrete de que a UI nova não pode reintroduzir o caminho.

**D7 — timeline da conta vazia apesar do audit log.** [CLAUDE.md §3.4](CLAUDE.md) diz que toda ação de operador grava duas linhas (`superadmin_audit_log` + `account_timeline`). A conta "Clínica Teste Bypass" tem 9 entradas no audit log e a Timeline do detalhe mostra "Nenhum evento registrado". Ou a dupla escrita não acontece, ou a Timeline lê a fonte errada.

**D8 — crash intermitente na carga fria.** O primeiro acesso a `/` renderizou tela branca com `Minified React error #310` (mais hooks renderizados que na renderização anterior) e `#root` vazio. Recarregando, funcionou. Erro de ordem de hooks em algum componente do shell — na reescrita, atenção a hooks depois de early-return em `AppLayout`/guards.

**D9 — série de 12 meses sem julho.** Os gráficos do dashboard superadmin rotulam `set out nov dez jan fev mar abr mai jun ago` — 11 rótulos, com "jul" faltando entre jun e ago. Provável off-by-one na geração do eixo.

**D10 — Equipe vazia × Health Score = 3.** O diálogo Equipe da clínica NexClin diz "Nenhum membro encontrado", mas `/superadmin/metricas` reporta EQUIPE = 3 para a mesma clínica, e as consultas referenciam Dr. Erick Reis e Dra. Maria como profissionais. As duas telas contam `team_members` de formas diferentes.

**Confirmado (sem divergência):** `/login` e `/signup` sob `PublicRoute` (rebateram para `/`), enquanto `/forgot-password` e `/request-access` renderizam com sessão — exatamente como [INVENTARIO.md §3.1](INVENTARIO.md) descreve.

---

## 6. NÃO COBERTO

| Item | Por quê |
|---|---|
| `/login`, `/signup` | `PublicRoute` redireciona com sessão ativa — exige janela anônima |
| `/anamnese-publica/:responseId` | precisa de um id real de resposta pendente |
| `/superadmin/login` | não visitada para não arriscar a sessão |
| Wizard Lead→Consulta | abre em fluxo de escrita; não acionado |
| Diálogos de no-show / cancelamento | idem |
| 10 dos 11 diálogos de `/configuracoes` | idem (só "Equipe" foi aberto e fechado) |
| "Gerar Insights" | dispara edge function de IA (escrita + custo) |
| Impersonação ("Acessar conta") e o banner âmbar | ato auditado; exige pedido explícito |
| Telas órfãs `Funil.tsx`, `Funil2.tsx`, `Leads.tsx`, `Despesas.tsx`, `Consultas.tsx` | não roteadas — não observáveis pela UI |
| Estados de plano/permissão (menu reduzido, URL bloqueada, conta suspensa) | a conta usada é superadmin + admin: vê tudo |

Os screenshots desta passagem estão no transcript da sessão, não em disco.
