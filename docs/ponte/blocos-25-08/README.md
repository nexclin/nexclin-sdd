# Sequência de blocos, 25/08/2026: migrações e base limpa para o reteste

> Escrito depois que o Arthur respondeu o questionário. As três respostas
> decidiram tudo o que está aqui:
>
> 1. **"Tudo é teste, pode zerar."** Some a migração de correção de dado. Não
>    existe erro a consertar em linha nenhuma: existe base a esvaziar.
> 2. **"Quem criou, mais o master."** É a regra de edição de tarefa, e ela
>    exige a coluna `tasks.created_by`.
> 3. **"Bloco a bloco, comigo junto."** Daí o formato: um arquivo por passo,
>    cada um com o que esperar de volta.

## Por que sou eu que escrevo e você que cola

Em 19/08 ficou provado que o editor de SQL da plataforma **executa uma consulta
diferente da que está na tela** quando é dirigido por automação. Registro em
`docs/seguranca/nota-sql-editor-lovable-2026-08-19.md`. Desde então, nenhum
agente aplica migração ali. Eu escrevo e confiro o retorno; a colagem é sua.

## A ordem, e a razão dela

Migração antes de zerar, e não o contrário. Se uma migração falhar, o dado
ainda está lá. Zerando primeiro, uma falha depois deixa a base vazia **e** o
schema pela metade.

| Bloco | O quê | Muda dado? |
|---|---|---|
| 0 | Anotar o backup mais recente | não |
| 0B | Ler as policies de `team_members` | não, só lê |
| 1 e 1B | Inventário e quem existe | não, só lê |
| 2 | EQP-1: clínica nasce com assinatura | sim, repara |
| 3 | Tarefas ganham autor e origem | sim, repara |
| 4 | Default de `enabled_modules` | sim, normaliza |
| 5 | Auditoria de dado e exclusão que marca | sim, estrutura |
| 5B | Ninguém muda a própria permissão | sim, estrutura |
| 6 | Zera o movimento | **sim, e sem volta** |
| 6B | Zera a configuração (opcional) | **sim, e sem volta** |
| 7 | Conferência final | não, só lê |

---

## Bloco 0. O ponto de retorno, e ele não é o que eu escrevi antes

> **Correção de 25/08.** A primeira versão deste bloco mandava exportar o banco
> "pela função de exportar dados da plataforma". **Essa função não existe neste
> projeto.** Procurei em Cloud → Database, Cloud → Overview, no menu do projeto
> e nas Configurações do projeto; a busca de configurações por "export" devolve
> *"No matching settings"*.
>
> O que existe e se parece com export é o **Export CSV** do painel de resultados
> do SQL editor, que exporta o resultado de UMA consulta. Não é backup de banco,
> e eu apoiei um passo irreversível num artefato que não estava lá.

**O ponto de retorno real são os Backups da plataforma.**

Onde: **Cloud → Database → botão Backups**, no canto superior direito. São
pontos de restauração diários automáticos, um por dia, cada um com um botão
"Restore to this backup".

**O que fazer no Bloco 0, então:**

1. Abra Backups e **anote a data e a hora do mais recente**, com fuso.
2. Confirme que ele é de hoje. Se o mais recente for de ontem, tudo que foi
   feito hoje está fora da rede.
3. No fim da sequência, confira que ele continua na lista.

**A diferença que isso faz, e ela é grande.** Restaurar não é seletivo:
o banco inteiro volta para aquele horário, e **tudo que veio depois se perde**,
inclusive as migrações desta sequência. O custo de errar deixou de ser
"restauro o arquivo" e passou a ser "perco o dia".

Como a base é toda de teste, isso é suficiente. Mas é diferente do que estava
escrito aqui, e você precisa saber disso antes do Bloco 6, não depois.

---

## Bloco 1. Inventário, e Bloco 1B. Quem existe

Arquivos: `bloco-1-inventario.sql` e `bloco-1b-quem-existe.sql`.

Os dois só leem. **Guarde os dois resultados**, porque o Bloco 7 confere contra
eles: as contagens de clínica e de acessos têm de sobreviver ao Bloco 6.

**Pare e me chame se o 1B mostrar mais de uma clínica com movimento.** Zerar
é o passo sem volta, e ele parte da sua resposta de que tudo é teste. Se
houver clínica que não é sua, essa resposta muda.

---

## Bloco 2. A clínica nasce com assinatura

Cole o conteúdo de
`supabase/migrations/20260825080000_assinatura_de_trial_no_cadastro_da_clinica.sql`.

**Este é o único item da bateria que ainda não tem efeito nenhum para o
Vinícius.** O relato foi *"ao cadastrar colaboradora e colocar para gerar
acesso, deu como não permitido"*, e quem levou o 403 era o administrador da
própria clínica.

