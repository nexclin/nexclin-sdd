import { createClient } from "@/lib/supabase/server";
import { MODULE_KEYS } from "@/lib/auth/modulos";
import { Cabecalho, Vazio, moeda } from "../_ui";

/**
 * SPEC 001 / T023 — Planos.
 *
 * O que a tarefa chama de "editor 15 ModuleKeys" é isto: para cada plano, quais
 * das quinze chaves estão ligadas. É a régua que define o **teto** de acesso de
 * toda clínica naquele plano, e por isso a tela mostra as quinze sempre, ligadas
 * e desligadas, em vez de listar só as ligadas. Ver uma chave faltando é o que
 * denuncia plano mal configurado, e uma lista só das ligadas esconderia isso.
 *
 * Leitura por enquanto. A escrita depende de fechar o formato de
 * `enabled_modules`: o default do MVP é array e o uso é de objeto. A decisão
 * está no BACKLOG e pertence à SPEC 004. Salvar antes de decidir gravaria os
 * dois formatos na mesma coluna.
 */
export default async function PlanosPage() {
  const supabase = await createClient();
  const { data: planos } = await supabase
    .from("plans")
    .select(
      "id, name, monthly_price, annual_price, trial_days, max_users, max_patients, max_leads_month, enabled_modules, status, visibility, is_default_trial",
    )
    .order("monthly_price", { ascending: true });

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Planos"
        subtitulo="O plano é o teto de acesso. A permissão individual distribui abaixo dele e nunca o excede."
      />

      {(planos ?? []).length === 0 && <Vazio>Nenhum plano cadastrado.</Vazio>}

      <div className="space-y-4">
        {(planos ?? []).map((p) => {
          // A coluna chega como objeto ou como array, dependendo de quando a
          // linha foi criada. Os dois formatos são lidos aqui; padronizar é
          // decisão da SPEC 004, e ler os dois evita tela em branco no meio.
          const bruto = p.enabled_modules as unknown;
          const ligado = (k: string) =>
            Array.isArray(bruto)
              ? bruto.includes(k)
              : Boolean((bruto as Record<string, unknown> | null)?.[k]);

          return (
            <section
              key={p.id}
              className="rounded-lg border border-white/10 bg-slate-900 p-5"
            >
              <div className="flex flex-wrap items-baseline justify-between gap-3">
                <h2 className="font-semibold">
                  {p.name}
                  {p.is_default_trial && (
                    <span className="ml-2 rounded bg-blue-600/20 px-2 py-0.5 text-xs text-blue-300">
                      trial padrão
                    </span>
                  )}
                </h2>
                <div className="text-sm text-slate-400">
                  {moeda(p.monthly_price)} por mês · {moeda(p.annual_price)} por
                  ano · trial de {p.trial_days ?? 0} dias
                  <span className="ml-2">
                    {p.status} · {p.visibility}
                  </span>
                </div>
              </div>

              <div className="mt-2 text-sm text-slate-400">
                Limites: {p.max_users ?? "ilimitado"} acessos ·{" "}
                {p.max_patients ?? "ilimitado"} pacientes ·{" "}
                {p.max_leads_month ?? "ilimitado"} leads por mês
              </div>

              <div className="mt-3 flex flex-wrap gap-1.5">
                {MODULE_KEYS.map((k) => (
                  <span
                    key={k}
                    className={
                      ligado(k)
                        ? "rounded border border-emerald-500/40 bg-emerald-500/10 px-2 py-0.5 text-xs text-emerald-300"
                        : "rounded border border-white/10 px-2 py-0.5 text-xs text-slate-500 line-through"
                    }
                  >
                    {k}
                  </span>
                ))}
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}
