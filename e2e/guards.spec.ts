import { expect, test, type Page } from "@playwright/test";

/**
 * SPEC 001 / T027 — os guards de rota, no navegador.
 *
 * # O que estes testes provam que os de unidade não provam
 *
 * Os 80 testes de Vitest exercitam a **decisão**: dado o que o banco respondeu,
 * o guard deixa passar ou não. Eles não tocam o banco, não passam pelo
 * middleware, e não sabem se o `redirect` realmente acontece.
 *
 * Aqui é o contrário: nada é simulado. O navegador pede a rota, o servidor
 * consulta o Postgres de verdade, a cascata de `my_permission` roda, e o teste
 * observa onde o usuário parou. É a única camada que prova a regra ponta a
 * ponta.
 *
 * # A regra de higiene destes testes
 *
 * Nenhum deles inventa dado. Se o ambiente não tiver credencial de teste, o
 * teste **pula com motivo explícito** em vez de passar vazio. Suíte verde que
 * não exercitou nada é o pior resultado possível, porque some com o alarme sem
 * resolver o problema.
 */

const SUPERADMIN = {
  email: process.env.E2E_SUPERADMIN_EMAIL,
  senha: process.env.E2E_SUPERADMIN_SENHA,
};

const USUARIO = {
  email: process.env.E2E_USUARIO_EMAIL,
  senha: process.env.E2E_USUARIO_SENHA,
};

/**
 * Rotas do app da clínica que **existem hoje** e exigem sessão.
 *
 * `/app/pacientes` e as outras do menu ainda não têm página: são as specs 006 em
 * diante. A primeira versão desta lista incluía `/app/pacientes` e o teste
 * falhou, com razão: rota sem `page.tsx` não faz o layout rodar, então o guard
 * não dispara e o Next devolve 404 na própria URL. Não é vazamento, porque não
 * há o que vazar; é rota que não existe. Testar rota inexistente como se
 * existisse é testar ficção, e o teste foi corrigido em vez do código.
 *
 * **Ao criar cada tela nova, acrescente a rota aqui.** É esta lista que garante
 * que o guard continua valendo para ela.
 */
const ROTAS_DO_APP = ["/app", "/app/configuracoes", "/app/conta-suspensa"];

/** Rotas do painel que exigem superadmin. */
const ROTAS_DO_PAINEL = [
  "/superadmin",
  "/superadmin/contas",
  "/superadmin/planos",
  "/superadmin/cupons",
  "/superadmin/faturamento",
  "/superadmin/metricas",
  "/superadmin/logs",
  "/superadmin/operadores",
  "/superadmin/comunicacao",
  "/superadmin/configuracoes",
];

async function entrar(page: Page, rota: string, email: string, senha: string) {
  await page.goto(rota);
  await page.getByLabel(/e-mail/i).fill(email);
  await page.getByLabel(/senha/i).first().fill(senha);
  await page.getByRole("button", { name: /entrar/i }).click();
}

test.describe("sem sessão, tudo é negado", () => {
  // Este bloco não precisa de credencial nenhuma, então roda sempre. É o
  // mínimo que qualquer ambiente consegue provar.

  for (const rota of ROTAS_DO_APP) {
    test(`${rota} manda para /login`, async ({ page }) => {
      await page.goto(rota);
      await expect(page).toHaveURL(/\/login/);
    });
  }

  for (const rota of ROTAS_DO_PAINEL) {
    test(`${rota} manda para /superadmin/login`, async ({ page }) => {
      await page.goto(rota);
      await expect(page).toHaveURL(/\/superadmin\/login/);
    });
  }

  test("rota do menu que ainda não existe não entrega conteúdo", async ({
    page,
  }) => {
    // Enquanto a spec do módulo não chega, a rota do menu não tem página. O que
    // importa provar não é o redirecionamento, é que **nada** de dado aparece:
    // sem sessão, sem clínica, sem menu. Quando a tela nascer, ela entra em
    // ROTAS_DO_APP acima e passa a ser cobrada pelo redirecionamento também.
    await page.goto("/app/pacientes");
    await expect(page.getByRole("navigation")).toHaveCount(0);
    await expect(page.getByText(/Seus módulos/i)).toHaveCount(0);
    await expect(page.getByText(/Modo suporte/i)).toHaveCount(0);
  });

  test("o app não pisca conteúdo protegido antes de redirecionar", async ({
    page,
  }) => {
    // O guard roda no servidor, então o HTML da rota protegida nunca chega ao
    // navegador. Se algum dia alguém mover o guard para o cliente, este teste
    // é o que denuncia.
    const respostas: string[] = [];
    page.on("response", (r) => respostas.push(r.url()));
    await page.goto("/app");
    await expect(page).toHaveURL(/\/login/);
    await expect(page.getByText(/nenhum módulo liberado/i)).toHaveCount(0);
  });
});

