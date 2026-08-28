# Feature Specification: Resíduos e Conformidade Documental

> **Aviso, 27/08/2026. Movido, não reescrito.** Este documento está no formato
> antigo de spec, e não nas sete seções da regra viva. Foi mantido como estava
> porque está **parado de propósito**: depende de decisão comercial do grupo e de
> emenda à constituição, para a 16ª ModuleKey. Ver a seção de decisões pendentes
> dentro do próprio documento. **Quando a decisão sair, reescreva no formato de
> sete seções antes de executar.**
>
> Onde se lê `specs/`, leia `docs/regras/`.

**Feature Branch**: `013-residuos-conformidade`

**Created**: 2026-08-25

**Status**: Draft — aguarda decisão comercial do grupo (ver §Decisões pendentes)

**Input**: Vídeo de conteúdo enviado por Arthur em 24/08/2026 (transcrição
`WhatsApp Video 2026-08-24 at 22.03.16.txt`), contraposto ao áudio de avaliação
do Vinícius (`WhatsApp Ptt 2026-08-24 at 22.51.14.txt`).

---

## Por que esta spec existe, e por que ela não é o que o vídeo propõe

O vídeo propõe um **micro-SaaS avulso**: cadastro da clínica, comprovantes de
coleta, painel de vencimento, "R$ 200/mês porque o dono prefere pagar a tomar
multa da vigilância". O argumento de venda é **medo**.

O Vinícius — que gere clínicas de verdade — derrubou esse argumento, e a
objeção dele é específica o bastante para ser levada a sério:

- nenhum médico que ele conhece dá importância ao tema, e ele "duvida" que
  paguem R$ 200 por isso;
- de todas as clínicas que ele operou, **uma** contratou consultoria de
  vigilância sanitária;
- a fiscalização é inconstante e **varia por estado** — o que o Rio cobra não é
  o que São Paulo cobra;
- portanto vender pelo medo é vender uma dor que o comprador não sente.

E fechou com a frase que **é** a validação: *"pensando no nosso programa em
agregar mais soluções pra gente cobrar o preço que a gente quer, eu acho que é
muito bom."*

**A tradução disso para spec:** o módulo entra, mas **muda de eixo**. Não é
produto avulso vendido por medo de multa; é **módulo do NexClin que sustenta o
teto de preço do plano** e resolve uma dor que a clínica sente de fato — a
papelada solta, o custo recorrente da coleta que ninguém acompanha, e um prazo
federal, datado e objetivo (a DMR trimestral) que hoje ninguém lembra.

Onde o vídeo diz "zero risco de multa", esta spec diz outra coisa, e a
diferença é deliberada: **o NexClin não promete conformidade — o NexClin
organiza a prova.** Quem responde legalmente é sempre a clínica. Essa
formulação é emprestada, com crédito, do `compliance.md` do projeto OpenClinic
(ver `docs/planejamento/openclinic-analise-2026-08-25.md`).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A coleta que aconteceu e o comprovante que não chegou (Priority: P1)

A recepcionista registra a coleta de resíduos do dia: quem coletou, quando,
quais grupos de resíduo, quanto pesou. Anexa o MTR que o portal do estado
emitiu. Semanas depois, a empresa coletora envia — ou não — o Certificado de
Destinação Final (CDF). O sistema mostra, em uma lista, **quais coletas ainda
estão sem CDF e há quantos dias**.

**Why this priority**: é o único item da cadeia que a clínica realmente não
enxerga hoje. MTR ela emite (o coletor cobra), mas o CDF chega por e-mail,
some, e é justamente o documento que fecha a rastreabilidade. Entregue
sozinho, este story já substitui a pasta física — que é o estado da arte na
clínica média.

**Independent Test**: cadastrar um coletor, lançar duas coletas, anexar MTR em
ambas e CDF em uma; a lista de pendências mostra exatamente uma coleta, com a
idade da pendência em dias.

**Acceptance Scenarios**:

