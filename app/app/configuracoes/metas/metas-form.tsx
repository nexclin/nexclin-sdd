"use client";

import { useState, useTransition } from "react";

import { salvarMeta } from "@/lib/config/acoes";
import { porDiaUtil } from "@/lib/config/metas";

export interface MetaDoMes {
  id?: string | null;
  revenue_target?: number | null;
  new_patients_target?: number | null;
  closings_target?: number | null;
  conversion_target?: number | null;
}

/**
 * O formulário da meta do mês.
 *
 * Cada campo mostra, ao vivo, **o que ele significa por dia útil**. É a peça que
 * faz a meta virar decisão: digitar 60 mil e ver "R$ 2.857 por dia útil" é o
 * momento em que a pessoa descobre se a meta é real.
 */
export function MetasForm({
  ano,
  mes,
  meta,
  diasRestantes,
}: {
  ano: number;
  mes: number;
  meta: MetaDoMes | null;
  diasRestantes: number;
}) {
  const [salvando, iniciar] = useTransition();
  const [aviso, setAviso] = useState<string | null>(null);
  const [salvo, setSalvo] = useState(false);
  const [faturamento, setFaturamento] = useState(
    meta?.revenue_target ? String(meta.revenue_target).replace(".", ",") : "",
  );

  const porDia = (() => {
    const n = Number(faturamento.replace(/\./g, "").replace(",", "."));
    if (!Number.isFinite(n) || n <= 0) return null;
    return porDiaUtil(n, 0, diasRestantes);
  })();

  function enviar(form: FormData) {
    iniciar(async () => {
      setSalvo(false);
      const r = await salvarMeta(form);
      if (r.ok) {
        setAviso(null);
        setSalvo(true);
        return;
      }
      setAviso(r.mensagem ?? "Não foi possível salvar.");
    });
  }

  return (
    <form action={enviar} className="space-y-4 rounded-lg border border-[#3A4A5C]/15 bg-white p-5">
      <h2 className="font-medium">A meta deste mês</h2>

      <input type="hidden" name="id" value={meta?.id ?? ""} />
      <input type="hidden" name="ano" value={ano} />
      <input type="hidden" name="mes" value={mes} />

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-1">
          <label htmlFor="revenue_target" className="text-sm text-[#3A4A5C]">
            Faturamento
          </label>
          <input
            id="revenue_target"
            name="revenue_target"
            inputMode="decimal"
            value={faturamento}
            onChange={(e) => setFaturamento(e.target.value)}
            placeholder="0,00"
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          />
          <p className="text-xs text-[#3A4A5C]/80">
            {porDia === null
              ? "Sem dia útil restante para distribuir."
              : `Dá ${porDia.toLocaleString("pt-BR", {
                  style: "currency",
                  currency: "BRL",
                  maximumFractionDigits: 0,
                })} por dia útil, em ${diasRestantes} dia(s).`}
          </p>
        </div>

        <Campo
          nome="new_patients_target"
          rotulo="Pacientes novos"
          valor={meta?.new_patients_target ?? ""}
        />
        <Campo
          nome="closings_target"
          rotulo="Fechamentos"
          valor={meta?.closings_target ?? ""}
        />
        <Campo
          nome="conversion_target"
          rotulo="Conversão (%)"
          valor={meta?.conversion_target ?? ""}
          nota="Percentual de orçamentos que viram tratamento."
        />
      </div>

      {aviso && (
        <p className="rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-800">
          {aviso}
        </p>
      )}
      {salvo && (
        <p className="rounded border border-[#1F8C8C]/40 bg-[#1F8C8C]/5 px-3 py-2 text-sm text-[#1F8C8C]">
          Meta salva.
        </p>
      )}

      <button
        type="submit"
        disabled={salvando}
        className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90 disabled:opacity-60"
      >
        {salvando ? "Salvando..." : "Salvar meta"}
      </button>
    </form>
  );
}

function Campo({
  nome,
  rotulo,
  valor,
  nota,
}: {
  nome: string;
  rotulo: string;
  valor: string | number;
  nota?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={nome} className="text-sm text-[#3A4A5C]">
        {rotulo}
      </label>
      <input
        id={nome}
        name={nome}
        inputMode="decimal"
        defaultValue={valor}
        className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
      />
      {nota && <p className="text-xs text-[#3A4A5C]/80">{nota}</p>}
    </div>
  );
}
