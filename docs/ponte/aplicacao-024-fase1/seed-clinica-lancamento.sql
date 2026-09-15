-- ===========================================================================
-- SEED de demonstração da Clínica Lançamento, para olhar o painel de Maria
-- ===========================================================================
-- Pedido do Arthur em 15/09: dado suficiente para ver o painel operacional
-- (regra 024, FR-014, os seis blocos), o ranking, a tela de tarefas e a caixa
-- de mensagens com conversa de verdade, e julgar layout, espaço e texto.
--
-- Tudo que este arquivo cria tem o prefixo "[demo]" no título, no nome ou no
-- corpo. A limpeza está em seed-clinica-lancamento-limpeza.sql e apaga só
-- isso. Rodar duas vezes NÃO duplica: o bloco confere o prefixo antes.
--
-- Roda como superusuário no editor, então passa por cima do RLS. Os ids de
-- membro são lidos de team_members na hora; os user_id são os já públicos
-- em b1-prova-t320-t221.sql. "Hoje" é o dia no fuso do Brasil.
--
-- O que fica em cada bloco do painel de Maria depois de rodar:
--   1. fila do dia: 4 consultas hoje, Dr. Lançamento, 2 confirmadas e 2 pendentes
--   2. minhas tarefas: 2 vencidas e 2 de hoje, todas de Maria
--   3. leads com cadência vencida: 3 (parados há 9, 12 e 20 dias)
--   4. mensagens não lidas: 2 para Maria (o Dr escreveu), 1 para o Dr
--   5. tarefas sem dono: 3 (uma delas recall_paciente)
--   6. recalls vencidos: 3 pacientes sem voltar há mais de 180 dias, 1 chegando
-- E para o ranking: 3 tarefas de Maria concluídas no prazo, 1 do Dr.

do $$
declare
  v_clinic   uuid := '45f88cf2-4440-48df-9a7c-dd46b90d366c';
  v_maria    uuid := '68326ea2-4c49-4742-b07a-0c333f199c6f';
  v_dr       uuid := '73deadca-6124-4f91-ac61-40a32e42fadc';
  v_maria_tm uuid;
  v_dr_tm    uuid;
  v_hoje     date := (now() at time zone 'America/Sao_Paulo')::date;
  p1 uuid; p2 uuid; p3 uuid; p4 uuid; p5 uuid; p6 uuid; p7 uuid;
  a1 uuid; a2 uuid;
  t1 uuid; t2 uuid; t5 uuid;
  l1 uuid;