A cadeia: `handle_new_user` cria clínica, perfil, papel e equipe, e **não cria
linha em `account_subscriptions`**. Sem ela, `my_permission` não acha
`enabled_modules`, devolve `none` e sai antes de chegar na linha que daria
`full` para o admin. A função de convite exige `full` e recusa.

O botão aparecia porque a tela é permissiva onde o banco é restritivo:
`usePermissions.ts` tem `if (!subscriptionState) return true`. Ver o botão e
levar a recusa é exatamente esse desencontro.

**Retorno esperado:** um `NOTICE` dizendo quantas clínicas receberam assinatura.

**Prova de que funcionou, e ela vale mais que o retorno:** entrar como dono da
clínica e convidar alguém de verdade.

---

## Bloco 3. Tarefa com autor e origem

Cole o conteúdo de
`supabase/migrations/20260825090000_origem_e_autor_das_tarefas.sql`.

É o que destrava a resposta 2. Sem `created_by` não há de onde saber quem
criou, e "editável pelo criador ou pelo master" não tem como existir.

O código já está publicado e **funciona nos dois estados do banco**: enquanto a
coluna não existe, ele grava a tarefa sem autor e a regra libera a edição.
Depois deste bloco, tarefa nova nasce com autor e a regra aperta sozinha.

**Retorno esperado:** as duas colunas criadas, e o `UPDATE` marcando como
`automatica` os tipos que só a automação produz.

Se o Bloco 6 já tiver rodado, esse `UPDATE` afeta zero linhas, e está certo:
não há tarefa antiga para reparar.

---

## Bloco 4. Default de `enabled_modules`

Cole o conteúdo de
`supabase/migrations/20260825070000_corrige_default_de_enabled_modules.sql`.

A coluna nasceu com `DEFAULT '[]'`, que é array, e o trigger que a valida exige
objeto. **O default da coluna é um valor que a própria tabela recusa.** Todo
`INSERT` em `plans` sem informar a coluna falha.

Ninguém esbarrou ainda porque os planos vieram de migração, que informa o
objeto na mão. Esbarra no dia em que um plano for criado pela tela do
superadmin.

**Retorno esperado:** nenhum erro. A conferência está comentada no rodapé do
próprio arquivo.

---

## Bloco 5. Auditoria de dado, e exclusão que marca

Cole o conteúdo de
`supabase/migrations/20260825060000_auditoria_de_dado_e_soft_delete_em_patients.sql`.

Duas coisas que a constituição já exigia e o banco não entregava:

- **Auditoria.** Hoje só ação de superadmin deixa rastro. O que o dono da
  clínica faz dentro da própria conta não registra nada, e é dado de saúde.
- **Exclusão de paciente.** Era `DELETE` de verdade: apagava a linha, levava o
  histórico junto, sem volta e sem registro de quem mandou.

A trilha nasce **sem policy de escrita**, de propósito. Com RLS ligada e
nenhuma policy de `INSERT`, `UPDATE` ou `DELETE`, toda escrita de sessão de
usuário é negada, e quem grava é o trigger, que roda `SECURITY DEFINER` e não
passa por RLS. A trilha fica imutável para todo mundo, inclusive para o
superadmin.

**O detalhe que exigiu mudar a tela antes:** depois deste bloco, o `DELETE` em
`patients` não dá erro. Ele afeta zero linhas em silêncio, porque RLS sem
policy nega sem reclamar. A tela mostraria "Paciente excluído" e o paciente
continuaria na lista.

Por isso o commit `d07b74f` inverteu a ordem: a tela marca `deleted_at`
primeiro, e só cai no `DELETE` antigo se a coluna ainda não existir. Funciona
antes e depois deste bloco, então **nenhuma ordem entre publicar e migrar
quebra nada**.

---

## Bloco 5B. Ninguém muda a própria permissão

> **Rode o `bloco-0-policies-de-team-members.sql` antes deste.**
>
> Em 25/08 o agente do Lovable afirmou, no painel de chat, ter feito a mesma
> correção: *"substituí a política aberta da equipe por regras granulares
> (leitura para a clínica, gestão só para administradores, autoedição sem poder
> alterar cargo/permissões/repasse)"*.
>
> Se aquilo rodou, este bloco pode ser redundante ou conflitar. Duas camadas
> checando a mesma coisa por caminhos diferentes é como nasce o bug em que uma
> delas é afrouxada e ninguém percebe, porque a outra ainda segura.
>
> O 0B devolve as policies, os triggers e os GRANTs de coluna que existem hoje.
> Mais de uma policy na tabela, ou trigger com nome parecido, significa **pare e
> me mande o resultado**.

Cole o conteúdo de
`supabase/migrations/20260825100000_ninguem_muda_a_propria_permissao.sql`.

