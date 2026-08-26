"use client";

/**
 * SPEC 003 — as peças de formulário do painel.
 *
 * Extraídas pelo mesmo motivo que `_ui/index.tsx`: três formulários repetindo o
 * mesmo campo escuro é onde a divergência visual nasce, e o `INVENTARIO-UI`
 * registra três vocabulários convivendo na referência por falta disto.
 */

import * as React from "react";

export function Campo({
  nome,
  rotulo,
  valor,
  tipo = "text",
  nota,
  obrigatorio,
  placeholder,
}: {
  nome: string;
  rotulo: string;
  valor?: string | number;
  tipo?: string;
  nota?: string;
  obrigatorio?: boolean;
  placeholder?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={nome} className="text-sm text-slate-400">
        {rotulo}
        {obrigatorio && <span aria-hidden> *</span>}
      </label>
      <input
        id={nome}
        name={nome}
        type={tipo}
        defaultValue={valor}
        placeholder={placeholder}
        className="rounded-lg border border-white/15 bg-slate-950 px-3 py-2 text-sm text-slate-100"
      />
      {nota && <p className="text-xs text-slate-500">{nota}</p>}
    </div>
  );
}

export function Selecao({
  nome,
  rotulo,
  valor,
  opcoes,
  nota,
}: {
  nome: string;
  rotulo: string;
  valor?: string;
  opcoes: readonly { valor: string; rotulo: string; desabilitado?: boolean }[];
  nota?: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={nome} className="text-sm text-slate-400">
        {rotulo}
      </label>
      <select
        id={nome}
        name={nome}
        defaultValue={valor}
        className="rounded-lg border border-white/15 bg-slate-950 px-3 py-2 text-sm text-slate-100"
      >
        {opcoes.map((o) => (
          <option key={o.valor} value={o.valor} disabled={o.desabilitado}>
            {o.rotulo}
          </option>
        ))}
      </select>
      {nota && <p className="text-xs text-slate-500">{nota}</p>}
    </div>
  );
}

export function Aviso({ tom, children }: { tom: "erro" | "ok"; children: React.ReactNode }) {
  return (
    <p
      className={
        tom === "erro"
          ? "rounded border border-amber-500/40 bg-amber-500/10 px-3 py-2 text-sm text-amber-200"
          : "rounded border border-emerald-500/40 bg-emerald-500/10 px-3 py-2 text-sm text-emerald-200"
      }
    >
      {children}
    </p>
  );
}

export function Botao({
  children,
  ocupado,
  tipo = "submit",
  onClick,
}: {
  children: React.ReactNode;
  ocupado?: boolean;
  tipo?: "submit" | "button";
  onClick?: () => void;
}) {
  return (
    <button
      type={tipo}
      onClick={onClick}
      disabled={ocupado}
      className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-emerald-500 disabled:opacity-60"
    >
      {ocupado ? "Salvando..." : children}
    </button>
  );
}
