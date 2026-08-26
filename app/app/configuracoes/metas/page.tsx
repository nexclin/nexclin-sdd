import Link from "next/link";

import { RequirePermission } from "@/lib/auth/guards";
import { createClient } from "@/lib/supabase/server";
import { lerRegras } from "@/lib/config/servidor";
import { diasUteisDoMes, porDiaUtil } from "@/lib/config/metas";
import { MetasForm, type MetaDoMes } from "./metas-form";

/**
 * SPEC 005 / T014 — metas mensais.
 *
 * # O que esta tela acrescenta ao que já existia
 *
 * A tabela `goals` já guardava faturamento, pacientes novos, fechamentos e
 * conversão por mês. Isso é meta de fim de mês, e meta de fim de mês não muda
 * o que alguém faz hoje.
 *
 * O que entra aqui é a metade que decide: **dias úteis, feriados e quanto falta
 * por dia útil**. Ideia trazida da modelagem do INI, onde a tela de metas abre
 * dizendo *"21 dias úteis, 4 restantes"*.
 *
 * Os feriados nacionais são calculados, não cadastrados. Pedir doze feriados
 * por ano para a clínica é o pedágio de configuração que a pesquisa mandou
 * evitar. Feriado municipal continua sendo dívida declarada, e o cálculo erra
 * para MAIS dias úteis, ou seja, exige um pouco menos por dia. É o lado seguro.
 */
export default async function MetasPage({
  searchParams,
}: {
  searchParams: Promise<{ ano?: string; mes?: string }>;
}) {
  const { ano: anoBruto, mes: mesBruto } = await searchParams;
  const agora = new Date();

  const ano = Number(anoBruto) || agora.getUTCFullYear();
  // O mês viaja 1 a 12 na URL, porque é assim que uma pessoa lê. Internamente
  // é 0 a 11, e a conversão fica num lugar só.
  const mesHumano = Math.min(12, Math.max(1, Number(mesBruto) || agora.getUTCMonth() + 1));
  const mes = mesHumano - 1;

  const supabase = await createClient();
  const [regras, { data: meta }] = await Promise.all([
    lerRegras(),
    supabase
      .from("goals")
      .select("id, month, year, revenue_target, new_patients_target, closings_target, conversion_target")
      .eq("year", ano)
      .eq("month", mesHumano)
      .maybeSingle(),
  ]);

  const dias = diasUteisDoMes(ano, mes, agora, regras.work_saturday);

  const alvo = Number(meta?.revenue_target ?? 0);
  const faltaPorDia = porDiaUtil(alvo, 0, dias.restantes);

  const nomeDoMes = new Date(Date.UTC(ano, mes, 1)).toLocaleDateString("pt-BR", {
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  });

  const anterior = mesHumano === 1 ? { ano: ano - 1, mes: 12 } : { ano, mes: mesHumano - 1 };
  const proximo = mesHumano === 12 ? { ano: ano + 1, mes: 1 } : { ano, mes: mesHumano + 1 };

  return (
    <RequirePermission module="configuracoes">
      <div className="space-y-6">
        <div>
          <Link href="/app/configuracoes" className="text-sm text-[#1F8C8C] hover:underline">
            Configurações
          </Link>
          <h1 className="mt-1 text-2xl font-semibold capitalize">Metas de {nomeDoMes}</h1>
          <p className="mt-1 max-w-2xl text-sm text-[#3A4A5C]">
            A meta do mês, e o que ela significa por dia útil. Sem isso, meta é
            um número que só faz sentido no dia 30.
          </p>
        </div>

        <div className="flex items-center gap-4 text-sm">
          <Link
            href={`/app/configuracoes/metas?ano=${anterior.ano}&mes=${anterior.mes}`}
            className="text-[#1F8C8C] hover:underline"
          >
            ← Mês anterior
          </Link>
          <Link
            href={`/app/configuracoes/metas?ano=${proximo.ano}&mes=${proximo.mes}`}
            className="text-[#1F8C8C] hover:underline"
          >
            Próximo mês →
          </Link>
        </div>

        <section className="rounded-lg border border-[#3A4A5C]/15 bg-white p-5">
          <div className="grid gap-4 sm:grid-cols-3">
            <Numero rotulo="Dias úteis no mês" valor={String(dias.uteis)} />
            <Numero
              rotulo="Ainda restam"
              valor={String(dias.restantes)}
              nota={dias.restantes === 0 ? "O mês fechou." : "Hoje conta."}
            />
            <Numero
              rotulo="Falta por dia útil"
              valor={
                faltaPorDia === null
                  ? "—"
                  : faltaPorDia.toLocaleString("pt-BR", {
                      style: "currency",
                      currency: "BRL",
                      maximumFractionDigits: 0,
                    })
              }
              nota={
                faltaPorDia === null
                  ? "Sem dia útil restante."
                  : "Sobre a meta de faturamento, ainda sem descontar o realizado."
              }
            />
          </div>

          <p className="mt-4 text-xs text-[#3A4A5C]">
            {regras.work_saturday
              ? "Sábado conta como dia útil, pela regra de negócio da clínica."
              : "Sábado não conta. Mude em Regras de negócio se a clínica atender."}
          </p>

          {dias.feriadosNoMes.length > 0 && (
            <p className="mt-2 text-xs text-[#3A4A5C]">
              <span className="font-medium">Feriados nacionais em dia de semana:</span>{" "}
              {dias.feriadosNoMes
                .map((d) => d.split("-").reverse().slice(0, 2).join("/"))
                .join(", ")}
              . Feriado municipal ainda não é considerado, então o número de dias
              úteis pode estar um pouco alto.
            </p>
          )}
        </section>

        <MetasForm
          ano={ano}
          mes={mesHumano}
          meta={(meta ?? null) as MetaDoMes | null}
          diasRestantes={dias.restantes}
        />
      </div>
    </RequirePermission>
  );
}

function Numero({
  rotulo,
  valor,
  nota,
}: {
  rotulo: string;
  valor: string;
  nota?: string;
}) {
  return (
    <div>
      <div className="text-sm text-[#3A4A5C]">{rotulo}</div>
      <div className="mt-1 text-2xl font-semibold">{valor}</div>
      {nota && <p className="text-xs text-[#3A4A5C]/80">{nota}</p>}
    </div>
  );
}
