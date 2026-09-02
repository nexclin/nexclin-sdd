/**
 * Regra 005 / FR-016: testes da decisão de mostrar a apresentação inicial.
 *
 * Um teste que foi retirado, e por quê: havia aqui um bloco que passava ruído
 * de progresso (`isComplete`, passos concluídos) para a função e exigia que a
 * resposta não mudasse, alegando travar o defeito de 28/08. A revisão de código
 * derrubou: quem garante isso é a assinatura, que só aceita o carimbo. O teste
 * pegava apenas a reintrodução pelo mesmo objeto, e deixava passar as duas
 * prováveis, um segundo parâmetro ou o chamador escrevendo
 * `deveMostrar(p) && !isComplete`. Teste que dá segurança falsa é pior que
 * teste que não existe.
 */

import { describe, expect, it } from "vitest";
import { deveMostrarApresentacao, marcaDeApresentacao } from "../apresentacao";

describe("deve mostrar a apresentação inicial?", () => {
  it("mostra para quem nunca viu", () => {
    expect(deveMostrarApresentacao({ onboarding_tour_seen_at: null })).toBe(true);
    expect(deveMostrarApresentacao({})).toBe(true);
  });

  it("não mostra para quem já viu", () => {
    expect(
      deveMostrarApresentacao({ onboarding_tour_seen_at: "2026-08-28T12:00:00Z" }),
    ).toBe(false);
  });

  // Perfil ainda não carregado não é o mesmo que "nunca viu". Tratar
  // `undefined` como "nunca viu" faria a apresentação piscar em toda navegação
  // enquanto o dado não chega.
  it("não mostra enquanto o perfil não chegou", () => {
    expect(deveMostrarApresentacao(null)).toBe(false);
    expect(deveMostrarApresentacao(undefined)).toBe(false);
  });

  // Entre mostrar de novo para quem já viu e não mostrar para quem não viu, foi
  // o segundo que trancou a conta mestra. Carimbo ilegível vale como visto.
  it("trata carimbo ilegível como já visto", () => {
    expect(deveMostrarApresentacao({ onboarding_tour_seen_at: "nao é data" })).toBe(
      false,
    );
  });

  it("string vazia é ausência de carimbo, então mostra", () => {
    expect(deveMostrarApresentacao({ onboarding_tour_seen_at: "" })).toBe(true);
    expect(deveMostrarApresentacao({ onboarding_tour_seen_at: "   " })).toBe(true);
  });
});

describe("a marca gravada", () => {
  it("é um carimbo ISO, e não um booleano", () => {
    const m = marcaDeApresentacao(new Date("2026-08-28T15:30:00Z"));
    expect(m.onboarding_tour_seen_at).toBe("2026-08-28T15:30:00.000Z");
  });

  it("marcar e reler produz uma decisão de não mostrar", () => {
    const perfil = marcaDeApresentacao(new Date("2026-08-28T15:30:00Z"));
    expect(deveMostrarApresentacao(perfil)).toBe(false);
  });
});
