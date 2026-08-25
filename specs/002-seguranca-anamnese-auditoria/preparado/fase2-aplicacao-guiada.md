# Fase 2 da SPEC 002 — aplicação guiada, bloco a bloco

> **Para o Arthur executar à mão, no SQL editor da Lovable.**
> Escrito em 25/08/2026, com o export do dia já feito e conferido
> (`b56d8d5f…`, registrado em `docs/seguranca/registro-exports-banco.md`).

---

## Por que isto não é automatizado

Não é preguiça nem cautela genérica. Em 19/08 ficou **provado** que o SQL editor
da Lovable, dirigido por automação de navegador, executa uma consulta diferente
da que está na tela: a consulta-canário nunca apareceu no painel de resultados,
que continuou mostrando o resultado da consulta anterior. Está em
`docs/seguranca/nota-sql-editor-lovable-2026-08-19.md`.

**Divergência entre o exibido e o executado é inaceitável contra produção.** Não
dá para afirmar o que o banco recebeu, e toda a disciplina de "implementado ≠
funciona" depende de poder verificar.

Então o formato é este: **cinco blocos, colados um por vez, cada um com a sua
consulta de conferência logo depois.** Não avance um bloco sem que a conferência
do anterior tenha batido.

A fonte de verdade continua sendo a migração versionada,
`supabase/migrations/20260825060000_auditoria_de_dado_e_soft_delete_em_patients.sql`.
Este documento é a mesma coisa, fatiada para colar.

**Antes de começar:** `More → Cloud → SQL editor`. O deep link não sobrevive a
recarregamento, então navegue pelo menu.

---

## Bloco 1 de 5 — a tabela de auditoria

Puramente aditivo. Não toca em nada que já existe, então o risco é zero.

```sql
CREATE TABLE IF NOT EXISTS public.data_audit_log (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id      uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  actor          uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  table_name     text NOT NULL,
  action         text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  record_id      uuid NOT NULL,
  previous_state jsonb
);

CREATE INDEX IF NOT EXISTS data_audit_log_clinic_created_idx
  ON public.data_audit_log (clinic_id, created_at DESC);
CREATE INDEX IF NOT EXISTS data_audit_log_registro_idx
  ON public.data_audit_log (table_name, record_id);

ALTER TABLE public.data_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin da clinica ou superadmin leem a trilha"
  ON public.data_audit_log
  FOR SELECT
  TO authenticated
  USING (
    public.is_superadmin(auth.uid())
    OR (
      clinic_id = public.get_my_clinic_id()
      AND public.has_role(auth.uid(), 'admin')
    )
  );

REVOKE INSERT, UPDATE, DELETE ON public.data_audit_log FROM authenticated;
GRANT  SELECT ON public.data_audit_log TO authenticated;
```

### Confira o bloco 1

```sql
SELECT
  (SELECT count(*) FROM pg_policies
     WHERE tablename = 'data_audit_log')                AS politicas,
  (SELECT relrowsecurity FROM pg_class
     WHERE oid = 'public.data_audit_log'::regclass)     AS rls_ligada,
  (SELECT count(*) FROM information_schema.column_privileges
     WHERE table_name = 'data_audit_log'
       AND grantee = 'authenticated'
       AND privilege_type = 'INSERT')                   AS insert_concedido;
```

**Esperado:** `politicas = 1`, `rls_ligada = true`, `insert_concedido = 0`.

O `insert_concedido = 0` é o item mais importante da conferência inteira. É ele
que faz a trilha ser imutável: com RLS ligada e nenhuma permissão de escrita,
ninguém grava por sessão de usuário. Quem grava é o trigger do bloco 3, que roda
`SECURITY DEFINER` e não passa por RLS. Se este número vier diferente de zero, a
trilha é editável e **não serve como auditoria** — pare e me chame.

---

## Bloco 2 de 5 — a coluna de exclusão

Também aditivo. Coluna nova, anulável, sem default: nenhuma linha existente muda.

```sql
ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

CREATE INDEX IF NOT EXISTS patients_ativos_idx
  ON public.patients (clinic_id)
  WHERE deleted_at IS NULL;
```

### Confira o bloco 2

```sql
SELECT
  (SELECT count(*) FROM information_schema.columns
     WHERE table_name = 'patients' AND column_name = 'deleted_at') AS coluna,
  (SELECT count(*) FROM public.patients WHERE deleted_at IS NOT NULL) AS ja_excluidos,
  (SELECT count(*) FROM public.patients) AS total;
```

**Esperado:** `coluna = 1`, `ja_excluidos = 0`, e `total` igual ao número de
pacientes que a clínica tem hoje. Se `ja_excluidos` vier maior que zero, algo
preencheu a coluna, o que não deveria ser possível: pare.

---

## Bloco 3 de 5 — o trigger de auditoria

Primeiro bloco que muda comportamento: a partir daqui, **toda** escrita em
`patients` grava uma linha na trilha.

```sql
CREATE OR REPLACE FUNCTION public.audita_mudanca_de_dado()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clinic_id uuid;
  v_record_id uuid;
  v_previous  jsonb;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_clinic_id := NEW.clinic_id;
    v_record_id := NEW.id;
    v_previous  := NULL;
  ELSE
    v_clinic_id := OLD.clinic_id;
    v_record_id := OLD.id;
    v_previous  := to_jsonb(OLD);
  END IF;

  INSERT INTO public.data_audit_log (
    clinic_id, actor, table_name, action, record_id, previous_state
  ) VALUES (
    v_clinic_id, auth.uid(), TG_TABLE_NAME, TG_OP, v_record_id, v_previous
  );

  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.audita_mudanca_de_dado() FROM PUBLIC, anon;

DROP TRIGGER IF EXISTS patients_audita_mudanca ON public.patients;
CREATE TRIGGER patients_audita_mudanca
  AFTER INSERT OR UPDATE OR DELETE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION public.audita_mudanca_de_dado();
```

