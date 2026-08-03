<!--
SYNC IMPACT REPORT
==================
Version change: (template) → 1.0.0
Rationale: Primeira ratificação formal. Constituição derivada das "Regras
Inegociáveis" (§4) e da filosofia de produto (§1) do arquivo claude.md
(datado 29/07/2026), agora promovidas a governança versionada do Spec Kit.

Modified principles: N/A (ratificação inicial)
Added principles:
  - I.  Segurança Mora no Banco
  - II. Privacidade e Auditoria (LGPD por Arquitetura)
  - III. Contrato Único de Módulos
  - IV. Spec-Driven Development com Parada Humana
  - V.  Segredos Fora do Código e Qualidade Verificável
  - VI. Valor Operacional Antes de Feature
Added sections:
  - Restrições Técnicas & Stack
  - Fluxo de Desenvolvimento
  - Governance

Removed sections: nenhuma
Templates requiring review:
  - .specify/templates/plan-template.md      (checar "Constitution Check")
  - .specify/templates/spec-template.md      (alinhar a princípios I-VI)
  - .specify/templates/tasks-template.md      (garantir gates de aceite manual)
Deferred TODOs: nenhum
-->

# NexClin Constitution

> Plataforma operacional inteligente para clínicas médicas e odontológicas.
> Esta constituição é a lei do repositório: supera qualquer preferência de
> implementação. Deriva das Regras Inegociáveis do `claude.md` e as promove a
> governança versionada. Em conflito, a constituição prevalece.

## Core Principles

### I. Segurança Mora no Banco

A segurança é propriedade do banco de dados, não da aplicação.

- Toda tabela com `clinic_id` **MUST** ter RLS habilitado — sem exceção.
- O modelo é **default deny**: o que não é explicitamente concedido é negado.
  O fallback de qualquer resolução de acesso é `none`.
- Nenhuma regra de acesso pode existir apenas no frontend. A tela **MUST**
  apenas refletir o que o banco já garante; um bug de aplicação não pode
  vazar dado de outra clínica.
- A âncora multi-tenant (`profiles.clinic_id`) **MUST** ser imutável para o
  usuário comum — só superadmin ou service role a altera, protegida por
  trigger.

**Rationale:** dados sensíveis de saúde e isolamento multi-tenant não podem
depender da corretude da camada de aplicação, que é a de menor confiança e a
mais reescrita. Se a segurança mora no Postgres via RLS, uma falha de UI ou de
API degrada função, não confidencialidade.

### II. Privacidade e Auditoria (LGPD por Arquitetura)

LGPD é requisito de arquitetura, não feature opcional.

- Toda ação administrativa sobre dado de cliente **MUST** gerar registro de
  auditoria: quem, o quê, quando, e o diff `old→new` quando houver alteração.
- Senha de cliente **MUST NEVER** ser definida por um admin ou operador. A
  única via de troca é o fluxo de reset por e-mail. Nenhuma action, função ou
  edge function pode setar senha diretamente.
- Dados pessoais **MUST NOT** trafegar em parâmetros de URL/query string.

**Rationale:** confiança do mercado de saúde e conformidade regulatória se
sustentam em rastreabilidade e no princípio de que ninguém — nem o suporte —
assume a identidade de credenciais de um cliente.

### III. Contrato Único de Módulos

As 15 ModuleKeys oficiais são o contrato único do sistema.

- `dashboard, leads, pacientes, anamnese, consultas, acompanhamento, tarefas,
  contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas,
  relatorios_demais, configuracoes, equipe, insights`.
- Planos, permissões individuais e telas **MUST** usar exatamente as mesmas
  strings. Nenhum módulo novo entra sem ser adicionado a esse contrato.
- Regra de acesso: **o plano é o teto; a permissão individual distribui abaixo
  do teto e nunca o excede.**

**Rationale:** um único vocabulário de módulos elimina divergência entre
cobrança, autorização e navegação — a fonte mais comum de brechas de acesso.

### IV. Spec-Driven Development com Parada Humana

Nenhuma feature nasce de código; nasce de spec aprovada.

- Nenhuma feature **MUST** ser implementada sem uma spec aprovada em `specs/`.
- O executor gera um plano por fases e **MUST** PARAR para aprovação humana
  antes de iniciar cada fase.
- "Implementado ≠ funciona": toda fase **MUST** fechar com critérios de aceite
  executados manualmente por um humano responsável (Arthur), não apenas por
  build verde.
