import Link from "next/link";

import { RequirePermission } from "@/lib/auth/guards";
import { createClient } from "@/lib/supabase/server";
import { emOrdemDeLeitura, montaArvore, type ContaCrua } from "@/lib/config/arvore";
import { PlanoDeContasForm } from "./plano-de-contas-form";

/**
 * SPEC 005 / T012 — o plano de contas.
 *
 * O único catálogo em árvore, e por isso o único fora do registro declarativo.
 * Forçá-lo lá dentro exigiria uma exceção, e abstração que ganha exceção deixa
 * de valer a pena.
 *
 * A tela mostra a **profundidade derivada dos pais**, e não a coluna `level`.
 * São duas fontes para a mesma verdade, e a coluna é a que sai do lugar quando
 * alguém move uma conta. Aqui a estrutura manda.
 */
export default async function PlanoDeContasPage({
  searchParams,
}: {
  searchParams: Promise<{ inativos?: string }>;
}) {
  const { inativos } = await searchParams;
  const incluirInativos = inativos === "1";

  const supabase = await createClient();
  let q = supabase
    .from("chart_of_accounts")
    .select("id, code, name, parent_id, level, active, is_system");
  if (!incluirInativos) q = q.eq("active", true);

  const { data } = await q;
  const contas = (data ?? []) as unknown as ContaCrua[];
  const plano = emOrdemDeLeitura(montaArvore(contas));

  const divergentes = plano.filter(
    (n) => typeof n.level === "number" && n.level !== n.profundidade + 1,
  );

  return (
    <RequirePermission module="configuracoes">
      <div className="space-y-6">
        <div>
          <Link href="/app/configuracoes" className="text-sm text-[#1F8C8C] hover:underline">
            Configurações
          </Link>
          <h1 className="mt-1 text-2xl font-semibold">Plano de contas</h1>
          <p className="mt-1 max-w-2xl text-sm text-[#3A4A5C]">
            A estrutura contábil da clínica. É por ela que despesa e receita são
            agrupadas no fluxo de caixa e nos relatórios.
          </p>
          <p className="mt-2 max-w-2xl text-xs text-[#3A4A5C]/80">
            <span className="font-medium">Usado em:</span> Contas a pagar, Contas
            a receber, Fluxo de caixa
          </p>
        </div>

        <div className="flex items-center gap-3 text-sm">
          <Link
            href="/app/configuracoes/plano-de-contas"
            className={incluirInativos ? "text-[#3A4A5C] hover:underline" : "font-medium"}
          >
            Ativas
          </Link>
          <Link
            href="/app/configuracoes/plano-de-contas?inativos=1"
            className={incluirInativos ? "font-medium" : "text-[#3A4A5C] hover:underline"}
          >
            Incluir inativas
          </Link>
        </div>

        {divergentes.length > 0 && (
          <p className="rounded border border-amber-300 bg-amber-50 px-3 py-2 text-xs text-amber-800">
            {divergentes.length} conta(s) têm a coluna <code>level</code> diferente
            da posição real na árvore. A tela mostra a posição real. O valor
            gravado se acerta sozinho no próximo salvamento de cada uma.
          </p>
        )}

        {plano.length === 0 ? (
          <p className="rounded-lg border border-[#3A4A5C]/15 bg-white p-5 text-sm text-[#3A4A5C]">
            Nenhuma conta {incluirInativos ? "" : "ativa "}cadastrada.
          </p>
        ) : (
          <ul className="divide-y divide-[#3A4A5C]/10 rounded-lg border border-[#3A4A5C]/15 bg-white">
            {plano.map((n) => (
              <li key={n.id} className="flex items-baseline gap-3 px-4 py-2 text-sm">
                <span
                  className="shrink-0 tabular-nums text-[#3A4A5C]"
                  style={{ paddingLeft: `${n.profundidade * 1.25}rem` }}
                >
                  {n.code}
                </span>
                <span className={n.profundidade === 0 ? "font-medium" : undefined}>
                  {n.name}
                </span>
                {!n.active && <span className="text-xs text-[#3A4A5C]/70">inativa</span>}
                {n.is_system && (
                  <span
                    className="text-xs text-[#3A4A5C]/70"
                    title="Registro do sistema: a clínica não edita"
                  >
                    sistema
                  </span>
                )}
              </li>
            ))}
          </ul>
        )}

        <PlanoDeContasForm contas={contas} />
      </div>
    </RequirePermission>
  );
}
