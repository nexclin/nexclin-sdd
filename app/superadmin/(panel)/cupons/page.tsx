import { createClient } from "@/lib/supabase/server";
import { Cabecalho, Td, Th, Vazio, dataCurta } from "../_ui";

/**
 * SPEC 001 / T023 — Cupons.
 *
 * A coluna de usos mostra usado sobre máximo porque é o número que decide se o
 * cupom ainda vale. O enforcement desse limite é dívida registrada no BACKLOG:
 * hoje nada impede o uso além do máximo, e a tela não pode dar a entender que
 * impede.
 */
export default async function CuponsPage() {
  const supabase = await createClient();
  const { data: cupons } = await supabase
    .from("coupons")
    .select(
      "id, code, discount_type, discount_value, applies_to, duration, duration_months, max_uses, used_count, expires_at, status",
    )
    .order("created_at", { ascending: false });

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Cupons"
        subtitulo="Descontos aplicáveis na assinatura. O limite de uso ainda não é aplicado pelo banco."
      />

      {(cupons ?? []).length === 0 ? (
        <Vazio>Nenhum cupom cadastrado.</Vazio>
      ) : (
        <table className="w-full overflow-hidden rounded-lg border border-white/10 bg-slate-900 text-sm">
          <thead>
            <tr>
              <Th>Código</Th>
              <Th>Desconto</Th>
              <Th>Aplica a</Th>
              <Th>Duração</Th>
              <Th>Usos</Th>
              <Th>Expira</Th>
              <Th>Status</Th>
            </tr>
          </thead>
          <tbody>
            {(cupons ?? []).map((c) => (
              <tr key={c.id}>
                <Td>
                  <span className="font-mono">{c.code}</span>
                </Td>
                <Td>
                  {c.discount_type === "percent"
                    ? String(c.discount_value) + "%"
                    : "R$ " + String(c.discount_value)}
                </Td>
                <Td>{c.applies_to ?? "—"}</Td>
                <Td>
                  {c.duration}
                  {c.duration_months
                    ? " (" + String(c.duration_months) + " meses)"
                    : ""}
                </Td>
                <Td>
                  {c.used_count ?? 0}
                  {c.max_uses ? " de " + String(c.max_uses) : " de ilimitado"}
                </Td>
                <Td>{dataCurta(c.expires_at)}</Td>
                <Td>{c.status}</Td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
