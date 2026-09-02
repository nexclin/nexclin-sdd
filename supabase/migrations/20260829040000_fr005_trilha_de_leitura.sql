-- 20260829040000_fr005_trilha_de_leitura.sql
--
-- FR-005 da regra 017: registrar quem viu qual prontuario durante impersonacao.
-- Especificacao completa em `docs/regras/017-superadmin-e-impersonacao.md`,
-- secoes 2 e 7. As quatro decisoes de escopo sao do Arthur, 29/08/2026.
--
-- POR QUE ISTO EXISTE: `superadmin_audit_log` registra ACAO administrativa, e
-- a impersonacao registra a ENTRADA. Nenhum dos dois registra o que foi VISTO
-- la dentro. Um operador abre duzentos prontuarios e a trilha guarda uma linha
-- dizendo que ele entrou. E o unico item do lancamento com prazo legal.
--
-- FAIXA A da Sec. 2.5: e banco, e migra intacta para a stack nova em outubro.
--
-- COMO SE PROVA: `docs/ponte/fr-005-aceite.sql`, escrito ANTES desta migracao e
-- rodado antes dela, com as 13 verificacoes lendo FALHOU. Rodar de novo depois
-- de aplicar isto tem de dar 13 OK.

-- =====================================================================
-- 1. A TABELA
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.patient_access_log (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- A sessao de impersonacao em que a leitura aconteceu. Sem FK pelo mesmo
  -- motivo do `patient_id` abaixo. Amarrar a leitura a SESSAO, e nao so ao
  -- operador, e o que permite responder "o que foi visto naquele atendimento
  -- de suporte" em vez de so "o que essa pessoa ja viu algum dia".
  session_id       uuid NOT NULL,

  -- A clinica DONA do paciente lido. E por esta coluna que o RLS decide, e por
  -- ela que a regra (a) da constituicao exige RLS nesta tabela.
  clinic_id        uuid NOT NULL,

  -- SEM CHAVE ESTRANGEIRA, e isto e deliberado.
  --
  -- Com `REFERENCES patients(id) ON DELETE CASCADE`, apagar um paciente
  -- apagaria junto a prova de que alguem o leu. Uma trilha que some com o que
  -- ela auditava nao e trilha. O mesmo vale para `clinic_id` e `session_id`.
  --
  -- O custo aceito e nao ter integridade referencial. Para registro historico
  -- isso e correto: a linha descreve um fato passado, e fato passado nao deixa
  -- de ter acontecido porque a linha referenciada sumiu.
  patient_id       uuid NOT NULL,

  operator_user_id uuid NOT NULL,

  -- Desnormalizado de proposito, pela mesma razao: o operador pode ser
  -- desativado ou removido, e a trilha precisa continuar dizendo QUEM leu.
  operator_email   text NOT NULL,

  -- Hoje so 'impersonation'. A coluna existe para a ampliacao decidida como
  -- requisito da stack nova, que e registrar tambem a leitura pela equipe da
  -- propria clinica, sem exigir migracao de tabela quando chegar a hora.
  context          text NOT NULL DEFAULT 'impersonation',

  read_at          timestamptz NOT NULL DEFAULT now()
);

-- Serve a consulta esperada e o proprio predicado do RLS: "as leituras desta
-- clinica, mais recentes primeiro".
CREATE INDEX IF NOT EXISTS patient_access_log_clinic_read_at_idx
  ON public.patient_access_log (clinic_id, read_at DESC);

-- "O que foi visto naquela sessao de suporte."
CREATE INDEX IF NOT EXISTS patient_access_log_session_idx
  ON public.patient_access_log (session_id);

COMMENT ON TABLE public.patient_access_log IS
  'FR-005 da regra 017. Trilha de leitura de prontuario durante impersonacao. '
  'SOMENTE ANEXACAO: nao ha policy de INSERT, UPDATE nem DELETE, e o unico '
  'escritor e registrar_leitura_de_paciente(). Sem FK de proposito, para a '
  'trilha sobreviver a exclusao do que ela audita.';

-- =====================================================================
-- 2. PERMISSOES DE TABELA
-- =====================================================================
--
-- Duas camadas, e as duas importam. O GRANT decide se o papel pode TENTAR; a
-- policy decide QUAIS LINHAS ele ve. Conceder so SELECT e o que garante que
-- nem uma policy de INSERT escrita por engano no futuro daria escrita direta.

GRANT SELECT ON public.patient_access_log TO authenticated;
GRANT ALL    ON public.patient_access_log TO service_role;

