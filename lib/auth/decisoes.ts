/**
 * SPEC 001 / T020 — as decisões de navegação dos guards, em forma pura.
 *
 * # Por que separar isto dos componentes
 *
 * Um guard escrito como Server Component é `async`, toca rede e chama
 * `redirect()`, que **lança** uma exceção do Next para desviar o fluxo. Nada
 * disso é testável de forma barata.
 *
 * Então o componente fica burro: ele busca o dado e pergunta a este arquivo o
 * que fazer. Toda a regra que decide "entra, não entra, vai para onde" mora
 * aqui, síncrona e sem dependência, e é o que o Vitest exercita. É como o
 * Princípio V se cumpre de verdade em guard de rota: *"o único código que
 * merece teste obrigatório é o que decide quem vê o quê."*
 *
 * # A forma da resposta
 *
 * Toda decisão devolve `{ acao }`. `"renderizar"` deixa passar; `"redirecionar"`
 * traz o destino. Não existe terceira opção, e não existe caminho que devolva
 * `undefined`: um guard que não decide é um guard que não protege.
 */

import { ehModuleKey, type ModuleKey } from "./modulos";
import { normalizarPermissao, NEGADO } from "./permissao";

export type Decisao =
  | { acao: "renderizar" }
  | { acao: "redirecionar"; destino: string; motivo: MotivoBloqueio };

export type MotivoBloqueio =
  | "sem_sessao"
  | "nao_superadmin"
  | "sem_permissao"
  | "modulo_fora_do_contrato"
  | "assinatura_inativa"
  | "onboarding_incompleto";

export const ROTA_LOGIN = "/login";
export const ROTA_LOGIN_SUPERADMIN = "/superadmin/login";
export const ROTA_ONBOARDING = "/app/configuracoes";
export const ROTA_CONTA_SUSPENSA = "/app/conta-suspensa";

const RENDERIZAR: Decisao = { acao: "renderizar" };

/**
 * `ProtectedRoute`: sem sessão, vai para o login.
 *
 * Aceita o objeto de usuário cru do Supabase. Qualquer coisa que não seja um
 * objeto com `id` preenchido conta como ausência de sessão, inclusive o
 * `{ user: null }` que o `getUser()` devolve quando o cookie expirou.
 */
export function decidirSessao(user: unknown): Decisao {
  const id = (user as { id?: unknown } | null)?.id;
  if (typeof id !== "string" || id.trim() === "") {
    return { acao: "redirecionar", destino: ROTA_LOGIN, motivo: "sem_sessao" };
  }
  return RENDERIZAR;
}

/**
 * `SuperAdminGuard`: exige sessão **e** `is_superadmin` verdadeiro no banco.
 *
 * Note a assimetria deliberada: `isSuper` só concede quando é **exatamente**
 * `true`. String `"true"`, número `1` e objeto truthy não passam. A resposta do
 * RPC atravessa serialização JSON, e "quase verdadeiro" não é autorização.
 */
export function decidirSuperAdmin(
  user: unknown,
  isSuper: unknown,
  error?: unknown,
): Decisao {
  const sessao = decidirSessao(user);
  if (sessao.acao === "redirecionar") {
    return {
      acao: "redirecionar",
      destino: ROTA_LOGIN_SUPERADMIN,
      motivo: "sem_sessao",
    };
  }
  if (error || isSuper !== true) {
    return {
      acao: "redirecionar",
      destino: ROTA_LOGIN_SUPERADMIN,
      motivo: "nao_superadmin",
    };
  }
  return RENDERIZAR;
}

/**
 * `RequirePermission({ module })`: consulta `my_permission` e reflete.
 *
 * Nega **antes** de olhar a resposta quando o módulo não está no contrato das
 * 15 chaves. Erro de digitação numa rota não pode virar porta aberta, e o
 * contrato de guards chama isso de "erro de desenvolvimento". O usuário é
 * mandado para a raiz do app, não para o login: ele tem sessão, só não tem
 * aquele módulo.
 */
export function decidirPermissao(
  modulo: unknown,
  data: unknown,
  error?: unknown,
): Decisao {
  if (!ehModuleKey(modulo)) {
    return {
      acao: "redirecionar",
      destino: "/app",
      motivo: "modulo_fora_do_contrato",
    };
  }
  if (normalizarPermissao(data, error) === NEGADO) {
    return { acao: "redirecionar", destino: "/app", motivo: "sem_permissao" };
  }
  return RENDERIZAR;
}

