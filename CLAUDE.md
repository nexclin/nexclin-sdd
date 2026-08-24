# CLAUDE.md — Contexto Completo do Projeto NexClin

> **O que é este arquivo:** a memória permanente do projeto para o Claude Code.
> Lido no início de toda sessão. Contém o que é o NexClin, tudo que já foi
> construído e validado, por que a arquitetura mudou, as regras inegociáveis
> e o plano do banco de dados. Atualizado em 20/08/2026.

---

## 1. O QUE É O NEXCLIN

SaaS de gestão para clínicas médicas e odontológicas — uma **plataforma
operacional inteligente**, não um sistema de cadastros. Critério que valida
toda funcionalidade: aumentar receita, reduzir custo, economizar tempo ou
melhorar decisão da clínica. O diferencial estratégico é embarcar metodologia
real de gestão clínica como inteligência do produto (IA proativa com
recomendações), não competir feature a feature com sistemas genéricos
(iClinic, Feegow, Clinicorp etc.).

**Sociedade:** Arthur Hideo (operacional/desenvolvimento — interlocutor deste
repositório) · Erick (estruturação da empresa e go-to-market) · mentor de
gestão clínica (conhecimento de domínio + canal de distribuição).

**Prazo vivo (revisado em 20/08/2026):** **01/09/2026** abre para um grupo de
**clientes fundadores, em uso gratuito**, na plataforma Lovable — não são
assinantes, e a plataforma é temporária. A stack deste repositório assume em
**outubro**. Escopo: fundação + os módulos que o fundador usará de fato. **O
que se corrige até lá segue o critério da §2.5, não o instinto de deixar
perfeito.**

**Mercado/regulatório:** dados sensíveis de saúde → LGPD é requisito de
arquitetura, não feature. Futuro do roadmap: prontuário (assinatura digital /
SBIS-CFM), TISS para convênios, NFS-e, WhatsApp para confirmação de agenda.

---

## 2. HISTÓRIA — DE ONDE VIEMOS

### 2.1 MVP no Lovable (concluído como referência)
O MVP foi construído no Lovable (Lovable Cloud = Supabase gerenciado).
Contém: dashboard com faturamento, agenda/consultas, pacientes, leads/
atendimentos, anamnese (com endpoint público), financeiro (contas a pagar/
receber, fluxo de caixa), relatórios, insights de IA, gestão de equipe com
permissões granulares, e um **painel Super Admin completo** (detalhado em §3).

### 2.2 Por que saímos do Lovable
O modelo de créditos inviabilizou o desenvolvimento: 60 créditos (~R$100)
foram consumidos numa única funcionalidade (superadmin). Features reais de
SaaS custam 30-60 créditos; terminar o produto custaria R$400-800+/mês,
crescendo com o ritmo. Decisão (jul/2026): migrar para estrutura própria de
custo fixo.

### 2.3 A stack nova (este repositório)
**Next.js (App Router) + TypeScript + Supabase próprio (Postgres + Auth +
RLS + Edge Functions) + Claude Code (plano Max) + SDD via GitHub Spec Kit.**
- Custo dev: ~R$0/mês · Custo com clientes: ~R$250-270/mês (Supabase Pro
  US$25 + Vercel Pro US$20 + domínio), previsível.
- E-mail transacional definitivo: **Resend** (o SMTP embutido não entrega —
  limitação já comprovada em teste).
- `../nexclin-lovable` = clone do repositório ao vivo da plataforma
  (`nexclin/nexclin`), usado para **ler as regras de negócio** e, desde
  17/08/2026, também como área de trabalho da **ponte inversa** que leva
  correção a produção sem consumir crédito. Ver a regra (i) em §4 e
  `docs/ponte/ponte-inversa.md`. *(Até 17/08 este caminho era descrito como
  "export do MVP, somente leitura" — o texto ficou para trás; o diretório
  passou a ser editável por desenho.)*

### 2.4 Por que essa arquitetura é a certa
1. **Segurança mora no banco:** RLS multi-tenant no Postgres — bug de
   aplicação não vaza dado de outra clínica. Essencial para saúde/LGPD.
