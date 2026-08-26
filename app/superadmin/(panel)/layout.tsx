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

  // SPEC 003 / F3: antes de desenhar qualquer coisa, encerrar o que venceu.
  //
  // A impersonação troca a ANCORA (`profiles.clinic_id`), e não só marca uma
  // sessão. Operador que fechou o navegador sem clicar em sair fica com o
  // perfil apontando para a clínica do cliente, e volta direto para dentro
  // dela. Esta chamada restaura a âncora das sessões vencidas.
  //
  // Aqui, e não noutro lugar, porque este layout é a porta de entrada de todas
  // as rotas do painel: o operador que volta passa por ele antes de ver
  // qualquer tela. Nunca lança: limpeza que derruba a página trocaria um
  // problema silencioso por um barulhento, e nenhum dos dois deixa ele
  // trabalhar.
  //
  // A janela que continua aberta, e está registrada como dívida na spec: se o
  // operador NUNCA mais voltar, ninguém chama isto. Fechar de vez exige cron
  // ou mexer em `get_my_clinic_id`, que toda policy do banco usa.
  await supabase.rpc("encerra_impersonacoes_vencidas").then(
    () => undefined,
    () => undefined,
  );

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
