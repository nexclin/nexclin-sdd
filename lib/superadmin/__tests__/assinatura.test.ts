/**
 * SPEC 003 — testes do núcleo da assinatura.
 *
 * Metade é calendário e metade é máquina de estados. As duas erram em silêncio
 * na produção, e o Princípio IX manda simular antes de declarar certo.
 */

import { describe, expect, it } from "vitest";

import {
  STATUS_DE_ASSINATURA,
  TRANSICOES,
  diaDaCobranca,
  diasNoMes,
  ehStatus,
  normalizaDiaDeCobranca,
  podeTransicionar,
  proximaCobranca,
} from "../assinatura";

/** Atalho para ler o resultado sem pensar em fuso. */
const iso = (d: Date) => d.toISOString().slice(0, 10);

describe("proximaCobranca: a armadilha do dia 31", () => {
  // O caminho ingênuo, `new Date(ano, mes, 31)`, TRANSBORDA para março em
  // silêncio quando o mês é fevereiro. O efeito na vida real é a fatura de
  // fevereiro sumir e duas caírem em março.

  it("dia 31 em fevereiro comum vira 28, não 3 de março", () => {
    // 2026 não é bissexto.
    const r = proximaCobranca(31, new Date(Date.UTC(2026, 1, 10)));
    expect(iso(r)).toBe("2026-02-28");
  });

  it("dia 31 em fevereiro bissexto vira 29", () => {
    const r = proximaCobranca(31, new Date(Date.UTC(2028, 1, 10)));
    expect(iso(r)).toBe("2028-02-29");
  });

  it("a prova de que o ingênuo erraria", () => {
    // Deixado explícito para quem for mexer aqui saber o que não fazer.
    const ingenuo = new Date(Date.UTC(2026, 1, 31));
    expect(iso(ingenuo)).toBe("2026-03-03");
    expect(iso(proximaCobranca(31, new Date(Date.UTC(2026, 1, 10))))).toBe("2026-02-28");
  });

  it("dia 30 em abril fica 30, e em fevereiro vira 28", () => {
    expect(iso(proximaCobranca(30, new Date(Date.UTC(2026, 3, 1))))).toBe("2026-04-30");
    expect(iso(proximaCobranca(30, new Date(Date.UTC(2026, 1, 1))))).toBe("2026-02-28");
  });
});

describe("proximaCobranca: este mês ou o próximo", () => {
  it("dia ainda não chegou: cobra neste mês", () => {
    expect(iso(proximaCobranca(20, new Date(Date.UTC(2026, 7, 5))))).toBe("2026-08-20");
  });

  it("hoje é o próprio dia: cobra hoje, não daqui a um mês", () => {
    expect(iso(proximaCobranca(20, new Date(Date.UTC(2026, 7, 20))))).toBe("2026-08-20");
  });

  it("dia já passou: cobra no mês seguinte", () => {
    // Marcar para uma data no passado criaria uma fatura nascida vencida.
    expect(iso(proximaCobranca(5, new Date(Date.UTC(2026, 7, 20))))).toBe("2026-09-05");
  });

  it("dezembro vira janeiro do ano seguinte", () => {
    expect(iso(proximaCobranca(5, new Date(Date.UTC(2026, 11, 20))))).toBe("2027-01-05");
  });

  it("dia 31 em janeiro, já passado, cai no último dia de fevereiro", () => {
    // O caso que junta as duas regras: virar de mês E grampear o dia.
    expect(iso(proximaCobranca(31, new Date(Date.UTC(2026, 0, 31))))).toBe("2026-01-31");
    expect(iso(proximaCobranca(31, new Date(Date.UTC(2027, 0, 31))))).toBe("2027-01-31");
  });

  it("nunca devolve data no passado, para nenhum dia de nenhum mês de 2026", () => {
    // Varredura, e não três exemplos escolhidos a dedo: o defeito de calendário
    // costuma aparecer numa combinação que ninguém pensou em testar.
    for (let mes = 0; mes < 12; mes++) {
      const ultimo = diasNoMes(2026, mes);
      for (let hoje = 1; hoje <= ultimo; hoje++) {
        for (let dia = 1; dia <= 31; dia++) {
          const agora = new Date(Date.UTC(2026, mes, hoje));
          const r = proximaCobranca(dia, agora);
          expect(
            r.getTime(),
            `dia ${dia} visto em ${iso(agora)} caiu em ${iso(r)}`,
          ).toBeGreaterThanOrEqual(agora.getTime());
        }
      }
    }
  });
});

