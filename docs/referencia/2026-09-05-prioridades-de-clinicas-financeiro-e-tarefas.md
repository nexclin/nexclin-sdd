# O que clínicas priorizam em financeiro e tarefas, e o que reclamam que falta

**Data:** 05/09/2026
**Tipo:** documento de referência. Descreve o que existe no mercado e o que
usuários relatam. **Não recomenda nada para o NexClin**, e não decide nada.
**Escopo:** nove sistemas de gestão usados por clínicas médicas e odontológicas
no Brasil (iClinic, Feegow, Clinicorp, Ninsaúde, Doctoralia e Docplanner,
Amplimed, Shosp, Dr. Clin, Simples Dental), avaliações públicas de usuários,
material de gestão clínica, e literatura sobre inadimplência, glosa, repasse e
conciliação.

---

## 0. Método, e o limite de prova deste documento

**Leia esta seção antes de usar qualquer número daqui.**

A pesquisa tinha ordem de usar fonte primária, e de marcar cada afirmação como
nível 1 (página do fabricante ou avaliação lida na íntegra) ou nível 2 (citada
mas não aberta).

**Não há uma única afirmação de nível 1 neste documento.** O ambiente desta
sessão bloqueia por política de egresso praticamente todo domínio comercial
brasileiro. Foram testados e devolveram bloqueio: `iclinic.com.br`,
`ajuda.feegow.com`, `feegowclinic.com.br`, `clinicorp.com`,
`simplesdental.com`, `amplimed.com.br`, `shosp.com.br`, `drclin.com.br`,
`ninsaude.com`, `blog.apolo.app`, `reclameaqui.com.br`, `capterra.com`,
`capterra.com.br`, `getapp.com`, `g2.com`, `play.google.com`, `apps.apple.com`,
`gov.br`, `ans.gov.br` e `scielo.br`. Só `github.com` e
`raw.githubusercontent.com` responderam, e nenhum dos fabricantes deste mercado
publica contrato de produto em repositório aberto.

**O que sobrou, e como ler.** O conteúdo chegou por extrato de busca sobre as
páginas oficiais e sobre as páginas de reclamação. O índice de busca leu a
página, eu não. Então:

- **N2** significa: a URL citada é a fonte, o extrato veio dela, e é ali que a
  afirmação deve ser reconferida antes de virar decisão.
- Onde o extrato não dá a frase literal do usuário, este documento **não
  inventa aspas**. Escreve em terceira pessoa e diz que é paráfrase do extrato.
- Onde não cheguei a nada, está escrito que não cheguei.

Cada linha de afirmação termina com a fonte e o nível, no formato
`([nome](url), N2)`.

**A separação que dá valor a este documento.** As seções 1 a 6 misturam duas
coisas de peso muito diferente, e elas estão sempre rotuladas:

- **ALEGAÇÃO DE FABRICANTE:** o que a empresa diz que o produto faz, na página
  dela. Vale como mapa do que o mercado considera obrigatório ter. Não vale como
  prova de que funciona.
- **DOR RELATADA:** o que um usuário escreveu numa reclamação pública. Vale como
  prova de que aquilo quebrou para alguém. Não vale como estatística.
- **MATERIAL DE GESTÃO:** artigo de consultoria, contabilidade ou associação.
  Quase todo esse material é produzido por quem vende software ou serviço
  contábil, então é marketing com dado dentro. Os números estão marcados um a um.

---

## 1. Quadro-resumo: o que cada fabricante destaca

Só o que a própria página do fabricante ou a central de ajuda dele destaca.
Célula vazia significa **não encontrado nas buscas**, e não significa ausente do
produto.

| | Repasse ou comissão | Régua de cobrança | Conciliação bancária | Convênio e glosa | Tarefas |
|---|---|---|---|---|---|
| **iClinic** | Regras de repasse por profissional, com percentual geral e percentual específico por procedimento | Lembretes automáticos de pagamento por SMS, e-mail e WhatsApp | não encontrado | Faturamento citado, integração profunda apontada como limite por análise de terceiro | não encontrado como módulo |
| **Feegow** | Quatro modelos nomeados: executor, solicitante, venda e equipe participante. Regra geral e regras específicas. Consolidação que trava o valor | não encontrado | Sim, por arquivo OFX, em Financeiro, Automação, Conciliação bancária | XML por operadora, validação de campo obrigatório para evitar glosa | Sim, módulo próprio com prioridade, responsável, projeto, prazo, tempo estimado, solicitante, visibilidade |
| **Clinicorp** | Regra de comissão por dentista, ligada ao histórico de procedimentos | Sim, sequência automática por WhatsApp, SMS e e-mail, antes e depois do vencimento | Citada como conciliação automática | não encontrado | não encontrado como módulo. Fala em automatizar tarefas operacionais |
| **Ninsaúde** | Controle de comissões | não encontrado | Conciliação bancária citada no módulo financeiro | Faturamento TISS com geração de guia, status de envio e identificação de glosa | não encontrado |
| **Doctoralia e Docplanner** | Repasse aqui é o marketplace pagando o profissional, não a clínica pagando o médico | Pagamento antecipado da consulta | não encontrado | não encontrado. Comprou a Feegow para cobrir financeiro e convênio | não encontrado |
| **Amplimed** | Cálculo de repasse com percentual por profissional | não encontrado | não encontrado | Módulo TISS com XML em lote | não encontrado |
| **Shosp** | Repasse parametrizado por profissional, serviço, convênio e unidade | não encontrado | não encontrado | Faturamento TISS | não encontrado |
| **Dr. Clin** | **não alcançado.** As buscas por "Dr. Clin" caem em Doctor Clin (operadora de plano do RS) e em Sistema Clin, que são outras empresas | | | | |
| **Simples Dental** | Regra de comissão por dentista com três gatilhos, e desconto de material, laboratório e taxa de cartão | Lista de pacientes devedores, lembretes por WhatsApp | não encontrado | não encontrado | Lembretes de agenda, não gestão de tarefa de equipe |