begin
  if exists (select 1 from public.tasks where clinic_id = v_clinic and title like '[demo]%') then
    raise notice 'seed já aplicado; rode a limpeza antes de repetir';
    return;
  end if;

  select id into v_maria_tm from public.team_members where user_id = v_maria and clinic_id = v_clinic;
  select id into v_dr_tm    from public.team_members where user_id = v_dr    and clinic_id = v_clinic;
  if v_maria_tm is null or v_dr_tm is null then
    raise exception 'team_members de Maria ou do Dr não encontrado na clínica';
  end if;

  -- ===== pacientes =====
  insert into public.patients (clinic_id, name, phone, is_first_visit) values
    (v_clinic, '[demo] Ana Beatriz Souza',   '(11) 99801-0001', false) returning id into p1;
  insert into public.patients (clinic_id, name, phone, is_first_visit) values
    (v_clinic, '[demo] Carlos Eduardo Lima', '(11) 99801-0002', false) returning id into p2;
  insert into public.patients (clinic_id, name, phone, is_first_visit) values
    (v_clinic, '[demo] Fernanda Martins',    '(11) 99801-0003', false) returning id into p3;
  insert into public.patients (clinic_id, name, phone, is_first_visit) values
    (v_clinic, '[demo] João Pedro Almeida',  '(11) 99801-0004', false) returning id into p4;
  insert into public.patients (clinic_id, name, phone, is_first_visit) values
    (v_clinic, '[demo] Larissa Campos',      '(11) 99801-0005', true)  returning id into p5;
  insert into public.patients (clinic_id, name, phone, is_first_visit) values
    (v_clinic, '[demo] Marcos Vinícius Rocha','(11) 99801-0006', false) returning id into p6;
  insert into public.patients (clinic_id, name, phone, is_first_visit) values
    (v_clinic, '[demo] Patrícia Nogueira',   '(11) 99801-0007', false) returning id into p7;

  -- ===== consultas passadas, realizadas: alimentam o recall =====
  -- vencidos (recall_days padrão 180): 210, 240 e 400 dias; chegando: 170 dias
  insert into public.appointments (clinic_id, patient_id, date, status, doctor, doctor_member_id, responsible, responsible_member_id, notes) values
    (v_clinic, p1, (((v_hoje - 210) + time '10:00') at time zone 'America/Sao_Paulo'), 'realizada', 'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo]'),
    (v_clinic, p2, (((v_hoje - 240) + time '11:00') at time zone 'America/Sao_Paulo'), 'realizada', 'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo]'),
    (v_clinic, p3, (((v_hoje - 400) + time '15:00') at time zone 'America/Sao_Paulo'), 'realizada', 'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo]'),
    (v_clinic, p4, (((v_hoje - 170) + time '09:00') at time zone 'America/Sao_Paulo'), 'realizada', 'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo]');

  -- ===== consultas de hoje: a fila do dia =====
  insert into public.appointments (clinic_id, patient_id, date, status, doctor, doctor_member_id, responsible, responsible_member_id, notes) values
    (v_clinic, p5, ((v_hoje + time '09:00') at time zone 'America/Sao_Paulo'), 'confirmada', 'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo] primeira consulta')
    returning id into a1;
  insert into public.appointments (clinic_id, patient_id, date, status, doctor, doctor_member_id, responsible, responsible_member_id, notes) values
    (v_clinic, p6, ((v_hoje + time '10:30') at time zone 'America/Sao_Paulo'), 'agendada',   'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo]')
    returning id into a2;
  insert into public.appointments (clinic_id, patient_id, date, status, doctor, doctor_member_id, responsible, responsible_member_id, notes) values
    (v_clinic, p7, ((v_hoje + time '14:00') at time zone 'America/Sao_Paulo'), 'confirmada', 'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo]'),
    (v_clinic, p4, ((v_hoje + time '16:00') at time zone 'America/Sao_Paulo'), 'agendada',   'Dr. Lançamento', v_dr_tm, 'Sra. Maria', v_maria_tm, '[demo] retorno');

  -- ===== leads parados: cadência vencida =====
  insert into public.leads (clinic_id, name, phone, funnel_stage, status, responsible, interest, created_at, updated_at) values
    (v_clinic, '[demo] Renata Oliveira',  '(11) 99802-0001', 'novo_contato',   'novo', 'Sra. Maria', 'Limpeza de pele', now() - interval '20 days', now() - interval '20 days'),
    (v_clinic, '[demo] Thiago Ferreira',  '(11) 99802-0002', 'em_atendimento', 'novo', 'Sra. Maria', 'Avaliação',       now() - interval '12 days', now() - interval '12 days'),
    (v_clinic, '[demo] Bruna Castro',     '(11) 99802-0003', 'novo_contato',   'novo', 'Dr. Lançamento', 'Retorno',     now() - interval '9 days',  now() - interval '9 days');
  select id into l1 from public.leads where clinic_id = v_clinic and name = '[demo] Renata Oliveira';

  -- ===== tarefas =====
  -- de Maria: 2 vencidas, 2 de hoje
  insert into public.tasks (clinic_id, title, description, type, origem, due_date, status, responsible, responsible_member_id, patient_id, lead_id, created_by) values
    (v_clinic, '[demo] Confirmar consulta de Larissa Campos', 'Ligar e confirmar horário de amanhã', 'confirmar_agendamento', 'automatica', (((v_hoje - 2) + time '18:00') at time zone 'America/Sao_Paulo'), 'pendente', 'Sra. Maria', v_maria_tm, p5, null, v_maria)
    returning id into t1;
  insert into public.tasks (clinic_id, title, description, type, origem, due_date, status, responsible, responsible_member_id, patient_id, lead_id, created_by) values
    (v_clinic, '[demo] Retornar contato de Renata Oliveira', 'Lead sem resposta há 20 dias', 'follow_up', 'manual', (((v_hoje - 1) + time '12:00') at time zone 'America/Sao_Paulo'), 'pendente', 'Sra. Maria', v_maria_tm, null, l1, v_maria)
    returning id into t2;
  insert into public.tasks (clinic_id, title, description, type, origem, due_date, status, responsible, responsible_member_id, patient_id, created_by) values
    (v_clinic, '[demo] Enviar anamnese para Marcos Vinícius', 'Consulta às 10h30', 'envio_anamnese', 'automatica', ((v_hoje + time '09:00') at time zone 'America/Sao_Paulo'), 'pendente', 'Sra. Maria', v_maria_tm, p6, v_maria),
    (v_clinic, '[demo] Separar prontuário de Patrícia Nogueira', null, 'outro', 'manual', ((v_hoje + time '13:00') at time zone 'America/Sao_Paulo'), 'pendente', 'Sra. Maria', v_maria_tm, p7, v_maria);

  -- sem dono: 3, uma delas recall_paciente
  insert into public.tasks (clinic_id, title, description, type, origem, due_date, status, responsible, responsible_member_id, patient_id, created_by) values
    (v_clinic, '[demo] Recall: Fernanda Martins sem voltar há 400 dias', null, 'recall_paciente', 'automatica', ((v_hoje + time '18:00') at time zone 'America/Sao_Paulo'), 'pendente', '', null, p3, null)
    returning id into t5;
  insert into public.tasks (clinic_id, title, description, type, origem, due_date, status, responsible, responsible_member_id, lead_id, created_by) values
    (v_clinic, '[demo] Recaptar Thiago Ferreira', 'Parou em atendimento', 'recaptacao_lead', 'automatica', (((v_hoje + 1) + time '12:00') at time zone 'America/Sao_Paulo'), 'pendente', '', null, null, null),
    (v_clinic, '[demo] Conferir estoque de material de consultório', null, 'outro', 'manual', (((v_hoje + 2) + time '12:00') at time zone 'America/Sao_Paulo'), 'pendente', '', null, null, v_dr);

  -- do Dr: 1 vencida, 1 de hoje
  insert into public.tasks (clinic_id, title, description, type, origem, due_date, status, responsible, responsible_member_id, patient_id, created_by) values
    (v_clinic, '[demo] Laudo de Carlos Eduardo Lima', 'Paciente cobrou por WhatsApp', 'pos_consulta', 'manual', (((v_hoje - 3) + time '12:00') at time zone 'America/Sao_Paulo'), 'pendente', 'Dr. Lançamento', v_dr_tm, p2, v_dr),
    (v_clinic, '[demo] Revisar plano de tratamento de Ana Beatriz', null, 'pos_consulta', 'manual', ((v_hoje + time '17:00') at time zone 'America/Sao_Paulo'), 'pendente', 'Dr. Lançamento', v_dr_tm, p1, v_dr);

  -- concluídas no prazo, para o ranking: 3 de Maria, 1 do Dr; 1 cancelada
  insert into public.tasks (clinic_id, title, type, origem, due_date, completed_at, status, responsible, responsible_member_id, created_by) values
    (v_clinic, '[demo] Confirmar consulta de João Pedro',   'confirmar_agendamento', 'automatica', (((v_hoje - 5) + time '18:00') at time zone 'America/Sao_Paulo'), (((v_hoje - 5) + time '10:00') at time zone 'America/Sao_Paulo'), 'concluida', 'Sra. Maria', v_maria_tm, v_maria),
    (v_clinic, '[demo] Enviar anamnese para Ana Beatriz',  'envio_anamnese',        'automatica', (((v_hoje - 4) + time '18:00') at time zone 'America/Sao_Paulo'), (((v_hoje - 4) + time '09:30') at time zone 'America/Sao_Paulo'), 'concluida', 'Sra. Maria', v_maria_tm, v_maria),
    (v_clinic, '[demo] Ligar para Bruna Castro',            'follow_up',             'manual',     (((v_hoje - 2) + time '18:00') at time zone 'America/Sao_Paulo'), (((v_hoje - 2) + time '15:00') at time zone 'America/Sao_Paulo'), 'concluida', 'Sra. Maria', v_maria_tm, v_maria),
    (v_clinic, '[demo] Assinar receita de Marcos Vinícius', 'pos_consulta',          'manual',     (((v_hoje - 1) + time '18:00') at time zone 'America/Sao_Paulo'), (((v_hoje - 1) + time '11:00') at time zone 'America/Sao_Paulo'), 'concluida', 'Dr. Lançamento', v_dr_tm, v_dr),
    (v_clinic, '[demo] Orçamento duplicado',                'outro',                 'manual',     (((v_hoje - 6) + time '18:00') at time zone 'America/Sao_Paulo'), null, 'cancelada', 'Sra. Maria', v_maria_tm, v_maria);

  -- ===== comentários numa tarefa =====
  insert into public.task_comments (clinic_id, task_id, author_id, body, created_at) values
    (v_clinic, t1, v_dr,    '[demo] Maria, ela pediu para trocar para a tarde, se der.', now() - interval '26 hours'),
    (v_clinic, t1, v_maria, '[demo] Vi. Tento hoje às 14h.', now() - interval '25 hours');

  -- ===== mensagens internas: a conversa entre Maria e o Dr =====
  insert into public.internal_messages (clinic_id, sender_id, recipient_id, body, ref_type, ref_id, created_at, read_at) values
    (v_clinic, v_maria, v_dr,    '[demo] Bom dia, doutor. A Larissa confirmou as 9h. Primeira consulta, sem anamnese ainda.', 'appointment', a1, now() - interval '3 hours', now() - interval '2 hours 50 minutes'),
    (v_clinic, v_dr,    v_maria, '[demo] Bom dia. Pode mandar a anamnese pelo WhatsApp dela antes das 9?', 'appointment', a1, now() - interval '2 hours 45 minutes', now() - interval '2 hours 40 minutes'),
    (v_clinic, v_maria, v_dr,    '[demo] Enviada. O Marcos das 10h30 ainda não confirmou, vou ligar.', 'appointment', a2, now() - interval '2 hours 30 minutes', now() - interval '2 hours'),
    (v_clinic, v_dr,    v_maria, '[demo] O laudo do Carlos eu termino hoje à tarde. Se ele ligar, avisa que sai até as 18h.', null, null, now() - interval '55 minutes', null),
    (v_clinic, v_dr,    v_maria, '[demo] E essa tarefa de recall da Fernanda está sem dono. Assume?', 'task', t5, now() - interval '40 minutes', null),
    (v_clinic, v_maria, v_dr,    '[demo] Assumo sim. Já vi a Fernanda na lista de recall.', 'task', t5, now() - interval '35 minutes', null);

  raise notice 'seed aplicado: 7 pacientes, 8 consultas, 3 leads, 14 tarefas, 2 comentários, 6 mensagens';
end $$;
