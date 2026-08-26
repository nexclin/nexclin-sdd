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
  /**
   * Onde este catálogo reaparece no sistema.
   *
   * # Por que isto é dado e não frase
   *
   * A `descricao` já explica o catálogo em prosa. Isto é outra coisa: a lista
   * das telas que **leem** estas linhas, para a configuração deixar de ser uma
   * gaveta e virar uma corrente de consequência.
   *
   * Vem da pesquisa de 25/08 sobre o INI, em
   * `docs/planejamento/modelagem-ini.md`. Lá, cada cartão de cadastro
   * diz o que alimenta ("estas são as colunas do Kanban", "isto alimenta o
   * Imobilizado"), e foi o item de maior retorno por menor custo da pesquisa
   * inteira.
   *
   * A razão é do nosso projeto, e não do INI: o onboarding tem 12 passos, e o
   * critério da §2.5 é o que o cliente fundador consegue operar. Dizer para que
   * serve é o que dá motivo para preencher agora em vez de depois.
   */
  alimenta: readonly string[];
  /**
   * A posição na sequência sugerida, e ela é por DEPENDÊNCIA DE DADO.
   *
   * Serviço vem antes de forma de pagamento porque o preço nasce no serviço;
   * origem vem depois de canal porque origem pertence a um canal. Preencher
   * fora de ordem funciona, e só custa voltar.
   */
  ordem: number;
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
    ordem: 8,
    alimenta: ["Leads", "Relatório de leads", "Dashboard"],
    tabela: "channels",
    rotulo: "Canais",
    rotuloSingular: "Canal",
    descricao: "Por onde o paciente chegou até a clínica. Alimenta o funil de captação.",
    campos: [NOME],
    passoDeOnboarding: "channels_origins",
  },
  {
    slug: "origens",
    ordem: 9,
    alimenta: ["Leads", "Relatório de leads"],
    tabela: "origins",
    rotulo: "Origens",
    rotuloSingular: "Origem",
    descricao: "A campanha ou indicação específica dentro de um canal.",
    campos: [NOME],
    passoDeOnboarding: "channels_origins",
  },
  {
    slug: "objecoes",
    ordem: 10,
    alimenta: ["Leads", "Relatório de leads"],
    tabela: "objections",
    rotulo: "Objeções",
    rotuloSingular: "Objeção",
    descricao: "Os motivos pelos quais um lead não agendou. É o que o relatório de leads lê.",
    campos: [NOME],
    passoDeOnboarding: "objections",
  },
  {
    slug: "servicos",
    ordem: 1,
    alimenta: ["Consultas", "Orçamentos", "Contas a receber", "Relatório de vendas", "Dashboard"],
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
    ordem: 4,
    alimenta: ["Contas a receber", "Fluxo de caixa", "Relatório de vendas"],
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
    ordem: 7,
    alimenta: ["Contas a pagar", "Fluxo de caixa"],
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
    slug: "contas-bancarias",
    ordem: 5,
    alimenta: ["Fluxo de caixa", "Contas a pagar", "Contas a receber"],
    tabela: "bank_accounts",
    rotulo: "Contas bancárias",
    rotuloSingular: "Conta bancária",
    descricao:
      "Onde o dinheiro entra e sai. É a conta que o fluxo de caixa concilia.",
    campos: [
      {
        coluna: "bank_name",
        rotulo: "Banco",
        tipo: "texto",
        obrigatorio: true,
        naLista: true,
      },
      { coluna: "bank_code", rotulo: "Código do banco", tipo: "texto", naLista: true },
      { coluna: "agency", rotulo: "Agência", tipo: "texto", naLista: true },
      { coluna: "account", rotulo: "Conta", tipo: "texto", naLista: true },
      {
        coluna: "account_type",
        rotulo: "Tipo",
        tipo: "texto",
        naLista: true,
        ajuda: "corrente, poupanca ou pagamento.",
      },
    ],
  },
  {
    slug: "tipos-de-fechamento",
    ordem: 6,
    alimenta: ["Acompanhamento", "Relatório de vendas"],
    tabela: "closing_types",
    rotulo: "Tipos de fechamento",
    rotuloSingular: "Tipo de fechamento",
    descricao: "Como um atendimento é classificado ao fechar.",
    campos: [NOME],
    temIsSystem: true,
  },
  {
    slug: "tipos-de-consulta",
    ordem: 2,
    alimenta: ["Consultas", "Agenda"],
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
    ordem: 3,
    alimenta: ["Formas de pagamento", "Contas a receber", "Fluxo de caixa"],
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

/**
 * Os catálogos na ordem sugerida de preenchimento.
 *
 * A ordem do array `CATALOGOS` é a de escrita, e ela não é a de dependência.
 * Quem monta tela usa esta função; quem valida slug usa o array.
 */
export function catalogosEmOrdem(): DefinicaoDeCatalogo[] {
  return [...CATALOGOS].sort((a, b) => a.ordem - b.ordem);
}

/**
 * O catálogo anterior e o próximo, para os botões Voltar e Avançar.
 *
 * Devolve `null` nas pontas, e é assim que a tela sabe não desenhar o botão.
 * Slug desconhecido devolve os dois `null`, e não uma exceção: quem chama já
 * tratou o desconhecido com um 404 antes de chegar aqui, e uma exceção aqui só
 * derrubaria a página duas vezes pelo mesmo motivo.
 */
export function vizinhosDoCatalogo(slug: string): {
  anterior: DefinicaoDeCatalogo | null;
  proximo: DefinicaoDeCatalogo | null;
} {
  const ordenados = catalogosEmOrdem();
  const i = ordenados.findIndex((c) => c.slug === slug);
  if (i < 0) return { anterior: null, proximo: null };
  return {
    anterior: ordenados[i - 1] ?? null,
    proximo: ordenados[i + 1] ?? null,
  };
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