1. **Given** uma coleta registrada há 40 dias com MTR anexado e sem CDF,
   **When** o usuário abre o módulo, **Then** a coleta aparece na lista de
   pendências com o rótulo "sem CDF há 40 dias".
2. **Given** a mesma coleta, **When** o usuário anexa o CDF, **Then** ela sai
   da lista de pendências e a cadeia (coleta → MTR → CDF) fica marcada como
   completa.
3. **Given** um usuário de outra clínica, **When** tenta acessar a coleta por
   URL direta com o ID, **Then** recebe negativa do banco, não da tela.

---

### User Story 2 - O prazo que ninguém lembra (Priority: P1)

O sistema mantém um calendário de obrigações com data certa e avisa antes de
vencer. A obrigação âncora é a **DMR (Declaração de Movimentação de
Resíduos)**, trimestral, com janelas fixas definidas em norma federal: 1º
trimestre entrega em 01–30/abril; 2º em 01–31/julho; 3º em 01–31/outubro; 4º em
01–31/janeiro do ano seguinte. Junto dela entram os vencimentos com data que a
clínica já tem: licença ambiental do coletor, contrato de coleta, revisão do
PGRSS e treinamento anual da equipe.

**Why this priority**: é a única parte da conformidade que é **objetiva,
federal e datada** — imune à objeção do Vinícius sobre a variação estadual da
fiscalização. E tem uma consequência operacional concreta, não hipotética:
enquanto houver DMR pendente, o sistema do órgão **bloqueia a emissão de novas
declarações** — o que trava a documentação da clínica inteira.

**Independent Test**: com a data do sistema em 20/09, o painel mostra a DMR do
3º trimestre como "abre em 01/10"; em 25/10, mostra "vence em 6 dias" com
destaque.

**Acceptance Scenarios**:

1. **Given** a clínica com o módulo ativo e nenhuma DMR marcada como entregue,
   **When** entra a janela de 01/10, **Then** a obrigação aparece como aberta,
   com prazo final 31/10.
2. **Given** a licença ambiental do coletor com validade em 30 dias, **When** o
   usuário abre o painel, **Then** vê o alerta de vencimento com o nome do
   coletor e a data.
3. **Given** uma obrigação marcada como cumprida com o comprovante anexado,
   **When** o prazo passa, **Then** ela não gera alerta e fica registrada no
   histórico do trimestre.

---

### User Story 3 - A pasta que o fiscal pede (Priority: P2)

O usuário escolhe um período e gera o **dossiê de fiscalização**: um único
arquivo com o PGRSS vigente, os contratos e licenças válidos naquele período,
todos os MTR e CDF do período, os comprovantes de DMR e os certificados de
treinamento. Índice na frente, tudo em ordem cronológica.

**Why this priority**: é o momento em que o produto prova seu valor em dois
minutos, e é o que se demonstra numa call de vendas. Depende dos stories 1 e 2
terem dado o que reunir.

**Independent Test**: com seis meses de coletas lançadas, gerar o dossiê do
semestre e conferir que todo documento anexado no período está dentro, com o
índice batendo com o conteúdo.

**Acceptance Scenarios**:

1. **Given** um período com 12 coletas, 12 MTR e 10 CDF, **When** o usuário
   gera o dossiê, **Then** o índice lista as 12 coletas e sinaliza
   explicitamente as 2 sem CDF, em vez de omiti-las.
2. **Given** um documento com validade vencida dentro do período, **When** o
   dossiê é gerado, **Then** ele é incluído com a data de validade visível.

---

### User Story 4 - A coleta também é dinheiro (Priority: P2)

O contrato com a empresa coletora tem valor mensal. Ao registrar o contrato, a
clínica escolhe lançá-lo como **despesa fixa em Contas a Pagar**, e as coletas
do período aparecem vinculadas àquele custo. Quem gere a clínica passa a ver
quanto a gestão de resíduos custa por mês e por unidade de volume coletado.

