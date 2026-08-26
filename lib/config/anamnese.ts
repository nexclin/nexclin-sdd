/**
 * SPEC 005 / T015 — o modelo de anamnese.
 *
 * # Por que este é o mais caro dos catálogos
 *
 * `anamnesis_config.fields` é um `jsonb` livre, e guarda **duas formas
 * diferentes** conforme a época em que a linha foi criada: um array plano de
 * campos, e um array de seções com campos dentro. A referência tem uma função
 * chamada `normalizeFieldsToSections` justamente para conviver com as duas.
 *
 * Coluna livre é onde a validação não existe, então ela precisa existir aqui.
 *
 * # A falha que erra em silêncio, e por isso tem teste próprio
 *
 * As respostas do paciente são gravadas **com a chave sendo o `id` do campo**.
 * Trocar o `id` de um campo não dá erro em lugar nenhum: a anamnese antiga
 * simplesmente perde aquela resposta, porque a chave que ela guarda deixou de
 * existir no modelo.
 *
 * Por isso `id` nunca é regerado ao editar, e há um teste que prova isso. É
 * histórico clínico, não formulário de site.
 */

export const TIPOS_DE_CAMPO = [
  "short_text",
  "long_text",
  "radio",
  "checkbox",
  "dropdown",
  "date",
  "number",
  "length_cm",
  "length_m",
  "mass_kg",
] as const;

export type TipoDeCampo = (typeof TIPOS_DE_CAMPO)[number];

/** Os rótulos, num `Record` completo: tipo novo sem rótulo é erro de compilação. */
export const ROTULO_DE_TIPO: Record<TipoDeCampo, string> = {
  short_text: "Texto curto",
  long_text: "Texto longo",
  radio: "Seleção única",
  checkbox: "Múltipla escolha",
  dropdown: "Lista suspensa",
  date: "Data",
  number: "Número",
  length_cm: "Comprimento (cm)",
  length_m: "Altura (m)",
  mass_kg: "Peso (kg)",
};

/** Os tipos que só fazem sentido com opções para escolher. */
export const TIPOS_COM_OPCOES: readonly TipoDeCampo[] = ["radio", "checkbox", "dropdown"];

export interface OpcaoDeCampo {
  label: string;
  value: string;
}

export interface CampoDeAnamnese {
  id: string;
  label: string;
  tipo: TipoDeCampo;
  obrigatorio: boolean;
  ativo: boolean;
  opcoes?: OpcaoDeCampo[];
}

export interface SecaoDeAnamnese {
  id: string;
  titulo: string;
  campos: CampoDeAnamnese[];
}

export function ehTipoDeCampo(v: unknown): v is TipoDeCampo {
  return typeof v === "string" && (TIPOS_DE_CAMPO as readonly string[]).includes(v);
}

function texto(v: unknown, padrao = ""): string {
  return typeof v === "string" ? v : padrao;
}

/**
 * Lê um campo vindo do `jsonb`, com os nomes das duas épocas.
 *
 * A referência grava `label`, `type`, `required` e `active`; aqui o vocabulário
 * é português. Ler os dois é o que evita a tela em branco no meio, e é o mesmo
 * padrão que `enabled_modules` precisou.
 *
 * Devolve `null` para lixo que não é objeto. Campo sem `id` **ganha um**, e é a
 * única situação em que gerar id é seguro: não havia resposta apontando para ele.
 */
function leCampo(bruto: unknown, novoId: () => string): CampoDeAnamnese | null {
  if (!bruto || typeof bruto !== "object" || Array.isArray(bruto)) return null;
  const o = bruto as Record<string, unknown>;

  const tipoBruto = o.tipo ?? o.type;
  const tipo: TipoDeCampo = ehTipoDeCampo(tipoBruto) ? tipoBruto : "short_text";

  const opcoesBrutas = Array.isArray(o.opcoes)
    ? o.opcoes
    : Array.isArray(o.options)
      ? o.options
      : [];

  const opcoes = opcoesBrutas
    .map((op) => {
      if (typeof op === "string") return { label: op, value: op };
      if (op && typeof op === "object") {
        const r = op as Record<string, unknown>;
        const label = texto(r.label ?? r.rotulo);
        return { label, value: texto(r.value ?? r.valor, label) };
      }
      return null;
    })
    .filter((op): op is OpcaoDeCampo => op !== null && op.label !== "");

  return {
    id: texto(o.id) || novoId(),
    label: texto(o.label ?? o.rotulo),
    tipo,
    obrigatorio: Boolean(o.obrigatorio ?? o.required),
    // `active !== false` e não `Boolean(active)`: campo antigo não tem a chave,
    // e ausência significa ativo. `Boolean(undefined)` desligaria o modelo
    // inteiro de toda clínica que cadastrou antes da coluna existir.
    ativo: (o.ativo ?? o.active) !== false,
    ...(TIPOS_COM_OPCOES.includes(tipo) ? { opcoes } : {}),
  };
}

