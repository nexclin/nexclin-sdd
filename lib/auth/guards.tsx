/**
 * Guards de servidor. Mesma observação de `servidor.ts` sobre `server-only`.
 */

import { redirect } from "next/navigation";
import type { ReactNode } from "react";

import {
  decidirEntradaNoApp,
  decidirPermissao,
  decidirSessao,
  decidirSuperAdmin,
  type Decisao,
} from "./decisoes";
import { moduloDaRota } from "./menu";
import type { ModuleKey } from "./modulos";
import {
  lerContextoDoUsuario,
  lerPermissao,
  lerSuperAdmin,
  lerUsuario,
  type ContextoDoUsuario,
} from "./servidor";

/**
 * SPEC 001 / T020 — os guards do contrato `contracts/app-guards.md`.
 *
 * Cada um faz três coisas, nesta ordem, e nada além disso:
 *
 * 1. busca o dado (`servidor.ts`, que nunca lança);
 * 2. pergunta a decisão (`decisoes.ts`, que é puro e testado);
 * 3. obedece.
 *
 * A regra de negócio não mora aqui de propósito. Componente `async` que chama
 * `redirect()` é caro de testar, então ele fica burro e a regra fica no módulo
 * puro, onde 61 testes a exercitam. É assim que o Princípio V se cumpre em
 * guard de rota sem depender de e2e para tudo.
 */

/** Obedece à decisão. `redirect` lança por dentro, então nada segue depois. */
function obedecer(decisao: Decisao): void {
  if (decisao.acao === "redirecionar") {
    redirect(decisao.destino);
  }
}

/**
 * `ProtectedRoute` — exige sessão.
 *
 * Sem sessão, vai para `/login`. Como resolve no servidor, não existe janela em
 * que o conteúdo protegido aparece antes do redirecionamento.
 */
export async function ProtectedRoute({ children }: { children: ReactNode }) {
  obedecer(decidirSessao(await lerUsuario()));
  return <>{children}</>;
}

/**
 * `SuperAdminGuard` — exige operador de superadmin ativo.
 *
 * Vale para todas as rotas `/superadmin/*`, exceto o próprio login, que fica
 * fora do grupo guardado para não criar laço de redirecionamento.
 */
export async function SuperAdminGuard({ children }: { children: ReactNode }) {
  const user = await lerUsuario();
  if (!user) {
    obedecer(decidirSuperAdmin(null, false));
    return null;
  }
  obedecer(decidirSuperAdmin(user, await lerSuperAdmin(user.id)));
  return <>{children}</>;
}

/**
 * `RequirePermission({ module })` — exige que `my_permission` conceda.
 *
 * O tipo de `module` é `ModuleKey`, então uma chave inventada não compila. A
 * checagem em tempo de execução continua existindo mesmo assim: TypeScript não
 * sobrevive ao `build`, e a decisão precisa negar chave fora do contrato mesmo
 * quando ela chega por caminho não tipado.
 */
export async function RequirePermission({
  module,
  children,
}: {
  module: ModuleKey;
  children: ReactNode;
}) {
  obedecer(decidirPermissao(module, await lerPermissao(module)));
  return <>{children}</>;
}

/**
 * O guard completo do app da clínica, para uso no layout de `/app`.
 *
 * Faz sessão, assinatura, onboarding e permissão do módulo da rota numa
 * passagem só, na ordem que `decidirEntradaNoApp` define e os testes travam.
 * Devolve o contexto já carregado para que o layout monte o menu e o banner
 * sem uma segunda ida ao banco.
 *
 * O `OnboardingGuard` está embutido aqui, e com ele o **bypass obrigatório sob
 * impersonação**: o suporte que entra numa conta não pode ser jogado no tour de
 * doze passos, ou a impersonação deixa de servir para o que existe.
 */
export async function guardarAppDaClinica(
  rotaAtual: string,
): Promise<ContextoDoUsuario> {
  const ctx = await lerContextoDoUsuario();
  const modulo = moduloDaRota(rotaAtual);

  obedecer(
    decidirEntradaNoApp({
      user: ctx.userId ? { id: ctx.userId } : null,
      statusAssinatura: ctx.statusAssinatura,
      onboarding: {
        concluido: ctx.onboarding.concluido,
        impersonando: ctx.impersonacao !== null,
      },
      rotaAtual,
      modulo: modulo ?? undefined,
      permissao: modulo ? ctx.permissoes[modulo] : undefined,
    }),
  );

  return ctx;
}
