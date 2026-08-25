"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

/**
 * SPEC 001 / T025 — o banner âmbar do modo suporte.
 *
 * O contrato de guards é literal: *"se `get_my_active_impersonation()` retorna
 * sessão ativa, renderizar banner âmbar fixo 'Modo suporte — <clínica>' em
 * todas as rotas, mais a ação 'Sair da conta'"*.
 *
 * A exigência de "todas as rotas" é o que faz ele viver no layout, e não em
 * cada página. Uma rota sem o banner é uma rota onde o operador esquece que
 * está dentro da conta de um cliente, e passa a agir como se fosse a própria.
 *
 * # Sobre o cache
 *
 * O contrato pede zerar o cache a cada entrada e saída. Não há React Query
 * neste app: os dados são lidos em Server Component. O equivalente exato é
 * `router.refresh()`, que descarta o cache de roteador do Next e refaz a
 * renderização no servidor com a âncora `clinic_id` já trocada. Sem isso, a
 * primeira tela após a saída ainda mostraria dado da clínica de onde se saiu.
 */
export function BannerImpersonacao({ clinica }: { clinica: string }) {
  const [saindo, setSaindo] = useState(false);
  const [erro, setErro] = useState(false);
  const router = useRouter();

  async function sair() {
    setSaindo(true);
    setErro(false);
    try {
      const supabase = createClient();
      const { error } = await supabase.rpc("superadmin_exit_clinic");
      if (error) {
        setErro(true);
        return;
      }
      // Ordem importa: primeiro descarta o cache, depois navega. Invertido, a
      // tela do painel apareceria com o cache da conta do cliente.
      router.refresh();
      router.push("/superadmin/contas");
    } catch {
      setErro(true);
    } finally {
      setSaindo(false);
    }
  }

  return (
    <div
      role="status"
      className="sticky top-0 z-50 flex items-center justify-between gap-4 bg-amber-400 px-4 py-2 text-sm text-[#0E1620]"
    >
      <span className="font-medium">
        Modo suporte — {clinica}
        {erro && (
          <span className="ml-2 font-normal">
            Não foi possível sair agora. Tente de novo.
          </span>
        )}
      </span>
      <button
        type="button"
        onClick={sair}
        disabled={saindo}
        className="shrink-0 rounded-md border border-[#0E1620]/30 px-3 py-1 font-medium transition hover:bg-[#0E1620]/10 disabled:opacity-60"
      >
        {saindo ? "Saindo..." : "Sair da conta"}
      </button>
    </div>
  );
}
