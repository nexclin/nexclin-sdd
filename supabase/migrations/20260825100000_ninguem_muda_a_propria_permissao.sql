-- Autoconcessão de permissão e de repasse em `team_members`.
--
-- Achado em 25/08/2026 por leitura de migração, usando a régua NGS1 da
-- certificação SBIS como espelho: o requisito `NGS1.03.11` diz que ninguém
-- altera as permissões do próprio usuário. Registro completo em
-- `docs/seguranca/autoconcessao-team-members-2026-08-25.md`.
--
-- O documento encaminhava a correção para depois do lançamento. **O Arthur
-- decidiu o contrário em 25/08: fechar agora, antes de 08/09.** Esta migração
-- é a decisão dele, escrita para ser o mais estreita possível.
--
-- # O buraco
--
-- Existe exatamente UMA policy na tabela, e ela é `FOR ALL` com a condição
-- sendo só o `clinic_id`:
--
--     USING (clinic_id = public.get_my_clinic_id())
--     WITH CHECK (clinic_id = public.get_my_clinic_id())
--
-- Mais `GRANT INSERT, UPDATE, DELETE ON public.team_members TO authenticated`.
--
-- Logo, qualquer membro autenticado dá UPDATE em qualquer linha da própria
-- clínica, inclusive na dele. Na leitura do código: uma secretária se promove a
-- `master`, e um profissional aumenta o próprio percentual de repasse.
--
-- O que ele NÃO é, e importa dizer para não virar alarme: não vaza entre
-- clínicas (o `clinic_id` é checado nos dois lados, e a âncora tem trigger
-- próprio), não fura o teto do plano (a cascata avalia `enabled_modules` antes
-- da permissão individual) e não alcança o papel global em `user_roles`, que é
-- superadmin desde `20260802073330`.
--
-- Fura a camada do meio, a permissão individual dentro da clínica, e a regra de
-- repasse, que é dinheiro.
--
-- # Por que TRIGGER e não policy
--
-- A regra não é "quem pode escrever nesta linha". É **"estas colunas não podem
-- mudar nestas condições"**. Policy expressa isso mal: um `WITH CHECK` enxerga
-- a linha depois da mudança, e não sabe o que havia antes. Trigger enxerga
-- `OLD` e `NEW` lado a lado, que é exatamente a comparação que a regra pede.
--
-- # Por que não mexo nos GRANTs nem na policy
--
-- O caminho mais limpo seria `GRANT UPDATE (colunas seguras)`, deixando as
-- colunas sensíveis inescreviveis por sessão de usuário. Ele quebraria a tela
-- de Equipe: `ConfigTeamDialog.tsx` faz UPDATE direto do cliente com o objeto
-- inteiro, e o admin perderia a capacidade de editar a permissão dos outros.
-- Consertar isso exigiria uma RPC nova na semana do lançamento.
--
-- O trigger fecha os dois furos sem tocar em nada que hoje funciona. A troca
-- por coluna, com RPC, fica para a spec de `equipe` na stack nova.
--
-- # O INSERT já estava fechado, e por acaso
--
-- Um membro poderia inserir uma segunda linha com o próprio `user_id` e
-- `permission_level = 'master'`. Não consegue: `idx_team_members_user_id_unique`
-- é UNIQUE sobre `user_id` onde ele não é nulo, desde `20260510225339`. Linha
-- com `user_id` nulo é inofensiva, porque `my_permission` procura por
-- `user_id`. Fica registrado que a proteção vem de um índice de unicidade, e
-- não de uma decisão de segurança: se aquele índice cair, o furo volta.

CREATE OR REPLACE FUNCTION public.barra_autoconcessao_em_team_members()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid       uuid := auth.uid();
  v_eh_admin  boolean;
  v_mudou_permissao boolean;
  v_mudou_repasse   boolean;