- A referência `../nexclin-lovable` (export do MVP) é **somente leitura**:
  regras de negócio são extraídas dela; nada é editado lá.

**Rationale:** o MVP anterior provou que velocidade sem especificação e sem
gate humano gera retrabalho caro. A parada por fase mantém o humano no
controle das decisões irreversíveis.

### V. Segredos Fora do Código e Qualidade Verificável

- Nenhuma credencial **MUST** aparecer em código, spec ou arquivo versionado.
  Segredos vivem apenas em variáveis de ambiente (`.env.local`, fora do git).
- TypeScript **MUST** ser estrito.
- Guards de rota e lógica de permissão **MUST** ter testes automatizados
  mínimos — são o perímetro de segurança da camada de aplicação.

**Rationale:** segredo versionado é vazamento permanente (fica no histórico);
e o único código que merece teste obrigatório é o que decide quem vê o quê.

### VI. Valor Operacional Antes de Feature

O NexClin é uma plataforma operacional inteligente, não um sistema de
cadastros.

- Toda funcionalidade proposta **MUST** passar por pelo menos um destes
  critérios: aumentar receita, reduzir custo, economizar tempo ou melhorar a
  decisão da clínica.
- O diferencial é embarcar metodologia real de gestão clínica como
  inteligência do produto (IA proativa com recomendações), não competir
  feature a feature com sistemas genéricos.

**Rationale:** foco em impacto operacional é o que justifica o produto frente
a concorrentes estabelecidos; features sem esse vínculo diluem o diferencial e
o tempo escasso até o primeiro cliente.

## Restrições Técnicas & Stack

- **Stack-alvo:** Next.js (App Router) + TypeScript + Supabase próprio
  (Postgres + Auth + RLS + Edge Functions). Hosting Vercel. Custo previsível é
  requisito de arquitetura — desenvolver mais não pode custar mais.
- **Fonte de verdade do schema:** `supabase/migrations`. Toda mudança de banco
  **MUST** ser uma migração versionada no repositório — nunca alteração manual
  no painel do Supabase.
- **E-mail transacional:** Resend. O SMTP embutido não entrega (comprovado) e
  **MUST NOT** ser usado para fluxos de auth (convite, reset).
- **Independência de fornecedor:** código no GitHub, banco no Supabase,
  hosting na Vercel — cada peça deve permanecer substituível.
- **Camadas de autorização:** `user_roles` (papel global) → `team_members`
  (permissão operacional por módulo) → `superadmin_operators` (nível SaaS),
  resolvidas no banco.

## Fluxo de Desenvolvimento

- Ordem canônica por feature: `/speckit-specify` → (`/speckit-clarify`) →
  `/speckit-plan` → `/speckit-tasks` → (`/speckit-analyze`) →
  `/speckit-implement`.
- Cada spec produz um plano por fases; cada fase tem critérios de aceite
  explícitos, verificados manualmente antes de avançar (Princípio IV).
- Toda alteração de banco entra por migração; seeds são idempotentes (rodar 2x
  não duplica).
- Nenhuma credencial em PR, spec ou task.
- Fundação atual: **SPEC 001 — fundação + superadmin** (`specs/`), com fases:
  (1) réplica do banco, (2) seeds, (3) edge functions, (4) app Next.js.

## Governance

- Esta constituição supera qualquer prática ou preferência de implementação.
  Em conflito entre a constituição e um plano/tarefa, a constituição vence.
- **Emendas** exigem: registro do motivo, atualização deste arquivo com
  incremento de versão e Sync Impact Report, e revisão dos templates
  dependentes (`plan`, `spec`, `tasks`).
- **Versionamento (SemVer):**
  - MAJOR — remoção/redefinição incompatível de princípio ou governança.
  - MINOR — novo princípio ou seção, ou expansão material de orientação.
  - PATCH — esclarecimentos, redação, correções não semânticas.
- **Conformidade:** todo plano e revisão **MUST** verificar aderência aos
  princípios I–VI. Complexidade que os contrarie precisa ser justificada por
  escrito ou rejeitada.
- **Orientação de runtime:** `claude.md` é o guia operacional de contexto do
  projeto e permanece subordinado a esta constituição.

**Version**: 1.0.0 | **Ratified**: 2026-08-02 | **Last Amended**: 2026-08-02
