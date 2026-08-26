"use client";

import { useState, useTransition } from "react";

import { salvarConta } from "@/lib/config/acoes";
import { paisPossiveis, type ContaCrua } from "@/lib/config/arvore";

/**
 * O formulário do plano de contas.
 *
 * A lista de pais vem de `paisPossiveis`, que exclui a própria conta e toda a
 * descendência dela. **É o que impede o ciclo antes de ele existir**, e é a
 * razão de o campo ser uma lista e não texto livre: `parent_id` é FK, e FK
 * aceita qualquer id da mesma tabela, inclusive um que feche o ciclo.
 *
 * A mesma checagem roda de novo na server action. Aqui é conveniência; lá é
 * fronteira.
 */
export function PlanoDeContasForm({ contas }: { contas: ContaCrua[] }) {
  const [aberto, setAberto] = useState(false);
  const [editando, setEditando] = useState<string>("");
  const [aviso, setAviso] = useState<string | null>(null);
  const [salvando, iniciar] = useTransition();

  const emEdicao = editando ? contas.find((c) => c.id === editando) : undefined;
  const pais = paisPossiveis(contas, editando || null);

  function enviar(form: FormData) {
    iniciar(async () => {
      const r = await salvarConta(form);
      if (r.ok) {
        setAviso(null);
        setAberto(false);
        setEditando("");
        return;
      }
      setAviso(r.mensagem ?? "Não foi possível salvar.");
    });
  }

  if (!aberto) {
    return (
      <div className="flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={() => { setEditando(""); setAviso(null); setAberto(true); }}
          className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90"
        >
          Nova conta
        </button>
        {contas.length > 0 && (
          <select
            value=""
            onChange={(e) => {
              if (!e.target.value) return;
              setEditando(e.target.value);
              setAviso(null);
              setAberto(true);
            }}
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          >
            <option value="">Editar uma conta...</option>
            {[...contas]
              .filter((c) => !c.is_system)
              .map((c) => (
                <option key={c.id} value={c.id}>
                  {c.code} · {c.name}
                </option>
              ))}
          </select>
        )}
      </div>
    );
  }

  return (
    <form action={enviar} className="space-y-4 rounded-lg border border-[#1F8C8C]/30 bg-white p-5">
      <h2 className="font-medium">{emEdicao ? "Editar conta" : "Nova conta"}</h2>

      <input type="hidden" name="id" value={emEdicao?.id ?? ""} />

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-1">
          <label htmlFor="code" className="text-sm text-[#3A4A5C]">Código *</label>
          <input
            id="code"
            name="code"
            defaultValue={emEdicao?.code ?? ""}
            placeholder="1.1.01"
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          />
          <p className="text-xs text-[#3A4A5C]/80">
            Separe os níveis por ponto. A ordenação entende número, então 1.10
            vem depois de 1.9 e não antes.
          </p>
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="name" className="text-sm text-[#3A4A5C]">Nome *</label>
          <input
            id="name"
            name="name"
            defaultValue={emEdicao?.name ?? ""}
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          />
        </div>

        <div className="flex flex-col gap-1 sm:col-span-2">
          <label htmlFor="parent_id" className="text-sm text-[#3A4A5C]">Conta pai</label>
          <select
            id="parent_id"
            name="parent_id"
            defaultValue={emEdicao?.parent_id ?? ""}
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          >
            <option value="">Nenhuma, é conta de primeiro nível</option>
            {pais.map((c) => (
              <option key={c.id} value={c.id}>
                {c.code} · {c.name}
              </option>
            ))}
          </select>
          <p className="text-xs text-[#3A4A5C]/80">
            A própria conta e o que está abaixo dela não aparecem aqui: a
            hierarquia ficaria circular, e toda leitura em árvore travaria.
          </p>
        </div>
      </div>

      {aviso && (
        <p className="rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-800">
          {aviso}
        </p>
      )}

      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={salvando}
          className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90 disabled:opacity-60"
        >
          {salvando ? "Salvando..." : "Salvar conta"}
        </button>
        <button
          type="button"
          onClick={() => { setAberto(false); setEditando(""); setAviso(null); }}
          className="text-sm text-[#3A4A5C] hover:underline"
        >
          Cancelar
        </button>
      </div>
    </form>
  );
}
