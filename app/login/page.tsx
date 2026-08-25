"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

/**
 * SPEC 001 / T019 — login do usuário comum da clínica.
 *
 * Separado do `/superadmin/login` de propósito, e a separação é de produto, não
 * de código: são dois mundos que o operador precisa distinguir num relance
 * (`.claude/rules/marca.md`). O login do painel ainda confere
 * `superadmin_operators` depois de autenticar; este não, porque quem entra aqui
 * é usuário de clínica e quem decide o que ele vê é a cascata do banco.
 *
 * **Não existe caminho aqui que defina senha de terceiro.** Só
 * `signInWithPassword` com a senha que o próprio dono digitou, e o link para o
 * fluxo de recuperação por e-mail. Regra (e) da constituição.
 */
export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [carregando, setCarregando] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const router = useRouter();

  async function entrar(e: React.FormEvent) {
    e.preventDefault();
    setCarregando(true);
    setErro(null);

    try {
      const supabase = createClient();
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password: senha,
      });

      if (error) {
        // Mensagem única para e-mail inexistente e senha errada. Distinguir os
        // dois entrega quais e-mails existem na base, que é enumeração de
        // usuário. O requisito `NGS1.02.16` da certificação SBIS pede
        // exatamente isto: erro de login não revela qual dado está errado.
        setErro("E-mail ou senha inválidos.");
        return;
      }

      // `refresh` antes de navegar: o layout de `/app` é Server Component e
      // precisa reler os cookies de sessão que acabaram de ser gravados.
      router.refresh();
      router.push("/app");
    } catch {
      setErro("Não foi possível entrar agora. Tente de novo em instantes.");
    } finally {
      setCarregando(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#F4F1EC] px-4">
      <div className="w-full max-w-sm">
        <h1 className="text-2xl font-semibold text-[#0E1620]">NexClin</h1>
        <p className="mt-1 text-sm text-[#3A4A5C]">Entre para acessar a clínica.</p>

        <form onSubmit={entrar} className="mt-8 space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm text-[#3A4A5C]">
              E-mail
            </label>
            <input
              id="email"
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 w-full rounded-md border border-[#3A4A5C]/25 bg-white px-3 py-2 text-[#0E1620] outline-none focus:border-[#1F8C8C]"
            />
          </div>

          <div>
            <label htmlFor="senha" className="block text-sm text-[#3A4A5C]">
              Senha
            </label>
            <input
              id="senha"
              type="password"
              required
              autoComplete="current-password"
              value={senha}
              onChange={(e) => setSenha(e.target.value)}
              className="mt-1 w-full rounded-md border border-[#3A4A5C]/25 bg-white px-3 py-2 text-[#0E1620] outline-none focus:border-[#1F8C8C]"
            />
          </div>

          {erro && (
            <p role="alert" className="text-sm text-red-700">
              {erro}
            </p>
          )}

          <button
            type="submit"
            disabled={carregando}
            className="w-full rounded-md bg-[#1F8C8C] px-4 py-2 font-medium text-white transition hover:bg-[#1F8C8C]/90 disabled:opacity-60"
          >
            {carregando ? "Entrando..." : "Entrar"}
          </button>
        </form>

        <div className="mt-6 flex justify-between text-sm">
          <Link href="/esqueci-senha" className="text-[#1F8C8C] hover:underline">
            Esqueci minha senha
          </Link>
          <Link href="/superadmin/login" className="text-[#3A4A5C] hover:underline">
            Acesso interno
          </Link>
        </div>
      </div>
    </main>
  );
}
