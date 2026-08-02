# CLAUDE.md — Contexto permanente do projeto NexClin

> Este arquivo é lido a cada sessão. Ele define **o que é o NexClin**, a **arquitetura-alvo**, as **regras inegociáveis** e o **método de trabalho**. Em caso de conflito entre uma instrução pontual e uma regra inegociável abaixo, **a regra prevalece** — pare e explique.

---

## O que é o NexClin

SaaS de **gestão para clínicas médicas e odontológicas**, **multi-tenant**, com **dados sensíveis de saúde** sujeitos à **LGPD**. Cada clínica é um inquilino isolado; usuários pertencem a uma clínica via `profiles.clinic_id`. Há uma camada de **Super Admin** (operações do SaaS: planos, assinaturas, faturamento, cupons, métricas, auditoria e **impersonação/suporte** para acessar uma clínica).

O comportamento validado vive no MVP de referência `../nexclin-lovable` (React+Vite+Supabase, exportado do Lovable). Este repositório (`nexclin-sdd`) é a **casa do produto real**, reescrito com qualidade e método. O inventário completo da referência está em [`INVENTARIO.md`](INVENTARIO.md).

---

## Arquitetura-alvo

- **Frontend/App:** Next.js (App Router) + **TypeScript estrito**.
- **Backend/Dados:** **Supabase próprio** (Postgres + Auth + Storage + Edge Functions), com **RLS** como fronteira de segurança primária.
- **Autorização:** decidida **no banco** — `my_permission(module)` faz a cascata `superadmin → status da assinatura → enabled_modules do plano → permissão individual → default deny`. O frontend apenas **consome** (`can()` espelha essa ordem para UX; nunca a substitui).
- **Multi-tenant:** âncora `clinic_id` em `profiles`; toda tabela de negócio isolada por RLS; impersonação do superadmin troca temporariamente o `clinic_id` do próprio perfil (auditada).
- **Migrações:** versionadas em `supabase/migrations/`, aplicadas via Supabase CLI, em ordem.
- **Método:** **Spec-Driven Development** (ver abaixo).

---

## Regras inegociáveis

**(a) RLS em toda tabela com `clinic_id`.** Nenhuma tabela de negócio existe sem Row Level Security habilitada e política que isole por `clinic_id` (via `get_my_clinic_id()`). Cross-tenant é impossível para usuário `authenticated` comum.

**(b) Default deny em permissões.** Toda resolução de permissão retorna negação por ausência. `my_permission` termina em `'none'`; jamais fail-open. (No MVP houve um intervalo fail-open corrigido — no repo novo é default-deny desde a primeira migração.)

**(c) Segurança mora no banco, nunca só na tela.** Guards de rota e menus são conveniência de UX. A autoridade é RLS + funções SECURITY DEFINER. Nenhuma regra de acesso pode existir apenas no frontend.

**(d) Toda ação administrativa sobre dado de cliente gera auditoria.** Ações de operador/admin sobre dados de clínica/paciente escrevem trilha imutável (`superadmin_audit_log` e/ou `account_timeline`), com `previous_state`/`new_state` quando aplicável. Impersonação, edição de perfil, troca de e-mail e reset de senha são sempre auditados.

**(e) Senha de cliente jamais é definida por admin — só reset por e-mail.** Nenhuma ação administrativa define senha de terceiros. O único caminho é `resetPasswordForEmail`. (A action `set_password` do MVP **não** é portada como fluxo normal — se existir, apenas como break-glass auditado e fora do produto.)

**(f) As 15 ModuleKeys são o contrato de módulos.** Fonte única e imutável sem spec:
`dashboard, leads, pacientes, anamnese, consultas, acompanhamento, tarefas, contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas, relatorios_demais, configuracoes, equipe, insights`.
`plans.enabled_modules` é `Record<ModuleKey, boolean>`. Qualquer mudança nesse conjunto exige spec aprovada.

**(g) Nenhuma credencial em código ou arquivo versionado.** Sempre variáveis de ambiente (`.env.local` fora do git; `.env*` no `.gitignore`). Isso vale até para URL/anon key. Service role key **nunca** no bundle do app — apenas em scripts/functions server-side. O script de seed **nunca** recebe senha por variável ou código.

---

## Regra de método (SDD)

- **Nenhuma feature sem spec aprovada.** Toda mudança de comportamento nasce como spec em `specs/NNN-nome.md`, seguida de um plano em fases; cada fase só é implementada **após aprovação explícita** do responsável.
- **`../nexclin-lovable` é referência SOMENTE LEITURA.** Jamais editar nada nela. Lê-se para extrair **lógica de negócio** (não estilo) e paridade de comportamento.
- **Portar do estado final consolidado**, não replicar cegamente a história de migrações do MVP (que contém passos destrutivos/QA). Ver `INVENTARIO.md` §5.4.
- **TypeScript estrito** e **testes mínimos** obrigatórios por fase quando a fase toca acesso: guards de rota e o hook de permissões.
- Trabalho pendente e dependências externas (ex.: `generate-insights` / gateway de IA) ficam registrados em `specs/BACKLOG.md`.

---

## Convenções operacionais

- Migrações limpas a partir do schema final; adicionar FKs faltantes e unicidade de catálogos identificados no inventário.
- Não portar `seed_superadmin_operator` com e-mail fixo — seed do superadmin é via `scripts/seed.ts` dirigido por `SUPERADMIN_EMAIL`.
- Confirmar decisões abertas do inventário (§5.4) na spec correspondente antes de implementar.
