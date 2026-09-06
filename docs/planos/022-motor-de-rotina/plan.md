# Plano de implementação: motor de rotina da clínica

**Frente:** `022-motor-de-rotina` · **Data:** 05/09/2026
**Regra:** [`spec.md`](./spec.md), que é link para
[`docs/regras/022-motor-de-rotina-da-clinica.md`](../../regras/022-motor-de-rotina-da-clinica.md)

> Gerado por `speckit-plan` sob a [ADR 0006](../../adr/0006-o-spec-kit-volta-pela-metade.md).
> **A decisão 1 da seção 7 foi respondida em 05/09**: a regra vai em duas
> entregas. As outras três continuam abertas e viram portão na seção 5.

---

## 1. Resumo

Catorze requisitos, nove deles faixa A. A regra separa em duas entregas porque
duas decisões tomadas com um dia de diferença se batiam: tarefas está na régua
dos 200% para 08/09, e o motor de rotina não cabe em três dias.

**Entrega 1, até 08/09, na Lovable:** três requisitos que a reunião pediu em voz
alta e que cabem. FR-005, FR-010 e FR-011.

**Entrega 2, na stack nova:** o motor, que é o que diferencia. FR-001 a FR-004,
mais FR-006 a FR-009 e FR-012.

**A dobradiça é o FR-005**, e é por isso que ele está na primeira: sem
responsável como referência a usuário não há foto a buscar, e não há para onde o
papel resolver. É a única coluna que as duas entregas precisam.

**O que a pesquisa de mercado mudou neste plano:** ela não trouxe uma ferramenta
para copiar, trouxe três buracos que a amostra inteira tem, e eles viraram os
requisitos 001 a 004. A consequência de plano é que a **Fase 3 não pode ser
cortada por prazo**: cortar a materialização por agenda transforma o produto no
nono gerenciador de tarefas genérico.

---

## 2. Contexto técnico

| | |
|---|---|
| **Banco** | PostgreSQL no Supabase, dois projetos: o da Lovable, ao vivo, e o da stack nova |
| **Onde se testa banco** | editor de SQL contra o banco ao vivo. Sem Docker e sem banco local |
| **Front da Lovable** | React e Vite. Gate: `npx tsc --noEmit -p tsconfig.app.json` |
| **Front da stack nova** | Next.js App Router, TypeScript estrito |
| **Agenda** | a materialização do FR-002 precisa de execução periódica. **A PRECISAR DE ESCLARECIMENTO:** `pg_cron` no Supabase, Edge Function agendada, ou geração sob demanda na leitura. Ver Fase 3 |
| **Caminho até o cliente** | ponte inversa, `docs/ponte/ponte-inversa.md` |
| **Alvo de prazo** | 08/09 só para a Entrega 1. Restam **três dias** |
| **Régua** | 200%. Tarefas é uma das duas áreas obrigadas |

**A PRECISAR DE ESCLARECIMENTO, e cada uma vira portão:**

1. Papel é entidade nova ou o enum `app_role` que já existe. Seção 7, decisão 2.
2. A janela de cumprimento é instante ou intervalo. Seção 7, decisão 3.
3. O checklist de rotinas do Vinícius, que é insumo e não decisão, e sem ele a
   tabela de rotina nasce vazia. Seção 7, decisão 4.

---

## 3. Portão constitucional

Conferido contra `docs/constituicao.md` v2.0.3.

| Alínea | O que exige | Situação |
|---|---|---|
| **(a)** | RLS em toda tabela com `clinic_id` | as três tabelas novas da Entrega 2 nascem com RLS. **Passa** |
| **(b)** | default deny | nenhuma policy nova com `USING(true)`. **Passa** |
| **(c)** | segurança no banco, tela só reflete | **VIOLAÇÃO EXISTENTE**, e ela é o FR-008. A policy de `tasks` é a original de 22/03 e não consulta `my_permission` |
| **(d)** | auditoria de ação administrativa | a instância guarda papel resolvido e a conclusão guarda hora. **Passa** |
| **(f)** | as 15 ModuleKeys são o contrato único | **nada aqui exige a décima sexta.** Tudo vive sob `tarefas`. Só o sininho da regra 020 precisaria, e ele não está neste plano |
| **(h)** | regra viva aprovada, parada humana por fase | a regra 022 existe, e cada fase para para aceite. **Passa** |
| **(j)** | implementado ≠ funciona | oito provas na seção 6 da regra. **Passa** |
| **(l)** | mudança corrige a regra no mesmo commit | o `spec.md` é link, não cópia. **Passa** |