**Entrou depois, por decisão do Arthur em 25/08.** O documento de segurança
encaminhava esta correção para depois do lançamento; ele decidiu fechar antes
de 08/09.

O buraco: existe uma policy só em `team_members`, `FOR ALL`, com a condição
sendo apenas o `clinic_id`. Qualquer membro dá UPDATE em qualquer linha da
própria clínica, inclusive na dele. Uma secretária se promove a `master`, e um
profissional aumenta o próprio percentual de repasse.

É trigger e não policy porque a regra é sobre a **mudança de coluna**, não sobre
quem escreve na linha, e um `WITH CHECK` não enxerga o valor anterior.

**Não toca em nada que hoje funciona.** O admin continua editando a permissão
dos outros pela tela de Equipe, o cadastro de clínica continua criando o time, e
o convite continua funcionando: esses caminhos não têm `auth.uid()`, e o
trigger os deixa passar de propósito.

**O que provar depois, e são quatro passos, não um:**

1. Membro não administrador tentando mudar a própria permissão: tem de recusar.
2. **Administrador mudando a permissão de outra pessoa: tem de salvar.** É o
   teste que mais importa, porque diz que a correção não trancou a clínica fora
   da própria equipe.
3. Administrador tentando mudar a própria: recusa também. Não tira acesso
   nenhum, porque o papel global de admin já dá `full` em todo módulo.
4. Não administrador tentando mexer em repasse de qualquer pessoa: recusa.

---

## Bloco 6. Zerar o movimento

Arquivo: `bloco-6-zerar-movimento.sql`. **Este é o passo sem volta.**

Sai o que foi lançado: paciente, lead, consulta, orçamento, fechamento,
recebível, receita, despesa, tarefa, anamnese respondida, insight.

Fica a conta e a configuração: clínica, perfil, equipe, papel, assinatura,
plano, e os catálogos. Ninguém reconfigura nada para retestar.

`TRUNCATE` e não `DELETE`, e o motivo que importa é o terceiro: **`TRUNCATE`
não dispara trigger de linha.** Com o Bloco 5 aplicado, um `DELETE` em
`patients` escreveria uma linha de auditoria por paciente, e a trilha nasceria
cheia de lixo de teste.

**Se der erro de chave estrangeira,** me mande o nome da tabela em vez de
acrescentar `CASCADE`. `CASCADE` apagaria essa tabela também, sem perguntar, e
ela pode ser uma das que decidimos manter. No erro, nada foi apagado.

Depois, rode `bloco-1-inventario.sql` de novo: as tabelas de movimento em zero,
e clínica, equipe e serviços iguais à primeira rodada.

---

## Bloco 6B. Zerar a configuração. Opcional, e provavelmente não

Arquivo: `bloco-6b-zerar-catalogos.sql`.

Só faz sentido se o reteste tiver de começar configurando serviço, plano de
contas e forma de pagamento do zero.

**Minha recomendação é pular.** O Bloco 6 já entrega base limpa de movimento, e
esse é o cenário mais próximo do que o cliente fundador vai encontrar: ele
configura uma vez e opera. Zerar catálogo transforma o reteste do financeiro em
reteste de cadastro.

E há uma armadilha dentro dele: `bank_accounts`, `payment_methods`, `channels`,
`origins`, `objections` e `business_rules` vêm do cadastro da clínica, não de
alguém. Zerando, **não voltam sozinhos**, porque aquele seed só dispara quando
uma clínica nasce. Por isso essas seis estão comentadas no arquivo.

---

## Bloco 7. Conferência final

Arquivo: `bloco-7-conferencia.sql`. Só lê. Dez linhas, cada uma com o valor
esperado ao lado. Qualquer coisa fora, me mande o resultado inteiro.

---

## Depois da sequência

O que fica pronto para o reteste do Vinícius:

- Os 23 itens da bateria corrigidos no código, publicados
  (`docs/planejamento/verificacao-bateria-25-08.md`).
- O convite de equipe funcionando, que era o único item ainda sem efeito.
- Tarefa editável pelo criador ou pelo master, com a coluna que sustenta a
  regra.
- Base limpa, então nenhum número vem de lançamento de teste antigo.

O que **não** fica pronto, e é honesto dizer: nada disso foi exercitado por uma
pessoa na tela. É código lido e SQL conferido, não comportamento provado. O
reteste é o que fecha.

E um item continua aberto de propósito, fora desta sequência: o furo de
autoconcessão em `team_members`
(`docs/seguranca/autoconcessao-team-members-2026-08-25.md`). Qualquer membro
pode alterar as próprias permissões e o próprio percentual de repasse. É faixa
A, atravessa, e não entra na semana do lançamento porque mexer na policy de
equipe às vésperas de abrir é trocar um risco conhecido por um desconhecido.
