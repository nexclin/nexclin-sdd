import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { MODULE_KEYS } from "@/lib/auth/modulos";
import { Cabecalho, Td, Th, Vazio, dataCurta, moeda } from "../../_ui";
import { AcoesDePerfil } from "./acoes-de-perfil";

/**
 * SPEC 001 / T023 e T024 — detalhe da conta.
 *
 * Reúne numa tela o que o suporte precisa para atender uma clínica: a
 * assinatura e o plano, quem tem acesso, o consumo de assentos, a linha do
 * tempo da conta, e as ações sobre perfis.
 *
 * O contador de assentos aparece aqui porque é a divergência D4 do
 * INVENTARIO-UI: o limite existe no banco, com trigger, e não aparecia em lugar
 * nenhum da tela. Limite invisível vira reclamação de suporte quando o admin
 * tenta convidar mais uma pessoa e não entende a recusa.
 */
export default async function DetalheDaContaPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: clinica } = await supabase
    .from("clinics")
    .select("id, name, created_at")
    .eq("id", id)
    .maybeSingle();

  if (!clinica) notFound();

  const [{ data: assinatura }, { data: membros }, { data: perfis }, { data: linhaDoTempo }] =
    await Promise.all([
      supabase
        .from("account_subscriptions")
        .select(
          "status, trial_start, trial_end, started_at, current_period_end, cancelled_at, cancel_reason, plans(id, name, monthly_price, max_users, enabled_modules)",
        )
        .eq("clinic_id", id)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle(),
      supabase
        .from("team_members")
        .select("id, name, role, permission_level, active, invite_status, user_id")
        .eq("clinic_id", id)
        .order("created_at", { ascending: true }),
      supabase
        .from("profiles")
        .select("user_id, full_name, phone")
        .eq("clinic_id", id),
      supabase
        .from("account_timeline")
        .select("id, event_type, description, created_at")
        .eq("clinic_id", id)
        .order("created_at", { ascending: false })
        .limit(30),
    ]);

  const plano = assinatura?.plans as
    | {
        id: string;
        name: string;
        monthly_price: number;
        max_users: number | null;
        enabled_modules: unknown;
      }
    | null
    | undefined;

  const ativos = (membros ?? []).filter((m) => m.active).length;
  const teto = plano?.max_users ?? null;

  const moduloLigado = (k: string) => {
    const bruto = plano?.enabled_modules as unknown;
    return Array.isArray(bruto)
      ? bruto.includes(k)
      : Boolean((bruto as Record<string, unknown> | null)?.[k]);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <Cabecalho
          titulo={clinica.name}
          subtitulo={"Conta criada em " + dataCurta(clinica.created_at)}
        />
        <Link
          href="/superadmin/contas"
          className="shrink-0 rounded-md border border-white/15 px-3 py-1.5 text-sm hover:bg-white/5"
        >
          Voltar
        </Link>
      </div>

      <section className="rounded-lg border border-white/10 bg-slate-900 p-5">
        <h2 className="mb-3 text-sm font-medium text-slate-300">Assinatura</h2>
        {!assinatura ? (
          <Vazio>Esta conta não tem assinatura registrada.</Vazio>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2">
            <dl className="space-y-1 text-sm">
              <Linha rotulo="Status" valor={String(assinatura.status)} />
              <Linha rotulo="Plano" valor={plano?.name ?? "—"} />
              <Linha rotulo="Mensalidade" valor={moeda(plano?.monthly_price)} />
              <Linha rotulo="Trial até" valor={dataCurta(assinatura.trial_end)} />
              <Linha
                rotulo="Período atual até"
                valor={dataCurta(assinatura.current_period_end)}
              />
              {assinatura.cancelled_at && (
                <Linha
                  rotulo="Cancelada em"
                  valor={
                    dataCurta(assinatura.cancelled_at) +
                    (assinatura.cancel_reason
                      ? " · " + String(assinatura.cancel_reason)
                      : "")
                  }
                />
              )}
            </dl>

            <div>
              <div className="text-sm text-slate-400">Acessos</div>
              <div className="mt-1 text-2xl font-semibold">
                {ativos} de {teto ?? "ilimitado"}
              </div>
              {teto !== null && ativos >= teto && (
                <p className="mt-1 text-xs text-amber-400">
                  Assentos esgotados. Um convite novo é barrado pelo trigger do
                  banco, e a tela precisa dizer isso antes da tentativa.
                </p>
              )}
            </div>
          </div>
        )}
      </section>

      {plano && (
        <section className="rounded-lg border border-white/10 bg-slate-900 p-5">
          <h2 className="mb-3 text-sm font-medium text-slate-300">
            Teto do plano
          </h2>
          <div className="flex flex-wrap gap-1.5">
            {MODULE_KEYS.map((k) => (
              <span
                key={k}
                className={
                  moduloLigado(k)
                    ? "rounded border border-emerald-500/40 bg-emerald-500/10 px-2 py-0.5 text-xs text-emerald-300"
                    : "rounded border border-white/10 px-2 py-0.5 text-xs text-slate-500 line-through"
                }
              >
                {k}
              </span>
            ))}
          </div>
          <p className="mt-2 text-xs text-slate-500">
            Nenhuma permissão individual desta clínica pode ultrapassar o que
            está aceso aqui.
          </p>
        </section>
      )}

      <section className="rounded-lg border border-white/10 bg-slate-900 p-5">
        <h2 className="mb-3 text-sm font-medium text-slate-300">
          Perfis e acessos
        </h2>
        {(membros ?? []).length === 0 ? (
          <Vazio>Nenhum membro cadastrado nesta clínica.</Vazio>
        ) : (
          <div className="space-y-5">
            {(membros ?? []).map((m) => {
              const perfil = (perfis ?? []).find((p) => p.user_id === m.user_id);
              return (
                <div
                  key={m.id}
                  className="rounded-md border border-white/10 p-4"
                >
                  <div className="flex flex-wrap items-baseline justify-between gap-2">
                    <div>
                      <span className="font-medium">{m.name}</span>
                      <span className="ml-2 text-xs text-slate-400">
                        {m.role} · {m.permission_level} ·{" "}
                        {m.active ? "ativo" : "inativo"}
                        {m.invite_status ? " · " + String(m.invite_status) : ""}
                      </span>
                    </div>
                    <span className="text-xs text-slate-500">
                      {perfil?.full_name || "sem nome no perfil"}
                      {perfil?.phone ? " · " + perfil.phone : ""}
                    </span>
                  </div>

                  {m.user_id ? (
                    <div className="mt-3">
                      <AcoesDePerfil userId={String(m.user_id)} />
                    </div>
                  ) : (
                    <p className="mt-2 text-xs text-amber-400">
                      Este membro não tem acesso vinculado. É o caso V-04B: a
                      linha do membro ficou quando a criação do acesso falhou.
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </section>

      <section className="rounded-lg border border-white/10 bg-slate-900 p-5">
        <h2 className="mb-3 text-sm font-medium text-slate-300">
          Linha do tempo da conta
        </h2>
        {(linhaDoTempo ?? []).length === 0 ? (
          <Vazio>Nenhum evento registrado.</Vazio>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr>
                <Th>Quando</Th>
                <Th>Evento</Th>
                <Th>Descrição</Th>
              </tr>
            </thead>
            <tbody>
              {(linhaDoTempo ?? []).map((e) => (
                <tr key={e.id}>
                  <Td>{dataCurta(e.created_at)}</Td>
                  <Td>
                    <span className="font-mono text-xs">{e.event_type}</span>
                  </Td>
                  <Td>{e.description ?? "—"}</Td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}

function Linha({ rotulo, valor }: { rotulo: string; valor: string }) {
  return (
    <div className="flex justify-between gap-4">
      <dt className="text-slate-400">{rotulo}</dt>
      <dd>{valor}</dd>
    </div>
  );
}
