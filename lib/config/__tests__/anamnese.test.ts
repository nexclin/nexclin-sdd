/**
 * SPEC 005 / T015 — testes do modelo de anamnese.
 *
 * Duas coisas erram em silêncio aqui, e as duas custam histórico clínico: a
 * coluna guardar duas formas diferentes, e o `id` do campo ser a chave das
 * respostas do paciente.
 */

import { describe, expect, it } from "vitest";

import {
  camposAtivos,
  normalizaParaSecoes,
  paraJsonb,
  problemasDoModelo,
  type SecaoDeAnamnese,
} from "../anamnese";

/** Gerador determinístico, para o teste não depender de sorte. */
function contador() {
  let n = 0;
  return () => `gerado-${++n}`;
}

describe("normalizaParaSecoes: a coluna guarda duas formas", () => {
  it("array plano de campos vira uma seção Geral", () => {
    const bruto = [
      { id: "a", label: "Alergia?", type: "short_text", required: true },
      { id: "b", label: "Observações", type: "long_text" },
    ];
    const s = normalizaParaSecoes(bruto, contador());
    expect(s).toHaveLength(1);
    expect(s[0].titulo).toBe("Geral");
    expect(s[0].campos.map((c) => c.id)).toEqual(["a", "b"]);
    expect(s[0].campos[0].obrigatorio).toBe(true);
  });

  it("array de seções é lido como está", () => {
    const bruto = [
      { id: "s1", title: "Saúde", fields: [{ id: "a", label: "Alergia?", type: "radio", options: ["Sim", "Não"] }] },
    ];
    const s = normalizaParaSecoes(bruto, contador());
    expect(s).toHaveLength(1);
    expect(s[0].titulo).toBe("Saúde");
    expect(s[0].campos[0].opcoes).toEqual([
      { label: "Sim", value: "Sim" },
      { label: "Não", value: "Não" },
    ]);
  });

  it("campo sem a chave `active` continua ATIVO", () => {
    // `Boolean(undefined)` desligaria o modelo inteiro de toda clínica que
    // cadastrou antes de a chave existir. Ausência significa ativo.
    const s = normalizaParaSecoes([{ id: "a", label: "X", type: "short_text" }], contador());
    expect(s[0].campos[0].ativo).toBe(true);
  });

  it("campo com active false fica desativado", () => {
    const s = normalizaParaSecoes([{ id: "a", label: "X", type: "short_text", active: false }], contador());
    expect(s[0].campos[0].ativo).toBe(false);
  });

  it("tipo desconhecido cai para texto curto em vez de sumir", () => {
    const s = normalizaParaSecoes([{ id: "a", label: "X", type: "assinatura_digital" }], contador());
    expect(s[0].campos[0].tipo).toBe("short_text");
  });

  it("lixo não vira exceção, vira lista vazia", () => {
    // Tela de configuração que estoura impede a clínica de configurar o resto.
    for (const ruim of [null, undefined, {}, "texto", 7, []]) {
      expect(normalizaParaSecoes(ruim, contador())).toEqual([]);
    }
  });

  it("item que não é objeto é descartado, e o resto sobrevive", () => {
    const s = normalizaParaSecoes(
      ["lixo", { id: "a", label: "Vale", type: "short_text" }, null],
      contador(),
    );
    expect(s[0].campos).toHaveLength(1);
    expect(s[0].campos[0].id).toBe("a");
  });

  it("campo sem id ganha um, e é a única vez que gerar id é seguro", () => {
    // Não havia resposta apontando para ele, então não há o que órfã.
    const s = normalizaParaSecoes([{ label: "X", type: "short_text" }], contador());
    expect(s[0].campos[0].id).toBe("gerado-1");
  });
});

describe("o id do campo é a chave das respostas, então ele não pode mudar", () => {
  it("ida e volta pelo jsonb preserva todo id", () => {
    // As respostas do paciente são gravadas por id. Regenerar um id não dá erro
    // em lugar nenhum: a anamnese antiga só perde aquela resposta.
    const original = [
      { id: "s1", title: "Saúde", fields: [
        { id: "campo-alergia", label: "Alergia?", type: "radio", options: ["Sim", "Não"] },
        { id: "campo-obs", label: "Observações", type: "long_text" },
      ] },
    ];

    const ida = normalizaParaSecoes(original, contador());
    const volta = normalizaParaSecoes(paraJsonb(ida), contador());

    expect(volta[0].campos.map((c) => c.id)).toEqual(["campo-alergia", "campo-obs"]);
    expect(volta[0].id).toBe(ida[0].id);
  });

  it("a ida e volta é estável, e a segunda passada não muda nada", () => {
    const bruto = [{ id: "a", label: "Alergia?", type: "checkbox", options: [{ label: "Pólen", value: "polen" }] }];
    const uma = normalizaParaSecoes(bruto, contador());
    const duas = normalizaParaSecoes(paraJsonb(uma), contador());
    const tres = normalizaParaSecoes(paraJsonb(duas), contador());
    expect(paraJsonb(duas)).toEqual(paraJsonb(tres));
  });

  it("o formato antigo se converte sozinho no primeiro salvamento", () => {
    // É o que evita uma migração de dado: a leitura aceita as duas formas, e a
    // escrita grava sempre a nova.
    const antigo = [{ id: "a", label: "X", type: "short_text" }];
    const gravado = paraJsonb(normalizaParaSecoes(antigo, contador())) as Array<Record<string, unknown>>;
    expect(Array.isArray(gravado[0].campos)).toBe(true);
  });
});

