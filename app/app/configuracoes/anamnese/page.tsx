import Link from "next/link";

import { RequirePermission } from "@/lib/auth/guards";
import { createClient } from "@/lib/supabase/server";
import { camposAtivos, normalizaParaSecoes, problemasDoModelo } from "@/lib/config/anamnese";
import { AnamneseForm, type ModeloCru } from "./anamnese-form";

/**
 * SPEC 005 / T015 — modelos de anamnese.
 *
 * O mais caro dos catálogos, e não por causa da tela: `anamnesis_config.fields`
 * é `jsonb` livre e guarda **duas formas diferentes**, conforme a época em que
 * a linha foi criada. A leitura aceita as duas, a escrita grava só a nova, e o
 * modelo se converte sozinho no primeiro salvamento. Sem migração de dado.
 *
 * A tela lista com o diagnóstico na frente: quantos campos o paciente vê, e o
 * que impediria o modelo de funcionar na mão dele.
 */
export default async function AnamnesePage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from("anamnesis_config")
    .select("id, title, specialty, fields, is_default, active")
    .order("is_default", { ascending: false });

  const modelos = (data ?? []) as unknown as ModeloCru[];

  return (
    <RequirePermission module="configuracoes">
      <div className="space-y-6">
        <div>
          <Link href="/app/configuracoes" className="text-sm text-[#1F8C8C] hover:underline">
            Configurações
          </Link>
          <h1 className="mt-1 text-2xl font-semibold">Modelos de anamnese</h1>
          <p className="mt-1 max-w-2xl text-sm text-[#3A4A5C]">
            O que o paciente responde antes da consulta. Um modelo é o padrão, e
            é ele que a consulta oferece quando ninguém escolhe outro.
          </p>
          <p className="mt-2 max-w-2xl text-xs text-[#3A4A5C]/80">
            <span className="font-medium">Usado em:</span> Anamnese, Consultas
          </p>
        </div>

        {modelos.length === 0 ? (
          <p className="rounded-lg border border-[#3A4A5C]/15 bg-white p-5 text-sm text-[#3A4A5C]">
            Nenhum modelo cadastrado. Sem modelo, a clínica não tem o que enviar
            ao paciente antes da consulta.
          </p>
        ) : (
          <ul className="grid gap-3">
            {modelos.map((m) => {
              const secoes = normalizaParaSecoes(m.fields);
              const problemas = problemasDoModelo(secoes);
              return (
                <li
                  key={m.id}
                  className="rounded-lg border border-[#3A4A5C]/15 bg-white p-4"
                >
                  <div className="flex flex-wrap items-baseline justify-between gap-2">
                    <div className="font-medium">
                      {m.title || "(sem título)"}
                      {m.is_default && (
                        <span className="ml-2 rounded bg-[#1F8C8C]/10 px-2 py-0.5 text-xs text-[#1F8C8C]">
                          padrão
                        </span>
                      )}
                    </div>
                    <div className="text-xs text-[#3A4A5C]">
                      {camposAtivos(secoes)} campo(s) ativo(s) em {secoes.length} seção(ões)
                      {m.specialty ? ` · ${m.specialty}` : ""}
                    </div>
                  </div>

                  {problemas.length > 0 && (
                    <ul className="mt-2 space-y-1">
                      {problemas.map((p, i) => (
                        <li key={i} className="text-xs text-amber-700">
                          <span className="font-medium">{p.onde}:</span> {p.mensagem}
                        </li>
                      ))}
                    </ul>
                  )}
                </li>
              );
            })}
          </ul>
        )}

        <AnamneseForm modelos={modelos} />
      </div>
    </RequirePermission>
  );
}
