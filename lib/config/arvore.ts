/**
 * SPEC 005 / T012 — o plano de contas, que é o único catálogo em árvore.
 *
 * # Por que este não entrou no registro declarativo
 *
 * Os dez catálogos são listas planas: nome, alguns valores, ativo. O plano de
 * contas tem `parent_id` e `level`, e uma linha só faz sentido dentro da
 * hierarquia. Forçá-lo no registro plano exigiria uma exceção lá dentro, e
 * abstração que ganha exceção deixa de valer a pena.
 *
 * # As duas coisas que erram em silêncio, e por isso moram aqui
 *
 * **O ciclo.** Nada no banco impede uma conta de apontar para a própria
 * descendente como pai: `parent_id` é uma FK para a mesma tabela, e FK não sabe
 * o que é ciclo. Uma vez formado, toda leitura recursiva trava ou estoura.
 *
 * **O nível.** `level` é uma coluna, e coluna que repete o que a estrutura já
 * diz sai do lugar na primeira movimentação. Aqui ele é **derivado do pai** na
 * hora de gravar, e a tela mostra o derivado, não o gravado.
 */

export interface ContaCrua {
  id: string;
  code: string;
  name: string;
  parent_id: string | null;
  level?: number | null;
  active: boolean;
  is_system?: boolean;
}

export interface NoDaArvore extends ContaCrua {
  /** A profundidade real, contada pelos pais. */
  profundidade: number;
  filhos: NoDaArvore[];
}

/**
 * Ordena por código, do jeito que plano de contas se lê.
 *
 * `"1.10"` e `"1.9"` comparados como texto põem o 10 antes do 9, porque `"1"` é
 * menor que `"9"`. Num plano de contas isso embaralha a lista inteira, e é o
 * tipo de defeito que ninguém reporta como bug: a pessoa só acha o sistema
 * confuso.
 *
 * A comparação é segmento a segmento, numérica quando os dois lados são
 * números, textual quando não são.
 */
export function comparaCodigo(a: string, b: string): number {
  const pa = a.split(".");
  const pb = b.split(".");
  const n = Math.max(pa.length, pb.length);

  for (let i = 0; i < n; i++) {
    const sa = pa[i];
    const sb = pb[i];
    // Quem acabou primeiro é o pai, e o pai vem antes: "1" antes de "1.1".
    if (sa === undefined) return -1;
    if (sb === undefined) return 1;

    const na = Number(sa);
    const nb = Number(sb);
    if (Number.isFinite(na) && Number.isFinite(nb) && sa !== "" && sb !== "") {
      if (na !== nb) return na - nb;
    } else if (sa !== sb) {
      return sa < sb ? -1 : 1;
    }
  }
  return 0;
}

/**
 * Monta a árvore a partir da lista plana.
 *
 * Linha órfã, cujo pai não veio na lista, é tratada como **raiz**. Some da
 * hierarquia mas não some da tela, e sumir da tela é o pior dos dois: a conta
 * continuaria recebendo lançamento sem ninguém conseguir encontrá-la.
 *
 * Ciclo é cortado: a linha que fecharia o ciclo vira raiz. A função nunca trava,
 * e nunca estoura a pilha, mesmo com dado corrompido.
 */
export function montaArvore(contas: readonly ContaCrua[]): NoDaArvore[] {
  const porId = new Map<string, NoDaArvore>();
  for (const c of contas) {
    porId.set(c.id, { ...c, profundidade: 0, filhos: [] });
  }

  /** Sobe pelos pais. Devolve `false` se o caminho fecha um ciclo. */
  const caminhoEhValido = (id: string): boolean => {
    const vistos = new Set<string>();
    let atual: string | undefined = id;
    while (atual) {
      if (vistos.has(atual)) return false;
      vistos.add(atual);
      atual = porId.get(atual)?.parent_id ?? undefined;
    }
    return true;
  };

  const raizes: NoDaArvore[] = [];

  for (const c of contas) {
    const no = porId.get(c.id)!;
    const pai = c.parent_id ? porId.get(c.parent_id) : undefined;

    if (!pai || !caminhoEhValido(c.id)) {
      raizes.push(no);
      continue;
    }
    pai.filhos.push(no);
  }

  const ordena = (nos: NoDaArvore[], profundidade: number) => {
    nos.sort((x, y) => comparaCodigo(x.code, y.code));
    for (const n of nos) {
      n.profundidade = profundidade;
      ordena(n.filhos, profundidade + 1);
    }
  };
  ordena(raizes, 0);

  return raizes;
}

/** A árvore achatada na ordem de leitura, para a tela desenhar linha a linha. */
export function emOrdemDeLeitura(raizes: readonly NoDaArvore[]): NoDaArvore[] {
  const saida: NoDaArvore[] = [];
  const anda = (nos: readonly NoDaArvore[]) => {
    for (const n of nos) {
      saida.push(n);
      anda(n.filhos);
    }
  };
  anda(raizes);
  return saida;
}

/**
 * As contas que podem ser pai de uma dada conta.
 *
 * Exclui a própria conta e toda a descendência dela. **É o que impede o ciclo
 * antes de ele existir**, e é a razão de a tela oferecer uma lista em vez de um
 * campo livre: o `parent_id` é FK, e FK aceita qualquer id da mesma tabela,
 * inclusive um que feche o ciclo.
 *
 * Passando `null` como `idDaConta`, devolve todas: é o caso de conta nova, que
 * ainda não tem descendência.
 */
export function paisPossiveis(
  contas: readonly ContaCrua[],
  idDaConta: string | null,
): ContaCrua[] {
  if (!idDaConta) return [...contas].sort((a, b) => comparaCodigo(a.code, b.code));

  const proibidos = new Set<string>([idDaConta]);
  // Repete até nada mais entrar: a lista não vem ordenada por profundidade, e
  // uma passada só perderia netos que aparecem antes dos filhos.
  let mudou = true;
  while (mudou) {
    mudou = false;
    for (const c of contas) {
      if (c.parent_id && proibidos.has(c.parent_id) && !proibidos.has(c.id)) {
        proibidos.add(c.id);
        mudou = true;
      }
    }
  }

  return contas
    .filter((c) => !proibidos.has(c.id))
    .sort((a, b) => comparaCodigo(a.code, b.code));
}

/**
 * O nível derivado do pai, para gravar.
 *
 * Raiz é 1, e não 0, porque é assim que a coluna nasceu (`DEFAULT 1`) e como o
 * dado existente está. Mudar a base agora reinterpretaria todas as linhas de
 * uma vez.
 */
export function nivelPeloPai(
  contas: readonly ContaCrua[],
  parentId: string | null,
): number {
  if (!parentId) return 1;

  const porId = new Map(contas.map((c) => [c.id, c]));
  let nivel = 1;
  let atual = porId.get(parentId);
  const vistos = new Set<string>();

  while (atual && !vistos.has(atual.id)) {
    vistos.add(atual.id);
    nivel++;
    atual = atual.parent_id ? porId.get(atual.parent_id) : undefined;
  }
  return nivel;
}
