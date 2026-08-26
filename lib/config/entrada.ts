/**
 * SPEC 005 / T009 — a metade que faltava: a entrada, antes de virar escrita.
 *
 * # Por que isto é um arquivo puro, e não parte da server action
 *
 * A action fala com o banco, e o que fala com o banco não se testa sem banco.
 * A decisão de **o que este formulário produziu** é aritmética e regra, e o
 * Princípio IX manda simular aritmética antes de declarar certa. Separando, a
 * parte que decide é provada por teste e a parte que grava fica trivial.
 *
 * # A fronteira que este arquivo é
 *
 * `catalogoPorSlug` impede a URL de escolher a TABELA. Este arquivo impede o
 * formulário de escolher a COLUNA: só o que está declarado em `campos` chega ao
 * objeto de escrita, e o resto é descartado em silêncio.
 *
 * Sem isso, um `<input name="clinic_id">` acrescentado no navegador viajaria
 * junto num spread e tentaria mover a linha para outra clínica. A RLS recusaria
 * (o `WITH CHECK` cobre), mas depender só da RLS para isso é depender de uma
 * camada onde caberiam duas. Defesa em profundidade é o padrão da SPEC 005, e
 * já está aplicado na escolha da tabela.
 */

import type { CampoDeCatalogo, DefinicaoDeCatalogo } from "./catalogo";

export interface EntradaAceita {
  ok: true;
  valores: Record<string, string | number | boolean | null>;
}

export interface EntradaRecusada {
  ok: false;
  /** Mensagem por coluna. A tela mostra ao lado do campo que a produziu. */
  erros: Record<string, string>;
}

export type ResultadoDeEntrada = EntradaAceita | EntradaRecusada;

/**
 * Interpreta um número digitado no formato brasileiro.
 *
 * # Por que não `Number(texto)`
 *
 * `Number("1.234,56")` devolve `NaN`, e `Number("1.234")` devolve **1.234**,
 * que é mil vezes menor que o que a pessoa quis dizer. As duas falhas são
 * silenciosas em tela de configuração, e uma delas grava preço errado.
 *
 * A regra: o **último** separador que aparecer é o decimal, e tudo antes dele
 * é agrupamento. Assim `1.234,56`, `1,234.56`, `1234,56` e `1234.56` chegam
 * todos a 1234.56, e `1.234` continua sendo mil duzentos e trinta e quatro.
 *
 * Devolve `null` para texto que não é número. Vazio também é `null`, e quem
 * chama decide se isso é erro ou coluna anulável.
 */
export function interpretaNumero(bruto: string): number | null {
  const texto = bruto.trim();
  if (texto === "") return null;

  // Só dígitos, separadores e um sinal na frente. Qualquer outra coisa é texto.
  if (!/^-?[\d.,\s]+$/.test(texto)) return null;

  const semEspaco = texto.replace(/\s/g, "");
  const ultimaVirgula = semEspaco.lastIndexOf(",");
  const ultimoPonto = semEspaco.lastIndexOf(".");
  const posicaoDecimal = Math.max(ultimaVirgula, ultimoPonto);

  let normalizado: string;
  if (posicaoDecimal < 0) {
    normalizado = semEspaco;
  } else {
    const separador = semEspaco[posicaoDecimal];
    const parteInteira = semEspaco.slice(0, posicaoDecimal).replace(/[.,]/g, "");
    const parteDecimal = semEspaco.slice(posicaoDecimal + 1);

    // Separador com três dígitos depois e nenhum outro separador antes é
    // agrupamento, não decimal: "1.234" é mil duzentos e trinta e quatro.
    // A exceção é quando os dois separadores aparecem, e aí o último é sempre
    // o decimal, porque ninguém escreve "1.234.567" com decimal no meio.
    const temOsDois = ultimaVirgula >= 0 && ultimoPonto >= 0;
    if (!temOsDois && parteDecimal.length === 3 && separador === ".") {
      normalizado = semEspaco.replace(/\./g, "");
    } else {
      normalizado = `${parteInteira}.${parteDecimal}`;
    }
  }

  const n = Number(normalizado);
  return Number.isFinite(n) ? n : null;
}

/** O texto de erro de um campo, ou `null` quando o valor serve. */
function validaCampo(
  campo: CampoDeCatalogo,
  bruto: string,
): { erro: string | null; valor: string | number | boolean | null } {
  if (campo.tipo === "booleano") {
    // Caixa de seleção não envia nada quando desmarcada. Ausência é `false`,
    // e não "não informado": é o único tipo em que vazio tem significado.
    return { erro: null, valor: bruto === "on" || bruto === "true" };
  }

  const texto = bruto.trim();

  if (texto === "") {
    if (campo.obrigatorio) {
      return { erro: `${campo.rotulo} é obrigatório.`, valor: null };
    }
    // Coluna anulável recebe NULL, e não string vazia. Gravar `''` num campo
    // numérico é erro de tipo, e num campo de texto cria a distinção inútil
    // entre "vazio" e "nulo" que depois some nos relatórios.
    return { erro: null, valor: null };
  }

  if (campo.tipo === "texto") {
    return { erro: null, valor: texto };
  }

  const n = interpretaNumero(texto);
  if (n === null) {
    return { erro: `${campo.rotulo} precisa ser um número.`, valor: null };
  }

  if (campo.tipo === "inteiro") {
    if (!Number.isInteger(n)) {
      return { erro: `${campo.rotulo} não aceita casas decimais.`, valor: null };
    }
    if (n < 0) {
      return { erro: `${campo.rotulo} não pode ser negativo.`, valor: null };
    }
    return { erro: null, valor: n };
  }

  if (campo.tipo === "moeda") {
    if (n < 0) {
      return { erro: `${campo.rotulo} não pode ser negativo.`, valor: null };
    }
    // Duas casas, sempre. `toFixed` arredonda pelo meio para cima, que é o que
    // se espera de dinheiro digitado, e o resultado volta a número para não
    // gravar texto numa coluna numérica.
    return { erro: null, valor: Number(n.toFixed(2)) };
  }

  // percentual
  if (n < 0 || n > 100) {
    return {
      erro: `${campo.rotulo} precisa estar entre 0 e 100.`,
      valor: null,
    };
  }
  return { erro: null, valor: Number(n.toFixed(4)) };
}

/**
 * Transforma o que o formulário mandou no objeto que vai para o banco.
 *
 * Percorre os CAMPOS DECLARADOS, e não as chaves recebidas. É a inversão que
 * faz a fronteira existir: campo a mais no formulário não tem por onde entrar,
 * porque ninguém pergunta o que o formulário trouxe.
 */
export function normalizaEntradaDeCatalogo(
  definicao: DefinicaoDeCatalogo,
  recebido: Record<string, string>,
): ResultadoDeEntrada {
  const valores: Record<string, string | number | boolean | null> = {};
  const erros: Record<string, string> = {};

  for (const campo of definicao.campos) {
    const { erro, valor } = validaCampo(campo, recebido[campo.coluna] ?? "");
    if (erro) {
      erros[campo.coluna] = erro;
    } else {
      valores[campo.coluna] = valor;
    }
  }

  if (Object.keys(erros).length > 0) return { ok: false, erros };
  return { ok: true, valores };
}
