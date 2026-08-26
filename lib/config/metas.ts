/**
 * SPEC 005 / T014 — metas mensais que sabem quantos dias úteis o mês tem.
 *
 * # Por que isto não é só uma tela de cadastro
 *
 * `goals` já existia, com `revenue_target`, `new_patients_target`,
 * `closings_target` e `conversion_target` por mês. O que faltava é o que
 * transforma meta em decisão: **quanto falta por dia útil**.
 *
 * A ideia veio da modelagem do INI (`docs/planejamento/modelagem-ini.md`), onde
 * a tela de metas abre com *"21 dias úteis, 4 restantes"* e mostra o gap por
 * dia. É a diferença entre saber que você está atrasado e saber o que fazer
 * hoje.
 *
 * # Por que o feriado é calculado e não cadastrado
 *
 * Feriado nacional brasileiro é **determinístico**: sete datas fixas e quatro
 * que dependem da Páscoa. Pedir para a clínica cadastrar doze feriados por ano é
 * o pedágio de configuração que a pesquisa do INI mandou evitar.
 *
 * **A dívida, declarada:** feriado municipal e estadual não entram aqui, e são
 * reais (aniversário da cidade fecha clínica). Precisam de uma tabela por
 * clínica, e isso é spec própria. Enquanto não existir, o cálculo erra **para
 * mais** dias úteis, ou seja, a meta diária sai um pouco menor que a verdadeira.
 * Errar para o lado de exigir menos é o lado seguro dos dois.
 */

/**
 * O domingo de Páscoa, pelo algoritmo gregoriano anônimo.
 *
 * # Por que isto precisa existir
 *
 * Quatro dos onze feriados nacionais são móveis e todos dependem da Páscoa:
 * Carnaval (47 dias antes), Sexta-Feira Santa (2 antes), e Corpus Christi (60
 * depois). Sem calcular a Páscoa, ou se cadastra tudo à mão todo ano, ou o
 * cálculo de dias úteis fica errado em três meses do ano.
 *
 * O algoritmo é conhecido e não tem atalho legível. O que dá para fazer, e está
 * feito, é **conferir contra datas reais** nos testes: 2026, 2027, 2028 e o
 * caso extremo de 2038, quando a Páscoa cai em 25 de abril.
 */
export function domingoDePascoa(ano: number): Date {
  const a = ano % 19;
  const b = Math.floor(ano / 100);
  const c = ano % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const mes = Math.floor((h + l - 7 * m + 114) / 31);
  const dia = ((h + l - 7 * m + 114) % 31) + 1;
  return new Date(Date.UTC(ano, mes - 1, dia));
}

/** Soma dias a uma data, em UTC, sem tropeçar em horário de verão. */
function maisDias(d: Date, dias: number): Date {
  return new Date(d.getTime() + dias * 24 * 60 * 60 * 1000);
}

const chave = (d: Date) => d.toISOString().slice(0, 10);

/**
 * Os feriados nacionais do ano, como `YYYY-MM-DD`.
 *
 * Não inclui ponto facultativo. Carnaval é facultativo por lei federal e é
 * feriado na prática de toda clínica brasileira, então entra: a régua aqui é o
 * dia em que a agenda não funciona, não o texto da lei.
 */
export function feriadosNacionais(ano: number): Set<string> {
  const pascoa = domingoDePascoa(ano);

  const datas = [
    new Date(Date.UTC(ano, 0, 1)),   // Confraternização Universal
    maisDias(pascoa, -48),           // Carnaval, segunda
    maisDias(pascoa, -47),           // Carnaval, terça
    maisDias(pascoa, -2),            // Sexta-Feira Santa
    new Date(Date.UTC(ano, 3, 21)),  // Tiradentes
    new Date(Date.UTC(ano, 4, 1)),   // Dia do Trabalho
    maisDias(pascoa, 60),            // Corpus Christi
    new Date(Date.UTC(ano, 8, 7)),   // Independência
    new Date(Date.UTC(ano, 9, 12)),  // Nossa Senhora Aparecida
    new Date(Date.UTC(ano, 10, 2)),  // Finados
    new Date(Date.UTC(ano, 10, 15)), // Proclamação da República
    new Date(Date.UTC(ano, 10, 20)), // Consciência Negra, nacional desde 2024
    new Date(Date.UTC(ano, 11, 25)), // Natal
  ];

  return new Set(datas.map(chave));
}

