-- BLOCO 1B. Quem existe. Só lê. Não muda nada.
--
-- O Bloco 1 conta linhas. Este diz de QUEM elas são. É o que decide se o
-- Bloco 6 pode zerar tudo ou se alguma clínica precisa ser poupada.
--
-- Se aparecer mais de uma clínica com movimento, PARE e me diga antes de
-- seguir. Zerar a base é o único passo desta sequência sem volta, e a volta
-- possível é restaurar o backup do dia, que leva junto tudo o que veio depois.

SELECT
  c.id,
  c.name                                       AS clinica,
  c.created_at::date                           AS criada_em,
  (SELECT count(*) FROM public.team_members tm WHERE tm.clinic_id = c.id)  AS acessos,
  (SELECT count(*) FROM public.patients p      WHERE p.clinic_id = c.id)   AS pacientes,
  (SELECT count(*) FROM public.appointments a  WHERE a.clinic_id = c.id)   AS consultas,
  (SELECT count(*) FROM public.receivables r   WHERE r.clinic_id = c.id)   AS a_receber,
  (SELECT count(*) FROM public.tasks t         WHERE t.clinic_id = c.id)   AS tarefas,
  s.status                                     AS assinatura,
  pl.name                                      AS plano
FROM public.clinics c
LEFT JOIN public.account_subscriptions s ON s.clinic_id = c.id
LEFT JOIN public.plans pl                ON pl.id = s.plan_id
ORDER BY c.created_at;
