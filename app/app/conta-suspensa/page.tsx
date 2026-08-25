/**
 * SPEC 001 / T020 — destino de quem tem assinatura suspensa ou cancelada.
 *
 * Existe porque negar sem explicar é pior que negar. A cascata do banco já
 * devolveria `none` para todo módulo dessa conta, e o usuário cairia num app
 * sem nenhum menu, sem entender por quê. Aqui ele lê o motivo e sabe a quem
 * recorrer.
 *
 * A tela **não** consulta nem exibe dado da clínica: quem chega nela está
 * bloqueado, e bloqueado não lê dado.
 */
export default function ContaSuspensaPage() {
  return (
    <div className="max-w-lg space-y-3">
      <h1 className="text-2xl font-semibold">Conta suspensa</h1>
      <p className="text-sm text-[#3A4A5C]">
        O acesso a esta clínica está suspenso. Os dados continuam guardados e
        nada foi apagado.
      </p>
      <p className="text-sm text-[#3A4A5C]">
        Para reativar, fale com o suporte do NexClin. A reativação é feita pela
        nossa equipe e leva efeito assim que confirmada.
      </p>
    </div>
  );
}
