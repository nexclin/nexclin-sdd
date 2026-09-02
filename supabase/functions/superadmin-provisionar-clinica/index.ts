// superadmin-provisionar-clinica
//
// Cria a conta de uma clinica nova, com o dono ja podendo entrar. Existe para o
// modelo de implantacao da NexClin: a empresa entrega a plataforma configurada e
// o cliente so chega e usa.
//
// A SENHA E DEFINIDA AQUI, e isso e permitido desde a emenda de 28/08/2026 a
// Secao II da constituicao. A emenda tem cinco condicoes, e este arquivo cumpre
// as cinco:
//
//   1. so o superadmin chama            -> `is_superadmin` verificado no banco
//   2. so ao provisionar conta nova     -> nao ha caminho aqui para trocar senha
//                                          de usuario existente
//   3. gera auditoria                   -> `superadmin_audit_log`
//   4. senha nunca gravada em claro     -> nao vai para o log nem para a
//                                          resposta, e nao e persistida
//   5. o dono pode trocar               -> fluxo normal de reset continua valendo
//
// Admin ou membro de clinica continua PROIBIDO de definir senha de outro
// usuario. A permissao e deste caminho, e nao do produto.
//
// # Por que criar o usuario e nao a clinica
//
// O gatilho `handle_new_user` em `auth.users` ja cria clinica, perfil, papel de
// admin, regras de negocio, o membro mestre da equipe, o plano de contas, os
// tipos de fechamento, os servicos nativos e a conta "Caixa (dinheiro)". Ele le
// tudo de `raw_user_meta_data`.
//
// Criar a clinica aqui a mao duplicaria esse corpo, e a copia envelheceria na
// primeira vez que o gatilho mudasse. E o Principio VIII, Uma Regra Uma Fonte:
// este arquivo passa os metadados certos e deixa o gatilho fazer o que ele ja
// sabe fazer.

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

    // 1. Quem esta chamando
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace("Bearer ", "");
    if (!token) return json({ error: "Não autenticado" }, 401);

    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: "Token inválido" }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

    // 2. E superadmin? A checagem e no BANCO, e nao no token, porque papel em
    //    token e informacao que o cliente carrega e poderia forjar.
    const { data: isSuper, error: isSuperErr } = await admin.rpc("is_superadmin", {
      _user_id: userData.user.id,
    });
    if (isSuperErr) return json({ error: isSuperErr.message }, 500);
    if (!isSuper) return json({ error: "Acesso negado" }, 403);

    const { data: operator } = await admin
      .from("superadmin_operators")
      .select("id")
      .eq("user_id", userData.user.id)
      .eq("active", true)
      .maybeSingle();

    // 3. O pedido
    const body = await req.json().catch(() => ({}));
    const {
      clinic_name,
      cnpj,
      specialty,
      owner_name,
      owner_email,
      owner_password,
      owner_phone,
      owner_crm,
      plan_id,
    } = body ?? {};

    if (!clinic_name || !String(clinic_name).trim()) {
      return json({ error: "Nome da clínica é obrigatório" }, 400);
    }
    if (!owner_email || !String(owner_email).includes("@")) {
      return json({ error: "E-mail do dono é obrigatório" }, 400);
    }
    // Oito e o minimo do proprio Supabase. Nao invento regra de forca aqui: a
    // senha e provisoria por natureza, e o dono troca quando quiser.
    if (!owner_password || String(owner_password).length < 8) {
      return json({ error: "Senha deve ter ao menos 8 caracteres" }, 400);
    }

    // 4. Cria o usuario. O gatilho `handle_new_user` faz o resto.
    //
    //    `email_confirm: true` porque quem confirma o e-mail e a NexClin, no
    //    ato da implantacao. Sem isso o dono receberia um pedido de confirmacao
    //    para uma conta que ele nao criou, o que contradiz o modelo de entregar
    //    pronto.
    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email: String(owner_email).trim().toLowerCase(),
      password: String(owner_password),
      email_confirm: true,
      user_metadata: {
        clinic_name: String(clinic_name).trim(),
        // O CNPJ VAI EM DIGITO, e nao com a mascara da tela.
        //
        // Achado em 29/08/2026 ao conferir a primeira conta provisionada em
        // producao: ela gravou `43.243.243/2423-42` enquanto a Barros Clinic
        // tinha `57314658000154`, na MESMA coluna. Dois formatos convivendo
        // quebram busca, comparacao e integracao fiscal.
        //
        // A mascara e da tela; o banco guarda digito. A mesma regra vive
        // testada em `lib/config/entrada.ts` na stack nova, como `normalizaCnpj`.
        cnpj: String(cnpj ?? "").replace(/\D/g, "").slice(0, 14),
        specialty: String(specialty ?? "").trim(),
        full_name: String(owner_name ?? "").trim(),
        phone: String(owner_phone ?? "").trim(),
        owner_crm: String(owner_crm ?? "").trim(),
      },
    });

    if (createErr) {
      // O caso comum e e-mail ja cadastrado. Dizer isso e melhor que devolver a
      // mensagem crua, porque e a unica que o operador consegue resolver.
      const msg = /already|exists|registered/i.test(createErr.message)
        ? "Já existe uma conta com este e-mail."
        : createErr.message;
      return json({ error: msg }, 400);
    }

    const newUserId = created.user?.id;
    if (!newUserId) return json({ error: "Usuário não foi criado" }, 500);

    // 5. Qual clinica o gatilho criou. Vem do perfil, que e onde a ancora mora.
    const { data: perfil } = await admin
      .from("profiles")
      .select("clinic_id")
      .eq("user_id", newUserId)
      .maybeSingle();

    const clinicId = perfil?.clinic_id ?? null;
    if (!clinicId) {
      return json(
        { error: "Conta criada, mas a clínica não foi encontrada. Verifique o gatilho handle_new_user." },
        500,
      );
    }

    // 6. O plano escolhido. Sem plano, a clinica nasce sem teto de modulos e
    //    todas as telas ficariam negadas pela cascata de `my_permission`.
    if (plan_id) {
      await admin.from("account_subscriptions").upsert(
        {
          clinic_id: clinicId,
          plan_id,
          status: "trial",
          trial_ends_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        },
        { onConflict: "clinic_id" },
      );
    }

    // 7. Auditoria. Condicao 3 da emenda, e regra (d) da constituicao.
    //
    //    `new_state` NAO leva a senha, e isso e deliberado: a condicao 4 diz
    //    que ela nao e gravada nem registrada em texto claro. O log guarda que
    //    uma senha foi definida, e nao qual.
    await admin.from("superadmin_audit_log").insert({
      operator_id: operator?.id ?? null,
      action: "clinic_provisioned",
      clinic_id: clinicId,
      previous_state: null,
      new_state: {
        clinic_name,
        cnpj: cnpj ?? "",
        owner_email,
        owner_name: owner_name ?? "",
        plan_id: plan_id ?? null,
        senha_definida: true,
      },
      reason: "Provisionamento de conta pelo superadmin",
      ip_address: req.headers.get("x-forwarded-for") ?? null,
    });

    // A resposta tambem nao devolve a senha. Quem a digitou ja a tem.
    return json({ ok: true, clinic_id: clinicId, user_id: newUserId });
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : "Erro inesperado" }, 500);
  }
});
