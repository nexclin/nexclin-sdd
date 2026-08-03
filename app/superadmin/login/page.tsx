"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

/**
 * SPEC 001 / T022 — Login próprio do Super Admin.
 * Paridade de comportamento com a referência: signInWithPassword e depois
 * confirma que o usuário é operador ativo em superadmin_operators (a RLS só
 * deixa um superadmin ler a própria linha). Não-operador: signOut + nega.
 */
export default function SuperAdminLoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const supabase = createClient();
    try {
      const { data: authData, error: authError } =
        await supabase.auth.signInWithPassword({ email, password });
      if (authError) throw authError;

      const { data: operator, error: opError } = await supabase
        .from("superadmin_operators")
        .select("id, active")
        .eq("user_id", authData.user.id)
        .eq("active", true)
        .maybeSingle();

      if (opError || !operator) {
        await supabase.auth.signOut();
        setError("Acesso negado. Você não é um operador autorizado.");
        return;
      }

      router.replace("/superadmin");
      router.refresh();
    } catch (err) {
      setError((err as Error).message || "Erro ao fazer login");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-900 p-4">
      <div className="w-full max-w-md rounded-2xl border border-white/10 bg-slate-800 p-8">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-white">NexClin SuperAdmin</h1>
          <p className="mt-1 text-sm text-slate-400">Painel de gestão do SaaS</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm text-slate-300" htmlFor="email">
              E-mail
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full rounded-md border border-white/10 bg-white/5 px-3 py-2 text-white placeholder:text-slate-500"
              placeholder="operador@nexclin.com"
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm text-slate-300" htmlFor="password">
              Senha
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full rounded-md border border-white/10 bg-white/5 px-3 py-2 text-white placeholder:text-slate-500"
              placeholder="••••••••"
            />
          </div>

          {error && (
            <p className="rounded-md bg-red-500/10 px-3 py-2 text-sm text-red-400">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-md bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700 disabled:opacity-60"
          >
            {loading ? "Entrando..." : "Entrar"}
          </button>
        </form>
      </div>
    </div>
  );
}