### Confira o bloco 3

```sql
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid = 'public.patients'::regclass
  AND NOT tgisinternal;
```

**Esperado:** aparecem `update_patients_updated_at` e
`patients_audita_mudanca`, os dois com `tgenabled = 'O'`.

### Prova de fogo do bloco 3, e faça ela

Não confie no trigger existir; prove que ele grava. Pela **tela do app**, edite
um paciente de teste (mude o telefone, por exemplo). Depois:

```sql
SELECT action, table_name, actor IS NOT NULL AS tem_autor,
       previous_state IS NOT NULL AS tem_estado_anterior, created_at
FROM public.data_audit_log
ORDER BY created_at DESC
LIMIT 3;
```

**Esperado:** uma linha `UPDATE` em `patients`, com `tem_autor = true` e
`tem_estado_anterior = true`. Isso fecha os aceites **T010** e **T012** de uma
vez.

Se `tem_autor` vier `false`, a edição não veio de uma sessão de usuário. Se
`tem_estado_anterior` vier `false`, o `to_jsonb(OLD)` falhou e a reconstrução
não é possível: pare.

---

## Bloco 4 de 5 — as policies. **Este é o único com risco real.**

Ele **derruba** a policy que hoje dá acesso a `patients` e cria três no lugar.
Entre o `DROP` e o `CREATE`, a tabela fica sem policy. Por isso: cole o bloco
**inteiro**, de uma vez, e não em partes.

O risco concreto se algo der errado no meio: a clínica para de ver os próprios
pacientes. A reversão está logo abaixo e leva dez segundos.

```sql
DROP POLICY IF EXISTS "Users can manage patients in their clinic" ON public.patients;

CREATE POLICY "Clinica le seus pacientes ativos"
  ON public.patients
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.get_my_clinic_id()
    AND deleted_at IS NULL
  );

CREATE POLICY "Clinica cadastra paciente"
  ON public.patients
  FOR INSERT
  TO authenticated
  WITH CHECK (clinic_id = public.get_my_clinic_id());

CREATE POLICY "Clinica atualiza e restaura seu paciente"
  ON public.patients
  FOR UPDATE
  TO authenticated
  USING (clinic_id = public.get_my_clinic_id())
  WITH CHECK (clinic_id = public.get_my_clinic_id());
```

### Confira o bloco 4

```sql
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'patients'
ORDER BY cmd;
```

**Esperado:** exatamente três linhas, com `cmd` valendo `INSERT`, `SELECT` e
`UPDATE`. **Nenhuma linha com `cmd = 'DELETE'`**, e nenhuma com `cmd = 'ALL'`.

E, no `SELECT`, o `qual` precisa conter `deleted_at IS NULL`. É essa condição
que impede a linha excluída de voltar às listas.

### Prova de fogo do bloco 4, e ela é obrigatória

**Abra o app e veja a lista de pacientes.** Ela precisa continuar mostrando
todos. Se aparecer vazia, a policy de leitura não está batendo, e a reversão é:

```sql
DROP POLICY IF EXISTS "Clinica le seus pacientes ativos" ON public.patients;
DROP POLICY IF EXISTS "Clinica cadastra paciente" ON public.patients;
DROP POLICY IF EXISTS "Clinica atualiza e restaura seu paciente" ON public.patients;

CREATE POLICY "Users can manage patients in their clinic" ON public.patients FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()))
  WITH CHECK (clinic_id IN (SELECT profiles.clinic_id FROM profiles WHERE profiles.user_id = auth.uid()));
```

Isso devolve o estado exato de antes, palavra por palavra. Se precisar usar,
me avise: significa que `get_my_clinic_id()` e o subselect em `profiles` não são
equivalentes em produção, e isso é um achado que muda a migração.

---

## Bloco 5 de 5 — tirar o DELETE da mão da aplicação

Último, e de propósito: até aqui, se algo desse errado, o `DELETE` ainda existia
como saída. Agora ele deixa de existir.

```sql
REVOKE DELETE ON public.patients FROM authenticated;
```

### Confira o bloco 5

```sql
SELECT count(*) AS delete_concedido
FROM information_schema.table_privileges
WHERE table_name = 'patients'
  AND grantee = 'authenticated'
  AND privilege_type = 'DELETE';
```

**Esperado:** `delete_concedido = 0`.

A partir daqui, exclusão de paciente pela aplicação **precisa** ser
`UPDATE ... SET deleted_at = now()`. É o próximo passo, e é o T009.

---

## O que fica pendente depois destes cinco blocos

| Item | Quem faz | Estado |
|---|---|---|
| **T009** — o app da plataforma passa a excluir com `deleted_at` e as listas filtram | Claude, pela ponte inversa | **só depois destes blocos.** Publicar o front antes da coluna existir quebra a exclusão na hora |
| **T011** — o paciente some da lista e a linha continua no banco | Arthur, na tela | aceite |
| **T013** — usuário de outra clínica não lê a trilha nem o paciente | Arthur | aceite de isolamento |
| **T014** — a mesma correção como migração versionada aqui | Claude | **já feito**, e antes: a migração foi escrita no repositório primeiro, que é o que a constituição manda |

**Uma ordem que não pode inverter:** enquanto o T009 não subir, a exclusão de
paciente pela tela vai **falhar**, porque o `DELETE` foi revogado no bloco 5 e o
app ainda tenta deletar. Entre o bloco 5 e o T009 existe uma janela em que
excluir paciente não funciona. Se a clínica estiver usando o sistema neste
momento, faça os cinco blocos e me chame na sequência, para eu fechar o T009
sem intervalo.
