/**
 * Este módulo é de servidor. Não há `import "server-only"` porque o pacote não
 * está nas dependências; a garantia vem de `@/lib/supabase/server`, que importa
 * `next/headers` e estoura se alguém tentar usá-lo do cliente.
 */

import { createClient } from "@/lib/supabase/server";
import { MODULOS_DO_MENU } from "./menu";
import type { ModuleKey } from "./modulos";
import { NEGADO, normalizarPermissao, type ValorPermissao } from "./permissao";
import {
  CONTAGENS_VAZIAS,
  resolverOnboarding,
  type ContagensOnboarding,
  type EstadoOnboarding,
} from "./onboarding";

/**
 * SPEC 001 / T020 — a coleta de dado que os guards precisam, no servidor.
 *
 * # Por que servidor
 *
 * Guard que decide no cliente pisca conteúdo protegido antes de redirecionar.
 * Server Component resolve antes de mandar HTML, então o usuário sem permissão
 * nunca vê a tela, nem por um frame. É a exigência de "estado de carga" do
 * contrato de guards.
 *
 * # A regra que rege todas as funções deste arquivo
 *
 * **Nenhuma lança, e toda falha vira negação.** Rede caída, sessão expirada,
 * RPC ausente, resposta com formato inesperado: tudo desce para o valor que
 * nega. Guard que estoura é guard que não protege, e exceção não tratada em
 * Server Component vira tela de erro, não bloqueio.
 */

export interface ContextoDoUsuario {
  userId: string | null;
  /** Status da assinatura da clínica. `null` quando não há assinatura ainda. */
  statusAssinatura: string | null;
  /** Sessão de impersonação ativa, se houver. */
  impersonacao: { id: string; clinica: string } | null;
  permissoes: Partial<Record<ModuleKey, ValorPermissao>>;
  onboarding: EstadoOnboarding;
}

/** Sessão do usuário, ou `null` em qualquer falha. */
export async function lerUsuario(): Promise<{ id: string } | null> {
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    return user?.id ? { id: user.id } : null;
  } catch {
    return null;
  }
}

/** `is_superadmin` no banco. Só `true` exato concede. */
export async function lerSuperAdmin(userId: string): Promise<boolean> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("is_superadmin", {
      _user_id: userId,
    });
    return !error && data === true;
  } catch {
    return false;
  }
}

/**
 * Uma permissão de módulo, via `my_permission`.
 *
 * É a mesma função que a RLS usa. O front pergunta ao banco em vez de
 * reimplementar a cascata, porque duas implementações da mesma cascata sempre
 * divergem, e sempre na direção de liberar demais.
 */
export async function lerPermissao(modulo: ModuleKey): Promise<ValorPermissao> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("my_permission", {
      _module: modulo,
    });
    return normalizarPermissao(data, error);
  } catch {
    return NEGADO;
  }
}

/**
 * As permissões dos módulos do menu, em paralelo.
 *
 * Uma chamada por módulo é o preço de não duplicar a cascata. São doze RPCs
 * `STABLE` numa conexão só, disparadas juntas: caro o bastante para valer um
 * cache por request no futuro, barato o bastante para não valer uma segunda
 * fonte de verdade agora.
 */
export async function lerPermissoesDoMenu(): Promise<
  Partial<Record<ModuleKey, ValorPermissao>>
> {
  const pares = await Promise.all(
    MODULOS_DO_MENU.map(
      async (m) => [m, await lerPermissao(m)] as const,
    ),
  );
  return Object.fromEntries(pares) as Partial<Record<ModuleKey, ValorPermissao>>;
}

/** Status da assinatura. `null` quando a clínica ainda não tem uma. */
export async function lerStatusAssinatura(): Promise<string | null> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("get_my_subscription_state");
    if (error) return null;
    const linha = Array.isArray(data) ? data[0] : data;
    const status = (linha as { status?: unknown } | null)?.status;
    return typeof status === "string" ? status : null;
  } catch {
    return null;
  }
}

/**
 * A sessão de impersonação ativa, se houver.
 *
 * Alimenta duas coisas: o banner âmbar obrigatório em todas as rotas, e o
 * bypass do `OnboardingGuard`. Falha vira `null`, que é o lado seguro: sem
 * banner e sem bypass é pior experiência, nunca acesso indevido.
 */
