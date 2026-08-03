import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

/**
 * SPEC 001 / T020 — Guard server-side do painel Super Admin.
 * Roda no servidor (sem flash de conteúdo). Autoriza consultando a função
 * is_superadmin no banco — a segurança real é do Postgres; aqui só decidimos
 * navegação. Login (/superadmin/login) fica FORA deste grupo, então não é
 * guardado (sem loop de redirect).
 */
export default async function SuperAdminPanelLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/superadmin/login");
  }

  const { data: isSuper, error } = await supabase.rpc("is_superadmin", {
    _user_id: user.id,
  });

  if (error || isSuper !== true) {
    redirect("/superadmin/login");
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <header className="border-b border-white/10 bg-slate-900">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <Link href="/superadmin" className="font-semibold">
            NexClin · SuperAdmin
          </Link>
          <nav className="flex gap-4 text-sm text-slate-400">
            <Link href="/superadmin" className="hover:text-white">
              Painel
            </Link>
            {/* Telas #23 (contas, planos, cupons, ...) entram aqui */}
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-6 py-8">{children}</main>
    </div>
  );
}
