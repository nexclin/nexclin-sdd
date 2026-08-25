import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

type CookieToSet = { name: string; value: string; options: CookieOptions };

/**
 * Renova a sessão do Supabase a cada request (padrão @supabase/ssr).
 * NÃO decide autorização aqui — isso é responsabilidade dos guards/RLS.
 */
export async function updateSession(request: NextRequest) {
  // SPEC 001 / T020 — a rota atual, para os guards de layout.
  //
  // O Next não passa o caminho como prop para um layout. Sem este cabeçalho, o
  // layout de `/app` não sabe qual módulo protege a rota e cai no padrão
  // "sem módulo", que **não** é gateado. Ou seja: sem isto, `RequirePermission`
  // simplesmente não dispara no nível do layout. Por isso ele é escrito aqui, e
  // por isso cada página também declara o seu módulo — defesa em profundidade,
  // porque um cabeçalho perdido não pode virar módulo liberado.
  //
  // Escrito no request, não na resposta: cabeçalho de resposta não chega ao
  // Server Component.
  request.headers.set("x-pathname", request.nextUrl.pathname);

  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value),
          );
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  // Toca o usuário para forçar refresh do token quando necessário.
  await supabase.auth.getUser();

  return supabaseResponse;
}
