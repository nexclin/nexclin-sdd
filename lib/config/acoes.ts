"use server";

/**
 * SPEC 005 / T009 e T011 — as escritas de configuração.
 *
 * # O que estas actions fazem e o que deliberadamente NÃO fazem
 *
 * Elas resolvem a definição, normalizam a entrada e gravam. **Não decidem
 * acesso.** A permissão do módulo `configuracoes` já é exigida pelo layout e
 * repetida pelo `RequirePermission` da página, e o isolamento entre clínicas é
 * da RLS. Uma terceira checagem aqui seria uma terceira fonte de verdade sobre
 * quem pode o quê, e é assim que as três divergem com o tempo.
 *
 * O que elas garantem, e é responsabilidade só delas:
 *
 * - a **tabela** vem da definição, nunca do que o cliente mandou;
 * - a **coluna** vem dos campos declarados, nunca do que o formulário trouxe;
 * - `clinic_id` **nunca** é escrito daqui, nem no INSERT.
 *
 * # Por que `clinic_id` não é escrito
 *
 * Seria a coisa mais natural do mundo mandar `clinic_id` no INSERT, e é
 * exatamente o caminho que faz a aplicação virar a autoridade sobre qual
 * clínica é a minha. A âncora mora em `profiles.clinic_id`, e quem responde por
 * ela é o banco. Aqui a coluna é preenchida pelo DEFAULT da tabela, que chama
 * `get_my_clinic_id()`.
 *
 * Se alguma tabela de catálogo não tiver esse default, o INSERT falha com
 * violação de NOT NULL, e **falhar é o comportamento certo**: melhor a tela
 * recusar do que a aplicação escolher a clínica.
 */

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";
import { catalogoPorSlug } from "./catalogo";
import { interpretaNumero, normalizaEntradaDeCatalogo } from "./entrada";
import {
  CAMPOS_DE_AGENDAMENTO,
  CAMPOS_DE_PACIENTE,
  PISO_AGENDAMENTO,
  PISO_PACIENTE,
  diasParaHoras,
  normalizaCamposObrigatorios,
  normalizaDias,
} from "./regras";

export interface ResultadoDeAcao {
  ok: boolean;
  /** Mensagem geral, quando a falha não é de um campo específico. */
  mensagem?: string;
  /** Erro por coluna, para a tela mostrar ao lado do campo. */
  erros?: Record<string, string>;
}

/** Lê o `FormData` como um objeto de strings, sem interpretar nada ainda. */
function comoTexto(form: FormData): Record<string, string> {
  const saida: Record<string, string> = {};
  for (const [chave, valor] of form.entries()) {
    if (typeof valor === "string") saida[chave] = valor;
  }
  return saida;
}

/**
 * Cria ou atualiza uma linha de catálogo.
 *
 * O `id` decide entre INSERT e UPDATE, e ele vem do formulário. Isso é seguro
 * pela RLS: um `id` de outra clínica não é alcançado pelo `USING` da policy, e
 * o UPDATE afeta zero linhas. **Zero linhas é tratado como falha aqui**, e não
 * como sucesso silencioso, que é o modo como esse tipo de bug costuma passar.
 */
export async function salvarLinhaDeCatalogo(
  slug: string,
  form: FormData,
): Promise<ResultadoDeAcao> {
  const definicao = catalogoPorSlug(slug);
  if (!definicao) return { ok: false, mensagem: "Catálogo desconhecido." };

  const recebido = comoTexto(form);
  const entrada = normalizaEntradaDeCatalogo(definicao, recebido);
  if (!entrada.ok) return { ok: false, erros: entrada.erros };

  const id = (recebido.id ?? "").trim();

  try {
    const supabase = await createClient();

    if (id === "") {
      const { error } = await supabase
        .from(definicao.tabela)
        .insert(entrada.valores as never);
      if (error) return { ok: false, mensagem: error.message };
    } else {
      const { data, error } = await supabase
        .from(definicao.tabela)
        .update(entrada.valores as never)
        .eq("id", id)
        .select("id");

      if (error) return { ok: false, mensagem: error.message };

      // RLS nega sem reclamar: o UPDATE volta sem erro e sem linha. Chamar isso
      // de sucesso mostraria "salvo" para uma escrita que não aconteceu.
      if (!data || data.length === 0) {
        return {
          ok: false,
          mensagem:
            "Nada foi alterado. O registro pode ser do sistema, ou pode não existir mais.",
        };
      }
    }
  } catch {
    return { ok: false, mensagem: "Não foi possível salvar. Tente de novo." };
  }

  revalidatePath(`/app/configuracoes/${definicao.slug}`);
  revalidatePath("/app/configuracoes");
  return { ok: true };
}

/**
 * Ativa ou desativa uma linha.
 *
 * Desativar e não apagar é a regra do catálogo inteiro: a linha continua
 * referenciada por consultas, recebíveis e leads antigos. Apagar deixaria
 * histórico apontando para o nada, e é o que faz relatório de meses fechados
 * mudar sozinho.
 */
export async function alternarAtivoDeCatalogo(
  slug: string,
  id: string,
  ativo: boolean,
): Promise<ResultadoDeAcao> {
  const definicao = catalogoPorSlug(slug);
  if (!definicao) return { ok: false, mensagem: "Catálogo desconhecido." };
  if (!id.trim()) return { ok: false, mensagem: "Registro não informado." };

  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from(definicao.tabela)
      .update({ active: ativo } as never)
      .eq("id", id)
      .select("id");

    if (error) return { ok: false, mensagem: error.message };
    if (!data || data.length === 0) {
      return { ok: false, mensagem: "Nada foi alterado." };
    }
  } catch {
    return { ok: false, mensagem: "Não foi possível alterar. Tente de novo." };
  }

  revalidatePath(`/app/configuracoes/${definicao.slug}`);
  return { ok: true };
}

