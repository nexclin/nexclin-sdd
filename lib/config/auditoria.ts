/**
 * Regra 005, FR-013: quais tabelas de configuração deixam rastro.
 *
 * A regra diz: *"A edição de catálogo e de regra de negócio MUST gerar registro
 * de auditoria, pelo mecanismo da regra 002."* O mecanismo é o trigger
 * `audita_mudanca_de_dado()`, que já existe e já é genérico: ele lê
 * `TG_TABLE_NAME`, `clinic_id` e `id`, então serve a qualquer tabela de negócio
 * sem uma linha nova de plpgsql.
 *
 * **Este arquivo não executa nada.** Ele é o *contrato*: a lista que o teste
 * confere contra as migrações. Catálogo novo que entre em `CATALOGOS` sem
 * ganhar trigger quebra o teste, de propósito, e é essa quebra que impede a
 * auditoria de ficar para trás em silêncio.
 *
 * **Por que a lista não é só `CATALOGOS.map(c => c.tabela)`:** `CATALOGOS` traz
 * as **dez** tabelas servidas pela tela genérica de catálogo, e quatro tabelas de
 * configuração ficam de fora dela por terem tela própria (`business_rules`,
 * `goals`, `anamnesis_config`, `chart_of_accounts`). Elas mudam número que o
 * resto do sistema lê, então precisam do mesmo rastro. Dez mais quatro é o
 * **catorze** desta lista.
 *
 * As contas do FR-004 e desta lista batem, e é fácil ler errado: o FR-004 fala
 * em **treze catálogos**, que são estas dez mais `chart_of_accounts`, `goals` e
 * `anamnesis_config`. Treze catálogos mais `business_rules`, que não é catálogo,
 * dá os mesmos catorze.
 */

import { CATALOGOS } from "./catalogo";

/**
 * Tabelas de configuração com tela própria, fora do catálogo genérico.
 *
 * `business_rules` guarda os parâmetros que a automação obedece; `goals`, a meta
 * do mês; `anamnesis_config`, o modelo do formulário; `chart_of_accounts`, a
 * árvore onde todo lançamento pendura.
 */
export const TABELAS_DE_CONFIGURACAO_COM_TELA_PROPRIA = [
  "business_rules",
  "goals",
  "anamnesis_config",
  "chart_of_accounts",
] as const;

/**
 * Toda tabela de configuração que **precisa** de trigger de auditoria.
 *
 * Ordenada, e sem repetição, para que a comparação com a migração seja estável
 * e a mensagem de falha do teste seja legível.
 */
export const TABELAS_AUDITADAS_DE_CONFIGURACAO: readonly string[] = [
  ...new Set([
    ...CATALOGOS.map((c) => c.tabela),
    ...TABELAS_DE_CONFIGURACAO_COM_TELA_PROPRIA,
  ]),
].sort();
