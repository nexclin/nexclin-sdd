import { createClient } from "@/lib/supabase/server";
import { Cabecalho } from "../../_ui";
import { NovaContaForm } from "./nova-conta-form";

/**
 * SPEC 003 — criar a conta de uma clínica.
 *
 * # Por que a criação tem dois passos, e isso é desenho e não pendência
 *
 * Aqui nascem a clínica, a assinatura (com plano e data de cobrança) e a linha
 * do dono na equipe. **O usuário de login não nasce aqui.**
 *
 * A edge function de convite deriva a clínica do perfil de **quem chama**, e o
 * comentário dela é explícito: *"é ela que o convidado herda, nunca uma vinda
 * do body"*. Essa guarda impede que alguém convide uma pessoa para uma clínica
 * arbitrária mandando o id na requisição. Criar um caminho privilegiado que
 * aceitasse `clinic_id` de fora desmontaria exatamente essa guarda.
 *
 * Então o segundo passo é **entrar na conta** (impersonação, auditada) e
 * convidar o dono pela tela de equipe. Dois passos, nenhuma porta nova, e os
 * dois já deixam rastro.
 */
export default async function NovaContaPage() {
  const supabase = await createClient();
  const { data: planos } = await supabase
    .from("plans")
    .select("id, name, monthly_price, trial_days")
    .eq("status", "active")
    .order("monthly_price", { ascending: true });

  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Nova conta"
        subtitulo="A clínica, o plano e a data de cobrança. O login do dono é o passo seguinte, por convite."
      />
      <NovaContaForm
        planos={
          (planos ?? []) as unknown as {
            id: string;
            name: string;
            monthly_price: number | null;
            trial_days: number | null;
          }[]
        }
      />
    </div>
  );
}
