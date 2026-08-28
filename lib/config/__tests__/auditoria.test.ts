/**
 * Regra 005, FR-013: o contrato entre a lista de tabelas e as migrações.
 *
 * Este arquivo não testa lógica: testa que **o banco foi mexido junto com o
 * código**. É o mesmo padrão do teste do contrato de módulos, e existe pela
 * mesma razão: acrescentar catálogo em `catalogo.ts` sem acrescentar trigger na
 * migração não quebra `tsc`, não quebra build, e a clínica passa a editar preço
 * de serviço sem deixar rastro. Falha silenciosa em auditoria é a pior espécie,
 * porque só se descobre no dia em que alguém precisa da resposta.
 *
 * Os testes leem os `.sql` do disco de propósito. Ler o arquivo é a única forma
 * de a migração virar contrato verificável; qualquer coisa mais frouxa que isso
 * seria testar a nossa intenção em vez do que o banco vai receber.
 */

import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

import { CATALOGOS } from "../catalogo";
import {
  TABELAS_AUDITADAS_DE_CONFIGURACAO,
  TABELAS_DE_CONFIGURACAO_COM_TELA_PROPRIA,
} from "../auditoria";

const DIR_MIGRACOES = join(process.cwd(), "supabase", "migrations");

/**
 * Todo o SQL versionado, concatenado.
 *
 * **O limite disto, dito em voz alta:** concatenar ignora a ordem, então um
 * trigger criado numa migração e derrubado numa posterior continuaria passando
 * aqui. Procurar `DROP TRIGGER` não resolve, porque a própria migração desta
 * regra dropa antes de criar, para ser idempotente. Aceito hoje: ninguém tem
 * motivo para derrubar auditoria, e o dia em que alguém tiver é o dia de este
 * teste ganhar um verificador de verdade, contra o banco.
 */
function sqlDasMigracoes(): string {
  return readdirSync(DIR_MIGRACOES)
    .filter((n) => n.endsWith(".sql"))
    .map((n) => readFileSync(join(DIR_MIGRACOES, n), "utf8"))
    .join("\n");
}

/**
 * Procura um trigger de auditoria para a tabela, tolerante a espaço e a quebra
 * de linha, e exigente no resto: precisa ser AFTER, precisa cobrir as três
 * operações, e precisa chamar a função certa.
 */
function temTriggerDeAuditoria(sql: string, tabela: string): boolean {
  const padrao = new RegExp(
    String.raw`CREATE\s+TRIGGER\s+\S+\s+` +
      String.raw`AFTER\s+INSERT\s+OR\s+UPDATE\s+OR\s+DELETE\s+` +
      String.raw`ON\s+public\.${tabela}\s+` +
      String.raw`FOR\s+EACH\s+ROW\s+EXECUTE\s+FUNCTION\s+` +
      String.raw`public\.audita_mudanca_de_dado\(\)`,
    "i",
  );
  return padrao.test(sql);
}

describe("a lista de tabelas auditadas", () => {
  it("cobre toda tabela de catálogo, sem exceção", () => {
    // Se este teste falhar, alguém acrescentou catálogo e não pensou no rastro.
    // A correção é acrescentar o trigger na migração, não remover a tabela daqui.
    for (const c of CATALOGOS) {
      expect(TABELAS_AUDITADAS_DE_CONFIGURACAO).toContain(c.tabela);
    }
  });

  it("cobre as quatro tabelas de configuração com tela própria", () => {
    for (const t of TABELAS_DE_CONFIGURACAO_COM_TELA_PROPRIA) {
      expect(TABELAS_AUDITADAS_DE_CONFIGURACAO).toContain(t);
    }
  });

  it("não inclui tabela que não é de configuração", () => {
    // `patients` já é auditada pela regra 002 e não é configuração. Se ela
    // aparecer aqui, alguém confundiu o escopo das duas regras.
    expect(TABELAS_AUDITADAS_DE_CONFIGURACAO).not.toContain("patients");
    expect(TABELAS_AUDITADAS_DE_CONFIGURACAO).not.toContain("appointments");
  });
});

describe("as migrações", () => {
  const sql = sqlDasMigracoes();

  it("definem a função genérica de auditoria", () => {
    expect(sql).toMatch(
      /CREATE\s+OR\s+REPLACE\s+FUNCTION\s+public\.audita_mudanca_de_dado\(\)/i,
    );
  });

  it.each([...TABELAS_AUDITADAS_DE_CONFIGURACAO])(
    "criam o trigger de auditoria em %s",
    (tabela) => {
      expect(temTriggerDeAuditoria(sql, tabela)).toBe(true);
    },
  );

  it("mantêm o trigger de patients, que veio da regra 002", () => {
    // Guarda de regressão: a migração desta regra mexe na mesma função, e não
    // pode derrubar o que já estava de pé.
    expect(temTriggerDeAuditoria(sql, "patients")).toBe(true);
  });
});
