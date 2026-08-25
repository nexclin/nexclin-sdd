/**
 * SPEC 001 / T020 — estado do onboarding da clínica.
 *
 * # O onboarding não tem coluna, e isso é de propósito
 *
 * A referência (`useOnboardingStatus.ts` no MVP) **não guarda** "onboarding
 * concluído" em lugar nenhum. Ela deriva o estado de doze perguntas do tipo
 * "esta clínica já tem pelo menos uma linha de X?". Conferido na leitura da
 * referência em 25/08/2026, e replicado aqui por paridade de comportamento.
 *
 * A consequência prática vale registrar: como é derivado, o onboarding
 * **volta a ficar incompleto** se a clínica desativar o último método de
 * pagamento. Isso é comportamento da referência, não bug daqui.
 *
 * # Por que puro
 *
 * Nada aqui toca rede. As doze contagens entram como dado, a decisão sai como
 * dado. É o que permite testar a regra sem banco, que é o mínimo obrigatório
 * do Princípio V para o que decide navegação.
 */

/** Os doze passos, na ordem em que a referência os apresenta. */
export const PASSOS_ONBOARDING = [
  "team",
  "patient_fields",
  "appointment_fields",
  "business_rules",
  "channels_origins",
  "services",
  "objections",
  "payment_methods",
  "chart_of_accounts",
  "bank_accounts",
  "goals",
  "anamnese",
] as const;

export type PassoOnboarding = (typeof PASSOS_ONBOARDING)[number];

/**
 * As contagens cruas que o servidor coleta. Cada campo é "quantas linhas
 * ativas esta clínica tem" na tabela correspondente.
 *
 * `business_rules` cobre três passos de uma vez (`patient_fields`,
 * `appointment_fields` e `business_rules`), porque na referência os três
 * consultam a mesma tabela. Manter os três passos separados é o que preserva
 * a contagem de "passo 4 de 12" idêntica à do MVP.
 */
export interface ContagensOnboarding {
  team_members: number;
  business_rules: number;
  channels: number;
  origins: number;
  services: number;
  objections: number;
  payment_methods: number;
  chart_of_accounts: number;
  bank_accounts: number;
  goals: number;
  anamnesis_config: number;
}

/** Tudo em zero. É o ponto de partida e também o fallback de erro. */
export const CONTAGENS_VAZIAS: ContagensOnboarding = {
  team_members: 0,
  business_rules: 0,
  channels: 0,
  origins: 0,
  services: 0,
  objections: 0,
  payment_methods: 0,
  chart_of_accounts: 0,
  bank_accounts: 0,
  goals: 0,
  anamnesis_config: 0,
};

export interface EstadoOnboarding {
  passos: Record<PassoOnboarding, boolean>;
  concluido: boolean;
  /** Índice do primeiro passo incompleto. Igual a 12 quando tudo terminou. */
  passoAtual: number;
  total: number;
}

/** Guarda contra número negativo, `NaN` e coisa que não é número. */
function tem(n: unknown, minimo = 1): boolean {
  return typeof n === "number" && Number.isFinite(n) && n >= minimo;
}

/**
 * Deriva o estado do onboarding a partir das contagens.
 *
 * A única regra que foge do padrão "pelo menos uma linha" é `team`, que exige
 * **duas** pessoas ativas. A referência usa `.limit(2)` e testa `>= 2`: a
 * clínica com só o dono não passou pelo passo de equipe.
 * `channels_origins` é um passo só e exige as duas tabelas.
 */
export function resolverOnboarding(
  contagens: Partial<ContagensOnboarding> | null | undefined,
): EstadoOnboarding {
  const c = { ...CONTAGENS_VAZIAS, ...(contagens ?? {}) };

  const passos: Record<PassoOnboarding, boolean> = {
    team: tem(c.team_members, 2),
    patient_fields: tem(c.business_rules),
    appointment_fields: tem(c.business_rules),
    business_rules: tem(c.business_rules),
    channels_origins: tem(c.channels) && tem(c.origins),
    services: tem(c.services),
    objections: tem(c.objections),
    payment_methods: tem(c.payment_methods),
    chart_of_accounts: tem(c.chart_of_accounts),
    bank_accounts: tem(c.bank_accounts),
    goals: tem(c.goals),
    anamnese: tem(c.anamnesis_config),
  };

  const primeiroIncompleto = PASSOS_ONBOARDING.findIndex((k) => !passos[k]);

  return {
    passos,
    concluido: primeiroIncompleto === -1,
    passoAtual:
      primeiroIncompleto === -1 ? PASSOS_ONBOARDING.length : primeiroIncompleto,
    total: PASSOS_ONBOARDING.length,
  };
}
