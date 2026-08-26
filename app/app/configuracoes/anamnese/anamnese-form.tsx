"use client";

import { useMemo, useState, useTransition } from "react";

import { salvarModeloDeAnamnese } from "@/lib/config/acoes";
import {
  ROTULO_DE_TIPO,
  TIPOS_COM_OPCOES,
  TIPOS_DE_CAMPO,
  normalizaParaSecoes,
  paraJsonb,
  problemasDoModelo,
  type CampoDeAnamnese,
  type SecaoDeAnamnese,
  type TipoDeCampo,
} from "@/lib/config/anamnese";

export interface ModeloCru {
  id: string;
  title: string | null;
  specialty: string | null;
  fields: unknown;
  is_default: boolean;
  active: boolean;
}

/** Id novo, e só para peça recém-criada. Ver o comentário em `anamnese.ts`. */
const novoId = () => Math.random().toString(36).slice(2, 9);

export function AnamneseForm({ modelos }: { modelos: ModeloCru[] }) {
  const [aberto, setAberto] = useState(false);
  const [editando, setEditando] = useState<string>("");
  const [titulo, setTitulo] = useState("");
  const [especialidade, setEspecialidade] = useState("");
  const [padrao, setPadrao] = useState(false);
  const [secoes, setSecoes] = useState<SecaoDeAnamnese[]>([]);
  const [aviso, setAviso] = useState<string | null>(null);
  const [salvando, iniciar] = useTransition();

  const problemas = useMemo(() => problemasDoModelo(secoes), [secoes]);

  function abrir(id: string) {
    const m = modelos.find((x) => x.id === id);
    setEditando(id);
    setTitulo(m?.title ?? "");
    setEspecialidade(m?.specialty ?? "");
    setPadrao(Boolean(m?.is_default));
    // A mesma normalização da leitura: a tela nunca vê a forma antiga crua.
    setSecoes(m ? normalizaParaSecoes(m.fields, novoId) : [
      { id: novoId(), titulo: "Geral", campos: [] },
    ]);
    setAviso(null);
    setAberto(true);
  }

  function enviar(form: FormData) {
    iniciar(async () => {
      form.set("modelo", JSON.stringify(paraJsonb(secoes)));
      const r = await salvarModeloDeAnamnese(form);
      if (r.ok) {
        setAberto(false);
        setEditando("");
        setAviso(null);
        return;
      }
      setAviso(r.mensagem ?? "Não foi possível salvar.");
    });
  }

  const trocaSecao = (i: number, nova: SecaoDeAnamnese) =>
    setSecoes((s) => s.map((x, j) => (j === i ? nova : x)));

  if (!aberto) {
    return (
      <div className="flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={() => abrir("")}
          className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90"
        >
          Novo modelo
        </button>
        {modelos.length > 0 && (
          <select
            value=""
            onChange={(e) => e.target.value && abrir(e.target.value)}
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          >
            <option value="">Editar um modelo...</option>
            {modelos.map((m) => (
              <option key={m.id} value={m.id}>
                {m.title || "(sem título)"}
              </option>
            ))}
          </select>
        )}
      </div>
    );
  }

  return (
    <form action={enviar} className="space-y-5 rounded-lg border border-[#1F8C8C]/30 bg-white p-5">
      <input type="hidden" name="id" value={editando} />

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-1">
          <label htmlFor="title" className="text-sm text-[#3A4A5C]">Título *</label>
          <input
            id="title" name="title" value={titulo}
            onChange={(e) => setTitulo(e.target.value)}
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          />
        </div>
        <div className="flex flex-col gap-1">
          <label htmlFor="specialty" className="text-sm text-[#3A4A5C]">Especialidade</label>
          <input
            id="specialty" name="specialty" value={especialidade}
            onChange={(e) => setEspecialidade(e.target.value)}
            className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
          />
        </div>
      </div>

      <label className="flex items-start gap-2 text-sm">
        <input
          type="checkbox" name="is_default" checked={padrao}
          onChange={(e) => setPadrao(e.target.checked)}
          className="mt-0.5 h-4 w-4"
        />
        <span>
          Este é o modelo padrão
          <span className="block text-xs text-[#3A4A5C]/80">
            Só um pode ser. Marcar aqui desmarca o anterior, porque dois padrões
            fariam a consulta escolher um por ordem de leitura, que muda sem aviso.
          </span>
        </span>
      </label>

      <div className="space-y-4">
        {secoes.map((secao, i) => (
          <Secao
            key={secao.id}
            secao={secao}
            onChange={(nova) => trocaSecao(i, nova)}
            onRemove={() => setSecoes((s) => s.filter((_, j) => j !== i))}
          />
        ))}
        <button
          type="button"
          onClick={() => setSecoes((s) => [...s, { id: novoId(), titulo: "", campos: [] }])}
          className="text-sm text-[#1F8C8C] hover:underline"
        >
          + Nova seção
        </button>
      </div>

      {problemas.length > 0 && (
        <ul className="space-y-1 rounded border border-amber-300 bg-amber-50 px-3 py-2">
          {problemas.map((p, i) => (
            <li key={i} className="text-xs text-amber-800">
              <span className="font-medium">{p.onde}:</span> {p.mensagem}
            </li>
          ))}
        </ul>
      )}
      {aviso && (
        <p className="rounded border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700">
          {aviso}
        </p>
      )}

      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={salvando || problemas.length > 0}
          title={problemas.length > 0 ? "Resolva os avisos acima antes de salvar." : undefined}
          className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90 disabled:opacity-60"
        >
          {salvando ? "Salvando..." : "Salvar modelo"}
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

function Secao({
  secao,
  onChange,
  onRemove,
}: {
  secao: SecaoDeAnamnese;
  onChange: (s: SecaoDeAnamnese) => void;
  onRemove: () => void;
}) {
  const trocaCampo = (i: number, campo: CampoDeAnamnese) =>
    onChange({ ...secao, campos: secao.campos.map((c, j) => (j === i ? campo : c)) });

  return (
    <fieldset className="rounded-lg border border-[#3A4A5C]/20 p-4">
      <div className="flex items-center gap-3">
        <input
          value={secao.titulo}
          onChange={(e) => onChange({ ...secao, titulo: e.target.value })}
          placeholder="Título da seção"
          className="flex-1 rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm font-medium"
        />
        <button type="button" onClick={onRemove} className="text-xs text-[#3A4A5C] hover:underline">
          Remover seção
        </button>
      </div>

      <ul className="mt-3 space-y-3">
        {secao.campos.map((campo, i) => (
          <li key={campo.id} className="rounded border border-[#3A4A5C]/15 p-3">
            <div className="grid gap-2 sm:grid-cols-2">
              <input
                value={campo.label}
                onChange={(e) => trocaCampo(i, { ...campo, label: e.target.value })}
                placeholder="A pergunta que o paciente vê"
                className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
              />
              <select
                value={campo.tipo}
                onChange={(e) => trocaCampo(i, { ...campo, tipo: e.target.value as TipoDeCampo })}
                className="rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
              >
                {TIPOS_DE_CAMPO.map((t) => (
                  <option key={t} value={t}>{ROTULO_DE_TIPO[t]}</option>
                ))}
              </select>
            </div>

            {TIPOS_COM_OPCOES.includes(campo.tipo) && (
              <div className="mt-2">
                <textarea
                  value={(campo.opcoes ?? []).map((o) => o.label).join("\n")}
                  onChange={(e) =>
                    trocaCampo(i, {
                      ...campo,
                      opcoes: e.target.value
                        .split("\n")
                        .map((l) => l.trim())
                        .filter((l) => l !== "")
                        .map((l) => ({ label: l, value: l })),
                    })
                  }
                  rows={3}
                  placeholder={"Uma opção por linha\nSim\nNão"}
                  className="w-full rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
                />
                <p className="text-xs text-[#3A4A5C]/80">
                  Uma opção por linha. Precisa de pelo menos duas.
                </p>
              </div>
            )}

            <div className="mt-2 flex flex-wrap items-center gap-4 text-sm">
              <label className="flex items-center gap-2">
                <input
                  type="checkbox" checked={campo.obrigatorio}
                  onChange={(e) => trocaCampo(i, { ...campo, obrigatorio: e.target.checked })}
                  className="h-4 w-4"
                />
                Obrigatório
              </label>
              <label className="flex items-center gap-2">
                <input
                  type="checkbox" checked={campo.ativo}
                  onChange={(e) => trocaCampo(i, { ...campo, ativo: e.target.checked })}
                  className="h-4 w-4"
                />
                Ativo
              </label>
              <button
                type="button"
                onClick={() => onChange({ ...secao, campos: secao.campos.filter((_, j) => j !== i) })}
                className="text-xs text-[#3A4A5C] hover:underline"
                title="Desativar preserva as respostas antigas. Remover tira o campo do modelo, e as respostas já dadas ficam órfãs."
              >
                Remover campo
              </button>
            </div>
          </li>
        ))}
      </ul>

      <button
        type="button"
        onClick={() =>
          onChange({
            ...secao,
            campos: [
              ...secao.campos,
              { id: novoId(), label: "", tipo: "short_text", obrigatorio: false, ativo: true },
            ],
          })
        }
        className="mt-3 text-sm text-[#1F8C8C] hover:underline"
      >
        + Novo campo
      </button>
    </fieldset>
  );
}
