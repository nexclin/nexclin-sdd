"use server";

/**
 * SPEC 003 — as escritas do painel superadmin.
 *
 * # O estado que estas actions consertam
 *
 * Medido em 26/08: as onze telas do painel existiam e **a única escrita em todo
 * o `app/superadmin/` era a impersonação**. Dava para ver conta, plano e
 * faturamento, e não dava para mudar nada. O superadmin é quem libera plano,
 * define cobrança e suspende quem não paga, e nada disso tinha caminho.
 *
 * # Onde mora a autorização
 *
 * Na RLS, e não aqui. `plans`, `account_subscriptions` e `clinics` já têm
 * policy `FOR ALL` exigindo `is_superadmin(auth.uid())`. Repetir a checagem
 * nestas funções criaria uma segunda fonte de verdade sobre quem é operador, e
 * as duas divergiriam no dia em que alguém mudasse uma só.
 *
 * O que estas actions garantem é o que a RLS não sabe: **que a mudança de
 * status é legal** (`cancelled` não volta) e **que a data de cobrança existe no
 * calendário** (dia 31 em fevereiro).
 *
 * # Auditoria
 *
 * Toda escrita aqui grava em `superadmin_audit_log`, e a trigger de
 * `20260826010000` põe sozinha a linha correspondente na linha do tempo da
 * conta. É a regra (d) da constituição, e nenhuma destas funções precisa saber
 * que a segunda tabela existe.
 */

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";
import { interpretaNumero } from "@/lib/config/entrada";
import { MODULE_KEYS } from "@/lib/auth/modulos";
import {
  diaDaCobranca,
  ehStatus,
  normalizaDiaDeCobranca,
  podeTransicionar,
  proximaCobranca,
  type StatusDeAssinatura,
} from "./assinatura";

export interface ResultadoDeAcao {
  ok: boolean;
  mensagem?: string;
}

function texto(form: FormData, chave: string): string {
  const v = form.get(chave);
  return typeof v === "string" ? v.trim() : "";
}

/**
 * Registra a ação no log de auditoria.
 *
 * Nunca lança, e a razão é desconfortável mas correta: se a auditoria falhar
 * **depois** de a escrita ter acontecido, derrubar a action mostraria erro para
 * uma mudança que já está no banco, e o operador tentaria de novo. Duas
 * mudanças, uma mensagem de erro. O caminho honesto é a escrita valer e a falha
 * de auditoria aparecer no log do servidor.
 *
 * A ordem, então, é sempre: escrever primeiro, auditar depois.
 */
async function audita(
  supabase: Awaited<ReturnType<typeof createClient>>,
  clinicId: string | null,
  action: string,
  anterior: unknown,
  novo: unknown,
  motivo?: string,
) {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;

    const { data: operador } = await supabase
      .from("superadmin_operators")
      .select("id")
      .eq("user_id", user.id)
      .maybeSingle();

    await supabase.from("superadmin_audit_log").insert({
      operator_id: operador?.id ?? null,
      action,
      clinic_id: clinicId,
      previous_state: anterior as never,
      new_state: novo as never,
      reason: motivo ?? null,
    } as never);
  } catch (e) {
    console.error("Falha ao auditar a acao do superadmin:", action, e);
  }
}

/**
 * Cria ou edita um plano.
 *
 * `enabled_modules` é montado a partir das 15 ModuleKeys, e **só delas**: a
 * chave vem do contrato, não do formulário. Chave inventada no navegador não
 * teria como entrar, e o trigger do banco recusaria de qualquer forma, o que
 * daria um erro incompreensível em vez de simplesmente ignorar o que não
 * existe.
 *
 * O objeto é completo, com `false` explícito para o que está desmarcado. Chave
 * ausente já vale como `false` na cascata, e gravar explícito faz o editor
 * mostrar o mesmo que o banco guarda, sem a diferença entre "desligado" e "não
 * mencionado".
 */
