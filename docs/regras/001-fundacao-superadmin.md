# 001 · Fundação: banco, auth, multi-tenant e Super Admin

> **Regra viva.** Nasceu antes da execução, guiou a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 27/08/2026:** banco replicado, seed rodado, edge functions no ar e
> app Next.js escrito. **Três provas de comportamento continuam abertas**, e por
> elas a regra não fecha. Alvo: a stack Next.js deste repositório.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Origem:** convertida da SPEC 001 em 27/08/2026, formato de sete seções.

---

## 1. O problema

O MVP construído no Lovable validou um banco inteiro, com isolamento
multi-tenant, cascata de permissão e painel de suporte, e validou junto uma
camada de aplicação de qualidade baixa, gerada por crédito. A saída não é
recomeçar: é levar o banco intacto para um Supabase próprio, onde 56 migrações
já provadas continuam sendo a autoridade sobre quem lê o quê, e reescrever por
cima só a aplicação. Sem essa fundação de pé, nenhum módulo de negócio tem onde
nascer, porque todos leem a mesma âncora (`profiles.clinic_id`) e a mesma
cascata (`my_permission`).

## 2. Requisitos

**O banco**

- **FR-001**: As migrações da referência **MUST** ser aplicadas em ordem, sem
  reescrita. *Porquê:* é o único ativo do MVP com qualidade comprovada, e
  reescrever schema validado troca risco conhecido por risco novo.
  **São 56, contadas em 28/08** pelo nome com hash que o Lovable gera. O número
  55, repetido no `CLAUDE.md` e em vários documentos desde julho, nunca bateu com
  o diretório.
- **FR-002**: O trigger `on_auth_user_created_superadmin` **MUST NOT** ser
  portado, e a função `seed_superadmin_operator` **MUST** ficar. *Porquê:* o
  trigger tem e-mail fixo em código; a função é alvo de um `REVOKE` posterior, e
  dropar as duas quebraria a migração de endurecimento.
- **FR-003**: Nenhuma tabela com `clinic_id` **MUST** ficar sem RLS. Divergência
  para a execução. *Porquê:* Princípio I. Bug de aplicação não pode vazar dado de
  outra clínica, e a única forma de garantir isso é o banco recusar.

**O seed**

- **FR-004**: O seed **MUST** ser idempotente e rodar com service role fora do
  bundle do app. *Porquê:* ele será rodado mais de uma vez, por gente diferente,
  e a segunda execução não pode duplicar plano nem operador.
- **FR-005**: O seed **MUST NOT** receber senha por variável, argumento ou
  código. Cria o usuário com senha aleatória descartada. *Porquê:* regra (e) da
  constituição. A senha real nasce por recovery, no painel, e vive no
  gerenciador.
- **FR-006**: O plano "Trial Padrão" **MUST** nascer com as 15 ModuleKeys em
  `true`, limites `NULL` e visibilidade `hidden`. *Porquê:* é o teto padrão de
  quem entra sem plano escolhido, e limite `NULL` significa ilimitado.

**As edge functions**

- **FR-007**: `superadmin-manage-user` **MUST** expor apenas `update_email` e
  `send_password_reset`, as duas atrás de bearer mais `is_superadmin`. *Porquê:*
  a action `set_password` da referência viola a regra (e) e foi removida na
  portagem.
- **FR-008**: `update_email` **MUST** gravar diff `old→new` em
  `superadmin_audit_log`. *Porquê:* trocar e-mail troca a credencial de acesso de
  uma pessoa. Ação administrativa sobre dado de cliente sem rastro é regra (d)
  violada.
- **FR-009**: `invite-team-user` **MUST NOT** aceitar, transportar ou gerar senha
  de terceiro, e **MUST** exigir `my_permission('equipe') = 'full'` avaliada pelo
  banco. *Porquê:* foi por essa porta que a violação da regra (e) chegou à
  produção. Corpo com `password` é recusado com 400, para um front desatualizado
  falhar alto em vez de ser ignorado em silêncio.

**O app**

- **FR-010**: O front **MUST NOT** reimplementar a cascata de permissão. Consome
  `my_permission`, a mesma função que a RLS usa. *Porquê:* segunda implementação
  sempre diverge da primeira, e diverge para o lado de liberar demais.
- **FR-011**: Os guards **MUST** resolver em Server Component, antes de mandar
  HTML. *Porquê:* guard de cliente abre uma janela em que conteúdo protegido
  pisca na tela antes do redirect.
