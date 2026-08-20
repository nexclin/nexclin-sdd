/**
 * SPEC 001 / T021 — testes do perímetro de permissão do front.
 *
 * Princípio V: "guards de rota e lógica de permissão MUST ter testes
 * automatizados mínimos — são o perímetro de segurança da camada de aplicação."
 * Esta é a dívida que estava em zero desde a Fase 4.
 *
 * O que estes testes protegem é uma coisa só, e ela é a que importa: **o front
 * falha fechado**. A cascata de permissão não é testada aqui porque não mora
 * aqui — mora em `my_permission`, no Postgres, e testá-la exige o banco (é
 * trabalho do T027, em Playwright).
 */

import { describe, expect, it } from "vitest";
import { MODULE_KEYS, ehModuleKey, type ModuleKey } from "../modulos";
import {
  NEGADO,
  normalizarPermissao,
  podeAcessar,
  resolverAcesso,
} from "../permissao";

describe("contrato das 15 ModuleKeys (regra (f))", () => {
  it("tem exatamente as 15 chaves oficiais, nem mais nem menos", () => {
    // Lista escrita à mão de propósito: se alguém acrescentar um módulo em
    // modulos.ts sem acrescentar no banco, este teste quebra — que é o ponto.
    const oficiais = [
      "dashboard",
      "leads",
      "pacientes",
      "anamnese",
      "consultas",
      "acompanhamento",
      "tarefas",
      "contas_receber",
      "contas_pagar",
      "fluxo_caixa",
      "relatorios_vendas",
      "relatorios_demais",
      "configuracoes",
      "equipe",
      "insights",
    ];
    expect([...MODULE_KEYS].sort()).toEqual(oficiais.sort());
    expect(MODULE_KEYS).toHaveLength(15);
  });

  it("não tem chave repetida", () => {
    expect(new Set(MODULE_KEYS).size).toBe(MODULE_KEYS.length);
  });

  it("reconhece as chaves do contrato e recusa o resto", () => {
    for (const chave of MODULE_KEYS) expect(ehModuleKey(chave)).toBe(true);

    for (const intruso of [
      "Pacientes", // maiúscula não conta — a string é literal
      "pacientes ", // espaço sobrando
      "financeiro", // módulo que não existe
      "contas-receber", // hífen no lugar de underscore
      "",
      null,
      undefined,
      42,
      {},
      [],
    ]) {
      expect(ehModuleKey(intruso)).toBe(false);
    }
  });
});

describe("normalizarPermissao — falha fechado (regra (b))", () => {
  it("nega quando o RPC devolve erro, mesmo com dado junto", () => {
    expect(normalizarPermissao("full", new Error("rede caiu"))).toBe(NEGADO);
    expect(normalizarPermissao("full", { message: "permission denied" })).toBe(
      NEGADO,
    );
  });

  it("nega quando não veio nada", () => {
    expect(normalizarPermissao(null)).toBe(NEGADO);
    expect(normalizarPermissao(undefined)).toBe(NEGADO);
  });

  it("nega quando veio um tipo que não é string", () => {
    for (const lixo of [0, 1, true, false, {}, [], () => "full"]) {
      expect(normalizarPermissao(lixo)).toBe(NEGADO);
    }
  });

  it("nega string vazia ou só espaço", () => {
    expect(normalizarPermissao("")).toBe(NEGADO);
    expect(normalizarPermissao("   ")).toBe(NEGADO);
  });

  it("preserva o valor que o banco mandou, sem interpretar", () => {
    // O vocabulário é por módulo e pertence ao banco. O front não traduz.
    for (const valor of [
      "full",
      "read",
      "all",
      "own",
      "simplified",
      "responsible_only",
      "status_only",
    ]) {
      expect(normalizarPermissao(valor)).toBe(valor);
    }
  });

  it("apara espaço em volta sem alterar o valor", () => {
    expect(normalizarPermissao("  full  ")).toBe("full");
  });

  it("nunca lança, para qualquer entrada", () => {
    const entradas: unknown[] = [
      null,
      undefined,
      NaN,
      Infinity,
      Symbol("x"),
      new Date(),
      { toString: () => { throw new Error("armadilha"); } },
    ];
    for (const e of entradas) {
      expect(() => normalizarPermissao(e)).not.toThrow();
      expect(() => podeAcessar(e)).not.toThrow();
    }
  });
});

describe("podeAcessar — 'none' é a única resposta que nega", () => {
  it("nega 'none'", () => {
    expect(podeAcessar("none")).toBe(false);
  });

  it("concede qualquer outro valor conhecido", () => {
    for (const valor of ["full", "read", "all", "own", "simplified"]) {
      expect(podeAcessar(valor)).toBe(true);
    }
  });

  it("nega tudo que não deu para interpretar", () => {
    for (const lixo of [null, undefined, "", "  ", 1, {}, []]) {
      expect(podeAcessar(lixo)).toBe(false);
    }
  });
});

describe("resolverAcesso — o módulo é verificado antes da resposta", () => {
  it("nega módulo fora do contrato mesmo com o banco dizendo 'full'", () => {
    // Um erro de digitação numa rota não pode virar porta aberta.
    const r = resolverAcesso("financeiro", "full");
    expect(r.liberado).toBe(false);
    expect(r.permissao).toBe(NEGADO);
  });

  it("nega módulo nulo, vazio ou de outro tipo", () => {
    for (const modulo of [null, undefined, "", 7, {}]) {
      expect(resolverAcesso(modulo, "full").liberado).toBe(false);
    }
  });

  it("libera módulo do contrato quando o banco concede", () => {
    const r = resolverAcesso("pacientes" satisfies ModuleKey, "full");
    expect(r.liberado).toBe(true);
    expect(r.permissao).toBe("full");
  });

  it("nega módulo do contrato quando o banco devolve 'none'", () => {
    const r = resolverAcesso("contas_pagar", "none");
    expect(r.liberado).toBe(false);
    expect(r.permissao).toBe(NEGADO);
  });

  it("nega quando o RPC falhou, para todos os 15 módulos", () => {
    for (const modulo of MODULE_KEYS) {
      const r = resolverAcesso(modulo, "full", new Error("timeout"));
      expect(r.liberado).toBe(false);
      expect(r.permissao).toBe(NEGADO);
    }
  });

  it("nega, para todos os 15 módulos, quando a resposta não veio", () => {
    for (const modulo of MODULE_KEYS) {
      expect(resolverAcesso(modulo, null).liberado).toBe(false);
      expect(resolverAcesso(modulo, undefined).liberado).toBe(false);
    }
  });
});
