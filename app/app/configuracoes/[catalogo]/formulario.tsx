"use client";

/**
 * SPEC 005 / T009 — o formulário único dos nove catálogos.
 *
 * Um formulário, e não nove. Os campos vêm da definição declarativa, do mesmo
 * jeito que as colunas da listagem vêm. Nove formulários seriam nove lugares
 * para a validação de moeda divergir, que é o Princípio VIII e é exatamente a
 * dívida registrada no `INVENTARIO-UI.md` da referência.
 *
 * É client component porque tem estado de interação real: qual linha está
 * aberta, e os erros que voltam por campo. A listagem continua sendo server.
 */

import { useState, useTransition } from "react";

import type { CampoDeCatalogo, DefinicaoDeCatalogo } from "@/lib/config/catalogo";
import { salvarLinhaDeCatalogo, alternarAtivoDeCatalogo } from "@/lib/config/acoes";

export interface LinhaEditavel {
  id: string;
  active: boolean;
  is_system?: boolean;
  [coluna: string]: unknown;
}

/**
 * O valor como ele deve aparecer DENTRO do input.
 *
 * Diferente do formatador da listagem, de propósito. A listagem mostra
 * `R$ 1.234,56`, e um input com esse texto devolveria isso mesmo no POST, com
 * o símbolo junto, que a validação recusa. Aqui vai o número cru com vírgula
 * decimal, que é o que a pessoa esperaria ter digitado.
 */
function paraInput(valor: unknown, tipo: CampoDeCatalogo["tipo"]): string {
  if (valor === null || valor === undefined) return "";
  if (tipo === "booleano") return valor ? "on" : "";
  if (tipo === "moeda" || tipo === "percentual") {
    const n = Number(valor);
    return Number.isFinite(n) ? String(n).replace(".", ",") : "";
  }
  return String(valor);
}

export function FormularioDeCatalogo({
  definicao,
  linhas,
}: {
  definicao: DefinicaoDeCatalogo;
  linhas: LinhaEditavel[];
}) {
  const [aberto, setAberto] = useState<string | null>(null);
  const [erros, setErros] = useState<Record<string, string>>({});
  const [aviso, setAviso] = useState<string | null>(null);
  const [salvando, iniciar] = useTransition();

  const emEdicao =
    aberto && aberto !== "novo" ? linhas.find((l) => l.id === aberto) : null;

  function fechar() {
    setAberto(null);
    setErros({});
    setAviso(null);
  }

  function enviar(form: FormData) {
    iniciar(async () => {
      const r = await salvarLinhaDeCatalogo(definicao.slug, form);
      if (r.ok) {
        fechar();
        return;
      }
      setErros(r.erros ?? {});
      setAviso(r.mensagem ?? null);
    });
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={() => {
            setErros({});
            setAviso(null);
            setAberto(aberto === "novo" ? null : "novo");
          }}
          className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90"
        >
          {aberto === "novo" ? "Cancelar" : `Novo ${definicao.rotuloSingular.toLowerCase()}`}
        </button>

        {linhas.length > 0 && (
          <span className="text-xs text-[#3A4A5C]">
            Clique em uma linha da tabela para editar.
          </span>
        )}
      </div>

      {aberto && (
        <form
          action={enviar}
          className="space-y-4 rounded-lg border border-[#1F8C8C]/30 bg-white p-5"
        >
          <h2 className="font-medium">
            {emEdicao
              ? `Editar ${definicao.rotuloSingular.toLowerCase()}`
              : `Novo ${definicao.rotuloSingular.toLowerCase()}`}
          </h2>

          {/* O `id` decide entre criar e atualizar. Não é fronteira de
              segurança: a RLS não alcança linha de outra clínica, e a action
              trata "zero linhas afetadas" como falha em vez de sucesso. */}
          <input type="hidden" name="id" value={emEdicao?.id ?? ""} />

          <div className="grid gap-4 sm:grid-cols-2">
            {definicao.campos.map((campo) => (
              <Campo
                key={campo.coluna}
                campo={campo}
                valor={paraInput(emEdicao?.[campo.coluna], campo.tipo)}
                erro={erros[campo.coluna]}
              />
            ))}
          </div>

          {aviso && (
            <p className="rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-800">
              {aviso}
            </p>
          )}

          {emEdicao?.is_system && (
            <p className="rounded border border-[#3A4A5C]/20 bg-[#F4F1EC] px-3 py-2 text-sm text-[#3A4A5C]">
              Registro do sistema. O banco recusa a alteração, e o botão fica
              aqui para que a recusa seja visível em vez de silenciosa.
            </p>
          )}

          <div className="flex items-center gap-3">
            <button
              type="submit"
              disabled={salvando}
              className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90 disabled:opacity-60"
            >
              {salvando ? "Salvando..." : "Salvar"}
            </button>
            <button
              type="button"
              onClick={fechar}
              className="text-sm text-[#3A4A5C] hover:underline"
            >
              Cancelar
            </button>
          </div>
        </form>
      )}

      {linhas.length > 0 && (
        <ul className="grid gap-2">
          {linhas.map((linha) => (
            <li
              key={linha.id}
              className="flex items-center justify-between gap-3 rounded-lg border border-[#3A4A5C]/15 bg-white px-3 py-2 text-sm"
            >
              <button
                type="button"
                onClick={() => {
                  setErros({});
                  setAviso(null);
                  setAberto(aberto === linha.id ? null : linha.id);
                }}
                className="flex-1 text-left hover:underline"
              >
                {String(linha.name ?? "(sem nome)")}
              </button>

              <button
                type="button"
                disabled={salvando || linha.is_system}
                title={
                  linha.is_system
                    ? "Registro do sistema: a clínica não desativa"
                    : linha.active
                      ? "Desativar. A linha continua no histórico."
                      : "Reativar"
                }
                onClick={() =>
                  iniciar(async () => {
                    const r = await alternarAtivoDeCatalogo(
                      definicao.slug,
                      linha.id,
                      !linha.active,
                    );
                    if (!r.ok) setAviso(r.mensagem ?? "Não foi possível alterar.");
                  })
                }
                className="shrink-0 text-xs text-[#1F8C8C] hover:underline disabled:text-[#3A4A5C]/40 disabled:no-underline"
              >
                {linha.active ? "Desativar" : "Reativar"}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function Campo({
  campo,
  valor,
  erro,
}: {
  campo: CampoDeCatalogo;
  valor: string;
  erro?: string;
}) {
  const id = `campo-${campo.coluna}`;

  if (campo.tipo === "booleano") {
    return (
      <label className="flex items-center gap-2 text-sm">
        <input
          type="checkbox"
          name={campo.coluna}
          defaultChecked={valor === "on"}
          className="h-4 w-4"
        />
        {campo.rotulo}
      </label>
    );
  }

  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={id} className="text-sm text-[#3A4A5C]">
        {campo.rotulo}
        {campo.obrigatorio && <span aria-hidden> *</span>}
      </label>
      <input
        id={id}
        name={campo.coluna}
        defaultValue={valor}
        inputMode={campo.tipo === "texto" ? undefined : "decimal"}
        aria-invalid={erro ? true : undefined}
        aria-describedby={campo.ajuda || erro ? `${id}-nota` : undefined}
        className={
          erro
            ? "rounded-lg border border-red-400 px-3 py-2 text-sm"
            : "rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
        }
      />
      {(erro || campo.ajuda) && (
        <p
          id={`${id}-nota`}
          className={erro ? "text-xs text-red-600" : "text-xs text-[#3A4A5C]/80"}
        >
          {erro ?? campo.ajuda}
        </p>
      )}
    </div>
  );
}
