-- 20260829020000_cnpj_normaliza_no_banco.sql
--
-- O banco passa a NORMALIZAR o CNPJ sozinho, em vez de recusar quem escreve
-- errado.
--
-- O QUE EU FIZ ERRADO, e a licao vale mais que o conserto. Em 20260829010000 eu
-- adicionei um CHECK exigindo CNPJ so com digito, e apliquei em producao. Mas a
-- edge function que escreve o CNPJ ainda estava no ar com a versao ANTIGA, que
-- manda formatado: correcao de function nao sobe por Publish, e isso ja tinha
-- sido aprendido HOJE, algumas horas antes, no primeiro deploy dela.
--
-- Resultado: a criacao de conta, que estava funcionando, quebrou com "Database
-- error creating new user". Eu tinha apertado a regra antes de o escritor
-- obedece-la.
--
-- Ordem que deveria ter sido seguida, e que fica escrita aqui: PRIMEIRO todo
-- escritor passa a obedecer, DEPOIS a trava aperta. E a mesma logica do
-- "function antes do Publish do front" da ponte inversa, aplicada a restricao
-- de banco.
--
-- POR QUE UM GATILHO, E NAO APENAS REDEPLOYAR A FUNCTION:
--
--   Redeployar conserta UM escritor. `clinics` e escrita pelo gatilho
--   `handle_new_user`, pela edge function de provisionamento, e por qualquer
--   tela futura de cadastro. Confiar em que os tres normalizem e apostar que
--   ninguem esquece.
--
--   Com o gatilho, o formato deixa de ser combinado e passa a ser garantido. O
--   CHECK continua, mas vira rede de seguranca em vez de porta de entrada: com
--   a normalizacao antes dele, nao ha escrita legitima que ele recuse.
--
-- Faixa A da Sec. 2.5: e banco, e migra intacta.

CREATE OR REPLACE FUNCTION public.normaliza_cnpj_da_clinica()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.cnpj IS NOT NULL THEN
    -- Mesma regra de `normalizaCnpj` em `lib/config/entrada.ts`, que tem os
    -- cinco testes: so digito, no maximo catorze.
    NEW.cnpj := left(regexp_replace(NEW.cnpj, '\D', '', 'g'), 14);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS clinics_normaliza_cnpj ON public.clinics;
CREATE TRIGGER clinics_normaliza_cnpj
  BEFORE INSERT OR UPDATE OF cnpj ON public.clinics
  FOR EACH ROW EXECUTE FUNCTION public.normaliza_cnpj_da_clinica();

COMMENT ON FUNCTION public.normaliza_cnpj_da_clinica() IS
  'Tira a mascara do CNPJ antes de gravar. O formato deixa de depender de quem '
  'escreve. Ver 20260829020000 e o CHECK de 20260829010000.';
