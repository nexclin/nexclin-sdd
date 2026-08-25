import Link from "next/link";
import { headers } from "next/headers";

import { guardarAppDaClinica } from "@/lib/auth/guards";
import { agruparMenu, montarMenu } from "@/lib/auth/menu";
import { BannerImpersonacao } from "./banner-impersonacao";

/**
 * SPEC 001 / T020, T025 e T026 — o shell do app da clínica.
 *
 * Um layout só faz o trabalho de quatro guards, e isso é economia de ida ao
 * banco, não atalho de segurança: `guardarAppDaClinica` roda sessão,
 * assinatura, onboarding e permissão do módulo na ordem que `decisoes.ts`
 * define e os testes travam. O contexto volta carregado e alimenta menu e
 * banner sem uma segunda consulta.
 *
 * Rodar no servidor é o que cumpre a exigência de não piscar conteúdo
 * protegido: quem não pode ver a tela nunca recebe o HTML dela.
 */
export default async function AppDaClinicaLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // O Next não entrega a rota atual a um layout por prop. O cabeçalho que o
  // middleware repassa é o caminho de confiança; na ausência dele, cai para
  // `/app`, que é a rota menos privilegiada possível (não é gateada, então
  // errar para cá nunca libera módulo).
  const h = await headers();
  const rotaAtual =
    h.get("x-pathname") ?? h.get("x-invoke-path") ?? "/app";

  const ctx = await guardarAppDaClinica(rotaAtual);
  const grupos = agruparMenu(montarMenu(ctx.permissoes));

  return (
    <div className="min-h-screen bg-[#F4F1EC] text-[#0E1620]">
      {ctx.impersonacao && (
        <BannerImpersonacao clinica={ctx.impersonacao.clinica} />
      )}

      <div className="flex">
        <aside className="min-h-screen w-60 shrink-0 bg-[#141C28] px-3 py-5 text-[#F4F1EC]">
          <Link href="/app" className="block px-2 text-lg font-semibold">
            NexClin
          </Link>

          <nav className="mt-6 space-y-5">
            {grupos.map((g) => (
              <div key={g.grupo}>
                <p className="px-2 text-[11px] uppercase tracking-wide text-[#F4F1EC]/45">
                  {g.grupo}
                </p>
                <ul className="mt-1 space-y-0.5">
                  {g.itens.map((item) => (
                    <li key={item.modulo}>
                      <Link
                        href={item.rota}
                        className="block rounded-md px-2 py-1.5 text-sm text-[#F4F1EC]/85 transition hover:bg-white/10 hover:text-white"
                      >
                        {item.rotulo}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}

            {grupos.length === 0 && (
              // Menu vazio não é tela quebrada: é o que a cascata decidiu.
              // Dizer isso é melhor que uma barra lateral em branco.
              <p className="px-2 text-xs text-[#F4F1EC]/60">
                Nenhum módulo liberado para o seu acesso. Fale com o
                administrador da clínica.
              </p>
            )}
          </nav>
        </aside>

        <main className="flex-1 px-8 py-8">{children}</main>
      </div>
    </div>
  );
}
