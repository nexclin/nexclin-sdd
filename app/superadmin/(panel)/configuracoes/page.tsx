import { createClient } from "@/lib/supabase/server";
import { Cabecalho, Vazio } from "../_ui";

/**
 * SPEC 001 / T023 — Configurações do SaaS.
 *
 * `saas_settings` é singleton. Os parâmetros de inadimplência já estão
 * gravados, mas **nada os executa**: a régua de e-mail, suspensão e
 * cancelamento é automação que está no BACKLOG. A tela diz isso na cara, com
 * destaque, para que ninguém confie num prazo que não roda.
 *
 * Foi uma decisão registrada do projeto: trial vencido não suspende sozinho, e
 * a suspensão é ato manual do superadmin.
 */
export default async function ConfiguracoesSaasPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("saas_settings")
    .select(
      "trial_default_days, trial_default_plan_id, trial_requires_card, trial_max_extension_days, overdue_email_days, overdue_suspend_days, overdue_cancel_days, overdue_max_retries, support_email, terms_url, privacy_url",
    )
    .limit(1)
    .maybeSingle();

  if (!data) {
    return (
      <div className="space-y-6">
        <Cabecalho titulo="Configurações" subtitulo="Parâmetros globais do SaaS." />
        <Vazio>
          Nenhuma configuração encontrada. O seed da Fase 2 cria a linha única.
        </Vazio>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Configurações"
        subtitulo="Parâmetros globais do SaaS. Leitura apenas."
      />

      <Bloco titulo="Trial">
        <Linha rotulo="Dias padrão" valor={String(data.trial_default_days ?? "—")} />
        <Linha rotulo="Exige cartão" valor={data.trial_requires_card ? "sim" : "não"} />
        <Linha
          rotulo="Extensão máxima"
          valor={String(data.trial_max_extension_days ?? 0) + " dias"}
        />
      </Bloco>

      <Bloco titulo="Inadimplência">
        <Linha
          rotulo="E-mails em D+"
          valor={JSON.stringify(data.overdue_email_days ?? [])}
        />
        <Linha rotulo="Suspende em D+" valor={String(data.overdue_suspend_days ?? "—")} />
        <Linha rotulo="Cancela em D+" valor={String(data.overdue_cancel_days ?? "—")} />
        <Linha rotulo="Tentativas" valor={String(data.overdue_max_retries ?? "—")} />
        <p className="pt-2 text-xs text-amber-400">
          Estes prazos estão gravados, e nenhuma rotina os executa. Trial vencido
          não suspende sozinho: a suspensão é ato manual do superadmin.
        </p>
      </Bloco>

      <Bloco titulo="Contato e termos">
        <Linha rotulo="Suporte" valor={data.support_email ?? "—"} />
        <Linha rotulo="Termos" valor={data.terms_url ?? "—"} />
        <Linha rotulo="Privacidade" valor={data.privacy_url ?? "—"} />
      </Bloco>
    </div>
  );
}

function Bloco({
  titulo,
  children,
}: {
  titulo: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-lg border border-white/10 bg-slate-900 p-5">
      <h2 className="mb-3 text-sm font-medium text-slate-300">{titulo}</h2>
      <dl className="space-y-1 text-sm">{children}</dl>
    </section>
  );
}

function Linha({ rotulo, valor }: { rotulo: string; valor: string }) {
  return (
    <div className="flex justify-between gap-4">
      <dt className="text-slate-400">{rotulo}</dt>
      <dd className="font-mono text-xs">{valor}</dd>
    </div>
  );
}
