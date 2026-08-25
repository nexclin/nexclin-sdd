/**
 * SPEC 001 / T020 e T026 — o menu lateral do app da clínica.
 *
 * O contrato de guards manda: *"montar itens a partir de `my_permission` por
 * módulo — item com `none` não aparece"*. Este arquivo faz só a parte pura
 * disso: dado o mapa de permissões que o banco devolveu, quais itens existem.
 *
 * Esconder o item **não é** a proteção. A proteção é a RLS mais o
 * `RequirePermission` na rota. O menu é defesa em profundidade e cortesia com
 * o usuário: item que aparece e dá "acesso negado" no clique é pior que item
 * que não aparece.
 *
 * As rotas saem de `docs/dominio/modulos.md`, que é a tabela oficial.
 */

import { MODULE_KEYS, type ModuleKey } from "./modulos";
import { podeAcessar } from "./permissao";

export type GrupoMenu = "Operação" | "Financeiro" | "Clínico" | "Análise" | "Sistema";

export interface ItemMenu {
  modulo: ModuleKey;
  rotulo: string;
  rota: string;
  grupo: GrupoMenu;
  /**
   * Se a rota é protegida por `RequirePermission`.
   *
   * Só o `dashboard` fica `false`, e por duas razões que se somam. A primeira
   * está registrada no INVENTARIO §3.1: o dashboard nunca teve gate de
   * permissão, é a raiz do app. A segunda apareceu num teste: a rota dele é
   * `/app`, então casar por prefixo faria **qualquer** rota desconhecida
   * (`/app/inexistente`) ser resolvida como dashboard, e portanto liberada.
   * Tirá-lo do casamento de rota fecha esse buraco de uma vez.
   */
  gateada: boolean;
}

/**
 * O catálogo, na ordem em que o menu deve aparecer.
 *
 * Três ausências deliberadas, e cada uma tem motivo escrito:
 *
 * - **`consultas`** não tem rota. A chave existe no contrato das 15, mas a tela
 *   rotulada "Consultas" aponta para `/acompanhamento`, protegida pela chave
 *   `acompanhamento`. `docs/dominio/modulos.md` registra a ambiguidade e manda
 *   decidir: ou `consultas` ganha destino próprio, ou sai por emenda. Até lá,
 *   fora do menu, porque item de menu sem destino é bug de navegação.
 * - **`equipe`** vive dentro de `/configuracoes`, não como item de topo.
 * - **`dashboard`** é a raiz e não é gateado por `RequirePermission`
 *   (INVENTARIO §3.1 registra "— (interno)").
 */
const CATALOGO: readonly ItemMenu[] = [
  { modulo: "dashboard", rotulo: "Início", rota: "/app", grupo: "Operação", gateada: false },
  { modulo: "leads", rotulo: "Atendimentos", rota: "/app/atendimentos", grupo: "Operação", gateada: true },
  { modulo: "pacientes", rotulo: "Pacientes", rota: "/app/pacientes", grupo: "Operação", gateada: true },
  { modulo: "acompanhamento", rotulo: "Consultas", rota: "/app/acompanhamento", grupo: "Operação", gateada: true },
  { modulo: "tarefas", rotulo: "Tarefas", rota: "/app/tarefas", grupo: "Operação", gateada: true },
  { modulo: "contas_receber", rotulo: "Contas a receber", rota: "/app/contas-receber", grupo: "Financeiro", gateada: true },
  { modulo: "contas_pagar", rotulo: "Contas a pagar", rota: "/app/contas-pagar", grupo: "Financeiro", gateada: true },
  { modulo: "fluxo_caixa", rotulo: "Fluxo de caixa", rota: "/app/fluxo-caixa", grupo: "Financeiro", gateada: true },
  { modulo: "anamnese", rotulo: "Anamnese", rota: "/app/anamnese", grupo: "Clínico", gateada: true },
  { modulo: "relatorios_vendas", rotulo: "Relatório de vendas", rota: "/app/relatorios/vendas", grupo: "Análise", gateada: true },
  { modulo: "relatorios_demais", rotulo: "Demais relatórios", rota: "/app/relatorios", grupo: "Análise", gateada: true },
  { modulo: "insights", rotulo: "Insights", rota: "/app/insights", grupo: "Análise", gateada: true },
  { modulo: "configuracoes", rotulo: "Configurações", rota: "/app/configuracoes", grupo: "Sistema", gateada: true },
] as const;

/** Os módulos que o menu consulta. `consultas` e `equipe` ficam de fora. */
export const MODULOS_DO_MENU: readonly ModuleKey[] = CATALOGO.map((i) => i.modulo);

/** A ordem dos grupos no menu. */
export const ORDEM_GRUPOS: readonly GrupoMenu[] = [
  "Operação",
  "Financeiro",
  "Clínico",
  "Análise",
  "Sistema",
];

/**
 * Filtra o catálogo pelo que o banco concedeu.
 *
 * Falha fechado por construção: o item só entra se `podeAcessar` disser sim
 * sobre o valor devolvido pelo banco. Chave ausente no mapa, valor nulo, valor
 * de tipo errado, `"none"`, tudo isso omite o item.
 */
export function montarMenu(
  permissoes: Partial<Record<ModuleKey, unknown>> | null | undefined,
): ItemMenu[] {
  const mapa = permissoes ?? {};
  return CATALOGO.filter((item) => podeAcessar(mapa[item.modulo]));
}

/** Agrupa para renderizar, descartando grupo que ficou vazio. */
export function agruparMenu(
  itens: readonly ItemMenu[],
): { grupo: GrupoMenu; itens: ItemMenu[] }[] {
  return ORDEM_GRUPOS.map((grupo) => ({
    grupo,
    itens: itens.filter((i) => i.grupo === grupo),
  })).filter((g) => g.itens.length > 0);
}

/**
 * O módulo que protege uma rota do app.
 *
 * Usada pelo guard de rota e pelo teste que garante que **toda** rota do menu
 * tem dono. Devolve `null` para rota desconhecida, e quem chama trata `null`
 * como negado, nunca como liberado.
 */
export function moduloDaRota(rota: string): ModuleKey | null {
  if (typeof rota !== "string" || rota === "") return null;
  // Só entram rotas gateadas. O dashboard mora em `/app` e casaria com toda
  // rota desconhecida por prefixo — foi assim que um teste pegou
  // `/app/inexistente` sendo resolvido como dashboard, e portanto liberado.
  // A rota mais específica vence: `/app/relatorios/vendas` não pode casar com
  // `/app/relatorios` por acidente de prefixo.
  const candidatos = CATALOGO.filter(
    (i) => i.gateada && (rota === i.rota || rota.startsWith(i.rota + "/")),
  ).sort((a, b) => b.rota.length - a.rota.length);
  return candidatos[0]?.modulo ?? null;
}

/** As rotas que existem no app, para separar "não gateada" de "não existe". */
export function rotaEhConhecida(rota: string): boolean {
  if (typeof rota !== "string" || rota === "") return false;
  return CATALOGO.some((i) => rota === i.rota || rota.startsWith(i.rota + "/"));
}

/** Guarda de completude: todo item do catálogo usa uma das 15 chaves. */
export function catalogoEstaNoContrato(): boolean {
  const contrato: ReadonlySet<string> = new Set(MODULE_KEYS);
  return CATALOGO.every((i) => contrato.has(i.modulo));
}
