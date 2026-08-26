-- SPEC 003, Fase 3: a sessão de suporte passa a ter prazo.
--
-- Escrita em 26/08/2026, a partir de pesquisa sobre controles de impersonação
-- em SaaS. O controle que a literatura trata como básico e que este banco não
-- tinha: *"o administrador de suporte não pode ficar logado para sempre; tem de
-- existir um tempo máximo de sessão"*.
--
-- # O que eu encontrei ao verificar, e é pior que a ausência do prazo
--
-- A impersonação aqui **troca a âncora**: `superadmin_enter_clinic` faz
-- `UPDATE profiles SET clinic_id = <clínica alvo>` no perfil do operador, e
-- `superadmin_exit_clinic` restaura a partir de `original_clinic_id`.
--
-- `get_my_clinic_id()` lê `profiles.clinic_id` e mais nada. Ela **não consulta**
-- a tabela de sessões.
--
-- A consequência: se o operador entra numa conta e fecha o navegador sem clicar
-- em sair, o perfil dele continua apontando para a clínica do cliente. Não por
-- uma hora: **para sempre**, até alguém clicar em sair. E a próxima vez que ele
-- abrir o sistema, entra direto na conta do cliente.
--
-- # Por isso um prazo só na sessão seria pior que nada
--
-- O caminho ingênuo seria pôr `expires_at` na sessão e filtrar em
-- `get_my_active_impersonation`. O banner sumiria da tela e **o acesso
-- continuaria**, porque quem decide o acesso é a âncora, não a sessão.
-- Esconder o aviso mantendo o acesso é a pior combinação possível das duas.
--
-- O prazo, então, tem de **desfazer a troca da âncora**, e é o que a função
-- abaixo faz.
--
-- # O que esta migração NÃO resolve, dito na cara
--
-- A função precisa ser chamada por alguém. Ela é chamada quando o operador
-- volta ao painel (o `layout` do superadmin) e antes de cada nova entrada. Se
-- o operador nunca mais voltar, a sessão fica aberta.
--
-- Fechar isso de vez exige uma das duas, e nenhuma é trabalho de véspera:
--
--   (a) `pg_cron` chamando a função de tempos em tempos. É a resposta certa.
--       Não há nenhuma extensão de cron nas 64 migrações deste banco, então
--       ligar uma é decisão nova, com spec própria.
--   (b) `get_my_clinic_id()` passar a consultar a sessão. É a função que TODA
--       policy do banco chama. Errar nela derruba o sistema inteiro, não uma
--       tela.
--
-- Registrado como dívida em `specs/003-superadmin-blindado/tasks.md`. O que
-- esta migração entrega é a redução da janela de "para sempre" para "até a
-- próxima vez que o operador abrir o painel", que é a diferença entre um
-- problema permanente e um transitório.

-- ---------------------------------------------------------------------------
-- 1. A coluna de prazo
-- ---------------------------------------------------------------------------

ALTER TABLE public.superadmin_impersonation_sessions
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

COMMENT ON COLUMN public.superadmin_impersonation_sessions.expires_at IS
  'Quando a sessao de suporte deixa de valer. Vencida, a ancora do operador e restaurada por encerra_impersonacoes_vencidas().';

-- Duas horas. É tempo suficiente para investigar um problema com o cliente ao
-- telefone, e curto o bastante para que um esquecimento não vire um dia inteiro
-- de acesso não vigiado.
ALTER TABLE public.superadmin_impersonation_sessions
  ALTER COLUMN expires_at SET DEFAULT (now() + interval '2 hours');

-- As sessões que já existem recebem o prazo contado do início delas, e não de
-- agora. Contar de agora daria mais duas horas a uma sessão que talvez esteja
-- aberta desde julho, que é o oposto do que a migração quer.
UPDATE public.superadmin_impersonation_sessions
   SET expires_at = started_at + interval '2 hours'
 WHERE expires_at IS NULL;

-- ---------------------------------------------------------------------------
-- 2. A função que desfaz a troca da âncora
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.encerra_impersonacoes_vencidas()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sessao record;
  v_encerradas integer := 0;
