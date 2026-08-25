/**
 * SPEC 001 / T023 — peças visuais compartilhadas das telas do painel.
 *
 * Extraídas porque nove telas repetindo a mesma tabela é onde a divergência
 * visual nasce. O INVENTARIO-UI registra três vocabulários de período
 * convivendo na referência justamente por falta disto.
 */

/** Célula de tabela com o padrão visual do painel. */
function Td({ children }: { children: React.ReactNode }) {
  return <td className="border-t border-white/10 px-3 py-2 align-top">{children}</td>;
}

function Th({ children }: { children: React.ReactNode }) {
  return <th className="px-3 py-2 text-left font-medium text-slate-400">{children}</th>;
}

function Cabecalho({ titulo, subtitulo }: { titulo: string; subtitulo: string }) {
  return (
    <div>
      <h1 className="text-2xl font-semibold">{titulo}</h1>
      <p className="mt-1 text-sm text-slate-400">{subtitulo}</p>
    </div>
  );
}

function Vazio({ children }: { children: React.ReactNode }) {
  return <p className="rounded-lg border border-white/10 bg-slate-900 p-5 text-sm text-slate-400">{children}</p>;
}

function dataCurta(v: unknown): string {
  if (typeof v !== "string") return "—";
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? "—" : d.toLocaleDateString("pt-BR");
}

function moeda(v: unknown): string {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return "—";
  return n.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

export { Td, Th, Cabecalho, Vazio, dataCurta, moeda };
