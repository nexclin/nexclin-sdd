# Tudo que está pendente, em 27/08/2026

> Pedido do Arthur: *"vamos definir o que fazer agora por hierarquia, cite tudo
> que está pendente e traga pra mim de volta pra eu decidir a ordem de
> execução"*.
>
> Montado lendo o repositório, os `tasks.md` e os registros datados, não de
> memória. Substitui o `docs/orquestracao/mapa-de-execucao.md` de 25/08 onde
> houver divergência: aquele foi escrito antes da inversão de prioridade de
> 26/08 e antes das seis migrações entrarem em 27/08.

## A hierarquia, em uma frase por nível

| Nível | O que é | Regra |
|---|---|---|
| **0** | Só o Arthur faz | Bloqueia trabalho meu. Enquanto não sai, eu fico parado nesses ramos |
| **1** | Lançamento de 08/09, na Lovable | Tem data. É o que o cliente fundador vê |
| **2** | Atravessa para outubro | Não tem data própria, mas o custo de deixar para depois é retrabalho |
| **3** | Stack nova | Adiada por decisão de 26/08. Não compete por tempo agora |
| **4** | Backlog | Registrado para não se perder. Nada aqui tem prazo |

**A coisa que pode reordenar tudo:** o segundo vídeo do Erick não foi
transcrito. Se ele contiver bateria de bugs, ela tem precedência sobre toda
funcionalidade nova desta lista, e os níveis 1 e 2 mudam de ordem. O primeiro
vídeo tem **zero bugs** (`triagem-erick-27-08.md`), então essa precedência ainda
não foi acionada.

---

## Nível 0. Só o Arthur, e cada um destrava algo meu

| # | Pendência | Custo | O que destrava | Desde |
|---|---|---|---|---|
| **0.1** | **Publish na Lovable** do commit `5a1931c`, a barra lateral | 1 clique | A correção só existe no repositório até isso | hoje |
| **0.2** | **Criar `teste@nexclin.com`** pela tela de cadastro, com senha nova | 1 minuto | O povoamento da conta de teste. Sem o cadastro real, a conta nasce sem perfil, sem clínica e sem assinatura | hoje |
| **0.3** | **Trocar a senha da conta-mestra** por recovery | 5 minutos | Nada tecnicamente. É reparo de segurança, exposta 2 vezes | 26/08 |
| **0.4** | **Ligar SMTP (Resend)** | 15 minutos | Convite de equipe e reset de senha. Hoje nenhum dos dois entrega | 26/08 |
| **0.5** | **Transcrever o 2º vídeo do Erick** | ? | Pode reordenar os níveis 1 e 2 inteiros | 26/08 |
| **0.6** | **Consulta de segurança em `storage.objects`** | 2 minutos | A SPEC 013, e é dívida de RLS sem filtro por `bucket_id` | 20/08 |
| **0.7** | **Reteste dos 23 itens do Vinícius** | 1 hora | Nada. Mas são 23 correções publicadas em 25/08 que ninguém reconferiu na tela | 25/08 |
| **0.8** | **Aceite do T017**: convidar alguém de verdade, abrir o link, definir senha | 10 minutos | Prova a última violação da regra (e) que foi corrigida. Hoje é código lido, não comportamento provado. **Depende do 0.4** | 20/08 |

**Observação sobre a senha exposta hoje.** `Nexclin123!` foi colada no chat e
não deve ser usada. É o terceiro vazamento de credencial em três dias
(`credencial-exposta-2026-08-25.md`, `-26.md`, e este), e segue o padrão
`Nome123!` que o registro de 26/08 pediu explicitamente para não repetir.

---

## Nível 1. Lançamento de 08/09, na plataforma Lovable

Tudo aqui é implementado na Lovable, pela inversão de prioridade de 26/08.

### 1.1 Povoamento das duas contas
**Pedido pelo Erick (E-01) e pelo Arthur hoje.** Duas contas povoadas:
`teste@nexclin.com` e a clínica da conta-mestra.

Depende do **0.2**. Falta decidir o porte, que é decisão de negócio: o Erick deu
o exemplo de faturamento entre 200 e 300 mil em dois meses seguidos.

Condição que sobrou, agora que os dados foram apagados: **o script que apaga sai
antes do que insere, e é testado antes.** O banco da Lovable migra intacto em
outubro, então dado de simulação sem expurgo seria importado e não descartado.

### 1.2 Personalização de perfil, com foto
**E-02, revisado.** Mostrar quem está logado já existe; o Erick não tinha
reparado. O que falta é a personalização nos moldes do INI. Mexe na mesma região
da tela que a barra lateral, que acabou de mudar.

