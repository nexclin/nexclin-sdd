/**
 * SPEC 005 / T008 — testes do núcleo de configurações.
 *
 * O critério de aceite da fila é explícito sobre um ponto: *"a regra
 * 'confirmação em dias mas armazenada em horas' é preservada, medida em ida e
 * volta"*. Isso é aritmética, e o Princípio IX manda simular aritmética antes
 * de declarar certa.
 */

import { describe, expect, it } from "vitest";
import {
  CAMPOS_DE_AGENDAMENTO,
  CAMPOS_DE_PACIENTE,
  PISO_AGENDAMENTO,
  PISO_PACIENTE,
  camposFaltando,
  diasParaHoras,
  horasParaDias,
  normalizaCamposObrigatorios,
  normalizaDias,
} from "../regras";
import {
  CATALOGOS,
  catalogoPorSlug,
  catalogosEmOrdem,
  colunasDaLista,
  colunasParaConsulta,
  vizinhosDoCatalogo,
} from "../catalogo";

describe("confirmation_hours: a ida e volta tem de ser estável", () => {
  // É o critério de aceite escrito na fila de especificações.
  it("todo valor de 1 a 30 dias volta igual ao que foi digitado", () => {
    for (let dias = 1; dias <= 30; dias++) {
      expect(horasParaDias(diasParaHoras(dias))).toBe(dias);
    }
  });

  it("exibe pelo menos 1 dia, porque zero dia não configura nada", () => {
    for (const h of [0, -5, 1, 11]) {
      expect(horasParaDias(h)).toBeGreaterThanOrEqual(1);
    }
  });

  it("arredonda para o dia mais próximo, e não trunca", () => {
    expect(horasParaDias(36)).toBe(2); // 1,5 dia arredonda para 2
    expect(horasParaDias(35)).toBe(1); // 1,45 dia arredonda para 1
    expect(horasParaDias(48)).toBe(2);
  });

  it("grava sempre em horas", () => {
    expect(diasParaHoras(1)).toBe(24);
    expect(diasParaHoras(2)).toBe(48);
    expect(diasParaHoras(30)).toBe(720);
  });

  it("entrada inválida cai no piso em vez de estourar", () => {
    for (const ruim of [null, undefined, "abc", NaN, Infinity, {}, []]) {
      expect(horasParaDias(ruim)).toBe(1);
      expect(diasParaHoras(ruim)).toBe(24);
    }
  });
});

describe("campos obrigatórios", () => {
  it("o piso não pode ser desmarcado", () => {
    // Paciente sem nome não é paciente. Deixar desmarcar seria configurar um
    // cadastro impossível.
    const r = normalizaCamposObrigatorios([], CAMPOS_DE_PACIENTE, PISO_PACIENTE);
    expect(r).toContain("name");

    const a = normalizaCamposObrigatorios([], CAMPOS_DE_AGENDAMENTO, PISO_AGENDAMENTO);
    expect(a).toContain("patient_id");
    expect(a).toContain("date");
  });

  it("descarta campo que o formulário não conhece", () => {
    const r = normalizaCamposObrigatorios(
      ["phone", "campo_inventado", "email"],
      CAMPOS_DE_PACIENTE,
      PISO_PACIENTE,
    );
    expect(r).toContain("phone");
    expect(r).toContain("email");
    expect(r).not.toContain("campo_inventado");
  });

  it("devolve na ordem do catálogo, para a tela não embaralhar a cada salvamento", () => {
    const r = normalizaCamposObrigatorios(
      ["email", "phone", "name"],
      CAMPOS_DE_PACIENTE,
      PISO_PACIENTE,
    );
    expect(r).toEqual(["name", "phone", "email"]);
  });

  it("valor que não é lista vira só o piso", () => {
    for (const ruim of [null, undefined, "name", 42, {}]) {
      expect(normalizaCamposObrigatorios(ruim, CAMPOS_DE_PACIENTE, PISO_PACIENTE)).toEqual([
        "name",
      ]);
    }
  });

  it("não duplica quando o piso já veio na lista", () => {
    const r = normalizaCamposObrigatorios(["name", "name"], CAMPOS_DE_PACIENTE, PISO_PACIENTE);
    expect(r.filter((c) => c === "name")).toHaveLength(1);
  });
});

describe("camposFaltando", () => {
  it("diz QUAIS faltaram, não só que faltou algo", () => {
    const faltam = camposFaltando({ name: "Ana", phone: "" }, ["name", "phone", "email"] as const);
    expect(faltam).toEqual(["phone", "email"]);
  });

  it("string só com espaço conta como vazia", () => {
    expect(camposFaltando({ name: "   " }, ["name"] as const)).toEqual(["name"]);
  });

  it("lista vazia conta como vazia, e zero NÃO conta", () => {
    expect(camposFaltando({ tags: [] }, ["tags"] as const)).toEqual(["tags"]);
    // Zero é um valor legítimo: preço zero, desconto zero.
    expect(camposFaltando({ price: 0 }, ["price"] as const)).toEqual([]);
    expect(camposFaltando({ ativo: false }, ["ativo"] as const)).toEqual([]);
  });
});

describe("normalizaDias", () => {
  it("aceita zero, ao contrário da confirmação", () => {
    // "Enviar a anamnese em 0 dias" significa enviar no ato, e é legítimo.
    expect(normalizaDias(0)).toBe(0);
  });

  it("recusa negativo e cai no padrão", () => {
    expect(normalizaDias(-3, 7)).toBe(7);
  });

  it("tem teto de um ano, porque acima disso é digitação errada", () => {
    expect(normalizaDias(9999)).toBe(365);
  });
});

