---
description: "Lista de tarefas da frente 022, motor de rotina"
---

# Tarefas: motor de rotina da clínica

**Entrada:** [`plan.md`](./plan.md) e [`spec.md`](./spec.md), que é link para a
regra viva.

## Formato: `[ID] [P?] [Fase] Descrição com o caminho do arquivo`

- **[P]**: pode rodar em paralelo, arquivo diferente e sem dependência aberta.
- **[Fase]**: `[F0]` a `[F6]`, as fases do plano.

> **Sem user story, por decisão da [ADR 0005](../../adr/0005-bifurcar-o-to-spec.md).**
> O agrupamento é por fase, que é o que tem aceite próprio pela alínea (h).

> **Os IDs continuam de T100** para não colidirem com os T001 a T047 da frente
> 021. As duas listas viram issue no mesmo repositório, e ID repetido faria a
> deduplicação do `speckit-taskstoissues` casar a tarefa errada.

> **Três portões são parada dura.** Tarefa depois de portão não começa antes de
> a decisão sair.

---

# ENTREGA 1, até 08/09, na Lovable

## Fase 0 · Conferir o banco antes de acreditar nele

**Objetivo:** derrubar ou confirmar a premissa 1 da regra, e medir o buraco do
FR-008 antes de decidir sobre ele.

- [ ] T100 [F0] Escrever o censo de `tasks` em `docs/ponte/022-censo-tarefas.sql`, listando por `information_schema.columns` as colunas de `tasks` e por `pg_policies` as policies dela
- [ ] T101 [P] [F0] Escrever no mesmo arquivo a contagem de valores distintos em `tasks.responsible`, com quantos deles casam com algum nome de usuário da clínica. **É este número que dimensiona o risco da Fase 1**
- [ ] T102 [P] [F0] Escrever no mesmo arquivo a prova 2, o bloco `BEGIN`/`ROLLBACK` medindo o que um usuário com `tarefas` negado lê de `tasks`, **com controle positivo**
- [ ] T103 [F0] Rodar os blocos no editor de SQL, um por vez, clicando por referência e não por coordenada
- [ ] T104 [F0] Registrar o resultado em `docs/historico/`, inclusive o que não deu para conferir, e corrigir a seção 3 da regra no mesmo commit se houver divergência

**Ponto de conferência:** premissa 1 confirmada ou derrubada, e os dois números
na mão.

---

## Fase 1 · O responsável vira usuário · FR-005

**Objetivo:** a dobradiça das duas entregas. Sem ela não há foto a buscar nem
para onde o papel resolver.

**Aceite independente:** o responsável de uma tarefa é usuário, e nenhum nome que
existia antes se perdeu.

- [ ] T105 [F1] Escrever a migração `supabase/migrations/2026090NNNNNNN_responsavel_da_tarefa_e_usuario.sql`, acrescentando a `tasks` a referência a usuário ou a membro da equipe
- [ ] T106 [F1] Na mesma migração, criar a coluna de **legado** que preserva o texto original de `responsible`. **Nome que não casar com usuário nenhum MUST ficar guardado ali, e MUST NOT ser descartado**: perder atribuição de tarefa de cliente real é dano que não se desfaz
- [ ] T107 [F1] Escrever a conversão que casa o texto existente com usuário, usando o número medido em T101, e deixar sem casar o que não casar em vez de adivinhar
- [ ] T108 [F1] Escrever o bloco guiado em `docs/ponte/aplicacao-022-fase1/`, um bloco por vez, cada um com a consulta de conferência ao lado e a reversão palavra por palavra abaixo
- [ ] T109 [F1] Conferir que o export do banco está feito e com cópia em nuvem, por `docs/seguranca/registro-exports-banco.md`
- [ ] T110 [F1] Aplicar os blocos no editor de SQL e conferir cada um
- [ ] T111 [P] [F1] Rodar `.claude/hooks/guarda-constituicao.mjs` sobre a migração nova
- [ ] T112 [F1] Trocar o front para gravar e ler o responsável como usuário, em `../nexclin-lovable/src/`. **Migração antes do front, sempre**
- [ ] T113 [F1] Procurar as telas irmãs que mostram responsável antes de fechar. **O padrão que se repetiu cinco vezes nesta base é conserto aplicado a uma tela e não às outras**
- [ ] T114 [F1] Gate de tipos com `npx tsc --noEmit -p tsconfig.app.json`. `npm run build` não confere tipos
- [ ] T115 [F1] Publicar pelo procedimento de `docs/ponte/ponte-inversa.md` e rodar `scripts/ponte.sh conferir`
- [ ] T116 [F1] Procurar marcador de texto da tela nova dentro do bundle publicado, porque o Publish da Lovable publica o preview e não o commit
- [ ] T117 [F1] Aceite na tela: atribuir tarefa a um usuário, conferir no banco, e conferir que nenhum nome antigo sumiu

**Ponto de conferência:** o responsável passa a ser referência, e o texto antigo
continua recuperável.

---