**Nenhuma violação nova.** A única é preexistente e está nomeada como requisito.

---

## 4. Estrutura

```text
docs/planos/022-motor-de-rotina/
├── spec.md   → link para ../../regras/022-motor-de-rotina-da-clinica.md
├── plan.md   este arquivo
└── tasks.md  gerado por /speckit-tasks
```

Pelos mesmos motivos da frente 021, **não são gerados** `research.md`,
`data-model.md`, `quickstart.md` nem `contracts/`. A pesquisa está em
`docs/referencia/2026-09-05-rotinas-recorrentes-no-mercado.md`, o modelo de dado
é a seção 3 da regra, e as provas são a seção 6. Duplicar cria divergência, que é
o que a alínea (l) existe para impedir.

---

## 5. As fases, e os portões

**Cada fase termina com aceite manual**, alínea (h).

### ENTREGA 1, até 08/09, na Lovable

#### Fase 0 · Conferir antes de acreditar

Não implementa nada. Censo de `tasks` por `information_schema` e `pg_policies`,
para confirmar ou derrubar a premissa 1 da regra, e para medir o buraco do
FR-008 antes de decidir sobre ele.

**Aceite:** o resultado bate com a tabela "o que já existe" da seção 3 da regra.
**Se divergir, a divergência é o achado.**

#### Fase 1 · O responsável vira usuário · FR-005

A dobradiça. Migração acrescentando referência a usuário, mais a conversão do
texto livre que já existe em `responsible`.

**O risco desta fase, e é o maior da Entrega 1:** o dado atual é texto digitado.
Nome que não casar com usuário nenhum **MUST** ficar preservado numa coluna de
legado, e **MUST NOT** ser descartado. Perder atribuição de tarefa de cliente
real é dano que não se desfaz.

**Ordem obrigatória:** migração antes do front.

**Aceite:** provas 5 e 8 parciais, na tela.

#### Fase 2 · Prazo, atraso e foto · FR-010 e FR-011

Contagem de dias de atraso escancarada, e foto do responsável no card. Depende
da Fase 1 para a foto.

**Armadilha que morde aqui:** `due_date` e `completed_at` são `TIMESTAMPTZ`, e o
Postgres não define `timestamptz + integer`. Toda conta de atraso converte os
dois lados com `::date`.

**Divergência deliberada, e está na regra:** nenhuma fonte primária da pesquisa
exibe número de dias. Trello usa três cores, Monday condiciona ao Deadline Mode,
Process Street pinta a data. Exibir o número foi pedido literal da reunião.

**Aceite:** prova 7. Tarefa vencida há três dias mostra o número 3.

**Aqui fecha a Entrega 1.** É o que vai ao cliente em 08/09.

---

### PORTÃO 1 · Papel: entidade ou enum?

Decisão 2 da seção 7. Bloqueia a Fase 4.

- **`app_role` que já existe** (`admin`, `medico`, `secretaria`, `user`): custa
  quase nada e resolve as rotinas que a clínica tem hoje.
- **Entidade nova:** permite papel próprio por clínica, mais fiel ao "varia de
  clínica para clínica", e custa uma tabela mais RLS.

**Papel não é ModuleKey, e as duas não se misturam.** Papel diz quem executa a
rotina; ModuleKey diz quem vê o módulo. A regra 019 já achou quatro papéis de
painel que não limitavam nada, e essa confusão não se repete aqui.

