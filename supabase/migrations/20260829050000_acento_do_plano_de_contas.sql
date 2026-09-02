-- 20260829050000_acento_do_plano_de_contas.sql
--
-- Conserta acento corrompido em `chart_of_accounts.name`. Achado em 29/08/2026
-- na bateria de relatorios: o Contas a Pagar mostrava `6.1.4 - RescisÃµes` e
-- `10 - AQUISIÃ‡Ã•ES` na tela, e o resto da pagina renderizava acento certo, o
-- que localiza o defeito no DADO e nao na tela.
--
-- ALCANCE MEDIDO ANTES: 204 linhas de 1976, em varias clinicas. Nenhuma outra
-- tabela afetada: `expense_categories`, `services` e `clinics` deram zero.
--
-- FAIXA A da Sec. 2.5, e por isso vale a pena consertar agora em vez de deixar
-- para a stack nova: e dado, o banco migra intacto em outubro, e ele aparece
-- justamente no financeiro, que e o diferencial de venda.
--
-- ============ O DIAGNOSTICO, E POR QUE O REPARO OBVIO FALHA ============
--
-- Os bytes UTF-8 originais foram lidos como CP1252, e os bytes que o CP1252 nao
-- define passaram crus. Os dois erros do reparo ingenuo dizem isso:
--
--   convert_to(name,'LATIN1')  -> ERRO em 0xe2 0x80 0xa1, que e `‡`.
--                                 LATIN1 nao tem esse caractere.
--   convert_to(name,'WIN1252') -> ERRO em 0xc2 0x81, que e U+0081.
--                                 CP1252 nao define o byte 0x81.
--
-- `Ç` em UTF-8 e C3 87, e o 87 virou `‡` pelo CP1252. `Á` e C3 81, e o 81 nao
-- existe no CP1252, entao passou cru e virou U+0081. Nenhuma conversao unica
-- desfaz, porque a corrupcao usou DUAS tabelas ao mesmo tempo.
--
-- ============ POR QUE NAO SE FILTRA POR `LIKE '%Ã%'` ============
--
-- Seria o obvio, e estragaria dado bom. `MANUTENÇÃO` escrito CERTO contem `Ã`,
-- e cairia no filtro. Rodar o reparo nele produziria bytes que nao formam UTF-8
-- valido, e a migracao inteira abortaria; ou pior, num caso limite, gravaria
-- lixo por cima de texto correto.
--
-- A deteccao usa TESTE DE IDA E VOLTA, que e a propria definicao de dupla
-- codificacao: repara, re-corrompe o reparo, e so aceita se o resultado for
-- byte a byte o texto original. Texto correto nunca passa nesse teste, entao a
-- funcao o devolve intacto. Isso torna a migracao segura E idempotente: rodar
-- de novo nao muda mais nada.

-- =====================================================================
-- 1. A FUNCAO DE REPARO
-- =====================================================================
--
-- Fica no banco em vez de virar UPDATE solto por dois motivos: ela e o unico
-- lugar onde o de-para dos 27 especiais existe, e a corrupcao pode reaparecer
-- em outra tabela por outro caminho de importacao.
--
-- Os 27 estao escritos com `chr()` de proposito, e nao com o caractere
-- literal. Colar caractere especial por navegador e por editor e exatamente o
-- tipo de coisa que gerou este defeito; `chr(8364)` nao se corrompe no caminho.

CREATE OR REPLACE FUNCTION public.reparar_mojibake_cp1252(t text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  -- OS 27 ESPECIAIS DO CP1252, na ordem dos bytes 0x80..0x9F
  de text :=
      chr(8364)||chr(8218)||chr(402) ||chr(8222)||chr(8230)||chr(8224)||chr(8225)
    ||chr(710) ||chr(8240)||chr(352) ||chr(8249)||chr(338) ||chr(381)
    ||chr(8216)||chr(8217)||chr(8220)||chr(8221)||chr(8226)||chr(8211)||chr(8212)
    ||chr(732) ||chr(8482)||chr(353) ||chr(8250)||chr(339) ||chr(382) ||chr(376);
  -- OS BYTES QUE ELES ERAM
  para text :=
      chr(128)||chr(130)||chr(131)||chr(132)||chr(133)||chr(134)||chr(135)
    ||chr(136)||chr(137)||chr(138)||chr(139)||chr(140)||chr(142)
    ||chr(145)||chr(146)||chr(147)||chr(148)||chr(149)||chr(150)||chr(151)
    ||chr(152)||chr(153)||chr(154)||chr(155)||chr(156)||chr(158)||chr(159);
  reparado text;
BEGIN
  IF t IS NULL THEN
    RETURN NULL;
  END IF;

  BEGIN
    -- 1. devolve os especiais aos code points U+0080..U+009F, o que faz a
    --    string inteira caber em U+0000..U+00FF
    -- 2. volta cada code point ao byte original, e le esses bytes como o UTF-8
    --    que eles sempre foram
    reparado := convert_from(convert_to(translate(t, de, para), 'LATIN1'), 'UTF8');
  EXCEPTION WHEN OTHERS THEN
    -- Nao era mojibake, ou nao e reparavel. Devolve intacto em vez de estourar:
    -- uma migracao de reparo nao pode derrubar as linhas que ja estavam boas.
    RETURN t;
  END;

  -- IDA E VOLTA. Re-corromper o reparo tem de reproduzir o original exatamente.
  -- Texto correto nunca satisfaz isso, e e o que protege `MANUTENÇÃO`.
  BEGIN
    IF translate(convert_from(convert_to(reparado, 'UTF8'), 'LATIN1'), para, de) = t THEN
      RETURN reparado;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RETURN t;
  END;

  RETURN t;
END;
$$;

COMMENT ON FUNCTION public.reparar_mojibake_cp1252(text) IS
  'Desfaz dupla codificacao UTF-8 lido como CP1252. Devolve o texto INTACTO '
  'quando ele nao passa no teste de ida e volta, entao e seguro rodar sobre '
  'coluna que mistura texto bom e corrompido, e e idempotente.';

-- Ninguem precisa chamar isto pela API. E utilitario de manutencao.
REVOKE ALL ON FUNCTION public.reparar_mojibake_cp1252(text) FROM PUBLIC, anon, authenticated;

-- =====================================================================
-- 2. O REPARO
-- =====================================================================
--
-- Sem WHERE por caractere: a funcao ja decide linha a linha, e devolve o
-- original no que nao for mojibake. O `IS DISTINCT FROM` evita reescrever linha
-- que nao muda, o que mantem `updated_at` de quem estava bom.

UPDATE public.chart_of_accounts
   SET name = public.reparar_mojibake_cp1252(name)
 WHERE name IS DISTINCT FROM public.reparar_mojibake_cp1252(name);

-- =====================================================================
-- 3. CONFERENCIA
-- =====================================================================
--
-- `chr(195)` e `Ã`. Sobrar linha aqui NAO e necessariamente defeito: pode ser
-- nome legitimamente com `Ã`, que a funcao preservou de proposito. Por isso a
-- conferencia mostra o que sobrou, para leitura humana, em vez de afirmar
-- sucesso sozinha.

SELECT 'linhas ainda com Ã (confira se sao legitimas)' AS verificacao,
       count(*)::text AS valor
  FROM public.chart_of_accounts
 WHERE name LIKE '%' || chr(195) || '%';
