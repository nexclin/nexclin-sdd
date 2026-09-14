-- ===========================================================================
-- 023 FASE 1, BLOCO 5 — REVERSAO. So se b5-conferencia.sql disser FALTA.
-- ===========================================================================
-- A tabela so cai se estiver VAZIA. Mensagem nao se apaga (FR-009): com dado
-- dentro, a reversao segura e derrubar as policies (RLS ligado sem policy =
-- ninguem le nem escreve) e parar a tela.

DROP TRIGGER IF EXISTS internal_messages_so_read_at ON public.internal_messages;
DROP FUNCTION IF EXISTS public.internal_messages_so_read_at();
DROP POLICY IF EXISTS "internal_messages_select_participante" ON public.internal_messages;
DROP POLICY IF EXISTS "internal_messages_insert_para_membro_com_login" ON public.internal_messages;
DROP POLICY IF EXISTS "internal_messages_update_so_destinatario" ON public.internal_messages;
DROP INDEX IF EXISTS public.internal_messages_nao_lidas_idx;
DROP INDEX IF EXISTS public.internal_messages_conversa_idx;

-- SO SE VAZIA. Confira antes: select count(*) from public.internal_messages;
-- DROP TABLE IF EXISTS public.internal_messages;