export async function salvarPlano(form: FormData): Promise<ResultadoDeAcao> {
  const id = texto(form, "id");
  const nome = texto(form, "name");
  if (nome === "") return { ok: false, mensagem: "O nome do plano é obrigatório." };

  const mensal = interpretaNumero(texto(form, "monthly_price"));
  if (mensal === null || mensal < 0) {
    return { ok: false, mensagem: "Mensalidade inválida." };
  }
  const anual = interpretaNumero(texto(form, "annual_price")) ?? 0;
  if (anual < 0) return { ok: false, mensagem: "Preço anual inválido." };

  const inteiroOuZero = (chave: string) => {
    const n = interpretaNumero(texto(form, chave));
    return n === null || n < 0 ? 0 : Math.floor(n);
  };

  const marcados = new Set(
    form.getAll("modulos").filter((v): v is string => typeof v === "string"),
  );
  const enabled_modules: Record<string, boolean> = {};
  for (const chave of MODULE_KEYS) enabled_modules[chave] = marcados.has(chave);

  const valores = {
    name: nome,
    description: texto(form, "description"),
    monthly_price: Number(mensal.toFixed(2)),
    annual_price: Number(anual.toFixed(2)),
    trial_days: inteiroOuZero("trial_days"),
    // Zero significa ILIMITADO nesta tabela, e não "nenhum": é o default da
    // coluna desde o começo, e mudar o sentido agora reinterpretaria todos os
    // planos existentes de uma vez.
    max_users: inteiroOuZero("max_users"),
    max_patients: inteiroOuZero("max_patients"),
    max_leads_month: inteiroOuZero("max_leads_month"),
    enabled_modules,
    status: texto(form, "status") === "inactive" ? "inactive" : "active",
    visibility: texto(form, "visibility") === "hidden" ? "hidden" : "public",
  };

  try {
    const supabase = await createClient();

    if (id === "") {
      const { data, error } = await supabase
        .from("plans")
        .insert(valores as never)
        .select("id")
        .single();
      if (error) return { ok: false, mensagem: error.message };
      await audita(supabase, null, "plan_create", null, { id: data?.id, ...valores });
    } else {
      const { data: antes } = await supabase
        .from("plans")
        .select("name, monthly_price, annual_price, enabled_modules, status, visibility")
        .eq("id", id)
        .maybeSingle();

      const { data, error } = await supabase
        .from("plans")
        .update(valores as never)
        .eq("id", id)
        .select("id");
      if (error) return { ok: false, mensagem: error.message };
      if (!data || data.length === 0) {
        return { ok: false, mensagem: "Nada foi alterado. O plano pode não existir mais." };
      }
      await audita(supabase, null, "plan_edit", antes, valores);
    }
  } catch {
    return { ok: false, mensagem: "Não foi possível salvar o plano." };
  }

  revalidatePath("/superadmin/planos");
  revalidatePath("/superadmin/contas");
  return { ok: true };
}

/**
 * Muda o plano, o status e a data de cobrança de uma conta.
 *
 * As três juntas de propósito: são o mesmo ato do ponto de vista de quem opera
 * ("colocar o cliente no plano Pro, ativo, cobrando dia 10"), e separá-las em
 * três botões criaria estados intermediários que ninguém quis, como conta ativa
 * sem plano.
 */
