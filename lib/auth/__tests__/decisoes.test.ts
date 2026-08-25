/**
 * SPEC 001 / T020 — testes das decisões de guard.
 *
 * O T021 já cobria o núcleo de permissão. Estes cobrem a camada que faltava: a
 * que decide navegação. São o mínimo obrigatório do Princípio V para guard de
 * rota, e existem porque o T021 nasceu sem consumidor: havia teste da regra e
 * nenhuma tela que a usasse.
 *
 * O critério de cada caso: **negar é o padrão**. Onde houver dúvida sobre o
 * dado, o teste exige bloqueio.
 */

import { describe, expect, it } from "vitest";
import {
  ROTA_CONTA_SUSPENSA,
  ROTA_LOGIN,
  ROTA_LOGIN_SUPERADMIN,
  ROTA_ONBOARDING,
  decidirAssinatura,
  decidirEntradaNoApp,
  decidirOnboarding,
  decidirPermissao,
  decidirSessao,
  decidirSuperAdmin,
} from "../decisoes";
import {
  CONTAGENS_VAZIAS,
  PASSOS_ONBOARDING,
  resolverOnboarding,
} from "../onboarding";
import {
  agruparMenu,
  catalogoEstaNoContrato,
  MODULOS_DO_MENU,
  moduloDaRota,
  montarMenu,
  rotaEhConhecida,
} from "../menu";

const USUARIO = { id: "11111111-1111-1111-1111-111111111111" };

describe("decidirSessao", () => {
  it("deixa passar quem tem id de usuário", () => {
    expect(decidirSessao(USUARIO)).toEqual({ acao: "renderizar" });
  });

  // Cada um destes já apareceu como resposta real do getUser em algum estado.
  it.each([
    ["nulo", null],
    ["indefinido", undefined],
    ["objeto vazio", {}],
    ["id nulo", { id: null }],
    ["id numérico", { id: 42 }],
    ["id string vazia", { id: "" }],
    ["id só espaço", { id: "   " }],
    ["string solta", "usuario"],
  ])("manda %s para o login", (_rotulo, entrada) => {
    expect(decidirSessao(entrada)).toEqual({
      acao: "redirecionar",
      destino: ROTA_LOGIN,
      motivo: "sem_sessao",
    });
  });
});

describe("decidirSuperAdmin", () => {
  it("libera com sessão e is_superadmin exatamente true", () => {
    expect(decidirSuperAdmin(USUARIO, true)).toEqual({ acao: "renderizar" });
  });

  it("manda para o login do painel quem não tem sessão", () => {
    const d = decidirSuperAdmin(null, true);
    expect(d).toMatchObject({
      acao: "redirecionar",
      destino: ROTA_LOGIN_SUPERADMIN,
      motivo: "sem_sessao",
    });
  });

  // "Quase verdadeiro" não é autorização. A resposta do RPC passa por JSON.
  it.each([
    ["string true", "true"],
    ["número 1", 1],
    ["objeto", {}],
    ["array vazio", []],
    ["false", false],
    ["nulo", null],
    ["indefinido", undefined],
  ])("nega quando is_superadmin é %s", (_rotulo, valor) => {
    expect(decidirSuperAdmin(USUARIO, valor)).toMatchObject({
      acao: "redirecionar",
      motivo: "nao_superadmin",
    });
  });

  it("nega quando o RPC devolveu erro, mesmo com data true", () => {
    expect(decidirSuperAdmin(USUARIO, true, new Error("rede"))).toMatchObject({
      acao: "redirecionar",
      motivo: "nao_superadmin",
    });
  });
});

describe("decidirPermissao", () => {
  it("libera quando o banco devolve um valor concreto", () => {
    expect(decidirPermissao("pacientes", "full")).toEqual({
      acao: "renderizar",
    });
  });

  it("libera valores de vocabulário próprio do módulo", () => {
    // A cascata devolve vocabulários diferentes por módulo. O front não pode
    // fechar essa união; só `none` nega.
    for (const v of ["read", "own", "simplified", "responsible_only", "status_only"]) {
      expect(decidirPermissao("relatorios_demais", v)).toEqual({
        acao: "renderizar",
      });
    }
  });

  it("nega em none", () => {
    expect(decidirPermissao("pacientes", "none")).toMatchObject({
      motivo: "sem_permissao",
      destino: "/app",
    });
  });

  it.each([
    ["nulo", null],
    ["indefinido", undefined],
    ["número", 3],
    ["string vazia", ""],
    ["só espaço", "  "],
  ])("nega quando a resposta é %s", (_rotulo, valor) => {
    expect(decidirPermissao("pacientes", valor)).toMatchObject({
      motivo: "sem_permissao",
    });
  });

  it("nega quando o RPC errou, mesmo com data concedendo", () => {
    expect(decidirPermissao("pacientes", "full", new Error("rede"))).toMatchObject({
      motivo: "sem_permissao",
    });
  });

  it("nega módulo fora do contrato das 15 chaves", () => {
    // Erro de digitação numa rota não pode virar porta aberta.
    for (const m of ["paciente", "PACIENTES", "residuos", "", null, 7]) {
      expect(decidirPermissao(m, "full")).toMatchObject({
        motivo: "modulo_fora_do_contrato",
      });
    }
  });
});

