/**
 * SPEC 005 / T006 — as conversões e validações de `business_rules`, em forma pura.
 *
 * Nada aqui toca rede ou React. É a parte da tela que dá para provar com número,
 * e o Princípio IX da constituição é explícito: *"aritmética de dinheiro MUST
 * ser simulada antes de enviar"*. Aritmética de prazo merece o mesmo tratamento,
 * porque erro de um dia numa regra de confirmação vira paciente ligado no dia
 * errado.
 */

/**
 * A armadilha conhecida: a regra de confirmação é **exibida em dias** e
 * **armazenada em horas**.
 *
 * A referência do MVP faz isso, o critério de pronto da fila exige preservar, e
 * a ida e volta precisa ser estável: o número que o usuário vê depois de salvar
 * tem de ser o mesmo que ele digitou.
 *
 * `max(1, ...)` existe porque zero dia não significa nada para quem configura.
 * Uma clínica que quer confirmar no mesmo dia configura 1, e o sistema confirma
 * 24 horas antes.
 */
export function horasParaDias(horas: unknown): number {
  const h = Number(horas);
  if (!Number.isFinite(h) || h <= 0) return 1;
  return Math.max(1, Math.round(h / 24));
}

/** O caminho de volta. Gravar sempre em horas, porque a coluna é em horas. */
export function diasParaHoras(dias: unknown): number {
  const d = Math.floor(Number(dias));
  if (!Number.isFinite(d) || d < 1) return 24;
  return d * 24;
}

/**
 * Os campos que o cadastro de paciente pode exigir.
 *
 * O default da coluna (`["name"]`) diz o contrato: são **nomes de campo**, não
 * rótulos. A lista fechada existe para que a tela de configuração não ofereça
 * campo que o formulário de paciente não conhece — oferecer seria configurar
 * uma exigência que nunca é aplicada.
 */
export const CAMPOS_DE_PACIENTE = [
  "name",
  "phone",
  "email",
  "birth_date",
  "cpf",
  "gender",
  "address",
  "city",
  "state",
  "zip_code",
  "channel_id",
  "origin_id",
] as const;

export type CampoDePaciente = (typeof CAMPOS_DE_PACIENTE)[number];

/** Os campos que o agendamento pode exigir. Default da coluna: `["patient_id","date"]`. */
export const CAMPOS_DE_AGENDAMENTO = [
  "patient_id",
  "date",
  "time",
  "doctor",
  "consultation_type_id",
  "channel_id",
  "origin_id",
  "notes",
] as const;

export type CampoDeAgendamento = (typeof CAMPOS_DE_AGENDAMENTO)[number];

/**
 * Normaliza a coluna `jsonb` de campos obrigatórios.
 *
 * A coluna pode trazer: o default, uma lista salva pela tela, `null` de linha
 * antiga, ou lixo. Tudo que não for uma lista de campos conhecidos é
 * descartado, e o que sobra passa pelo piso.
 */
export function normalizaCamposObrigatorios<T extends string>(
  valor: unknown,
  conhecidos: readonly T[],
  piso: readonly T[],
): T[] {
  const validos = new Set<string>(conhecidos);
  const lista = Array.isArray(valor) ? valor : [];
  const limpos = lista.filter((v): v is T => typeof v === "string" && validos.has(v));

  // O piso é o que o sistema não consegue operar sem. Paciente sem nome não é
  // paciente, e agendamento sem data e sem paciente não é agendamento.
  // Desmarcá-los na tela seria configurar um cadastro impossível.
  const comPiso = new Set<T>([...piso, ...limpos]);

  // Devolve na ordem do catálogo, não na ordem em que foi salvo. Assim a tela
  // não embaralha a cada gravação.
  return conhecidos.filter((c) => comPiso.has(c));
}

/** Os campos que nunca podem ser desmarcados. */
export const PISO_PACIENTE: readonly CampoDePaciente[] = ["name"];
export const PISO_AGENDAMENTO: readonly CampoDeAgendamento[] = ["patient_id", "date"];

/**
 * Valida um cadastro contra os campos que a clínica marcou como obrigatórios.
 *
 * Devolve a lista de campos que faltaram, e não um booleano: a tela precisa
 * dizer **quais**, e não só que algo falta.
 */
export function camposFaltando<T extends string>(
  dados: Record<string, unknown>,
  obrigatorios: readonly T[],
): T[] {
  return obrigatorios.filter((campo) => {
    const v = dados[campo];
    if (v === null || v === undefined) return true;
    if (typeof v === "string") return v.trim() === "";
    if (Array.isArray(v)) return v.length === 0;
    return false;
  });
}

/** Os parâmetros de `business_rules` que são contagem de dias. */
export interface RegrasEmDias {
  followup_days: number;
  recapture_days: number;
  recall_days: number;
  satisfaction_survey_days: number;
  anamnesis_send_days: number;
}

/**
 * Normaliza um prazo em dias vindo do banco ou do formulário.
 *
 * Zero é permitido aqui, ao contrário da confirmação: "enviar a anamnese em 0
 * dias" significa enviar no ato, e é uma configuração legítima.
 */
export function normalizaDias(valor: unknown, padrao = 0): number {
  const n = Math.floor(Number(valor));
  if (!Number.isFinite(n) || n < 0) return padrao;
  // Um ano é o teto. Acima disso é digitação errada, não configuração.
  return Math.min(365, n);
}
