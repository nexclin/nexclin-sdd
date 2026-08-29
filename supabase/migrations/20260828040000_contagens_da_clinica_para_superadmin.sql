-- 20260828040000_contagens_da_clinica_para_superadmin.sql
--
-- O painel de superadmin mostrava SEIS ZEROS numa clinica com 180 pacientes e
-- 420 consultas. Achado em 28/08/2026 na Clinica Teste Final.
--
-- A CONSULTA ESTAVA CERTA. `SuperAdminContaDetalhe.tsx` faz
-- `.from("patients").select("id", { count: "exact", head: true })
--  .eq("clinic_id", id)`, que e exatamente o certo. O RLS e que filtrava: a
-- policy de `patients` concede a linha cujo `clinic_id` bate com o do perfil de
-- quem pergunta, e o superadmin esta ancorado na propria clinica dele. O banco
-- devolvia zero, sem erro.
--
-- E POR ISSO ERA PIOR QUE UM ERRO DE PERMISSAO: erro aparece e se investiga.
-- Zero silencioso se le como "esta clinica nao usa o sistema", numa tela feita
-- para decidir sobre a conta do cliente. A tela nao falhava, mentia.
--
-- POR QUE UMA RPC, E NAO POLICY DE SUPERADMIN NAS TABELAS:
--
--   A saida obvia seria conceder SELECT de superadmin em `patients`,
--   `appointments`, `leads`, `tasks` e `receivables`. Ela funciona, e abre
--   LEITURA DE DADO DE PACIENTE DE TODAS AS CLINICAS para a conta mestra.
--
--   Dado de saude e sensivel pela LGPD, e a validacao de mercado de 28/08
--   (`docs/historico/2026-08-28-validacao-superadmin-mercado.md`) ja registrou
--   que a maior lacuna do painel e nao haver trilha de LEITURA de dado
--   clinico. Conceder SELECT amplo agravaria exatamente essa lacuna, para
--   entregar seis numeros.
--
--   A tela precisa de CONTAGEM, nao de linha. Esta funcao devolve seis
--   inteiros e nenhum dado de paciente. E o principio da minimizacao aplicado:
--   entrega o que a tela precisa e nada alem.
--
-- A GUARDA E OBRIGATORIA. `SECURITY DEFINER` roda com os privilegios do dono e
-- ignora RLS, entao sem a checagem qualquer usuario autenticado contaria a base
-- de qualquer clinica. A funcao verifica `is_superadmin` na primeira linha e
-- levanta excecao antes de olhar tabela nenhuma.
--
-- Faixa A da Sec. 2.5: e banco, e migra intacta para a stack nova.

CREATE OR REPLACE FUNCTION public.superadmin_contagens_da_clinica(_clinic_id uuid)
RETURNS TABLE (
  leads bigint,
  pacientes bigint,
  consultas bigint,
  tarefas bigint,
  recebiveis bigint,
  equipe bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Antes de qualquer contagem. Nao mova para baixo.
  IF NOT public.is_superadmin(auth.uid()) THEN
    RAISE EXCEPTION 'Somente superadmin pode contar a base de outra clinica.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF _clinic_id IS NULL THEN
    RAISE EXCEPTION 'clinic_id nulo';
  END IF;

  RETURN QUERY
  SELECT
    (SELECT count(*) FROM public.leads        WHERE clinic_id = _clinic_id),
    (SELECT count(*) FROM public.patients     WHERE clinic_id = _clinic_id),
    (SELECT count(*) FROM public.appointments WHERE clinic_id = _clinic_id),
    (SELECT count(*) FROM public.tasks        WHERE clinic_id = _clinic_id),
    (SELECT count(*) FROM public.receivables  WHERE clinic_id = _clinic_id),
    (SELECT count(*) FROM public.team_members WHERE clinic_id = _clinic_id);
END;
$$;

-- `authenticated` precisa poder chamar, porque o superadmin chega autenticado.
-- Quem barra nao e a permissao de execucao, e a guarda de dentro.
REVOKE EXECUTE ON FUNCTION public.superadmin_contagens_da_clinica(uuid) FROM PUBLIC, anon;

COMMENT ON FUNCTION public.superadmin_contagens_da_clinica(uuid) IS
  'Seis contagens de uso de uma clinica, para o painel de superadmin. '
  'Devolve numero e nunca linha, para nao abrir dado de paciente. '
  'Exige is_superadmin. Ver 20260828040000.';
