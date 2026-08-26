/**
 * SPEC 005 / T014 — testes de dias úteis e meta diária.
 *
 * A Páscoa é o coração disto: quatro dos onze feriados nacionais dependem dela,
 * e errar por um dia joga Carnaval e Corpus Christi para o mês errado. O
 * algoritmo não é legível, então o que se pode fazer é **conferir contra datas
 * reais**, e é o que está aqui.
 */

import { describe, expect, it } from "vitest";

import {
  diasUteisDoMes,
  domingoDePascoa,
  feriadosNacionais,
  porDiaUtil,
  ritmoEsperado,
} from "../metas";

const iso = (d: Date) => d.toISOString().slice(0, 10);

describe("domingoDePascoa, conferido contra datas reais", () => {
  const conhecidas: Array<[number, string]> = [
    [2024, "2024-03-31"],
    [2025, "2025-04-20"],
    [2026, "2026-04-05"],
    [2027, "2027-03-28"],
    [2028, "2028-04-16"],
    [2030, "2030-04-21"],
    [2038, "2038-04-25"], // o extremo tardio possível
    [1981, "1981-04-19"],
  ];

  for (const [ano, esperado] of conhecidas) {
    it(`${ano} cai em ${esperado}`, () => {
      expect(iso(domingoDePascoa(ano))).toBe(esperado);
    });
  }

  it("cai sempre entre 22 de março e 25 de abril, em 200 anos", () => {
    // A garantia estrutural do algoritmo. Se ele sair desta janela em algum
    // ano, está errado, e um teste de datas conhecidas sozinho não pegaria.
    for (let ano = 1900; ano < 2100; ano++) {
      const d = domingoDePascoa(ano);
      const dia = iso(d).slice(5);
      expect(dia >= "03-22" && dia <= "04-25", `${ano} caiu em ${iso(d)}`).toBe(true);
      expect(d.getUTCDay(), `${ano} não caiu num domingo`).toBe(0);
    }
  });
});

describe("feriadosNacionais", () => {
  it("2026 tem os móveis nas datas certas", () => {
    const f = feriadosNacionais(2026);
    // Páscoa 05/04/2026.
    expect(f.has("2026-02-16")).toBe(true); // Carnaval, segunda
    expect(f.has("2026-02-17")).toBe(true); // Carnaval, terça
    expect(f.has("2026-04-03")).toBe(true); // Sexta-Feira Santa
    expect(f.has("2026-06-04")).toBe(true); // Corpus Christi
  });

  it("tem os fixos, inclusive a Consciência Negra", () => {
    const f = feriadosNacionais(2026);
    for (const d of [
      "2026-01-01", "2026-04-21", "2026-05-01", "2026-09-07",
      "2026-10-12", "2026-11-02", "2026-11-15", "2026-11-20", "2026-12-25",
    ]) {
      expect(f.has(d), d).toBe(true);
    }
  });

  it("não inclui dia comum", () => {
    const f = feriadosNacionais(2026);
    expect(f.has("2026-03-10")).toBe(false);
    expect(f.has("2026-08-15")).toBe(false);
  });
});

