import { RequirePermission } from "@/lib/auth/guards";
import { lerContextoDoUsuario } from "@/lib/auth/servidor";
import { PASSOS_ONBOARDING } from "@/lib/auth/onboarding";

/**
 * SPEC 001 / T026 — placeholder de Configurações, e destino do onboarding.
 *
 * Os onze diálogos de configuração são a **SPEC 004**, primeira da fila da
 * Onda 1. Esta tela existe agora por dois motivos concretos:
 *
 * 1. é para onde o `OnboardingGuard` manda a clínica incompleta, e mandar para
 *    uma rota que não existe seria trocar um desvio por um 404;
 * 2. é o primeiro consumidor real de `RequirePermission`, o que prova o guard
 *    numa rota de verdade em vez de só no teste.
 *
 * O `RequirePermission` aqui é redundante com o gate do layout, e a redundância
 * é o ponto: o layout depende de um cabeçalho vindo do middleware, e cabeçalho
 * perdido não pode virar módulo liberado.
 */
export default async function ConfiguracoesPage() {
  const ctx = await lerContextoDoUsuario();

  return (
    <RequirePermission module="configuracoes">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-semibold">Configurações</h1>
          <p className="mt-1 text-sm text-[#3A4A5C]">
            Os catálogos e regras de negócio da clínica entram na SPEC 004. Esta
            tela mostra o que falta configurar.
          </p>
        </div>

        <section className="rounded-lg border border-[#3A4A5C]/15 bg-white p-5">
          <h2 className="font-medium">
            Configuração inicial: {ctx.onboarding.passoAtual} de{" "}
            {ctx.onboarding.total}
          </h2>
          <ul className="mt-3 space-y-1 text-sm">
            {PASSOS_ONBOARDING.map((p) => (
              <li key={p} className="flex items-center gap-2">
                <span
                  aria-hidden
                  className={
                    ctx.onboarding.passos[p]
                      ? "inline-block h-2 w-2 rounded-full bg-[#1F8C8C]"
                      : "inline-block h-2 w-2 rounded-full bg-[#3A4A5C]/30"
                  }
                />
                <span>{p}</span>
                <span className="text-xs text-[#3A4A5C]">
                  {ctx.onboarding.passos[p] ? "pronto" : "pendente"}
                </span>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </RequirePermission>
  );
}
