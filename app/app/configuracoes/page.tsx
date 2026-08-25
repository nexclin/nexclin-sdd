import Link from "next/link";

import { RequirePermission } from "@/lib/auth/guards";
import { lerContextoDoUsuario } from "@/lib/auth/servidor";
import { PASSOS_ONBOARDING } from "@/lib/auth/onboarding";
import { CATALOGOS } from "@/lib/config/catalogo";
import { lerRegras } from "@/lib/config/servidor";
import { horasParaDias } from "@/lib/config/regras";

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
          <h2 className="mb-3 text-sm font-medium uppercase tracking-wide text-[#3A4A5C]">
            Catálogos
          </h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {CATALOGOS.map((c) => (
              <Link
                key={c.slug}
                href={`/app/configuracoes/${c.slug}`}
                className="rounded-lg border border-[#3A4A5C]/15 bg-white p-4 transition hover:border-[#1F8C8C]/50"
              >
                <div className="font-medium">{c.rotulo}</div>
                <p className="mt-1 text-xs text-[#3A4A5C]">{c.descricao}</p>
              </Link>
            ))}
          </div>
        </section>

        <section>
          <h2 className="mb-3 text-sm font-medium uppercase tracking-wide text-[#3A4A5C]">
            Regras de negócio
          </h2>
          <div className="rounded-lg border border-[#3A4A5C]/15 bg-white p-5">
            <dl className="grid gap-2 text-sm sm:grid-cols-2">
              <Regra
                rotulo="Confirmar a consulta com antecedência de"
                valor={`${horasParaDias(regras.confirmation_hours)} dia(s)`}
                nota="Exibido em dias, armazenado em horas."
              />
              <Regra rotulo="Follow-up após" valor={`${regras.followup_days} dia(s)`} />
              <Regra rotulo="Recaptação após" valor={`${regras.recapture_days} dia(s)`} />
              <Regra rotulo="Recall após" valor={`${regras.recall_days} dia(s)`} />
              <Regra
                rotulo="Pesquisa de satisfação após"
                valor={`${regras.satisfaction_survey_days} dia(s)`}
              />
              <Regra
                rotulo="Enviar anamnese com"
                valor={`${regras.anamnesis_send_days} dia(s)`}
              />
              <Regra
                rotulo="Trabalha aos sábados"
                valor={regras.work_saturday ? "Sim" : "Não"}
                nota="Decide se a tarefa cai no sábado ou é empurrada para o dia útil seguinte."
              />
            </dl>

            {regras.id === null && (
              <p className="mt-3 text-xs text-amber-700">
                Esta clínica ainda não tem regras gravadas. Os valores acima são
                os padrões, e passam a valer de fato no primeiro salvamento.
              </p>
            )}

            <p className="mt-3 text-xs text-[#3A4A5C]">
              A edição das regras entra na próxima tarefa desta spec. A conversão
              de dias para horas já está escrita e testada, com a ida e volta
              conferida para 1 a 30 dias.
            </p>
          </div>
        </section>
      </div>
    </RequirePermission>
  );
}

function Regra({
  rotulo,
  valor,
  nota,
}: {
  rotulo: string;
  valor: string;
  nota?: string;
}) {
  return (
    <div className="flex flex-col">
      <dt className="text-[#3A4A5C]">{rotulo}</dt>
      <dd className="font-medium">{valor}</dd>
      {nota && <p className="text-xs text-[#3A4A5C]/80">{nota}</p>}
    </div>
  );
}