/** Os dois estados que derrubam a conta inteira, conforme o enum do banco. */
const STATUS_QUE_BLOQUEIA: ReadonlySet<string> = new Set([
  "suspended",
  "cancelled",
]);

/**
 * Assinatura suspensa ou cancelada tira o acesso ao app.
 *
 * Fica separada de `decidirPermissao` de propósito: a cascata do banco já nega
 * módulo por módulo nesse caso, mas negar sem explicar manda o usuário para uma
 * tela vazia sem dizer por quê. Aqui ele vai para a tela de conta suspensa, que
 * explica e oferece contato.
 *
 * **Ausência de assinatura não bloqueia.** Uma clínica recém-criada, antes do
 * seed da assinatura, não pode ficar trancada para fora por um dado que ainda
 * não existe. Quem nega de fato é a cascata do banco, módulo a módulo.
 */
export function decidirAssinatura(status: unknown): Decisao {
  if (typeof status === "string" && STATUS_QUE_BLOQUEIA.has(status)) {
    return {
      acao: "redirecionar",
      destino: ROTA_CONTA_SUSPENSA,
      motivo: "assinatura_inativa",
    };
  }
  return RENDERIZAR;
}

export interface EntradaOnboarding {
  concluido: boolean;
  /** Sessão de impersonação ativa, vinda de `get_my_active_impersonation()`. */
  impersonando: boolean;
  /** Rota que o usuário pediu, para não redirecionar o destino sobre si mesmo. */
  rotaAtual: string;
}

/**
 * `OnboardingGuard`: leva a clínica incompleta para o fluxo inicial.
 *
 * **O bypass sob impersonação é obrigatório**, e está no contrato de guards com
 * essas palavras: *"não dispara sob impersonação — o superadmin entra direto na
 * conta"*. O motivo é operacional: o suporte entra para investigar um problema,
 * e ser jogado no tour de doze passos toda vez torna a impersonação inútil.
 *
 * O segundo desvio evitado é o laço: se o usuário já está na rota de
 * onboarding, não se redireciona para ela de novo.
 */
export function decidirOnboarding(entrada: EntradaOnboarding): Decisao {
  if (entrada.impersonando) return RENDERIZAR;
  if (entrada.concluido) return RENDERIZAR;

  const rota = entrada.rotaAtual ?? "";
  if (rota === ROTA_ONBOARDING || rota.startsWith(ROTA_ONBOARDING + "/")) {
    return RENDERIZAR;
  }

  return {
    acao: "redirecionar",
    destino: ROTA_ONBOARDING,
    motivo: "onboarding_incompleto",
  };
}

/**
 * O guard completo do app da clínica, na ordem em que os testes precisam ver.
 *
 * A ordem **é** a regra, e não é arbitrária:
 *
 * 1. sem sessão, nem se pergunta o resto;
 * 2. assinatura morta bloqueia a conta inteira, antes de qualquer módulo;
 * 3. onboarding incompleto desvia, salvo impersonação;
 * 4. e só então o módulo da rota é conferido.
 *
 * Inverter 2 e 4 mandaria o usuário de conta suspensa para "sem permissão", que
 * é verdade mas não ajuda ninguém a resolver o problema.
 */
export function decidirEntradaNoApp(entrada: {
  user: unknown;
  statusAssinatura: unknown;
  onboarding: { concluido: boolean; impersonando: boolean };
  rotaAtual: string;
  modulo?: unknown;
  permissao?: unknown;
  erroPermissao?: unknown;
}): Decisao {
  const sessao = decidirSessao(entrada.user);
  if (sessao.acao === "redirecionar") return sessao;

  const assinatura = decidirAssinatura(entrada.statusAssinatura);
  if (assinatura.acao === "redirecionar") return assinatura;

  const onboarding = decidirOnboarding({
    concluido: entrada.onboarding.concluido,
    impersonando: entrada.onboarding.impersonando,
    rotaAtual: entrada.rotaAtual,
  });
  if (onboarding.acao === "redirecionar") return onboarding;

  // Rota sem módulo declarado (a raiz do app, por exemplo) não é gateada por
  // permissão. É o comportamento registrado para o dashboard no INVENTARIO §3.1.
  if (entrada.modulo === undefined || entrada.modulo === null) {
    return RENDERIZAR;
  }

  return decidirPermissao(
    entrada.modulo,
    entrada.permissao,
    entrada.erroPermissao,
  );
}

/** Reexportado para quem monta a rota e precisa do tipo estreito. */
export type { ModuleKey };
