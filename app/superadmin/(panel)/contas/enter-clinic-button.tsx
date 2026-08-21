"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

/**
 * SPEC 001 / #25 — Entrada em modo suporte (impersonação).
 * Chama a RPC superadmin_enter_clinic (troca auditada da âncora clinic_id) e
 * leva ao app da clínica. A saída/banner âmbar vivem no app da clínica (#25).
 * A autorização REAL é do banco (a RPC valida is_superadmin).
 */
export function EnterClinicButton({
  clinicId,
  clinicName,
}: {
  clinicId: string;
  clinicName: string;
}) {
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function handleEnter() {
    if (
      !window.confirm(
        `Entrar na conta "${clinicName}" em modo suporte? Suas ações ficarão auditadas.`,
      )
    ) {
      return;
    }
    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.rpc("superadmin_enter_clinic", {
      _target_clinic_id: clinicId,
    });
    setLoading(false);
    if (error) {
      window.alert(`Falha ao entrar na conta: ${error.message}`);
      return;
    }
    router.push("/");
    router.refresh();
  }

  return (
    <button
      onClick={handleEnter}
      disabled={loading}
      className="rounded border border-amber-500/40 px-2 py-0.5 text-xs text-amber-300 hover:bg-amber-500/10 disabled:opacity-60"
    >
      {loading ? "Entrando..." : "Acessar conta"}
    </button>
  );
}
