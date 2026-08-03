/**
 * SPEC 001 / T022 — Painel Super Admin (placeholder navegável).
 * As 11 telas (contas, planos, cupons, faturamento, métricas, logs,
 * operadores, configurações, comunicação) entram na issue #23.
 * Este layout já está guardado por (panel)/layout.tsx.
 */
export default function SuperAdminDashboardPage() {
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Painel Super Admin</h1>
      <p className="text-slate-400">
        Acesso autorizado. As telas de gestão (contas, planos, cupons,
        faturamento, métricas, logs, operadores, configurações) serão
        adicionadas na issue #23.
      </p>
      <div className="rounded-lg border border-white/10 bg-slate-900 p-4 text-sm text-slate-400">
        Fundação viva: banco replicado, seed do superadmin e este acesso
        (login + guard) prontos. Próximo: impersonação (#25) e as telas (#23).
      </div>
    </div>
  );
}
