import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { lerImpersonacao } from "@/lib/auth/servidor";
import { BannerImpersonacao } from "@/app/app/banner-impersonacao";

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

  // SPEC 001 / T025 — o banner vale para **todas** as rotas, e o painel é uma
  // delas. Um operador com impersonação ativa que volta ao painel precisa
  // continuar vendo que está dentro da conta de um cliente; sem isso ele
  // esquece, e a próxima ação sai no lugar errado.
  const impersonacao = await lerImpersonacao();

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      {impersonacao && <BannerImpersonacao clinica={impersonacao.clinica} />}
      <header className="border-b border-white/10 bg-slate-900">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <Link href="/superadmin" className="font-semibold">
            NexClin · SuperAdmin
          </Link>
          <nav className="flex flex-wrap gap-x-4 gap-y-1 text-sm text-slate-400">
            {[
              ["/superadmin", "Painel"],
              ["/superadmin/contas", "Contas"],
              ["/superadmin/planos", "Planos"],
              ["/superadmin/cupons", "Cupons"],
              ["/superadmin/faturamento", "Faturamento"],
              ["/superadmin/metricas", "Métricas"],
              ["/superadmin/logs", "Logs"],
              ["/superadmin/operadores", "Operadores"],
              ["/superadmin/comunicacao", "Comunicação"],
              ["/superadmin/configuracoes", "Configurações"],
            ].map(([rota, rotulo]) => (
              <Link key={rota} href={rota} className="hover:text-white">
                {rotulo}
              </Link>
            ))}
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-6 py-8">{children}</main>
    </div>
  );
}
