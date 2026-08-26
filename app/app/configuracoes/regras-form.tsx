"use client";

/**
 * SPEC 005 / T011 — a tela de regras de negócio.
 *
 * # O que esta tela decide, e por que ela é a mais perigosa das configurações
 *
 * As outras telas de configuração enchem listas. Esta muda o comportamento de
 * módulos que ainda nem foram escritos: `followup_days`, `recall_days` e
 * `recapture_days` decidem quando a esteira de tarefas dispara, e
 * `patient_required_fields` decide se a recepção consegue salvar um cadastro.
 *
 * Daí duas escolhas de desenho:
 *
 * 1. **Cada campo diz o que acontece quando muda**, no mesmo espírito do
 *    "usado em" dos catálogos. Número sem consequência declarada é número que
 *    ninguém ajusta, ou que alguém ajusta sem saber o que quebrou.
 * 2. **O piso aparece marcado e desabilitado**, não escondido. Esconder faria
 *    parecer que o nome do paciente é opcional; mostrar travado ensina a regra.
 */

import { useState, useTransition } from "react";

import { salvarRegras } from "@/lib/config/acoes";
import {
  CAMPOS_DE_AGENDAMENTO,
  CAMPOS_DE_PACIENTE,
  PISO_AGENDAMENTO,
  PISO_PACIENTE,
  horasParaDias,
} from "@/lib/config/regras";
// `import type` e apagado na compilacao, entao o modulo de servidor (que
// importa `next/headers`) nao entra no pacote do cliente.
import type { RegrasDaClinica } from "@/lib/config/servidor";
import {
  ROTULO_DE_CAMPO_DE_AGENDAMENTO,
  ROTULO_DE_CAMPO_DE_PACIENTE,
} from "@/lib/config/rotulos";

/** As listas jsonb chegam como `unknown`. Só interessa o que é string. */
function comoLista(valor: unknown): string[] {
  return Array.isArray(valor) ? valor.filter((v): v is string => typeof v === "string") : [];
}

export function RegrasForm({ regras }: { regras: RegrasDaClinica }) {
  const [salvando, iniciar] = useTransition();
  const [aviso, setAviso] = useState<string | null>(null);
  const [salvo, setSalvo] = useState(false);

  const doPaciente = comoLista(regras.patient_required_fields);
  const doAgendamento = comoLista(regras.appointment_required_fields);

  function enviar(form: FormData) {
    iniciar(async () => {
      setSalvo(false);
      const r = await salvarRegras(form);
      if (r.ok) {
        setAviso(null);
        setSalvo(true);
        return;
      }
      setAviso(r.mensagem ?? "Não foi possível salvar.");
    });
  }

  return (
    <form action={enviar} className="space-y-6 rounded-lg border border-[#3A4A5C]/15 bg-white p-5">
      <input type="hidden" name="id" value={regras.id ?? ""} />

      <section>
        <h3 className="mb-3 text-sm font-medium uppercase tracking-wide text-[#3A4A5C]">
          Prazos da esteira
        </h3>
        <div className="grid gap-4 sm:grid-cols-2">
          <Dias
            nome="confirmation_days"
            rotulo="Confirmar a consulta com antecedência de"
            /* Exibido em dias, armazenado em horas. A conversão é única e tem a
               ida e volta testada de 1 a 30 dias; aqui só se chama. */
            valor={horasParaDias(regras.confirmation_hours)}
            efeito="Decide quando a tarefa de confirmação aparece antes da consulta."
          />
          <Dias
            nome="followup_days"
            rotulo="Follow-up após"
            valor={regras.followup_days}
            efeito="Dias após o atendimento para a tarefa de retorno de contato."
          />
          <Dias
            nome="recapture_days"
            rotulo="Recaptação após"
            valor={regras.recapture_days}
            efeito="Dias de silêncio até o paciente ou lead entrar na esteira de recaptação."
          />
          <Dias
            nome="recall_days"
            rotulo="Recall após"
            valor={regras.recall_days}
            efeito="O ciclo de retorno da especialidade. Em odontologia costuma ser 180 dias."
          />
          <Dias
            nome="satisfaction_survey_days"
            rotulo="Pesquisa de satisfação após"
            valor={regras.satisfaction_survey_days}
            efeito="Dias após o atendimento para pedir a avaliação."
          />
          <Dias
            nome="anamnesis_send_days"
            rotulo="Enviar anamnese com"
            valor={regras.anamnesis_send_days}
            efeito="Dias de antecedência para mandar o link da anamnese ao paciente."
          />
        </div>

        <label className="mt-4 flex items-start gap-2 text-sm">
          <input
            type="checkbox"
            name="work_saturday"
            defaultChecked={regras.work_saturday}
            className="mt-0.5 h-4 w-4"
          />
          <span>
            A clínica atende aos sábados
            <span className="block text-xs text-[#3A4A5C]/80">
              Decide se a tarefa cai no sábado ou é empurrada para o dia útil
              seguinte. Desmarcado, nenhuma tarefa vence num sábado.
            </span>
          </span>
        </label>
      </section>

      <section>
        <h3 className="mb-1 text-sm font-medium uppercase tracking-wide text-[#3A4A5C]">
          Campos obrigatórios no cadastro de paciente
        </h3>
        <p className="mb-3 text-xs text-[#3A4A5C]">
          Marcar aqui impede o salvamento sem o campo. Exigir demais faz a
          recepção deixar o cadastro para depois, e o cadastro para depois não
          acontece.
        </p>
        <Marcadores
          nome="patient_required_fields"
          campos={CAMPOS_DE_PACIENTE}
          rotulos={ROTULO_DE_CAMPO_DE_PACIENTE}
          marcados={doPaciente}
          piso={PISO_PACIENTE}
        />
      </section>

      <section>
        <h3 className="mb-1 text-sm font-medium uppercase tracking-wide text-[#3A4A5C]">
          Campos obrigatórios no agendamento
        </h3>
        <Marcadores
          nome="appointment_required_fields"
          campos={CAMPOS_DE_AGENDAMENTO}
          rotulos={ROTULO_DE_CAMPO_DE_AGENDAMENTO}
          marcados={doAgendamento}
          piso={PISO_AGENDAMENTO}
        />
      </section>

      {aviso && (
        <p className="rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-800">
          {aviso}
        </p>
      )}
      {salvo && (
        <p className="rounded border border-[#1F8C8C]/40 bg-[#1F8C8C]/5 px-3 py-2 text-sm text-[#1F8C8C]">
          Regras salvas.
          {regras.id === null && " A clínica passou a ter regras próprias."}
        </p>
      )}

      <button
        type="submit"
        disabled={salvando}
        className="rounded-lg bg-[#1F8C8C] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#1F8C8C]/90 disabled:opacity-60"
      >
        {salvando ? "Salvando..." : "Salvar regras"}
      </button>
    </form>
  );
}