export async function salvarAssinatura(form: FormData): Promise<ResultadoDeAcao> {
  const clinicId = texto(form, "clinic_id");
  const assinaturaId = texto(form, "id");
  if (clinicId === "") return { ok: false, mensagem: "Conta não informada." };

  const statusAtual = texto(form, "status_atual");
  const statusNovo = texto(form, "status");
  if (!ehStatus(statusAtual) || !ehStatus(statusNovo)) {
    return { ok: false, mensagem: "Status inválido." };
  }
  if (!podeTransicionar(statusAtual as StatusDeAssinatura, statusNovo as StatusDeAssinatura)) {
    return {
      ok: false,
      mensagem:
        statusAtual === "cancelled"
          ? "Conta cancelada não é reativada. Crie uma assinatura nova, que fica registrada como ato próprio."
          : `Não é permitido ir de "${statusAtual}" para "${statusNovo}".`,
    };
  }

  const planoId = texto(form, "plan_id");
  const diaBruto = texto(form, "dia_de_cobranca");
  const dia = diaBruto === "" ? null : normalizaDiaDeCobranca(diaBruto);
  if (diaBruto !== "" && dia === null) {
    return { ok: false, mensagem: "O dia de cobrança precisa estar entre 1 e 31." };
  }

  const valores: Record<string, unknown> = {
    plan_id: planoId === "" ? null : planoId,
    status: statusNovo,
    updated_at: new Date().toISOString(),
  };

  if (dia !== null) {
    const proxima = proximaCobranca(dia, new Date());
    valores.current_period_start = new Date().toISOString();
    valores.current_period_end = proxima.toISOString();
  }

  // Cancelar carimba quando e por quê. Sem isso o histórico não diz se a conta
  // saiu ontem ou em março.
  if (statusNovo === "cancelled" && statusAtual !== "cancelled") {
    valores.cancelled_at = new Date().toISOString();
    valores.cancel_reason = texto(form, "motivo") || null;
  }
  // Ativar pela primeira vez marca o início. Reativar uma suspensa não mexe:
  // a relação começou antes.
  if (statusNovo === "active" && statusAtual === "trial") {
    valores.started_at = new Date().toISOString();
  }

  try {
    const supabase = await createClient();

    const { data: antes } = await supabase
      .from("account_subscriptions")
      .select("plan_id, status, current_period_end")
      .eq("clinic_id", clinicId)
      .maybeSingle();

    if (assinaturaId === "" && !antes) {
      const { error } = await supabase
        .from("account_subscriptions")
        .insert({ clinic_id: clinicId, ...valores } as never);
      if (error) return { ok: false, mensagem: error.message };
    } else {
      const { data, error } = await supabase
        .from("account_subscriptions")
        .update(valores as never)
        .eq("clinic_id", clinicId)
        .select("id");
      if (error) return { ok: false, mensagem: error.message };
      if (!data || data.length === 0) {
        return { ok: false, mensagem: "Nada foi alterado." };
      }
    }

    await audita(
      supabase,
      clinicId,
      "subscription_change",
      antes,
      {
        plan_id: valores.plan_id,
        status: statusNovo,
        current_period_end: valores.current_period_end ?? antes?.current_period_end ?? null,
        dia_de_cobranca: dia ?? diaDaCobranca(antes?.current_period_end as string | null),
      },
      texto(form, "motivo") || undefined,
    );
  } catch {
    return { ok: false, mensagem: "Não foi possível salvar a assinatura." };
  }

  revalidatePath(`/superadmin/contas/${clinicId}`);
  revalidatePath("/superadmin/contas");
  return { ok: true };
}

export interface ResultadoDeCriacao extends ResultadoDeAcao {
  clinicId?: string;
}

/**
 * Cria a conta de uma clínica: a clínica, a assinatura e a linha do dono.
 *
 * # O que esta função NÃO faz, e é decisão de segurança
 *
 * Ela **não cria o usuário de login**, e não é por falta de vontade. A edge
 * function de convite deriva a clínica do **perfil de quem chama**, e o
 * comentário dela é explícito: *"é ela que o convidado herda, nunca uma vinda do
 * body"*. Essa guarda existe para que ninguém consiga convidar alguém para uma
 * clínica arbitrária mandando o id no corpo da requisição.
 *
 * Acrescentar um caminho privilegiado que aceitasse `clinic_id` de fora
 * desmontaria justamente essa guarda, e criaria a segunda porta que a SPEC 003
 * manda não existir.
 *
 * O fluxo, então, tem dois passos e os dois já são auditados:
 *
 *   1. aqui: a conta nasce, com plano e data de cobrança;
 *   2. **Entrar na conta** (impersonação, auditada) e convidar o dono pela tela
 *      de equipe, que usa a função de convite existente, sem senha.
 *
 * Dois passos em vez de um, e nenhuma porta nova. A tela diz isso na cara para
 * ninguém achar que a conta ficou pela metade por engano.
 *
 * A linha do dono já é criada aqui, em `team_members`, com `permission_level`
 * master e sem `user_id`. É ela que o convite preenche depois, e deixá-la
 * pronta evita que alguém convide o dono como operacional por descuido.
 */
