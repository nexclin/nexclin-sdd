/**
 * SPEC 005 / T009 — testes da entrada dos catálogos.
 *
 * O Princípio IX é explícito: aritmética de dinheiro se simula antes de
 * declarar certa. Metade destes testes é exatamente isso, e a outra metade
 * prova a fronteira que impede o formulário de escolher a coluna.
 */

import { describe, expect, it } from "vitest";

import { catalogoPorSlug } from "../catalogo";
import { interpretaNumero, normalizaEntradaDeCatalogo } from "../entrada";

describe("interpretaNumero: o formato brasileiro, e a armadilha do ponto", () => {
  // A armadilha que motivou a função: `Number("1.234")` devolve 1.234, mil
  // vezes menor que o pretendido, e sem erro nenhum. Num campo de preço isso
  // vira R$ 1,23 no lugar de R$ 1.234,00.
  const casos: Array<[string, number | null]> = [
    ["1.234,56", 1234.56],
    ["1234,56", 1234.56],
    ["1234.56", 1234.56],
    ["1,234.56", 1234.56],
    ["1.234", 1234],       // agrupamento, NÃO um vírgula-dois-três-quatro
    ["1.234.567", 1234567],
    ["0,5", 0.5],
    ["0.5", 0.5],
    ["150", 150],
    ["-30,5", -30.5],
    ["1 234,56", 1234.56], // espaço como agrupador, que o teclado numérico produz
    ["", null],
    ["   ", null],
    ["abc", null],
    ["12abc", null],
    ["R$ 150", null],      // o símbolo não é aceito: quem digita moeda digita número
  ];

  for (const [entrada, esperado] of casos) {
    it(`"${entrada}" vira ${esperado}`, () => {
      expect(interpretaNumero(entrada)).toBe(esperado);
    });
  }

  it("o caso que mais dói: 1.234 não pode virar 1.234", () => {
    // Escrito separado porque é o defeito real que a função existe para evitar.
    expect(Number("1.234")).toBe(1.234);
    expect(interpretaNumero("1.234")).toBe(1234);
  });
});

describe("normalizaEntradaDeCatalogo: a fronteira e as regras", () => {
  const servicos = catalogoPorSlug("servicos")!;
  const formasDePagamento = catalogoPorSlug("formas-de-pagamento")!;

  it("campo que não está declarado NÃO chega ao objeto de escrita", () => {
    // É a fronteira. Um `<input name="clinic_id">` acrescentado no navegador
    // viajaria junto num spread e tentaria mover a linha para outra clínica.
    const r = normalizaEntradaDeCatalogo(servicos, {
      name: "Limpeza",
      clinic_id: "clinica-de-outra-pessoa",
      id: "linha-alheia",
      is_system: "true",
    });

    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.valores).not.toHaveProperty("clinic_id");
    expect(r.valores).not.toHaveProperty("id");
    expect(r.valores).not.toHaveProperty("is_system");
    expect(r.valores.name).toBe("Limpeza");
  });

  it("campo obrigatório vazio recusa, e diz qual é", () => {
    const r = normalizaEntradaDeCatalogo(servicos, { name: "   " });
    expect(r.ok).toBe(false);
    if (r.ok) return;
    expect(r.erros.name).toContain("obrigatório");
  });

  it("campo opcional vazio vira NULL, e não string vazia", () => {
    // Gravar '' numa coluna numérica é erro de tipo, e numa de texto cria a
    // distinção inútil entre vazio e nulo que some nos relatórios depois.
    const r = normalizaEntradaDeCatalogo(servicos, { name: "Consulta", price: "" });
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.valores.price).toBeNull();
  });

  it("moeda fecha em duas casas", () => {
    const r = normalizaEntradaDeCatalogo(servicos, {
      name: "Clareamento",
      price: "1.234,567",
    });
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.valores.price).toBe(1234.57);
  });

  it("moeda negativa recusa: preço negativo não existe", () => {
    const r = normalizaEntradaDeCatalogo(servicos, { name: "X", price: "-10" });
    expect(r.ok).toBe(false);
  });

  it("percentual fora de 0 a 100 recusa", () => {
    // Taxa de 150% num recebível some com o líquido inteiro, em silêncio.
    const ruim = normalizaEntradaDeCatalogo(formasDePagamento, {
      name: "Crédito",
      default_fee_percent: "150",
    });
    expect(ruim.ok).toBe(false);

    const bom = normalizaEntradaDeCatalogo(formasDePagamento, {
      name: "Crédito",
      default_fee_percent: "3,49",
    });
    expect(bom.ok).toBe(true);
    if (!bom.ok) return;
    expect(bom.valores.default_fee_percent).toBe(3.49);
  });

  it("inteiro não aceita casa decimal nem negativo", () => {
    const comDecimal = normalizaEntradaDeCatalogo(formasDePagamento, {
      name: "Débito",
      payment_term_days: "1,5",
    });
    expect(comDecimal.ok).toBe(false);

    const negativo = normalizaEntradaDeCatalogo(formasDePagamento, {
      name: "Débito",
      payment_term_days: "-1",
    });
    expect(negativo.ok).toBe(false);

    const bom = normalizaEntradaDeCatalogo(formasDePagamento, {
      name: "Débito",
      payment_term_days: "30",
    });
    expect(bom.ok).toBe(true);
  });

  it("texto que não é número recusa em vez de virar zero", () => {
    // Virar zero seria pior que recusar: preço zero é um preço válido, e
    // ninguém repara nele até o relatório fechar errado.
    const r = normalizaEntradaDeCatalogo(servicos, { name: "X", price: "abc" });
    expect(r.ok).toBe(false);
    if (r.ok) return;
    expect(r.erros.price).toContain("número");
  });

  it("todos os erros voltam juntos, não um por vez", () => {
    // Formulário que corrige um erro por submissão é o que faz a pessoa
    // desistir de preencher a configuração.
    const r = normalizaEntradaDeCatalogo(servicos, {
      name: "",
      price: "abc",
      duration_minutes: "1,5",
    });
    expect(r.ok).toBe(false);
    if (r.ok) return;
    expect(Object.keys(r.erros).sort()).toEqual([
      "duration_minutes",
      "name",
      "price",
    ]);
  });
});