BEGIN
  -- Sem `auth.uid()` a escrita não veio de uma pessoa: é service role, trigger
  -- de cadastro, edge function ou migração. Esses caminhos já têm guarda
  -- própria, e barrá-los aqui quebraria o cadastro de clínica e o convite de
  -- equipe. Deixar passar é deliberado.
  IF v_uid IS NULL THEN
    RETURN NEW;
  END IF;

  -- Superadmin passa. Ele opera sob impersonação auditada, e a trilha em
  -- `superadmin_audit_log` é o controle desse caminho.
  IF public.is_superadmin(v_uid) THEN
    RETURN NEW;
  END IF;

  v_eh_admin := public.has_role(v_uid, 'admin');

  v_mudou_permissao :=
        NEW.permission_level IS DISTINCT FROM OLD.permission_level
     OR NEW.permissions      IS DISTINCT FROM OLD.permissions;

  v_mudou_repasse :=
        NEW.repasse_percent        IS DISTINCT FROM OLD.repasse_percent
     OR NEW.modelo_repasse         IS DISTINCT FROM OLD.modelo_repasse
     OR NEW.calcula_sobre          IS DISTINCT FROM OLD.calcula_sobre
     OR NEW.valor_fixo_sublocacao  IS DISTINCT FROM OLD.valor_fixo_sublocacao;

  -- Regra 1: ninguém muda a própria permissão. Nem o admin.
  --
  -- Para o admin isso não tira nada: `has_role(uid,'admin')` já devolve `full`
  -- em todo módulo, antes de a permissão individual ser consultada. A linha
  -- dele em `team_members` não é o que lhe dá acesso. Então proibir custa zero
  -- e faz a regra valer para todo mundo, sem exceção que precise ser explicada.
  IF v_mudou_permissao AND OLD.user_id IS NOT NULL AND OLD.user_id = v_uid THEN
    RAISE EXCEPTION
      'Ninguém altera a própria permissão. Peça a um administrador da clínica.'
      USING ERRCODE = '42501';
  END IF;

  -- Regra 2: repasse é decisão do dono, não de quem recebe.
  --
  -- Aqui a condição é o PAPEL e não a linha: um profissional não muda o repasse
  -- de ninguém, nem o próprio. Quem define quanto a clínica repassa é quem
  -- responde pela clínica.
  IF v_mudou_repasse AND NOT v_eh_admin THEN
    RAISE EXCEPTION
      'Só um administrador da clínica altera as regras de repasse.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.barra_autoconcessao_em_team_members() IS
  'NGS1.03.11: ninguem altera a propria permissao, e repasse so por admin. Compara OLD e NEW porque a regra e sobre a MUDANCA de coluna, nao sobre quem escreve na linha.';

REVOKE ALL ON FUNCTION public.barra_autoconcessao_em_team_members() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS team_members_barra_autoconcessao ON public.team_members;
CREATE TRIGGER team_members_barra_autoconcessao
  BEFORE UPDATE ON public.team_members
  FOR EACH ROW EXECUTE FUNCTION public.barra_autoconcessao_em_team_members();

-- ---------------------------------------------------------------------------
-- Como provar que funcionou, e por que a conferência de schema não basta
-- ---------------------------------------------------------------------------
--
-- Confirmar que o trigger existe prova que o objeto foi criado, não que a
-- regra pega. O que prova é tentar, logado como gente de verdade:
--
-- 1. Entre como um membro NÃO administrador da clínica.
-- 2. Tente mudar a própria permissão para `master` pela tela de Equipe.
--    Esperado: erro "Ninguém altera a própria permissão".
-- 3. Entre como administrador e mude a permissão de OUTRA pessoa.
--    Esperado: salva normalmente. **Este é o teste que importa mais**, porque
--    é o que diz que a correção não trancou a clínica fora da própria equipe.
-- 4. Como administrador, tente mudar a PRÓPRIA permissão.
--    Esperado: o mesmo erro do passo 2. Não tira acesso nenhum: o papel global
--    de admin continua dando `full` em todo módulo.
--
-- Enquanto os quatro não forem executados, isto é código lido, não
-- comportamento provado.