describe("diasUteisDoMes", () => {
  const inicio = new Date(Date.UTC(2026, 7, 1));

  it("agosto de 2026 tem 21 dias úteis sem sábado", () => {
    // Agosto de 2026 tem 31 dias, começa num sábado, e não tem feriado
    // nacional. 21 dias úteis é o número que qualquer calendário confirma.
    const r = diasUteisDoMes(2026, 7, inicio, false);
    expect(r.uteis).toBe(21);
    expect(r.feriadosNoMes).toEqual([]);
  });

  it("o sábado entra quando a clínica atende no sábado", () => {
    const sem = diasUteisDoMes(2026, 7, inicio, false);
    const com = diasUteisDoMes(2026, 7, inicio, true);
    expect(com.uteis).toBeGreaterThan(sem.uteis);
    expect(com.uteis - sem.uteis).toBe(5); // agosto de 2026 tem 5 sábados
  });

  it("fevereiro de 2026 desconta os dois dias de Carnaval", () => {
    const semFeriado = 20; // fevereiro de 2026 tem 20 dias de semana
    const r = diasUteisDoMes(2026, 1, new Date(Date.UTC(2026, 1, 1)), false);
    expect(r.uteis).toBe(semFeriado - 2);
    expect(r.feriadosNoMes).toEqual(["2026-02-16", "2026-02-17"]);
  });

  it("feriado que cai no fim de semana não desconta duas vezes", () => {
    // 2026-11-15 é domingo. Ele já não era dia útil, e não pode ser subtraído
    // de novo, senão novembro perderia um dia que nunca teve.
    const r = diasUteisDoMes(2026, 10, new Date(Date.UTC(2026, 10, 1)), false);
    expect(r.feriadosNoMes).not.toContain("2026-11-15");
    // 02, 20 e 25 de novembro de 2026 caem em dia de semana.
    expect(r.feriadosNoMes).toContain("2026-11-02");
    expect(r.feriadosNoMes).toContain("2026-11-20");
  });

  it("hoje conta como restante", () => {
    // Tirar o dia corrente faria a meta diária subir toda manhã.
    const r = diasUteisDoMes(2026, 7, new Date(Date.UTC(2026, 7, 3)), false);
    expect(r.restantes).toBe(r.uteis); // 3/08/2026 é a primeira segunda
    expect(r.decorridos).toBe(0);
  });

  it("no fim do mês restam zero e decorridos é o total", () => {
    const r = diasUteisDoMes(2026, 7, new Date(Date.UTC(2026, 8, 1)), false);
    expect(r.restantes).toBe(0);
    expect(r.decorridos).toBe(r.uteis);
  });

  it("hora do dia não muda a conta", () => {
    // A comparação é por dia. Comparar instantes diria que hoje já passou às
    // 00:01, e a clínica perderia um dia útil toda madrugada.
    const cedo = diasUteisDoMes(2026, 7, new Date(Date.UTC(2026, 7, 10, 0, 1)), false);
    const tarde = diasUteisDoMes(2026, 7, new Date(Date.UTC(2026, 7, 10, 23, 59)), false);
    expect(cedo.restantes).toBe(tarde.restantes);
  });

  it("decorridos mais restantes é sempre o total, em todo mês de 2026", () => {
    for (let mes = 0; mes < 12; mes++) {
      for (const dia of [1, 10, 20, 28]) {
        const r = diasUteisDoMes(2026, mes, new Date(Date.UTC(2026, mes, dia)), false);
        expect(r.decorridos + r.restantes, `${mes + 1}/${dia}`).toBe(r.uteis);
      }
    }
  });
});

describe("porDiaUtil", () => {
  it("divide o que falta pelos dias que restam", () => {
    expect(porDiaUtil(10000, 4000, 6)).toBe(1000);
  });

  it("meta batida devolve zero, e não número negativo", () => {
    // Negativo lido às pressas parece dívida. Zero diz a verdade.
    expect(porDiaUtil(10000, 12000, 5)).toBe(0);
    expect(porDiaUtil(10000, 10000, 5)).toBe(0);
  });

  it("sem dia útil restante devolve null, e não Infinity", () => {
    // A tela mostraria "R$ Infinity por dia", que é pior que não mostrar nada.
    expect(porDiaUtil(10000, 4000, 0)).toBeNull();
    expect(porDiaUtil(10000, 4000, -1)).toBeNull();
  });

  it("meta zero não vira exigência", () => {
    expect(porDiaUtil(0, 0, 10)).toBe(0);
  });
});

describe("ritmoEsperado", () => {
  it("metade do mês decorrido dá 0,5", () => {
    expect(ritmoEsperado({ uteis: 20, restantes: 10, decorridos: 10, feriadosNoMes: [] })).toBe(0.5);
  });

  it("mês sem dia útil não divide por zero", () => {
    expect(ritmoEsperado({ uteis: 0, restantes: 0, decorridos: 0, feriadosNoMes: [] })).toBe(0);
  });
});
