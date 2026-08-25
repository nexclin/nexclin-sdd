/**
 * SPEC 005 / T007 — a definição declarativa dos catálogos da clínica.
 *
 * # Por que uma definição, e não treze telas
 *
 * Nove dos catálogos têm a mesma forma: `id`, `clinic_id`, `name`, `active`, e
 * algumas colunas de valor. Escrever nove telas seria criar **nove lugares para
 * a mesma regra divergir** — que é o Princípio VIII da constituição, e é o que
 * o `INVENTARIO-UI.md` documenta ter acontecido na referência, com três
 * vocabulários de período convivendo.
 *
 * Aqui, acrescentar um catálogo é acrescentar uma entrada nesta lista.
 *
 * # A definição é também a lista de permissão da rota
 *
 * A rota `/app/configuracoes/[catalogo]` recebe o nome do catálogo pela URL, e
 * **usa esse nome para escolher a tabela consultada**. Sem validação, isso vira
 * leitura de tabela arbitrária escolhida pelo cliente.
 *
 * Por isso a busca é sempre por este registro, e catálogo desconhecido é 404.
 * Não é conveniência de roteamento: é a fronteira que impede a URL de escolher
 * o que o banco lê.
 */

export type TipoDeCampo = "texto" | "moeda" | "percentual" | "inteiro" | "booleano";

export interface CampoDeCatalogo {
  coluna: string;
  rotulo: string;
  tipo: TipoDeCampo;
  obrigatorio?: boolean;
  /** Aparece na tabela de listagem. Campo sem isto só aparece no formulário. */
  naLista?: boolean;
  ajuda?: string;
}

export interface DefinicaoDeCatalogo {
  /** O identificador na URL. Precisa ser estável: vira link salvo pelo usuário. */
  slug: string;
  /** A tabela no Postgres. Só nomes desta lista chegam a uma consulta. */
  tabela: string;
  rotulo: string;
  rotuloSingular: string;
  descricao: string;
  campos: CampoDeCatalogo[];
  /**
   * Se a tabela tem `is_system`. Linha de sistema não é editável nem removível
   * pela clínica, e a tela precisa saber disso para não oferecer o botão.
   */
  temIsSystem?: boolean;
  /** O passo do onboarding que esta tabela fecha, se fechar algum. */
  passoDeOnboarding?: string;
}

const NOME: CampoDeCatalogo = {
  coluna: "name",
  rotulo: "Nome",
  tipo: "texto",
  obrigatorio: true,
  naLista: true,
};

