/**
 * SPEC 003 — o núcleo puro da assinatura: estado e data de cobrança.
 *
 * # Por que isto é um arquivo puro e separado das telas
 *
 * O painel precisa decidir duas coisas que erram em silêncio: **qual mudança de
 * status é permitida** e **quando cai a próxima cobrança**. As duas são regra e
 * aritmética, e o Princípio IX manda simular aritmética antes de declarar
 * certa. Numa server action isso não se testa sem banco; aqui se testa.
 *
 * A segunda tem uma armadilha de calendário que só aparece em fevereiro, e é
 * exatamente o tipo de coisa que ninguém descobre até a primeira cobrança
 * pular um mês. Ver `proximaCobranca`.
 */

export const STATUS_DE_ASSINATURA = [
  "trial",
  "active",
  "overdue",
  "suspended",
  "cancelled",
] as const;

export type StatusDeAssinatura = (typeof STATUS_DE_ASSINATURA)[number];

export const ROTULO_DE_STATUS: Record<StatusDeAssinatura, string> = {
  trial: "Em teste",
  active: "Ativa",
  overdue: "Em atraso",
  suspended: "Suspensa",
  cancelled: "Cancelada",
};

/**
 * Para onde cada status pode ir.
 *
 * # As duas decisões que esta tabela toma
 *
 * **`cancelled` não sai de lugar nenhum.** Cancelamento é fim de relação, e
 * reativar por engano uma conta cancelada devolveria acesso a quem pediu para
 * sair. Voltar exige criar assinatura nova, que é um ato deliberado e deixa
 * rastro próprio.
 *
 * **`trial` não vai direto para `suspended`.** Suspender é punição por não
 * pagamento, e quem está em teste ainda não devia nada. Trial que acaba vira
 * `overdue` (cobrança devida) ou `cancelled` (desistiu), e a §3.3 do
 * `CLAUDE.md` registra que trial vencido não suspende sozinho.
 */
export const TRANSICOES: Record<StatusDeAssinatura, readonly StatusDeAssinatura[]> = {
  trial: ["active", "overdue", "cancelled"],
  active: ["overdue", "suspended", "cancelled"],
  overdue: ["active", "suspended", "cancelled"],
  suspended: ["active", "cancelled"],
  cancelled: [],
};

export function ehStatus(valor: unknown): valor is StatusDeAssinatura {
  return typeof valor === "string" &&
    (STATUS_DE_ASSINATURA as readonly string[]).includes(valor);
}

/**
 * Se a mudança de status é permitida.
 *
 * Ficar no mesmo status é permitido: salvar o formulário sem mexer no status
 * não pode virar erro, senão editar a data de cobrança exigiria mudar o estado
 * da conta junto.
 */
export function podeTransicionar(
  de: StatusDeAssinatura,
  para: StatusDeAssinatura,
): boolean {
  if (de === para) return true;
  return TRANSICOES[de].includes(para);
}

/** Quantos dias tem o mês. Fevereiro de ano bissexto inclusive. */
export function diasNoMes(ano: number, mes: number): number {
  // Dia 0 do mês seguinte é o último dia deste. `Date.UTC` para o resultado não
  // depender do fuso da máquina que roda o servidor.
  return new Date(Date.UTC(ano, mes + 1, 0)).getUTCDate();
}

/**
 * O dia do mês em que a conta é cobrada, normalizado.
 *
 * Aceita 1 a 31. Fora disso, ou lixo, devolve `null`, e quem chama trata como
 * campo não informado. Não existe "corrigir para o mais próximo" aqui: dia 45
 * é digitação errada, e adivinhar 4 ou 5 seria escolher a data de cobrança de
 * um cliente por conta própria.
 */
export function normalizaDiaDeCobranca(valor: unknown): number | null {
  const n = Math.floor(Number(valor));
  if (!Number.isFinite(n) || n < 1 || n > 31) return null;
  return n;
}

/**
 * A próxima data de cobrança, a partir de um dia do mês escolhido.
 *
 * # A armadilha de calendário, e por que ela precisa de teste
 *
 * Uma conta cobrada **dia 31** não pode ser cobrada em fevereiro, que não tem
 * dia 31. O caminho ingênuo, `new Date(ano, mes, 31)`, **transborda para março**
 * em silêncio: o JavaScript aceita e ajusta. O efeito é a fatura de fevereiro
 * sumir e duas caírem em março.
 *
 * A regra aqui: o dia é **grampeado ao último dia do mês**. Dia 31 em fevereiro
 * vira 28, ou 29 em ano bissexto. É o que faturamento faz na vida real, e é
 * previsível: a conta nunca pula um mês.
 *
 * # Por que "próxima" e não "esta"
 *
 * Se o dia escolhido ainda não passou neste mês, a cobrança é neste mês. Se já
 * passou, é no mês que vem. Marcar para uma data no passado criaria uma fatura
 * nascida vencida.
 *
 * `agora` é parâmetro, e não `new Date()` lá dentro, porque função que lê o
 * relógio não se testa.
 */
export function proximaCobranca(dia: number, agora: Date): Date {
  const ano = agora.getUTCFullYear();
  const mes = agora.getUTCMonth();
  const hoje = agora.getUTCDate();

  const diaNesteMes = Math.min(dia, diasNoMes(ano, mes));

  if (hoje <= diaNesteMes) {
    return new Date(Date.UTC(ano, mes, diaNesteMes));
  }

  // Mês seguinte. `mes + 1` com dezembro vira janeiro do ano seguinte sozinho,
  // e `Date.UTC` resolve a virada sem conta de ano na mão.
  const proximoAno = new Date(Date.UTC(ano, mes + 1, 1)).getUTCFullYear();
  const proximoMes = new Date(Date.UTC(ano, mes + 1, 1)).getUTCMonth();
  return new Date(
    Date.UTC(proximoAno, proximoMes, Math.min(dia, diasNoMes(proximoAno, proximoMes))),
  );
}

/** O dia do mês de uma data de cobrança já gravada, para a tela mostrar. */
export function diaDaCobranca(iso: string | null | undefined): number | null {
  if (!iso) return null;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d.getUTCDate();
}

/**
 * O preço mensal, em número, a partir do que foi digitado.
 *
 * Reaproveita o interpretador da SPEC 005 em vez de escrever outro: o defeito
 * do `Number("1.234")` valendo 1,234 é o mesmo aqui, e num campo de mensalidade
 * ele cobra R$ 1,23 no lugar de R$ 1.234,00.
 */
export { interpretaNumero } from "@/lib/config/entrada";
