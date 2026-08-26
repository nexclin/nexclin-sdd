import { createClient } from "@/lib/supabase/server";
import { MODULE_KEYS } from "@/lib/auth/modulos";
import { Cabecalho, Vazio, moeda } from "../_ui";
import { PlanoForm, type PlanoEditavel } from "./plano-form";

/**
 * SPEC 001 / T023 — Planos.
 *
 * O que a tarefa chama de "editor 15 ModuleKeys" é isto: para cada plano, quais
 * das quinze chaves estão ligadas. É a régua que define o **teto** de acesso de
 * toda clínica naquele plano, e por isso a tela mostra as quinze sempre, ligadas
 * e desligadas, em vez de listar só as ligadas. Ver uma chave faltando é o que
 * denuncia plano mal configurado, e uma lista só das ligadas esconderia isso.
 *
 * # A escrita entrou em 26/08, e o que a destravou
 *
 * Aqui estava escrito "leitura por enquanto", porque salvar dependia de fechar
 * o formato de `enabled_modules`: o default do MVP é array e o uso é de objeto,
 * e gravar antes de decidir poria os dois formatos na mesma coluna.
 *
 * **A decisão saiu em 25/08**, na migração
 * `20260825070000_corrige_default_de_enabled_modules.sql`: é objeto, o default
 * foi alinhado e uma constraint impede que volte a ser array. Sem ambiguidade,
 * gravar deixou de ser arriscado, e o editor entrou.
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

      <div className="rounded-lg border border-white/10 bg-slate-900 p-4">
        <p className="mb-2 text-sm text-slate-400">
          Criar um plano novo, com mensalidade e módulos.
        </p>
        <PlanoForm />
      </div>

      {(planos ?? []).length === 0 && <Vazio>Nenhum plano cadastrado.</Vazio>}

      <div className="space-y-4">
        {(planos ?? []).map((p) => {
          // A coluna chega como objeto ou como array, dependendo de quando a
          // linha foi criada. A migração de 25/08 padronizou o default e
          // normalizou as linhas existentes, e a leitura dos dois formatos fica
          // como rede: linha gravada antes dela ainda pode estar em array.
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

              <div className="mt-4 border-t border-white/10 pt-3">
                <PlanoForm plano={p as unknown as PlanoEditavel} />
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}
