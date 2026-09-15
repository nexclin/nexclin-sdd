-- Apaga só o que seed-clinica-lancamento.sql criou: tudo com "[demo]" no
-- título, nome, corpo ou nota, na Clínica Lançamento. Roda como superusuário,
-- por cima do RLS (tasks e internal_messages não têm policy de DELETE).
-- As linhas de data_audit_log geradas pelos triggers ficam, com actor nulo;
-- são rastro do seed e não atrapalham nada.

do $$
declare v_clinic uuid := '45f88cf2-4440-48df-9a7c-dd46b90d366c';
begin
  delete from public.internal_messages where clinic_id = v_clinic and body like '[demo]%';
  delete from public.task_comments     where clinic_id = v_clinic and body like '[demo]%';
  delete from public.tasks             where clinic_id = v_clinic and title like '[demo]%';
  delete from public.appointments      where clinic_id = v_clinic and notes like '[demo]%';
  delete from public.leads             where clinic_id = v_clinic and name like '[demo]%';
  delete from public.patients          where clinic_id = v_clinic and name like '[demo]%';
  raise notice 'seed removido';
end $$;