export const CATALOGOS: readonly DefinicaoDeCatalogo[] = [
  {
    slug: "canais",
    tabela: "channels",
    rotulo: "Canais",
    rotuloSingular: "Canal",
    descricao: "Por onde o paciente chegou até a clínica. Alimenta o funil de captação.",
    campos: [NOME],
    passoDeOnboarding: "channels_origins",
  },
  {
    slug: "origens",
    tabela: "origins",
    rotulo: "Origens",
    rotuloSingular: "Origem",
    descricao: "A campanha ou indicação específica dentro de um canal.",
    campos: [NOME],
    passoDeOnboarding: "channels_origins",
  },
  {
    slug: "objecoes",
    tabela: "objections",
    rotulo: "Objeções",
    rotuloSingular: "Objeção",
    descricao: "Os motivos pelos quais um lead não agendou. É o que o relatório de leads lê.",
    campos: [NOME],
    passoDeOnboarding: "objections",
  },
  {
    slug: "servicos",
    tabela: "services",
    rotulo: "Serviços",
    rotuloSingular: "Serviço",
    descricao:
      "O que a clínica oferece, com preço e custo. A macro-categoria é o que separa consulta de venda em todo o financeiro.",
    campos: [
      NOME,
      { coluna: "macro_category", rotulo: "Macro-categoria", tipo: "texto", naLista: true,
        ajuda: "Separa consulta de venda nos relatórios. Preencher errado tira a receita do lugar certo." },
      { coluna: "category", rotulo: "Categoria", tipo: "texto" },
      { coluna: "price", rotulo: "Preço", tipo: "moeda", naLista: true },
      { coluna: "cost", rotulo: "Custo", tipo: "moeda" },
      { coluna: "duration_minutes", rotulo: "Duração (min)", tipo: "inteiro" },
    ],
    passoDeOnboarding: "services",
  },
  {
    slug: "formas-de-pagamento",
    tabela: "payment_methods",
    rotulo: "Formas de pagamento",
    rotuloSingular: "Forma de pagamento",
    descricao:
      "A taxa e o prazo daqui é que decidem o líquido e o vencimento de todo recebível.",
    campos: [
      NOME,
      { coluna: "brand", rotulo: "Bandeira", tipo: "texto" },
      { coluna: "default_fee_percent", rotulo: "Taxa padrão", tipo: "percentual", naLista: true },
      { coluna: "anticipation_fee_percent", rotulo: "Taxa de antecipação", tipo: "percentual" },
      { coluna: "payment_term_days", rotulo: "Prazo (dias)", tipo: "inteiro", naLista: true },
    ],
    passoDeOnboarding: "payment_methods",
  },
  {
    slug: "categorias-de-despesa",
    tabela: "expense_categories",
    rotulo: "Categorias de despesa",
    rotuloSingular: "Categoria de despesa",
    descricao: "Como as saídas são agrupadas no DRE e no fluxo de caixa.",
    campos: [
      NOME,
      { coluna: "subcategory", rotulo: "Subcategoria", tipo: "texto", naLista: true },
      { coluna: "cost_center", rotulo: "Centro de custo", tipo: "texto", naLista: true },
    ],
  },
  {
    slug: "tipos-de-fechamento",
    tabela: "closing_types",
    rotulo: "Tipos de fechamento",
    rotuloSingular: "Tipo de fechamento",
    descricao: "Como um atendimento é classificado ao fechar.",
    campos: [NOME],
    temIsSystem: true,
  },
  {
    slug: "tipos-de-consulta",
    tabela: "consultation_types",
    rotulo: "Tipos de consulta",
    rotuloSingular: "Tipo de consulta",
    descricao: "Primeira consulta, retorno, avaliação. Cada um com o seu preço.",
    campos: [
      NOME,
      { coluna: "description", rotulo: "Descrição", tipo: "texto" },
      { coluna: "price", rotulo: "Preço", tipo: "moeda", naLista: true },
    ],
  },
  {
    slug: "adquirentes",
    tabela: "acquirers",
    rotulo: "Adquirentes",
    rotuloSingular: "Adquirente",
    descricao: "As maquininhas, com as taxas de crédito, débito e antecipação.",
    campos: [
      NOME,
      { coluna: "credit_fee_percent", rotulo: "Taxa de crédito", tipo: "percentual", naLista: true },
      { coluna: "debit_fee_percent", rotulo: "Taxa de débito", tipo: "percentual", naLista: true },
      { coluna: "anticipation_fee_percent", rotulo: "Taxa de antecipação", tipo: "percentual" },
    ],
  },
] as const;

/**
 * Encontra um catálogo pelo slug da URL.
 *
 * Devolve `null` para slug desconhecido, e quem chama **precisa** tratar `null`
 * como 404. É esta função que impede a URL de escolher a tabela consultada.
 */
export function catalogoPorSlug(slug: unknown): DefinicaoDeCatalogo | null {
  if (typeof slug !== "string" || slug === "") return null;
  return CATALOGOS.find((c) => c.slug === slug) ?? null;
}

/** As colunas que a listagem mostra, sempre com o nome primeiro. */
export function colunasDaLista(c: DefinicaoDeCatalogo): CampoDeCatalogo[] {
  return c.campos.filter((f) => f.naLista);
}

/**
 * As colunas a pedir ao banco.
 *
 * Nomeadas, nunca `select("*")`: o item 17 da auditoria de segurança
 * (SPEC 016) registra que o app não usa `*` em lugar nenhum, e essa disciplina
 * é o que impede coluna nova de vazar para a tela sem ninguém decidir.
 */
export function colunasParaConsulta(c: DefinicaoDeCatalogo): string {
  const base = ["id", "active"];
  const doCatalogo = c.campos.map((f) => f.coluna);
  if (c.temIsSystem) base.push("is_system");
  return [...base, ...doCatalogo].join(", ");
}