describe("decidirAssinatura", () => {
  it.each(["suspended", "cancelled"])("bloqueia a conta %s", (status) => {
    expect(decidirAssinatura(status)).toMatchObject({
      acao: "redirecionar",
      destino: ROTA_CONTA_SUSPENSA,
      motivo: "assinatura_inativa",
    });
  });

  it.each(["trial", "active", "overdue"])("deixa passar a conta %s", (status) => {
    expect(decidirAssinatura(status)).toEqual({ acao: "renderizar" });
  });

  it("não tranca clínica sem assinatura ainda registrada", () => {
    // Clínica recém-criada, antes do seed. Quem nega de fato é a cascata do
    // banco, módulo a módulo, e não este desvio.
    expect(decidirAssinatura(null)).toEqual({ acao: "renderizar" });
    expect(decidirAssinatura(undefined)).toEqual({ acao: "renderizar" });
  });
});

describe("decidirOnboarding", () => {
  it("deixa passar quando concluído", () => {
    expect(
      decidirOnboarding({ concluido: true, impersonando: false, rotaAtual: "/app" }),
    ).toEqual({ acao: "renderizar" });
  });

  it("desvia para o fluxo inicial quando incompleto", () => {
    expect(
      decidirOnboarding({ concluido: false, impersonando: false, rotaAtual: "/app" }),
    ).toMatchObject({ destino: ROTA_ONBOARDING, motivo: "onboarding_incompleto" });
  });

  // Exigência escrita no contrato de guards, com estas palavras.
  it("NÃO dispara sob impersonação, mesmo incompleto", () => {
    expect(
      decidirOnboarding({ concluido: false, impersonando: true, rotaAtual: "/app" }),
    ).toEqual({ acao: "renderizar" });
  });

  it("não redireciona a rota de onboarding para ela mesma", () => {
    for (const rota of [ROTA_ONBOARDING, ROTA_ONBOARDING + "/equipe"]) {
      expect(
        decidirOnboarding({ concluido: false, impersonando: false, rotaAtual: rota }),
      ).toEqual({ acao: "renderizar" });
    }
  });
});

describe("resolverOnboarding", () => {
  it("clínica zerada tem 0 de 12 e não está concluída", () => {
    const e = resolverOnboarding(CONTAGENS_VAZIAS);
    expect(e.concluido).toBe(false);
    expect(e.passoAtual).toBe(0);
    expect(e.total).toBe(12);
    expect(Object.values(e.passos).every((v) => v === false)).toBe(true);
  });

  it("exige DUAS pessoas ativas no passo de equipe", () => {
    // Paridade com a referência, que usa .limit(2) e testa >= 2: a clínica só
    // com o dono não passou pelo passo de equipe.
    expect(resolverOnboarding({ team_members: 1 }).passos.team).toBe(false);
    expect(resolverOnboarding({ team_members: 2 }).passos.team).toBe(true);
  });

  it("channels_origins exige as duas tabelas", () => {
    expect(resolverOnboarding({ channels: 1, origins: 0 }).passos.channels_origins).toBe(false);
    expect(resolverOnboarding({ channels: 0, origins: 1 }).passos.channels_origins).toBe(false);
    expect(resolverOnboarding({ channels: 1, origins: 1 }).passos.channels_origins).toBe(true);
  });

  it("business_rules acende os três passos que a referência liga na mesma tabela", () => {
    const p = resolverOnboarding({ business_rules: 1 }).passos;
    expect(p.patient_fields).toBe(true);
    expect(p.appointment_fields).toBe(true);
    expect(p.business_rules).toBe(true);
  });

  it("conclui quando os doze passos fecham", () => {
    const e = resolverOnboarding({
      team_members: 2,
      business_rules: 1,
      channels: 1,
      origins: 1,
      services: 1,
      objections: 1,
      payment_methods: 1,
      chart_of_accounts: 1,
      bank_accounts: 1,
      goals: 1,
      anamnesis_config: 1,
    });
    expect(e.concluido).toBe(true);
    expect(e.passoAtual).toBe(PASSOS_ONBOARDING.length);
  });

  it("trata número inválido como ausência", () => {
    for (const ruim of [-1, NaN, Infinity, "2" as unknown as number, null as unknown as number]) {
      expect(resolverOnboarding({ services: ruim }).passos.services).toBe(false);
    }
  });

  it("entrada nula não estoura e devolve tudo negado", () => {
    expect(resolverOnboarding(null).concluido).toBe(false);
    expect(resolverOnboarding(undefined).concluido).toBe(false);
  });
});

