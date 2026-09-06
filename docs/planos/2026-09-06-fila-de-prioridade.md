# Fila de prioridade, 06/09/2026

As 55 issues abertas em `nexclin/nexclin-sdd`, uma linha cada, para o Arthur e
o Erick marcarem o que é **correção imediata** antes de 08/09.

**A coluna que decide o custo não é a dificuldade, é quem executa.** Sete já
estão com o código feito e esperam só aceite. Vinte e seis são do Arthur e não
gastam token nenhum do Claude. Vinte e duas gastam, e três delas são caras.

**Como marcar:** ponha `AGORA`, `08/09` ou `DEPOIS` na coluna vazia. Item sem
marca fica como está.

## Como #61 e #62 foram verificadas, já que você perguntou

Você rodou a conferência e me mandou o resultado. **Ele prova as duas**, e a
razão é mecânica, não interpretação:

A consulta que devolveu `intactas` e `linhas` **cita as três colunas novas pelo
nome**. Se qualquer uma não existisse, o Postgres devolveria erro de coluna
inexistente, e não linhas. Ela devolveu **604 e 604** em `receivables` e **157 e
157** em `expenses`.

Logo: as seis colunas existem, e **nenhuma das 761 linhas foi tocada**. A
consulta de reversão confirmou pelo outro lado, com `baixas_gravadas = 0`.

Pode marcar as duas como OK. O que **não** está provado por isso é o
comportamento das telas de baixa, que é a issue #71 e ainda depende do Publish.

## Legenda de custo

| Marca | O que significa |
|---|---|
| **zero** | é do Arthur, o Claude não gasta token |
| **baixo** | um arquivo, poucas linhas, sem risco de regressão |
| **médio** | um a três arquivos, ou uma migração nova |
| **alto** | várias telas, com risco de regressão |

Custo aqui é tamanho de diff e número de arquivos tocados, não uma medição de
token. Não existe medição precisa disponível.

---

## A. Prontas, esperando só o seu olho

| Issue | O que é | Custo | Marcar |
|---|---|---|---|
| #61 | migração da baixa em duas etapas | zero | **OK, verificada em 06/09** |
| #62 | bloco guiado da fase 1 da 021, com conferência e reversão | zero | **OK, verificada em 06/09** |
| #88 | procurar as telas irmãs que mostram responsável. São três, e as três têm foto | zero | |
| #93 | contagem de dias de atraso no card, e não só cor | zero | |
| #94 | foto do responsável no card | zero | |
| #95 | tratar o caso sem foto, que cai nas iniciais | zero | |
| #96 | aplicar prazo, atraso e foto às telas irmãs | zero | |

---

## B. Suas, e não gastam token do Claude

### B1. Infra, e é onde mora o maior risco

| Issue | O que é | Por que importa | Marcar |
|---|---|---|---|
| #47 | garantir uma restauração **testada** do banco antes de 08/09 | export que ninguém testou não é backup | **OK, o Arthur assumiu em 06/09** |
| #48 | definir a senha real do superadmin por recovery | a alínea (e) proíbe senha definida por terceiro | **OK, feita** |
| #50 | destravar os cinco e2e da cascata de permissão | **falta um segundo usuário na clínica.** Destrava cinco provas e a foto do responsável de uma vez. **Passo a passo em [`docs/ponte/50-segundo-usuario-passo-a-passo.md`](../ponte/50-segundo-usuario-passo-a-passo.md)** | |

### B2. Rodar SQL no editor

| Issue | O que é | Marcar |
|---|---|---|
| #58 | censo financeiro, blocos 3, 3b e 3c: `revenues` contra `receivables` e as 28 linhas | |
| #78 | censo de tarefas, bloco 1: **quantos valores de `responsible` não casam com membro**. É o número que libera a fase 1 da 022 | |
| #64 | aplicar os blocos da fase 1 da 021 e conferir cada um. O b1 já foi em 06/09 | |
| #85 | aplicar os blocos da fase 1 da 022, que ainda não existem | |

### B3. Portão de export, antes de cada fase

| Issue | O que é | Marcar |
|---|---|---|
| #63 | conferir export com cópia em nuvem antes da fase 1 da 021 | |
| #84 | o mesmo antes da fase 1 da 022 | |

### B4. Publicar e conferir que publicou

| Issue | O que é | Marcar |
|---|---|---|
| #69 | publicar pela ponte inversa e rodar `scripts/ponte.sh conferir` | |
| #70 | procurar o marcador de texto das telas novas dentro do bundle | |
| #90 | publicar a fase 1 da 022 | |
| #91 | procurar o marcador da tela de tarefas dentro do bundle | |
| #97 | gate de tipos, publicar e conferir o marcador da fase 2 | |