REVOKE INSERT, UPDATE, DELETE ON public.patient_access_log FROM authenticated;
REVOKE ALL ON public.patient_access_log FROM anon;

ALTER TABLE public.patient_access_log ENABLE ROW LEVEL SECURITY;

-- =====================================================================
-- 3. RLS: DUAS POLICIES, E SO DE LEITURA
-- =====================================================================
--
-- Regra (b), default deny: o que nao esta concedido aqui esta negado. Nao ha
-- policy de INSERT, de UPDATE nem de DELETE, e a AUSENCIA delas E a proibicao.
-- Nem superadmin apaga linha desta tabela.

-- Quem audita ve tudo.
DROP POLICY IF EXISTS "Superadmin le toda a trilha" ON public.patient_access_log;
CREATE POLICY "Superadmin le toda a trilha"
  ON public.patient_access_log
  FOR SELECT
  TO authenticated
  USING (public.is_superadmin(auth.uid()));

-- A clinica ve as linhas DELA, e isso nao e generosidade: e a resposta que o
-- titular do dado tem direito de receber sobre quem da plataforma abriu o
-- prontuario do paciente dele.
DROP POLICY IF EXISTS "Clinica le a trilha dela" ON public.patient_access_log;
CREATE POLICY "Clinica le a trilha dela"
  ON public.patient_access_log
  FOR SELECT
  TO authenticated
  USING (
    clinic_id IN (
      SELECT p.clinic_id FROM public.profiles p WHERE p.user_id = auth.uid()
    )
  );

-- =====================================================================
-- 4. O UNICO ESCRITOR
-- =====================================================================
--
-- SECURITY DEFINER e o que permite escrever numa tabela sem policy de INSERT.
-- `SET search_path = public` nao e enfeite: sem ele, quem controlar o
-- search_path escolhe qual funcao a definer vai acabar chamando, e uma definer
-- e execucao com os privilegios do dono.

CREATE OR REPLACE FUNCTION public.registrar_leitura_de_paciente(p_patient_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session_id  uuid;
  v_operator    uuid;
  v_clinic      uuid;
  v_email       text;
BEGIN
  -- A sessao de impersonacao ATIVA de quem esta chamando. Mesmo criterio de
  -- `get_my_active_impersonation`: a mais recente ainda sem `ended_at`.
  SELECT s.id, s.superadmin_user_id, s.target_clinic_id
    INTO v_session_id, v_operator, v_clinic
    FROM public.superadmin_impersonation_sessions s
   WHERE s.superadmin_user_id = auth.uid()
     AND s.ended_at IS NULL
   ORDER BY s.started_at DESC
   LIMIT 1;

  -- Fora de impersonacao nao registra, e nao levanta erro. O escopo decidido
  -- em 29/08 e so impersonacao, e a tela chama esta funcao em todo prontuario
  -- que abre: levantar excecao aqui quebraria o prontuario do usuario comum.
  IF v_session_id IS NULL THEN
    RETURN false;
  END IF;

  -- O paciente tem de ser da clinica da sessao. Sem esta guarda, um operador
  -- poderia gravar leitura de paciente de outra clinica e sujar a trilha de
  -- quem nao foi lido, que e pior que nao registrar: e registrar mentira.
  IF NOT EXISTS (
    SELECT 1 FROM public.patients
     WHERE id = p_patient_id AND clinic_id = v_clinic
  ) THEN
    RETURN false;
  END IF;

  SELECT o.email INTO v_email
    FROM public.superadmin_operators o
   WHERE o.user_id = v_operator;

  INSERT INTO public.patient_access_log
    (session_id, clinic_id, patient_id, operator_user_id, operator_email, context)
  VALUES
    (v_session_id, v_clinic, p_patient_id, v_operator,
     -- Operador sem linha em `superadmin_operators` nao deveria ter sessao
     -- ativa, mas trilha que perde a linha por causa de um NOT NULL e pior que
     -- trilha com identificacao incompleta.
     coalesce(v_email, 'desconhecido'),
     'impersonation');

  RETURN true;
END;
$$;

COMMENT ON FUNCTION public.registrar_leitura_de_paciente(uuid) IS
  'FR-005 da regra 017. Unico escritor de patient_access_log. Devolve false, '
  'sem erro, quando nao ha impersonacao ativa ou quando o paciente nao e da '
  'clinica da sessao.';

-- Regra (b): anon nao executa. `PUBLIC` inclui anon, entao revoga-se dos dois
-- antes de conceder ao papel que deve poder.
REVOKE ALL ON FUNCTION public.registrar_leitura_de_paciente(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_leitura_de_paciente(uuid) TO authenticated;
