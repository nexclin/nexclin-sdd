# Contract — Guards do app (Fase 4)

Paridade de **comportamento** com a referência (não estilo). Todo guard só
reflete o que o banco decide; nenhuma regra de acesso vive só no front (Princípio
I e III).

## `ProtectedRoute`
- **Regra:** sem sessão → redireciona para `/login`. Com sessão → renderiza.
- **Estado de carga:** enquanto resolve a sessão, não pisca conteúdo protegido.

## `RequirePermission({ module })`
- **Regra:** consulta `my_permission(module)`; se `none` → bloqueia (404/redirect
  + esconde do menu). Caso contrário renderiza.
- **Contrato de módulos:** `module` ∈ 15 ModuleKeys. String fora do contrato é
  erro de desenvolvimento.
- **Aceite:** cenário 3 do quickstart (plano vence individual).

## `SuperAdminGuard`
- **Regra:** valida `is_superadmin`; senão 403/redirect para `/superadmin/login`.
- **Escopo:** todas as rotas `/superadmin/*`.

## `OnboardingGuard`
- **Regra:** direciona clínica sem onboarding concluído para o fluxo inicial.
- **Bypass obrigatório:** **não** dispara sob impersonação
  (`get_my_active_impersonation()` ativo) — o superadmin entra direto na conta.

## Banner de impersonação (layout global)
- **Regra:** se `get_my_active_impersonation()` retorna sessão ativa, renderizar
  banner âmbar fixo "Modo suporte — <clínica>" em **todas** as rotas + ação
  "Sair da conta" (chama `superadmin_exit_clinic` e volta ao painel).
- **Cache:** invalidar/zerar o cache de dados (React Query) a cada entrada e
  saída de impersonação.

## Menu lateral
- **Regra:** montar itens a partir de `my_permission` por módulo — item com
  `none` **não aparece**. Espelha o bloqueio de rota (defesa em profundidade,
  mas a decisão continua no banco).

## Testes mínimos (Princípio V)
- E2E: cada guard bloqueia/permite conforme a matriz de permissão.
- Unit: hook que consome `my_permission` cobre superadmin, suspenso, fora do
  plano, individual e default deny.
