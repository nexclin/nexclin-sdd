-- 20260828030000_is_system_so_active_e_editavel.sql
--
-- Regra 005, FR-006. A decisao do Arthur em 28/08/2026, entre as tres saidas
-- que a secao 7 da regra colocou: **so `active` e editavel em linha de
-- sistema**. Nega a exclusao, e no update exige que todo o resto fique igual.
--
-- POR QUE ISTO EXISTE: a trava morava so na tela, e isso e a regra (c) da
-- constituicao sendo violada. `formulario.tsx` desabilitava o botao e
-- `page.tsx` mostrava o selo, mas a policy era
-- `FOR ALL USING (clinic_id = get_my_clinic_id())` e nenhuma action lia
-- `is_system`. Uma chamada direta a API editava e apagava linha de sistema. As
-- mensagens de erro em `acoes.ts` ja descreviam um bloqueio que nao existia.
-- Seguranca que mora na tela nao e seguranca.
--
-- POR QUE A ESCOLHA NAO ERA OBVIA: negar todo UPDATE seria mais simples de
-- garantir, e conflitaria com o FR-005. A desativacao e logica, ou seja, e um
-- UPDATE de `active`. Negar tudo impediria a clinica de DESATIVAR um tipo de
-- fechamento que ela nao usa, e esconder da lista o que nao se oferece e
-- exatamente o que o FR-005 pede. As duas saidas mais baratas entregavam um
-- requisito as custas do outro. Esta entrega os dois.
--
-- POR QUE GATILHO, E NAO `WITH CHECK`: a regra e "as demais colunas ficam
-- iguais", e isso e uma comparacao com o valor ANTERIOR. `WITH CHECK` nao
-- enxerga OLD, so a linha resultante. A secao 7 da regra dizia "por WITH CHECK
-- ou trigger"; ao escrever, so trigger serve.
--
-- POR QUE UMA FUNCAO PARA AS TRES TABELAS: `chart_of_accounts`, `closing_types`
-- e `bank_accounts` carregam `is_system`. Escrever a lista de colunas
-- protegidas tabela a tabela apodreceria no primeiro `ADD COLUMN`, porque
-- ninguem lembraria de voltar aqui. Comparando `to_jsonb` da linha inteira
-- menos as colunas liberadas, coluna nova ja nasce protegida. E o Principio
-- VIII, Uma Regra Uma Fonte.
--
-- A EXCECAO segue o padrao de `prevent_clinic_id_change` (20260724233525):
-- `auth.uid() IS NULL` cobre service role e os seeds `SECURITY DEFINER`, que
-- rodam sem JWT, e o superadmin passa por ser quem opera a plataforma. Sem
-- isso, `semear_clinica` quebraria ao reparar uma clinica.
--
-- Faixa A da Sec. 2.5: e banco, e migra intacta para a stack nova.

CREATE OR REPLACE FUNCTION public.protege_linha_de_sistema()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Quem opera a plataforma, e o proprio sistema, passam direto.
  IF auth.uid() IS NULL OR public.is_superadmin(auth.uid()) THEN
    RETURN NEW;
  END IF;

  IF OLD.is_system THEN
    -- `active` e a unica coluna que a clinica move numa linha de sistema, e
    -- `updated_at` sai da conta por ser carimbo, nao conteudo.
    IF (to_jsonb(NEW) - 'active' - 'updated_at')
       IS DISTINCT FROM
       (to_jsonb(OLD) - 'active' - 'updated_at') THEN
      RAISE EXCEPTION
        'Entrada de sistema: so a ativacao pode ser alterada. Para deixar de '
        'oferece-la, desative-a.'
        USING ERRCODE = 'check_violation';
    END IF;
  ELSIF NEW.is_system THEN
    -- O caminho inverso, que ninguem lembra de fechar: marcar a PROPRIA linha
    -- como de sistema. Nao e perigoso por si, mas `is_system` significa "veio
    -- do seed", e deixar a clinica atribuir isso a si mesma esvazia o sentido
    -- da coluna e confunde qualquer contagem futura de linha semeada.
    RAISE EXCEPTION 'Somente o sistema marca uma entrada como de sistema.'
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.protege_linha_de_sistema() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS chart_of_accounts_protege_sistema ON public.chart_of_accounts;
CREATE TRIGGER chart_of_accounts_protege_sistema
  BEFORE UPDATE ON public.chart_of_accounts
  FOR EACH ROW EXECUTE FUNCTION public.protege_linha_de_sistema();

DROP TRIGGER IF EXISTS closing_types_protege_sistema ON public.closing_types;
CREATE TRIGGER closing_types_protege_sistema
  BEFORE UPDATE ON public.closing_types
  FOR EACH ROW EXECUTE FUNCTION public.protege_linha_de_sistema();

DROP TRIGGER IF EXISTS bank_accounts_protege_sistema ON public.bank_accounts;
CREATE TRIGGER bank_accounts_protege_sistema
  BEFORE UPDATE ON public.bank_accounts
  FOR EACH ROW EXECUTE FUNCTION public.protege_linha_de_sistema();

-- A EXCLUSAO e negada por policy RESTRICTIVE, e nao reescrevendo a policy
-- permissiva que ja existe. Restritiva entra em E logico com as demais, entao
-- ela subtrai permissao sem que eu precise saber o que a outra concede. Menos
-- risco de, ao reescrever, afrouxar o isolamento por `clinic_id` sem querer.
--
-- O superadmin continua podendo apagar: ele e quem conserta cadastro quebrado,
-- e o service role nem chega aqui, porque ignora RLS.

DROP POLICY IF EXISTS "Linha de sistema nao se apaga" ON public.chart_of_accounts;
CREATE POLICY "Linha de sistema nao se apaga"
  ON public.chart_of_accounts AS RESTRICTIVE FOR DELETE TO authenticated
  USING (NOT is_system OR public.is_superadmin(auth.uid()));

DROP POLICY IF EXISTS "Linha de sistema nao se apaga" ON public.closing_types;
CREATE POLICY "Linha de sistema nao se apaga"
  ON public.closing_types AS RESTRICTIVE FOR DELETE TO authenticated
  USING (NOT is_system OR public.is_superadmin(auth.uid()));

DROP POLICY IF EXISTS "Linha de sistema nao se apaga" ON public.bank_accounts;
CREATE POLICY "Linha de sistema nao se apaga"
  ON public.bank_accounts AS RESTRICTIVE FOR DELETE TO authenticated
  USING (NOT is_system OR public.is_superadmin(auth.uid()));

COMMENT ON FUNCTION public.protege_linha_de_sistema() IS
  'Regra 005 FR-006: em linha is_system, so `active` muda. Exclusao negada por '
  'policy restritiva nas mesmas tabelas.';
