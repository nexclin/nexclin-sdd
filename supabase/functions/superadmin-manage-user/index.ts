// SPEC 001 / Fase 3 (T013) — portada de ../nexclin-lovable com UMA adaptação
// de conformidade: a action `set_password` foi REMOVIDA. A referência a
// mantinha para "cleanup de testes / emergência", mas definir senha de cliente
// por admin viola a constituição (Princípio II / regra (e): senha jamais é
// definida por admin — somente reset por e-mail). Restam apenas as ações
// auditadas update_email e send_password_reset.
//
// Guardas mantidas: bearer + is_superadmin (checado no banco). Secrets
// (SUPABASE_URL, SERVICE_ROLE, ANON) injetados pelo runtime do projeto novo.

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

    // 1. Authenticate caller
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace("Bearer ", "");
    if (!token) return json({ error: "Não autenticado" }, 401);

    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: "Token inválido" }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

    // 2. Verify is_superadmin via DB
    const { data: isSuperData, error: isSuperErr } = await admin.rpc("is_superadmin", {
      _user_id: userData.user.id,
    });
    if (isSuperErr) return json({ error: isSuperErr.message }, 500);
    if (!isSuperData) return json({ error: "Acesso negado" }, 403);

    const { data: operator } = await admin
      .from("superadmin_operators")
      .select("id")
      .eq("user_id", userData.user.id)
      .eq("active", true)
      .maybeSingle();
    const operatorId = operator?.id ?? null;

    const body = await req.json().catch(() => ({}));
    const { action } = body ?? {};

    // Helper to fetch target user's profile clinic_id + current email
    const loadTarget = async (targetUserId: string) => {
      const [{ data: prof }, { data: authUser }] = await Promise.all([
        admin.from("profiles").select("clinic_id").eq("user_id", targetUserId).maybeSingle(),
        admin.auth.admin.getUserById(targetUserId),
      ]);
      return {
        clinic_id: prof?.clinic_id ?? null,
        email: authUser?.user?.email ?? null,
      };
    };

    // 3a. update_email (auditado old→new)
    if (action === "update_email") {
      const { user_id, new_email } = body;
      if (!user_id || !new_email) return json({ error: "user_id e new_email obrigatórios" }, 400);
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(String(new_email))) return json({ error: "E-mail inválido" }, 400);

      const target = await loadTarget(user_id);
      if (!target.email) return json({ error: "Usuário alvo não encontrado" }, 404);

      const { error: updErr } = await admin.auth.admin.updateUserById(user_id, {
        email: new_email,
        email_confirm: true,
      });
      if (updErr) return json({ error: updErr.message }, 400);

      await admin.from("superadmin_audit_log").insert({
        operator_id: operatorId,
        action: "email_change",
        clinic_id: target.clinic_id,
        previous_state: { target_user_id: user_id, email: target.email },
        new_state: { email: new_email },
      });

      return json({ ok: true });
    }

    // 3b. send_password_reset (via resetPasswordForEmail; auditado)
    if (action === "send_password_reset") {
      const { user_id } = body;
      if (!user_id) return json({ error: "user_id obrigatório" }, 400);

      const target = await loadTarget(user_id);
      if (!target.email) return json({ error: "Usuário alvo não encontrado" }, 404);

      const publicClient = createClient(SUPABASE_URL, ANON_KEY);
      const { error: linkErr } = await publicClient.auth.resetPasswordForEmail(
        target.email,
      );
      if (linkErr) return json({ error: linkErr.message }, 400);

      await admin.from("superadmin_audit_log").insert({
        operator_id: operatorId,
        action: "password_reset_sent",
        clinic_id: target.clinic_id,
        new_state: { target_user_id: user_id, email: target.email },
      });

      return json({ ok: true });
    }

    // set_password: REMOVIDA por conformidade (constituição, regra (e)).
    return json({ error: "Action inválida" }, 400);
  } catch (e) {
    return json({ error: (e as Error).message }, 500);
  }
});