**Why this priority**: é o que liga o módulo ao motivo pelo qual o NexClin é
comprado — dinheiro — e é o que satisfaz o Princípio VI da constituição sem
depender do argumento regulatório. Fica em P2 porque depende do módulo
`contas_pagar`, que é Onda 2.

**Independent Test**: cadastrar contrato de R$ 480/mês, marcar a integração; a
despesa aparece em Contas a Pagar com a categoria correta e o vencimento certo,
e o painel de resíduos mostra o custo por quilo coletado no mês.

**Acceptance Scenarios**:

1. **Given** um contrato de coleta com valor mensal e dia de vencimento,
   **When** o usuário ativa o lançamento automático, **Then** as parcelas do
   mês corrente e dos meses seguintes nascem em Contas a Pagar — inclusive a do
   mês corrente quando o vencimento já passou (regra D-13 / V-26).
2. **Given** o contrato desativado, **When** o usuário confirma, **Then** as
   parcelas futuras deixam de ser geradas e as passadas permanecem intactas.

---

### Edge Cases

- **Coleta extraordinária** (fora do calendário contratado) — precisa ser
  registrável sem contrato vinculado, porque acontece.
- **Coletor trocado no meio do período** — o dossiê tem de conter as licenças
  dos dois, cada uma no seu intervalo de vigência.
- **MTR emitido e coleta não realizada** (caminhão não veio) — o manifesto
  precisa ser cancelável, com motivo, sem apagar o registro.
- **Clínica em estado cujo portal não é o nacional** (SP usa SIGOR/CETESB, RJ
  usa INEA, e assim por diante) — o número do MTR tem formatos diferentes; o
  campo aceita o formato de qualquer origem e registra **qual sistema emitiu**.
- **Documento anexado com o arquivo errado** — substituição gera nova versão,
  não sobrescreve; o original permanece auditável.
- **Clínica sem geração de resíduo do grupo B ou E** (consultório que só faz
  consulta) — o módulo não pode obrigar preenchimento de grupos que ela não
  gera, sob pena de virar burocracia inútil e ser abandonado.
- **Retenção**: os documentos precisam sobreviver 5 anos (exigência do PGRSS).
  Nenhuma rotina de expurgo pode alcançá-los antes disso.

---

## Requirements *(mandatory)*

### Functional Requirements

**Cadastro e coleta**

- **FR-001**: O sistema MUST permitir cadastrar empresas coletoras com CNPJ,
  número e validade da licença ambiental, e contrato vinculado.
- **FR-002**: O sistema MUST permitir registrar uma coleta com data prevista,
  data realizada, coletor, unidade de atendimento e, por grupo de resíduo, a
  quantidade coletada.
- **FR-003**: O sistema MUST tratar os grupos de resíduo como catálogo
  configurável pela clínica a partir da classificação da RDC ANVISA 222/2018
  (A — biológico, B — químico, C — radioativo, D — comum, E —
  perfurocortante), e MUST permitir que a clínica desative os grupos que não
  gera.
- **FR-004**: O sistema MUST permitir cancelar uma coleta ou um manifesto com
  motivo obrigatório, preservando o registro original.

**Documentos**

- **FR-005**: O sistema MUST permitir anexar documentos a uma coleta ou à
  clínica, tipificados como: MTR, CDF, DMR, contrato de coleta, licença
  ambiental, PGRSS e certificado de treinamento.
- **FR-006**: Todo documento MUST registrar número, data de emissão, data de
  validade quando houver, o sistema emissor quando aplicável (nacional ou
  estadual), e quem o anexou.
- **FR-007**: A substituição de um arquivo já anexado MUST criar uma nova
  versão; o arquivo anterior MUST permanecer recuperável e auditável.
- **FR-008**: O sistema MUST NOT permitir exclusão definitiva de documento de
  conformidade dentro do prazo de retenção de 5 anos — exclusão marca, não
  remove.

**Pendências e prazos**

- **FR-009**: O sistema MUST apresentar a lista de coletas sem CDF, com a idade
  da pendência em dias.
