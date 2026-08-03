# NexClin

Plataforma operacional inteligente para gestão de clínicas médicas e
odontológicas: agenda e consultas, pacientes e anamnese, CRM e funil de
captação, financeiro completo (contas, fluxo de caixa e repasse
profissional), relatórios, insights de IA com metodologia real de gestão
clínica, e painel Super Admin multi-tenant para operação do SaaS.

## Pré-requisitos

- Node.js 18 ou superior
- Conta e projeto no Supabase (PostgreSQL gerenciado)
- Supabase CLI (`npm i -g supabase`)
- pnpm ou npm como gerenciador de pacotes

## Configuração do ambiente

Copie o arquivo de exemplo e preencha as variáveis:

```bash
cp .env.example .env.local
```

| Variável | Descrição |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | URL do projeto Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Chave pública (anon) do projeto |
| `SUPABASE_SERVICE_ROLE_KEY` | Chave administrativa — apenas scripts/server, jamais no cliente |
| `SUPERADMIN_EMAIL` | E-mail do operador Super Admin (seed) |
| `RESEND_API_KEY` | Chave do Resend (e-mails transacionais — a partir da SPEC 003) |

> **Regra do projeto:** nenhuma credencial é commitada. `.env.local` está no
> `.gitignore`; senhas vivem exclusivamente em gerenciador de senhas.

## Banco de dados

Vincule o projeto e aplique as migrações (56 herdadas do MVP validado +
novas):

```bash
supabase link --project-ref <ref-do-projeto>
supabase db push
```

Rode o seed idempotente (plano Trial Padrão, saas_settings e operador
Super Admin):

```bash
npx tsx scripts/seed.ts
```

O seed cria o usuário Super Admin com senha aleatória descartada — a senha
real é definida pelo operador via recuperação de senha no painel do
Supabase (Authentication → Users → send recovery).

## Servidor de desenvolvimento

```bash
npm run dev
```

Acesse `http://localhost:3000`. Painel administrativo em `/superadmin`.

## Testes

```bash
npm test
```

## Usuários do seed

| E-mail | Perfil | Observação |
|---|---|---|
| valor de `SUPERADMIN_EMAIL` | Super Admin | Acesso ao painel `/superadmin`; senha via recovery |
| criados sob demanda em dev | Clínica / equipe | Use o fluxo de onboarding + convites (SPEC 005); nada de senha fixa versionada |

## Stack técnica

| Camada | Tecnologia |
|---|---|
| Framework | Next.js 15 (App Router) |
| Linguagem | TypeScript (strict) |
| Banco de dados | PostgreSQL (Supabase) com RLS multi-tenant |
| Autenticação | Supabase Auth |
| Funções de servidor | Supabase Edge Functions |
| Validação | Zod |
| Estilização | Tailwind CSS + shadcn/ui |
| E-mail transacional | Resend |
| Testes | Vitest |
| Lint | ESLint |
| Hospedagem | Vercel |
| Método | SDD — GitHub Spec Kit + Claude Code |

## Como o desenvolvimento funciona

- **`CLAUDE.md`** — contexto permanente do projeto (história, regras
  inegociáveis, arquitetura).
- **`ROADMAP-SPECS.md`** — mapa das specs por setor, com etapas e tasks.
- **`WORKFLOW-GITHUB.md`** — governança de branches, issues, PRs e merge.
- **`specs/`** — uma pasta por spec; cada feature nasce de spec aprovada
  (`/speckit.specify` → `/plan` → `/tasks` → `/analyze` → `/implement`).
- Toda spec fecha com critérios de aceite executados manualmente:
  **implementado ≠ funciona**.

## Segurança

Multi-tenant isolado por RLS no banco (não na tela), default deny em
permissões, trilha de auditoria de ações administrativas, soft delete em
dados sensíveis (SPEC 004) e conformidade LGPD como requisito de
arquitetura. Vulnerabilidades: reporte em privado para o mantenedor.
