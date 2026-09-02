-- =====================================================================
-- ACENTO NO PLANO DE CONTAS: o TESTE do reparo. So leitura.
-- =====================================================================
--
-- Rodar ISTO antes da migracao. Ele nao escreve nada: mostra, lado a lado, o
-- nome atual e o nome reparado, para conferir a olho antes de qualquer UPDATE.
--
-- ============ O DIAGNOSTICO ============
--
-- Os bytes UTF-8 originais foram lidos como CP1252, e os bytes que o CP1252 nao
-- define passaram crus. Prova disso sao os dois erros que o reparo ingenuo deu
-- em 29/08/2026:
--
--   convert_to(name,'LATIN1')  -> falha em 0xe2 0x80 0xa1, que e o caractere
--                                 ‡. LATIN1 nao o tem.
--   convert_to(name,'WIN1252') -> falha em 0xc2 0x81, que e U+0081. CP1252 nao
--                                 define o byte 0x81.
--
-- Os dois juntos dizem tudo. `Ç` em UTF-8 e C3 87, e o 87 virou ‡ pelo CP1252.
-- `Á` e C3 81, e o 81 nao existe no CP1252, entao passou cru e virou U+0081.
-- Nenhuma conversao unica desfaz, porque a corrupcao usou duas tabelas.
--
-- ============ O REPARO, EM DOIS TEMPOS ============
--
--   1. `translate` devolve os 27 especiais do CP1252 para os code points
--      U+0080 a U+009F correspondentes. Depois disso a string inteira cabe em
--      U+0000 a U+00FF.
--   2. `convert_to(...,'LATIN1')` volta cada code point ao byte original, e
--      `convert_from(...,'UTF8')` le esses bytes como o UTF-8 que sempre foram.
--
-- Os 27 estao escritos com `chr()` de proposito, e nao com o caractere literal:
-- colar caractere especial por navegador e por editor e exatamente o tipo de
-- coisa que gerou este defeito. `chr(8364)` nao se corrompe no caminho.
-- =====================================================================

WITH mapa AS (
  SELECT
    -- OS 27 ESPECIAIS DO CP1252, na ordem dos bytes 0x80..0x9F
    chr(8364)||chr(8218)||chr(402) ||chr(8222)||chr(8230)||chr(8224)||chr(8225)
  ||chr(710) ||chr(8240)||chr(352) ||chr(8249)||chr(338) ||chr(381)
  ||chr(8216)||chr(8217)||chr(8220)||chr(8221)||chr(8226)||chr(8211)||chr(8212)
  ||chr(732) ||chr(8482)||chr(353) ||chr(8250)||chr(339) ||chr(382) ||chr(376)
      AS de,
    -- OS BYTES QUE ELES ERAM: 0x80,0x82..0x8C,0x8E,0x91..0x9C,0x9E,0x9F
    chr(128)||chr(130)||chr(131)||chr(132)||chr(133)||chr(134)||chr(135)
  ||chr(136)||chr(137)||chr(138)||chr(139)||chr(140)||chr(142)
  ||chr(145)||chr(146)||chr(147)||chr(148)||chr(149)||chr(150)||chr(151)
  ||chr(152)||chr(153)||chr(154)||chr(155)||chr(156)||chr(158)||chr(159)
      AS para
),
reparo AS (
  SELECT coa.id, coa.code, coa.name AS atual,
         convert_from(
           convert_to(translate(coa.name, m.de, m.para), 'LATIN1'),
           'UTF8'
         ) AS reparado
    FROM public.chart_of_accounts coa CROSS JOIN mapa m
   WHERE coa.name LIKE '%' || chr(195) || '%'   -- chr(195) = 'Ã', a marca da corrupcao
)
SELECT code, atual, reparado,
       CASE
         WHEN reparado LIKE '%' || chr(195) || '%' THEN 'AINDA CORROMPIDO'
         WHEN reparado = atual                     THEN 'NAO MUDOU'
         ELSE 'reparado'
       END AS resultado
  FROM reparo
 ORDER BY code
 LIMIT 25;
