# BACKLOG — trabalho adiado / a re-especificar

> Itens conscientemente fora do escopo atual, registrados para não se perderem. Cada um vira uma spec própria antes de implementar (regra de método do CLAUDE.md).

## Edge functions não portadas na SPEC 001

- **`generate-insights`** — insights de gestão por IA.
  - **Bloqueio:** depende do **Lovable AI Gateway** (`LOVABLE_API_KEY`, modelo `google/gemini-3-flash-preview`), dependência de fornecedor que não portamos.
  - **Direção:** re-especificar com provedor próprio (recomendado **Claude / API Anthropic**), preservando o contrato de saída `insights[] { title, content, category ∈ {marketing, comercial, operação, financeiro, geral}, priority ∈ {high, medium, low} }`. Ver INVENTARIO §2.2.
- **`anamnesis-public`** — formulário público de anamnese (service role, sem auth, idempotente).
  - **Motivo do adiamento:** pertence ao módulo de anamnese/paciente, fora da Fundação. Portar quando o módulo entrar. Ver INVENTARIO §2.1.

## Decisões de arquitetura a confirmar (de INVENTARIO §5.4)

- `enabled_modules`: padronizar como `Record<ModuleKey, boolean>` (o default `'[]'` do MVP é array — descasa com o uso). 
- Auditoria de ações administrativas **dentro** da clínica (hoje só ações de superadmin são auditadas) — fechar lacuna da regra (d).
- ~~Fluxo de convite (`invite-team-user`): preferir convite por e-mail/definição de senha pelo próprio convidado em vez de senha em texto claro pelo admin.~~ **Resolvido em 19/08/2026** (T017 da SPEC 002): a função usa `generateLink({ type: "invite" })` e o convidado define a própria senha. Resta a variante final — quando o Resend entrar (SPEC 003), trocar por `inviteUserByEmail` e parar de devolver `action_link` na resposta; e aplicar a correção na plataforma Lovable, que ainda roda a versão antiga.
- FKs faltantes e unicidade de catálogos ao escrever o schema limpo (§5.4.9–11).
- Enforcement de `max_patients`/`max_leads_month` (hoje só `max_users` tem trigger).
- Páginas órfãs do MVP (`Consultas`, `Funil`, `Funil2`, `Leads`, `Despesas`, `ContasFixas`) — decidir intenção antes de portar.
- Aproximações do MVP a especificar de verdade: histórico de MRR (hoje sintético), imposto no repasse (hardcoded 0), atribuição de profissional no repasse, Comunicação do superadmin (stub), enforcement de cupons.

## Candidatos a módulo novo (levantados em 25/08/2026)

Registrados na leitura do repositório OpenClinic — análise completa em
[`docs/planejamento/openclinic-analise-2026-08-25.md`](../docs/planejamento/openclinic-analise-2026-08-25.md).

- **Estoque + pacote de sessões com saldo** — o procedimento realizado baixa o
  kit de material; a venda de pacote gera saldo de sessões que cada atendimento
  consome. **Estética e odontologia** (dois dos quatro verticais) vendem
  majoritariamente por pacote, e consumo de material é custo direto que hoje
  nenhuma delas consegue medir. É candidato **mais forte** a "funcionalidade que
  faz cobrar mais" do que o módulo de resíduos, e por uma dor que o cliente já
  sente. Sem spec ainda.
- **Régua NGS1 da certificação SBIS** — matriz própria de requisitos de
  segurança com coluna de situação no NexClin, escrita da fonte oficial. Os
  buracos já identificados estão na §3.1 da análise (autoconcessão de
  permissão, bloqueio por tentativas, bloqueio por inatividade, termo de uso).
- **Resíduos e conformidade documental** — já tem spec:
  [`specs/013-residuos-conformidade/`](./013-residuos-conformidade/spec.md).
  Parada por decisão comercial e por emenda à constituição.

## Módulos de negócio (specs futuras, fora da Fundação)

Pacientes, Leads/Atendimentos (funil 1), Acompanhamento/Consultas (funil 2 + fechamento), Tarefas, Anamnese, Financeiro (contas a receber/pagar, fluxo de caixa), Relatórios (leads, vendas, contas, DFC/DRE, produtividade, repasse), Insights, Configurações completas, Onboarding de 12 passos.