describe("diasNoMes", () => {
  it("fevereiro conhece anos bissextos, inclusive a regra dos séculos", () => {
    expect(diasNoMes(2026, 1)).toBe(28);
    expect(diasNoMes(2028, 1)).toBe(29);
    expect(diasNoMes(2000, 1)).toBe(29); // divisível por 400: é bissexto
    expect(diasNoMes(1900, 1)).toBe(28); // divisível por 100 e não por 400: não é
  });

  it("os meses de 30 e de 31", () => {
    expect(diasNoMes(2026, 3)).toBe(30); // abril
    expect(diasNoMes(2026, 0)).toBe(31); // janeiro
    expect(diasNoMes(2026, 11)).toBe(31); // dezembro
  });
});

describe("normalizaDiaDeCobranca", () => {
  it("aceita 1 a 31", () => {
    expect(normalizaDiaDeCobranca("1")).toBe(1);
    expect(normalizaDiaDeCobranca(31)).toBe(31);
    expect(normalizaDiaDeCobranca("10")).toBe(10);
  });

  it("recusa fora da faixa em vez de adivinhar", () => {
    // Dia 45 é digitação errada. Corrigir para 4 ou 5 seria escolher a data de
    // cobrança de um cliente por conta própria.
    expect(normalizaDiaDeCobranca(0)).toBeNull();
    expect(normalizaDiaDeCobranca(32)).toBeNull();
    expect(normalizaDiaDeCobranca(45)).toBeNull();
    expect(normalizaDiaDeCobranca(-5)).toBeNull();
    expect(normalizaDiaDeCobranca("abc")).toBeNull();
    expect(normalizaDiaDeCobranca("")).toBeNull();
    expect(normalizaDiaDeCobranca(null)).toBeNull();
  });
});

describe("podeTransicionar: a máquina de estados", () => {
  it("cancelada não sai de lugar nenhum", () => {
    // Reativar por engano devolveria acesso a quem pediu para sair.
    for (const destino of STATUS_DE_ASSINATURA) {
      if (destino === "cancelled") continue;
      expect(podeTransicionar("cancelled", destino), destino).toBe(false);
    }
  });

  it("trial não vai direto para suspensa", () => {
    // Suspender é punição por não pagamento, e quem está em teste nada devia.
    expect(podeTransicionar("trial", "suspended")).toBe(false);
    expect(podeTransicionar("trial", "active")).toBe(true);
    expect(podeTransicionar("trial", "overdue")).toBe(true);
    expect(podeTransicionar("trial", "cancelled")).toBe(true);
  });

  it("suspensa volta a ativa, que é o caminho de quem pagou o atraso", () => {
    expect(podeTransicionar("suspended", "active")).toBe(true);
  });

  it("ficar no mesmo status é sempre permitido", () => {
    // Senão, editar a data de cobrança exigiria mudar o estado da conta junto.
    for (const s of STATUS_DE_ASSINATURA) {
      expect(podeTransicionar(s, s), s).toBe(true);
    }
  });

  it("toda transição declarada aponta para um status que existe", () => {
    for (const [de, destinos] of Object.entries(TRANSICOES)) {
      for (const para of destinos) {
        expect(ehStatus(para), `${de} -> ${para}`).toBe(true);
      }
    }
  });

  it("todo status conhecido está na tabela de transições", () => {
    // Status novo no enum sem entrada aqui seria um estado de onde nada sai,
    // e isso trancaria a conta em silêncio.
    for (const s of STATUS_DE_ASSINATURA) {
      expect(TRANSICOES[s], s).toBeDefined();
    }
  });
});

describe("ehStatus e diaDaCobranca", () => {
  it("ehStatus recusa o que não é status", () => {
    expect(ehStatus("active")).toBe(true);
    expect(ehStatus("ativo")).toBe(false);
    expect(ehStatus("")).toBe(false);
    expect(ehStatus(null)).toBe(false);
    expect(ehStatus(3)).toBe(false);
  });

  it("diaDaCobranca lê o dia de uma data gravada", () => {
    expect(diaDaCobranca("2026-08-20T00:00:00.000Z")).toBe(20);
    expect(diaDaCobranca(null)).toBeNull();
    expect(diaDaCobranca("")).toBeNull();
    expect(diaDaCobranca("nao e data")).toBeNull();
  });
});
