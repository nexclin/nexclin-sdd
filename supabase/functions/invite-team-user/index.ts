// SPEC 002 / T017 — convite de membro de equipe SEM senha definida por terceiro.
//
// Histórico: a versão portada na SPEC 001 (T014) recebia `password` em texto e
// deixava o admin da clínica escolher a senha inicial do convidado. Isso viola
// o Princípio II da constituição e a regra (e) do CLAUDE.md — "senha de cliente
// jamais é definida por admin". Estava em produção; corrigido na janela de
// 22-23/08/2026, antecipado para não competir com a bateria de correções.
//
// Como ficou: a função não aceita, não transporta e não gera senha em lugar
// nenhum. `generateLink({ type: "invite" })` cria o usuário em estado de convite
// e devolve o link de acesso; quem digita a senha é o próprio convidado, em
// /nova-senha, depois de o link autenticá-lo em /auth/callback.
//
// Por que o link volta na resposta em vez de ir por e-mail: a entrega
// transacional ainda não está de pé (o SMTP embutido comprovadamente não
// entrega — specs/001-fundacao-superadmin/research.md R5) e o Resend só entra
// na SPEC 003. Até lá o admin repassa o link ao convidado por fora. A fronteira
// que importa continua respeitada: ninguém além do dono da conta escolhe a
// senha dela. Quando o Resend entrar, troque `generateLink` por
// `inviteUserByEmail` e pare de devolver `action_link` — o resto não muda.

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
    const SITE_URL = Deno.env.get("SITE_URL") ?? "";

    // Autentica o chamador
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace("Bearer ", "");
    if (!token) return json({ error: "Não autenticado" }, 401);

    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: "Token inválido" }, 401);

    const body = await req.json();
    const { email, full_name, team_member_id } = body;

    // Recusa explícita: um front desatualizado que ainda mande senha precisa
    // falhar alto, não ser ignorado em silêncio. É isto que prova que o
    // caminho fechou.
    if ("password" in body) {
      return json(
        {
          error:
            "Este endpoint não aceita mais senha. O convidado define a própria " +
            "senha pelo link devolvido em `action_link` (Princípio II).",
        },
        400,
      );
    }

    if (!email || !full_name) {
      return json({ error: "Campos obrigatórios: email, full_name" }, 400);
    }

    // Autorização: convidar é ação do módulo `equipe`. O banco decide, não a
    // tela — my_permission() roda com a identidade do chamador e já aplica a
    // cascata (plano é o teto, default deny).
    const { data: permissao, error: permErr } = await userClient.rpc("my_permission", {
      _module: "equipe",
    });
    if (permErr) return json({ error: permErr.message }, 400);
    if (permissao !== "full") {
      return json({ error: "Sem permissão para convidar na equipe" }, 403);
    }

    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE);

    // Clínica do chamador — é ela que o convidado herda, nunca uma vinda do body
    const { data: profile } = await adminClient
      .from("profiles")
      .select("clinic_id")
      .eq("user_id", userData.user.id)
      .single();
    if (!profile?.clinic_id) {
      return json({ error: "Clínica não encontrada" }, 400);
    }

    // Cria o convidado e gera o link. Nenhuma senha entra, sai ou é gravada.
    // O metadata é o que o trigger handle_new_user lê para vincular à clínica.
    const { data: convite, error: conviteErr } = await adminClient.auth.admin.generateLink({
      type: "invite",
      email,
      options: {
        data: {
          full_name,
          invite_clinic_id: profile.clinic_id,
          invite_team_member_id: team_member_id || null,
        },
        ...(SITE_URL ? { redirectTo: `${SITE_URL}/auth/callback?next=/nova-senha` } : {}),
      },
    });
    if (conviteErr) {
      const jaExiste = /already|registered|exists/i.test(conviteErr.message);
      return json(
        {
          error: jaExiste
            ? "Já existe conta com este e-mail. Use recuperação de senha em vez de convite."
            : conviteErr.message,
        },
        400,
      );
    }

    const novoUsuario = convite.user;
    const actionLink = convite.properties?.action_link;

    // Garantia extra: o trigger handle_new_user já vincula, mas reforçamos aqui
    if (team_member_id) {
      await adminClient
        .from("team_members")
        .update({ email, user_id: novoUsuario.id, invite_status: "pending" })
        .eq("id", team_member_id)
        .eq("clinic_id", profile.clinic_id);
    }

    // action_link é credencial de uso único: devolvido ao chamador e nunca
    // registrado em log.
    return json({ ok: true, user_id: novoUsuario.id, action_link: actionLink });
  } catch (e) {
    return json({ error: (e as Error).message }, 500);
  }
});
