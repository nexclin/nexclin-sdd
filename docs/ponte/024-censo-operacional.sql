-- =============================================================================
-- 024 · CENSO OPERACIONAL · Fase 0 da frente 024
-- =============================================================================
-- Issues: T301 (#151), T302 (#152), T303 (#153), T304 (#154)
-- Regra:  docs/regras/024-perfil-operacional.md, secao 3 e secao 4
-- Plano:  docs/planos/024-perfil-operacional/plan.md, Fase 0
--
-- COMO RODAR: editor de SQL da plataforma (More > Cloud > SQL editor), UM BLOCO
--   POR VEZ, clicando por referencia e nao por coordenada. O Arthur clica Run.
-- NADA AQUI ESCREVE. Sao consultas a information_schema, pg_catalog e contagens.
--
-- O resultado vai para docs/historico/2026-09-NN-censo-operacional.md (T306).
--   Se divergir da secao 3 da regra, A DIVERGENCIA E O ACHADO, e a regra se
--   corrige antes de qualquer migracao da Fase 1.
--
-- Estado deste arquivo em 14/09/2026: os quatro blocos estao escritos (T301 a T304).
-- =============================================================================


-- =============================================================================
-- BLOCO 1 · A premissa 1: todo membro que loga tem team_members.user_id?  ·  T301 (#151)
-- =============================================================================
-- E a premissa 1 da secao 4 da regra 024, e a mesma da secao 8.4 da regra 023.
--   Assumir tarefa (FR-007) grava responsible_member_id a partir do team_members
--   do usuario logado. Quem loga e nao tem team_members, ou tem team_members
--   sem user_id, NAO CONSEGUE ASSUMIR. E o Portao 3 do plano.
--
-- A migracao 20260825080000 registrou a divida: "o dono entra em team_members
--   sem user_id". Este bloco mede o tamanho dela por clinica, em vez de
--   assumir.
--
-- TRES LEITURAS, e as tres precisam voltar numero:
--   1a. team_members sem user_id, por clinica (a divida da migracao de 25/08).
--   1b. profiles que logam e nao tem NENHUMA linha em team_members da propria
--       clinica (quem nao aparece em lugar nenhum).
--   1c. CONTROLE POSITIVO: team_members COM user_id, por clinica. Se 1a e 1b
--       voltarem zero e 1c tambem voltar zero, a consulta esta errada e nao a
--       clinica esta em ordem. Toda afirmacao negativa precisa do controle.


-- -----------------------------------------------------------------------------
-- BLOCO 1a · team_members sem user_id, por clinica
-- -----------------------------------------------------------------------------
-- ESPERADO, pela migracao de 25/08: pelo menos 1 por clinica criada antes dela
--   (o dono). Membro convidado e ainda sem login tambem cai aqui, e isso NAO e
--   defeito: e convite pendente. A coluna invite_status separa os dois casos.

select
  c.name                                   as clinica,
  tm.clinic_id,
  count(*)                                 as membros_sem_user_id,
  count(*) filter (where tm.active)        as ativos_sem_user_id,
  count(*) filter (where tm.permission_level = 'master') as masters_sem_user_id,
  string_agg(
    tm.name || ' [' || tm.role || ', ' || coalesce(tm.invite_status, '?') || ']',
    '; ' order by tm.name
  )                                        as quem
from public.team_members tm
join public.clinics c on c.id = tm.clinic_id
where tm.user_id is null
group by c.name, tm.clinic_id
order by c.name;


-- -----------------------------------------------------------------------------
-- BLOCO 1b · quem loga e nao esta em team_members da propria clinica
-- -----------------------------------------------------------------------------
-- ESPERADO: o dono das clinicas de agosto, se a linha dele em team_members nao
--   existe (caso diferente do 1a, em que a linha existe sem user_id).
-- O criterio de "loga" e ter profiles.user_id, porque profiles referencia
--   auth.users com ON DELETE CASCADE: profile que existe e usuario que existe.
-- Superadmin nao tem clinic_id e nao entra: a linha where p.clinic_id is not
--   null tira ele de proposito.

select
  c.name                                   as clinica,
  p.clinic_id,
  p.full_name,
  p.user_id,
  exists (
    select 1 from public.user_roles ur
    where ur.user_id = p.user_id and ur.role = 'admin'
  )                                        as eh_admin_da_clinica
from public.profiles p
join public.clinics c on c.id = p.clinic_id
where p.clinic_id is not null
  and not exists (
    select 1 from public.team_members tm
    where tm.clinic_id = p.clinic_id
      and tm.user_id = p.user_id
  )
order by c.name, p.full_name;


-- -----------------------------------------------------------------------------
-- BLOCO 1c · CONTROLE POSITIVO: team_members com user_id, por clinica
-- -----------------------------------------------------------------------------
-- ESPERADO: a Claros Clinic com 6 e a Cezar Essence com 3 (ou 4, se o medico
--   logou), pelo handoff de 11/09. A clinica de teste com 1, ate a issue #50
--   entregar o segundo usuario (Maria), e 2 depois.
-- Se este bloco voltar vazio, o problema e a consulta, nao o banco.

select
  c.name                                   as clinica,
  tm.clinic_id,
  count(*)                                 as membros_com_user_id,
  count(*) filter (where tm.active)        as ativos_com_user_id,
  count(*) filter (where tm.role = 'medico') as medicos_com_user_id,
  string_agg(tm.name || ' [' || tm.role || ']', '; ' order by tm.name) as quem
from public.team_members tm
join public.clinics c on c.id = tm.clinic_id
where tm.user_id is not null
group by c.name, tm.clinic_id
order by c.name;


-- -----------------------------------------------------------------------------
-- BLOCO 1d · o resumo em uma linha, para o historico
-- -----------------------------------------------------------------------------
-- Uma linha por clinica com as tres contagens lado a lado. E esta tabela que
--   vai para docs/historico/2026-09-NN-censo-operacional.md.
-- profiles_fora conta o 1b; sem_user_id conta o 1a; com_user_id conta o 1c.

select
  c.name                                                   as clinica,
  c.id                                                     as clinic_id,
  (select count(*) from public.team_members tm
     where tm.clinic_id = c.id and tm.user_id is not null) as com_user_id,
  (select count(*) from public.team_members tm
     where tm.clinic_id = c.id and tm.user_id is null)     as sem_user_id,
  (select count(*) from public.profiles p
     where p.clinic_id = c.id
       and not exists (select 1 from public.team_members tm
                       where tm.clinic_id = c.id and tm.user_id = p.user_id)) as profiles_fora
from public.clinics c
order by c.name;

-- LEITURA DO RESULTADO:
--   sem_user_id = 0 e profiles_fora = 0 em toda clinica  -> premissa 1 vale,
--     Portao 3 nao existe, e a Fase 3 nao ganha item.
--   sem_user_id > 0 ou profiles_fora > 0 em alguma clinica -> Portao 3 abre:
--     T352 leva o numero ao Arthur com os dois caminhos (migracao a partir de
--     profiles, ou tela do superadmin). NAO E DESTA REGRA DECIDIR.
--   com_user_id = 0 em toda clinica -> a consulta esta errada. Parar e conferir
--     antes de registrar qualquer coisa.


-- =============================================================================
-- BLOCO 2 · O trigger de auditoria existe no banco ao vivo, e onde?  ·  T302 (#152)
-- =============================================================================
-- A Fase 1 (T310) ESTENDE o trigger audita_mudanca_de_dado a tasks e
--   appointments. So faz sentido se ele existir no banco ao vivo: ele foi
--   escrito neste repositorio (migracoes 20260825060000 e 20260827030000) e
--   NAO esta no clone da Lovable, entao chegou ao banco por bloco de SQL, ou
--   nao chegou. Este bloco decide.
--
-- ESPERADO, pelas duas migracoes:
--   a funcao public.audita_mudanca_de_dado() existe;
--   a tabela public.data_audit_log existe;
--   triggers *_audita_mudanca, AFTER INSERT OR UPDATE OR DELETE, FOR EACH ROW,
--   em: patients, channels, origins, objections, services, payment_methods,
--   expense_categories (7 tabelas). NENHUM em tasks nem em appointments ainda.
--
-- Se a funcao nao existir: a Fase 1 ganha um item antes de T310, trazer a
--   migracao de 25/08 inteira, e a regra 024 (secao 3, linha "auditoria de
--   tasks e appointments") esta assumindo algo que nao esta no ar.

-- -----------------------------------------------------------------------------
-- BLOCO 2a · a funcao e a tabela existem?
-- -----------------------------------------------------------------------------
-- ESPERADO: uma linha para a funcao e uma para a tabela. Duas linhas.

select 'funcao' as o_que, p.proname as nome, pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'audita_mudanca_de_dado'
union all
select 'tabela', t.table_name, ''
from information_schema.tables t
where t.table_schema = 'public' and t.table_name = 'data_audit_log';


-- -----------------------------------------------------------------------------
-- BLOCO 2b · em quais tabelas o trigger esta ligado
-- -----------------------------------------------------------------------------
-- ESPERADO: 7 linhas, as tabelas listadas acima, todas com
--   'AFTER INSERT OR DELETE OR UPDATE' e 'FOR EACH ROW'.
--   tasks e appointments NAO devem aparecer. Se aparecerem, alguem ja fez a
--   Fase 1 pela metade, e T310 vira conferencia em vez de criacao.

select
  c.relname                                   as tabela,
  t.tgname                                    as trigger,
  pg_get_triggerdef(t.oid)                    as definicao
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
join pg_proc p on p.oid = t.tgfoid
where n.nspname = 'public'
  and p.proname = 'audita_mudanca_de_dado'
  and not t.tgisinternal
order by c.relname;


-- -----------------------------------------------------------------------------
-- BLOCO 2c · CONTROLE POSITIVO: os outros triggers de tasks e appointments
-- -----------------------------------------------------------------------------
-- ESPERADO em tasks: trg_set_task_completed_at (BEFORE UPDATE, migracao de
--   10/05) e o de updated_at, se houver. Se 2b nao mostrou tasks e este bloco
--   tambem nao mostrar nada, a consulta a pg_trigger esta errada, e nao o
--   banco sem trigger.

select
  c.relname                as tabela,
  t.tgname                 as trigger,
  pg_get_triggerdef(t.oid) as definicao
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('tasks', 'appointments')
  and not t.tgisinternal
order by c.relname, t.tgname;


-- =============================================================================
-- BLOCO 3 · tasks.type tem CHECK, ou e texto livre?  ·  T303 (#153)
-- =============================================================================
-- Decide a forma de T312: se ha CHECK em type, 'recall_paciente' exige ALTER
--   da constraint; se nao ha, o tipo novo entra so na lista do front
--   (src/lib/tiposDeTarefa.ts, T343) e T312 vira comentario.
--
-- ESPERADO, pela migracao 20260825090000, que diz em comentario que
--   "tasks.type e TEXT sem CHECK": NENHUMA constraint sobre type, e UMA sobre
--   origem, CHECK (origem IN ('manual', 'automatica')). A constraint de origem
--   e o controle positivo deste bloco: se ela nao aparecer, a consulta esta
--   errada.

-- -----------------------------------------------------------------------------
-- BLOCO 3a · todas as CHECK de tasks, com a coluna que cada uma cobre
-- -----------------------------------------------------------------------------

select
  con.conname                          as constraint_name,
  pg_get_constraintdef(con.oid)        as definicao,
  array_agg(att.attname order by att.attname) as colunas
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
left join lateral unnest(con.conkey) as k(attnum) on true
left join pg_attribute att on att.attrelid = c.oid and att.attnum = k.attnum
where n.nspname = 'public'
  and c.relname = 'tasks'
  and con.contype = 'c'
group by con.conname, con.oid
order by con.conname;


-- -----------------------------------------------------------------------------
-- BLOCO 3b · o tipo e enum? e os valores que ja existem em type
-- -----------------------------------------------------------------------------
-- ESPERADO: data_type = 'text' (nao 'USER-DEFINED', que seria enum).
-- A segunda consulta lista os valores distintos de type com contagem, para
--   conferir que 'recall_paciente' nao existe ainda e que 'recall' (o
--   automatico da 020) e 'recaptacao_*' sao os vizinhos com que ele nao pode
--   se confundir.

select column_name, data_type, udt_name, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'tasks' and column_name = 'type';

select coalesce(type, '(nulo)') as type, count(*) as tarefas
from public.tasks
group by type
order by tarefas desc, type;


-- =============================================================================
-- BLOCO 4 · As policies de tasks e appointments, como estao  ·  T304 (#154)
-- =============================================================================
-- ESPERADO, pela migracao 20260322133319 e por nenhuma posterior ter mexido:
--   tasks:        UMA policy, "Users can manage tasks in their clinic",
--                 cmd = ALL, roles = {authenticated}, qual por clinic_id.
--   appointments: UMA policy, "Users can manage appointments in their clinic",
--                 mesma forma.
--   Nenhuma delas chama my_permission (e o FR-011 da regra 021, medido em
--   07/09 nas 79 policies).
--
-- E o que sustenta o fato 3 do plano: tirar o DELETE do FR-009 e QUEBRAR a
--   policy FOR ALL de tasks em tres (T313), e nao apagar uma quarta. Se
--   voltar mais de uma policy por tabela, o plano esta errado e T313 muda.

-- -----------------------------------------------------------------------------
-- BLOCO 4a · as policies, uma por linha
-- -----------------------------------------------------------------------------

select
  tablename,
  policyname,
  cmd,
  roles,
  permissive,
  qual,
  with_check,
  (coalesce(qual, '') || coalesce(with_check, '')) like '%my_permission%' as chama_my_permission
from pg_policies
where schemaname = 'public'
  and tablename in ('tasks', 'appointments')
order by tablename, policyname;


-- -----------------------------------------------------------------------------
-- BLOCO 4b · RLS esta ligado nas duas? e o que authenticated pode fazer
-- -----------------------------------------------------------------------------
-- ESPERADO: relrowsecurity = true nas duas. E os GRANTs de authenticated
--   incluindo DELETE hoje: e por isso que tirar o DELETE e pela policy, e nao
--   so pelo botao. Se o GRANT de DELETE nao existir, T313 fica mais simples
--   e T320 precisa de outra prova.

select c.relname as tabela, c.relrowsecurity as rls_ligado, c.relforcerowsecurity as rls_forcado
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('tasks', 'appointments')
order by c.relname;

select table_name, grantee, string_agg(privilege_type, ', ' order by privilege_type) as privilegios
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('tasks', 'appointments')
  and grantee in ('authenticated', 'anon')
group by table_name, grantee
order by table_name, grantee;


-- -----------------------------------------------------------------------------
-- BLOCO 4c · CONTROLE POSITIVO: uma tabela que tem policy por operacao
-- -----------------------------------------------------------------------------
-- task_comments nasceu em 07/09 com duas policies separadas, SELECT e INSERT
--   (docs/ponte/aplicacao-023/b1). Se este bloco mostrar as duas, a leitura de
--   pg_policies esta boa e o "uma policy so" de 4a e fato, nao falha de
--   consulta.

select tablename, policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'task_comments'
order by policyname;