/**
 * T014 — grava a meta de um mês.
 *
 * `goals` tem `UNIQUE(clinic_id, month, year)`, então existe no máximo uma linha
 * por mês. O `id` decide entre criar e atualizar, e ele vem da leitura da
 * própria tela.
 *
 * Números vazios viram `0`, e não `null`: a coluna já tem `DEFAULT 0`, e meta
 * não informada é meta zero, não meta desconhecida. A diferença aparece na hora
 * de somar: `null` propaga para o total e some com o número.
 */
export async function salvarMeta(form: FormData): Promise<ResultadoDeAcao> {
  const t = comoTexto(form);

  const ano = Math.floor(Number(t.ano));
  const mes = Math.floor(Number(t.mes));
  if (!Number.isFinite(ano) || ano < 2000 || ano > 2100) {
    return { ok: false, mensagem: "Ano inválido." };
  }
  if (!Number.isFinite(mes) || mes < 1 || mes > 12) {
    return { ok: false, mensagem: "Mês inválido." };
  }

  const numero = (chave: string) => {
    const n = interpretaNumero(t[chave] ?? "");
    return n === null || n < 0 ? 0 : n;
  };

  const valores = {
    year: ano,
    month: mes,
    revenue_target: Number(numero("revenue_target").toFixed(2)),
    new_patients_target: Math.floor(numero("new_patients_target")),
    closings_target: Math.floor(numero("closings_target")),
    conversion_target: Math.min(100, Number(numero("conversion_target").toFixed(2))),
  };

  const id = (t.id ?? "").trim();

  try {
    const supabase = await createClient();

    if (id === "") {
      const { error } = await supabase.from("goals").insert(valores as never);
      if (error) return { ok: false, mensagem: error.message };
    } else {
      const { data, error } = await supabase
        .from("goals")
        .update(valores as never)
        .eq("id", id)
        .select("id");
      if (error) return { ok: false, mensagem: error.message };
      if (!data || data.length === 0) {
        return { ok: false, mensagem: "Nada foi alterado." };
      }
    }
  } catch {
    return { ok: false, mensagem: "Não foi possível salvar a meta." };
  }

  revalidatePath("/app/configuracoes/metas");
  return { ok: true };
}

/**
 * T011 — grava as regras de negócio da clínica.
 *
 * # A regra que esta action existe para não deixar escapar
 *
 * `confirmation_hours` é exibida em DIAS e armazenada em HORAS. A conversão
 * mora em `regras.ts`, é pura e tem a ida e volta testada de 1 a 30 dias. Aqui
 * ela só é chamada, e é por isso que não há multiplicação por 24 solta neste
 * arquivo: cada lugar que multiplicasse por conta própria seria um lugar novo
 * para a regra divergir.
 *
 * # Por que UPSERT e não INSERT ou UPDATE
 *
 * A clínica pode não ter a linha ainda, e a tela mostra os padrões nesse caso.
 * O primeiro salvamento tem de criar; os seguintes, atualizar. Decidir na
 * aplicação qual dos dois é o caso exigiria uma leitura antes da escrita, com
 * a corrida entre as duas.
 */
export async function salvarRegras(form: FormData): Promise<ResultadoDeAcao> {
  const t = comoTexto(form);

  const dias = (chave: string, padrao: number) =>
    normalizaDias(t[chave], padrao);

  const valores = {
    followup_days: dias("followup_days", 7),
    recapture_days: dias("recapture_days", 30),
    recall_days: dias("recall_days", 180),
    satisfaction_survey_days: dias("satisfaction_survey_days", 1),
    anamnesis_send_days: dias("anamnesis_send_days", 1),
    confirmation_hours: diasParaHoras(dias("confirmation_days", 1)),
    work_saturday: t.work_saturday === "on" || t.work_saturday === "true",
    // O terceiro argumento é o PISO: campos que a clínica não consegue
    // desmarcar. Paciente sem nome e consulta sem paciente não são
    // configuração, são registro quebrado, e a normalização os devolve
    // mesmo quando o formulário não os manda.
    patient_required_fields: normalizaCamposObrigatorios(
      form.getAll("patient_required_fields").filter((v) => typeof v === "string"),
      CAMPOS_DE_PACIENTE,
      PISO_PACIENTE,
    ),
    appointment_required_fields: normalizaCamposObrigatorios(
      form.getAll("appointment_required_fields").filter((v) => typeof v === "string"),
      CAMPOS_DE_AGENDAMENTO,
      PISO_AGENDAMENTO,
    ),
  };

  const id = (t.id ?? "").trim();

  try {
    const supabase = await createClient();

    if (id === "") {
      const { error } = await supabase
        .from("business_rules")
        .insert(valores as never);
      if (error) return { ok: false, mensagem: error.message };
    } else {
      const { data, error } = await supabase
        .from("business_rules")
        .update(valores as never)
        .eq("id", id)
        .select("id");
      if (error) return { ok: false, mensagem: error.message };
      if (!data || data.length === 0) {
        return { ok: false, mensagem: "Nada foi alterado." };
      }
    }
  } catch {
    return { ok: false, mensagem: "Não foi possível salvar. Tente de novo." };
  }

  revalidatePath("/app/configuracoes");
  return { ok: true };
}