## Fase 2 · Prazo, atraso e foto · FR-010 e FR-011

**Objetivo:** o que faz o olho do médico brilhar, e é a metade barata.

**Aceite independente:** prova 7 na tela.

- [ ] T118 [F2] Exibir a **contagem de dias** de atraso no card, e não só cor. **Converter `due_date` e `completed_at` com `::date` nos dois lados**: Postgres não define `timestamptz + integer`, e isso já custou tempo
- [ ] T119 [P] [F2] Exibir a foto do responsável no card, usando `20260827010000_foto_de_perfil.sql`, que já existe. Depende de T112
- [ ] T120 [P] [F2] Tratar o caso sem foto, que existe e é comum: iniciais ou avatar neutro, e nunca espaço vazio
- [ ] T121 [F2] Aplicar os dois às telas irmãs de tarefa, e não só à lista principal
- [ ] T122 [F2] Gate de tipos, publicar, e conferir o marcador no bundle
- [ ] T123 [F2] **Prova 7** na tela: tarefa vencida há três dias mostra o número 3
- [ ] T124 [F2] Validação pela ótica de quem usa, e não pela do backend. **É o que fecha os 200%** desta entrega
- [ ] T125 [F2] Item que não deu para provar na tela fecha como **"código lido, não comportamento provado"** e continua aberto

**FIM DA ENTREGA 1.** É o que vai ao cliente em 08/09.

---

# PORTÕES

## PORTÃO 1 · Papel é entidade nova ou o `app_role` que já existe?

Bloqueia a Fase 4.

- [ ] T126 Levar ao Arthur os dois lados: `app_role` custa quase nada e resolve as rotinas de hoje; entidade nova permite papel por clínica e custa uma tabela mais RLS. **Registrar que papel não é ModuleKey**, para não repetir a confusão que a regra 019 achou nos quatro papéis do painel

## PORTÃO 2 · A janela de cumprimento é instante ou intervalo?

Bloqueia a Fase 3.

- [ ] T127 Levar ao Arthur o caso de cada lado: "ligar para o lead no dia 3" é um dia, "conferir o caixa toda segunda" é uma janela. **Se for intervalo, a tabela de rotina precisa de início e fim**, e isso muda a Fase 3 antes de ela começar

## PORTÃO 3 · O checklist de rotinas do Vinícius

Bloqueia a Fase 5. **É insumo, não decisão.**

- [ ] T128 Cobrar o checklist, e perguntar junto **quantas rotinas são**: cinco cabem na tela de configuração, cinquenta exigem importação, que é outra tarefa
- [ ] T129 Registrar em qual dia chegou, e o que ele mudou na modelagem da rotina

---

# ENTREGA 2, stack nova

## Fase 3 · O motor · FR-001, FR-002, FR-003, FR-009

**Depende do portão 2.**

**Aceite independente:** provas 3, 4 e 6. A prova 3 é a que separa este produto
do mercado.

- [ ] T130 [F3] Modelar a tabela de **rotina** e escrever a migração: título, tipo, periodicidade, janela, papel responsável e ativa. **Entidade própria**, e não campo dentro da tarefa, com RLS por `clinic_id` e default deny
- [ ] T131 [F3] **FR-001**: acrescentar a `tasks` a coluna que aponta para a rotina que gerou a instância, indexada, e nula para tarefa manual
- [ ] T132 [F3] **FR-002 e FR-003**: acrescentar a `tasks` a coluna de **competência**, o dia da rotina a que a instância se refere, distinta de `due_date`
- [ ] T133 [F3] Criar o **índice único por rotina mais competência**. A idempotência mora no banco: trava no banco não depende de quem chama, e o job vai rodar mais de uma vez por dia
- [ ] T134 [F3] Escrever o teste do gerador de instâncias em `lib/`, **antes** do gerador, e vê-lo falhar
- [ ] T135 [F3] Escrever o gerador, materializando **na data, por agenda**, e nunca ao concluir a anterior
- [ ] T136 [F3] Decidir e implementar o disparo periódico. **A PRECISAR DE ESCLARECIMENTO no plano:** `pg_cron`, Edge Function agendada, ou geração sob demanda na leitura. Registrar a escolha e o porquê
- [ ] T137 [F3] **FR-009**: garantir que mudar a rotina não altera instância já gerada. Instância que muda depois do fato torna o cumprimento infalsificável
- [ ] T138 [F3] **Prova 3**: criar rotina diária, **não cumprir por três dias**, e conferir que existem **três** instâncias vencidas. Se existir zero, o motor está materializando ao concluir e o requisito falhou
- [ ] T139 [F3] **Prova 4**: rodar o job duas vezes no mesmo dia. A segunda não cria instância
- [ ] T140 [F3] **Prova 6**: mudar o título da rotina e conferir que a instância já gerada não muda

**Ponto de conferência:** rotina não cumprida deixa rastro, e é isso que torna
cumprimento mensurável.

## Fase 4 · Papel · FR-004

**Depende do portão 1 e da Fase 3.**

