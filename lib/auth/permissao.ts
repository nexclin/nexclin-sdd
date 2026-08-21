/**
 * SPEC 001 / T021 — o núcleo puro da decisão de permissão no front.
 *
 * # O que este arquivo NÃO faz, de propósito
 *
 * Ele **não reimplementa a cascata** de permissão. A cascata — superadmin vence
 * sempre; assinatura suspensa nega tudo; módulo fora do plano nega; admin da
 * clínica recebe full; senão vale a permissão individual; fallback `none` — vive
 * em `my_permission(_module)`, no Postgres, e é lá que ela deve continuar.
 *
 * Regra (c) da constituição: *segurança mora no banco; a tela apenas reflete.
 * Nenhuma regra de acesso pode existir só no frontend.* Uma cópia da cascata
 * aqui seria uma segunda fonte de verdade, e a segunda fonte de verdade sempre
 * diverge da primeira — normalmente na direção de liberar demais.
 *
 * # O que ele faz
 *
 * A única responsabilidade que é genuinamente do front: **falhar fechado**.
 * Quando a resposta do banco não chega, chega quebrada, ou chega com algo que
 * não sabemos interpretar, a resposta é `none`. Regra (b): o que não é
 * explicitamente concedido é negado.
 *
 * Por isso tudo aqui é função pura, sem React e sem rede — para poder ser
 * testado de verdade, que é o mínimo obrigatório do Princípio V.
 */

import { ehModuleKey } from "./modulos";

/** O valor que nega. É o fallback de tudo que dá errado. */
export const NEGADO = "none" as const;

/**
 * O valor devolvido por `my_permission`. Deliberadamente uma string aberta, e
 * não uma união fechada: cada módulo tem o seu próprio vocabulário no banco
 * (`full`/`read`, `all`/`own`, `full`/`simplified`, `responsible_only`,
 * `status_only`…). Fechar a união aqui seria trazer a regra do banco para o
 * front pela porta dos fundos.
 */
export type ValorPermissao = string;

/**
 * Normaliza a resposta do RPC para algo em que dá para confiar.
 *
 * Falha fechado em todos os caminhos: erro, nulo, indefinido, tipo errado,
 * string vazia ou só espaços. Nunca lança — um guard que estoura é um guard
 * que não protege.
 */
export function normalizarPermissao(
  data: unknown,
  error?: unknown,
): ValorPermissao {
  if (error) return NEGADO;
  if (typeof data !== "string") return NEGADO;
  const limpo = data.trim();
  if (limpo === "") return NEGADO;
  return limpo;
}

/**
 * A única leitura universal que o front pode fazer sobre o valor: `none` nega,
 * qualquer outra coisa concede *algum* acesso.
 *
 * O que cada valor concede exatamente — ler, escrever, ver só o que é seu — é
 * regra de negócio do módulo e pertence ao banco. O front pergunta; não decide.
 */
export function podeAcessar(valor: unknown): boolean {
  return normalizarPermissao(valor) !== NEGADO;
}

/**
 * Decide o acesso a um módulo a partir da resposta crua do RPC.
 *
 * Nega antes mesmo de olhar a resposta quando o módulo pedido não está no
 * contrato das 15 chaves — módulo que não existe não tem permissão, e um erro
 * de digitação numa rota não pode virar porta aberta.
 */
export function resolverAcesso(
  modulo: unknown,
  data: unknown,
  error?: unknown,
): { permissao: ValorPermissao; liberado: boolean } {
  if (!ehModuleKey(modulo)) {
    return { permissao: NEGADO, liberado: false };
  }
  const permissao = normalizarPermissao(data, error);
  return { permissao, liberado: permissao !== NEGADO };
}