2. **Nada validado foi jogado fora:** o banco inteiro (55 migrações) migra
   intacto; reescreve-se só a camada de aplicação, a de menor qualidade
   gerada pelo Lovable.
3. **Independência de fornecedor:** código no GitHub, banco no Supabase,
   hosting na Vercel — qualquer peça é trocável.
4. **Custo previsível:** desenvolver mais não custa mais.

### 2.5 A plataforma Lovable é ponte, não destino — e isso decide o que se corrige

> **Leia isto antes de aceitar qualquer pedido de correção na plataforma ao
> vivo.** Registrado em 20/08/2026, decisão do Arthur. Substitui o critério
> anterior de "zerar todos os bugs que atrapalham antes de abrir".

**A situação.** A plataforma no Lovable entra no ar em 01/09/2026 para um grupo
de **clientes fundadores, em uso gratuito**. Ela é **temporária**: vive cerca de
um mês, até fechar os 30 dias desses fundadores. A stack Next.js deste
repositório deve substituí-la em **outubro/2026**, numa transição gradual a
partir de meados de setembro.

**O compromisso com o fundador** é entregar o que foi prometido — um software de
gestão em lançamento, com os problemas de um lançamento. **Não precisa ser
perfeito.** O que não pode é decepcionar: ele tem de conseguir operar a clínica.

**O critério de correção, em uma frase:** corrigir na plataforma só vale quando
a correção **atravessa** para a stack nova. Fora disso é polir o que será
descartado.

**A consequência que se esquece com facilidade:** na maioria dos casos o que
atravessa **não é o código — é a regra escrita**. O front React/Vite do Lovable
será reescrito em Next.js de qualquer jeito. O que sobrevive é a decisão de
*como o sistema deve se comportar*. **Escrever a regra é a entrega; implementar
na Lovable é opcional.**

Três faixas, para triar qualquer apontamento novo:

| Faixa | Pergunta | Ação |
|---|---|---|
| **A — atravessa como banco** | É migração, RLS, trigger, coluna, regra de recebível? | **Corrigir.** As migrações vão intactas para a stack nova (§2.4). Aqui o código é o artefato durável. |
| **B — atravessa como regra** | Depende de uma regra que a stack nova também vai precisar? | **Escrever a regra**, datada, em `docs/planejamento/` ou na spec do módulo. Implementar na Lovable só se o fundador esbarrar no uso. |
| **C — não atravessa** | É front, layout, mensagem, comportamento de tela? | **Não corrigir.** Vira requisito da stack nova. Exceção única: se impedir o fundador de usar o que foi prometido. |

**Corolário sobre backlog:** a meta é a stack nova nascer **sem bug e sem
backlog**. Então item de backlog não é trabalho adiado — é **requisito da stack
nova**, e deve entrar na spec do módulo correspondente em vez de dormir numa
lista.

**A régua fina: DADO atravessa, CÁLCULO DE TELA não.** Decidido em 20/08 pelo
Arthur, e é o que torna a §2.5 utilizável em vez de ambígua.

"Atravessa" não é só sobre código. **O banco migra intacto** (§2.4) — e com ele
vem tudo que as clínicas registrarem no mês da Lovable. O Arthur estima
**R$ 100–200 mil de faturamento** lançado por clínica nesse período. Lançamento
errado em agosto **não é descartado em outubro: é importado**.

> **Financeiro na Lovable tem de funcionar como vai funcionar na stack final.**
> Outras coisas podem passar; financeiro não.

A razão é de produto, não de engenharia: gestão financeira é o diferencial que
as clínicas não têm, e é por ele que o NexClin foi vendido. Entregar número
errado justamente aí destrói o argumento de venda.

**Como aplicar, item a item:** pergunte *o que fica gravado?*
- Muda o que é **persistido** — valor, data, atribuição, a qual conta pertence?
  → **faixa A. Corrigir.** O erro migra.