export interface DiasDoMes {
  /** Quantos dias úteis o mês inteiro tem. */
  uteis: number;
  /** Quantos ainda restam, contando hoje. */
  restantes: number;
  /** Quantos já passaram. */
  decorridos: number;
  /** Os feriados que caíram em dia de semana, para a tela poder listar. */
  feriadosNoMes: string[];
}

/**
 * Conta os dias úteis de um mês.
 *
 * `sabadoUtil` vem de `business_rules.work_saturday`, e é por isso que esta
 * função recebe e não consulta: quem sabe se a clínica abre no sábado é a
 * configuração da clínica, e uma função pura não vai ao banco.
 *
 * `hoje` também é parâmetro. Função que lê o relógio não se testa.
 *
 * **Hoje conta como restante.** O dia ainda não acabou, e tirar o dia corrente
 * da conta faria a meta diária subir na manhã de cada dia, o que é o oposto do
 * que a tela deve mostrar.
 */
export function diasUteisDoMes(
  ano: number,
  mes: number,
  hoje: Date,
  sabadoUtil: boolean,
): DiasDoMes {
  const feriados = feriadosNacionais(ano);
  const ultimo = new Date(Date.UTC(ano, mes + 1, 0)).getUTCDate();

  let uteis = 0;
  let restantes = 0;
  const feriadosNoMes: string[] = [];

  // A comparação é por DIA, não por instante: `hoje` pode vir com hora, e um
  // `>=` sobre timestamps diria que hoje já passou às 00:01.
  const hojeChave = chave(new Date(Date.UTC(
    hoje.getUTCFullYear(), hoje.getUTCMonth(), hoje.getUTCDate(),
  )));

  for (let dia = 1; dia <= ultimo; dia++) {
    const d = new Date(Date.UTC(ano, mes, dia));
    const k = chave(d);
    const semana = d.getUTCDay();

    const ehFeriado = feriados.has(k);
    if (ehFeriado && semana !== 0 && semana !== 6) feriadosNoMes.push(k);

    const ehFimDeSemana = semana === 0 || (semana === 6 && !sabadoUtil);
    if (ehFimDeSemana || ehFeriado) continue;

    uteis++;
    if (k >= hojeChave) restantes++;
  }

  return { uteis, restantes, decorridos: uteis - restantes, feriadosNoMes };
}

/**
 * Quanto falta por dia útil para bater a meta.
 *
 * Devolve `null` quando não há mais dia útil no mês: dividir por zero daria
 * `Infinity`, e a tela mostraria "R$ Infinity por dia", que é pior que não
 * mostrar nada.
 *
 * Meta já batida devolve **zero**, e não um número negativo. Negativo lido às
 * pressas parece dívida; zero diz a verdade, que é "não falta nada".
 */
export function porDiaUtil(
  meta: number,
  realizado: number,
  diasRestantes: number,
): number | null {
  if (diasRestantes <= 0) return null;
  const falta = meta - realizado;
  if (falta <= 0) return 0;
  return falta / diasRestantes;
}

/**
 * O quanto do mês já passou, em dias úteis, de 0 a 1.
 *
 * Serve para a tela dizer se o realizado está no ritmo: 40% do mês decorrido
 * com 20% da meta batida é atraso, e o número sozinho não conta isso.
 */
export function ritmoEsperado(dias: DiasDoMes): number {
  if (dias.uteis === 0) return 0;
  return dias.decorridos / dias.uteis;
}