describe("menu", () => {
  it("todo item do catálogo usa uma das 15 ModuleKeys", () => {
    expect(catalogoEstaNoContrato()).toBe(true);
  });

  it("esconde o que o banco negou", () => {
    const itens = montarMenu({ pacientes: "full", contas_pagar: "none" });
    const modulos = itens.map((i) => i.modulo);
    expect(modulos).toContain("pacientes");
    expect(modulos).not.toContain("contas_pagar");
    expect(modulos).not.toContain("insights"); // ausente do mapa
  });

  it("mapa vazio, nulo ou quebrado não mostra nada", () => {
    expect(montarMenu({})).toHaveLength(0);
    expect(montarMenu(null)).toHaveLength(0);
    expect(montarMenu(undefined)).toHaveLength(0);
    expect(montarMenu({ pacientes: 1 as unknown as string })).toHaveLength(0);
  });

  it("não oferece consultas nem equipe como item de topo", () => {
    // `consultas` não tem destino próprio decidido e `equipe` vive dentro de
    // configurações. Item de menu sem destino é bug de navegação.
    expect(MODULOS_DO_MENU).not.toContain("consultas");
    expect(MODULOS_DO_MENU).not.toContain("equipe");
  });

  it("agrupa na ordem e descarta grupo vazio", () => {
    const grupos = agruparMenu(montarMenu({ pacientes: "full", insights: "full" }));
    expect(grupos.map((g) => g.grupo)).toEqual(["Operação", "Análise"]);
  });

  it("resolve o módulo dono de cada rota, com a mais específica vencendo", () => {
    expect(moduloDaRota("/app/pacientes")).toBe("pacientes");
    expect(moduloDaRota("/app/pacientes/123")).toBe("pacientes");
    // O caso que um prefixo ingênuo erraria:
    expect(moduloDaRota("/app/relatorios/vendas")).toBe("relatorios_vendas");
    expect(moduloDaRota("/app/relatorios")).toBe("relatorios_demais");
  });

  it("rota desconhecida devolve null, e quem chama trata como negado", () => {
    for (const r of ["/app/inexistente", "", "/outra-coisa", null as unknown as string]) {
      expect(moduloDaRota(r)).toBeNull();
    }
  });

  it("o dashboard não participa do casamento de rota", () => {
    // Foi este teste que pegou o defeito: `/app` como rota do dashboard casava
    // por prefixo com QUALQUER rota desconhecida sob `/app`, e como o dashboard
    // não é gateado, a rota desconhecida saía liberada.
    expect(moduloDaRota("/app")).toBeNull();
    expect(moduloDaRota("/app/qualquer-coisa")).toBeNull();
    // Mas `/app` continua sendo rota conhecida, e o item segue no menu.
    expect(rotaEhConhecida("/app")).toBe(true);
    expect(rotaEhConhecida("/app/inexistente")).toBe(true); // prefixo do dashboard
    expect(rotaEhConhecida("/fora-do-app")).toBe(false);
    expect(MODULOS_DO_MENU).toContain("dashboard");
  });
});

describe("decidirEntradaNoApp — a ordem é a regra", () => {
  const base = {
    user: USUARIO,
    statusAssinatura: "active",
    onboarding: { concluido: true, impersonando: false },
    rotaAtual: "/app/pacientes",
    modulo: "pacientes",
    permissao: "full",
  };

  it("libera o caminho feliz", () => {
    expect(decidirEntradaNoApp(base)).toEqual({ acao: "renderizar" });
  });

  it("sessão vem antes de tudo", () => {
    const d = decidirEntradaNoApp({ ...base, user: null, statusAssinatura: "suspended" });
    expect(d).toMatchObject({ motivo: "sem_sessao" });
  });

  it("assinatura morta vence a falta de permissão", () => {
    // Inverter a ordem mandaria a conta suspensa para "sem permissão", que é
    // verdade e não ajuda ninguém a resolver o problema.
    const d = decidirEntradaNoApp({
      ...base,
      statusAssinatura: "suspended",
      permissao: "none",
    });
    expect(d).toMatchObject({ motivo: "assinatura_inativa" });
  });

  it("onboarding incompleto vence a permissão do módulo", () => {
    const d = decidirEntradaNoApp({
      ...base,
      onboarding: { concluido: false, impersonando: false },
    });
    expect(d).toMatchObject({ motivo: "onboarding_incompleto" });
  });

  it("impersonação atravessa o onboarding e chega na checagem de módulo", () => {
    const d = decidirEntradaNoApp({
      ...base,
      onboarding: { concluido: false, impersonando: true },
      permissao: "none",
    });
    expect(d).toMatchObject({ motivo: "sem_permissao" });
  });

  it("rota sem módulo declarado não é gateada por permissão", () => {
    // É o comportamento registrado do dashboard: sem RequirePermission.
    const d = decidirEntradaNoApp({ ...base, modulo: undefined, rotaAtual: "/app" });
    expect(d).toEqual({ acao: "renderizar" });
  });

  it("nega quando a permissão não veio", () => {
    expect(
      decidirEntradaNoApp({ ...base, permissao: undefined }),
    ).toMatchObject({ motivo: "sem_permissao" });
  });
});
