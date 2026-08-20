import { defineConfig } from "vitest/config";
import { fileURLToPath } from "node:url";

/**
 * SPEC 001 / T021 — configuração mínima de teste.
 *
 * Ambiente `node`, sem jsdom, de propósito: o que precisa de teste obrigatório
 * pela constituição (Princípio V) é a lógica de permissão, e ela foi escrita
 * como função pura justamente para não depender de DOM. Teste de componente e
 * de rota renderizada é escopo do T027 (Playwright), com banco de verdade.
 */
export default defineConfig({
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./", import.meta.url)),
    },
  },
  test: {
    environment: "node",
    include: ["**/__tests__/**/*.test.ts", "**/*.test.ts"],
    exclude: ["node_modules/**", ".next/**", "strix/**"],
  },
});