- **FR-012**: A decisão de acesso **MUST** viver em módulo puro e síncrono,
  separada do componente que redireciona. *Porquê:* guard `async` que chama
  `redirect()` é caro de testar, e o que não se testa não se prova.
- **FR-013**: O menu **MUST** ser montado a partir de `my_permission`, um módulo
  por vez, e item negado **MUST NOT** aparecer. *Porquê:* esconder é cortesia;
  quem bloqueia é a rota e a RLS. As duas coisas juntas são defesa em
  profundidade, e nenhuma delas substitui a outra.
- **FR-014**: Toda rota nova **MUST** entrar em `ROTAS_DO_APP`. *Porquê:* é essa
  lista que faz o teste de guard valer para ela. Rota fora da lista sai do
  alcance da prova sem ninguém notar.
- **FR-015**: O banner de impersonação **MUST** aparecer em todas as rotas, do
  app da clínica e do painel, e a saída **MUST** descartar o cache antes de
  navegar. *Porquê:* operador que volta ao painel com impersonação ativa precisa
  ver onde está, senão a próxima ação sai na conta errada. Invertida a ordem, a
  primeira tela após a saída ainda mostra dado da clínica de onde se saiu.
- **FR-016**: `OnboardingGuard` **MUST NOT** disparar sob impersonação. *Porquê:*
  o superadmin entra para dar suporte, não para completar o onboarding do
  cliente.
- **FR-017**: A mensagem de erro do login **MUST** ser única para e-mail
  inexistente e senha errada. *Porquê:* requisito `NGS1.02.16` da certificação
  SBIS. Mensagem distinta permite enumerar quem tem conta.

## 3. O que muda no banco

Nada é criado por esta regra. Ela **replica** o schema validado e dropa apenas um
trigger.

| Objeto | Ação |
|---|---|
| 56 migrações da referência | aplicadas em ordem, intactas |
| `on_auth_user_created_superadmin` | **dropado** por migração nova (`20260802090000`) |
| `seed_superadmin_operator` | mantida, preserva o `REVOKE` de `20260802073330` |
| `plans` (1 linha), `saas_settings` (singleton), `superadmin_operators` (1 linha) | criados pelo seed idempotente |

O inventário completo do schema replicado (44 tabelas, 3 enums, cerca de 40
funções, triggers e RLS por tabela), no estado em que ele foi portado, vive em
[`../referencia/schema-validado.md`](../referencia/schema-validado.md). As
assinaturas das RPCs, os contratos dos guards e os das edge functions vivem em
[`../referencia/contratos-da-fundacao.md`](../referencia/contratos-da-fundacao.md).

**A cascata de `my_permission`, que é o coração:** superadmin dá `full`;
assinatura `suspended` ou `cancelled` dá `none`; módulo ausente ou `false` em
`enabled_modules` do plano dá `none`; admin da clínica dá `full`; senão vale a
permissão individual do `team_member`; fallback **`none`**. O plano é o teto, a
permissão individual distribui abaixo dele, e nunca o excede.

## 4. Premissas

- **O banco da referência está sem drift.** 56 migrações fiéis, zero objeto
  órfão, verificado antes de começar. Hoje o diretório tem **72 arquivos**: as 56
  portadas mais 16 escritas neste repositório, e as duas famílias se distinguem
  pelo nome, porque as da referência carregam o hash gerado pelo Lovable e as
  nossas têm nome em português.
- **`ALTER TYPE ... ADD VALUE` não roda dentro de transação com uso imediato.**
  A migração `20260725001410` acrescenta `user` a `app_role` e foi isolada.
- **`clinic_within_user_limit` compara com `<` estrito.** O `<=` deixava entrar
  um acesso a mais que o plano permite. O bug era real e foi encontrado em teste.
- **`OnboardingGuard` é derivado, não persistido.** A referência não guarda
  onboarding concluído em coluna nenhuma: deriva de doze contagens, e o passo de
  equipe exige **duas** pessoas ativas.
- **`enabled_modules` é objeto, não array.** O default da coluna é `'[]'` e o
  trigger exige objeto. A correção pertence à regra 005, FR-001.
- **O e-mail atual de um perfil não é exibível pelo painel.** Ele vive em
  `auth.users`, fora do alcance de qualquer sessão autenticada. Quem o resolve é
  a edge function, com service role. Expor `auth.users` por RPC só para melhorar
  um rótulo seria troca ruim.
