"use client";

import Link from "next/link";
import { useState, useTransition } from "react";

import { criarConta } from "@/lib/superadmin/acoes";
import { ROTULO_DE_STATUS } from "@/lib/superadmin/assinatura";
import { Aviso, Botao, Campo, Selecao } from "../../_ui/formulario";

export interface PlanoParaEscolher {
  id: string;
  name: string;
  monthly_price: number | null;
  trial_days: number | null;
}

export function NovaContaForm({ planos }: { planos: PlanoParaEscolher[] }) {
  const [aviso, setAviso] = useState<string | null>(null);
  const [criada, setCriada] = useState<string | null>(null);
  const [criando, iniciar] = useTransition();

  function enviar(form: FormData) {
    iniciar(async () => {
      const r = await criarConta(form);
      if (r.ok && r.clinicId) {
        setAviso(null);
        setCriada(r.clinicId);
        return;
      }
      setAviso(r.mensagem ?? "Não foi possível criar a conta.");
    });
  }

  if (criada) {
    return (
      <div className="space-y-4 rounded-lg border border-emerald-500/30 bg-slate-900 p-5">
        <Aviso tom="ok">Conta criada, com plano e data de cobrança.</Aviso>

        <div className="space-y-2 text-sm text-slate-300">
          <p className="font-medium">Falta o login do dono, e são dois cliques:</p>
          <ol className="ml-5 list-decimal space-y-1 text-slate-400">
            <li>Abra a conta e clique em <strong>Entrar na conta</strong>.</li>
            <li>
              Na tela de Equipe, envie o convite para o e-mail do responsável.
              Ele define a própria senha pelo link, e ninguém define senha por
              ele.
            </li>
            <li>Volte, e clique em sair do modo suporte.</li>
          </ol>
          <p className="text-xs text-slate-500">
            O convite herda a clínica de quem está dentro dela, e é por isso que
            este passo não pôde ser feito na tela anterior. A alternativa seria
            aceitar a clínica por parâmetro, que é a porta que essa guarda
            fecha.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <Link
            href={`/superadmin/contas/${criada}`}
            className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-500"
          >
            Abrir a conta
          </Link>
          <button
            type="button"
            onClick={() => setCriada(null)}
            className="text-sm text-slate-400 hover:underline"
          >
            Criar outra
          </button>
        </div>
      </div>
    );
  }

  const preco = (p: PlanoParaEscolher) =>
    p.monthly_price === null || p.monthly_price === undefined
      ? p.name
      : `${p.name} · ${Number(p.monthly_price).toLocaleString("pt-BR", {
          style: "currency",
          currency: "BRL",
        })} por mês`;

  return (
    <form action={enviar} className="space-y-5 rounded-lg border border-white/10 bg-slate-900 p-5">
      <div className="grid gap-4 sm:grid-cols-2">
        <Campo nome="name" rotulo="Nome da clínica" obrigatorio />
        <Campo nome="owner_name" rotulo="Nome do responsável" obrigatorio />
        <Campo
          nome="owner_email"
          rotulo="E-mail do responsável"
          tipo="email"
          nota="É para onde o convite vai. Pode ficar em branco agora e ser preenchido depois."
        />

        <Selecao
          nome="plan_id"
          rotulo="Plano"
          opcoes={[
            { valor: "", rotulo: "Sem plano" },
            ...planos.map((p) => ({ valor: p.id, rotulo: preco(p) })),
          ]}
          nota="O plano é o teto de acesso. Sem plano, todo módulo fica bloqueado."
        />

        <Selecao
          nome="status"
          rotulo="Situação inicial"
          valor="trial"
          opcoes={(["trial", "active", "overdue"] as const).map((s) => ({
            valor: s,
            rotulo: ROTULO_DE_STATUS[s],
          }))}
          nota="Conta nova não nasce suspensa nem cancelada: isso deixaria o cliente sem acesso na hora em que ele mais espera ter."
        />

        <Campo
          nome="trial_days"
          rotulo="Dias de teste"
          valor={14}
          tipo="number"
          nota="Só vale quando a situação inicial é Em teste."
        />

        <Campo
          nome="dia_de_cobranca"
          rotulo="Dia de cobrança"
          tipo="number"
          placeholder="1 a 31"
          nota="Dia 31 em fevereiro cai no último dia do mês, e a conta nunca pula uma cobrança."
        />
      </div>

      {aviso && <Aviso tom="erro">{aviso}</Aviso>}

      <Botao ocupado={criando}>Criar conta</Botao>
    </form>
  );
}
