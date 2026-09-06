-- ===========================================================================
-- 021 FASE 1, BLOCO 1 — REVERSAO, palavra por palavra
-- ===========================================================================
--
-- Desfaz o b1 por inteiro. E seguro enquanto NENHUMA baixa nova tiver sido
-- gravada pelas telas de FR-001: a partir dai, derrubar as colunas apaga
-- valor recebido e autor de baixas reais, e isso e perda de dado, nao
-- reversao. A consulta abaixo responde se ainda da para reverter.

-- 1. DA PARA REVERTER? Rode isto ANTES do resto.
select
  (select count(*) from public.receivables
    where settled_value is not null or settled_by is not null or settled_at is not null)
  + (select count(*) from public.expenses
    where settled_value is not null or settled_by is not null or settled_at is not null)
  as baixas_gravadas,
  case when (
    (select count(*) from public.receivables
      where settled_value is not null or settled_by is not null or settled_at is not null)
    + (select count(*) from public.expenses
      where settled_value is not null or settled_by is not null or settled_at is not null)
  ) = 0
  then 'PODE REVERTER, nada foi gravado ainda'
  else 'NAO REVERTA SEM EXPORTAR: ha baixa real nestas colunas' end as veredito;

-- 2. A reversao. So depois de o veredito acima dizer PODE REVERTER.
alter table public.receivables drop constraint if exists receivables_settled_value_nao_negativo;
alter table public.expenses    drop constraint if exists expenses_settled_value_nao_negativo;

alter table public.receivables
  drop column if exists settled_value,
  drop column if exists settled_by,
  drop column if exists settled_at;

alter table public.expenses
  drop column if exists settled_value,
  drop column if exists settled_by,
  drop column if exists settled_at;
