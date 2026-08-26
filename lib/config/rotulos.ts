/**
 * SPEC 005 / T011 — os rótulos humanos dos campos obrigatórios.
 *
 * # Por que isto existe em vez de a tela chamar `name` de "name"
 *
 * A regra do `app.md` é explícita: *"rótulo de enum nunca vai cru para a tela"*.
 * Ela rastreia a uma dívida real da referência, onde `confirmacao` aparecia
 * assim mesmo para o usuário.
 *
 * Aqui o risco é maior que feio: a pessoa está decidindo o que passa a ser
 * **obrigatório** no cadastro de paciente. Marcar `zip_code` sem saber que é o
 * CEP é decidir no escuro, e o efeito aparece uma semana depois, quando a
 * recepção não consegue salvar ninguém.
 *
 * # Por que um `Record` completo e não um `Partial`
 *
 * O tipo obriga a lista a cobrir **todas** as chaves. Campo novo em
 * `CAMPOS_DE_PACIENTE` sem rótulo aqui é erro de compilação, e não um `name`
 * cru vazando para a tela meses depois. É o mesmo padrão das 15 ModuleKeys.
 */

import type { CampoDeAgendamento, CampoDePaciente } from "./regras";

export const ROTULO_DE_CAMPO_DE_PACIENTE: Record<CampoDePaciente, string> = {
  name: "Nome",
  phone: "Telefone",
  email: "E-mail",
  birth_date: "Data de nascimento",
  cpf: "CPF",
  gender: "Sexo",
  address: "Endereço",
  city: "Cidade",
  state: "Estado",
  zip_code: "CEP",
  channel_id: "Canal",
  origin_id: "Origem",
};

export const ROTULO_DE_CAMPO_DE_AGENDAMENTO: Record<CampoDeAgendamento, string> = {
  patient_id: "Paciente",
  date: "Data",
  time: "Horário",
  doctor: "Profissional",
  consultation_type_id: "Tipo de consulta",
  channel_id: "Canal",
  origin_id: "Origem",
  notes: "Observações",
};
