import { lerContextoDoUsuario } from "@/lib/auth/servidor";
import { PASSOS_ONBOARDING } from "@/lib/auth/onboarding";
import { montarMenu } from "@/lib/auth/menu";

/**
 * SPEC 001 / T026 — a raiz do app da clínica.
 *
 * Dashboard vazio de propósito. O módulo `dashboard` é a spec 012 da fila e só
 * agrega o que os outros produzem; especificá-lo antes seria projetar métrica
 * sobre dado que ainda não existe.
 *
 * O que esta tela faz de útil hoje: mostrar ao usuário **o que ele consegue
 * acessar** e **quanto falta do onboarding**. As duas coisas vêm do banco, não
 * de suposição, então ela também serve de prova visual de que a cascata está
 * funcionando.
 *
 * Sem `RequirePermission`: o dashboard nunca teve gate (INVENTARIO §3.1).
 */
export default async function InicioPage() {
  const ctx = await lerContextoDoUsuario();
  const liberados = montarMenu(ctx.permissoes);
  const { onboarding } = ctx;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-semibold">Início</h1>
        <p className="mt-1 text-sm text-[#3A4A5C]">
          Esqueleto da Fase 4. O painel de indicadores entra na spec do
          dashboard, depois que os módulos que o alimentam existirem.
        </p>
      </div>

      {!onboarding.concluido && (
        <section className="rounded-lg border border-[#1F8C8C]/30 bg-white p-5">
          <h2 className="font-medium">
            Configuração inicial: {onboarding.passoAtual} de {onboarding.total}
          </h2>
          <p className="mt-1 text-sm text-[#3A4A5C]">
            A clínica opera melhor com os catálogos preenchidos. Nada aqui
            bloqueia o uso.
          </p>
          <ul className="mt-3 grid gap-1 text-sm sm:grid-cols-2">
            {PASSOS_ONBOARDING.map((p) => (
              <li key={p} className="flex items-center gap-2">
                <span
                  aria-hidden
                  className={
                    onboarding.passos[p]
                      ? "inline-block h-2 w-2 rounded-full bg-[#1F8C8C]"
                      : "inline-block h-2 w-2 rounded-full bg-[#3A4A5C]/30"
                  }
                />
                <span className={onboarding.passos[p] ? "" : "text-[#3A4A5C]"}>
                  {p}
                </span>
              </li>
            ))}
          </ul>
        </section>
      )}

      <section className="rounded-lg border border-[#3A4A5C]/15 bg-white p-5">
        <h2 className="font-medium">Seus módulos</h2>
        <p className="mt-1 text-sm text-[#3A4A5C]">
          Lista montada a partir de <code>my_permission</code>, no banco. O que
          não aparece aqui, a cascata negou.
        </p>
        <ul className="mt-3 flex flex-wrap gap-2 text-sm">
          {liberados.map((i) => (
            <li
              key={i.modulo}
              className="rounded-md border border-[#3A4A5C]/20 px-2.5 py-1"
            >
              {i.rotulo}
              <span className="ml-2 text-xs text-[#3A4A5C]">
                {ctx.permissoes[i.modulo]}
              </span>
            </li>
          ))}
          {liberados.length === 0 && (
            <li className="text-[#3A4A5C]">Nenhum módulo liberado.</li>
          )}
        </ul>
      </section>
    </div>
  );
}