- **FR-010**: O sistema MUST manter o calendário de obrigações periódicas com
  as janelas fixas da DMR trimestral, e MUST derivar alertas de vencimento a
  partir das datas de validade de licenças, contratos, PGRSS e treinamentos.
- **FR-011**: O sistema MUST permitir marcar uma obrigação como cumprida
  mediante anexo do comprovante, e MUST manter o histórico por período.
- **FR-012**: A antecedência dos alertas MUST ser configurável pela clínica,
  com padrão de 30 dias.

**Dossiê**

- **FR-013**: O sistema MUST gerar, para um período escolhido, um dossiê único
  contendo os documentos vigentes e emitidos no período, com índice.
- **FR-014**: O dossiê MUST declarar explicitamente as lacunas encontradas
  (coleta sem MTR, coleta sem CDF, obrigação não cumprida) em vez de omiti-las.

**Custo**

- **FR-015**: O sistema MUST permitir vincular o contrato de coleta a uma
  despesa recorrente em Contas a Pagar, respeitando a regra já fechada de
  materialização de despesa fixa (D-13 / V-26).
- **FR-016**: O sistema MUST apresentar o custo do período e o custo por
  unidade de quantidade coletada.

**Acesso, isolamento e auditoria**

- **FR-017**: O módulo MUST ser governado por uma ModuleKey própria,
  `residuos`, usada identicamente por plano, permissão individual, rota e
  menu — e MUST obedecer à cascata de resolução de acesso vigente, com fallback
  `none`.
- **FR-018**: Toda tabela do módulo MUST ter `clinic_id` e RLS habilitada;
  nenhum dado de uma clínica pode ser alcançável por outra, nem por RPC nem por
  URL direta.
- **FR-019**: Os arquivos anexados MUST ser armazenados com isolamento por
  clínica verificado no banco, e MUST NOT ser acessíveis por URL pública sem
  autenticação.
- **FR-020**: Toda criação, alteração, substituição e exclusão lógica de
  documento de conformidade MUST gerar registro de auditoria com autor, momento
  e diff `old→new`.

**Honestidade regulatória**

- **FR-021**: Nenhuma tela, texto de marketing ou relatório do módulo MUST
  afirmar que o uso do NexClin torna a clínica conforme, ou que elimina o risco
  de multa. O produto organiza a prova; a responsabilidade legal é da clínica.
- **FR-022**: O módulo MUST registrar em que sistema (nacional ou estadual)
  cada manifesto foi emitido, porque a exigência varia por estado e o dossiê
  precisa refletir a realidade de cada unidade.

### Key Entities

- **Coletor**: a empresa contratada. CNPJ, licença ambiental com validade,
  contrato vigente, status ativo/inativo.
- **Coleta**: o evento. Data prevista, data realizada, coletor, unidade,
  quantidades por grupo, situação (prevista, realizada, cancelada).
- **Grupo de resíduo**: catálogo por clínica, derivado da classificação
  oficial, com marcação de "a clínica gera / não gera".
- **Documento de conformidade**: MTR, CDF, DMR, contrato, licença, PGRSS,
  certificado de treinamento. Tipo, número, emissão, validade, sistema emissor,
  arquivo, versão, vínculo opcional com uma coleta.
- **Obrigação periódica**: a instância datada de um dever recorrente (a DMR de
  um trimestre, o treinamento de um ano). Período, janela de entrega, situação,
  comprovante.
- **Contrato de coleta**: valor, periodicidade, dia de vencimento, vínculo com
  a despesa recorrente em Contas a Pagar.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A recepcionista registra uma coleta completa, com anexo do MTR,
  em menos de 90 segundos, sem treinamento prévio além de uma leitura da tela.
- **SC-002**: Em uma clínica com 6 meses de histórico, o dossiê de fiscalização
  é gerado em menos de 30 segundos e nenhum documento anexado no período fica
  de fora.
- **SC-003**: 100% das coletas sem CDF há mais de 30 dias aparecem na lista de
  pendências — nenhuma pendência silenciosa.
