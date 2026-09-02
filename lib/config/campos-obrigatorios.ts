/**
 * O par (catálogo, piso) de campos obrigatórios, fixado num lugar só.
 *
 * Regra 005, FR-010: *"os formulários dos módulos posteriores MUST obedecê-los
 * sem lista fixa em código. Porquê: lista fixa em código transforma
 * configuração em mentira: a tela oferece a escolha e o formulário ignora."*
 *
 * `normalizaCamposObrigatorios` em `regras.ts` recebe três argumentos, e dois
 * deles andam sempre juntos: o catálogo da entidade e o piso da entidade. Antes
 * deste arquivo esse par aparecia escrito à mão em quatro lugares, e um
 * catálogo novo obrigaria a lembrar dos quatro. Aqui ele é escrito uma vez.
 *
 * Não é invólucro decorativo: `acoes.ts` grava por estas funções, e a tela de
 * regras lê por elas. Quem chamar a normalização crua com o trio à mão está
 * repetindo o que já está resolvido.
 *
 * **O que este arquivo NÃO faz, e não deve fazer:** validar cadastro. Isso é do
 * módulo que tiver o formulário, e ele usa `camposFaltando` de `regras.ts` com
 * a lista que estas funções devolvem. O FR-010 pede que o formulário obedeça à
 * configuração, não que este arquivo saiba o que é um paciente válido.
 */

import {
  CAMPOS_DE_AGENDAMENTO,
  CAMPOS_DE_PACIENTE,
  PISO_AGENDAMENTO,
  PISO_PACIENTE,
  normalizaCamposObrigatorios,
  type CampoDeAgendamento,
  type CampoDePaciente,
} from "./regras";

/**
 * Normaliza um valor cru de `patient_required_fields`.
 *
 * Serve para os dois sentidos: o que veio do formulário, no salvamento, e o que
 * veio da coluna `jsonb`, na leitura. Nos dois casos o valor é `unknown`, e nos
 * dois o piso volta.
 */
export function normalizaCamposDePaciente(valor: unknown): CampoDePaciente[] {
  return normalizaCamposObrigatorios(valor, CAMPOS_DE_PACIENTE, PISO_PACIENTE);
}

/** O mesmo para `appointment_required_fields`. */
export function normalizaCamposDeAgendamento(valor: unknown): CampoDeAgendamento[] {
  return normalizaCamposObrigatorios(
    valor,
    CAMPOS_DE_AGENDAMENTO,
    PISO_AGENDAMENTO,
  );
}
