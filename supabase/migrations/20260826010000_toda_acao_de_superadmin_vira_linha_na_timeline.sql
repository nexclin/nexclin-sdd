-- SPEC 003, Fase 1, item 2: toda ação de operador grava DUAS linhas.
--
-- A spec é explícita: *"toda ação grava duas linhas: `superadmin_audit_log` +
-- `account_timeline` (a referência falhava na segunda; aqui é obrigatória e
-- verificada)"*.
--
-- # O que foi medido antes de escrever isto
--
-- Varredura em `app/`, `lib/` e `supabase/functions/`:
--
--   `superadmin_audit_log`  → 1 leitura (tela de logs) e 2 escritas
--                             (`update_email` e `send_password_reset`).
--   `account_timeline`      → 1 LEITURA e **ZERO ESCRITAS**.
--
-- A tela de detalhe da conta desenha uma linha do tempo que nada alimenta. O
-- mesmo defeito da referência, portado junto com o resto.
--
-- # Por que TRIGGER, e não uma função que os chamadores usam
--
-- O caminho óbvio seria uma função `registra_acao_de_superadmin` que insere nas
-- duas tabelas, e trocar os dois `INSERT` da edge function por ela. Resolveria
-- hoje e falharia de novo amanhã, porque **depende de todo chamador futuro
-- lembrar de usá-la**. Foi exatamente assim que a referência perdeu a segunda
-- linha: não por decisão, por esquecimento repetido.
--
-- Com trigger, a regra deixa de ser uma convenção e passa a ser uma
-- propriedade da tabela. Quem escrever auditoria por qualquer caminho, hoje ou
-- em outubro, produz a linha do tempo sem saber que ela existe. Inclui as
-- funções de impersonação, que escrevem `superadmin_audit_log` de dentro do
-- banco e nunca passariam por uma função da aplicação.
--
-- É o Princípio VIII, Uma Regra Uma Fonte, aplicado no único lugar onde ele
-- não pode ser contornado.

-- ---------------------------------------------------------------------------
-- 1. O texto que a linha do tempo mostra
-- ---------------------------------------------------------------------------

-- Separado da trigger de propósito: é a única parte que muda quando aparece
-- uma ação nova, e mantê-la isolada evita mexer na trigger por causa de texto.
CREATE OR REPLACE FUNCTION public.descricao_de_acao_de_superadmin(
  _action text,
  _previous jsonb,
  _new jsonb
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT CASE _action
    WHEN 'impersonation_start' THEN 'Suporte entrou na conta'
    WHEN 'impersonation_end'   THEN 'Suporte saiu da conta'
    WHEN 'profile_edit'        THEN 'Perfil de usuário editado pelo suporte'
    WHEN 'email_change'        THEN
      'E-mail de login alterado de ' ||
      COALESCE(_previous ->> 'email', 'desconhecido') || ' para ' ||
      COALESCE(_new ->> 'email', 'desconhecido')
    WHEN 'password_reset_sent' THEN
      'Reset de senha enviado para ' || COALESCE(_new ->> 'email', 'o usuário')
    ELSE 'Ação do suporte: ' || _action
  END;
$$;

COMMENT ON FUNCTION public.descricao_de_acao_de_superadmin(text, jsonb, jsonb) IS
  'O texto humano da linha do tempo. Separado da trigger porque e a unica parte que muda quando surge uma acao nova.';

-- ---------------------------------------------------------------------------
-- 2. A trigger que espelha
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.espelha_auditoria_na_timeline()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- `account_timeline.clinic_id` é NOT NULL, e `superadmin_audit_log.clinic_id`
  -- é anulável. Ação sem clínica não tem linha do tempo a que pertencer, e
  -- inventar uma seria pior que não ter: a auditoria continua registrada, que é
  -- o que a regra (d) da constituição exige.
  IF NEW.clinic_id IS NULL THEN
    RETURN NULL;
  END IF;

  INSERT INTO public.account_timeline (
    clinic_id, operator_id, event_type, description, metadata, created_at
  ) VALUES (
    NEW.clinic_id,
    NEW.operator_id,
    NEW.action,
    public.descricao_de_acao_de_superadmin(NEW.action, NEW.previous_state, NEW.new_state),
    jsonb_build_object(
      'audit_log_id',   NEW.id,
      'previous_state', NEW.previous_state,
      'new_state',      NEW.new_state,
      'reason',         NEW.reason
    ),
    NEW.created_at   -- o mesmo instante, para as duas linhas casarem
  );

  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.espelha_auditoria_na_timeline() IS
  'SPEC 003 F1: toda linha de superadmin_audit_log vira uma linha de account_timeline. Trigger e nao funcao de aplicacao, porque a referencia perdeu a segunda linha por esquecimento repetido dos chamadores.';

REVOKE ALL ON FUNCTION public.espelha_auditoria_na_timeline() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS superadmin_audit_log_espelha_timeline ON public.superadmin_audit_log;
CREATE TRIGGER superadmin_audit_log_espelha_timeline
  AFTER INSERT ON public.superadmin_audit_log
  FOR EACH ROW EXECUTE FUNCTION public.espelha_auditoria_na_timeline();

-- ---------------------------------------------------------------------------
-- 3. Reparo do que já aconteceu
-- ---------------------------------------------------------------------------

-- As ações auditadas antes desta migração não têm linha do tempo. A linha do
-- tempo existe para o operador entender o histórico da conta, e um histórico
-- que começa hoje mente por omissão.
--
-- O `NOT EXISTS` usa o `audit_log_id` gravado no metadata, então rodar duas
-- vezes não duplica.
INSERT INTO public.account_timeline (
  clinic_id, operator_id, event_type, description, metadata, created_at
)
SELECT
  a.clinic_id,
  a.operator_id,
  a.action,
  public.descricao_de_acao_de_superadmin(a.action, a.previous_state, a.new_state),
  jsonb_build_object(
    'audit_log_id',   a.id,
    'previous_state', a.previous_state,
    'new_state',      a.new_state,
    'reason',         a.reason,
    'reparo',         true
  ),
  a.created_at
FROM public.superadmin_audit_log a
WHERE a.clinic_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.account_timeline t
     WHERE t.metadata ->> 'audit_log_id' = a.id::text
  );

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
--
--   SELECT count(*) AS auditorias_sem_linha_do_tempo
--     FROM public.superadmin_audit_log a
--    WHERE a.clinic_id IS NOT NULL
--      AND NOT EXISTS (SELECT 1 FROM public.account_timeline t
--                       WHERE t.metadata ->> 'audit_log_id' = a.id::text);
--
-- Esperado: 0, agora e sempre.
--
-- E a prova que vale mais: trocar o e-mail de um usuário pelo painel e ver a
-- entrada aparecer na linha do tempo da conta **sem que a aplicação tenha
-- escrito nela**.
