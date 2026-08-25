# OpenClinic — o que é, o que serve para o NexClin, e o que não encostar

> Análise do repositório `github.com/Iniciativa-OpenClinic/OpenClinic`, pedida
> pelo Arthur em 25/08/2026 depois de o Erick lembrar do projeto num grupo de
> mentoria. Repositório inteiro lido (clone completo, 22 arquivos, ~250 KB de
> documentação). Feito em 25/08/2026.

---

## 1. O que o repositório é de fato

Antes de qualquer opinião, os números conferidos direto na API do GitHub, para
que a decisão seja tomada sobre o projeto real e não sobre a versão dele que
circula em grupo de mentoria:

| Fato | Valor conferido |
|---|---|
| Criado em | **11/08/2026** — tem 14 dias |
| Último push | 22/08/2026 |
| Estrelas / forks | **13 / 6** |
| Contribuidores no git | **3** — `mdiaoficial` (Dr. Daniel Dorta, CRM 174209), `claude` (bot), `luizsergio214` |
| Linhas de código | **zero** |
| Licença | **AGPL-3.0** |
| Status declarado | pré-alfa, com aviso explícito de "não use em atendimento a pacientes" |

**A informação de "cerca de quarenta desenvolvedores voluntários" não bate com
o repositório.** Quarenta é, muito provavelmente, o tamanho do **grupo de
WhatsApp** — que é onde eles próprios dizem que a conversa acontece. No git,
quem escreveu foi uma pessoa, um bot e um colaborador com dois commits. Isso
não desqualifica o projeto; muda o que se pode esperar dele nos próximos meses.

**Não existe software.** O que existe é uma fundação documental — e ela é boa.
O roadmap deles está na **Fase 2 de 5**: decidir a stack. A decisão da
linguagem do backend estava marcada para **26/08/2026** — amanhã. O MVP é a
Fase 4, sem data.

**Conclusão de leitura:** o OpenClinic não é um concorrente, não é um
fornecedor e não é, hoje, uma peça de software que se possa usar. É um
**documento de referência bem escrito** sobre o domínio que o NexClin ainda não
entrou — o prontuário — e é isso que o torna útil agora.

---

## 2. O alerta que vem antes de qualquer aproveitamento: a licença

**AGPL-3.0.** É a licença copyleft mais forte que existe para software de rede,
e ela foi escolhida por eles **de propósito**, com a intenção declarada de
impedir que alguém feche o que nasceu aberto.

O que ela significa para nós, em uma frase:

> Se qualquer trecho de código do OpenClinic entrar no NexClin, o NexClin —
> que é oferecido pela rede como SaaS — passa a ter de **publicar todo o
> código-fonte** da versão que serve os clientes.

Não há atalho, não há "só um pedacinho", e não adianta ser código de servidor
que ninguém vê: **o "A" de AGPL existe justamente para fechar essa brecha.**

Como ainda não há código lá, o risco imediato não é de código — **é de texto**.
Documentação também é obra protegida, e o repositório inteiro está sob a mesma
licença. Copiar a matriz SBIS deles para dentro do NexClin, ou colar parágrafos
do `compliance.md`, é o mesmo problema com outra roupa.

**A regra prática para esta casa, e ela é simples:**

- **Ler, aprender e citar — sempre.** Fato regulatório não é propriedade de
  ninguém: a RDC 222/2018 é pública, a lista de requisitos da SBIS é da SBIS.
- **Refazer com as nossas palavras, a partir da fonte primária.** Quando um
  documento do OpenClinic apontar uma norma, vamos à norma.
- **Nunca copiar e colar** — nem código, nem tabela, nem parágrafo.
- Dar crédito quando a ideia veio de lá. É honesto e é barato.

Detalhe que vale registrar porque eles mesmos registram: a matriz SBIS do
repositório é **paráfrase própria deles**; o texto oficial dos requisitos é
**© SBIS** e não está transcrito lá. Se formos usar a certificação como régua,
compramos os documentos oficiais.

*Isto é leitura de licença, não parecer jurídico. Antes de qualquer decisão com
peso legal — em especial a de integração comercial da §6 — passar por advogado.*

---

## 3. O que vale trazer para o NexClin (cinco coisas concretas)

### 3.1 A matriz de rastreabilidade da certificação — o item mais valioso

Eles mapearam **256 requisitos** da certificação SBIS S-RES v5.2 aplicáveis à
categoria Clínica/Ambulatório, divididos em ECF (funcionais, 133), NGS1
(segurança, 88) e NGS2 (assinatura digital, 35), cada um com estágio, módulo
responsável e situação.