- [ ] T141 [F4] Implementar a atribuição da rotina a papel, conforme a decisão do portão 1
- [ ] T142 [F4] Resolver o papel para pessoa **no momento em que a instância é gerada**, e gravar o resultado na instância
- [ ] T143 [F4] **Prova 5**: trocar a pessoa do papel e gerar a instância seguinte. A nova aponta para a pessoa nova, **e a antiga continua apontando para a antiga**

## Fase 5 · A tela da manhã · FR-012

**Depende das fases 3 e 4, e do portão 3 para ter o que mostrar.**

- [ ] T144 [F5] Construir a tela que **abre na rotina do dia**, e não num quadro vazio à espera de que alguém escreva card
- [ ] T145 [P] [F5] Exibir a taxa de cumprimento por rotina, sobre as instâncias que deveriam existir. **O denominador vem do FR-003**, e não da contagem de linhas existentes
- [ ] T146 [F5] Aceite pela ótica de quem usa: uma pessoa que nunca viu o sistema abre a tela e sabe o que fazer primeiro

## Fase 6 · Comentário, subtarefa e permissão · FR-006, FR-007, FR-008

Independentes entre si e do motor.

- [ ] T147 [P] [F6] **FR-006**: modelar a tabela de comentário de tarefa, com autor, texto e hora, com RLS e default deny
- [ ] T148 [P] [F6] **FR-007**: acrescentar a `tasks` a coluna de tarefa pai, para subtarefa
- [ ] T149 [F6] **FR-008**: trocar as policies de `tasks` por policies separadas por operação, consultando `my_permission('tarefas')`
- [ ] T150 [F6] Escrever a reversão palavra por palavra abaixo de cada bloco de policy
- [ ] T151 [F6] Rodar o agente `auditor-multitenant` sobre a migração, **tentando furar a cascata** e não só lendo
- [ ] T152 [F6] Achado de nível alto do auditor vira issue própria antes de a fase fechar
- [ ] T153 [F6] **Prova 2** completa, com as duas metades: módulo negado volta zero linha, módulo liberado volta linha

## Fase 7 · Fechamento

- [ ] T154 [P] [F7] Atualizar `docs/regras/README.md` com o estado real da regra 022
- [ ] T155 [P] [F7] Rodar `/speckit-analyze` sobre regra, plano e tarefas, e resolver o que ele apontar
- [ ] T156 [F7] Escrever o handoff do dia, com o que ficou aberto dito em voz alta

---

## Dependências e ordem

### Entre fases

- **F0** não depende de nada e bloqueia todo o resto.
- **F1** depende de F0. **É a dobradiça**: F2, F4 e F5 dependem dela.
- **F2** depende de F1. **Aqui fecha a Entrega 1.**
- **PORTÃO 1** bloqueia F4. **PORTÃO 2** bloqueia F3. **PORTÃO 3** bloqueia F5.
- **F3** depende do portão 2 e de F0.
- **F4** depende do portão 1 e de F3.
- **F5** depende de F3, F4 e do portão 3.
- **F6** é independente do motor, e depende só de F0.
- **F7** depende do que tiver sido feito.

### Dentro de cada fase

- Migração antes de front. Sempre.
- Reversão escrita antes de aplicar bloco em produção.
- Teste antes do código, e visto falhar, onde houver teste.
- Aceite na tela antes de fechar a fase.

### O que roda em paralelo

- T101 e T102 escrevem em paralelo, e **rodam em série no editor**.
- T119 e T120 são o mesmo componente e a mesma passada.
- T147 e T148 são objetos independentes.
- **F6 pode andar em paralelo com F3**, porque não toca a rotina. É a única
  paralelização real desta frente.

**O que NÃO roda em paralelo:** nada da Entrega 1 com nada da Entrega 2. As duas
mexem em `tasks`, e a plataforma tem um Publish só. Antes de tentar, ler
`nx-paralelo`.

---

## Estratégia de entrega

### O que precisa estar de pé em 08/09

**Fase 0, Fase 1 e Fase 2.** São 26 tarefas, das quais 4 são aceite na tela.

1. F0 inteira. Se a premissa 1 cair aqui, o resto muda antes de custar trabalho.
2. F1, e o cuidado dela é o dado: **nenhum nome antigo pode sumir**.
3. F2, que é a metade barata e a que o cliente vê.
4. **PARAR e validar** pela ótica de quem usa. É o que fecha os 200%.

### Depois de 08/09

Os três portões, que são conversa e não implementação. Depois F3, que é o
produto, e F6 em paralelo com ela.

**O que não se corta por prazo, e o plano registra:** a materialização por
agenda. Cortar isso transforma o produto no nono gerenciador de tarefas
genérico, e a pesquisa mediu que os outros oito já existem há mais tempo.

---

## Notas

- Commit por tarefa ou por grupo lógico, e a mensagem registra **o porquê**.
- Mudança de comportamento corrige a regra no mesmo commit, alínea (l).
- Parar em ponto de conferência é legítimo. Atravessar portão não é.