- **SC-004**: Nenhuma DMR passa despercebida: em toda janela trimestral, o
  alerta aparece no primeiro dia da janela e não some até ser marcado como
  cumprido ou o prazo encerrar.
- **SC-005**: A clínica responde "quanto custou minha gestão de resíduos no
  trimestre" em um clique — número que ela hoje não tem.
- **SC-006**: Zero acesso cruzado entre clínicas em teste de isolamento
  executado por Arthur, incluindo tentativa por URL direta de arquivo anexado.
- **SC-007**: Na conversa comercial, o módulo é apresentável sem usar a palavra
  "multa" e ainda assim o gestor entende o valor — é o teste do argumento que o
  Vinícius derrubou.

---

## Assumptions

- **O público é o gerador, não o coletor.** O módulo serve à clínica que gera o
  resíduo. Não há intenção de atender a empresa de coleta como cliente.
- **A emissão do MTR continua acontecendo no portal do órgão.** Na V1 a clínica
  emite o manifesto onde já emite hoje (SINIR nacional, SIGOR/CETESB em SP,
  INEA no RJ, e assim por diante) e **registra o número + anexa o PDF** no
  NexClin. Integração automática por web service existe — SP e RJ publicam
  manuais de integração — mas são sistemas diferentes por estado, com
  credencial própria e homologação própria. Integrar 27 sistemas para uma base
  concentrada em poucos estados é inversão de prioridade. **Integração é spec
  posterior, começando por SP**, e só depois que a base justificar.
- **O PGRSS não é redigido pelo sistema.** O PGRSS é documento técnico,
  assinado por responsável habilitado. O NexClin guarda a versão vigente,
  controla a data de revisão e o inclui no dossiê. Redigir plano de
  gerenciamento é serviço de consultoria, não software.
- **A quantidade gerada é declarada, não medida.** A clínica informa peso ou
  volume por coleta, como consta no manifesto. Estimar geração por procedimento
  realizado é sofisticação sem demanda — fica fora.
- **Construir não custa crédito.** Correção do Arthur em 25/08, e ela desfaz
  uma afirmação errada da primeira versão desta spec. Desde a ponte inversa, o
  trabalho é commit no repositório e publicação; não se compra crédito da
  Lovable para construir. Some-se a §2.4: **o banco migra intacto**, e a
  estrutura, o dado e a regra de negócio são os mesmos nas duas stacks. O que
  se refaz na virada de outubro é a camada de tela, a hospedagem e o apontamento
  do banco. Portanto **construir este módulo não é trabalho jogado fora** — e a
  pergunta legítima é de **ordem**, não de custo.
- **A ordem decidida em 25/08 é: módulos financeiros primeiro, este depois.**
  Não por preço, mas por dependência: o User Story 4 precisa de
  `contas_pagar`, e o financeiro é o diferencial que sustenta a venda hoje.
  Fechados os financeiros, esta spec vai para `/speckit-plan` sem espera.
- **Este módulo não é do lançamento de 08/09.** A spec existe agora para que a
  decisão comercial seja tomada com o escopo real na mesa, e não com o escopo
  do vídeo.

---

## Dependências e dívidas que este módulo cobra

Registradas porque são pré-requisitos reais, não avisos genéricos:

1. **`storage.objects` sem filtro por `bucket_id`** — a migração de segurança
   aplicada em 20/08 restringiu SELECT/INSERT/UPDATE/DELETE a
   `is_superadmin(auth.uid())`, e **não filtra por bucket**. Hoje isso não
   incomoda porque só existe o bucket de export. **Este é o primeiro módulo com
   upload de arquivo pela clínica** — e, do jeito que está, o upload falharia
   sem explicação, ou só o superadmin leria os documentos. A dívida está
   registrada em `docs/planejamento/handoffs/2026-08-20-fim-do-dia.md` §2.5(b) e
   vira **bloqueio** aqui.
