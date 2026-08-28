# Nota operacional — o SQL editor do Lovable não é dirigível por automação

**Data:** 19/08/2026 · **Contexto:** tentativa de aplicar o Bloco B
(`WITH CHECK` na policy de UPDATE de `profiles`) no banco de produção.

## O que aconteceu

O SQL editor (`More → Cloud → SQL editor`) executou **uma** consulta com
sucesso e, a partir daí, parou de responder a novos comandos enviados por
automação de navegador. O texto digitado aparece corretamente no editor,
mas o botão *Run* passa a devolver sempre o resultado da **primeira**
consulta.

## Como isso foi provado

Consulta-canário deliberadamente distinta:

```sql
SELECT count(*) AS teste_canario FROM pg_policies WHERE tablename = 'profiles';
```

O cabeçalho `teste_canario` **nunca apareceu** no painel Results — que
continuou exibindo `cmd | policyname | qual | with_check` da consulta
anterior. Ou seja: a tela mostra uma consulta e o motor executa outra.

Causa provável: o editor é CodeMirror; digitação sintética (CDP) atualiza
o DOM mas não o estado interno que o botão *Run* lê. O `EditorView` não é
alcançável pelo DOM (`el.cmView` ausente), então não há como sincronizar
nem como verificar o que será enviado.

## Por que isso importa

**Divergência entre o exibido e o executado é inaceitável contra produção.**
Não é lentidão nem falha de clique: é a impossibilidade de afirmar o que
o banco recebeu. Toda a disciplina de "implementado ≠ funciona" depende de
poder verificar; aqui a verificação não existe.

## Consequência prática

- **Escritas no banco do Lovable são feitas à mão**, pelo Arthur, com
  colagem e clique reais. Automação de navegador só serve para **leitura**
  e conferência — e mesmo assim, com canário antes de confiar no resultado.
- Isso vale para a janela de **22–23/08** (Fase 2 da SPEC 002): o plano
  previa uma sequência de migrações; cada uma precisa de colagem manual e
  conferência individual, o que muda a estimativa de tempo.
- O deep link `?view=more&subview=cloud&section=sql` **não sobrevive a
  recarregamento** — volta para `subview=analytics`. Navegar pelo menu.

## Estado deixado no banco

Nenhuma alteração. Verificado por consulta direta após as tentativas:
a policy `Users can update their own profile` continua com
`qual = (user_id = auth.uid())` e `with_check = NULL` — exatamente o
estado original. Não houve aplicação parcial (o `DROP` não passou sozinho,
o que teria removido a policy).

## Achado colateral confirmado

O estado "antes" do Bloco B está **provado**, não presumido:
`with_check` é `NULL` na policy de UPDATE de `profiles` em produção. A
âncora multi-tenant está apoiada somente no trigger
`prevent_clinic_id_change`. O endurecimento continua necessário.