### PORTÃO 2 · A janela de cumprimento é instante ou intervalo?

Decisão 3 da seção 7. Bloqueia a Fase 3.

"Ligar para o lead no dia 3" é um dia. "Conferir o caixa toda segunda" é uma
janela que a pessoa cumpre em qualquer hora. **Se for intervalo, `due_date`
sozinho não basta** e a tabela de rotina precisa de início e fim.

### PORTÃO 3 · O checklist do Vinícius

Não é decisão, é insumo, e ficou com ele na reunião de 03/09. Bloqueia a Fase 5.

Sem ele a tabela de rotina nasce vazia e o produto entrega motor sem
combustível. **Pergunta a fazer junto:** quantas rotinas são. Se forem cinco,
cabem na tela de configuração; se forem cinquenta, precisa de importação, e isso
é outra tarefa.

---

### ENTREGA 2, stack nova

#### Fase 3 · O motor · FR-001, FR-002, FR-003, FR-009

Depende do portão 2.

A tabela de rotina, o ponteiro da instância para ela, a competência, e o job de
materialização por agenda.

**Três coisas que este plano não deixa cortar por prazo**, porque são o produto:

1. A instância aponta para a rotina. Sem isso não há taxa por rotina.
2. A materialização é por agenda. **Não** ao concluir a anterior.
3. Rotina não cumprida deixa instância vencida.

**A idempotência é índice único** por rotina mais competência, no banco. Trava no
banco não depende de quem chama, e o job vai rodar mais de uma vez por dia.

**Aceite:** provas 3, 4 e 6. A prova 3 é a que separa este produto do mercado:
criar rotina diária, não cumprir por três dias, e conferir que existem **três**
instâncias vencidas. Se existir zero, o motor está materializando ao concluir e o
requisito falhou.

#### Fase 4 · Papel · FR-004

Depende do portão 1 e da Fase 3.

O papel resolve para pessoa **no momento em que a instância é gerada**, e o
resultado fica gravado na instância.

**Aceite:** prova 5. Trocar a pessoa do papel e gerar a instância seguinte. A
nova aponta para a pessoa nova, **e a antiga continua apontando para a antiga**.

#### Fase 5 · A tela da manhã · FR-012

Depende das fases 3 e 4, e do portão 3 para ter o que mostrar.

A tela abre na rotina do dia, e não num quadro vazio.

#### Fase 6 · Comentário, subtarefa e permissão · FR-006, FR-007, FR-008

Independentes entre si e do motor. O FR-008 leva o `auditor-multitenant` antes
do aceite, tentando furar a cascata em vez de só lê-la.

**Aceite do FR-008:** prova 2 **com controle positivo**. Usuário com o módulo
negado volta zero linha, e usuário com o módulo liberado volta linha. Só a
primeira metade passa por vacuidade.

---

## 6. Complexidade a justificar

| Violação | Por que existe | Alternativa mais simples, e por que não serve |
|---|---|---|
| **Alínea (c)**: acesso de `tasks` só na tela | preexistente, policy de 22/03. Nomeada como FR-008 em vez de herdada calada | deixar como está aceita que o menu é a segurança. `tasks` carrega `patient_id` |
| **Materialização por agenda**, mais cara que ao concluir | é o requisito que torna cumprimento mensurável | materializar ao concluir é o padrão de três das oito ferramentas, e faz o dia pulado sumir |
| **Duas entregas** | tarefas está na régua dos 200% para 08/09 e o motor não cabe em três dias | entregar tudo em 08/09 produziria motor não provado numa área que a reunião marcou como obrigada a 200% |

---

## 7. O que este plano deliberadamente não faz

- **Não cria tabela paralela de eventos.** FR-013. `tasks.origem` já existe.
- **Não constrói gerenciador de tarefas genérico.** FR-014.
- **Não toca a décima sexta ModuleKey.** Nada aqui precisa dela.
- **Não implementa agenda de tarefas nem painel de auditoria do time.** Foram
  citados na reunião como "a julgar depois", e continuam sem decisão.