- Muda só **como a tela soma ou exibe** o que já está gravado certo?
  → faixa B. A regra escrita basta; a stack nova calcula certo desde o começo.

Exemplo do próprio lote: V-18 e V-20 (a entrada abate a consulta ou a
prescrição) mudam **atribuição gravada** — atravessam, corrigem-se. V-13 e V-21
(ticket médio, taxa de conversão no dashboard) são **cálculo sobre dado que já
está certo** — a regra basta.

**A exceção da faixa C tem um nome, e ele é RELATÓRIO.** Em 20/08 o Vinícius
foi explícito: o time dele **não usa o dashboard** — puxa as bases pelos
**relatórios**, toda semana, e decide em cima delas. Relatório errado vira
decisão errada e perda para a clínica. Logo, **os relatórios não são faixa B:
têm de funcionar em 01/09**, mesmo sendo a plataforma temporária. É o caso
literal de "impedir o fundador de usar o que foi prometido". Dashboard, ao
contrário, foi rebaixado — é "visão simples pro médico", nas palavras dele.

Regra de bolso que sai daí: **antes de classificar em faixa, pergunte por onde
o cliente realmente opera.** A intuição de quem constrói (dashboard é a cara do
produto) não bateu com a de quem usa (a cara é o relatório).

**Onde isso já está aplicado:** `docs/planejamento/triagem-baterias-18-19.md`
(33 apontamentos das baterias do Vinícius, classificados nas três faixas, com as
decisões de regra datadas). É o modelo para triar a bateria do Erick e o que
vier depois.

---

## 3. O QUE JÁ FOI CONSTRUÍDO E VALIDADO (no MVP de referência)

Método usado: **Construção Guiada** — cada etapa fecha somente com teste
funcional real ("implementado ≠ funciona"). Tudo abaixo está nas 55
migrações de `../nexclin-lovable/supabase/migrations` (verificado: zero
drift, nenhum objeto órfão) e nas 4 edge functions.

### 3.1 Modelo multi-tenant
- **Âncora:** `profiles.clinic_id` define a clínica do usuário logado.
- **37 tabelas de negócio** com coluna `clinic_id` + RLS (padrões: subselect
  em profiles, ou `get_my_clinic_id()` SECURITY DEFINER). Tabelas globais:
  `clinics, plans, coupons, saas_settings, superadmin_operators, user_roles`.
- **Trava estrutural:** trigger `prevent_clinic_id_change` — só superadmin
  (ou service role) altera a âncora. Fechou brecha crítica real: usuário
  podia trocar o próprio clinic_id e ver dados de outra clínica.
- `profiles.user_id` é UNIQUE; INSERT em profiles não tem política pública
  (perfis nascem só pelo trigger `handle_new_user`). Testado: INSERT
  malicioso → bloqueado por RLS.

### 3.2 Papéis e permissões (3 camadas)
1. `user_roles` (enum `app_role`: admin, medico, secretaria, user) — papel
   global; `has_role()` calcula is_admin.
2. `team_members` — papel operacional na clínica: `permission_level`
   (master/gerencial/operacional/configuravel) + `permissions` jsonb por
   módulo. Repasse médico: modelo, percentual, base de cálculo.
3. `superadmin_operators` — nível SaaS, fora das clínicas.

**Contrato de módulos (15 ModuleKeys oficiais):** dashboard, leads,
pacientes, anamnese, consultas, acompanhamento, tarefas, contas_receber,
contas_pagar, fluxo_caixa, relatorios_vendas, relatorios_demais,
configuracoes, equipe, insights.

**Resolução de acesso — função `my_permission(_module)`, cascata testada:**
superadmin → full sempre; assinatura suspended/cancelled → none; módulo
false/ausente em `enabled_modules` do plano → none; admin da clínica → full;
senão permissão individual do team_member; **fallback: none (default deny)**.
Regra de ouro: *o plano é o teto; a permissão individual distribui abaixo
do teto; permissão individual nunca excede o plano.*

