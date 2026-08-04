import { createClient } from "@/lib/supabase/server";

/**
 * SPEC 001 / #23 — Dashboard do Super Admin (Server Component).
 * Métricas lidas no servidor via RLS (superadmin enxerga todas as contas).
 */
const STATUS_LABEL: Record<string, string> = {
  trial: "Trial",
  active: "Ativas",
  overdue: "Inadimplentes",
  suspended: "Suspensas",
  cancelled: "Canceladas",
};

export default async function SuperAdminDashboardPage() {
  const supabase = await createClient();

  const [{ count: clinicCount }, { data: subs }, { count: operatorCount }] =
    await Promise.all([
      supabase.from("clinics").select("id", { count: "exact", head: true }),
      supabase.from("account_subscriptions").select("status"),
      supabase
        .from("superadmin_operators")
        .select("id", { count: "exact", head: true })
        .eq("active", true),
    ]);

  const tally = (subs ?? []).reduce<Record<string, number>>((acc, s) => {
    const k = s.status as string;
    acc[k] = (acc[k] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Painel Super Admin</h1>
        <p className="mt-1 text-sm text-slate-400">Visão geral do SaaS</p>
      </div>

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <Metric label="Clínicas" value={clinicCount ?? 0} />
        <Metric label="Operadores ativos" value={operatorCount ?? 0} />
        <Metric label="Assinaturas" value={(subs ?? []).length} />
        <Metric label="Ativas" value={tally["active"] ?? 0} />
      </div>

      <div className="rounded-lg border border-white/10 bg-slate-900 p-5">
        <h2 className="mb-3 text-sm font-medium text-slate-300">
          Assinaturas por status
        </h2>
        <div className="flex flex-wrap gap-3">
          {Object.keys(STATUS_LABEL).map((k) => (
            <div
              key={k}
              className="rounded-md border border-white/10 px-3 py-2 text-sm"
            >
              <span className="text-slate-400">{STATUS_LABEL[k]}: </span>
              <span className="font-semibold">{tally[k] ?? 0}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-lg border border-white/10 bg-slate-900 p-4">
      <div className="text-2xl font-semibold">{value}</div>
      <div className="mt-1 text-xs text-slate-400">{label}</div>
    </div>
  );
}
