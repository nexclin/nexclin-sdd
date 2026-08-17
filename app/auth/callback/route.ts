import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * SPEC 001 / T019 — Pouso dos links de e-mail do Supabase Auth.
 *
 * É para cá que apontam o link de recuperação de senha e o convite. Troca o
 * code por uma sessão e manda o usuário definir a própria senha.
 *
 * Note a fronteira: aqui ninguém DEFINE senha de ninguém. O link só autentica
 * o dono do e-mail; quem digita a senha nova é ele, em /nova-senha. Admin
 * definindo senha de terceiro é proibido (Princípio II).
 */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/nova-senha";

  if (!code) {
    return NextResponse.redirect(`${origin}/superadmin/login?erro=link_invalido`);
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    return NextResponse.redirect(`${origin}/superadmin/login?erro=link_expirado`);
  }

  // `next` só pode ser rota interna — evita open redirect via link forjado.
  const destino = next.startsWith("/") ? next : "/nova-senha";
  return NextResponse.redirect(`${origin}${destino}`);
}