### 3.3 Planos e assinaturas
- `plans` (preços, trial_days, max_users/max_patients/max_leads_month —
  NULL = ilimitado, `enabled_modules` jsonb validado por trigger contra as
  15 chaves), `account_subscriptions` (status enum: trial, active, overdue,
  suspended, cancelled), `coupons`, `saas_settings` (singleton), `billings`,
  `account_timeline`.
- Limite de usuários aplicado por trigger em team_members
  (`clinic_within_user_limit`, comparação estrita `<` — bug off-by-one foi
  encontrado em teste e corrigido: deixava entrar 1 acesso a mais).
- Trial vencido NÃO suspende sozinho (decisão registrada) — suspensão é ato
  manual do superadmin; automação de cobrança é backlog.

### 3.4 Super Admin (funcionalidade completa e testada)
- Identidade própria (`superadmin_operators`) + login separado
  (/superadmin/login) + guard próprio. `is_superadmin()` consultada pelo
  banco em toda operação.
- **Impersonação ("Acessar conta"):** funções `superadmin_enter_clinic` /
  `superadmin_exit_clinic` / `get_my_active_impersonation` — troca auditada
  da âncora clinic_id, com tabela de sessões (entrada/saída), troca
  automática entre clínicas, escrita total dentro da conta. UI: banner âmbar
  fixo "Modo suporte — <clínica>" em todas as rotas + sair; cache zerado a
  cada troca; onboarding não dispara sob impersonação. Usuário comum
  invocando → 'Acesso negado' (testado).
- **Gestão de clínicas:** CRUD completo (políticas próprias).
- **Edição de perfis de clientes:** política de UPDATE + trigger de
  auditoria com diff old→new (auto-edição não audita) + edge function
  `superadmin-manage-user`: `update_email` (auditado, com confirmação) e
  `send_password_reset` (via resetPasswordForEmail). **Nenhuma action
  define senha — jamais.**
- **Auditoria:** `superadmin_audit_log` — impersonation_start/end,
  profile_edit, email_change, password_reset_sent.
- Telas do painel: contas (lista/detalhe), planos, cupons, faturamento,
  métricas, comunicação, logs, operadores, configurações.
- Telas do app reagem ao plano: menu esconde módulos fora do plano, URL
  direta bloqueia, tela de conta suspensa, contador "Acessos: X de Y".

### 3.5 Edge functions (4, na referência)
| Function | Papel | Destino |
|---|---|---|
| superadmin-manage-user | e-mail/reset com guarda dupla | **portada** (T013, Fase 3) — só `update_email` e `send_password_reset`; `set_password` removida |
| invite-team-user | convida por link; o convidado define a própria senha | portada (Fase 3) e **reescrita no T017 da SPEC 002** (20/08) — o caminho que aceitava `password` do admin foi removido aqui **e** na plataforma ao vivo |
| anamnesis-public | endpoint público de anamnese | backlog |
| generate-insights | insights via gateway de IA do Lovable | backlog (re-especificar com API própria) |

### 3.6 Ressalvas e pendências herdadas
- Envio real de e-mail não funciona no ambiente antigo (SMTP embutido) —
  código validado; entrega definitiva = Resend nesta estrutura.
- Etapa 3c-2 (tela de edição de perfis) pode ter fechado no Lovable após o
  export — conferir paridade ao ler a referência.
- Conta-mestra: e-mail erpclinicas@gmail.com se mantém; a senha antiga está
  QUEIMADA (exposta em chat) — nova senha só via reset manual no painel do
  Supabase, vive no gerenciador de senhas.

---

## 4. REGRAS INEGOCIÁVEIS (valem para todo código deste repo)

(a) RLS em TODA tabela com clinic_id — sem exceção.
(b) Default deny: o que não é explicitamente concedido, é negado.
(c) Segurança mora no banco; a tela apenas reflete. Nenhuma regra de acesso
    pode existir só no frontend.
(d) Toda ação administrativa sobre dado de cliente gera auditoria
    (quem, o quê, quando, old→new).