describe("problemasDoModelo", () => {
  const secao = (campos: SecaoDeAnamnese["campos"]): SecaoDeAnamnese[] => [
    { id: "s1", titulo: "Saúde", campos },
  ];

  it("modelo sem campo ativo é recusado", () => {
    const p = problemasDoModelo(secao([
      { id: "a", label: "X", tipo: "short_text", obrigatorio: false, ativo: false },
    ]));
    expect(p.some((x) => x.mensagem.includes("formulário vazio"))).toBe(true);
  });

  it("dois campos com o mesmo id: as respostas se sobrescreveriam", () => {
    const p = problemasDoModelo(secao([
      { id: "igual", label: "A", tipo: "short_text", obrigatorio: false, ativo: true },
      { id: "igual", label: "B", tipo: "short_text", obrigatorio: false, ativo: true },
    ]));
    expect(p.some((x) => x.mensagem.includes("mesmo identificador"))).toBe(true);
  });

  it("campo sem pergunta é recusado", () => {
    const p = problemasDoModelo(secao([
      { id: "a", label: "   ", tipo: "short_text", obrigatorio: false, ativo: true },
    ]));
    expect(p.some((x) => x.mensagem.includes("sem pergunta"))).toBe(true);
  });

  it("seleção com menos de duas opções é recusada", () => {
    const p = problemasDoModelo(secao([
      { id: "a", label: "Sexo", tipo: "radio", obrigatorio: false, ativo: true, opcoes: [{ label: "M", value: "m" }] },
    ]));
    expect(p.some((x) => x.mensagem.includes("duas opções"))).toBe(true);
  });

  it("opções com o mesmo valor gravado são recusadas", () => {
    const p = problemasDoModelo(secao([
      { id: "a", label: "Sexo", tipo: "dropdown", obrigatorio: false, ativo: true, opcoes: [
        { label: "Masculino", value: "x" },
        { label: "Feminino", value: "x" },
      ] },
    ]));
    expect(p.some((x) => x.mensagem.includes("mesmo valor"))).toBe(true);
  });

  it("obrigatório e desativado juntos: a anamnese nunca fecharia", () => {
    const p = problemasDoModelo([
      { id: "s1", titulo: "Saúde", campos: [
        { id: "a", label: "Ativo", tipo: "short_text", obrigatorio: false, ativo: true },
        { id: "b", label: "Fantasma", tipo: "short_text", obrigatorio: true, ativo: false },
      ] },
    ]);
    expect(p.some((x) => x.mensagem.includes("nunca apareceria"))).toBe(true);
  });

  it("modelo bom não tem problema nenhum", () => {
    const p = problemasDoModelo(secao([
      { id: "a", label: "Alergia?", tipo: "radio", obrigatorio: true, ativo: true, opcoes: [
        { label: "Sim", value: "sim" }, { label: "Não", value: "nao" },
      ] },
      { id: "b", label: "Observações", tipo: "long_text", obrigatorio: false, ativo: true },
    ]));
    expect(p).toEqual([]);
  });

  it("todos os problemas voltam juntos, não um por vez", () => {
    const p = problemasDoModelo([
      { id: "s1", titulo: "", campos: [
        { id: "a", label: "", tipo: "short_text", obrigatorio: false, ativo: true },
        { id: "a", label: "Dup", tipo: "radio", obrigatorio: false, ativo: true, opcoes: [] },
      ] },
    ]);
    expect(p.length).toBeGreaterThanOrEqual(4);
  });
});

describe("camposAtivos", () => {
  it("conta só o que o paciente vai ver", () => {
    const s: SecaoDeAnamnese[] = [
      { id: "1", titulo: "A", campos: [
        { id: "a", label: "1", tipo: "short_text", obrigatorio: false, ativo: true },
        { id: "b", label: "2", tipo: "short_text", obrigatorio: false, ativo: false },
      ] },
      { id: "2", titulo: "B", campos: [
        { id: "c", label: "3", tipo: "short_text", obrigatorio: false, ativo: true },
      ] },
    ];
    expect(camposAtivos(s)).toBe(2);
  });

  it("modelo vazio conta zero", () => {
    expect(camposAtivos([])).toBe(0);
  });
});
