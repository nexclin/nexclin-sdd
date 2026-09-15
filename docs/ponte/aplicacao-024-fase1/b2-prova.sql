-- ===========================================================================
-- PROVA do b2 (nexclin#185 e FR-011 da 024), no editor, sem deixar rastro
-- ===========================================================================
-- Um bloco DO, mesmo desenho do b1-prova-t320-t221.sql: troca para
-- authenticated com o JWT de Maria ou do Dr. Lancamento, tenta o que a policy
-- proibe e o que ela permite, grava o resultado numa tabela temporaria e
-- volta a superusuario. Nada e alterado de verdade: o UPDATE de controle
-- grava o mesmo valor que ja estava.
--
-- Clinica Lancamento 45f88cf2. Maria 68326ea2 (operacional). Dr 73deadca
-- (master e admin).

create temp table if not exists prova(ordem int, passo text, resultado text);
truncate prova;

do $$
declare
  v_clinic uuid := '45f88cf2-4440-48df-9a7c-dd46b90d366c';
  v_maria  uuid := '68326ea2-4c49-4742-b07a-0c333f199c6f';
  v_dr     uuid := '73deadca-6124-4f91-ac61-40a32e42fadc';
  v_pesos  jsonb;
  n        int;
begin
  select task_type_weights into v_pesos from public.business_rules where clinic_id = v_clinic;

  -- ===== como Maria: le, nao grava =====
  perform set_config('request.jwt.claims', json_build_object('sub', v_maria, 'role', 'authenticated')::text, true);
  set local role authenticated;

  select count(*) into n from public.business_rules where clinic_id = v_clinic;
  insert into prova values (1, 'SELECT business_rules como Maria', 'linhas: ' || n || ' (esperado 1)');

  update public.business_rules set task_type_weights = coalesce(v_pesos, '{}'::jsonb) where clinic_id = v_clinic;
  get diagnostics n = row_count;
  insert into prova values (2, 'UPDATE task_type_weights como Maria', 'linhas: ' || n || ' (esperado 0)');

  select count(*) into n from public.tarefas_assumidas_por_membro(now() - interval '365 days', now());
  insert into prova values (3, 'tarefas_assumidas_por_membro como Maria', 'linhas: ' || n || ' (esperado: executa sem erro; o numero e o da clinica)');

  select count(*) into n from public.data_audit_log where clinic_id = v_clinic;
  insert into prova values (4, 'controle: data_audit_log direto como Maria', 'linhas: ' || n || ' (esperado 0, a trilha continua so do admin)');

  -- ===== controle positivo: como o Dr, grava =====
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_dr, 'role', 'authenticated')::text, true);
  set local role authenticated;

  update public.business_rules set task_type_weights = coalesce(v_pesos, '{}'::jsonb) where clinic_id = v_clinic;
  get diagnostics n = row_count;
  insert into prova values (5, 'controle: UPDATE task_type_weights como Dr', 'linhas: ' || n || ' (esperado 1)');

  reset role;
end $$;

select * from prova order by ordem;
