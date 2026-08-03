import { createBrowserClient } from "@supabase/ssr";

/**
 * Cliente Supabase para uso no BROWSER (client components).
 * Usa apenas a anon key pública; a segurança real mora no banco (RLS).
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
