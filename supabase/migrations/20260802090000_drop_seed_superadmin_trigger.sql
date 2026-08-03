-- SPEC 001 / Fase 1 (T003) — exceção deliberada do seed de e-mail fixo.
--
-- Remove APENAS o trigger que semeava o superadmin a partir de um e-mail
-- fixo (erpclinicas@gmail.com). A FUNÇÃO seed_superadmin_operator() é
-- mantida de propósito: a migração 20260802073330 faz
-- `REVOKE EXECUTE ON FUNCTION public.seed_superadmin_operator()`, então
-- dropar a função quebraria aquela migração. Sem o trigger, a função é
-- inofensiva (nunca dispara).
--
-- A criação do superadmin passa a ser feita pelo script scripts/seed.ts
-- (Fase 2), dirigido pela variável de ambiente SUPERADMIN_EMAIL — sem
-- e-mail fixo em código e sem senha em código (constituição, Princípios II e V).

DROP TRIGGER IF EXISTS on_auth_user_created_superadmin ON auth.users;