2. **Emenda à constituição (Princípio III)** — `residuos` seria a **16ª
   ModuleKey**. O contrato hoje declara 15 strings exatas, o trigger de
   validação de `enabled_modules` valida contra elas, e a constituição exige
   emenda para qualquer módulo novo. Isso é gate de aprovação humana, não
   detalhe de implementação: sem a emenda (v1.0.0 → v1.1.0), o módulo não
   nasce.
3. **Auditoria dentro da clínica** — hoje só ação de superadmin é auditada. O
   FR-020 depende da Fase 2 da SPEC 002 (`data_audit_log` + trigger), já
   especificada e pendente.
4. **`contas_pagar` (Onda 2)** — pré-requisito do User Story 4, junto com a
   regra de materialização de despesa fixa fechada na D-13 / V-26.
5. **Retenção LGPD** — a política de retenção/expurgo, hoje no backlog, precisa
   conhecer o piso de 5 anos deste módulo antes de existir, ou vai apagar o que
   a lei manda guardar.

---

## Decisões pendentes — não são de engenharia

Ficam registradas aqui porque a spec não avança de fase sem elas, e nenhuma é
decisão de quem escreve código:

- **D-R1 — Em qual plano o módulo entra, e o que mais entra junto.** Não vender
  avulso: entra como diferencial de plano superior. Mas a pesquisa de
  precificação (`NexClin - Pesquisa de Mercado e Precificacao.html`, §10.2)
  impõe uma correção de expectativa que precisa estar escrita aqui:

  - o teto de preço hoje é de cerca de **R$ 700 na faixa de 8 usuários**; acima
    disso a clínica compara com Feegow VIP, que tem TISS, glosa e IA;
  - o que derruba esse teto **não é a ausência de resíduos**. A pesquisa
    classifica **prescrição digital assinada** como "derruba o teto e é a
    lacuna mais urgente" (o iClinic a entrega no plano de R$ 99) e **prontuário
    certificado** como "maior limitador de preço";
  - a mesma seção já previu o mecanismo: no lançamento diferencia-se só por
    faixa de usuários, e **depois do lançamento as funções novas entram como
    plano superior**, criando o próximo degrau sem mexer no que já foi vendido.

  Conclusão para esta spec: **resíduos é um degrau legítimo, não o degrau.** Um
  plano superior sustentado só por contagem de usuário é frágil pelo motivo que
  a §10.2 já registra (9 dos 10 concorrentes cobram por profissional de saúde e
  dão secretária de graça). A fila por valor de mercado é prescrição digital,
  prontuário, TISS, e resíduos junto deles.

- **D-R2 — RESOLVIDA em 25/08.** Não há divulgação a fazer: os fundadores não
  conhecem o escopo do produto em detalhe, e a prospecção ampla é trabalho
  posterior ao lançamento. Constrói-se primeiro.

- **D-R3 — RESOLVIDA em 25/08.** Ordem definida pelo Arthur: **módulos
  financeiros primeiro; resíduos imediatamente depois.** Não é adiamento por
  desinteresse, é dependência — o User Story 4 precisa de `contas_pagar`.

---

## Fontes

Fatos regulatórios usados nesta spec, para conferência:

- Classificação de resíduos e obrigatoriedade do PGRSS: RDC ANVISA nº 222/2018.
- MTR como obrigação do **gerador**, emitido a cada coleta, no SINIR ou no
  sistema estadual equivalente.
- DMR trimestral com janelas fixas (abril, julho, outubro, janeiro), conforme
  Portaria MMA nº 280/2020; DMR pendente bloqueia novas declarações no sistema.
- CDF emitido pelo destinador, fechando a rastreabilidade da cadeia.
- Guarda mínima de 5 anos dos documentos referenciados no PGRSS.
- Web services de integração publicados por CETESB (SIGOR-MTR, manual de
  integração v1.15) e INEA (RJ) — base da decisão de adiar a integração.

> Levantamento por pesquisa, não parecer jurídico. Antes de qualquer afirmação
> regulatória em material de venda, revisar com advogado — é a mesma cautela
> que o OpenClinic adota no seu `compliance.md`, e ela existe porque errar aqui
> custa credibilidade.
