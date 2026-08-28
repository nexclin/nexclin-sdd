/**
 * A apresentação inicial: quem já viu, e quem ainda deve ver.
 *
 * Regra 005, FR-015 e FR-016. Nasce de um defeito que trancou a conta mestra
 * fora do sistema em 28/08/2026, e o que importa aqui é a lição, não a coluna.
 *
 * **O defeito era de lógica, não de armazenamento.** Na plataforma Lovable a
 * apresentação decidia aparecer consultando `isComplete`, derivado de doze
 * contagens no banco. Sem formulário de anamnese cadastrado a clínica ficava
 * incompleta para sempre, a apresentação renascia a cada carga de página, e um
 * efeito devolvia qualquer rota para a do passo corrente. A navegação foi
 * sequestrada, e nenhum dos dois botões de saída funcionava.
 *
 * **A regra que sai daí:** a decisão de mostrar a apresentação MUST NOT
 * consultar o progresso da configuração. São duas perguntas, "já viu?" e "já
 * configurou?", e juntá-las foi o defeito inteiro.
 *
 * **O que garante isso aqui é a ASSINATURA, não um teste.** `deveMostrar` só
 * recebe o carimbo do usuário, então não tem como olhar o progresso. Um teste
 * que passe ruído de progresso e verifique que a resposta não muda seria quase
 * teatro: ele só pega a reintrodução pelo mesmo objeto, e deixa passar as duas
 * prováveis, um segundo parâmetro na função ou o chamador escrevendo
 * `deveMostrar(...) && !isComplete`. Contra essas, o que protege é a revisão de
 * quem mexer aqui, e este comentário.
 *
 * O armazenamento é `profiles.onboarding_tour_seen_at` (`20260828020000`).
 */

/** O pedaço do perfil que interessa a esta decisão. */
export interface PerfilComApresentacao {
  /** Carimbo ISO vindo do banco. `null` é quem nunca viu. */
  onboarding_tour_seen_at?: string | null;
}

/**
 * Deve mostrar a apresentação inicial a este usuário?
 *
 * Repare no que a função não recebe: nada sobre catálogos, metas, anamnese ou
 * passos concluídos. Se alguém precisar passar isso aqui, o defeito de 28/08
 * está voltando, e a resposta certa é recusar o parâmetro.
 */
export function deveMostrarApresentacao(
  perfil: PerfilComApresentacao | null | undefined,
): boolean {
  // Perfil ainda não carregado não é "nunca viu". Tratar os dois como iguais
  // faria a apresentação piscar em toda navegação enquanto o dado não chega.
  if (!perfil) return false;

  const carimbo = perfil.onboarding_tour_seen_at;
  if (carimbo === null || carimbo === undefined) return true;
  // Espaço em branco é ausência de carimbo, não presença de um ilegível.
  if (carimbo.trim() === "") return true;

  // Qualquer carimbo preenchido conta como "já viu", inclusive um que não
  // pareça data. Entre mostrar de novo para quem já viu e não mostrar para
  // quem não viu, foi o segundo que trancou a conta mestra.
  return false;
}

/**
 * A marca a gravar quando a pessoa dispensa ou termina a apresentação.
 *
 * Recebe a data em vez de chamar `new Date()` por dentro, para que o teste
 * possa fixá-la e para que o chamador decida o instante.
 */
export function marcaDeApresentacao(quando: Date): { onboarding_tour_seen_at: string } {
  return { onboarding_tour_seen_at: quando.toISOString() };
}
