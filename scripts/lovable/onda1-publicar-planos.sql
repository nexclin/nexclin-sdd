-- =============================================================================
-- NexClin — Onda 1: habilitar módulos, publicar planos e ajustar trial padrão
-- =============================================================================
-- Origem      : sessão de planejamento com Arthur em 2026-08-18.
-- Alvo        : banco de PRODUÇÃO do Lovable Cloud (nexclin.lovable.app).
--               Este repositório aponta para o Supabase novo — portanto ESTE
--               ARQUIVO NÃO RODA DAQUI. Ele é para ser colado, na íntegra,
--               no SQL editor do Lovable Cloud (Cloud → SQL editor no
--               navegador), pelo Arthur.
--
-- Antes de rodar (obrigatório, não há recuperação no tempo neste tier):
--   1. Cloud → Overview → Advanced settings → Export project data
--      (baixar dump do banco de produção como backup manual).
--   2. Confirmar que os 3 planos abaixo continuam com os nomes exatos
--      (o WHERE deste script casa por `name`).
--
-- Por que só "Onda 1":
--   O primeiro cliente entra em 01/09/2026 usando apenas o núcleo
--   operacional. Repasse médico (contas_pagar, fluxo_caixa) e insights de
--   IA ficam para uma onda posterior — decisão registrada no plano de
--   lançamento. Gravamos as 5 chaves fora da Onda 1 explicitamente como
--   `false` (em vez de omiti-las) para que o admin da clínica veja com
--   clareza, na tela de plano, o que está fechado nesta rodada.
--
-- Ordem de execução dos blocos: 1 → 2 → 3 → 4. Não pular verificação.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- BLOCO 1 — Habilitar módulos da Onda 1 em cada plano
-- -----------------------------------------------------------------------------
-- As 15 ModuleKeys aparecem na ordem canônica do CLAUDE.md:
--   dashboard, leads, pacientes, anamnese, consultas, acompanhamento,
--   tarefas, contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas,
--   relatorios_demais, configuracoes, equipe, insights
--
-- Onda 1 (true — 10): dashboard, leads, pacientes, anamnese, consultas,
--   acompanhamento, tarefas, contas_receber, configuracoes, equipe.
-- Fora da Onda 1 (false — 5): contas_pagar, fluxo_caixa, relatorios_vendas,
--   relatorios_demais, insights.
--
-- O trigger `validate_enabled_modules` rejeita qualquer chave fora da lista
-- oficial — se o UPDATE abortar, é sinal de drift entre este arquivo e o
-- banco: PARAR e conferir a lista antes de reexecutar.

UPDATE public.plans
SET enabled_modules = '{
      "dashboard": true,
      "leads": true,
      "pacientes": true,
      "anamnese": true,
      "consultas": true,
      "acompanhamento": true,
      "tarefas": true,
      "contas_receber": true,
      "contas_pagar": false,
      "fluxo_caixa": false,
      "relatorios_vendas": false,
      "relatorios_demais": false,
      "configuracoes": true,
      "equipe": true,
      "insights": false
    }'::jsonb,
    updated_at = now()
WHERE name = 'Essencial 3 usuários';

UPDATE public.plans
SET enabled_modules = '{
      "dashboard": true,
      "leads": true,
      "pacientes": true,
      "anamnese": true,
      "consultas": true,
      "acompanhamento": true,
      "tarefas": true,
      "contas_receber": true,
      "contas_pagar": false,
      "fluxo_caixa": false,
      "relatorios_vendas": false,
      "relatorios_demais": false,
      "configuracoes": true,
      "equipe": true,
      "insights": false
    }'::jsonb,
    updated_at = now()
WHERE name = 'Clínica 5 usuários';

UPDATE public.plans
SET enabled_modules = '{
      "dashboard": true,
      "leads": true,
      "pacientes": true,
      "anamnese": true,
      "consultas": true,
      "acompanhamento": true,
      "tarefas": true,
      "contas_receber": true,
      "contas_pagar": false,
      "fluxo_caixa": false,
      "relatorios_vendas": false,
      "relatorios_demais": false,
      "configuracoes": true,
      "equipe": true,
      "insights": false
    }'::jsonb,
    updated_at = now()
WHERE name = 'Corpo Clínico 8 usuários';


-- -----------------------------------------------------------------------------
-- BLOCO 2 — Publicar os 3 planos (hidden → public)
-- -----------------------------------------------------------------------------
-- A cláusula `AND visibility = 'hidden'` é rede de segurança: se alguém já
-- tiver publicado manualmente um dos planos, este UPDATE não faz nada nele
-- (e updated_at não é tocado à toa). Idempotente por construção.

UPDATE public.plans
SET visibility = 'public',
    updated_at = now()
WHERE name = 'Essencial 3 usuários'
  AND visibility = 'hidden';

UPDATE public.plans
SET visibility = 'public',
    updated_at = now()
WHERE name = 'Clínica 5 usuários'
  AND visibility = 'hidden';

UPDATE public.plans
SET visibility = 'public',
    updated_at = now()
WHERE name = 'Corpo Clínico 8 usuários'
  AND visibility = 'hidden';


-- -----------------------------------------------------------------------------
-- BLOCO 3 — Trial padrão do SaaS: 14 → 30 dias
-- -----------------------------------------------------------------------------
-- `saas_settings` é singleton (uma linha só). A coluna que rege a duração
-- padrão do trial de novas contas é `trial_default_days` (integer,
-- default 14). O WHERE evita gravação supérflua caso o valor já esteja em 30.

UPDATE public.saas_settings
SET trial_default_days = 30,
    updated_at = now()
WHERE trial_default_days <> 30;


-- -----------------------------------------------------------------------------
-- BLOCO 4 — Verificação (rodar depois dos 3 blocos acima)
-- -----------------------------------------------------------------------------
-- 4.1 — Confirmar publicação e módulos habilitados por plano.
--       Esperado: 3 linhas, visibility = 'public', enabled_modules com as
--       10 chaves em true e 5 em false conforme Onda 1.
SELECT name,
       visibility,
       monthly_price,
       jsonb_pretty(enabled_modules) AS enabled_modules
FROM public.plans
WHERE name IN (
        'Essencial 3 usuários',
        'Clínica 5 usuários',
        'Corpo Clínico 8 usuários'
      )
ORDER BY monthly_price;

-- 4.2 — Confirmar trial padrão. Esperado: 30.
SELECT trial_default_days
FROM public.saas_settings;

-- 4.3 — Sanidade estrutural: cada plano tem que ter exatamente as 15
--       ModuleKeys oficiais no jsonb (nem a mais, nem a menos).
--       Esperado: 15.
SELECT count(*) AS total_chaves
FROM jsonb_object_keys(
       (SELECT enabled_modules
          FROM public.plans
         WHERE name = 'Essencial 3 usuários')
     );
