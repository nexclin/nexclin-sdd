import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { EnterClinicButton } from "./enter-clinic-button";

/**
 * SPEC 001 / #23 — Contas (lista de clínicas). Server Component: lê no
 * servidor via RLS. A entrada em modo suporte (#25) fica no botão client
 * EnterClinicButton, que chama a RPC superadmin_enter_clinic.
 */
const STATUS: Record<string, { label: string; cls: string }> = {
  trial: { label: "Trial", cls: "border-amber-500/40 text-amber-300" },
  active: { label: "Ativa", cls: "border-emerald-500/40 text-emerald-300" },
  overdue: { label: "Inadimplente", cls: "border-red-500/40 text-red-300" },
  suspended: { label: "Suspensa", cls: "border-red-500/40 text-red-300" },
  cancelled: { label: "Cancelada", cls: "border-slate-500/40 text-slate-400" },
  sem_plano: { label: "Sem plano", cls: "border-slate-600 text-slate-500" },
};

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return `${String(d.getUTCDate()).padStart(2, "0")}/${String(
    d.getUTCMonth() + 1,
  ).padStart(2, "0")}/${d.getUTCFullYear()}`;
}

export default async function ContasPage() {
  const supabase = await createClient();

  const { data: clinics } = await supabase
    .from("clinics")
    .select("id, name, cnpj, specialty, created_at")
    .order("created_at", { ascending: false });

  const ids = (clinics ?? []).map((c) => c.id);
  const [{ data: subs }, { data: profiles }] = await Promise.all([
    supabase.from("account_subscriptions").select("clinic_id, status"),
    supabase
      .from("profiles")
      .select("clinic_id, full_name")
      .in("clinic_id", ids.length ? ids : ["00000000-0000-0000-0000-000000000000"]),
  ]);

  const rows = (clinics ?? []).map((c) => ({
    ...c,
    status: subs?.find((s) => s.clinic_id === c.id)?.status ?? "sem_plano",
    owner: profiles?.find((p) => p.clinic_id === c.id)?.full_name ?? "—",
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Contas</h1>
        <p className="mt-1 text-sm text-slate-400">
          {rows.length} clínica(s) cadastrada(s)
        </p>
      </div>

      <div className="overflow-x-auto rounded-lg border border-white/10">
        <table className="w-full text-sm">
          <thead className="bg-slate-900 text-left text-slate-400">
            <tr>
              <th className="px-4 py-3 font-medium">Clínica</th>
              <th className="px-4 py-3 font-medium">Responsável</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Desde</th>
              <th className="px-4 py-3 font-medium">Ações</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-slate-500">
                  Nenhuma conta encontrada
                </td>
              </tr>
            ) : (
              rows.map((c) => {
                const st = STATUS[c.status] ?? STATUS.sem_plano;
                return (
                  <tr key={c.id} className="border-t border-white/10">
                    <td className="px-4 py-3 font-medium">{c.name}</td>
                    <td className="px-4 py-3 text-slate-300">{c.owner}</td>
                    <td className="px-4 py-3">
                      <span
                        className={`rounded border px-2 py-0.5 text-xs ${st.cls}`}
                      >
                        {st.label}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-400">
                      {fmtDate(c.created_at)}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <Link
                          href={`/superadmin/contas/${c.id}`}
                          className="text-blue-400 hover:text-blue-300"
                        >
                          Ver
                        </Link>
                        <EnterClinicButton clinicId={c.id} clinicName={c.name} />
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
