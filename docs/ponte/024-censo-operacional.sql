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
-- Estado deste arquivo em 14/09/2026: so o BLOCO 1 esta escrito (T301).
--   Os blocos 2, 3 e 4 (T302, T303, T304) entram no mesmo arquivo.
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