### B5. Aceitar, que é onde "implementado" vira "funciona"

| Issue | O que é | Marcar |
|---|---|---|
| #71 | a baixa grava valor, hora com fuso e autor | |
| #72 | baixar R$ 100 recebendo R$ 97. O previsto continua 100, o recebido é 97, e o caixa usa 97 | |
| #73 | o saldo de hoje bate com a soma feita à mão | |
| #92 | responsável é usuário, e nenhum nome antigo sumiu | |
| #98 | tarefa vencida há três dias mostra o número 3 | |
| #99 | aceite 200%, validação pela ótica de quem usa | |
| #41 | apagar paciente deixa autor, hora e estado anterior | |
| #42 | paciente some das listas e a linha continua existindo | |
| #43 | reconstruir o paciente a partir de `previous_state` | |
| #44 | outra clínica não lê a auditoria nem o paciente | |
| #36 | provar o formulário público de anamnese ponta a ponta | |
| #49 | provar o diff de `update_email` em `superadmin_audit_log` | |

### B6. Decidir

| Issue | O que é | Marcar |
|---|---|---|
| #60 | **portão 1**: o destino de `revenues`. Ela e `receivables` guardam os mesmos campos, e nenhum caminho do app escreve em `revenues` | |
| #37 | `public_token` dedicado na anamnese pública entra antes de 08/09? | |

---

## C. Minhas, e é aqui que o token vai

### C1. Altas, três

| Issue | O que é | Depende de | Marcar |
|---|---|---|---|
| #66 | baixa de contas a receber vira duas etapas no front | **nada, está destravada**: o b1 já foi aplicado | |
| #67 | a mesma troca em contas a pagar | #66 | |
| #87 | o front grava e lê o responsável como usuário | migração da 022, que depende de #78 | |
| #40 | exclusão de paciente vira soft delete e as listas filtram | #39 | |

### C2. Médias, cinco

| Issue | O que é | Depende de | Marcar |
|---|---|---|---|
| #80 | migração que faz o responsável da tarefa virar referência a usuário | #78 | |
| #81 | coluna de legado preservando o texto original de `responsible` | vai junto com #80 | |
| #82 | conversão do texto em usuário, sem adivinhar | vai junto com #80 | |
| #83 | bloco guiado da fase 1 da 022 | vai junto com #80 | |
| #38 | `public_token` dedicado na anamnese pública | decisão #37 | |
| #45 | backport das correções como migração versionada na stack nova | nada, mas só importa em outubro | |

### C3. Baixas, oito

| Issue | O que é | Marcar |
|---|---|---|
| #65 | rodar o guarda-constituição sobre a migração da 021 | |
| #86 | o mesmo sobre a migração da 022 | |
| #46 | hook e auditor multitenant sobre as migrações novas | |
| #59 | registrar o resultado do censo financeiro e corrigir a regra se divergir | |
| #79 | registrar o censo de tarefas e corrigir a regra se divergir | |
| #74 | registrar o que não deu para provar na 021, sem arredondar | |
| #100 | registrar o que não deu para provar na entrega 1 da 022 | |
| #68 #89 | gates de tipo, que já rodam em todo commit | |

---

## D. Fora das issues, e um deles é número errado na sua tela

| O que é | Custo | Por quê | Marcar |
|---|---|---|---|
| `initialBalance` do **Saldo do Período** ignora todo movimento anterior ao período | médio | o saldo do período só está certo quando a abertura da conta coincide com o início do período. Em qualquer outro mês ele está deslocado. Achado em 06/09, não tocado porque muda número que você já olha | |
| barra lateral ainda rola abaixo de 615px de janela | baixo | você disse para deixar para depois | |
| `CONTEXT.md` com 73 linhas contra um teto de 60 que ele mesmo declara | baixo | precisa de você para decidir o que cortar, ou subir o teto | |
| PR #54 em `nexclin-sdd` continua aberto | baixo | mesclar ou fechar | |

---

## O que eu faria, se a decisão fosse minha

**Primeiro o que é seu e destrava o meu**, porque não custa token: #47, #50 e
#78, nessa ordem. O #50 sozinho destrava cinco provas de permissão e a foto do
responsável.

**Depois #66 e #67.** É a única coisa cara que já está destravada, e é o que a
reunião classificou como inegociável: financeiro que não erra o caixa.

**#87 em segundo**, porque mesmo escrita hoje ela não funciona até a migração
da 022 ser aplicada. **#40 em terceiro**, porque exclusão de paciente não é
caminho que o fundador percorre na primeira semana.

**Depois de 08/09**: as oito baixas de registro, o #38 e o #45, que por
definição só importa em outubro.