Fontes das células, todas N2:
[iClinic, repasse](https://suporte.iclinic.com.br/pt-br/relatorio-de-repasse-para-profissionais-de-saude) ·
[iClinic, financeiro](https://iclinic.com.br/funcionalidades/gestao-financeira/) ·
[iClinic, inadimplência](https://blog.iclinic.com.br/reduza-inadimplencia-de-pacientes-com-tecnologia/) ·
[Feegow, regras de repasse](https://ajuda.feegow.com/support/solutions/articles/67000202643-11-configure-as-regras-de-repasse) ·
[Feegow, conciliação](https://ajuda.feegow.com/support/solutions/articles/67000729287-como-funciona-a-conciliac%C3%A3o-banc%C3%A1ria-) ·
[Feegow, tarefas](https://ajuda.feegow.com/support/solutions/articles/67000172165-tarefas) ·
[Clinicorp, régua](https://www.clinicorp.com/post/parceiros-regua-de-cobranca-felipe-bahls) ·
[Clinicorp, financeiro](https://www.clinicorp.com/post/qual-melhor-software-odontologico-controle-financeiro-clinica) ·
[Ninsaúde, financeiro](https://www.ninsaude.com/pt-br/gerenciamento-financeiro-software-clinica/) ·
[Doctoralia, pagamentos](https://pro.doctoralia.com.br/blog/clinicas/pagamento-online-de-consulta-vantagens-como-oferecer) ·
[Doctoralia compra Feegow](https://press.doctoralia.com.br/212904-doctoralia-anuncia-aquisicao-da-feegow) ·
[Amplimed, financeiro](https://www.amplimed.com.br/gestao-financeira/) ·
[Shosp, financeiro](https://www.shosp.com.br/funcionalidades/gerenciamento-financeiro) ·
[Shosp, repasse](https://www.shosp.com.br/blog/repasse-medico-de-forma-otimizada-em-sua-clinica) ·
[Simples Dental, comissão](https://ajuda.simplesdental.com/pt-BR/articles/651095-como-configurar-as-regras-de-comissao-de-cada-dentista).

**Leitura do quadro.** Repasse ou comissão aparece em oito dos nove sistemas
alcançados. Régua de cobrança aparece em três. Conciliação bancária aparece
em três, e só a Feegow nomeia o formato do arquivo. **Tarefas como módulo com
responsável e prazo aparece em um só, a Feegow.** Nenhum dos nove documenta
tarefa recorrente ou checklist reaplicável de equipe nas páginas alcançadas.

---

## 2. Repasse médico: onde está o atrito

Esta é a seção mais densa do documento, porque foi o item onde mais material
apareceu, tanto de fabricante quanto de reclamação.

### 2.1 Os eixos que os sistemas modelam

Cruzando as centrais de ajuda alcançadas, um repasse é definido por seis
decisões, e cada fabricante cobre um subconjunto diferente.

**1. Quem recebe.** A Feegow é a única alcançada que separa papéis nomeados:
executor, solicitante, vendedor e equipe participante. No modelo dela, se não
houver solicitante, o valor que iria para o solicitante fica com a empresa
([Feegow, casos de repasse](https://ajuda.feegow.com/support/solutions/articles/67000679860-quais-os-casos-de-repasse-e-o-que-ocasionam-),
N2, alegação de fabricante). O iClinic, o Shosp e a Amplimed descrevem repasse
para o profissional que atendeu, sem esse desdobramento
([iClinic](https://suporte.iclinic.com.br/pt-br/relatorio-de-repasse-para-profissionais-de-saude),
[Shosp](https://www.shosp.com.br/blog/repasse-medico-de-forma-otimizada-em-sua-clinica),
[Amplimed](https://www.amplimed.com.br/gestao-financeira/), N2).

**2. Sobre o quê incide.** A Feegow chama de base de cálculo, e a regra escolhe
entre valor total e subtotal
([Feegow, regras](https://ajuda.feegow.com/support/solutions/articles/67000202643-11-configure-as-regras-de-repasse),
N2). O Simples Dental subtrai o custo cadastrado do tratamento antes de aplicar
o percentual, e mantém um artigo dedicado só a explicar por que a comissão por
valor fixo não desconta esse custo
([Simples Dental, cálculo](https://ajuda.simplesdental.com/pt-BR/articles/5678040-como-e-feito-o-calculo-de-comissao-dos-profissionais),
[Simples Dental, valor fixo](https://ajuda.simplesdental.com/pt-BR/articles/7183466-por-que-a-comissao-por-valor-fixo-nao-desconta-o-custo-do-tratamento),
N2). **O fato de existir um artigo de ajuda só para isso é o indício mais
direto que encontrei de que a base de cálculo confunde o usuário na prática.**

**3. Percentual ou valor fixo.** Os dois formatos aparecem na Feegow, no
iClinic e no Simples Dental
([Feegow](https://ajuda.feegow.com/support/solutions/articles/67000202643-11-configure-as-regras-de-repasse),
[Simples Dental](https://ajuda.simplesdental.com/pt-BR/articles/651095-como-configurar-as-regras-de-comissao-de-cada-dentista),
N2).

**4. Regra geral contra regra específica.** A Feegow documenta uma regra geral
padrão da clínica, aplicada a tudo que não cai em regra específica, e regras
específicas por convênio, por profissional e por forma de pagamento
([Feegow](https://ajuda.feegow.com/support/solutions/articles/67000202643-11-configure-as-regras-de-repasse),
N2). O iClinic tem percentual geral e percentual específico por procedimento
([iClinic](https://suporte.iclinic.com.br/pt-br/relatorio-de-repasse-para-profissionais-de-saude),
N2). O Shosp cita níveis por profissional, serviço, convênio e unidade
([Shosp](https://www.shosp.com.br/blog/repasse-medico-de-forma-otimizada-em-sua-clinica),
N2).

**5. O gatilho, ou seja, quando o repasse nasce.** É a decisão mais consequente
e a que menos fabricante explicita. O Simples Dental é o único alcançado que
nomeia três gatilhos alternativos: débito recebido, tratamento finalizado, e
aprovação de orçamento
([Simples Dental](https://ajuda.simplesdental.com/pt-BR/articles/651095-como-configurar-as-regras-de-comissao-de-cada-dentista),
N2). Material de gestão trata isso como o ponto onde nasce a divergência,
porque a consulta acontece num dia e o pagamento em outro
([App Health, controle de repasse](https://www.apphealth.com.br/controle-de-repasse-medico),
N2, material de gestão).

**6. A consolidação, ou seja, quando o valor deixa de mudar.** A Feegow tem uma
tela de consolidação em Financeiro, Repasses, Consolidação, onde a linha verde
significa nota paga e a vermelha nota não paga. Após consolidar, **o repasse
fica inalterável**, e vira uma conta a pagar com centro de custo
([Feegow, consolidar](https://ajuda-franquia.feegow.com/support/solutions/articles/67000740488-como-consolidar-e-pagar-os-repasses),
N2, alegação de fabricante). Foi o único fabricante alcançado que documenta um
ponto de congelamento explícito.

### 2.2 A base de cálculo real, segundo material contábil

**MATERIAL DE GESTÃO.** Um texto de contabilidade para médicos afirma que o
valor bruto do atendimento raramente é a base real do repasse, e lista quatro
descontos que precisam ser acordados antes: taxa de cartão, tributo sobre
receita, material e insumo de alto custo, e atendimento glosado pelo convênio,
que precisa ser tratado à parte para não distorcer a conta
([ContaDr](https://www.contadr.com.br/repasse-medico-conheca-a-melhor-forma-de-pagar-profissionais-sem-riscos/),
N2). O mesmo material afirma que esses critérios precisam estar registrados e
acordados com cada profissional. **Não consegui abrir a página**, então trate
como paráfrase do extrato.

O Simples Dental é o único fabricante alcançado que documenta desconto de
material, laboratório e taxa de cartão dentro da regra de comissão
([Simples Dental, gestão e financeiro](https://www.simplesdental.com/gestao-e-financeiro),
N2, alegação de fabricante).

### 2.3 Estorno, cancelamento e inadimplência do paciente

**MATERIAL DE GESTÃO.** Um texto de consultoria trata o caso de comissão já
apurada quando o paciente cancela ou não paga, e afirma que sem cláusula
específica no contrato ou na política de remuneração assinada, a comissão é
devida, e o desconto não se sustenta
([Senior Gestão e Marketing](https://www.seniorgestaoemarketing.com.br/o-paciente-cancelou-o-pagamento-a-clinica-pode-descontar-a-comissao-do-vendedor),
N2). Outro texto afirma a regra operacional: atendimento cancelado ou não pago
não deve entrar no repasse como se tivesse sido recebido
([App Health](https://www.apphealth.com.br/controle-de-repasse-medico), N2).

**Nenhum dos nove fabricantes documenta, nas páginas alcançadas, o que acontece
com um repasse já consolidado quando o recebimento é estornado.** A Feegow tem
artigo sobre como corrigir ou cancelar um recebimento errado
([Feegow](https://ajuda.feegow.com/support/solutions/articles/67000723075-17-como-corrigir-cancelar-um-recebimento-errado-),
N2) e artigo sobre desconsolidar repasse com valor errado, mas não achei a
ligação entre os dois documentada.

### 2.4 DOR RELATADA sobre repasse

Cinco fontes distintas, todas em reclamação pública, todas N2, nenhuma aberta
na íntegra.

1. **Valor de repasse absurdamente fora de escala.** Extrato de reclamação
   relata um pagamento de paciente de R$ 308,00 repassado ao médico como
   R$ 38.000,00
   ([Reclame Aqui, Feegow](https://www.reclameaqui.com.br/feegow/nao-contrate-promessas-e-zero-assistencia-sistema-falho-em-relatorios_OshcSjw6S_ReZizc/),
   N2). Diferença de duas ordens de grandeza.
2. **Perda de controle dos repasses.** Extrato de reclamação relata perda de
   controle do caixa das empresas desde março de 2022 e perda de controle dos
   repasses médicos
   ([Reclame Aqui, Feegow](https://www.reclameaqui.com.br/feegow/sistema-sem-suporte-e-nenhum-controle-financeiro-das-empresas-de-contrato_SnZdfktOPe2epVrn/),
   N2).
3. **Repasse feito sobre valor errado por causa de relatório errado.** Extrato
   de reclamação relata erro em relatório de produção que durou mais de 20 dias
   duplicando guias, e repasses feitos sobre valores incorretos
   ([Reclame Aqui, Feegow](https://www.reclameaqui.com.br/feegow/erros-em-relatorios-de-producao-causam-prejuizo-a-clinica_dqE-ujiT-LJCcSQE/),
   N2). Aqui o repasse é vítima do relatório, não a causa.
4. **Falha nas comissões dos dentistas.** Extrato de reclamação cita falhas nas
   comissões dos dentistas e dificuldade para gerar relatórios configurados
   ([Reclame Aqui, Clinicorp](https://www.reclameaqui.com.br/clinicorp/sistema-apresenta-muitas-falhas_yecPSuMsR1ZdTd9Z/),
   N2).
5. **Repasse do marketplace que não chega.** Vários extratos relatam consultas
   pagas pela Doctoralia cujo valor não foi repassado ao profissional, com
   ausência de indicador na plataforma dizendo se a tentativa de repasse
   ocorreu, foi cancelada, ou deu qual erro
   ([Reclame Aqui, Doctoralia](https://www.reclameaqui.com.br/doctoralia/doctoralia-falha-na-informacao-de-repasse-de-pagamentos-online_CBbLEnKb9mpZ7AI_/),
   N2). **Atenção ao vocabulário:** aqui repasse é o marketplace pagando o
   profissional, não a clínica pagando o médico. É outro problema, mas a queixa
   de fundo é a mesma: **não dá para ver por que o valor não saiu.**

**A forma da dor, resumida.** Nas cinco, o usuário não reclama de falta de
funcionalidade de repasse. Reclama de **valor que não bate e de não conseguir
auditar de onde o número veio**. O próprio fabricante confirma o padrão ao
manter um artigo de ajuda cujo tema é repasse que não aparece, aparece sem
valor, aparece com valor incorreto, ou aparece duplicado
([Feegow, casos de repasse](https://ajuda.feegow.com/support/solutions/articles/67000679860-quais-os-casos-de-repasse-e-o-que-ocasionam-),
N2).

---

## 3. Convênio e glosa: quanto é dor de clínica pequena

### 3.1 O tamanho do problema, em número

**MATERIAL DE GESTÃO, com números de origens diferentes e que não conversam
entre si.** Registro os três, com a divergência à vista.

- Levantamento da Associação Nacional de Hospitais Privados com 85 instituições,
  entre janeiro e fevereiro de 2025, aponta glosa em 15,89% do faturamento
  ([iaflow, artigo](https://iaflow.cc/artigos/clinica-glosas-convenios-faturamento-ia-auditoria-2026.html),
  N2). É amostra de hospital privado, não de clínica pequena.
- Outro texto afirma taxa consolidada de glosa aceita em 1,96% da receita bruta
  de convênio em 2024 ([mesma fonte](https://iaflow.cc/artigos/clinica-glosas-convenios-faturamento-ia-auditoria-2026.html),
  N2). A diferença entre 15,89% e 1,96% é a diferença entre glosa inicial e
  glosa que sobrou depois do recurso, e a fonte não deixa isso explícito.
- Uma terceira estimativa fala em 5% a 15% da receita mensal de clínicas
  conveniadas ([Bionexo](https://bionexo.com/blog/glosas-hospitalares/), N2).

**Não consegui abrir nenhuma das três**, e não consegui chegar à cartilha de
glosa da ANS, que é a fonte reguladora e seria a única de nível 1 possível aqui
([ANS, cartilha de glosa](https://www.ans.gov.br/images/stories/Plano_de_saude_e_Operadoras/Area_do_prestador/contrato_entre_operadoras_e_prestadores/cartilha_glosa.pdf),
domínio bloqueado). **Trate os três números como não verificados.**

### 3.2 A natureza da glosa

**MATERIAL DE GESTÃO.** A maioria das glosas é descrita como técnica e não
clínica: não é que o procedimento não devia ter sido feito, é que a guia foi
preenchida errado, com código TUSS desatualizado, autorização prévia ausente ou
dado do beneficiário divergente
([Idomed](https://www.idomed.com.br/blog/saude/o-que-sao-glosas), N2).

Quatro indicadores são apontados como suficientes para acompanhar faturamento
de convênio: taxa de glosa inicial, taxa de glosa final depois dos recursos,
percentual recuperado em contestação, e prazo médio entre atendimento e
recebimento ([App Health](https://www.apphealth.com.br/indicadores-faturamento-tiss-tuss),
N2).

O prazo de contestação varia por contrato, com referência comum de 30 dias a
partir do retorno do lote, e a Resolução Normativa 503 de 2022 da ANS exigiria
que o contrato preveja as hipóteses de glosa e que o prazo de contestação do
prestador seja igual ao prazo de resposta da operadora
([TISS Manager](https://tissmanager.com.br/blog/recurso-de-glosa-tiss-modelo-pronto),
N2). **Não abri o texto da RN 503 e não confirmei essa leitura na fonte
normativa.** Fica registrado como afirmação de terceiro.

### 3.3 Quanto disso pesa numa clínica pequena

**Não encontrei fonte que responda isso diretamente.** O que encontrei foi
contexto lateral, e ele não fecha a pergunta:

- A Demografia Médica é citada dizendo que a maioria dos médicos atende os dois
  regimes, com cerca de 20% exclusivamente no setor privado
  ([Ministério da Saúde sobre a Demografia Médica 2025](https://www.gov.br/saude/pt-br/assuntos/noticias/2025/abril/usuarios-de-plano-de-saude-tem-mais-acesso-a-cirurgias-do-que-pacientes-do-sus-aponta-demografia-medica-2025),
  N2, domínio bloqueado, extrato de busca apenas).
- Material de fabricante afirma que para quem está começando o convênio tende a
  compensar, e para o profissional estabelecido o particular tende a compensar
  mais, sem número que sustente
  ([iClinic](https://iclinic.com.br/blog/particular-ou-convenio/), N2, alegação
  de fabricante).
- Terceirizar faturamento é apresentado como caminho comum, com a contrapartida
  explícita de perda de controle
  ([Validador TISS](https://www.validadortiss.com.br/terceirizacao-faturamento-medico/),
  N2).

**O que dá para afirmar com o material alcançado:** cinco dos nove fabricantes
oferecem TISS ou faturamento de convênio (Feegow, Ninsaúde, Amplimed, Shosp,
iClinic), e nenhum deles trata isso como diferencial de topo de página. É
funcionalidade de catálogo. **O que não dá para afirmar** é o corte por tamanho
de clínica, e nenhuma fonte alcançada oferece esse corte.

---

## 4. Conciliação bancária e OFX

### 4.1 Quem oferece

**ALEGAÇÃO DE FABRICANTE.** Só a Feegow, entre os nove, documenta o mecanismo
com nome de formato e caminho de menu: arquivo OFX, em Financeiro, Automação,
Conciliação bancária
([Feegow](https://ajuda.feegow.com/support/solutions/articles/67000729287-como-funciona-a-conciliac%C3%A3o-banc%C3%A1ria-),
N2). A Clinicorp cita conciliação automática na lista de funcionalidades
financeiras, sem detalhar formato
([Clinicorp](https://www.clinicorp.com/post/qual-melhor-software-odontologico-controle-financeiro-clinica),
N2). A Ninsaúde cita conciliação bancária no módulo financeiro, sem detalhar
([Ninsaúde](https://www.ninsaude.com/pt-br/gerenciamento-financeiro-software-clinica/),
N2). Nos outros seis, não encontrei.

O fluxo descrito é sempre o mesmo: baixar o extrato OFX no aplicativo do banco
e subir o arquivo no sistema, na conta que se quer conciliar
([OnDoctor](https://ondoctor.app/como-conciliacao-bancaria-otimiza-gestao-financeira/),
N2, alegação de fabricante).

### 4.2 Se o usuário pequeno usa de verdade

**Não encontrei nenhuma fonte que responda isso.** Procurei reclamação,
avaliação ou pesquisa sobre uso real de conciliação por consultório pequeno, e
o que voltou foi exclusivamente material promocional dizendo que conciliação é
indispensável, produzido por quem vende software de clínica ou serviço contábil
([Clínica nas Nuvens](https://clinicanasnuvens.com.br/blog/conciliacao-bancaria/),
[Contmed](https://www.contmed.com.br/conformidade/conciliacao-contabil-para-clinicas-medicas/),
N2). **Registro como pergunta não respondida**, e não como ausência de uso.

O único argumento de uso concreto que apareceu é indireto: sistema compatível
com OFX permite passar os dados à contabilidade sem retrabalho no fechamento do
mês ([OnDoctor](https://ondoctor.app/como-conciliacao-bancaria-otimiza-gestao-financeira/),
N2). Ou seja, quem consome a conciliação pode ser o contador, não a clínica.
**Isso é hipótese apoiada em uma fonte de marketing, não é achado.**

**Nenhuma reclamação pública sobre conciliação bancária apareceu nas buscas.**
Isso é compatível com duas explicações opostas, funciona bem ou quase ninguém
usa, e o material alcançado não separa as duas.

---

## 5. Régua de cobrança e inadimplência

### 5.1 Os números da inadimplência

**MATERIAL DE GESTÃO, números que não conversam entre si.**

- Média nacional de inadimplência em clínicas e consultórios odontológicos de
  6,7%, atribuída ao relatório anual do Grupo TOMAZ
  ([Codental](https://www.codental.com.br/blog/inadimplencia-na-odontologia-10-formas-de-blindar-seu-consultorio/),
  N2). **Não localizei o relatório original.**
- Perda de até 15% do faturamento na média de mercado, com clínicas organizadas
  abaixo de 2% ([mesma fonte](https://www.codental.com.br/blog/inadimplencia-na-odontologia-10-formas-de-blindar-seu-consultorio/),
  N2).
- Como parâmetro de gestão, inadimplência abaixo de 3% para particular seria
  controlada, e acima de 7% exigiria revisão da política de cobrança
  ([MBH Institute](https://mbhinstitute.com.br/up/gestao-de-clinica-medica-indicadores-financeiros/),
  N2).

Nenhum desses três foi verificado na fonte primária.

### 5.2 A forma da régua

**MATERIAL DE GESTÃO.** A régua é descrita como protocolo que define
antecipadamente qual mensagem sai, em qual canal, em qual momento do ciclo, e
com qual tom. Um ponto de partida citado: lembrete 3 dias antes do vencimento,
comunicação no dia, e mensagens aos 3, 7, 15 e 30 dias de atraso
([Zenvia](https://zenvia.com/blog/cobranca-whatsapp/), N2).

**ALEGAÇÃO DE FABRICANTE.** A Clinicorp descreve o sistema identificando
parcelas vencidas e disparando a régua por WhatsApp, SMS ou e-mail, com alertas
configuráveis antes e depois do vencimento, e afirma redução de inadimplência de
até 50%, e de 65% em média nos primeiros meses para quem usa o meio de pagamento
próprio deles ([Clinicorp](https://www.clinicorp.com/post/parceiros-regua-de-cobranca-felipe-bahls),
N2). **São números do vendedor sobre o próprio produto, sem metodologia
publicada na página.** O Simples Dental afirma redução de faltas de até 70% com
lembrete automático ([Simples Dental](https://www.simplesdental.com/blog/simples-dental/),
N2), que é outra métrica, falta e não inadimplência.

**Nenhuma dor relatada por usuário sobre régua de cobrança apareceu nas
buscas.** Não sei se é porque funciona, se é porque poucos usam, ou se é porque
minhas consultas não alcançaram.

---

## 6. Tarefas: a rotina de quem opera a clínica

### 6.1 O que os sistemas entregam

**ALEGAÇÃO DE FABRICANTE.** A Feegow é o único dos nove com módulo de tarefa
documentado com campo a campo: prioridade, responsáveis, projeto, data e hora de
prazo, tempo estimado, solicitantes, título, visibilidade pública ou privada, e
descrição ([Feegow, tarefas](https://ajuda.feegow.com/support/solutions/articles/67000172165-tarefas),
N2). **É um card de tarefa horizontal, não uma rotina de clínica.** Não achei
recorrência, template nem checklist reaplicável na documentação alcançada.

Os outros oito descrevem automação de mensagem e de lembrete ao paciente, não
gestão de pendência da equipe. O iClinic mantém artigo de blog sobre gestão de
tarefas na clínica, mas o texto trata de organização e não de uma
funcionalidade nomeada
([iClinic](https://blog.iclinic.com.br/gestao-de-tarefas/), N2). A Clinicorp
fala em automatizar tarefas operacionais, e os exemplos citados são estoque e
gestão de pagamento
([Clinicorp](https://www.clinicorp.com/post/tarefas-operacionais-odontologia), N2).

**Conclusão do levantamento: a rotina da secretária existe farta na literatura
de gestão e quase não existe como objeto dentro dos sistemas alcançados.**

### 6.2 A rotina descrita na literatura de gestão

**MATERIAL DE GESTÃO.** É o material mais consistente entre fontes diferentes,
e é o que descreve a semana real.

**Diário, na abertura.** Conferir se a agenda do dia está atualizada, verificar
mensagens, e-mails e recados deixados depois do fechamento anterior, abrir o
sistema e revisar notificações e pendências, checar status de confirmação e
reagendamento, e verificar caixa e troco quando há recebimento presencial
([Clínica Ágil](https://www.clinicaagil.com.br/site/checklist-clinica-fisioterapia/),
N2).

**Diário, no fechamento.** Verificar recebimentos do dia em dinheiro, Pix,
cartão e transferência, registrar os valores no sistema, atualizar status de
pagamento pendente e de inadimplência, separar comprovante, e fechar o caixa
([mesma fonte](https://www.clinicaagil.com.br/site/checklist-clinica-fisioterapia/), N2).

**Semanal, do lado da gestora.** Fluxo de caixa e ocupação da agenda primeiro,
porque respondem se a semana está dentro do esperado. Depois a taxa de
inadimplência, tratada como alerta quando sai do histórico. Depois ticket médio
e rentabilidade por procedimento, como tendência. A cadência sugerida é de 15
minutos na segunda-feira de manhã para revisar sete indicadores
([4Medic](https://4medic.com.br/gestao-de-clinicas/), N2).

**Mensal.** Fechamento com indicadores administrativos e financeiros, e reunião
com a equipe revisando os números do mês anterior
([Dicas para Clínicas](https://dicasparaclinicas.com.br/como-delegar-rotinas-administrativas-clinicas/),
N2). A mesma fonte registra a crítica ao fechamento mensal: quando o gestor
percebe no dia 30 que o faturamento ficou 20% abaixo do previsto, já não há o
que fazer naquele mês.

**A observação de forma que sai daí:** a rotina descrita é composta de itens que
se repetem em cadência fixa, com responsável implícito pelo papel (recepção,
gestora) e com janela de conclusão (abertura, fechamento, segunda de manhã).
Nenhum dos nove sistemas alcançados modela isso. O que eles modelam é card
avulso, no caso da Feegow, e mensagem automática ao paciente, no caso de todos
os outros.

### 6.3 DOR RELATADA sobre rotina e retrabalho

- Equipe de recepção digitando o mesmo dado em mais de um lugar porque agenda e
  financeiro não conversam
  ([ClinicWeb](https://clinicweb.com.br/blog/problemas-de-organizacao-em-clinicas-medicas),
  N2). **É blog de fabricante descrevendo a dor**, não é reclamação de usuário.
  Classifico como material de gestão, não como dor relatada.
- Reclamação genérica sobre software de gestão: páginas que não se
  interconectam e relatório sem inteligência
  ([Vitta](https://www.vitta.com.br/software-de-gestao-as-maiores-reclamacoes-de-profissionais/),
  N2). Mesma ressalva: é fabricante falando de concorrente.

**Não encontrei nenhuma reclamação pública de usuário sobre ausência de módulo
de tarefas.** Isso é um achado por si: a dor de tarefa aparece em quem escreve
sobre gestão, e não aparece em quem escreve reclamação. **Reclamação pública
tende a registrar o que quebrou, não o que nunca existiu**, então a ausência
aqui não é evidência de que a dor não exista.

---

## 7. Os indicadores que a clínica acompanha

**MATERIAL DE GESTÃO.** Duas listas independentes convergem em seis itens.

Lista de sete indicadores: ticket médio, taxa de ocupação, inadimplência, custo
por paciente, margem de contribuição, receita recorrente e fluxo de caixa
([MBH Institute](https://mbhinstitute.com.br/up/gestao-de-clinica-medica-indicadores-financeiros/),
N2). Parâmetros citados na mesma fonte: ocupação saudável entre 75% e 85%,
inadimplência particular abaixo de 3%. A mesma página afirma que clínicas que
monitoram indicadores de forma sistemática crescem 2,3 vezes mais rápido, **sem
citar o estudo de origem**, o que torna esse número inutilizável como prova.

Do lado das contas a pagar, o material descreve que todo custo precisa de data
de vencimento, valor, categoria, **recorrência** e responsável pela aprovação, e
que a separação entre fixo e variável serve para achar o ponto de equilíbrio
([ProDoctor](https://prodoctor.net/blog/fluxo-de-caixa-para-clinicas/), N2).
Centro de custo aparece como o corte que mostra quanto cada área ou
especialidade consome ([mesma fonte](https://prodoctor.net/blog/fluxo-de-caixa-para-clinicas/), N2).
Projeção de 90 dias é citada para antecipar vencimento de DAS, décimo terceiro e
renovação contratual ([mesma fonte](https://prodoctor.net/blog/fluxo-de-caixa-para-clinicas/), N2),
e a Clinicorp diz oferecer exatamente projeção de 90 dias
([Clinicorp](https://www.clinicorp.com/post/gestao-financeira-clinica-odontologica-clinicorp),
N2, alegação de fabricante).

---

## 8. DOR RELATADA: o catálogo do que quebrou, por fonte

Só reclamação pública de usuário. Todas N2, nenhuma aberta na íntegra, todas em
paráfrase do extrato de busca, sem aspas inventadas.

| # | O que o usuário relata | Fonte |
|---|---|---|
| 1 | Repasse de R$ 308,00 saiu como R$ 38.000,00 | [Feegow](https://www.reclameaqui.com.br/feegow/nao-contrate-promessas-e-zero-assistencia-sistema-falho-em-relatorios_OshcSjw6S_ReZizc/) |
| 2 | DRE não funciona e relatórios financeiros não funcionam, com chamados abertos desde novembro sem solução | [Feegow](https://www.reclameaqui.com.br/feegow/nao-contrate-promessas-e-zero-assistencia-sistema-falho-em-relatorios_OshcSjw6S_ReZizc/) |
| 3 | Erro em relatório de produção por mais de 20 dias, duplicando guias, obrigando a levantar dado manualmente | [Feegow](https://www.reclameaqui.com.br/feegow/erros-em-relatorios-de-producao-causam-prejuizo-a-clinica_dqE-ujiT-LJCcSQE/) |
| 4 | Perda de controle do caixa e dos repasses médicos desde março de 2022 | [Feegow](https://www.reclameaqui.com.br/feegow/sistema-sem-suporte-e-nenhum-controle-financeiro-das-empresas-de-contrato_SnZdfktOPe2epVrn/) |
| 5 | Pedido de treinamento e orientação para conseguir usar o módulo financeiro | [Feegow](https://www.reclameaqui.com.br/feegow/falta-de-treinamento-e-suporte-para-modulo-financeiro-do-sistema-feegow_ILcIfv3uDoxho7RS/) |
| 6 | Financeiro cheio de falhas, com necessidade de manter planilha paralela em Excel e conferir todos os lançamentos todos os dias | [Clinicorp](https://www.reclameaqui.com.br/clinicorp/sistema-financeiro-e-uma_SJg9y4i8Ik6mOg4n/) |
| 7 | Função Caixa desabilitada sem aviso prévio, sendo a ferramenta usada para acompanhar o recebimento diário | [Clinicorp](https://www.reclameaqui.com.br/clinicorp/clinicorp-falha-critica-na-funcionalidade-caixa-causa-desorganizacao-financeira-e-falta-de-suporte_xEZw7jxMVJQbytqT/) |
| 8 | Falhas nas comissões dos dentistas e dificuldade para gerar relatórios configurados | [Clinicorp](https://www.reclameaqui.com.br/clinicorp/sistema-apresenta-muitas-falhas_yecPSuMsR1ZdTd9Z/) |
| 9 | Lançamentos financeiros registrados às 19h46 e 19h47 de 31/01/2023, com a clínica fechada, sem autorização | [Clinicorp](https://www.reclameaqui.com.br/clinicorp/invasao-de-sistema-financeiro-da-clinica_KTEKIA4xV2iIQ54O/) |
| 10 | Consulta de crédito exibindo score próximo de 800 para paciente cujo score real era 300 | [Clinicorp](https://www.reclameaqui.com.br/empresa/clinicorp/lista-reclamacoes/) |
| 11 | Sistema não permite duas formas de pagamento numa mesma consulta, caso do paciente que paga parte no cartão e parte em dinheiro. Relatado desde a compra e reconhecido pelo atendimento como deficiência | [iClinic](https://www.reclameaqui.com.br/iclinic/iclinic-problemas-no-sistema-na-parte-de-gestao-nao-resolvidas_X_PqPyW-ZlEEyYsR/) |
| 12 | Não é possível selecionar acesso específico por item do sistema para cada usuário cadastrado | [iClinic](https://www.reclameaqui.com.br/iclinic/iclinic-problemas-no-sistema-na-parte-de-gestao-nao-resolvidas_X_PqPyW-ZlEEyYsR/) |
| 13 | Sistema sem acesso, prontuário em branco, travamento durante atendimento, com atraso de 30 a 40 minutos na agenda | [iClinic](https://www.reclameaqui.com.br/iclinic/sistema-nao-funciona_IFZwjYJDT4jnYHJF/) |
| 14 | Suporte com atendente diferente a cada chamada e sem histórico do problema | [iClinic](https://www.reclameaqui.com.br/iclinic/sistema-nao-funciona-teleconsulta-nao-funciona-sem-suporte_wm3ZiA3KfICMoGxg/) |
| 15 | Relatório do módulo financeiro sem informação básica como CPF, o que o torna inútil | [Amplimed](https://www.reclameaqui.com.br/amplimed/sistema-e-muito-ruim_kyYbbgDD12kybrGt/) |
| 16 | Sistema cai todo mês ou pelo menos duas vezes por mês, com registro que não salva e agenda que não carrega | [Amplimed](https://www.reclameaqui.com.br/amplimed/o-sistema-cai-todo-o-mes_Rcnqwt82yLlGttCv/) |
| 17 | Bloqueio por falta de pagamento com a conta em dia | [Amplimed](https://www.reclameaqui.com.br/amplimed/problema-nao-resolvido_D9rkCsTq_UXsUmFl/) e [Shosp](https://www.reclameaqui.com.br/empresa/shosp/lista-reclamacoes/) |
| 18 | Todos os profissionais do aplicativo com permissão financeira, apesar de a configuração do administrador limitar esse acesso a ele | [Simples Dental](https://www.reclameaqui.com.br/simples-dental/falha-gravissima-no-aplicativo-simples-dental-permissoes-financeiras-expostas-e-dificuldade-de-contato-com-suporte_XunotMxfOEBcRU95/) |
| 19 | Instabilidade recorrente descrita como rotina | [Simples Dental](https://www.reclameaqui.com.br/simples-dental/instabilidade-virou-rotina_FcBxgTwxa8Jh_Ude/) |
| 20 | Consulta paga pela plataforma sem repasse ao profissional três meses depois, e ausência de indicador dizendo se a tentativa de repasse ocorreu, foi cancelada, ou deu qual erro | [Doctoralia](https://www.reclameaqui.com.br/doctoralia/doctoralia-falha-na-informacao-de-repasse-de-pagamentos-online_CBbLEnKb9mpZ7AI_/) |
| 21 | Aplicativo fecha sozinho durante o uso, perdendo o trabalho em andamento, e não exibe informação básica do prontuário | [Clinicorp, App Store](https://apps.apple.com/br/app/clinicorp/id1213414194) |

**Índices públicos de reputação citados nos extratos, todos N2 e nenhum
verificado na página:** Feegow com nota 6,8 de 10 e 93 reclamações, resolvendo
80,8%; iClinic com 6,9 de 10 nos últimos 12 meses e 76,2% de resolução;
Doctoralia com 675 reclamações, 82,8% respondidas e nota 6,34 de 10; Simples
Dental com 9,6 de 10 e 18 reclamações. **Números de reputação mudam com o tempo
e servem só de ordem de grandeza.**

---

## 9. O que apareceu mais de uma vez

Contagem de **fontes distintas** que citaram cada dor. Fonte distinta significa
uma reclamação diferente, ou um artigo de origem diferente. Duas dores citadas
na mesma reclamação contam uma vez cada, para a reclamação. Todas N2.

| Dor | Fontes distintas | Quais |
|---|---|---|
| **Suporte que não resolve dentro da janela em que a clínica precisa** | **6** | Feegow (3 reclamações), Clinicorp (1), Amplimed (1), iClinic (1) |
| **Relatório financeiro que não fecha, obrigando conferência manual ou planilha paralela** | **5** | Feegow (relatório de produção), Feegow (DRE), Clinicorp (planilha em Excel), Clinicorp (relatório configurado), Amplimed (relatório sem CPF) |
| **Repasse ou comissão com valor errado, sem forma de auditar de onde veio o número** | **5** | Feegow (R$ 308 virou R$ 38 mil), Feegow (perda de controle), Feegow (repasse sobre valor errado), Clinicorp (comissão dos dentistas), Doctoralia (repasse sem indicador de erro) |
| **Instabilidade do sistema em horário de atendimento** | **4** | iClinic, Amplimed, Clinicorp, Simples Dental |
| **Permissão financeira que não obedece à configuração, ou que não existe com o recorte necessário** | **3** | Simples Dental (permissão exposta no app), iClinic (sem acesso por item), Clinicorp (lançamento fora do horário de funcionamento) |
| **Funcionalidade financeira retirada ou alterada sem aviso** | **2** | Clinicorp (Caixa desabilitada), Feegow (perda de acesso aos relatórios principais) |
| **Bloqueio de acesso por suposta inadimplência com a conta em dia** | **2** | Amplimed, Shosp |
| **Lançamento de recebimento que não cabe no modelo do sistema** | **1** | iClinic (duas formas de pagamento numa consulta) |
| **Ausência de módulo de tarefas** | **0** | Nenhuma reclamação pública encontrada |

**Do lado das alegações de fabricante**, o que se repete em mais de um site:
repasse ou comissão configurável (8 de 9), faturamento TISS (5 de 9), régua ou
lembrete de cobrança (3 de 9), conciliação bancária (3 de 9), tarefa de equipe
com responsável e prazo (1 de 9).

**Do lado do material de gestão**, o que se repete em mais de uma fonte: ticket
médio, taxa de ocupação, inadimplência e fluxo de caixa aparecem nas duas listas
de indicadores alcançadas; fechamento de caixa diário e confirmação de consulta
aparecem em todas as descrições de rotina de recepção alcançadas.

---

## 10. O que isto obriga a decidir

Perguntas em aberto que saíram da pesquisa. **Não são respondidas aqui**, e
nenhuma delas é recomendação.

1. **O repasse nasce quando?** Os três gatilhos documentados no mercado são
   excludentes entre si: valor recebido do paciente, tratamento concluído, e
   orçamento aprovado. Um sistema que suporta os três precisa decidir se o
   gatilho é da clínica, do profissional, ou do procedimento.

2. **O repasse incide sobre o quê?** Valor cheio, ou valor depois de taxa de
   cartão, tributo, custo de material e laboratório. Se depois, a ordem dos
   descontos muda o resultado, e a ordem precisa estar escrita.

3. **Quando o valor do repasse para de mudar?** A Feegow congela na
   consolidação e declara o repasse inalterável. Sem um ponto de congelamento,
   todo relatório de repasse é uma foto de um número que ainda se move.

4. **O que acontece com repasse já congelado quando o recebimento é
   estornado?** Nenhum fabricante alcançado documenta isso, e o material de
   consultoria diz que sem cláusula escrita o desconto não se sustenta.

5. **Quem pode ver o repasse do outro?** A dor de permissão financeira apareceu
   em três sistemas distintos, e repasse é o dado onde o vazamento tem custo
   entre sócios, não só entre clínica e paciente.

6. **O relatório de repasse precisa mostrar a memória de cálculo?** As cinco
   reclamações de repasse não pedem funcionalidade nova. Pedem enxergar de onde
   veio o número.

7. **Convênio e glosa entram, e em qual profundidade?** Cinco dos nove
   fabricantes têm TISS, e nenhuma fonte alcançada mostra o corte por tamanho de
   clínica. A pergunta anterior a essa é se a clínica alvo atende convênio.

8. **Atendimento glosado sai da base de repasse, ou entra e depois se corrige?**
   O material contábil diz que glosa precisa ser tratada à parte para não
   distorcer, e não descreve como.

9. **Conciliação bancária é para a clínica ou para o contador?** Nenhuma fonte
   alcançada respondeu quem opera a conciliação numa clínica pequena, e a
   resposta muda quem é o usuário da tela.

10. **Um recebimento pode ter mais de uma forma de pagamento?** É a única
    reclamação encontrada que descreve uma limitação de modelagem de dado, e não
    um bug. O paciente que paga metade no cartão e metade em dinheiro não cabe
    no modelo de um dos sistemas.

11. **Tarefa é card avulso ou rotina recorrente?** A rotina descrita pela
    literatura de gestão tem cadência fixa, papel e janela. O único módulo de
    tarefa alcançado no mercado é card avulso com responsável e prazo.

12. **Quem é o dono da tarefa, a pessoa ou o papel?** A rotina de abertura e
    fechamento de caixa é da recepção, não de uma pessoa. Nenhum sistema
    alcançado modela papel.

13. **A régua de cobrança é do sistema ou de uma ferramenta de mensagem?** Três
    dos nove embutem, e os números de eficácia publicados são do próprio
    vendedor sobre o próprio produto.

14. **Qual é o denominador da inadimplência que a tela vai mostrar?** As três
    referências alcançadas (6,7% de média, até 15% de perda, abaixo de 3% como
    saudável) não usam a mesma base, e nenhuma foi verificada na origem.

15. **O fechamento é diário, semanal ou mensal?** A literatura descreve os três
    em cadências diferentes, com o alerta de que o mensal chega tarde para
    corrigir o mês.

---

## 11. Onde esta pesquisa não chegou

Registro explícito, no mesmo espírito de "código lido, não comportamento
provado".

- **Nenhuma fonte foi aberta na íntegra.** Todo o documento é nível 2.
- **Dr. Clin não foi identificado.** As buscas devolveram Doctor Clin (operadora
  do Rio Grande do Sul) e Sistema Clin, que são outras empresas. Se o nome
  correto for outro, a pesquisa precisa ser refeita com ele.
- **Nenhuma avaliação de Capterra, G2, Google Play ou App Store foi lida.** Os
  quatro domínios estão bloqueados. As duas linhas que citam App Store vieram de
  extrato de busca.
- **A cartilha de glosa da ANS não foi lida**, nem o texto da RN 503 de 2022.
- **Nenhum dado sobre uso real de conciliação bancária por clínica pequena foi
  encontrado.**
- **Nenhuma reclamação sobre régua de cobrança, sobre conciliação, ou sobre
  ausência de tarefas foi encontrada.** Ausência de reclamação encontrada não é
  prova de ausência de dor.
- **Discussão pública em fórum, grupo ou rede social não foi alcançada.** As
  buscas só devolveram páginas de fabricante, de agregador e de reclamação.
