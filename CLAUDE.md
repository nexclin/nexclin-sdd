# CLAUDE.md — Contexto Completo do Projeto NexClin

> **O que é este arquivo:** a memória permanente do projeto para o Claude Code.
> Lido no início de toda sessão. Contém o que é o NexClin, tudo que já foi
> construído e validado, por que a arquitetura mudou, as regras inegociáveis
> e o plano do banco de dados. Atualizado em 29/07/2026.

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

**Prazo vivo:** primeiros clientes assinantes previstos para ~1 mês. Escopo
de lançamento: fundação + módulos que o primeiro cliente usará de fato.

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
- `../nexclin-lovable` = export do MVP, **referência somente leitura**.
  Nada é editado lá; regras de negócio são extraídas de lá.

### 2.4 Por que essa arquitetura é a certa
1. **Segurança mora no banco:** RLS multi-tenant no Postgres — bug de
   aplicação não vaza dado de outra clínica. Essencial para saúde/LGPD.
2. **Nada validado foi jogado fora:** o banco inteiro (55 migrações) migra
   intacto; reescreve-se só a camada de aplicação, a de menor qualidade
   gerada pelo Lovable.
3. **Independência de fornecedor:** código no GitHub, banco no Supabase,
   hosting na Vercel — qualquer peça é trocável.
4. **Custo previsível:** desenvolver mais não custa mais.

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
| superadmin-manage-user | e-mail/reset com guarda dupla | portar (Fase 3) |
| invite-team-user | cria usuário convidado + vínculo | portar (Fase 3) |
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
(i) ../nexclin-lovable é somente leitura.
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
[ ] Constitution formal do Spec Kit (este arquivo é a base)
[ ] SPEC 002+ : módulos do escopo de lançamento do 1º cliente
```

A especificação completa da fundação, com fases, pré-requisitos e critérios
de aceite, vive em **specs/001-fundacao-superadmin.md** (fonte de verdade
da execução atual).
