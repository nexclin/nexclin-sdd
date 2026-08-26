"use client";

/**
 * SPEC 003 — plano, situação e data de cobrança de uma conta.
 *
 * # Por que os três num formulário só
 *
 * Do ponto de vista de quem opera, é um ato: *"põe o cliente no plano Pro,
 * ativo, cobrando dia 10"*. Três botões separados criariam estados
 * intermediários que ninguém quis, como conta ativa sem plano, ou plano
 * atribuído sem data de cobrança.
 *
 * # As transições proibidas somem da lista, e a tela diz por quê
 *
 * `TRANSICOES` decide, e o mesmo módulo é consultado pela server action. A tela
 * é o reflexo, e a recusa mora no servidor: esconder a opção é conveniência,
 * não fronteira.
 */

import { useState, useTransition } from "react";

import { salvarAssinatura } from "@/lib/superadmin/acoes";
import {
  ROTULO_DE_STATUS,
  STATUS_DE_ASSINATURA,
  TRANSICOES,
  diaDaCobranca,
  ehStatus,
  type StatusDeAssinatura,
} from "@/lib/superadmin/assinatura";
import { Aviso, Botao, Campo, Selecao } from "../../_ui/formulario";

export interface AssinaturaEditavel {
  id?: string | null;
  clinic_id: string;
  plan_id?: string | null;
  status?: string | null;
  current_period_end?: string | null;
}

export interface PlanoDisponivel {
  id: string;
  name: string;
  monthly_price: number | null;
}

export function AssinaturaForm({
  assinatura,
  planos,
}: {
  assinatura: AssinaturaEditavel;
  planos: PlanoDisponivel[];
}) {
  const [aviso, setAviso] = useState<string | null>(null);
  const [salvo, setSalvo] = useState(false);
  const [salvando, iniciar] = useTransition();

  const atual: StatusDeAssinatura = ehStatus(assinatura.status)
    ? (assinatura.status as StatusDeAssinatura)
    : "trial";

  const permitidos = [atual, ...TRANSICOES[atual]];
  const dia = diaDaCobranca(assinatura.current_period_end);

  function enviar(form: FormData) {
    iniciar(async () => {
      setSalvo(false);
      const r = await salvarAssinatura(form);
      if (r.ok) {
        setAviso(null);
        setSalvo(true);
        return;
      }
      setAviso(r.mensagem ?? "Não foi possível salvar.");
    });
  }

  const preco = (p: PlanoDisponivel) =>
    p.monthly_price === null || p.monthly_price === undefined
      ? p.name
      : `${p.name} · ${Number(p.monthly_price).toLocaleString("pt-BR", {
          style: "currency",
          currency: "BRL",
        })} por mês`;

  return (
    <form action={enviar} className="space-y-4 rounded-lg border border-white/10 bg-slate-900 p-5">
      <h2 className="font-semibold">Plano, situação e cobrança</h2>

      <input type="hidden" name="clinic_id" value={assinatura.clinic_id} />
      <input type="hidden" name="id" value={assinatura.id ?? ""} />
      <input type="hidden" name="status_atual" value={atual} />

      <div className="grid gap-4 sm:grid-cols-2">
        <Selecao
          nome="plan_id"
          rotulo="Plano"
          valor={assinatura.plan_id ?? ""}
          opcoes={[
            { valor: "", rotulo: "Sem plano" },
            ...planos.map((p) => ({ valor: p.id, rotulo: preco(p) })),
          ]}
          nota="O plano é o teto de acesso. Sem plano, a cascata devolve none em todo módulo."
        />

        <Selecao
          nome="status"
          rotulo="Situação"
          valor={atual}
          opcoes={STATUS_DE_ASSINATURA.filter((s) => permitidos.includes(s)).map((s) => ({
            valor: s,
            rotulo: ROTULO_DE_STATUS[s],
          }))}
          nota={
            atual === "cancelled"
              ? "Conta cancelada não é reativada. Voltar exige assinatura nova, que é ato próprio e deixa rastro."
              : "Só aparecem as mudanças permitidas a partir da situação atual."
          }
        />

        <Campo
          nome="dia_de_cobranca"
          rotulo="Dia de cobrança"
          valor={dia ?? ""}
          tipo="number"
          placeholder="1 a 31"
          nota="Dia 31 em fevereiro cai no último dia do mês, e a conta nunca pula uma cobrança."
        />

        <Campo
          nome="motivo"
          rotulo="Motivo"
          nota="Vai para a auditoria e para a linha do tempo. Obrigatório na prática ao cancelar."
        />
      </div>

      {aviso && <Aviso tom="erro">{aviso}</Aviso>}
      {salvo && <Aviso tom="ok">Assinatura atualizada, e a mudança está na linha do tempo.</Aviso>}

      <Botao ocupado={salvando}>Salvar</Botao>
    </form>
  );
}
