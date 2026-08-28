-- D-13 — A taxa da adquirente vira despesa (PREPARADO, NAO APLICADO)
--
-- ⚠️ ESTE ARQUIVO NAO DEVE SER APLICADO AINDA. O nome comeca com "PREPARADO-"
-- de proposito, para nao ser confundido com uma migracao pronta. Antes de rodar:
--   1. export do banco confirmado NA MAO (gate T004 da SPEC 002);
--   2. decisao sobre o backfill historico (ver secao no fim);
--   3. a mudanca do DRE (receita bruta) tem de ir JUNTO — ver "dupla contagem".
--
-- Regra (../../historico/2026-08-20-triagem-baterias-vinicius.md, D-13):
--   "Ja e descontado na fonte, mas e uma despesa."  — Arthur
--   "Na DRE tem um campo especifico de taxas, custos bancarios."  — Vinicius
--
-- POR QUE TRIGGER, E NAO CODIGO NO FRONT
--
-- Existem SEIS caminhos que inserem em `receivables`:
--   LaunchReceivableDialog, ClosingDetailDialog, Acompanhamento (3x),
--   ContasReceber.
-- Remendar os seis significa que o setimo nasce sem a taxa. A regra e do
-- dominio, entao mora no banco — e assim ela atravessa para a stack nova como
-- migracao, que e o unico artefato que migra intacto (CLAUDE.md §2.4).

-- ---------------------------------------------------------------------------
-- 1. A funcao
-- ---------------------------------------------------------------------------
create or replace function public.gerar_despesa_taxa_recebivel()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_taxa numeric;
  v_conta uuid;
begin
  -- Sem taxa, nada a fazer. Dinheiro e pix caem aqui.
  if coalesce(new.fee_percent, 0) <= 0 then
    return new;
  end if;

  -- A taxa incide sobre o BRUTO. Se gross_value nao veio, cai para `value`,
  -- que e o que os caminhos antigos preenchem.
  v_taxa := round(coalesce(new.gross_value, new.value, 0) * new.fee_percent / 100.0, 2);

  if v_taxa <= 0 then
    return new;
  end if;

  -- Conta contabil: 8.1.1 "Despesas Bancarias", criada pelo
  -- seed_chart_of_accounts. Buscada por CODIGO, nunca por nome — nome o
  -- usuario renomeia, codigo e contrato.
  select id into v_conta
  from chart_of_accounts
  where clinic_id = new.clinic_id and code = '8.1.1'
  limit 1;

  -- Sem a conta, NAO inventa lancamento solto: uma despesa sem plano de contas
  -- suja o DRE e ninguem descobre de onde veio. Deixa passar e registra.
  if v_conta is null then
    raise warning 'D-13: conta 8.1.1 ausente na clinica %, taxa de % nao lancada',
      new.clinic_id, v_taxa;
    return new;
  end if;

  insert into expenses (
    clinic_id, description, chart_account_id, value,
    due_date, competence_date,
    -- Nasce PAGA: a adquirente retem na fonte, nao ha pagamento a fazer.
    -- Nascer "pendente" criaria conta a pagar que ninguem vai pagar.
    status, paid_at,
    origin_type, supplier, notes
  ) values (
    new.clinic_id,
    'Taxa - ' || coalesce(new.description, 'recebimento'),
    v_conta,
    v_taxa,
    new.due_date,
    new.due_date,
    'pago',
    new.due_date,
    'taxa_recebivel',
    '',
    'Gerado automaticamente do recebivel ' || new.id::text
  );

  return new;
end;
$$;

revoke execute on function public.gerar_despesa_taxa_recebivel() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. O gatilho
-- ---------------------------------------------------------------------------
drop trigger if exists trg_despesa_taxa_recebivel on public.receivables;
create trigger trg_despesa_taxa_recebivel
after insert on public.receivables
for each row
execute function public.gerar_despesa_taxa_recebivel();


-- ===========================================================================
-- O QUE AINDA FALTA — nao aplique so isto acima
-- ===========================================================================
--
-- A) DUPLA CONTAGEM (obrigatorio ir junto)
--    Hoje o DRE soma `net_value` como receita (RelatorioDfcDre.tsx:103,147).
--    Com a despesa da taxa existindo, `net_value` desconta a taxa uma segunda
--    vez. Com R$250 a 3,5%: resultado cairia de 241,25 para 232,50.
--    O DRE tem de passar a somar `gross_value`.
--
-- B) INCONSISTENCIA JA EXISTENTE, achada ao preparar isto
--    O Fluxo de Caixa soma `r.value` (FluxoCaixa.tsx:90). E `value` nao e
--    preenchido igual em todo lugar: ContasReceber.tsx:225 grava
--    `value: f.net_value || f.value || f.gross_value` — ou seja, LIQUIDO ali e
--    BRUTO nos outros caminhos. O caixa ja mistura as duas coisas hoje, antes
--    da D-13. Precisa ser padronizado em BRUTO na mesma mudanca.
--
-- C) BACKFILL DOS RECEBIVEIS ANTIGOS — decisao do Arthur
--    O trigger so pega insercao nova. Os recebiveis que ja existem tem
--    fee_percent mas nenhuma despesa de taxa. Se o DRE mudar para bruto sem
--    backfill, a receita historica infla sem a despesa correspondente.
--    Tres saidas:
--      1. gerar as despesas retroativas com um INSERT ... SELECT (abaixo, comentado);
--      2. nao mexer no historico e assumir que so vale dali para frente;
--      3. como hoje so ha dado de teste, LIMPAR e comecar limpo — provavelmente
--         a melhor, ja que o primeiro cliente real entra em 01/09.
--
--    Se a escolha for (1):
--    insert into expenses (clinic_id, description, chart_account_id, value,
--                          due_date, competence_date, status, paid_at,
--                          origin_type, supplier, notes)
--    select r.clinic_id, 'Taxa - ' || coalesce(r.description,'recebimento'),
--           c.id,
--           round(coalesce(r.gross_value, r.value, 0) * r.fee_percent / 100.0, 2),
--           r.due_date, r.due_date, 'pago', r.due_date,
--           'taxa_recebivel', '', 'Backfill D-13 do recebivel ' || r.id::text
--      from receivables r
--      join chart_of_accounts c
--        on c.clinic_id = r.clinic_id and c.code = '8.1.1'
--     where coalesce(r.fee_percent,0) > 0
--       and round(coalesce(r.gross_value, r.value, 0) * r.fee_percent / 100.0, 2) > 0
--       and not exists (
--             select 1 from expenses e
--              where e.origin_type = 'taxa_recebivel'
--                and e.notes like '%' || r.id::text
--           );
--
-- D) ACEITE (Principio IV — implementado ≠ funciona)
--    Com UMA venda real no credito, conferir os tres numeros:
--      - extrato do banco bate com o LIQUIDO;
--      - DRE mostra receita BRUTA e a linha de taxa separada;
--      - resultado final igual ao de antes (a taxa aparece, nao muda o total).
