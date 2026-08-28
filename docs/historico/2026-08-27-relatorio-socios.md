# Relatório para os sócios, 27/08/2026

> Cobre o período desde o último relatório, de 25/08. Escrito para quem não lê
> código: fala do que a clínica passa a conseguir fazer, não de como foi feito.
>
> Faltam **12 dias** para o lançamento de 08/09.

---

## 1. A decisão que mudou o plano

Até 25/08 a orientação era: corrigir na plataforma atual só o que fosse
aproveitado depois, e construir o que é novo já na estrutura definitiva.

**Em 26/08 isso foi invertido.** Tudo que está definido passa a ser construído na
plataforma que vai ao ar em 08/09, e a estrutura definitiva espera. A migração
acontece gradualmente em setembro e se conclui em outubro.

**O que se ganha:** o cliente fundador abre com o produto completo, não com um
esqueleto.

**O que se paga:** as telas construídas agora serão reescritas na migração. É
retrabalho real, e foi aceito conscientemente. Produto que não abre não tem
migração para fazer.

---

## 2. O que o produto ganhou

Sete funcionalidades novas, todas publicadas. Elas têm um fio comum: **o sistema
deixa de só registrar o que a clínica fez e passa a dizer o que ela deveria
fazer.**

### Régua de cobrança

O sistema já sabia quem estava em atraso e não fazia nada com isso. Agora ele
diz **quem chamar hoje e o que dizer**, em cinco faixas, com a mensagem pronta e
o botão de WhatsApp.

A primeira faixa é **antes** do vencimento. Lembrar alguém que vai vencer custa
uma mensagem; cobrar depois custa a relação.

*Referência de mercado: clínicas que estruturam cobrança em faixas relatam queda
de até 60% na inadimplência.*

### Custo da hora clínica e preço mínimo

**É o diferencial de venda, e até anteontem não existia em lugar nenhum do
produto.**

O sistema passa a calcular quanto custa manter a cadeira aberta por uma hora,
somando custo fixo e depreciação de equipamento, dividido pelas horas realmente
produtivas. E daí, o preço mínimo de cada procedimento.

Num exemplo real de clínica pequena: hora clínica de R$ 162, e uma profilaxia de
50 minutos com R$ 25 de material tem preço mínimo de **R$ 363**. Se a clínica
cobra R$ 250, ela perde R$ 113 por atendimento e não sabe.

A lista de serviços agora mostra quais estão **abaixo do custo** (sangra a cada
atendimento) e quais estão **abaixo da margem** (paga o custo, não o lucro). São
problemas diferentes e a tela os separa.

### Taxa de falta e ocupação da agenda

A taxa de falta em clínicas brasileiras fica entre 20% e 30%, é o maior ralo de
receita da operação, e **não aparecia em lugar nenhum do sistema**.

Agora aparece, com o custo em reais ao lado: cada falta é uma hora de cadeira que
a clínica pagou e não vendeu.

### Recall de pacientes

A configuração "recall após 180 dias" existia na tela desde sempre, e **nada no
código a usava**. A clínica configurava e nunca acontecia nada.

Agora há uma lista de quem não volta há tempo demais, separada em "retorno
vencido" e "retorno chegando". A segunda é a que rende: falar com quem está a
duas semanas de vencer é convite; falar com quem sumiu há um ano é resgate.

### Meta do mês por dia útil

O painel mostrava meta e realizado, o que responde "como está o mês" e não muda o
que alguém faz hoje. Agora mostra **quanto falta por dia útil**, com os feriados
nacionais já descontados.

E avisa quando o realizado está abaixo do ritmo: 40% do mês passado com 20% da
meta batida é atraso, e o percentual sozinho não conta isso.

### Insumos e composição de custo

O custo de cada serviço era um número digitado à mão que ninguém sabia de onde
veio e que nunca era atualizado.

Agora ele pode ser **composto** a partir dos insumos. E o sistema impede o erro
de custeio mais comum em clínica: lançar o preço da caixa como custo do
procedimento. Uma caixa de 100 luvas por R$ 30 custa R$ 0,30 o par, não R$ 30.

### Salas, equipamentos e conflito de agenda

Marcar dois procedimentos na mesma sala no mesmo horário só era descoberto quando
os dois pacientes chegavam. Agora o sistema aponta o conflito e mostra o uso de
cada sala no dia.

**Mais:** o painel do superadmin, que era só leitura, passou a permitir criar
conta de cliente, definir plano, situação e data de cobrança.

---

## 3. O que foi corrigido

### Segurança

