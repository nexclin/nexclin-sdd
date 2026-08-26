/**
 * SPEC 005 / T012 — testes da árvore do plano de contas.
 *
 * Três coisas erram em silêncio aqui, e cada uma tem seu bloco: a ordenação por
 * código, o ciclo, e o nível derivado.
 */

import { describe, expect, it } from "vitest";

import {
  comparaCodigo,
  emOrdemDeLeitura,
  montaArvore,
  nivelPeloPai,
  paisPossiveis,
  type ContaCrua,
} from "../arvore";

const conta = (
  id: string,
  code: string,
  parent_id: string | null = null,
): ContaCrua => ({ id, code, name: `Conta ${code}`, parent_id, active: true });

describe("comparaCodigo", () => {
  it("1.10 vem depois de 1.9, e não antes", () => {
    // Comparado como texto, "1.10" < "1.9" porque "1" < "9". Num plano de
    // contas isso embaralha a lista, e ninguém reporta como bug: a pessoa só
    // acha o sistema confuso.
    expect("1.10" < "1.9").toBe(true);
    expect(comparaCodigo("1.10", "1.9")).toBeGreaterThan(0);
  });

  it("o pai vem antes do filho", () => {
    expect(comparaCodigo("1", "1.1")).toBeLessThan(0);
    expect(comparaCodigo("1.1", "1")).toBeGreaterThan(0);
  });

  it("ordena uma lista inteira do jeito que se lê", () => {
    const codigos = ["2", "1.10", "1.2", "1", "1.1", "10", "1.9", "3.1.2", "3.1.10"];
    expect([...codigos].sort(comparaCodigo)).toEqual([
      "1", "1.1", "1.2", "1.9", "1.10", "2", "3.1.2", "3.1.10", "10",
    ]);
  });

  it("código não numérico não quebra, cai para comparação de texto", () => {
    expect(comparaCodigo("A", "B")).toBeLessThan(0);
    expect(comparaCodigo("1.A", "1.B")).toBeLessThan(0);
    expect(comparaCodigo("1", "1")).toBe(0);
  });
});

describe("montaArvore", () => {
  it("aninha e calcula a profundidade pelos pais", () => {
    const contas = [
      conta("a", "1"),
      conta("b", "1.1", "a"),
      conta("c", "1.1.1", "b"),
      conta("d", "2"),
    ];
    const raizes = montaArvore(contas);
    expect(raizes.map((r) => r.code)).toEqual(["1", "2"]);
    expect(raizes[0].filhos[0].code).toBe("1.1");
    expect(raizes[0].filhos[0].profundidade).toBe(1);
    expect(raizes[0].filhos[0].filhos[0].profundidade).toBe(2);
  });

  it("ordem de entrada não importa: filho antes do pai funciona", () => {
    const contas = [conta("c", "1.1.1", "b"), conta("b", "1.1", "a"), conta("a", "1")];
    const plano = emOrdemDeLeitura(montaArvore(contas));
    expect(plano.map((n) => n.code)).toEqual(["1", "1.1", "1.1.1"]);
  });

  it("órfã vira raiz em vez de sumir", () => {
    // Sumir da tela seria pior: a conta continuaria recebendo lançamento sem
    // ninguém conseguir encontrá-la.
    const contas = [conta("a", "1"), conta("x", "9.9", "nao-existe")];
    const plano = emOrdemDeLeitura(montaArvore(contas));
    expect(plano.map((n) => n.code)).toContain("9.9");
    expect(plano.find((n) => n.code === "9.9")?.profundidade).toBe(0);
  });

  it("ciclo não trava nem estoura a pilha", () => {
    // Nada no banco impede isto: parent_id é FK para a mesma tabela, e FK não
    // sabe o que é ciclo.
    const contas = [conta("a", "1", "b"), conta("b", "1.1", "a")];
    const plano = emOrdemDeLeitura(montaArvore(contas));
    expect(plano).toHaveLength(2);
  });

  it("ciclo de três também é cortado", () => {
    const contas = [conta("a", "1", "c"), conta("b", "2", "a"), conta("c", "3", "b")];
    const plano = emOrdemDeLeitura(montaArvore(contas));
    expect(plano).toHaveLength(3);
  });

  it("toda conta aparece exatamente uma vez", () => {
    const contas = [
      conta("a", "1"), conta("b", "1.1", "a"), conta("c", "1.2", "a"),
      conta("d", "2"), conta("e", "2.1", "d"), conta("f", "orfa", "sumiu"),
    ];
    const plano = emOrdemDeLeitura(montaArvore(contas));
    expect(plano).toHaveLength(contas.length);
    expect(new Set(plano.map((n) => n.id)).size).toBe(contas.length);
  });
});

describe("paisPossiveis: é o que impede o ciclo antes de ele existir", () => {
  const contas = [
    conta("a", "1"),
    conta("b", "1.1", "a"),
    conta("c", "1.1.1", "b"),
    conta("d", "2"),
  ];

  it("a própria conta não pode ser pai de si mesma", () => {
    expect(paisPossiveis(contas, "a").map((c) => c.id)).not.toContain("a");
  });

  it("descendente não pode ser pai do ancestral", () => {
    // Se `c` pudesse ser pai de `a`, o ciclo estaria formado.
    const ids = paisPossiveis(contas, "a").map((c) => c.id);
    expect(ids).not.toContain("b");
    expect(ids).not.toContain("c");
    expect(ids).toContain("d");
  });

  it("neto listado antes do filho ainda é excluído", () => {
    // A exclusão precisa repetir até estabilizar: uma passada só perderia o
    // neto que aparece antes do filho na lista.
    const foraDeOrdem = [conta("c", "1.1.1", "b"), conta("a", "1"), conta("b", "1.1", "a")];
    const ids = paisPossiveis(foraDeOrdem, "a").map((c) => c.id);
    expect(ids).toEqual([]);
  });

  it("conta nova pode ter qualquer pai", () => {
    expect(paisPossiveis(contas, null)).toHaveLength(4);
  });

  it("devolve ordenado por código", () => {
    const desordenadas = [conta("z", "10"), conta("y", "2"), conta("x", "1.10"), conta("w", "1.9")];
    expect(paisPossiveis(desordenadas, null).map((c) => c.code)).toEqual([
      "1.9", "1.10", "2", "10",
    ]);
  });
});

describe("nivelPeloPai", () => {
  const contas = [conta("a", "1"), conta("b", "1.1", "a"), conta("c", "1.1.1", "b")];

  it("raiz é 1, porque é como a coluna nasceu", () => {
    expect(nivelPeloPai(contas, null)).toBe(1);
  });

  it("cada degrau soma um", () => {
    expect(nivelPeloPai(contas, "a")).toBe(2);
    expect(nivelPeloPai(contas, "b")).toBe(3);
    expect(nivelPeloPai(contas, "c")).toBe(4);
  });

  it("pai inexistente conta como raiz, sem travar", () => {
    expect(nivelPeloPai(contas, "sumiu")).toBe(1);
  });

  it("ciclo no caminho não trava", () => {
    const ciclo = [conta("a", "1", "b"), conta("b", "1.1", "a")];
    expect(() => nivelPeloPai(ciclo, "a")).not.toThrow();
  });
});
