// SPEC 001 / Fase 3 (T014) — portada de ../nexclin-lovable.
// Adaptação mínima: import normalizado para o especificador npm: (mesmo padrão
// da superadmin-manage-user). Comportamento preservado: cria o usuário
// convidado com metadata que o trigger handle_new_user usa para vincular à
// clínica; reforça o vínculo em team_members. Secrets injetados pelo runtime.
//
// RESSALVA (registrada em specs/BACKLOG.md): esta função recebe `password` em
// texto e o admin define a senha inicial do convidado. O caminho preferido
// (convite por e-mail, convidado define a própria senha) está no backlog e
// será re-especificado — mantido aqui como paridade com o MVP validado.

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

    // Authenticate caller
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace("Bearer ", "");
    if (!token) return json({ error: "Não autenticado" }, 401);

    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: "Token inválido" }, 401);

    const body = await req.json();
    const { email, password, full_name, team_member_id } = body;

    if (!email || !password || !full_name) {
      return json({ error: "Campos obrigatórios: email, password, full_name" }, 400);
    }

    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE);

    // Get caller clinic_id
    const { data: profile } = await adminClient
      .from("profiles")
      .select("clinic_id")
      .eq("user_id", userData.user.id)
      .single();
    if (!profile?.clinic_id) {
      return json({ error: "Clínica não encontrada" }, 400);
    }

    // Create user with auto-confirm; metadata sinaliza ao trigger que é convidado
    const { data: created, error: createErr } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name,
        invite_clinic_id: profile.clinic_id,
        invite_team_member_id: team_member_id || null,
      },
    });
    if (createErr) return json({ error: createErr.message }, 400);

    // Garantia extra: o trigger handle_new_user já vincula, mas reforçamos aqui
    if (team_member_id) {
      await adminClient
        .from("team_members")
        .update({ email, user_id: created.user.id, invite_status: "active" })
        .eq("id", team_member_id)
        .eq("clinic_id", profile.clinic_id);
    }

    return json({ ok: true, user_id: created.user.id });
  } catch (e) {
    return json({ error: (e as Error).message }, 500);
  }
});
