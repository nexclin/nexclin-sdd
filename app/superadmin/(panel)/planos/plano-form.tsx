"use client";

/**
 * SPEC 003 — o editor de plano.
 *
 * # Por que ele pôde ser escrito agora, e não antes
 *
 * A tela de planos dizia, em comentário: *"leitura por enquanto; a escrita
 * depende de fechar o formato de `enabled_modules`, porque o default do MVP é
 * array e o uso é de objeto. Salvar antes de decidir gravaria os dois formatos
 * na mesma coluna"*.
 *
 * **A decisão foi tomada em 25/08** e está na migração
 * `20260825070000_corrige_default_de_enabled_modules.sql`: é objeto, o default
 * foi alinhado e uma constraint impede que volte a ser array. Com o formato
 * fechado, gravar deixou de ser ambíguo.
 *
 * # As quinze chaves aparecem sempre, ligadas e desligadas
 *
 * Listar só as ligadas esconderia plano mal configurado, que é exatamente o que
 * se quer enxergar: o plano é o **teto** de acesso de toda clínica nele.
 */

import { useState, useTransition } from "react";

import { MODULE_KEYS } from "@/lib/auth/modulos";
import { salvarPlano } from "@/lib/superadmin/acoes";
import { Aviso, Botao, Campo, Selecao } from "../_ui/formulario";

export interface PlanoEditavel {
  id: string;
  name: string;
  description?: string | null;
  monthly_price: number | null;
  annual_price: number | null;
  trial_days: number | null;
  max_users: number | null;
  max_patients: number | null;
  max_leads_month: number | null;
  enabled_modules: unknown;
  status?: string | null;
  visibility?: string | null;
}

/** A coluna chega como objeto novo ou como array antigo. Os dois são lidos. */
function ligados(valor: unknown): Set<string> {
  if (Array.isArray(valor)) return new Set(valor.filter((v) => typeof v === "string"));
  if (valor && typeof valor === "object") {
    return new Set(
      Object.entries(valor as Record<string, unknown>)
        .filter(([, v]) => v === true)
        .map(([k]) => k),
    );
  }
  return new Set();
}

/** Número para o input: vírgula decimal, sem símbolo de moeda. */
function paraInput(v: number | null | undefined): string {
  if (v === null || v === undefined) return "";
  return String(v).replace(".", ",");
}

export function PlanoForm({ plano }: { plano?: PlanoEditavel }) {
  const [aberto, setAberto] = useState(false);
  const [aviso, setAviso] = useState<string | null>(null);
  const [salvo, setSalvo] = useState(false);
  const [salvando, iniciar] = useTransition();

  const marcados = ligados(plano?.enabled_modules);

  function enviar(form: FormData) {
    iniciar(async () => {
      setSalvo(false);
      const r = await salvarPlano(form);
      if (r.ok) {
        setAviso(null);
        setSalvo(true);
        setAberto(false);
        return;
      }
      setAviso(r.mensagem ?? "Não foi possível salvar.");
    });
  }

  if (!aberto) {
    return (
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => { setSalvo(false); setAberto(true); }}
          className="text-sm text-emerald-400 hover:underline"
        >
          {plano ? "Editar plano" : "Novo plano"}
        </button>
        {salvo && <span className="text-xs text-emerald-300">Salvo.</span>}
      </div>
    );
  }

  return (
    <form action={enviar} className="space-y-5 rounded-lg border border-emerald-500/30 bg-slate-900 p-5">
      <input type="hidden" name="id" value={plano?.id ?? ""} />

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo nome="name" rotulo="Nome do plano" valor={plano?.name} obrigatorio />
        <Campo nome="description" rotulo="Descrição" valor={plano?.description ?? ""} />
        <Campo
          nome="monthly_price"
          rotulo="Mensalidade"
          valor={paraInput(plano?.monthly_price)}
          placeholder="0,00"
          nota="Em reais. Ponto e vírgula são entendidos como no Brasil."
        />
        <Campo
          nome="annual_price"
          rotulo="Preço anual"
          valor={paraInput(plano?.annual_price)}
          placeholder="0,00"
        />
        <Campo
          nome="trial_days"
          rotulo="Dias de teste"
          valor={plano?.trial_days ?? 14}
          tipo="number"
        />
        <Campo
          nome="max_users"
          rotulo="Limite de acessos"
          valor={plano?.max_users ?? 0}
          tipo="number"
          nota="Zero significa ILIMITADO nesta tabela, e não nenhum."
        />
        <Campo
          nome="max_patients"
          rotulo="Limite de pacientes"
          valor={plano?.max_patients ?? 0}
          tipo="number"
          nota="Zero é ilimitado."
        />
        <Campo
          nome="max_leads_month"
          rotulo="Limite de leads por mês"
          valor={plano?.max_leads_month ?? 0}
          tipo="number"
          nota="Zero é ilimitado."
        />
        <Selecao
          nome="status"
          rotulo="Situação"
          valor={plano?.status ?? "active"}
          opcoes={[
            { valor: "active", rotulo: "Ativo" },
            { valor: "inactive", rotulo: "Inativo" },
          ]}
        />
        <Selecao
          nome="visibility"
          rotulo="Visibilidade"
          valor={plano?.visibility ?? "public"}
          opcoes={[
            { valor: "public", rotulo: "Público" },
            { valor: "hidden", rotulo: "Oculto" },
          ]}
          nota="Oculto não aparece para o cliente, e continua atribuível por aqui."
        />
      </div>

      <div>
        <p className="mb-1 text-sm text-slate-400">Módulos liberados</p>
        <p className="mb-3 text-xs text-slate-500">
          Este é o teto. A permissão individual distribui abaixo dele e nunca o
          excede, então desmarcar aqui tira o módulo de todo mundo da clínica,
          inclusive do dono.
        </p>
        <ul className="grid gap-2 sm:grid-cols-3">
          {MODULE_KEYS.map((chave) => (
            <li key={chave}>
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  name="modulos"
                  value={chave}
                  defaultChecked={marcados.has(chave)}
                  className="h-4 w-4"
                />
                <code className="text-xs">{chave}</code>
              </label>
            </li>
          ))}
        </ul>
      </div>

      {aviso && <Aviso tom="erro">{aviso}</Aviso>}

      <div className="flex items-center gap-3">
        <Botao ocupado={salvando}>Salvar plano</Botao>
        <button
          type="button"
          onClick={() => { setAberto(false); setAviso(null); }}
          className="text-sm text-slate-400 hover:underline"
        >
          Cancelar
        </button>
      </div>
    </form>
  );
}
