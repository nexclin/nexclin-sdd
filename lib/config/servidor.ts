/**
 * SPEC 005 / T009 — a camada de dados dos catálogos, no servidor.
 *
 * Mesma disciplina de `lib/auth/servidor.ts`: **nada aqui lança**, e toda falha
 * vira lista vazia. Tela de configuração que estoura numa consulta impede a
 * clínica de configurar o resto.
 *
 * Não há `import "server-only"` porque o pacote não está nas dependências; a
 * garantia vem de `@/lib/supabase/server`, que importa `next/headers`.
 */

import { createClient } from "@/lib/supabase/server";
import {
  colunasParaConsulta,
  type DefinicaoDeCatalogo,
} from "./catalogo";

export interface LinhaDeCatalogo {
  id: string;
  active: boolean;
  is_system?: boolean;
  [coluna: string]: unknown;
}

/**
 * Lê as linhas de um catálogo.
 *
 * **A tabela vem da definição, nunca da URL.** Quem chama já resolveu o slug
 * por `catalogoPorSlug`, que devolve `null` para slug desconhecido. Este
 * parâmetro é a definição inteira, e não uma string, justamente para que não
 * exista um caminho em que o nome da tabela chegue aqui vindo do cliente.
 *
 * Não filtra por `clinic_id`: a RLS já faz isso. Repetir o filtro criaria uma
 * segunda fonte de verdade sobre qual clínica é a minha, e é exatamente a
 * dívida que a fase 0 encontrou nas policies (`research.md` §2).
 */
export async function lerCatalogo(
  definicao: DefinicaoDeCatalogo,
  opcoes: { incluirInativos?: boolean } = {},
): Promise<LinhaDeCatalogo[]> {
  try {
    const supabase = await createClient();
    let q = supabase
      .from(definicao.tabela)
      .select(colunasParaConsulta(definicao))
      .order("name", { ascending: true });

    // O padrão é mostrar só o ativo, porque é o que a clínica usa no dia a dia.
    // O inativo continua existindo e continua legível onde já foi usado.
    if (!opcoes.incluirInativos) q = q.eq("active", true);

    const { data, error } = await q;
    if (error) return [];
    return (data ?? []) as unknown as LinhaDeCatalogo[];
  } catch {
    return [];
  }
}

/** Quantas linhas ativas o catálogo tem. Alimenta o índice de configurações. */
export async function contarCatalogo(
  definicao: DefinicaoDeCatalogo,
): Promise<number> {
  try {
    const supabase = await createClient();
    const { count, error } = await supabase
      .from(definicao.tabela)
      .select("id", { count: "exact", head: true })
      .eq("active", true);
    return error ? 0 : (count ?? 0);
  } catch {
    return 0;
  }
}

export interface RegrasDaClinica {
  id: string | null;
  followup_days: number;
  confirmation_hours: number;
  recapture_days: number;
  recall_days: number;
  satisfaction_survey_days: number;
  anamnesis_send_days: number;
  work_saturday: boolean;
  patient_required_fields: unknown;
  appointment_required_fields: unknown;
}

/** Os defaults, que valem quando a clínica ainda não tem a linha. */
export const REGRAS_PADRAO: RegrasDaClinica = {
  id: null,
  followup_days: 7,
  confirmation_hours: 24,
  recapture_days: 30,
  recall_days: 180,
  satisfaction_survey_days: 1,
  anamnesis_send_days: 1,
  work_saturday: false,
  patient_required_fields: ["name"],
  appointment_required_fields: ["patient_id", "date"],
};

/**
 * As regras de negócio da clínica.
 *
 * É uma linha por clínica. Quando ela não existe — clínica recém-criada — os
 * defaults valem, e a tela grava a linha no primeiro salvamento. Devolver
 * `null` obrigaria toda tela consumidora a tratar a ausência, e cada uma
 * trataria de um jeito.
 */
export async function lerRegras(): Promise<RegrasDaClinica> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("business_rules")
      .select(
        "id, followup_days, confirmation_hours, recapture_days, recall_days, satisfaction_survey_days, anamnesis_send_days, work_saturday, patient_required_fields, appointment_required_fields",
      )
      .limit(1)
      .maybeSingle();

    if (error || !data) return REGRAS_PADRAO;
    return { ...REGRAS_PADRAO, ...(data as Partial<RegrasDaClinica>) };
  } catch {
    return REGRAS_PADRAO;
  }
}
