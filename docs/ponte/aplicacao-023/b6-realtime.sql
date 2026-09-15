-- ===========================================================================
-- 023 FASE 3 — a mensagem interna em tempo real
-- ===========================================================================
-- Regra 023, FR-015. T241 (nexclin#44). O censo de 14/09 mostrou que a
-- publicação supabase_realtime existe e está vazia, então é ALTER, não
-- CREATE. O RLS vale na assinatura: o Realtime do Supabase filtra pelo SELECT
-- do assinante, e a policy por participante da migração 20260914020000 é o
-- que impede terceiro de receber o evento. A prova 6 (T245) confere isso com
-- uma terceira aba, e não assume.
--
-- Só leitura de evento: nada aqui muda dado. Reversão no fim.
-- ===========================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.internal_messages;

-- REVERSÃO:
--   ALTER PUBLICATION supabase_realtime DROP TABLE public.internal_messages;