### 1.3 Centros de custo
**O único item "importa" da modelagem INI ainda não implantado.** Está pendente
desde 26/08 e é pré-requisito do 1.4.

### 1.4 DRE por centro de custo, com custo explodido por despesa
**E-04.** É o item mais bem posicionado da lista do Erick, e a razão é que dois
testadores chegaram nele por caminhos independentes: ele pedindo estrutura de
custo, e o time do Vinícius operando por relatório toda semana. A §2.5 tem
exceção nomeada para relatório justamente por isso.

Depende do 1.3.

### 1.5 Comentário no registro, com citação de departamento
**E-03.** Funcionalidade nova e transversal: serve consulta, tarefa, orçamento e
conta a pagar ao mesmo tempo. Precisa de spec própria, e não entra antes de
08/09 sem cortar outra coisa.

### 1.6 Plano de carreira e tabela salarial por cargo
**E-05.** Depende do 1.4: é o custo de pessoa por cargo que alimenta o rateio do
centro de custo. Especificar junto com o 1.4 ou nenhum dos dois.

---

## Nível 2. Atravessa para outubro

### 2.1 SPEC 002, Fase 2: auditoria de dado e soft delete
T005 a T008 estão **escritas** como migração versionada e aguardam aplicação.
T009 é a ponte na aplicação, T010 a T013 são aceites, T014 a T016 fazem o
backport para `supabase/migrations` daqui.

**É banco puro, então atravessa 100%.** Era prioridade declarada da janela de
22 a 23/08 e não foi executada.

### 2.2 T021 da SPEC 001: testes de permissão em Vitest
**Em zero, e é mínimo obrigatório da constituição, Princípio V.** Está registrado
como pendente no `CLAUDE.md` §6 desde o começo.

### 2.3 Auditoria do que o suporte cria sob impersonação
Dívida registrada na SPEC 006. Hoje a impersonação é auditada na entrada e na
saída, mas o que o operador escreve dentro da conta não distingue autor.

### 2.4 Emenda D-005.5: `consultas` sai do contrato de módulos
Aprovada. O contrato vai de 15 para 14 chaves. **Aplicação deliberadamente
adiada para a fase de migração**, porque mexer no contrato de permissões perto
da abertura troca um problema conhecido e inerte por um desconhecido e ativo.

---

## Nível 3. Stack nova, adiada por decisão de 26/08

Não compete por tempo agora. Listado para não sumir.

- **Aceites das SPECs 001, 003 e 005.** Estavam bloqueados pelo login do
  superadmin; a inversão de 26/08 os tirou do caminho crítico.
- **O mesmo defeito de fuso horário existe em `lib/superadmin/acoes.ts`**, que
  chama `proximaCobranca(dia, new Date())`. Encontrado em 26/08 e não corrigido,
  porque corrigir código congelado sem poder testá-lo acrescenta risco sem
  retorno. Está anotado em `verificacao-modelagem-26-08.md` para não se perder.
- **SPECs 007 a 012 não escritas**: pacientes, consultas, tarefas, leads,
  anamnese, contas a receber, dashboard.
- **SPEC 016**, endurecimento de segurança: escrita, sem `tasks.md`.
- **SPEC 013**, resíduos: escrita e bloqueada por três coisas, sendo uma delas
  o item 0.6 acima.

---

## Nível 4. Backlog

- `generate-insights` e `anamnesis-public`, as duas edge functions não portadas.
- **Estoque e pacote de sessões com saldo.** Registrado em 25/08 como candidato
  mais forte a "funcionalidade que faz cobrar mais" do que o módulo de resíduos,
  porque estética e odontologia vendem majoritariamente por pacote.
- Enforcement de `max_patients` e `max_leads_month`, que hoje não têm trigger.
- Régua NGS1 da certificação SBIS.

---

## O que eu recomendo, se a decisão for minha

Não é, e por isso fica no fim. Mas a ordem que eu executaria é:

1. **0.1 e 0.2**, porque são dois cliques e destravam duas frentes minhas.
2. **1.1, o povoamento**, porque é o que o Erick condicionou para a bateria
   maior dele, e porque base vazia esconde a classe de defeito que só aparece
   com volume: paginação, espaço de tela, e relatório que não fecha.
3. **0.5, o segundo vídeo**, em paralelo, porque ele pode reordenar o resto.
4. **1.3 e 1.4 juntos**, centros de custo e a DRE, que é o maior valor de
   produto pendente e o único item que dois testadores pediram.
5. **2.1**, a Fase 2 da SPEC 002, porque é banco puro e é a coisa desta lista
   cujo adiamento custa mais caro: ela atravessa inteira e já foi adiada uma vez.

O 1.2, a personalização de perfil, é barato e cabe em qualquer buraco.
