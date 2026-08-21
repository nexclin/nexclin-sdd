"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import type { ModuleKey } from "./modulos";
import { NEGADO, resolverAcesso, type ValorPermissao } from "./permissao";

/**
 * SPEC 001 / T021 — permissão de módulo para uso na tela.
 *
 * # Isto não é fronteira de segurança
 *
 * Conforme `.claude/rules/app.md`: este hook existe para **esconder menu e
 * evitar clique morto**. A fronteira real é RLS mais as RPCs do banco. Se você
 * consegue imaginar um `fetch` direto que traria dado de outra clínica, o
 * problema está na migração, não aqui.
 *
 * # Por que ele consulta, em vez de espelhar
 *
 * A regra manda espelhar a cascata do banco sem inventar outra. A forma mais
 * segura de espelhar é **não copiar**: o hook chama `my_permission(_module)`, a
 * mesma função que a RLS usa. Assim não existe uma segunda implementação para
 * divergir da primeira — e divergência de cascata sempre erra para o lado de
 * liberar demais.
 *
 * A cascata continua sendo, no banco: impersonação → assinatura suspensa nega →
 * módulo fora do plano nega → admin recebe full → permissão individual →
 * fallback `none`. *O plano é o teto; a permissão individual distribui abaixo.*
 *
 * # Enquanto carrega, nega
 *
 * `liberado` nasce `false` e só vira `true` quando o banco responde concedendo.
 * Nunca há uma janela em que a tela mostra o que ainda não foi autorizado.
 */
export function usePermissao(modulo: ModuleKey) {
  const [permissao, setPermissao] = useState<ValorPermissao>(NEGADO);
  const [liberado, setLiberado] = useState(false);
  const [carregando, setCarregando] = useState(true);

  useEffect(() => {
    let ativo = true;
    setCarregando(true);
    // Volta a negar a cada troca de módulo: sem isto, a resposta do módulo
    // anterior ficaria valendo por um instante para o novo.
    setPermissao(NEGADO);
    setLiberado(false);

    (async () => {
      const supabase = createClient();
      try {
        const { data, error } = await supabase.rpc("my_permission", {
          _module: modulo,
        });
        if (!ativo) return;
        const r = resolverAcesso(modulo, data, error);
        setPermissao(r.permissao);
        setLiberado(r.liberado);
      } catch {
        // Rede caiu, sessão expirou, qualquer coisa: nega. Regra (b).
        if (!ativo) return;
        setPermissao(NEGADO);
        setLiberado(false);
      } finally {
        if (ativo) setCarregando(false);
      }
    })();

    return () => {
      ativo = false;
    };
  }, [modulo]);

  return { permissao, liberado, carregando };
}
