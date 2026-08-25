"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

/**
 * SPEC 001 / T024 — as ações da seção Perfis.
 *
 * # A regra que desenha esta tela inteira
 *
 * Existem exatamente **duas** ações, e a terceira que faltaria não existe de
 * propósito: **não há caminho aqui para definir a senha de ninguém.** A action
 * `set_password` foi removida da edge function no porte (Princípio II, regra
 * (e)), e o audit log do MVP tem uma linha de `password set` de 28/07 que é
 * justamente a falha que essa remoção fecha.
 *
 * O que sobra é o que pode existir: trocar o e-mail, que fica auditado com o
 * diff, e disparar o e-mail de recuperação, para a pessoa escolher a própria
 * senha.
 *
 * # Por que a troca de e-mail pede confirmação
 *
 * Trocar o e-mail troca a credencial de acesso da pessoa. Errar o campo tira o
 * cliente de dentro da própria conta, e o caminho de volta é o suporte. A
 * confirmação existe por isso, e não por cerimônia.
 */
/**
 * `emailAtual` é opcional, e a ausência dele é a regra, não a exceção.
 *
 * O e-mail vive em `auth.users`, que **não é legível** por uma sessão de
 * usuário, nem pelo superadmin: só a service role alcança. Quem resolve o
 * e-mail é a própria edge function, no servidor, na hora de agir. Trazer isso
 * para a tela exigiria expor `auth.users` por uma RPC, e expor a tabela de
 * autenticação para melhorar um rótulo é uma troca ruim.
 *
 * Então a tela trabalha sem o e-mail e diz isso, em vez de mostrar campo vazio
 * fingindo que carregou.
 */
export function AcoesDePerfil({
  userId,
  emailAtual,
}: {
  userId: string;
  emailAtual?: string;
}) {
  const [novoEmail, setNovoEmail] = useState("");
  const [confirmando, setConfirmando] = useState(false);
  const [ocupado, setOcupado] = useState<null | "email" | "reset">(null);
  const [aviso, setAviso] = useState<{ tipo: "ok" | "erro"; texto: string } | null>(
    null,
  );
  const router = useRouter();

  async function chamar(corpo: Record<string, unknown>) {
    const supabase = createClient();
    const { data, error } = await supabase.functions.invoke(
      "superadmin-manage-user",
      { body: corpo },
    );
    if (error) throw new Error(error.message);
    if (data && typeof data === "object" && "error" in data) {
      throw new Error(String((data as { error: unknown }).error));
    }
  }

  async function trocarEmail() {
    setOcupado("email");
    setAviso(null);
    try {
      await chamar({
        action: "update_email",
        user_id: userId,
        new_email: novoEmail,
      });
      setAviso({
        tipo: "ok",
        texto: "E-mail trocado. A mudança ficou registrada no log de auditoria.",
      });
      setNovoEmail("");
      setConfirmando(false);
      router.refresh();
    } catch (e) {
      setAviso({ tipo: "erro", texto: (e as Error).message });
    } finally {
      setOcupado(null);
    }
  }

  async function enviarReset() {
    setOcupado("reset");
    setAviso(null);
    try {
      await chamar({ action: "send_password_reset", user_id: userId });
      setAviso({
        tipo: "ok",
        texto:
          "E-mail de recuperacao enviado para o endereco cadastrado" +
          (emailAtual ? " (" + emailAtual + ")" : "") +
          ". Quem define a senha e a propria pessoa.",
      });
      router.refresh();
    } catch (e) {
      setAviso({ tipo: "erro", texto: (e as Error).message });
    } finally {
      setOcupado(null);
    }
  }

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <label htmlFor={"email-" + userId} className="block text-xs text-slate-400">
          Novo e-mail
        </label>
        <div className="flex flex-wrap gap-2">
          <input
            id={"email-" + userId}
            type="email"
            value={novoEmail}
            onChange={(e) => {
              setNovoEmail(e.target.value);
              setConfirmando(false);
            }}
            placeholder={emailAtual ?? "e-mail atual guardado na autenticacao"}
            className="min-w-64 flex-1 rounded-md border border-white/15 bg-slate-950 px-3 py-1.5 text-sm outline-none focus:border-blue-500"
          />
          {!confirmando ? (
            <button
              type="button"
              disabled={!novoEmail || novoEmail === emailAtual || ocupado !== null}
              onClick={() => setConfirmando(true)}
              className="rounded-md border border-white/15 px-3 py-1.5 text-sm hover:bg-white/5 disabled:opacity-40"
            >
              Trocar e-mail
            </button>
          ) : (
            <>
              <button
                type="button"
                disabled={ocupado !== null}
                onClick={trocarEmail}
                className="rounded-md bg-amber-500 px-3 py-1.5 text-sm font-medium text-slate-950 disabled:opacity-60"
              >
                {ocupado === "email" ? "Trocando..." : "Confirmar troca"}
              </button>
              <button
                type="button"
                onClick={() => setConfirmando(false)}
                className="rounded-md border border-white/15 px-3 py-1.5 text-sm hover:bg-white/5"
              >
                Cancelar
              </button>
            </>
          )}
        </div>
        {confirmando && (
          <p className="text-xs text-amber-400">
            Isto troca a credencial de acesso da pessoa para {novoEmail}. Ela
            passa a entrar com o e-mail novo, e o e-mail anterior deixa de
            funcionar. A mudanca fica registrada no log com o valor antigo.
          </p>
        )}
      </div>

      <div>
        <button
          type="button"
          disabled={ocupado !== null}
          onClick={enviarReset}
          className="rounded-md border border-white/15 px-3 py-1.5 text-sm hover:bg-white/5 disabled:opacity-40"
        >
          {ocupado === "reset" ? "Enviando..." : "Enviar recuperação de senha"}
        </button>
        <p className="mt-1 text-xs text-slate-500">
          Não existe, e não vai existir, botão para definir a senha de um
          cliente. A pessoa define a própria senha pelo link que chega no e-mail.
        </p>
      </div>

      {aviso && (
        <p
          role="status"
          className={
            aviso.tipo === "ok"
              ? "text-sm text-emerald-400"
              : "text-sm text-red-400"
          }
        >
          {aviso.texto}
        </p>
      )}
    </div>
  );
}
