-- 20260829010000_cnpj_em_digito.sql
--
-- `clinics.cnpj` passa a guardar SO DIGITO, e a mascara fica na tela.
--
-- O DEFEITO, achado em 29/08/2026 ao conferir a primeira conta provisionada em
-- producao: ela gravou `43.243.243/2423-42`, enquanto a Barros Clinic tinha
-- `57314658000154`. Dois formatos na mesma coluna.
--
-- POR QUE ISSO IMPORTA MAIS DO QUE PARECE. Dois formatos convivendo quebram
-- tres coisas de uma vez: a busca por CNPJ nao acha quem esta no outro formato,
-- a comparacao entre duas clinicas da diferente para o mesmo numero, e qualquer
-- integracao fiscal futura recebe lixo. Nenhuma delas falha com erro: as tres
-- falham em silencio, devolvendo "nao encontrado" para um dado que existe.
--
-- Pela regua fina da Sec. 2.5 isto e dado PERSISTIDO, e a regra ali e explicita:
-- o banco migra intacto em outubro, entao lancamento errado hoje nao e
-- descartado, e importado. Faixa A.
--
-- A REGRA MORA EM TRES LUGARES, e as tres precisam concordar:
--   1. `lib/config/entrada.ts`, como `normalizaCnpj`, com cinco testes.
--   2. A edge function `superadmin-provisionar-clinica`, no provisionamento.
--   3. Esta migracao, para o que ja esta gravado.
--
-- O corte em catorze digitos e o tamanho do CNPJ. Sem ele, numero colado errado
-- entra inteiro e a coluna passa a ter valor que nao e CNPJ nenhum.

UPDATE public.clinics
SET cnpj = left(regexp_replace(cnpj, '\D', '', 'g'), 14)
WHERE cnpj IS NOT NULL
  AND cnpj <> left(regexp_replace(cnpj, '\D', '', 'g'), 14);

-- A trava para nao voltar. Sem ela, o proximo caminho que gravar CNPJ repete o
-- defeito, e ninguem descobre ate a busca falhar em silencio.
--
-- Aceita vazio de proposito: a coluna tem default `''` e clinica sem CNPJ e
-- caso legitimo, sobretudo em conta de teste. O que se recusa e o formatado.
ALTER TABLE public.clinics
  DROP CONSTRAINT IF EXISTS clinics_cnpj_so_digito;

ALTER TABLE public.clinics
  ADD CONSTRAINT clinics_cnpj_so_digito
  CHECK (cnpj IS NULL OR cnpj ~ '^[0-9]{0,14}$');

COMMENT ON COLUMN public.clinics.cnpj IS
  'Somente digito, no maximo 14. A mascara e da tela. '
  'Ver 20260829010000 e normalizaCnpj em lib/config/entrada.ts.';