Por que isso importa aqui: a certificação **SBIS-CFM já está declarada no
roadmap do NexClin** (`CLAUDE.md` §1, "futuro do roadmap"). O bloco **NGS1 é
segurança pura** — e é exatamente o terreno onde o NexClin já investiu pesado.
Lendo a lista deles contra o que temos, o retrato é este:

**Onde o NexClin já está forte** — e provavelmente à frente de um projeto que
ainda não escreveu código:

- `NGS1.06.04` isolamento entre organizações → é o nosso RLS multi-tenant com
  trigger de âncora imutável.
- `NGS1.07.01/02/05` trilha contínua, imutável, com autor e momento → é o
  `superadmin_audit_log`.
- `NGS1.02.02` senha como hash irreversível, `NGS1.02.19` SALT por senha →
  Supabase Auth.
- `NGS1.05.02` todo processamento e validação no servidor → é literalmente o
  Princípio I da nossa constituição, dito com outras palavras.
- `NGS1.09.03/06` data e hora com fuso → é o que a correção V-17/V-28B tratou.

**Onde a lista deles aponta buraco no nosso** — e este é o valor real do
exercício:

| Requisito | O que exige | Situação no NexClin |
|---|---|---|
| `NGS1.03.11` | Ninguém altera as próprias permissões | **Falha confirmada por leitura de migração.** A policy de `team_members` é `FOR ALL` checando só `clinic_id` — qualquer membro altera o próprio `permission_level`, `permissions` e `repasse_percent`. Detalhe e limites em [`docs/seguranca/autoconcessao-team-members-2026-08-25.md`](../seguranca/autoconcessao-team-members-2026-08-25.md). |
| `NGS1.03.06` | Perfil de TI **sem** acesso a dado clínico real | **Conflito conhecido.** Nossa impersonação dá escrita total dentro da conta — é auditada, mas é acesso a dado clínico por operador de SaaS. |
| `NGS1.02.13` | Bloqueio após N tentativas de login | Não implementado. |
| `NGS1.02.20` | Bloqueio de sessão por inatividade, tempo configurável | Não implementado. |
| `NGS1.02.03` | Senha mínima de 8 caracteres com letras e números | Não verificado. |
| `NGS1.11.01` | Aceite de termo de uso no primeiro acesso e a cada mudança | Não existe. |
| `NGS1.03.09` | Usuário que já operou o sistema **nunca é removido** | Contradiz o "excluir team_member" da fila da spec 005. |
| `NGS1.12.03` | Inativação de registro clínico com justificativa, permanecendo visível | Anamnese não tem isso. |
| `NGS1.07.06` | Trilha **sem** dado clínico e **sem** identificar paciente | Não verificado nas nossas trilhas. |
| `NGS1.04.03` | Backup cifrado | Depende do Supabase Pro — ainda não ligado. |

Uma tensão que merece registro próprio: **`NGS1.02.06` exige que o
administrador possa gerar a senha inicial do usuário, com troca obrigatória no
primeiro acesso.** Nossa regra (e) proíbe qualquer admin definir senha de
terceiro, e o T017 acabou de remover esse caminho da plataforma. Não é
contradição de fato — o convite por link cumpre o mesmo propósito com
segurança maior —, mas **é divergência com a régua da certificação**, e um dia
um auditor vai perguntar. Fica anotado agora, e não daqui a um ano.

**Encaminhamento:** montar `docs/seguranca/regua-ngs1.md` — nossa própria
matriz, escrita do zero a partir dos documentos oficiais da SBIS, com uma
coluna "situação no NexClin". Não é trabalho de agora; é trabalho de antes de
falar em certificação com qualquer cliente.

### 3.2 O disclaimer regulatório — para copiar a postura, não o texto

O `compliance.md` deles abre com duas frases que valem mais que o documento:

> Este documento não é parecer jurídico. · **Usar o sistema não torna uma
> clínica conforme à LGPD** — a clínica continua responsável legal pelos dados.

E cada seção separa **quem é o obrigado por lei** de **o que o software precisa
suportar** para ajudar o obrigado a cumprir.

Isso é diretamente aplicável ao NexClin — e já foi aplicado: virou o **FR-021
da SPEC 013**. É também o antídoto contra o discurso do vídeo de resíduos
("zero risco de multa"), que é a promessa que nenhum software pode cumprir.

