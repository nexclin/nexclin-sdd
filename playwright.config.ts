import { defineConfig, devices } from "@playwright/test";

/**
 * SPEC 001 / T027 — configuração do e2e.
 *
 * O T021 e o T020 cobrem a decisão de permissão em unidade, com função pura. É
 * muito, e não é suficiente: eles provam que a regra decide certo **dado** o que
 * o banco respondeu. O que ninguém provou ainda é que o banco responde certo, e
 * que o redirecionamento acontece de verdade no navegador.
 *
 * É isso que estes testes fazem, e é por isso que a fila da spec diz que "é lá
 * que a regra de permissão de fato se prova".
 *
 * # Pré-requisitos que não são de código
 *
 * Estes testes precisam de um banco com seed e de credenciais de teste. Eles
 * são escritos para falhar de forma clara quando isso falta, em vez de passar
 * vazios: teste que passa sem exercitar nada é pior que teste que falta, porque
 * dá confiança falsa.
 *
 * Variáveis esperadas em `.env.local`:
 *   E2E_URL_BASE          (opcional, padrão http://localhost:3000)
 *   E2E_SUPERADMIN_EMAIL  e  E2E_SUPERADMIN_SENHA
 *   E2E_USUARIO_EMAIL     e  E2E_USUARIO_SENHA    (usuário comum de clínica)
 */
export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false, // sessões compartilham o mesmo banco de teste
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? "github" : "list",
  timeout: 30_000,
  expect: { timeout: 10_000 },

  use: {
    baseURL: process.env.E2E_URL_BASE ?? "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },

  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],

  webServer: {
    command: "npm run dev",
    url: process.env.E2E_URL_BASE ?? "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