BEGIN
  FOR v_sessao IN
    SELECT * FROM public.superadmin_impersonation_sessions
     WHERE ended_at IS NULL
       AND expires_at IS NOT NULL
       AND expires_at <= now()
  LOOP
    -- A ordem importa: restaurar a âncora ANTES de fechar a sessão. Se algo
    -- falhar no meio, a sessão continua aberta e o próximo chamador tenta de
    -- novo. Fechando primeiro, uma falha deixaria a âncora trocada sem nenhum
    -- registro aberto apontando para o problema.
    --
    -- `original_clinic_id` pode ser NULL quando o operador não tinha clínica
    -- antes de entrar, e nesse caso NULL é o valor certo a restaurar.
    UPDATE public.profiles
       SET clinic_id = v_sessao.original_clinic_id, updated_at = now()
     WHERE user_id = v_sessao.superadmin_user_id;

    UPDATE public.superadmin_impersonation_sessions
       SET ended_at = now()
     WHERE id = v_sessao.id;

    -- A saída automática é auditada como qualquer outra, e a trigger de
    -- 20260826010000 põe a linha correspondente na linha do tempo da conta
    -- sem que nada aqui precise saber que ela existe.
    INSERT INTO public.superadmin_audit_log (
      operator_id, action, clinic_id, previous_state, new_state, reason
    )
    SELECT
      o.id,
      'impersonation_end',
      v_sessao.target_clinic_id,
      jsonb_build_object('session_id', v_sessao.id, 'started_at', v_sessao.started_at),
      jsonb_build_object('encerrada_por', 'prazo', 'expires_at', v_sessao.expires_at),
      'Sessao de suporte encerrada automaticamente por vencimento do prazo'
    FROM public.superadmin_operators o
    WHERE o.user_id = v_sessao.superadmin_user_id;

    v_encerradas := v_encerradas + 1;
  END LOOP;

  RETURN v_encerradas;
END;
$$;

COMMENT ON FUNCTION public.encerra_impersonacoes_vencidas() IS
  'Restaura a ancora do operador e fecha a sessao de suporte vencida. Restaurar a ancora e o ponto: prazo que so escondesse o banner manteria o acesso.';

REVOKE ALL ON FUNCTION public.encerra_impersonacoes_vencidas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.encerra_impersonacoes_vencidas() TO authenticated;

-- A função é segura para qualquer autenticado chamar: ela não recebe
-- parâmetro, não escolhe quem encerrar, e só age sobre sessão já vencida. O
-- pior que um usuário comum consegue fazer é encerrar mais cedo uma sessão de
-- suporte que já deveria estar encerrada.

-- ---------------------------------------------------------------------------
-- 3. A sessão vencida deixa de ser "ativa" para a tela
-- ---------------------------------------------------------------------------

-- Depois do item 2 esta filtragem é redundante na prática, e ela fica porque a
-- redundância aqui é barata e cobre a ordem em que as coisas acontecem: entre o
-- vencimento e a próxima chamada da função de limpeza, o banner não deve mais
-- afirmar que a sessão está valendo.
CREATE OR REPLACE FUNCTION public.get_my_active_impersonation()
RETURNS TABLE (
  id uuid,
  superadmin_user_id uuid,
  target_clinic_id uuid,
  original_clinic_id uuid,
  started_at timestamptz,
  target_clinic_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT s.id, s.superadmin_user_id, s.target_clinic_id, s.original_clinic_id,
         s.started_at, c.name
  FROM public.superadmin_impersonation_sessions s
  JOIN public.clinics c ON c.id = s.target_clinic_id
  WHERE s.superadmin_user_id = auth.uid()
    AND s.ended_at IS NULL
    AND (s.expires_at IS NULL OR s.expires_at > now())
  ORDER BY s.started_at DESC
  LIMIT 1
$$;

REVOKE EXECUTE ON FUNCTION public.get_my_active_impersonation() FROM PUBLIC, anon;

-- ---------------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------------
--
--   SELECT count(*) AS sessoes_abertas_e_vencidas
--     FROM public.superadmin_impersonation_sessions
--    WHERE ended_at IS NULL AND expires_at <= now();
--
-- Logo após aplicar, pode ser maior que zero: são as sessões antigas, que
-- receberam prazo retroativo. Rode `SELECT public.encerra_impersonacoes_vencidas();`
-- e confira de novo. Esperado: 0, e o número devolvido pela função dizendo
-- quantas âncoras foram restauradas.
--
-- **Se esse número vier maior que zero, isso é um achado, não um detalhe:**
-- significa que havia perfil de operador apontando para a clínica de um cliente
-- sem ninguém saber.