describe("registro de catálogos", () => {
  it("todo slug é único", () => {
    const slugs = CATALOGOS.map((c) => c.slug);
    expect(new Set(slugs).size).toBe(slugs.length);
  });

  it("toda tabela é única", () => {
    const tabelas = CATALOGOS.map((c) => c.tabela);
    expect(new Set(tabelas).size).toBe(tabelas.length);
  });

  it("todo catálogo tem pelo menos uma coluna na lista", () => {
    for (const c of CATALOGOS) {
      expect(colunasDaLista(c).length).toBeGreaterThan(0);
    }
  });

  it("todo catálogo tem exatamente um campo obrigatório de nome", () => {
    for (const c of CATALOGOS) {
      const obrigatorios = c.campos.filter((f) => f.obrigatorio);
      expect(obrigatorios).toHaveLength(1);
      expect(obrigatorios[0].coluna).toBe("name");
    }
  });

  it("slug desconhecido devolve null, e é isso que vira 404", () => {
    // Esta é a fronteira que impede a URL de escolher qual tabela o banco lê.
    for (const ruim of ["patients", "profiles", "../services", "", null, 7, "SERVICOS"]) {
      expect(catalogoPorSlug(ruim)).toBeNull();
    }
  });

  it("slug conhecido devolve a definição certa", () => {
    expect(catalogoPorSlug("servicos")?.tabela).toBe("services");
    expect(catalogoPorSlug("formas-de-pagamento")?.tabela).toBe("payment_methods");
  });

  it("a consulta pede colunas nomeadas, nunca asterisco", () => {
    for (const c of CATALOGOS) {
      const cols = colunasParaConsulta(c);
      expect(cols).not.toContain("*");
      expect(cols).toContain("id");
      expect(cols).toContain("active");
      expect(cols).toContain("name");
    }
  });

  it("is_system só é pedido de quem tem a coluna", () => {
    const comFlag = CATALOGOS.filter((c) => c.temIsSystem);
    const semFlag = CATALOGOS.filter((c) => !c.temIsSystem);
    for (const c of comFlag) expect(colunasParaConsulta(c)).toContain("is_system");
    for (const c of semFlag) expect(colunasParaConsulta(c)).not.toContain("is_system");
  });
});

describe("a sequência de configuração", () => {
  // Importada do INI, registrada em `docs/planejamento/pesquisa-ini-2026-08-25.md`.
  //
  // O que se testa aqui não é a ordem "certa" — ordem é decisão de produto e
  // pode mudar. O que se testa é que a ESTRUTURA da sequência não tem buraco,
  // porque um buraco significa uma tela de onde não se sai, ou duas telas
  // disputando a mesma posição.

  it("toda ordem é única, senão duas telas disputam a mesma posição", () => {
    const ordens = CATALOGOS.map((c) => c.ordem);
    expect(new Set(ordens).size).toBe(CATALOGOS.length);
  });

  it("a sequência é contínua de 1 até o total, sem pular número", () => {
    const ordens = [...CATALOGOS.map((c) => c.ordem)].sort((a, b) => a - b);
    expect(ordens).toEqual(
      Array.from({ length: CATALOGOS.length }, (_, i) => i + 1),
    );
  });

  it("todo catálogo diz onde é usado, e sem entrada vazia", () => {
    for (const c of CATALOGOS) {
      expect(c.alimenta.length, `${c.slug} não diz onde é usado`).toBeGreaterThan(0);
      for (const onde of c.alimenta) {
        expect(onde.trim(), `${c.slug} tem destino vazio`).not.toBe("");
      }
    }
  });

  it("percorrer só pelo Avançar visita todos os catálogos, uma vez cada", () => {
    // É a prova de que não existe tela de onde não se sai. Sem ela, um erro de
    // `ordem` deixaria um catálogo inalcançável pela sequência, e ninguém
    // notaria até um cliente reclamar de um cadastro que "não existe".
    const primeiro = catalogosEmOrdem()[0];
    const visitados: string[] = [];
    let atual: string | null = primeiro.slug;

    while (atual) {
      expect(visitados, `${atual} visitado duas vezes: há um ciclo`).not.toContain(atual);
      visitados.push(atual);
      atual = vizinhosDoCatalogo(atual).proximo?.slug ?? null;
    }

    expect(visitados.length).toBe(CATALOGOS.length);
    expect(new Set(visitados)).toEqual(new Set(CATALOGOS.map((c) => c.slug)));
  });

  it("as pontas não têm vizinho, e é assim que o botão some", () => {
    const ordenados = catalogosEmOrdem();
    expect(vizinhosDoCatalogo(ordenados[0].slug).anterior).toBeNull();
    expect(vizinhosDoCatalogo(ordenados[ordenados.length - 1].slug).proximo).toBeNull();
  });

  it("Voltar desfaz Avançar em todo par vizinho", () => {
    for (const c of catalogosEmOrdem()) {
      const proximo = vizinhosDoCatalogo(c.slug).proximo;
      if (!proximo) continue;
      expect(vizinhosDoCatalogo(proximo.slug).anterior?.slug).toBe(c.slug);
    }
  });

  it("slug desconhecido devolve os dois nulos, sem lançar", () => {
    // A tela já respondeu 404 antes de chegar aqui. Lançar seria derrubar a
    // página duas vezes pelo mesmo motivo.
    expect(vizinhosDoCatalogo("patients")).toEqual({ anterior: null, proximo: null });
    expect(vizinhosDoCatalogo("")).toEqual({ anterior: null, proximo: null });
  });
});
