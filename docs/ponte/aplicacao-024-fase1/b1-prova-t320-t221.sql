-- ===========================================================================
-- PROVAS T320 (024) e T221 a T223 (023), no editor, sem deixar rastro
-- ===========================================================================
-- Um bloco DO: cria o dado de prova, troca para o papel authenticated com o
-- JWT de Maria ou do Dr. Lancamento, tenta o que a regra proibe e o que ela
-- permite (controle positivo em cada uma), grava o resultado numa tabela
-- temporaria, volta a superusuario e APAGA o dado de prova. O DO e atomico:
-- se falhar no meio, nada fica. Ao fim, um SELECT mostra as linhas.
--
-- Clinica Lancamento 45f88cf2. Maria 68326ea2 (operacional). Dr 73deadca
-- (master). Joana f7c57275 (profile sem team_members, nao pode receber).

create temp table if not exists prova(ordem int, passo text, resultado text);
truncate prova;

do $$
declare
  v_clinic uuid := '45f88cf2-4440-48df-9a7c-dd46b90d366c';
  v_maria  uuid := '68326ea2-4c49-4742-b07a-0c333f199c6f';
  v_dr     uuid := '73deadca-6124-4f91-ac61-40a32e42fadc';
  v_joana  uuid := 'f7c57275-eabf-49e2-b2be-8fe8328249df';
  v_task   uuid;
  v_msg    uuid;
  n        int;
begin
  -- dado de prova, como superusuario
  insert into public.tasks (clinic_id, title, type, due_date, status, origem, responsible)
    values (v_clinic, 'PROVA T320 apagar', 'follow_up', now(), 'pendente', 'manual', '')
    returning id into v_task;

  -- ===== T320: como Maria, DELETE em tasks devolve 0; UPDATE devolve 1 =====
  perform set_config('request.jwt.claims', json_build_object('sub', v_maria, 'role', 'authenticated')::text, true);
  set local role authenticated;

  delete from public.tasks where id = v_task;
  get diagnostics n = row_count;
  insert into prova values (1, 'T320 DELETE em tasks como Maria', 'linhas apagadas: ' || n || ' (esperado 0)');

  update public.tasks set status = 'cancelada' where id = v_task;
  get diagnostics n = row_count;
  insert into prova values (2, 'T320 controle: UPDATE status como Maria', 'linhas: ' || n || ' (esperado 1)');

  -- ===== T221: INSERT assinado por outro recusado; em nome proprio passa =====
  begin
    insert into public.internal_messages (clinic_id, sender_id, recipient_id, body)
      values (v_clinic, v_dr, v_dr, 'x');
    insert into prova values (3, 'T221 INSERT com sender_id do Dr, como Maria', 'PASSOU (esperado recusa)');
  exception when others then
    insert into prova values (3, 'T221 INSERT com sender_id do Dr, como Maria', 'recusado: ' || sqlstate || ' ' || left(sqlerrm, 60));
  end;

  begin
    insert into public.internal_messages (clinic_id, recipient_id, body)
      values (v_clinic, v_dr, 'PROVA T221 apagar') returning id into v_msg;
    insert into prova values (4, 'T221 controle: INSERT em nome proprio para o Dr', 'INSERT 1 (esperado)');
  exception when others then
    insert into prova values (4, 'T221 controle: INSERT em nome proprio para o Dr', 'FALHOU: ' || sqlstate || ' ' || left(sqlerrm, 60));
  end;

  -- ===== T222: para membro sem login (Joana) recusado =====
  begin
    insert into public.internal_messages (clinic_id, recipient_id, body)
      values (v_clinic, v_joana, 'x');
    insert into prova values (5, 'T222 INSERT para Joana, sem team_members', 'PASSOU (esperado recusa)');
  exception when others then
    insert into prova values (5, 'T222 INSERT para Joana, sem team_members', 'recusado: ' || sqlstate || ' ' || left(sqlerrm, 60));
  end;

  -- ===== T223: como Dr, le a mensagem; UPDATE de body cai no trigger; read_at passa =====
  perform set_config('request.jwt.claims', json_build_object('sub', v_dr, 'role', 'authenticated')::text, true);

  select count(*) into n from public.internal_messages where id = v_msg;
  insert into prova values (6, 'T223 SELECT como o Dr, destinatario', 'linhas: ' || n || ' (esperado 1)');

  begin
    update public.internal_messages set body = 'editada' where id = v_msg;
    get diagnostics n = row_count;
    insert into prova values (7, 'T223 UPDATE de body como o Dr', 'PASSOU, linhas ' || n || ' (esperado recusa do trigger)');
  exception when others then
    insert into prova values (7, 'T223 UPDATE de body como o Dr', 'recusado: ' || sqlstate || ' ' || left(sqlerrm, 60));
  end;

  update public.internal_messages set read_at = now() where id = v_msg;
  get diagnostics n = row_count;
  insert into prova values (8, 'T223 controle: UPDATE de read_at como o Dr', 'linhas: ' || n || ' (esperado 1)');

  -- como Joana (terceira, com login mas fora da conversa): SELECT devolve 0
  perform set_config('request.jwt.claims', json_build_object('sub', v_joana, 'role', 'authenticated')::text, true);
  select count(*) into n from public.internal_messages where id = v_msg;
  insert into prova values (9, 'T223 SELECT como Joana, terceira', 'linhas: ' || n || ' (esperado 0)');

  -- limpeza, como superusuario
  reset role;
  delete from public.internal_messages where id = v_msg;
  delete from public.data_audit_log where record_id = v_task;
  delete from public.tasks where id = v_task;
  insert into prova values (10, 'limpeza', 'dado de prova apagado');
exception when others then
  reset role;
  insert into prova values (99, 'ERRO FORA DAS PROVAS', sqlstate || ' ' || sqlerrm);
end $$;

select ordem, passo, resultado from prova order by ordem;
