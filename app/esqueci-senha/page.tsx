"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";

/**
 * SPEC 001 / T019 — Pedido de recuperação de senha.
 *
 * Único caminho de troca de senha que existe no sistema: dispara
 * `resetPasswordForEmail` e o dono do e-mail define a própria senha em
 * /nova-senha. Nenhuma tela, action ou função define senha de terceiro.
 *
 * A resposta é sempre a mesma, exista o e-mail ou não — senão a tela vira um
 * oráculo de quais e-mails têm conta.
 */
export default function EsqueciSenhaPage() {
  const [email, setEmail] = useState("");
  const [carregando, setCarregando] = useState(false);
  const [enviado, setEnviado] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setCarregando(true);

    const supabase = createClient();
    await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/callback?next=/nova-senha`,
    });

    setCarregando(false);
    setEnviado(true);
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-900 p-4">
      <div className="w-full max-w-md rounded-2xl border border-white/10 bg-slate-800 p-8">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-white">Recuperar acesso</h1>
          <p className="mt-1 text-sm text-slate-400">
            Enviamos um link para você definir uma senha nova.
          </p>
        </div>

        {enviado ? (
          <div className="space-y-4">
            <p className="rounded-md bg-emerald-500/10 px-3 py-2 text-sm text-emerald-300">
              Se existir uma conta com esse e-mail, o link de recuperação chega
              em instantes. Confira também a caixa de spam.
            </p>
            <Link
              href="/superadmin/login"
              className="block text-center text-sm text-slate-400 hover:text-white"
            >
              Voltar para o login
            </Link>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
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
                autoComplete="email"
                className="w-full rounded-md border border-white/10 bg-white/5 px-3 py-2 text-white placeholder:text-slate-500"
                placeholder="voce@clinica.com.br"
              />
            </div>

            <button
              type="submit"
              disabled={carregando}
              className="w-full rounded-md bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700 disabled:opacity-60"
            >
              {carregando ? "Enviando..." : "Enviar link de recuperação"}
            </button>

            <Link
              href="/superadmin/login"
              className="block text-center text-sm text-slate-400 hover:text-white"
            >
              Voltar para o login
            </Link>
          </form>
        )}
      </div>
    </div>
  );
}
