/**
 * Regra 005 / FR-010: testes do par (catálogo, piso) fixado num lugar só.
 *
 * O que estas funções existem para impedir: `normalizaCamposObrigatorios` pede
 * três argumentos, e dois deles andam sempre juntos. Escrever o par à mão em
 * cada chamada é a porta de entrada para o catálogo de um lado divergir do
 * outro, e daí para a lista fixa em código que o FR-010 proíbe.
 *
 * Quem chama hoje: `acoes.ts`, no salvamento das regras de negócio.
 */

import { describe, expect, it } from "vitest";
import {
  normalizaCamposDeAgendamento,
  normalizaCamposDePaciente,
} from "../campos-obrigatorios";

describe("normalização de campos obrigatórios de paciente", () => {
  it("respeita o que a clínica marcou", () => {
    expect(normalizaCamposDePaciente(["name", "phone", "email"])).toEqual([
      "name",
      "phone",
      "email",
    ]);
  });

  // O piso existe porque paciente sem nome não é paciente. Desmarcá-lo na tela
  // configuraria um cadastro impossível, então ele volta mesmo se removido.
  it("reimpõe o piso quando o valor vem sem ele", () => {
    expect(normalizaCamposDePaciente(["phone"])).toContain("name");
  });

  // Vale para os dois sentidos: o que vem do formulário no salvamento, e o que
  // vem da coluna jsonb na leitura. Nos dois o valor é `unknown`.
  it("sobrevive a lixo, venha do formulário ou da coluna", () => {
    for (const lixo of [null, undefined, 42, "name", {}, [1, 2], ["inexistente"]]) {
      expect(normalizaCamposDePaciente(lixo)).toEqual(["name"]);
    }
  });

  it("devolve na ordem do catálogo, não na ordem em que foi salvo", () => {
    const saida = normalizaCamposDePaciente(["email", "name", "phone"]);
    expect(saida.indexOf("name")).toBeLessThan(saida.indexOf("phone"));
    expect(saida.indexOf("phone")).toBeLessThan(saida.indexOf("email"));
  });
});

describe("normalização de campos obrigatórios de agendamento", () => {
  it("tem piso de dois campos, e não de um", () => {
    expect(normalizaCamposDeAgendamento([])).toEqual(["patient_id", "date"]);
    expect(normalizaCamposDeAgendamento(["time"])).toContain("patient_id");
    expect(normalizaCamposDeAgendamento(["time"])).toContain("date");
  });

  it("aceita campos do catálogo de agendamento", () => {
    expect(normalizaCamposDeAgendamento(["doctor", "notes"])).toContain("doctor");
    expect(normalizaCamposDeAgendamento(["doctor", "notes"])).toContain("notes");
  });

  // Um catálogo não empresta campo ao outro. `notes` é de agendamento e não
  // existe em paciente; se as duas funções compartilhassem catálogo por
  // engano, este teste quebraria.
  it("não aceita campo do outro catálogo", () => {
    expect(normalizaCamposDePaciente(["notes"])).toEqual(["name"]);
  });
});
