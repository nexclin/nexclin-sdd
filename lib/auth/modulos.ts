/**
 * SPEC 001 / T021 — o contrato único de módulos, do lado do front.
 *
 * Estas 15 chaves são as mesmas usadas pelo plano (`plans.enabled_modules`),
 * pela permissão individual (`team_members.permissions`) e pelas telas. Regra
 * (f) da constituição: uma string só, em todo lugar. Um módulo novo não existe
 * enquanto não entrar aqui E no banco.
 *
 * A ordem não importa; a completude sim. O teste em `__tests__/permissao.test.ts`
 * trava a lista contra acréscimo ou remoção acidental — se você mudar aqui sem
 * mudar o banco, o teste quebra, que é exatamente o objetivo.
 */
export const MODULE_KEYS = [
  "dashboard",
  "leads",
  "pacientes",
  "anamnese",
  "consultas",
  "acompanhamento",
  "tarefas",
  "contas_receber",
  "contas_pagar",
  "fluxo_caixa",
  "relatorios_vendas",
  "relatorios_demais",
  "configuracoes",
  "equipe",
  "insights",
] as const;

export type ModuleKey = (typeof MODULE_KEYS)[number];

const CONJUNTO: ReadonlySet<string> = new Set(MODULE_KEYS);

/** Só o que está no contrato é módulo. Qualquer outra coisa é negada adiante. */
export function ehModuleKey(valor: unknown): valor is ModuleKey {
  return typeof valor === "string" && CONJUNTO.has(valor);
}
