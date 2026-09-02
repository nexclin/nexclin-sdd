-- 20260828020000_apresentacao_inicial_por_usuario.sql
--
-- Regra 005, FR-016: a marca de "ja viu a apresentacao inicial" passa a ser
-- coluna por usuario, e para de viver no navegador.
--
-- A divida foi contraida hoje, 28/08/2026, e de olhos abertos. Na plataforma
-- Lovable a marca ficou no `localStorage` porque coluna nova exigiria o export
-- do banco e a mao do Arthur no SQL editor, e a conta mestra estava TRANCADA
-- fora do sistema naquele momento. O custo aceito foi ver a apresentacao uma
-- vez a mais num navegador novo. A regra registrou a escolha como divida a
-- pagar, nao como padrao a copiar. Isto e o pagamento.
--
-- Por que `timestamptz` e nao `boolean`:
--
--   Um booleano responde "viu?". Um carimbo responde "viu?" e "quando?", pelo
--   mesmo espaco. O "quando" tem dois usos concretos: suporte, para saber se a
--   pessoa passou pela apresentacao antes ou depois de uma mudanca de tela, e
--   produto, para decidir se um redesenho grande justifica reapresentar a quem
--   viu a versao antiga. Booleano joga isso fora e nao volta atras.
--
--   `NULL` significa "nunca viu". Nao ha default: quem nunca viu nao tem data.
--
-- Por que em `profiles`, e nao em tabela nova:
--
--   E um fato por usuario, do tamanho de uma coluna. Tabela nova custaria RLS
--   propria, policy propria e um join, para guardar um carimbo. E `profiles` ja
--   tem a policy "Users can update their own profile" (20260817021500), com
--   `USING (user_id = auth.uid())`, entao a coluna nasce protegida: cada um
--   escreve a propria marca e a de mais ninguem. Nenhuma policy nova.
--
-- Por que NAO entra na auditoria da regra (d):
--
--   A regra (d) cobre "toda acao administrativa sobre dado de cliente". Marcar
--   que se viu a propria apresentacao nao e administrativa, nao e sobre dado de
--   cliente, e nao tem `old -> new` que interesse a ninguem. Auditar isso
--   encheria a trilha de ruido e tornaria mais dificil achar o que importa.
--   O gatilho `trg_audit_superadmin_profile_edit` continua valendo para o que
--   ele ja cobria: edicao de perfil por superadmin.
--
-- Por que NAO ha backfill, que a revisao de codigo levantou:
--
--   A objecao foi que, sem backfill, todo usuario existente fica NULL e vera a
--   apresentacao de novo. A objecao vale para uma coluna que descreve algo ja
--   acontecido; esta nao descreve.
--
--   A apresentacao inicial NAO EXISTE nesta stack. `app/app/` tem
--   `configuracoes` e `conta-suspensa`, e mais nada. Ninguem viu a apresentacao
--   daqui porque nao ha o que ver, entao NULL nao e lacuna: e o valor
--   verdadeiro para todo mundo, hoje.
--
--   Preencher com `now()` afirmaria que 17 pessoas viram uma tela que nunca foi
--   construida, e a primeira pessoa a abrir a stack nova nunca veria a
--   apresentacao. O backfill e que criaria o defeito.
--
--   A marca do `localStorage` da Lovable tambem nao se migra, e nem deveria:
--   e outra apresentacao, noutra plataforma, com outro conteudo.
--
-- Faixa A da Sec. 2.5: e banco, e migra intacta.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS onboarding_tour_seen_at timestamptz;

COMMENT ON COLUMN public.profiles.onboarding_tour_seen_at IS
  'Quando este usuario viu a apresentacao inicial. NULL = nunca viu. '
  'Regra 005, FR-016. Substitui o localStorage usado na plataforma Lovable.';