/**
 * Normaliza o `jsonb` para seções, aceitando as duas formas.
 *
 * Array plano de campos vira uma seção só, chamada "Geral". Array de seções é
 * lido como está. Qualquer outra coisa vira lista vazia, e não exceção: tela de
 * configuração que estoura impede a clínica de configurar o resto.
 *
 * `novoId` é parâmetro para o teste poder ser determinístico. Função que sorteia
 * não se testa.
 */
export function normalizaParaSecoes(
  bruto: unknown,
  novoId: () => string = () => Math.random().toString(36).slice(2, 9),
): SecaoDeAnamnese[] {
  if (!Array.isArray(bruto)) return [];

  const pareceSecao = (x: unknown) =>
    !!x &&
    typeof x === "object" &&
    !Array.isArray(x) &&
    Array.isArray((x as Record<string, unknown>).campos ?? (x as Record<string, unknown>).fields);

  if (bruto.length > 0 && bruto.every(pareceSecao)) {
    return bruto.map((s) => {
      const o = s as Record<string, unknown>;
      const campos = (o.campos ?? o.fields) as unknown[];
      return {
        id: texto(o.id) || novoId(),
        titulo: texto(o.titulo ?? o.title, "Sem título"),
        campos: campos.map((c) => leCampo(c, novoId)).filter((c): c is CampoDeAnamnese => c !== null),
      };
    });
  }

  const campos = bruto.map((c) => leCampo(c, novoId)).filter((c): c is CampoDeAnamnese => c !== null);
  if (campos.length === 0) return [];
  return [{ id: novoId(), titulo: "Geral", campos }];
}

export interface ProblemaNoModelo {
  onde: string;
  mensagem: string;
}

/**
 * Os problemas que impedem o modelo de funcionar na mão do paciente.
 *
 * Devolve a lista, e não um booleano: a tela precisa dizer **qual** campo está
 * errado, e um formulário que corrige um erro por vez é o que faz a pessoa
 * desistir de preencher.
 */
export function problemasDoModelo(secoes: readonly SecaoDeAnamnese[]): ProblemaNoModelo[] {
  const problemas: ProblemaNoModelo[] = [];
  const idsVistos = new Set<string>();

  const ativos = secoes.flatMap((s) => s.campos.filter((c) => c.ativo));
  if (ativos.length === 0) {
    problemas.push({
      onde: "modelo",
      mensagem: "O modelo não tem nenhum campo ativo. O paciente receberia um formulário vazio.",
    });
  }

  for (const secao of secoes) {
    if (secao.titulo.trim() === "") {
      problemas.push({ onde: `seção ${secao.id}`, mensagem: "A seção está sem título." });
    }

    for (const campo of secao.campos) {
      const onde = `${secao.titulo || "seção sem título"} · ${campo.label || "campo sem rótulo"}`;

      // Id repetido é o pior defeito possível aqui: as respostas são gravadas
      // POR ID, então dois campos com o mesmo id disputam a mesma resposta e um
      // deles perde, sem erro nenhum.
      if (idsVistos.has(campo.id)) {
        problemas.push({ onde, mensagem: "Dois campos com o mesmo identificador. As respostas se sobrescreveriam." });
      }
      idsVistos.add(campo.id);

      if (campo.label.trim() === "") {
        problemas.push({ onde, mensagem: "O campo está sem pergunta. O paciente veria uma caixa sem rótulo." });
      }

      if (TIPOS_COM_OPCOES.includes(campo.tipo)) {
        const n = campo.opcoes?.length ?? 0;
        if (n < 2) {
          problemas.push({
            onde,
            mensagem: `${ROTULO_DE_TIPO[campo.tipo]} precisa de pelo menos duas opções. Com menos, não há o que escolher.`,
          });
        }
        const valores = new Set((campo.opcoes ?? []).map((o) => o.value));
        if (valores.size !== n) {
          problemas.push({ onde, mensagem: "Duas opções com o mesmo valor gravado." });
        }
      }

      if (campo.obrigatorio && !campo.ativo) {
        problemas.push({
          onde,
          mensagem: "Campo obrigatório e desativado ao mesmo tempo. Ele nunca apareceria, e a anamnese nunca fecharia.",
        });
      }
    }
  }

  return problemas;
}

/** Quantos campos o paciente vai ver de fato. */
export function camposAtivos(secoes: readonly SecaoDeAnamnese[]): number {
  return secoes.reduce((n, s) => n + s.campos.filter((c) => c.ativo).length, 0);
}

/**
 * De volta para o `jsonb`, na forma de seções.
 *
 * Grava sempre a forma nova. A leitura continua aceitando a antiga, então o
 * modelo se converte sozinho no primeiro salvamento, sem migração de dado.
 */
export function paraJsonb(secoes: readonly SecaoDeAnamnese[]): unknown {
  return secoes.map((s) => ({
    id: s.id,
    titulo: s.titulo,
    campos: s.campos.map((c) => ({
      id: c.id,
      label: c.label,
      tipo: c.tipo,
      obrigatorio: c.obrigatorio,
      ativo: c.ativo,
      ...(TIPOS_COM_OPCOES.includes(c.tipo) ? { opcoes: c.opcoes ?? [] } : {}),
    })),
  }));
}
