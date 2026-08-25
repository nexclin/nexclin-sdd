import { Cabecalho } from "../_ui";

/**
 * SPEC 001 / T023 — Comunicação.
 *
 * A referência tem esta tela como **stub**, e o BACKLOG a registra assim, em
 * letras claras: "Comunicação do superadmin (stub)". Portar um stub como se
 * fosse funcionalidade seria mentir no inventário, e o inventário é o que
 * decide o que ainda falta.
 *
 * Então a tela existe, é navegável, e diz o que falta. É a alternativa honesta
 * a um formulário que não envia nada.
 */
export default function ComunicacaoPage() {
  return (
    <div className="space-y-6">
      <Cabecalho
        titulo="Comunicação"
        subtitulo="Envio de mensagem para as contas. Ainda não implementado."
      />

      <section className="rounded-lg border border-amber-500/30 bg-amber-500/5 p-5 text-sm">
        <h2 className="font-medium text-amber-300">Por que esta tela está vazia</h2>
        <p className="mt-2 text-slate-300">
          Na referência do MVP esta funcionalidade é um stub: a tela existe, o
          envio não. Ela foi portada como aviso, e não como formulário, porque
          formulário que não envia é pior que tela vazia. Quem clica em enviar
          acredita que enviou.
        </p>
        <p className="mt-2 text-slate-300">
          O que falta, na ordem: integrar o Resend, já que o SMTP embutido não
          entrega e isso foi comprovado em teste; definir os modelos de mensagem;
          e decidir o registro de envio, que é dado de contato com cliente e
          precisa de trilha própria.
        </p>
      </section>
    </div>
  );
}
