# SPEC 003 — Super Admin finalizado e blindado (stack nova)

> **Status:** proposta · **Executor:** Claude Code · **Aprovador:** Arthur Hideo
> **Estende:** SPEC 001, Fase 4 (painel superadmin em Next.js)
> **Referência funcional:** `../nexclin-lovable` (SOMENTE LEITURA) +
> `INVENTARIO-UI.md` (o que existe de fato) + `docs/seguranca/revisao-2026-08-16.md`
> **Lei:** `.specify/memory/constitution.md` · **Contexto:** `CLAUDE.md`
> **Método:** SDD — plano por fases, PARADA para aprovação antes de cada fase.

---

## OBJETIVO

Completar o painel Super Admin na stack nova e blindá-lo por todos os
princípios da constituição — impersonação auditada, dados sensíveis via RPC,
escrita privilegiada só para superadmin, e **nenhuma action que defina senha**.
Ao final, o superadmin da stack nova faz tudo o que o de referência faz, com
paridade de comportamento e sem as brechas que o MVP teve.

## RITMO

Sem prazo de 01/09. O superadmin é ferramenta interna de operação (Arthur e
Erick), não tela de cliente, e o lançamento ocorre na plataforma Lovable, cujo
superadmin já opera o essencial. Esta spec é da stack nova e segue o princípio
"sem pressa, com segurança máxima".

## ESTADO DE PARTIDA (medido em 16/08, `INVENTARIO-UI.md`)

Portado na stack nova: **2 de 11** telas — dashboard e lista de contas
(`app/superadmin/(panel)`). Faltam 9. E há um item que **nunca existiu no
Lovable**: a seção de Perfis (edição de cliente, troca de e-mail, envio de
reset). A SPEC 001 F4 pedia "paridade com a referência" para ela — mas não há
referência visual a copiar. Esta spec resolve essa lacuna definindo o desenho.

---

## PRÉ-REQUISITOS

- SPEC 001 Fases 1–3 concluídas (banco replicado, seeds, edge functions).
- Login superadmin funcional na stack nova (`/superadmin/login`).
- Edge function `superadmin-manage-user` portada (já no repo, com a action de
  senha removida por conformidade).

---

## FASE 1 — SEÇÃO DE PERFIS (a lacuna sem referência)

O item que a SPEC 001 não pôde copiar. Definir o desenho e implementar.

1. No detalhe da conta (`/superadmin/contas/:id`), adicionar o bloco **Perfis**
   com, para cada usuário da clínica:
   - **Editar perfil** (nome, telefone, dados não sensíveis) — grava via
     política de UPDATE + trigger de auditoria com diff `old→new`. Auto-edição
     não audita.
   - **Trocar e-mail de login** — via edge function `superadmin-manage-user`
     action `update_email` (auditada, com confirmação explícita no diálogo).
   - **Enviar reset de senha** — action `send_password_reset`
     (`resetPasswordForEmail`). **NENHUMA opção define senha.** A ausência do
     botão "definir senha" é requisito, não esquecimento.
2. Toda ação grava **duas linhas**: `superadmin_audit_log` + `account_timeline`
   (a referência falhava na segunda — ver `INVENTARIO-UI.md` D7; aqui é
   obrigatória e verificada).
3. **Verificação:** editar perfil audita `old→new`; auto-edição não audita;
   trocar e-mail muda o login; enviar reset dispara e-mail (via Resend);
   inexistência total de caminho que defina senha (o guarda confirma no código).

## FASE 2 — AS 9 TELAS RESTANTES

Reconstruir com paridade de comportamento (regra, não estilo), lendo
`INVENTARIO-UI.md` para o que cada tela mostra e opera:

1. **Detalhe da conta** — a mais densa: cards (cadastrais, responsável,
   assinatura), uso do sistema, painel Ações (Alterar Plano, Estender Trial,
   Aplicar Desconto, Registrar Reembolso, Nota Interna, Suspender, Cancelar) e
   Timeline. Máquina de estados de assinatura gated por status.
2. **Planos** — editor alinhado às 15 ModuleKeys (`enabled_modules` validado
   por trigger).
3. **Cupons**, **Faturamento** (cobranças + inadimplência), **Métricas**
   (health score, MRR, churn, uso por módulo), **Comunicação** (variáveis
   `{nome_clinica}` etc.), **Logs de auditoria** (com export CSV),
   **Operadores**, **Configurações do SaaS** (régua de inadimplência).
3. **Verificação:** cada tela reage ao banco vivo; toda ação de operador que
   deveria auditar, audita; nenhuma regra de acesso vive só no front.

## FASE 3 — BLINDAGEM

Aplicar, na stack nova, as lições que o scanner do Lovable já corrigiu lá, e
confirmar que não há regressão.

1. **Impersonação** escopada ao próprio superadmin (`superadmin_enter_clinic`/
   `exit`); banner âmbar fixo "Modo suporte — <clínica>" em todas as rotas;
   cache zerado a cada entrada/saída; onboarding não dispara sob impersonação.
2. **Dados sensíveis da equipe** (e-mail, telefone, registro, repasse)
   acessíveis só a admin/superadmin, via RPC dedicada — nunca em `select *`
   aberto.
3. **Escrita em `user_roles`** e execução de funções privilegiadas restritas a
   superadmin; `is_superadmin` só responde sobre o próprio usuário.
4. `SECURITY DEFINER` com `SET search_path` fixo em toda função.
5. **Verificação:** o agente `auditor-multitenant` roda sobre todo o painel e
   não encontra vazamento entre clínicas nem escalada de privilégio; testes
   automatizados nos guards (`SuperAdminGuard`) e na resolução de permissão.

---

## REGRAS TRANSVERSAIS (da constituição)

RLS em toda tabela com `clinic_id`; default deny; segurança no banco, nunca só
na tela; toda ação administrativa auditada com `old→new`; **senha de cliente
jamais definida por admin** — só reset por e-mail; TypeScript estrito; testes
mínimos em guards e permissões.

## CRITÉRIOS DE ACEITE (executados manualmente por Arthur)

1. As 11 telas do painel existem e reagem ao banco vivo.
2. Seção de Perfis: editar audita `old→new`; auto-edição não audita; troca de
   e-mail muda login; reset por e-mail funciona; **não existe** caminho que
   defina senha (confirmado pelo guarda no código).
3. Toda ação de operador grava as duas linhas (`superadmin_audit_log` +
   `account_timeline`).
4. Impersonação: entrar → banner com nome certo → escrever na clínica-alvo →
   trocar de clínica sem sair → sair → âncora restaurada → tudo auditado.
5. Usuário comum invocando qualquer RPC de superadmin → 'Acesso negado'.
6. `auditor-multitenant` fecha sem achado de severidade alta.
7. Dados sensíveis da equipe não aparecem para papel não-admin.