(e) Senha de cliente jamais é definida por admin — somente reset por e-mail.
(f) As 15 ModuleKeys são o contrato único de módulos (planos, permissões,
    telas usam as mesmas strings).
(g) Nenhuma credencial em código, spec ou arquivo versionado — sempre
    variáveis de ambiente (.env.local, fora do git).
(h) Método SDD: nenhuma feature sem spec aprovada em specs/. Executor gera
    plano por fases e PARA para aprovação humana antes de cada fase.
(i) `../nexclin-lovable` **mudou de papel** — leia antes de editar. Era o
    export do MVP, somente leitura. Desde a criação da ponte inversa
    (`scripts/ponte.sh`), é o **clone do repositório ao vivo da plataforma**,
    no mesmo caminho, e É EDITÁVEL — é por ele que a correção chega ao
    cliente. O que continua proibido é editar ali **fora do procedimento**:
    só bug, conserto mínimo, `git pull` antes, `main` sempre, nunca
    `--force`, e a ordem obrigatória **function antes do Publish do front**.
    Procedimento em `docs/ponte/ponte-inversa.md`.
(j) "Implementado ≠ funciona": toda fase fecha com critérios de aceite
    executados manualmente por Arthur.
(k) TypeScript estrito; testes automatizados mínimos em guards e permissões.

---

## 5. PLANO DO BANCO DE DADOS (projeção)

**Fase 1 — Réplica (spec 001):** aplicar as 55 migrações da referência, em
ordem, no Supabase próprio via CLI. Exceção deliberada: não portar o trigger
de seed com e-mail fixo (seed vira script por env). Cuidado conhecido:
ALTER TYPE ... ADD VALUE fora de transação. Verificação: relatório
comparando schema aplicado × referência (43 tabelas + globais, RLS, funções,
triggers, enums) — divergência = parar.

**Fase 2 — Seeds (spec 001):** script idempotente (service role): plano
Trial Padrão (15 módulos true, limites NULL, hidden), saas_settings,
usuário superadmin por SUPERADMIN_EMAIL com senha aleatória descartada +
registro em superadmin_operators. Rodar 2x sem duplicar.

**Depois da fundação:**
- Novas migrações SEMPRE neste repo (supabase/migrations), nunca à mão no
  painel — o repositório permanece fonte de verdade do schema.
- Resend integrado ao auth (convites, reset) — reteste de entrega ponta a
  ponta obrigatório.
- No primeiro cliente real: Supabase Pro NO MESMO DIA (backup diário; o
  tier grátis pausa em 7 dias e não tem backup) + apontar domínio.
- Backlog de banco: automação de cobrança/suspensão (saas_settings já tem
  os parâmetros), retenção/expurgo LGPD, e specs próprias por módulo de
  negócio (agenda, financeiro, CRM/recall — cada um com suas tabelas já
  existentes na réplica).

---

## 6. ESTADO ATUAL E PRÓXIMOS PASSOS

```
[x] MVP de referência completo (superadmin validado ponta a ponta)
[x] Export → github.com/nexclin/nexclin · clone local ../nexclin-lovable
[x] Anti-drift: 55 migrações fiéis, zero órfãos
[x] Decisão de stack + custos comunicados aos sócios
[>] SPEC 001 (specs/001-fundacao-superadmin.md): Fases 1-4 — banco,
    seeds, edge functions, app Next.js (auth + painel superadmin +
    esqueleto do app da clínica)
[ ] Critérios de aceite da SPEC 001 executados por Arthur
[ ] Senha nova da conta-mestra via reset no painel (pós Fase 2)
[x] Constitution formal do Spec Kit (.specify/memory/constitution.md, v1.0.0)
[ ] SPEC 002+ : módulos do escopo de lançamento do 1º cliente
[ ] T021 da SPEC 001 — testes de permissão em Vitest: EM ZERO, e é mínimo
    obrigatório da constituição (Princípio V)
```

### Linha do tempo viva (atualizada em 20/08/2026)

