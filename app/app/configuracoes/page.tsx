import Link from "next/link";

import { RequirePermission } from "@/lib/auth/guards";
import { lerContextoDoUsuario } from "@/lib/auth/servidor";
import { PASSOS_ONBOARDING } from "@/lib/auth/onboarding";
import { catalogosEmOrdem } from "@/lib/config/catalogo";
import { lerRegras } from "@/lib/config/servidor";
import { RegrasForm } from "./regras-form";

/**
 * SPEC 005 / T016 — o índice de Configurações.
 *
 * Duas coisas, e as duas vêm do banco: **onde configurar cada coisa**, e
 * **quanto falta** da configuração inicial.
 *
 * O `RequirePermission` aqui é redundante com o gate do layout, e a redundância
 * é o ponto: o layout depende de um cabeçalho vindo do middleware, e cabeçalho
 * perdido não pode virar módulo liberado.
 */
export default async function ConfiguracoesPage() {
  const [ctx, regras] = await Promise.all([lerContextoDoUsuario(), lerRegras()]);

  return (
    <RequirePermission module="configuracoes">
      <div className="space-y-8">
        <div>
          <h1 className="text-2xl font-semibold">Configurações</h1>
          <p className="mt-1 max-w-2xl text-sm text-[#3A4A5C]">
            Os catálogos e as regras que os outros módulos leem. Pacientes,
            consultas, tarefas e anamnese dependem do que está aqui.
          </p>
        </div>

        {!ctx.onboarding.concluido && (
          <section className="rounded-lg border border-[#1F8C8C]/30 bg-white p-5">
            <h2 className="font-medium">
              Configuração inicial: {ctx.onboarding.passoAtual} de{" "}
              {ctx.onboarding.total}
            </h2>
            <p className="mt-1 text-sm text-[#3A4A5C]">
              Nada aqui bloqueia o uso do sistema. A clínica opera melhor com os
              catálogos preenchidos, e alguns módulos ficam sem opção para
              oferecer enquanto eles estiverem vazios.
            </p>
            <ul className="mt-3 grid gap-1 text-sm sm:grid-cols-2">
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
                  <span className={ctx.onboarding.passos[p] ? "" : "text-[#3A4A5C]"}>
                    {p}
                  </span>
                </li>
              ))}
            </ul>
          </section>
        )}

        <section>
          <h2 className="mb-1 text-sm font-medium uppercase tracking-wide text-[#3A4A5C]">
            Catálogos
          </h2>
          <p className="mb-3 max-w-2xl text-xs text-[#3A4A5C]">
            Estão na ordem sugerida, que é a ordem de dependência: o serviço
            carrega o preço que o recebível usa, e a origem pertence a um canal.
            Preencher fora de ordem funciona, e só custa voltar. Cada tela tem
            um botão Avançar para a seguinte.
          </p>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {catalogosEmOrdem().map((c, i) => (
              <Link
                key={c.slug}
                href={`/app/configuracoes/${c.slug}`}
                className="rounded-lg border border-[#3A4A5C]/15 bg-white p-4 transition hover:border-[#1F8C8C]/50"
              >
                <div className="flex items-baseline gap-2">
                  <span className="text-xs tabular-nums text-[#3A4A5C]/60">
                    {i + 1}
                  </span>
                  <span className="font-medium">{c.rotulo}</span>
                </div>
                <p className="mt-1 text-xs text-[#3A4A5C]">{c.descricao}</p>
                <p className="mt-2 text-xs text-[#3A4A5C]/80">
                  <span className="font-medium">Usado em:</span>{" "}
                  {c.alimenta.join(", ")}
                </p>
              </Link>
            ))}
          </div>
        </section>

        <section>
          <h2 className="mb-1 text-sm font-medium uppercase tracking-wide text-[#3A4A5C]">
            Regras de negócio
          </h2>
          <p className="mb-3 max-w-2xl text-xs text-[#3A4A5C]">
            Estas não são listas: são os números que decidem quando a esteira de
            tarefas dispara e o que o cadastro exige para salvar. Cada campo diz
            o que muda quando você mexe nele.
          </p>
          <RegrasForm regras={regras} />
        </section>

      </div>
    </RequirePermission>
  );
}
