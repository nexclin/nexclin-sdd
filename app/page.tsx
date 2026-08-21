import Link from "next/link";

/**
 * Raiz temporária. O app da clínica (esqueleto navegável, #26) e o login de
 * usuário comum (#19) entram na Fase 4. Por ora, atalho para o painel.
 */
export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 bg-slate-950 text-slate-100">
      <h1 className="text-3xl font-semibold">NexClin</h1>
      <p className="text-slate-400">Fundação — SPEC 001</p>
      <Link
        href="/superadmin"
        className="rounded-md bg-blue-600 px-4 py-2 font-medium hover:bg-blue-700"
      >
        Acessar painel Super Admin
      </Link>
    </main>
  );
}
