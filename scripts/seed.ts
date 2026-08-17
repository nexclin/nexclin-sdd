/**
 * SPEC 001 / Fase 2 — Seed idempotente (T007–T010).
 *
 * Roda com a SERVICE ROLE, fora do bundle do app. Cria/garante:
 *   a. Plano "Trial Padrão" (15 ModuleKeys=true, limites NULL, hidden, trial 14).
 *   b. saas_settings singleton (trial_default_plan_id + trial_default_days=14).
 *   c. Usuário auth SUPERADMIN_EMAIL (senha ALEATÓRIA descartada — a senha real
 *      é definida pelo operador via recovery no painel; NUNCA por código/env).
 *   d. Registro em superadmin_operators (role super_owner, active=true).
 *
 * IDEMPOTENTE: rodar 2x não duplica nada (constituição, Princípio II e V).
 *
 * NOTA: as migrações (20260725033102) já semeiam o plano Trial + apontam o
 * saas_settings. Este seed é defensivo: só cria o que faltar. O trabalho que
 * NÃO vem das migrações é o superadmin (o trigger de e-mail fixo foi dropado).
 *
 * Como rodar (Fase 2, após db push):
 *   1. Preencher .env.local (NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 *      SUPERADMIN_EMAIL).
 *   2. Instalar deps: npm i @supabase/supabase-js dotenv
 *   3. npx tsx scripts/seed.ts
 */

import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { config } from "dotenv";

// Carrega .env.local (convenção do projeto) com fallback para .env.
config({ path: ".env.local" });
config();

const MODULE_KEYS = [
  "dashboard", "leads", "pacientes", "anamnese", "consultas", "acompanhamento",
  "tarefas", "contas_receber", "contas_pagar", "fluxo_caixa",
  "relatorios_vendas", "relatorios_demais", "configuracoes", "equipe", "insights",
] as const;

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) {
    console.error(`ERRO: variável de ambiente ausente: ${name}`);
    process.exit(1);
  }
  return v;
}

const SUPABASE_URL =
  process.env.NEXT_PUBLIC_SUPABASE_URL ?? requireEnv("SUPABASE_URL");
const SERVICE_ROLE_KEY = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
const SUPERADMIN_EMAIL = requireEnv("SUPERADMIN_EMAIL");

const admin: SupabaseClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

/** a. Garante o plano Trial Padrão; retorna o id. */
async function ensureTrialPlan(): Promise<string> {
  const { data: existing, error: selErr } = await admin
    .from("plans")
    .select("id")
    .eq("is_default_trial", true)
    .limit(1)
    .maybeSingle();
  if (selErr) throw selErr;
  if (existing?.id) {
    console.log("• plano Trial Padrão já existe:", existing.id);
    return existing.id;
  }

  const enabledModules = Object.fromEntries(MODULE_KEYS.map((k) => [k, true]));
  const { data, error } = await admin
    .from("plans")
    .insert({
      name: "Trial Padrão",
      description: "Plano de avaliação com acesso completo",
      is_default_trial: true,
      status: "active",
      visibility: "hidden",
      monthly_price: 0,
      annual_price: 0,
      trial_days: 14,
      max_users: null,
      max_patients: null,
      max_leads_month: null,
      enabled_modules: enabledModules,
    })
    .select("id")
    .single();
  if (error) throw error;
  console.log("• plano Trial Padrão criado:", data.id);
  return data.id;
}

/** b. Garante o singleton saas_settings apontando ao plano Trial. */
async function ensureSaasSettings(trialPlanId: string): Promise<void> {
  const { data: existing, error: selErr } = await admin
    .from("saas_settings")
    .select("id, trial_default_plan_id")
    .limit(1)
    .maybeSingle();
  if (selErr) throw selErr;

  if (!existing) {
    const { error } = await admin.from("saas_settings").insert({
      trial_default_days: 14,
      trial_default_plan_id: trialPlanId,
    });
    if (error) throw error;
    console.log("• saas_settings criado (singleton).");
    return;
  }
  if (existing.trial_default_plan_id !== trialPlanId) {
    const { error } = await admin
      .from("saas_settings")
      .update({ trial_default_plan_id: trialPlanId, trial_default_days: 14 })
      .eq("id", existing.id);
    if (error) throw error;
    console.log("• saas_settings atualizado (aponta ao plano Trial).");
  } else {
    console.log("• saas_settings já consistente.");
  }
}

/** Procura um usuário auth por e-mail paginando a admin API. */
async function findAuthUserByEmail(email: string): Promise<string | null> {
  const target = email.toLowerCase();
  for (let page = 1; page <= 50; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw error;
    const hit = data.users.find((u) => (u.email ?? "").toLowerCase() === target);
    if (hit) return hit.id;
    if (data.users.length < 200) break;
  }
  return null;
}

/** c+d. Garante o usuário superadmin e seu registro em superadmin_operators. */
async function ensureSuperadmin(): Promise<void> {
  let userId = await findAuthUserByEmail(SUPERADMIN_EMAIL);

  if (!userId) {
    // Senha aleatória descartada — nunca logada, nunca persistida.
    // ATENÇÃO ao comprimento: o GoTrue trunca em 72 caracteres (limite do
    // bcrypt) e, acima disso, responde 500 com corpo vazio — erro que não diz
    // nada. Um UUID v4 já traz 122 bits de entropia; dois eram desperdício que
    // estourava o limite. Não volte a concatenar UUIDs aqui.
    const randomPassword = globalThis.crypto.randomUUID() + "Aa9!";
    const { data, error } = await admin.auth.admin.createUser({
      email: SUPERADMIN_EMAIL,
      password: randomPassword,
      email_confirm: true,
      user_metadata: { full_name: "Super Owner" },
    });
    if (error) throw error;
    userId = data.user.id;
    console.log("• usuário superadmin criado:", SUPERADMIN_EMAIL);
    console.log("  -> defina a senha real via recovery no painel Supabase (T012).");
  } else {
    console.log("• usuário superadmin já existe:", SUPERADMIN_EMAIL);
  }

  const { error } = await admin
    .from("superadmin_operators")
    .upsert(
      {
        user_id: userId,
        name: "Super Owner",
        email: SUPERADMIN_EMAIL,
        role: "super_owner",
        active: true,
      },
      { onConflict: "user_id" },
    );
  if (error) throw error;
  console.log("• superadmin_operators garantido (super_owner, active).");
}

async function main(): Promise<void> {
  console.log("== seed NexClin (idempotente) ==");
  const trialPlanId = await ensureTrialPlan();
  await ensureSaasSettings(trialPlanId);
  await ensureSuperadmin();
  console.log("== seed concluído com sucesso ==");
}

main().catch((err) => {
  console.error("seed FALHOU:", err?.message ?? err);
  process.exit(1);
});
