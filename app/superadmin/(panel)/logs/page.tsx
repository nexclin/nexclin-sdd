import { createClient } from "@/lib/supabase/server";
import { Cabecalho, Td, Th, Vazio } from "../_ui";

/**
 * SPEC 001 / T023 — Logs de auditoria do superadmin.
 *
 * É a prova viva da regra (d): toda ação administrativa sobre dado de cliente
 * deixa quem, o quê, quando e o estado anterior. A tela existe para que essa
 * prova seja consultável, e não apenas gravada.
 *
 * O estado anterior e o novo aparecem crus, em JSON, dentro de um detalhe que
 * abre. Formatar um diff bonito viria ao custo de escolher quais campos
 * mostrar, e numa trilha de auditoria esconder campo é exatamente o que não
 * pode acontecer.
 */
export default async function LogsPage() {
  const supabase = await createClient();
  const { data: registros } = await supabase
    .from("superadmin_audit_log")
    .select(
      "id, action, clinic_id, previous_state, new_state, reason, ip_address, created_at, superadmin_operators(name)",
    )
    .order("created_at", { ascending: false })
    .limit(200);

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Logs"
        subtitulo="Trilha das ações de superadmin. Sem edição e sem exclusão."
      />

      {(registros ?? []).length === 0 ? (
        <Vazio>
          Nenhuma ação registrada ainda. Trilha vazia num sistema que nunca foi
          operado é o esperado; num sistema em uso, é sinal de problema.
        </Vazio>
      ) : (
        <table className="w-full overflow-hidden rounded-lg border border-white/10 bg-slate-900 text-sm">
          <thead>
            <tr>
              <Th>Quando</Th>
              <Th>Operador</Th>
              <Th>Ação</Th>
              <Th>Clínica</Th>
              <Th>Antes e depois</Th>
            </tr>
          </thead>
          <tbody>
            {(registros ?? []).map((r) => (
              <tr key={r.id}>
                <Td>
                  {new Date(r.created_at as string).toLocaleString("pt-BR")}
                </Td>
                <Td>
                  {(r.superadmin_operators as { name?: string } | null)?.name ??
                    "—"}
                </Td>
                <Td>
                  <span className="font-mono text-xs">{r.action}</span>
                </Td>
                <Td>
                  <span className="font-mono text-xs text-slate-400">
                    {String(r.clinic_id ?? "—").slice(0, 8)}
                  </span>
                </Td>
                <Td>
                  <details>
                    <summary className="cursor-pointer text-slate-400">
                      ver
                    </summary>
                    <pre className="mt-1 max-w-xl overflow-x-auto whitespace-pre-wrap text-xs text-slate-400">
                      {JSON.stringify(
                        {
                          antes: r.previous_state,
                          depois: r.new_state,
                          motivo: r.reason,
                          ip: r.ip_address,
                        },
                        null,
                        2,
                      )}
                    </pre>
                  </details>
                </Td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
