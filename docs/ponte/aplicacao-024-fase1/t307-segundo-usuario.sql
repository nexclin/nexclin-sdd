-- T307 (024) e T206 (023): registrar o segundo usuário da Clínica Lançamento.
-- Só leitura. O resultado vai para docs/historico/, sem e-mail e sem senha,
-- com o id inteiro de team_members e só o prefixo do user_id.
-- Esperado: duas linhas com user_prefix (Dr. Lançamento, master; Sra. Maria,
-- operacional) e as demais sem user_id.
select tm.id as team_member_id, tm.name, tm.permission_level, tm.role, tm.active,
       tm.created_at, left(tm.user_id::text, 8) as user_prefix
  from public.team_members tm
 where tm.clinic_id = '45f88cf2-4440-48df-9a7c-dd46b90d366c'
 order by tm.created_at;
