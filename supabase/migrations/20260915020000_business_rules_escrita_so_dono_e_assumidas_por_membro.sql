-- ===========================================================================
-- 024 FASE 1, BLOCO 2 — dois achados da análise de 15/09 que são de banco
-- ===========================================================================
--
-- Regra: docs/regras/024-perfil-operacional.md, FR-011, FR-012 e seção 3.
-- Origem: docs/historico/2026-09-15-auditoria-024-escopo-e-business-rules.md
--         (achado (d) do auditor, nexclin#185) e o item I2 do speckit-analyze
--         de 15/09 sobre a 024.
--
-- Bloco 1. `business_rules` tinha a policy de 22/03, `FOR ALL` só por
--   `clinic_id`. Qualquer membro da clínica gravava `task_type_weights` (e
--   `followup_days`, `recall_days`, `patient_required_fields`) pela API, sem
--   o módulo `configuracoes`. O FR-012 diz "configurado pelo dono", e a
--   alínea (c) diz que isso tem de valer no banco. Leitura continua para todo
--   membro: a tabela é lida em 20 lugares do front, pela secretária inclusive.
--
-- Bloco 2. A medida "tarefas assumidas" (FR-011) lê `data_audit_log`, e a
--   policy de leitura dessa tabela (25/08) abre a trilha só para admin. Para a
--   secretária o RLS devolve zero linha, e o ranking mostrava zero em vez de
--   "indisponível". Aqui entra uma função `SECURITY DEFINER` que devolve só
--   (membro, instante) da própria clínica, sem abrir `previous_state` nem
--   `actor`. A conta é a mesma que o front fazia: a primeira linha de UPDATE
--   de cada tarefa em que o responsável anterior era nulo, atribuída a quem é
--   o responsável hoje.
--
-- ESTE ARQUIVO NÃO TOCA NENHUMA LINHA EXISTENTE. Só troca policy e cria uma
-- função. A semeadura de `business_rules` (`handle_new_user`,
-- `semear_clinica`, `semeia_operacao_da_clinica`) é `SECURITY DEFINER` e não
-- passa pela policy; clínica nova continua nascendo com a linha.
--
-- COMO RODAR: pelo editor de SQL da Lovable, um bloco por vez, na ordem. A
-- reversão de cada bloco está em comentário logo abaixo dele. A conferência e
-- a prova estão em docs/ponte/aplicacao-024-fase1/b2-*.sql.
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- BLOCO 1 · business_rules: leitura para a clínica, escrita para quem manda
-- ---------------------------------------------------------------------------
-- "Quem manda" é a forma que o banco já usa em get_clinic_team_full (02/08) e
-- na leitura de data_audit_log (25/08): superadmin, admin da clínica
-- (user_roles) ou team_members ativo com permission_level 'master' (um por
-- usuário, índice único de 25/08; a clínica dele é a de get_my_clinic_id). Não chama
-- my_permission, pelo motivo registrado no b1 da 023: nenhuma policy do schema
-- chama a cascata hoje, e essa mudança é geral (FR-011 da 021).
--
-- CUIDADO NA ORDEM: DROP e CREATE no mesmo bloco, sem parar no meio. Entre um
-- e outro, business_rules fica sem policy e RLS ligado, e ninguém lê a linha.

DROP POLICY IF EXISTS "Users can manage business_rules in their clinic" ON public.business_rules;

CREATE POLICY "business_rules_select_na_propria_clinica"
  ON public.business_rules FOR SELECT TO authenticated
  USING (clinic_id = public.get_my_clinic_id() OR public.is_superadmin(auth.uid()));

CREATE POLICY "business_rules_insert_so_quem_manda"
  ON public.business_rules FOR INSERT TO authenticated
  WITH CHECK (
    public.is_superadmin(auth.uid())
    OR (
      clinic_id = public.get_my_clinic_id()
      AND (
        public.has_role(auth.uid(), 'admin')
        OR EXISTS (
          SELECT 1 FROM public.team_members tm
          WHERE tm.user_id = auth.uid() AND tm.active = true
            AND tm.permission_level = 'master'
        )
      )
    )
  );

CREATE POLICY "business_rules_update_so_quem_manda"
  ON public.business_rules FOR UPDATE TO authenticated
  USING (
    public.is_superadmin(auth.uid())
    OR (
      clinic_id = public.get_my_clinic_id()
      AND (
        public.has_role(auth.uid(), 'admin')
        OR EXISTS (
          SELECT 1 FROM public.team_members tm
          WHERE tm.user_id = auth.uid() AND tm.active = true
            AND tm.permission_level = 'master'
        )
      )
    )
  )
  WITH CHECK (
    public.is_superadmin(auth.uid())
    OR (
      clinic_id = public.get_my_clinic_id()
      AND (
        public.has_role(auth.uid(), 'admin')
        OR EXISTS (
          SELECT 1 FROM public.team_members tm
          WHERE tm.user_id = auth.uid() AND tm.active = true
            AND tm.permission_level = 'master'
        )
      )
    )
  );

-- Sem policy de DELETE: default deny, alínea (b). business_rules é uma linha
-- por clínica (índice único de 27/08) e ninguém a apaga pela tela.

-- REVERSÃO DO BLOCO 1 (volta a policy de 22/03, palavra por palavra):
--   DROP POLICY IF EXISTS "business_rules_select_na_propria_clinica" ON public.business_rules;
--   DROP POLICY IF EXISTS "business_rules_insert_so_quem_manda" ON public.business_rules;
--   DROP POLICY IF EXISTS "business_rules_update_so_quem_manda" ON public.business_rules;
--   CREATE POLICY "Users can manage business_rules in their clinic"
--     ON public.business_rules FOR ALL TO authenticated
--     USING (clinic_id IN (SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid()))
--     WITH CHECK (clinic_id IN (SELECT clinic_id FROM public.profiles WHERE user_id = auth.uid()));


-- ---------------------------------------------------------------------------
-- BLOCO 2 · tarefas_assumidas_por_membro: a contagem sem abrir a trilha
-- ---------------------------------------------------------------------------
-- Devolve (member_id, em) por tarefa assumida no período, na clínica de quem
-- chama. SECURITY DEFINER porque data_audit_log só abre para admin, e o
-- ranking (FR-013) é de todo membro. O que sai é o mínimo que a conta
-- precisa: nem previous_state, nem actor, nem record_id.
--
-- "Assumida" é a primeira linha de UPDATE de cada tarefa em que o
-- responsible_member_id anterior era nulo, atribuída a quem é o responsável
-- hoje. É a mesma conta que RankingDeProdutividade.tsx fazia no front até
-- 15/09, e tem o mesmo limite dela: uma tarefa devolvida e assumida de novo
-- por outra pessoa conta uma vez, para o dono atual. O registro completo de
-- quem, quando, de quem para quem (FR-008) continua em data_audit_log, e o
-- dono o lê pela policy de 25/08.

CREATE OR REPLACE FUNCTION public.tarefas_assumidas_por_membro(p_de timestamptz, p_ate timestamptz)
RETURNS TABLE (member_id uuid, em timestamptz)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT DISTINCT ON (l.record_id)
    t.responsible_member_id AS member_id,
    l.created_at            AS em
  FROM public.data_audit_log l
  JOIN public.tasks t ON t.id = l.record_id
  WHERE l.clinic_id = public.get_my_clinic_id()
    AND t.clinic_id = l.clinic_id
    AND l.table_name = 'tasks'
    AND l.action = 'UPDATE'
    AND (l.previous_state ->> 'responsible_member_id') IS NULL
    AND t.responsible_member_id IS NOT NULL
    AND l.created_at >= p_de
    AND l.created_at <= p_ate
  ORDER BY l.record_id, l.created_at;
$$;

REVOKE EXECUTE ON FUNCTION public.tarefas_assumidas_por_membro(timestamptz, timestamptz) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.tarefas_assumidas_por_membro(timestamptz, timestamptz) TO authenticated;

COMMENT ON FUNCTION public.tarefas_assumidas_por_membro(timestamptz, timestamptz) IS
  'Regra 024, FR-011: tarefas assumidas por membro no período, na clínica de quem chama. Só (membro, instante); a trilha inteira continua sendo só do admin.';

-- REVERSÃO DO BLOCO 2:
--   DROP FUNCTION IF EXISTS public.tarefas_assumidas_por_membro(timestamptz, timestamptz);