- **A entrega transacional de e-mail não está de pé.** O SMTP embutido não
  entrega, comprovado em teste. Até o Resend entrar (regra 003), o convite
  devolve o link na resposta e o admin repassa por fora.

## 5. Dependências

- **Nada precede esta regra.** Ela é a fundação.
- **Precisam dela:** todas as regras de módulo (005 em diante), porque todas leem
  a âncora e a cascata.
- **A regra 003** estende a Fase 4 desta: completa e blinda o painel superadmin
  na stack nova.
- **Ambiente:** projeto Supabase próprio, CLI linkada, e em `.env.local`
  `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`,
  `SUPABASE_SERVICE_ROLE_KEY` e `SUPERADMIN_EMAIL`. Nunca versionadas.

## 6. Como se prova que funciona

Executado por Arthur na tela. Item sem prova fecha como *"código lido, não
comportamento provado"* e continua aberto.

O ambiente sai de pé com quatro comandos, na ordem:

```bash
supabase db push && npx tsx scripts/seed.ts && supabase functions deploy && npm run dev
```

1. **Login superadmin.** `/superadmin/login` com `SUPERADMIN_EMAIL` abre o
   painel; usuário comum em `/superadmin/*` recebe 403 ou redirect.
2. **Impersonação completa.** Entrar numa conta, ver o banner âmbar com o nome
   certo, escrever um registro na clínica-alvo, trocar de clínica sem sair, sair,
   e conferir a âncora restaurada e os eventos `impersonation_start` e
   `impersonation_end` em `superadmin_audit_log`.
3. **O teto vence o individual.** Plano sem `contas_pagar` mais usuário com
   permissão individual `full` no mesmo módulo: o menu esconde e a URL direta
   bloqueia.
4. **Conta suspensa.** `status = suspended`: usuário comum vê a tela de bloqueio;
   superadmin impersonando tem acesso pleno.
5. **Limite de acessos.** Com `max_users = 1` e um acesso ativo, o segundo é
   barrado com mensagem clara, inclusive por reativação de um inativo.
6. **Auditoria de perfil.** Editar o perfil de um cliente audita `old→new`;
   auto-edição do superadmin não audita; `update_email` troca o login; `INSERT`
   direto em `profiles` por usuário comum é negado pela RLS.
7. **Idempotência.** `scripts/seed.ts` rodado duas vezes não duplica nada, e
   nenhuma senha aparece em log ou código.

**Prova automatizada, mínimo do Princípio V:** 80 testes em Vitest cobrem o que é
desta regra (19 do hook de permissão, 61 dos guards), dentro de uma suíte que em
27/08 tem 225 e roda verde. Mais 15 testes Playwright passando. **Cinco e2e
continuam pulados**, com motivo explícito, porque exigem login real: menu montado
por `my_permission`, usuário comum barrado no painel, e módulo negado bloqueando
por URL direta.

**Os testes são provados por mutação, não por passarem.** Removida a checagem de
erro do hook, dois testes falham; removida a verificação do contrato de módulo,
outros dois. Teste que não falha quando o código quebra não protege nada.

## 7. A decisão que falta

Nenhuma decisão de desenho. **Faltam três atos, e os três são do Arthur.** Cada
um tem issue própria, abertas em 27/08/2026:

1. **Definir a senha real do superadmin** ([#48](https://github.com/nexclin/nexclin-sdd/issues/48)), por recovery no painel do Supabase.
   `last_sign_in_at` nunca foi preenchido: o superadmin ainda não logou, e nada
   que dependa de sessão real pode ser provado enquanto isso.
2. **Provar o diff de `update_email`** em `superadmin_audit_log` ([#49](https://github.com/nexclin/nexclin-sdd/issues/49)). A chamada sem
   token já devolve 401 nas duas functions, confirmado ao vivo. Falta a metade
   que prova a auditoria.
3. **Destravar os cinco e2e pulados** ([#50](https://github.com/nexclin/nexclin-sdd/issues/50)): convidar um usuário de teste com permissão
   **parcial**, deixando ao menos um módulo negado, e preencher as quatro
   variáveis `E2E_*` (receita em `.env.example`). É o módulo negado que exercita
   o bloqueio; usuário com tudo liberado não prova nada.
