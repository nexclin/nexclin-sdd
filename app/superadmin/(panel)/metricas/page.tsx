import { createClient } from "@/lib/supabase/server";
import { Cabecalho, Vazio, moeda } from "../_ui";

/**
 * SPEC 001 / T023 — Métricas.
 *
 * Só entra número que sai de dado real. O histórico de MRR da referência era
 * **sintético**, e o BACKLOG registra isso como "aproximação a especificar de
 * verdade". Por isso ele não foi portado: gráfico bonito com número inventado é
 * pior que ausência de gráfico, porque alguém decide em cima dele.
 */
export default async function MetricasPage() {
  const supabase = await createClient();

  const [{ data: assinaturas }, { count: clinicas }, { data: pagas }] =
    await Promise.all([
      supabase
        .from("account_subscriptions")
        .select("status, plan_id, plans(monthly_price)"),
      supabase.from("clinics").select("id", { count: "exact", head: true }),
      supabase.from("billings").select("amount").eq("status", "paid"),
    ]);

  const linhas = assinaturas ?? [];
  const ativas = linhas.filter((s) => s.status === "active");
  const mrr = ativas.reduce(
    (soma, s) =>
      soma +
      (Number((s.plans as { monthly_price?: number } | null)?.monthly_price) ||
        0),
    0,
  );
  const arrecadado = (pagas ?? []).reduce(
    (soma, b) => soma + (Number(b.amount) || 0),
    0,
  );
  const porStatus = linhas.reduce<Record<string, number>>((acc, s) => {
    const k = String(s.status);
    acc[k] = (acc[k] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Métricas"
        subtitulo="Apenas o que sai de dado real. Nada estimado."
      />

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <Cartao rotulo="Clínicas" valor={String(clinicas ?? 0)} />
        <Cartao rotulo="Assinaturas ativas" valor={String(ativas.length)} />
        <Cartao rotulo="MRR" valor={moeda(mrr)} />
        <Cartao rotulo="Arrecadado" valor={moeda(arrecadado)} />
      </div>

      <section className="rounded-lg border border-white/10 bg-slate-900 p-5">
        <h2 className="mb-3 text-sm font-medium text-slate-300">
          Assinaturas por status
        </h2>
        {Object.keys(porStatus).length === 0 ? (
          <Vazio>Nenhuma assinatura registrada.</Vazio>
        ) : (
          <div className="flex flex-wrap gap-3 text-sm">
            {Object.entries(porStatus).map(([k, v]) => (
              <div key={k} className="rounded-md border border-white/10 px-3 py-2">
                <span className="text-slate-400">{k}: </span>
                <span className="font-semibold">{v}</span>
              </div>
            ))}
          </div>
        )}
      </section>

      <p className="text-xs text-slate-500">
        MRR é a soma do preço mensal dos planos com assinatura ativa. Não
        desconta cupom, porque o enforcement de cupom ainda não existe. Dizer o
        método evita que o número seja lido como coisa que ele não é.
      </p>
    </div>
  );
}

function Cartao({ rotulo, valor }: { rotulo: string; valor: string }) {
  return (
    <div className="rounded-lg border border-white/10 bg-slate-900 p-4">
      <div className="text-2xl font-semibold">{valor}</div>
      <div className="mt-1 text-xs text-slate-400">{rotulo}</div>
    </div>
  );
}
