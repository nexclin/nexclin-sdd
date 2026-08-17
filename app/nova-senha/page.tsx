"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

/**
 * SPEC 001 / T019 — Conclusão do fluxo de recuperação de senha.
 *
 * O usuário chega aqui já autenticado pela sessão de recovery criada em
 * /auth/callback, e define a PRÓPRIA senha. Nenhum administrador define senha
 * de terceiro em lugar nenhum do sistema (Princípio II / regra (e)).
 */
export default function NovaSenhaPage() {
  const [senha, setSenha] = useState("");
  const [confirmacao, setConfirmacao] = useState("");
  const [carregando, setCarregando] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const [pronto, setPronto] = useState(false);
  const [temSessao, setTemSessao] = useState<boolean | null>(null);
  const router = useRouter();

  useEffect(() => {
    const supabase = createClient();
    supabase.auth.getUser().then(({ data }) => setTemSessao(!!data.user));
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErro(null);

    if (senha.length < 8) {
      setErro("A senha precisa ter pelo menos 8 caracteres.");
      return;
    }
    if (senha !== confirmacao) {
      setErro("As duas senhas não são iguais.");
      return;
    }

    setCarregando(true);
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({ password: senha });
    setCarregando(false);

    if (error) {
      setErro(error.message);
      return;
    }

    setPronto(true);
    setTimeout(() => {
      router.replace("/superadmin/login");
      router.refresh();
    }, 2000);
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-900 p-4">
      <div className="w-full max-w-md rounded-2xl border border-white/10 bg-slate-800 p-8">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-white">Definir nova senha</h1>
          <p className="mt-1 text-sm text-slate-400">
            Escolha uma senha que só você conheça.
          </p>
        </div>

        {temSessao === false && (
          <p className="rounded-md bg-amber-500/10 px-3 py-2 text-sm text-amber-300">
            Este link não é mais válido. Peça um novo e-mail de recuperação e
            abra o link mais recente.
          </p>
        )}

        {pronto ? (
          <p className="rounded-md bg-emerald-500/10 px-3 py-2 text-sm text-emerald-300">
            Senha alterada. Redirecionando para o login...
          </p>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm text-slate-300" htmlFor="senha">
                Nova senha
              </label>
              <input
                id="senha"
                type="password"
                value={senha}
                onChange={(e) => setSenha(e.target.value)}
                required
                minLength={8}
                autoComplete="new-password"
                className="w-full rounded-md border border-white/10 bg-white/5 px-3 py-2 text-white placeholder:text-slate-500"
                placeholder="mínimo de 8 caracteres"
              />
            </div>

            <div className="space-y-2">
              <label className="text-sm text-slate-300" htmlFor="confirmacao">
                Repita a nova senha
              </label>
              <input
                id="confirmacao"
                type="password"
                value={confirmacao}
                onChange={(e) => setConfirmacao(e.target.value)}
                required
                autoComplete="new-password"
                className="w-full rounded-md border border-white/10 bg-white/5 px-3 py-2 text-white placeholder:text-slate-500"
                placeholder="••••••••"
              />
            </div>

            {erro && (
              <p className="rounded-md bg-red-500/10 px-3 py-2 text-sm text-red-400">
                {erro}
              </p>
            )}

            <button
              type="submit"
              disabled={carregando || temSessao === false}
              className="w-full rounded-md bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700 disabled:opacity-60"
            >
              {carregando ? "Salvando..." : "Salvar nova senha"}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
