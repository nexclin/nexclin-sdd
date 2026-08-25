import { createClient } from "@/lib/supabase/server";
import { Cabecalho, Td, Th, Vazio, dataCurta } from "../_ui";

/**
 * SPEC 001 / T023 — Operadores do SaaS.
 *
 * `superadmin_operators` é a identidade de nível SaaS, que vive fora de
 * qualquer clínica. A tela é de leitura de propósito: criar um operador é o ato
 * que dá acesso irrestrito a dado de saúde de **todos** os clientes, e isso não
 * deve ser um botão numa tela enquanto não tiver spec própria. Fica registrado
 * aqui em vez de virar dívida esquecida.
 *
 * A marca de "nunca logou" existe porque ela é a pendência T012 aparecendo: o
 * superadmin da stack nova ainda não entrou uma vez sequer.
 */
export default async function OperadoresPage() {
  const supabase = await createClient();
  const { data: operadores } = await supabase
    .from("superadmin_operators")
    .select("id, name, email, role, active, last_login_at, last_login_ip, created_at")
    .order("created_at", { ascending: true });

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Operadores"
        subtitulo="Identidades de nível SaaS. Leitura apenas."
      />

      {(operadores ?? []).length === 0 ? (
        <Vazio>Nenhum operador cadastrado. O seed da Fase 2 cria o primeiro.</Vazio>
      ) : (
        <table className="w-full overflow-hidden rounded-lg border border-white/10 bg-slate-900 text-sm">
          <thead>
            <tr>
              <Th>Nome</Th>
              <Th>E-mail</Th>
              <Th>Papel</Th>
              <Th>Ativo</Th>
              <Th>Último acesso</Th>
            </tr>
          </thead>
          <tbody>
            {(operadores ?? []).map((o) => (
              <tr key={o.id}>
                <Td>{o.name}</Td>
                <Td>{o.email}</Td>
                <Td>{String(o.role)}</Td>
                <Td>{o.active ? "sim" : "não"}</Td>
                <Td>
                  {dataCurta(o.last_login_at)}
                  {!o.last_login_at && (
                    <span className="ml-1 text-xs text-amber-400">
                      nunca logou
                    </span>
                  )}
                </Td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <p className="text-xs text-slate-500">
        Criar ou desativar operador exige spec própria. Um operador enxerga dado
        de saúde de todas as clínicas, e a criação precisa ser ato deliberado,
        não clique.
      </p>
    </div>
  );
}