export async function criarConta(form: FormData): Promise<ResultadoDeCriacao> {
  const nome = texto(form, "name");
  if (nome === "") return { ok: false, mensagem: "O nome da clínica é obrigatório." };

  const donoNome = texto(form, "owner_name");
  const donoEmail = texto(form, "owner_email");
  if (donoNome === "") return { ok: false, mensagem: "O nome do responsável é obrigatório." };
  if (donoEmail !== "" && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(donoEmail)) {
    return { ok: false, mensagem: "E-mail do responsável inválido." };
  }

  const statusNovo = texto(form, "status");
  if (!ehStatus(statusNovo)) return { ok: false, mensagem: "Status inválido." };
  if (statusNovo === "cancelled" || statusNovo === "suspended") {
    // Nascer suspensa ou cancelada não descreve nenhuma situação real, e
    // deixaria o cliente sem acesso na hora em que ele mais espera ter.
    return { ok: false, mensagem: "Conta nova começa em teste, ativa ou em atraso." };
  }

  const planoId = texto(form, "plan_id");
  const diaBruto = texto(form, "dia_de_cobranca");
  const dia = diaBruto === "" ? null : normalizaDiaDeCobranca(diaBruto);
  if (diaBruto !== "" && dia === null) {
    return { ok: false, mensagem: "O dia de cobrança precisa estar entre 1 e 31." };
  }

  try {
    const supabase = await createClient();

    const { data: clinica, error: erroClinica } = await supabase
      .from("clinics")
      .insert({ name: nome } as never)
      .select("id")
      .single();

    if (erroClinica || !clinica) {
      return { ok: false, mensagem: erroClinica?.message ?? "Não foi possível criar a clínica." };
    }

    const clinicId = (clinica as { id: string }).id;
    const agora = new Date();

    const assinatura: Record<string, unknown> = {
      clinic_id: clinicId,
      plan_id: planoId === "" ? null : planoId,
      status: statusNovo,
      started_at: agora.toISOString(),
    };
    if (statusNovo === "trial") {
      assinatura.trial_start = agora.toISOString();
      const dias = Math.max(1, Math.floor(Number(texto(form, "trial_days")) || 14));
      assinatura.trial_end = new Date(
        agora.getTime() + dias * 24 * 60 * 60 * 1000,
      ).toISOString();
    }
    if (dia !== null) {
      assinatura.current_period_start = agora.toISOString();
      assinatura.current_period_end = proximaCobranca(dia, agora).toISOString();
    }

    // A trigger `clinics_cria_assinatura_de_trial` (migração 20260825080000) já
    // pode ter criado a assinatura no INSERT acima. Por isso é UPDATE quando ela
    // existe, e não um INSERT que estouraria o UNIQUE(clinic_id).
    const { data: jaExiste } = await supabase
      .from("account_subscriptions")
      .select("id")
      .eq("clinic_id", clinicId)
      .maybeSingle();

    if (jaExiste) {
      const { clinic_id: _ignora, ...semClinica } = assinatura;
      void _ignora;
      await supabase
        .from("account_subscriptions")
        .update(semClinica as never)
        .eq("clinic_id", clinicId);
    } else {
      await supabase.from("account_subscriptions").insert(assinatura as never);
    }

    // `invite_status` só é informado quando há e-mail. Sem e-mail não há
    // convite pendente, e inventar um terceiro valor para essa situação
    // acrescentaria um estado que nenhuma outra parte do sistema conhece.
    const dono: Record<string, unknown> = {
      clinic_id: clinicId,
      name: donoNome,
      email: donoEmail,
      role: "admin",
      permission_level: "master",
      active: true,
    };
    if (donoEmail !== "") dono.invite_status = "pending";

    await supabase.from("team_members").insert(dono as never);

    await audita(supabase, clinicId, "account_create", null, {
      name: nome,
      owner_name: donoNome,
      owner_email: donoEmail || null,
      plan_id: planoId || null,
      status: statusNovo,
      dia_de_cobranca: dia,
    });

    revalidatePath("/superadmin/contas");
    return { ok: true, clinicId };
  } catch {
    return { ok: false, mensagem: "Não foi possível criar a conta." };
  }
}
