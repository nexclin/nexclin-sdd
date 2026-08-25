import { createClient } from "@/lib/supabase/server";
import { Cabecalho, Td, Th, Vazio, dataCurta, moeda } from "../_ui";

/**
 * SPEC 001 / T023 — Faturamento.
 *
 * Lê `billings`. A automação de cobrança, a régua D+1/3/7/15/30 que já tem
 * parâmetro gravado em `saas_settings`, **não existe**: está no BACKLOG. Então
 * esta tela mostra o que foi registrado e não promete cobrar nada sozinha.
 *
 * O total soma apenas o que está pago, e apenas dentro das cobranças listadas.
 * Somar o previsto junto do realizado é como relatório passa a mentir.
 */
export default async function FaturamentoPage() {
  const supabase = await createClient();
  const { data: cobrancas } = await supabase
    .from("billings")
    .select(
      "id, clinic_id, amount, status, attempted_at, paid_at, attempts, period_start, period_end, clinics(name)",
    )
    .order("created_at", { ascending: false })
    .limit(100);

  const pago = (cobrancas ?? []).reduce(
    (soma, c) => soma + (c.status === "paid" ? Number(c.amount) || 0 : 0),
    0,
  );

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Faturamento"
        subtitulo="Cobranças registradas. A automação de cobrança ainda não existe."
      />

      <div className="rounded-lg border border-white/10 bg-slate-900 p-4">
        <div className="text-2xl font-semibold">{moeda(pago)}</div>
        <div className="mt-1 text-xs text-slate-400">
          Somado entre as cobranças pagas listadas abaixo, nas 100 mais recentes
        </div>
      </div>

      {(cobrancas ?? []).length === 0 ? (
        <Vazio>Nenhuma cobrança registrada.</Vazio>
      ) : (
        <table className="w-full overflow-hidden rounded-lg border border-white/10 bg-slate-900 text-sm">
          <thead>
            <tr>
              <Th>Clínica</Th>
              <Th>Valor</Th>
              <Th>Status</Th>
              <Th>Competência</Th>
              <Th>Tentativas</Th>
              <Th>Pago em</Th>
            </tr>
          </thead>
          <tbody>
            {(cobrancas ?? []).map((c) => (
              <tr key={c.id}>
                <Td>{(c.clinics as { name?: string } | null)?.name ?? "—"}</Td>
                <Td>{moeda(c.amount)}</Td>
                <Td>{c.status}</Td>
                <Td>
                  {dataCurta(c.period_start)} a {dataCurta(c.period_end)}
                </Td>
                <Td>{c.attempts ?? 0}</Td>
                <Td>{dataCurta(c.paid_at)}</Td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