### 3.3 ADR numerado, com as alternativas descartadas e por quê

Eles mantêm `docs/decisions/NNNN-titulo.md`, uma decisão por arquivo, com
contexto, consequências assumidas e — obrigatoriamente — **o que foi descartado
e o motivo**. Três regras de governança acompanham, e as três são boas:
argumento é assinado; tese vencida não é apagada; **decisão não se fecha com
gente ausente**.

O NexClin tem hoje decisões espalhadas em quatro lugares: `D-1` a `D-13` dentro
da triagem, `BACKLOG.md`, os handoffs e o `CLAUDE.md`. Funciona, mas já
produziu retrabalho — a §2.5 do `CLAUDE.md` teve de ser escrita porque o
critério anterior não estava registrado em lugar nenhum com data.

**Encaminhamento barato:** criar `docs/decisions/` e migrar para lá as decisões
que já foram tomadas e são caras de reverter (§2.5, a régua "dado atravessa /
cálculo de tela não", D-12, D-13, a escolha de stack). Não precisa ser hoje.

### 3.4 Requisitos não-funcionais que moldam o modelo de dados

O `prd.md` deles lista, como capacidade e não como feature: trilha imutável,
controle de acesso granular por domínio (financeiro / administrativo /
clínico), isolamento entre organizações **como requisito separado do controle
de acesso**, soft delete universal, **proveniência do dado** ("não é log de
aplicação: log serve para diagnosticar erro, proveniência precisa ser
consultável por quem audita"), assinatura digital, portabilidade e retenção de
20 anos.

Convergência com o que já estamos fazendo: o `deleted_at` e o `data_audit_log`
da **Fase 2 da SPEC 002** são exatamente soft delete + proveniência. Bom sinal
— chegamos ao mesmo lugar por caminho independente.

Divergência que merece atenção: **"acesso a prontuário é, por padrão, restrito
a profissional de saúde; conceder a outro perfil é decisão explícita e
registrada."** No NexClin, admin da clínica é `full` em tudo, inclusive
`anamnese`. Para gestão pura isso é razoável. No dia em que houver prontuário,
deixa de ser.

### 3.5 A arquitetura em camadas, e a lição de negócio escondida nela

Eles organizam a V1 em quatro camadas — transversal (identidade, auditoria,
terminologias) → estrutura (organização, pessoas, catálogo, convênios) →
operação (agenda, prontuário) → apoio (estoque, financeiro) — com a regra de
que **cada camada só depende das de baixo**. É o mesmo raciocínio da nossa
`fila-especificacoes.md`, que ordena por dependência de dado. Convergência,
não novidade.

A lição que **não** é arquitetura está no `prd.md` deles, sobre a agenda:

> Vende-se o prontuário para o médico, mas quem opera o sistema o dia inteiro é
> a equipe de recepção — a qualidade do agendamento decide a adoção do produto
> na prática.

É a **mesma descoberta** que tivemos em 20/08 com o Vinícius, quando ele disse
que o time dele não usa o dashboard e puxa tudo por relatório. Dois projetos
independentes esbarrando na mesma regra: *pergunte por onde o cliente realmente
opera, não por onde você imagina que ele opera.* Vale promover isso a princípio
do NexClin, e não deixar como anedota de uma sessão.

---

## 4. O que **não** trazer

- **HL7 FHIR como forma de pensar o banco.** É a decisão fundadora deles, e
  eles próprios descrevem o custo: o descasamento entre os *bundles*
  desnormalizados do FHIR e a normalização relacional "reaparece a cada recurso
  novo" e **não está resolvido**. Para um produto de **gestão**, esse custo não
  se paga. FHIR entra no NexClin no dia — e só no dia — em que houver prontuário
  e necessidade real de RNDS.
- **AGPL, em qualquer dose.** Ver §2.
- **"API antes de interface".** Faz todo sentido para um projeto que quer virar
  padrão de interoperabilidade. Não faz nenhum para quem tem cliente fundador
  esperando tela em 08/09.
- **O núcleo neutro sem IA — mas com uma ressalva séria.** Eles proíbem IA e
  apoio à decisão no núcleo **de propósito**, para não cair no enquadramento de
  Software como Dispositivo Médico da ANVISA (RDC 751/2022 e 657/2022). O
  NexClin faz o oposto: IA proativa é o diferencial declarado. **Provavelmente
  estamos seguros**, porque nossos `insights` são de gestão — marketing,
  comercial, operação, financeiro — e não tocam conduta clínica. Mas a
  fronteira é real e fina: **no dia em que um insight sugerir conduta clínica,
  o regime muda.** O documento deles registra ainda que a Resolução CFM
  nº 2.454/2026, sobre uso de IA na medicina, entra em vigor em **26/08/2026** —
  amanhã. Vale conferir na fonte antes de qualquer material de venda que fale
  de IA.

---

## 5. O ponto cego que a leitura revelou no nosso produto

O `modulos.md` deles tem um módulo de **Estoque** ligado ao Prontuário: o
procedimento realizado **baixa o kit automaticamente**, atualiza a posição de
estoque e alerta no mínimo. E um **plano terapêutico** que gera orçamento, que
gera pacote com saldo de sessões, que gera a fila de marcação na agenda.

O NexClin tem orçamento, fechamento e recebível — mas **não tem estoque e não
tem pacote com saldo de sessões**. Para clínica de estética e odontologia (dois
dos nossos quatro verticais), pacote de sessões é o modelo de venda dominante,
e consumo de material é custo direto que hoje ninguém consegue medir.

Isso não é urgente, não é do lançamento, e não veio da bateria de ninguém —
mas é candidato mais forte a "funcionalidade que faz cobrar mais" do que o
módulo de resíduos, e **por um caminho que o cliente já sente na pele**.
Registrado aqui para não se perder.

---

## 6. O que fazer com a relação — recomendação

Os dois projetos não competem. O OpenClinic quer ser **prontuário aberto e
interoperável** e não tem nada de gestão financeira, funil comercial ou
repasse. O NexClin é **gestão** e não tem prontuário — que está no nosso próprio
roadmap.

Três posturas possíveis, da mais barata à mais cara:

**(a) Observar — recomendado agora.** Custo zero. Acompanhar `docs/decisions/`
e o roadmap deles. O que produzirem de mapeamento regulatório é insumo gratuito
para a nossa régua de certificação.

**(b) Participar como quem opera.** O `CONTRIBUTING.md` deles pede
explicitamente "quem já operou um prontuário na prática e sabe onde dói" — que
é a descrição do Vinícius. Custo: tempo. Retorno: rede de contato em saúde
digital e presença num projeto que pode virar referência. **Recomendação:
depois do lançamento**, não antes. Nada disso vale mais que a entrega de 08/09.

**(c) Integrar um dia, via a API aberta deles.** É a possibilidade
estrategicamente interessante: o NexClin cuidaria da gestão e conversaria com
uma instância OpenClinic que **o próprio cliente hospeda**, para a parte de
prontuário. Consumir a API de uma instância separada é caso diferente de
incorporar código — mas **essa distinção é exatamente o tipo de coisa que se
confirma com advogado antes de virar plano**, não depois. Só faz sentido
quando eles tiverem software, o que não acontece este ano.

**Uma cautela sobre expectativa:** um projeto de 14 dias, com três
contribuidores no git e a decisão de linguagem ainda em aberto, tem alta
probabilidade de nunca chegar à Fase 4. A documentação deles é excelente e vale
ler **hoje**; o software deles não deve entrar em nenhum plano nosso com data.

---

## 7. Encaminhamentos que saem daqui

| # | O quê | Quando | Dono |
|---|---|---|---|
| OC-1 | Regra da casa: nada do OpenClinic é copiado — nem código, nem texto. Ler, refazer da fonte, citar. | **Já vale** | todos |
| OC-2 | `docs/seguranca/regua-ngs1.md` — nossa matriz NGS1 escrita do zero, com coluna de situação | antes de falar em certificação com cliente | Claude |
| OC-3 | Corrigir a autoconcessão de permissão em `team_members` (faixa A, **não** na semana do lançamento) | spec 005 / SPEC 002 | Claude |
| OC-3b | Verificar os outros buracos da tabela da §3.1 (`.02.13` tentativas, `.02.20` inatividade, `.02.03` senha, `.11.01` termo) | pós-lançamento | Claude + Arthur |
| OC-4 | `docs/decisions/` com as decisões caras já tomadas | quando houver folga | Claude |
| OC-5 | Registrar "estoque + pacote de sessões" como candidato a módulo, à frente de resíduos | agora | Claude |
| OC-6 | Conferir a Resolução CFM nº 2.454/2026 (IA na medicina) na fonte antes de material de venda que cite IA | antes do go-to-market | Erick |
| OC-7 | Decidir participação no projeto (postura **b**) | **depois de 08/09** | Arthur + Vinícius |
