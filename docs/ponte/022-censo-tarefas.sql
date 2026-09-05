-- =============================================================================
-- 022 · CENSO DE TAREFAS · Fase 0 da frente 022
-- =============================================================================
-- Issues: T100 (#75), T101 (#76), T102 (#77)
-- Regra:  docs/regras/022-motor-de-rotina-da-clinica.md
--
-- COMO RODAR: editor de SQL, UM BLOCO POR VEZ, clicando por referencia.
-- NADA AQUI ESCREVE. O bloco 3 roda dentro de BEGIN/ROLLBACK.
--
-- O BLOCO 2 E O MAIS IMPORTANTE DESTE ARQUIVO. Ele mede o risco da Fase 1, que
--   nao e risco de codigo: e risco de DADO. tasks.responsible e texto digitado,
--   e converter texto livre em referencia sem saber quantos casam e adivinhacao
--   sobre tarefa de cliente real.
-- =============================================================================


-- =============================================================================
-- BLOCO 1 · As colunas de tasks  ·  T100 (#75)
-- =============================================================================
-- ESPERADO, segundo a secao 3 da regra 022:
--   type, title, description, due_date (TIMESTAMPTZ), status, completed_at,
--   patient_id, lead_id, created_by, origem com CHECK ('manual','automatica'),
--   e responsible como TEXT DEFAULT '' SEM CHAVE ESTRANGEIRA NENHUMA.
--   NAO existem: recorrencia, tarefa pai, comentario, template.

select
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema='public' and table_name='tasks'
order by ordinal_position;


-- -----------------------------------------------------------------------------
-- BLOCO 1b · responsible tem chave estrangeira?
-- -----------------------------------------------------------------------------
-- ESPERADO: zero. E o que transforma "a coluna mostra setor em vez de usuario"
--   de defeito de exibicao em ausencia de referencia. Mesma classe do
--   expenses.payment_method da regra 021.

select
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name  as referencia_tabela,
  ccu.column_name as referencia_coluna
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on kcu.constraint_name = tc.constraint_name
join information_schema.constraint_column_usage ccu
  on ccu.constraint_name = tc.constraint_name
where tc.table_schema='public'
  and tc.table_name='tasks'
  and tc.constraint_type='FOREIGN KEY'
order by kcu.column_name;


-- -----------------------------------------------------------------------------
-- BLOCO 1c · o alicerce do motor ja existe?
-- -----------------------------------------------------------------------------
-- ESPERADO: origem existe com CHECK ('manual','automatica'), e a coluna que
--   apontaria para uma rotina NAO existe. Nao falta o cano, falta a rotina em
--   cima dele. E por isso que o FR-013 proibe tabela paralela de eventos.

select
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='tasks' and column_name='origem')  as tem_origem,
  (select count(*) from information_schema.columns
    where table_schema='public' and table_name='tasks'
      and column_name ~* 'rotina|routine|recurr|template|parent|competencia')     as colunas_de_rotina,
  (select count(*) from information_schema.tables
    where table_schema='public' and table_name ~* 'rotina|routine|task_comment')  as tabelas_de_rotina;


-- -----------------------------------------------------------------------------
-- BLOCO 1d · os nove tipos de evento, medidos e nao supostos
-- -----------------------------------------------------------------------------
-- A regra 020 afirma que tasks e escrita automaticamente com nove tipos. Este
--   bloco mede quais existem de verdade e em que volume. Se vierem menos de
--   nove, a regra 020 se corrige.

select
  type,
  origem,
  count(*)                              as quantidade,
  min(created_at)::date                 as primeira,
  max(created_at)::date                 as ultima
from tasks
group by 1, 2
order by 3 desc;


-- =============================================================================
-- BLOCO 2 · O NUMERO QUE DIMENSIONA O RISCO DA FASE 1  ·  T101 (#76)
-- =============================================================================
-- Quantos valores distintos existem em responsible, e quantos casam com nome de
--   usuario. O que NAO casar precisa ir para a coluna de legado da T106 (#81),
--   e nunca ser descartado: perder atribuicao de tarefa de cliente real e dano
--   que nao se desfaz.
--
-- O casamento aqui e por nome exato, sem acento e sem caixa. E DE PROPOSITO
--   conservador: casamento aproximado atribui tarefa a pessoa errada, e ninguem
--   percebe ate alguem cobrar quem nao devia.

-- O casamento e por nome exato, sem caixa e com espacos aparados. NAO remove
--   acento, e isso e escolha: errar para MAIS no legado e o lado seguro do erro.
--   Nome com acento divergente aparece como "nao casa", vai para o legado, e
--   alguem olha. O contrario, casar por aproximacao, atribui tarefa a pessoa
--   errada e ninguem percebe ate alguem cobrar quem nao devia.

with distintos as (
  select nullif(trim(responsible), '') as nome, count(*) as tarefas
  from tasks
  group by 1
),
usuarios as (
  select distinct lower(trim(full_name)) as nome_normalizado
  from profiles
  where full_name is not null and trim(full_name) <> ''
)
select
  count(*) filter (where d.nome is null)                                        as valores_vazios,
  count(*) filter (where d.nome is not null)                                    as valores_distintos_preenchidos,
  count(*) filter (where d.nome is not null and u.nome_normalizado is not null) as casam_com_usuario,
  count(*) filter (where d.nome is not null and u.nome_normalizado is null)     as NAO_casam_e_vao_para_o_legado,
  coalesce(sum(d.tarefas) filter (where d.nome is not null and u.nome_normalizado is null), 0) as tarefas_em_risco,
  coalesce(sum(d.tarefas), 0)                                                   as tarefas_totais
from distintos d
left join usuarios u
  on lower(trim(d.nome)) = u.nome_normalizado;


-- -----------------------------------------------------------------------------
-- BLOCO 2b · A lista dos que nao casam, para olhar com os proprios olhos
-- -----------------------------------------------------------------------------
-- Se aqui aparecerem nomes de SETOR ("comercial", "recepcao") e nao de pessoa,
--   isso muda a Fase 1: parte do que esta em responsible nunca foi usuario, e
--   sim papel. Nesse caso, avise antes de escrever a conversao da T107 (#82).

select
  trim(responsible) as valor,
  count(*)          as tarefas
from tasks
where nullif(trim(responsible),'') is not null
  and lower(trim(responsible)) not in (
    select lower(trim(full_name)) from profiles
    where full_name is not null and trim(full_name) <> ''
  )
group by 1
order by 2 desc;


-- =============================================================================
-- BLOCO 3 · PROVA 2 · o buraco de permissao em tasks  ·  T102 (#77)
-- =============================================================================
-- AQUI E PIOR QUE NO FINANCEIRO por um motivo especifico: tasks carrega
--   patient_id. E a alinea (c) ao contrario, sobre dado ligado a paciente.
--
-- As mesmas tres armadilhas do censo financeiro valem: nada de tabela
--   temporaria, controle positivo obrigatorio, e tudo em BEGIN/ROLLBACK.
--
-- Preencha os dois user_id. Para achar candidatos, rode o BLOCO 3a.

-- -----------------------------------------------------------------------------
-- BLOCO 3a · Achar os dois usuarios de teste
-- -----------------------------------------------------------------------------
select
  p.user_id,
  p.full_name,
  tm.permission_level,
  tm.permissions -> 'tarefas' as permissao_tarefas,
  tm.active
from profiles p
left join team_members tm on tm.user_id = p.user_id
where p.clinic_id = 'd51ce6c7-582b-469b-a01b-608bd9b38885'
order by tm.permission_level nulls last, p.full_name;


-- -----------------------------------------------------------------------------
-- BLOCO 3b · O teste, com as duas metades
-- -----------------------------------------------------------------------------
BEGIN;

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" = '{"sub":"COLE_AQUI_O_USER_ID_NEGADO","role":"authenticated"}';

select set_config('nx022.negado_ve_tarefas',
  (select count(*)::text from tasks), true);
select set_config('nx022.negado_ve_com_paciente',
  (select count(*)::text from tasks where patient_id is not null), true);
select set_config('nx022.negado_permissao',
  coalesce(my_permission('tarefas'), 'nulo'), true);

SET LOCAL "request.jwt.claims" = '{"sub":"COLE_AQUI_O_USER_ID_LIBERADO","role":"authenticated"}';

select set_config('nx022.liberado_ve_tarefas',
  (select count(*)::text from tasks), true);
select set_config('nx022.liberado_permissao',
  coalesce(my_permission('tarefas'), 'nulo'), true);

RESET ROLE;
select
  current_setting('nx022.negado_permissao',       true) as permissao_do_negado,
  current_setting('nx022.negado_ve_tarefas',      true) as tarefas_que_o_negado_ve,
  current_setting('nx022.negado_ve_com_paciente', true) as dessas_quantas_tem_paciente,
  current_setting('nx022.liberado_permissao',     true) as permissao_do_liberado,
  current_setting('nx022.liberado_ve_tarefas',    true) as tarefas_que_o_liberado_ve,
  case
    when current_setting('nx022.liberado_ve_tarefas', true)::int = 0
      then 'TESTE INVALIDO: controle positivo voltou zero. Confira o user_id LIBERADO'
    when current_setting('nx022.negado_ve_com_paciente', true)::int > 0
      then 'DEFEITO CONFIRMADO, E COM PACIENTE JUNTO: modulo negado le tarefa ligada a paciente. E o FR-008'
    when current_setting('nx022.negado_ve_tarefas', true)::int > 0
      then 'DEFEITO CONFIRMADO: modulo negado le tarefas. E o FR-008'
    else 'SEM DEFEITO: a policy ja consulta a cascata. Corrija a secao 3 da regra'
  end as veredito;

ROLLBACK;


-- =============================================================================
-- REGISTRAR O RESULTADO  ·  T104 (#79)
-- =============================================================================
-- Copiar para docs/historico/, inclusive o que nao deu para conferir.
--
-- DOIS NUMEROS PRECISAM SAIR DAQUI, e sao eles que destravam a Fase 1:
--   1. quantos valores de responsible NAO casam, e quantas tarefas estao neles
--   2. se o modulo negado le tarefa, e se le tarefa com paciente
-- =============================================================================