| Achado | Gravidade |
|---|---|
| Qualquer membro da equipe podia **alterar as próprias permissões e o próprio percentual de repasse** | Alta. Dinheiro e acesso |
| Sessão de suporte não tinha prazo: quem entrava numa conta de cliente e fechava o navegador ficava lá dentro **indefinidamente** | Alta |
| A linha do tempo da conta era uma tela mostrando dado que ninguém escrevia | Média |
| A senha da conta-mestra foi exposta em texto puro, pela segunda vez | **Precisa de troca, e ainda não foi feita** |

### Defeitos encontrados numa bateria de verificação

Depois de tudo publicado, rodei uma verificação completa e encontrei três
defeitos reais:

**1. Fuso horário.** Todas as telas com data erravam o dia **entre 21h e
meia-noite**, que é justamente o horário em que dono de clínica olha o sistema.
No dia 31 do mês, a tela de metas mostraria o mês seguinte.

**2. Telefone incompleto** no cadastro gerava um botão de WhatsApp que não abre
conversa nenhuma. A pessoa clica, nada acontece, e conclui que o sistema está
quebrado.

**3. Um valor inválido no banco** faria a tela mostrar "R$ NaN" no lugar do
preço, sem erro nenhum.

Os três foram corrigidos e agora têm teste automático.

### Qualidade

O projeto passou a ter **76 testes automáticos** na plataforma que vai ao ar, e
225 na estrutura definitiva. Antes de anteontem, a plataforma tinha um.

Isso importa por uma razão prática: sem eles, a próxima pessoa que mexer no
cálculo de preço quebra a conta e nada acusa.

---

## 4. O que falta para 08/09

| Pendência | De quem depende | Impacto se não sair |
|---|---|---|
| **Aplicar seis alterações no banco** | Arthur, hoje | Cinco telas mostram alerta em vez de funcionar |
| Trocar a senha da conta-mestra | Arthur | Risco de segurança aberto |
| Ligar o envio de e-mail (Resend) | Arthur | Sem reset de senha e sem convite de equipe |
| Transcrever os apontamentos do Erick | Erick e Arthur | Bugs que quem testou encontrou continuam no ar |
| Reteste do Vinícius | Vinícius | Os 23 itens da bateria estão corrigidos desde 25/08 e ninguém conferiu |

**O gargalo real é o primeiro**, e é uma tarefa de minutos.

---

## 5. Três coisas que precisam de decisão do grupo

### Um endpoint novo foi publicado sem passar pelo processo

Entraram no repositório da plataforma 20 alterações que não vieram pelo caminho
combinado. Entre elas, **um endpoint que expõe pacientes, consultas e resumo
financeiro por integração externa**, com página de consentimento.

Tecnicamente o desenho respeita o isolamento entre clínicas, e nisso está
correto. Mas é uma **superfície externa nova num sistema com dado de saúde, a 12
dias de abrir, sem revisão e sem especificação**.

A conta da plataforma é a do Erick. Não é acusação: é uma pergunta de processo.
**Quem pode publicar no repositório, e sob qual procedimento?**

### A parceria com a Surgic

O Arthur está prospectando a Surgic, distribuidora de insumos médicos do Sul
Fluminense, cuja carteira de clientes é composta de clínicas, laboratórios e
consultórios. É a mesma peça que o mentor representa: **canal de distribuição**.

A estrutura discutida é comissão de 100% do primeiro mês por cliente indicado.
Há um detalhe a fechar: se o cliente tem 30 dias grátis, 100% do primeiro mês é
zero. Ou o cliente indicado paga desde o dia 1, ou a comissão passa a ser sobre o
segundo mês.

**E vale confirmar com o contador**, porque no primeiro desenho o dinheiro entra
e sai, e pode haver imposto sobre uma receita repassada inteira.

### A migração para outubro

Confirmada. Setembro é transição gradual, outubro é a virada oficial. Isso
significa que o mês de operação na plataforma atual é definitivo: **o que as
clínicas lançarem lá vem junto para a estrutura nova.**

É por isso que a parte financeira teve prioridade absoluta nas correções.

---

## 6. Onde está a documentação

Tudo o que está acima tem registro em arquivo, e nada depende da memória de
ninguém:

- `2026-08-26-registro-do-dia.md`: cada alteração com o motivo
- `specs/006-modelagem-ini/spec.md`: as dez funcionalidades e por que cada
  decisão foi tomada
- `2026-08-26-verificacao-modelagem.md`: a bateria e os três
  defeitos
- `docs/seguranca/`: os achados de segurança, um arquivo por achado
- `docs/ponte/blocos-26-08/`: o passo a passo das seis alterações de banco
