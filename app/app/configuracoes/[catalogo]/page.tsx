import Link from "next/link";
import { notFound } from "next/navigation";

import { RequirePermission } from "@/lib/auth/guards";
import { catalogoPorSlug, colunasDaLista } from "@/lib/config/catalogo";
import { lerCatalogo } from "@/lib/config/servidor";

/**
 * SPEC 005 / T010 — a rota genérica de catálogo.
 *
 * # A validação NÃO é detalhe de roteamento
 *
 * O parâmetro `[catalogo]` vem da URL, e é ele que decide **qual tabela do
 * Postgres é consultada**. Sem validação, `/app/configuracoes/patients` viraria
 * uma leitura de `patients` por uma tela de configuração.
 *
 * Por isso o slug é resolvido contra o registro em `lib/config/catalogo.ts`, e
 * desconhecido é `notFound()`. A RLS ainda protegeria o dado de outra clínica,
 * mas não protegeria o dado da própria clínica de aparecer numa tela que não é
 * a dele. Defesa em profundidade: as duas camadas, não uma.
 *
 * Um teste cobre isso, com `patients`, `profiles` e `../services` entre os
 * casos.
 */
export default async function CatalogoPage({
  params,
  searchParams,
}: {
  params: Promise<{ catalogo: string }>;
  searchParams: Promise<{ inativos?: string }>;
}) {
  const { catalogo: slug } = await params;
  const definicao = catalogoPorSlug(slug);
  if (!definicao) notFound();

  const { inativos } = await searchParams;
  const incluirInativos = inativos === "1";

  const linhas = await lerCatalogo(definicao, { incluirInativos });
  const colunas = colunasDaLista(definicao);

  return (
    <RequirePermission module="configuracoes">
      <div className="space-y-6">
        <div>
          <Link
            href="/app/configuracoes"
            className="text-sm text-[#1F8C8C] hover:underline"
          >
            Configurações
          </Link>
          <h1 className="mt-1 text-2xl font-semibold">{definicao.rotulo}</h1>
          <p className="mt-1 max-w-2xl text-sm text-[#3A4A5C]">
            {definicao.descricao}
          </p>
        </div>

        <div className="flex items-center gap-3 text-sm">
          <Link
            href={`/app/configuracoes/${definicao.slug}`}
            className={
              incluirInativos
                ? "text-[#3A4A5C] hover:underline"
                : "font-medium text-[#0E1620]"
            }
          >
            Ativos
          </Link>
          <Link
            href={`/app/configuracoes/${definicao.slug}?inativos=1`}
            className={
              incluirInativos
                ? "font-medium text-[#0E1620]"
                : "text-[#3A4A5C] hover:underline"
            }
          >
            Incluir inativos
          </Link>
        </div>

        {linhas.length === 0 ? (
          <p className="rounded-lg border border-[#3A4A5C]/15 bg-white p-5 text-sm text-[#3A4A5C]">
            Nenhum registro
            {incluirInativos ? "" : " ativo"} em {definicao.rotulo.toLowerCase()}.
            {definicao.passoDeOnboarding
              ? " Este é um dos passos da configuração inicial."
              : ""}
          </p>
        ) : (
          <div className="overflow-x-auto rounded-lg border border-[#3A4A5C]/15 bg-white">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-[#3A4A5C]/15">
                  {colunas.map((c) => (
                    <th
                      key={c.coluna}
                      className="px-3 py-2 text-left font-medium text-[#3A4A5C]"
                      title={c.ajuda}
                    >
                      {c.rotulo}
                    </th>
                  ))}
                  <th className="px-3 py-2 text-left font-medium text-[#3A4A5C]">
                    Situação
                  </th>
                </tr>
              </thead>
              <tbody>
                {linhas.map((linha) => (
                  <tr key={linha.id} className="border-t border-[#3A4A5C]/10">
                    {colunas.map((c) => (
                      <td key={c.coluna} className="px-3 py-2 align-top">
                        {formata(linha[c.coluna], c.tipo)}
                      </td>
                    ))}
                    <td className="px-3 py-2 align-top">
                      {linha.active ? "Ativo" : "Inativo"}
                      {linha.is_system ? (
                        <span
                          className="ml-2 text-xs text-[#3A4A5C]"
                          title="Registro do sistema: a clínica não edita nem remove"
                        >
                          sistema
                        </span>
                      ) : null}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <p className="text-xs text-[#3A4A5C]">
          A edição entra na próxima tarefa desta spec. Esta tela já lê do banco,
          com as colunas nomeadas e a permissão do módulo <code>configuracoes</code>.
        </p>
      </div>
    </RequirePermission>
  );
}

/**
 * Formata um valor pelo tipo declarado no registro.
 *
 * Um formatador só, para os nove catálogos. Nove cópias disto é como nascem os
 * três vocabulários de período que o `INVENTARIO-UI.md` registra na referência.
 */
function formata(valor: unknown, tipo: string): string {
  if (valor === null || valor === undefined || valor === "") return "—";
  switch (tipo) {
    case "moeda": {
      const n = Number(valor);
      return Number.isFinite(n)
        ? n.toLocaleString("pt-BR", { style: "currency", currency: "BRL" })
        : "—";
    }
    case "percentual": {
      const n = Number(valor);
      return Number.isFinite(n) ? `${n.toFixed(2)}%` : "—";
    }
    case "inteiro": {
      const n = Number(valor);
      return Number.isFinite(n) ? String(Math.round(n)) : "—";
    }
    case "booleano":
      return valor ? "Sim" : "Não";
    default:
      return String(valor);
  }
}