function Dias({
  nome,
  rotulo,
  valor,
  efeito,
}: {
  nome: string;
  rotulo: string;
  valor: number;
  efeito: string;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={nome} className="text-sm text-[#3A4A5C]">
        {rotulo}
      </label>
      <div className="flex items-center gap-2">
        <input
          id={nome}
          name={nome}
          type="number"
          min={0}
          max={365}
          defaultValue={valor}
          className="w-24 rounded-lg border border-[#3A4A5C]/25 px-3 py-2 text-sm"
        />
        <span className="text-sm text-[#3A4A5C]">dia(s)</span>
      </div>
      <p className="text-xs text-[#3A4A5C]/80">{efeito}</p>
    </div>
  );
}

function Marcadores<T extends string>({
  nome,
  campos,
  rotulos,
  marcados,
  piso,
}: {
  nome: string;
  campos: readonly T[];
  rotulos: Record<T, string>;
  marcados: string[];
  piso: readonly T[];
}) {
  return (
    <ul className="grid gap-2 sm:grid-cols-3">
      {campos.map((campo) => {
        const noPiso = piso.includes(campo);
        return (
          <li key={campo}>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                name={nome}
                value={campo}
                defaultChecked={noPiso || marcados.includes(campo)}
                /* Caixa desabilitada nao e enviada pelo formulario, e esta
                   tudo bem: `normalizaCamposObrigatorios` reaplica o piso no
                   servidor. A tela mostra a regra; quem a garante e a funcao
                   pura, testada. Se dependesse do envio, bastaria o navegador
                   omitir o campo para o nome do paciente virar opcional. */
                disabled={noPiso}
                className="h-4 w-4"
              />
              <span className={noPiso ? "text-[#3A4A5C]" : undefined}>
                {rotulos[campo]}
                {noPiso && (
                  <span
                    className="ml-1 text-xs text-[#3A4A5C]/70"
                    title="O sistema exige este campo. Sem ele o registro não identifica ninguém."
                  >
                    sempre
                  </span>
                )}
              </span>
            </label>
          </li>
        );
      })}
    </ul>
  );
}