```
01/09  abre para os clientes fundadores, na plataforma Lovable, de graça
set/2  transição gradual começa
out    stack Next.js substitui a plataforma  ← o destino real
```

**Frente Lovable (temporária, ~1 mês de vida).** Ver §2.5 para o critério do
que se corrige e do que não se corrige.
- [x] T017 — `invite-team-user` sem senha de terceiro, em produção (20/08).
      Fechou a última violação conhecida da regra (e) na plataforma ao vivo.
- [ ] **Aceite manual do T017**: convidar alguém de verdade, abrir o link,
      definir senha, entrar. Até isso, é código lido, não comportamento
      provado.
- [x] Triagem das baterias do Vinícius (18–19/08): 33 apontamentos, 25 bugs,
      classificados nas 3 faixas da §2.5 →
      `docs/planejamento/triagem-baterias-18-19.md`
- [ ] Quatro perguntas devolvidas ao Vinícius, prazo 21/08 →
      `docs/planejamento/perguntas-vinicius-20-08.md`
- [ ] Bateria do Erick (24–26/08) — triar no mesmo documento, numeração E-01
      em diante já reservada
- [ ] Janela 22–23/08: faixa A da bateria + **Fase 2 da SPEC 002**, que tem
      prioridade por ser banco puro (atravessa 100%)
- [ ] **T004 da SPEC 002 é gate absoluto e assíncrono** — exportar o banco
      antes de qualquer escrita; o link chega por e-mail e só se pode
      exportar 1 vez a cada 24h. Disparar ANTES de 22/08.

> **Retomando em sessão nova?** Comece por
> `docs/planejamento/handoffs/2026-08-24-proximas-acoes.md` — é o handoff
> corrente, escrito para ser colado inteiro num chat novo. O de 20/08 continua
> valendo como histórico, mas foi superado.
>
> *(referência antiga)* `docs/planejamento/handoffs/2026-08-20-fim-do-dia.md` — ele diz o que ler, em
> que ordem, o que está publicado, o que falta, e as armadilhas do procedimento.
> A primeira ação pendente é uma consulta de segurança em `storage.objects`
> (`docs/seguranca/storage-objects-2026-08-20.md`), que só o Arthur pode rodar.

**Armadilha de procedimento aprendida em 20/08:** o Publish do Lovable **não**
redeploya edge function, e o CLI do Supabase responde **403** no projeto
gerenciado por eles. Correção que toca front + function tem de subir a
**function primeiro**. Detalhes e custo em `docs/ponte/ponte-inversa.md`.

A especificação completa da fundação, com fases, pré-requisitos e critérios
de aceite, vive em **specs/001-fundacao-superadmin.md** (fonte de verdade
da execução atual).

---

## 7. ESTRUTURA HARNESS (como este repositório dirige o Claude Code)

O desenvolvimento é guiado por uma estrutura de engenharia de harness. Cada
peça rastreia a uma falha real do projeto (princípio da catraca) — leia
**docs/harness/README.md** antes de mexer nela.

- **`.claude/hooks/guarda-constituicao.mjs`** — roda a cada escrita; bloqueia
  RLS ausente, `USING(true)`, caminho que define senha e segredo versionado.
- **`.claude/rules/{banco,app,marca}.md`** — restrições por área (`paths:`).
- **`.claude/agents/`** — auditor-multitenant, triador-apontamentos,
  consultor-vertical, relator-semanal.
- **`.claude/skills/`** — `nx-modulo` (portar um dos 15 módulos),
  `nx-ponte` (corrigir bug na plataforma Lovable até a migração).
- **`docs/dominio/`** — as 15 ModuleKeys × ondas, e os 4 verticais
  (médico ativo; psicologia/estética na fila; odonto fechado).
- **`docs/marca/tokens.md`** — paleta e tipografia da identidade.
- **`docs/seguranca/`** — revisões de segurança datadas.

A regra de bolso: "toda vez que X" → hook; restrição de área → rule;
procedimento longo → skill; trabalho paralelo → agente. A constituição
(`.specify/memory/constitution.md`) vence qualquer uma delas.