export async function lerImpersonacao(): Promise<{
  id: string;
  clinica: string;
} | null> {
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("get_my_active_impersonation");
    if (error) return null;
    const linha = Array.isArray(data) ? data[0] : data;
    if (!linha) return null;
    const id = (linha as { id?: unknown }).id;
    const nome = (linha as { target_clinic_name?: unknown }).target_clinic_name;
    if (typeof id !== "string") return null;
    return { id, clinica: typeof nome === "string" ? nome : "clínica" };
  } catch {
    return null;
  }
}

/** As tabelas que os doze passos do onboarding consultam. */
const TABELAS_ONBOARDING: readonly {
  tabela: string;
  campo: keyof ContagensOnboarding;
  exigeAtivo: boolean;
}[] = [
  { tabela: "team_members", campo: "team_members", exigeAtivo: true },
  { tabela: "business_rules", campo: "business_rules", exigeAtivo: false },
  { tabela: "channels", campo: "channels", exigeAtivo: true },
  { tabela: "origins", campo: "origins", exigeAtivo: true },
  { tabela: "services", campo: "services", exigeAtivo: true },
  { tabela: "objections", campo: "objections", exigeAtivo: true },
  { tabela: "payment_methods", campo: "payment_methods", exigeAtivo: true },
  { tabela: "chart_of_accounts", campo: "chart_of_accounts", exigeAtivo: true },
  { tabela: "bank_accounts", campo: "bank_accounts", exigeAtivo: true },
  { tabela: "goals", campo: "goals", exigeAtivo: false },
  { tabela: "anamnesis_config", campo: "anamnesis_config", exigeAtivo: true },
] as const;

/**
 * Conta as linhas que definem o onboarding.
 *
 * Não filtra por `clinic_id` na consulta: a RLS já faz isso, e repetir o filtro
 * no cliente criaria uma segunda fonte de verdade sobre qual clínica é a minha.
 * Se a RLS estiver certa, a contagem já vem certa. Se estiver errada, o
 * problema é a migração, e um filtro aqui só esconderia o furo.
 *
 * Erro em qualquer tabela vira zero, e zero deixa o passo incompleto. Falha
 * fechado: no pior caso a clínica vê o tour de novo, que é incômodo, não risco.
 */
export async function lerContagensOnboarding(): Promise<ContagensOnboarding> {
  try {
    const supabase = await createClient();
    const pares = await Promise.all(
      TABELAS_ONBOARDING.map(async ({ tabela, campo, exigeAtivo }) => {
        try {
          let q = supabase
            .from(tabela)
            .select("id", { count: "exact", head: true });
          if (exigeAtivo) q = q.eq("active", true);
          const { count, error } = await q;
          return [campo, error ? 0 : (count ?? 0)] as const;
        } catch {
          return [campo, 0] as const;
        }
      }),
    );
    return { ...CONTAGENS_VAZIAS, ...Object.fromEntries(pares) };
  } catch {
    return CONTAGENS_VAZIAS;
  }
}

/**
 * Tudo que o layout do app precisa, numa ida só.
 *
 * As quatro consultas independentes vão em paralelo. A ordem das decisões
 * continua sendo responsabilidade de `decidirEntradaNoApp`, que é pura e
 * testada; aqui só se busca o dado.
 */
export async function lerContextoDoUsuario(): Promise<ContextoDoUsuario> {
  const user = await lerUsuario();
  if (!user) {
    return {
      userId: null,
      statusAssinatura: null,
      impersonacao: null,
      permissoes: {},
      onboarding: resolverOnboarding(CONTAGENS_VAZIAS),
    };
  }

  const [statusAssinatura, impersonacao, permissoes, contagens] =
    await Promise.all([
      lerStatusAssinatura(),
      lerImpersonacao(),
      lerPermissoesDoMenu(),
      lerContagensOnboarding(),
    ]);

  return {
    userId: user.id,
    statusAssinatura,
    impersonacao,
    permissoes,
    onboarding: resolverOnboarding(contagens),
  };
}