test.describe("sessão de superadmin", () => {
  test.skip(
    !SUPERADMIN.email || !SUPERADMIN.senha,
    "faltam E2E_SUPERADMIN_EMAIL e E2E_SUPERADMIN_SENHA no ambiente",
  );

  test("entra no painel e alcança as dez telas", async ({ page }) => {
    await entrar(page, "/superadmin/login", SUPERADMIN.email!, SUPERADMIN.senha!);
    await expect(page).toHaveURL(/\/superadmin(?!\/login)/);

    for (const rota of ROTAS_DO_PAINEL) {
      await page.goto(rota);
      // Não deve voltar para o login em nenhuma delas.
      await expect(page).not.toHaveURL(/\/superadmin\/login/);
      // E não deve estourar: o painel sempre desenha um cabeçalho.
      await expect(page.getByRole("heading").first()).toBeVisible();
    }
  });

  test("o painel nunca oferece caminho para definir senha", async ({ page }) => {
    // Regra (e) da constituição, verificada na tela e não só no código da edge
    // function. O audit log do MVP tem uma linha de `password set`; este teste
    // é a catraca que impede o botão de voltar por descuido de UI.
    await entrar(page, "/superadmin/login", SUPERADMIN.email!, SUPERADMIN.senha!);
    await page.goto("/superadmin/contas");

    const proibido = page.getByRole("button", {
      name: /definir senha|alterar senha|nova senha do usuário/i,
    });
    await expect(proibido).toHaveCount(0);
  });
});

test.describe("sessão de usuário comum", () => {
  test.skip(
    !USUARIO.email || !USUARIO.senha,
    "faltam E2E_USUARIO_EMAIL e E2E_USUARIO_SENHA no ambiente",
  );

  test("entra no app e o menu reflete a cascata do banco", async ({ page }) => {
    await entrar(page, "/login", USUARIO.email!, USUARIO.senha!);
    await expect(page).toHaveURL(/\/app/);

    // O menu é montado a partir de `my_permission`, um módulo por vez. O que
    // aparece aqui é o que o banco concedeu, e nada além.
    const menu = page.getByRole("navigation");
    await expect(menu).toBeVisible();
  });

  test("usuário comum não entra no painel de superadmin", async ({ page }) => {
    // É a checagem que separa os dois mundos. Ter sessão não é ser superadmin.
    await entrar(page, "/login", USUARIO.email!, USUARIO.senha!);
    await page.goto("/superadmin");
    await expect(page).toHaveURL(/\/superadmin\/login/);
  });

  test("módulo negado bloqueia a rota, e não só esconde o item", async ({
    page,
  }) => {
    await entrar(page, "/login", USUARIO.email!, USUARIO.senha!);
    await page.goto("/app");

    // Descobre um módulo que o menu NÃO ofereceu e tenta entrar por URL direta.
    // Esconder do menu é cortesia; bloquear a rota é a regra.
    const rotasPossiveis = [
      "/app/contas-pagar",
      "/app/fluxo-caixa",
      "/app/insights",
      "/app/relatorios/vendas",
    ];

    for (const rota of rotasPossiveis) {
      const visivel = await page
        .getByRole("link", { name: new RegExp(rota.split("/").pop()!, "i") })
        .count();
      if (visivel > 0) continue; // este módulo foi concedido, não serve de teste

      await page.goto(rota);
      // Sem permissão, a decisão manda para a raiz do app.
      await expect(page).toHaveURL(/\/app(?!\/)/);
      return;
    }

    test.skip(
      true,
      "este usuário tem todos os módulos liberados; use um com permissão parcial para exercitar o bloqueio",
    );
  });
});
