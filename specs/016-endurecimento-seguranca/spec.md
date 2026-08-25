# Feature Specification: Endurecimento de segurança pré-lançamento

**Feature Branch**: `016-endurecimento-seguranca`

**Created**: 2026-08-25

**Status**: Draft

**Input**: Lista de 20 itens de segurança pré-lançamento, trazida pelo Arthur em 25/08/2026. Cada um foi **auditado contra o código**, não estimado.

---

## O placar, e a leitura que ele exige

**8 aplicados · 6 parciais · 6 ausentes.**

Antes da tabela, a distinção que decide tudo nesta spec, e que a lista original
não tem como fazer: **existem dois sistemas.**

- A **plataforma Lovable**, que vai ao ar em 08/09 com clientes reais e dado de
  saúde real.
- A **stack Next.js** deste repositório, que assume em outubro.

Um item pode estar resolvido aqui e aberto lá, ou o contrário. Header de
segurança configurado neste repositório **não protege ninguém em 08/09**, porque
quem serve o cliente naquele dia é a Lovable. E CAPTCHA no formulário público de
anamnese protege **agora**, porque aquele endpoint está no ar e é público.

Por isso a spec separa por **onde o risco mora**, não por item.

---

## A auditoria, item a item

Cada verdito abaixo tem evidência. Onde diz "verificado", foi rodado comando.

| # | Item | Situação | Evidência |
|---|---|---|---|
| 1 | Esconder API Keys | ✅ | `.env.local` no `.gitignore`; `.env.example` sem valores. `NEXT_PUBLIC_SUPABASE_ANON_KEY` é pública **por desenho** e não é segredo: quem protege é a RLS. |
| 2 | Limpar secrets do git | ✅ | `git log --all -- .env.local` volta vazio: nunca foi commitado. Além disso o hook `guarda-constituicao` recusa a escrita de JWT literal, `sb_secret_`, chave do Resend e service role em arquivo. |
| 3 | Public Key DB | ✅ | `SERVICE_ROLE` aparece em 4 arquivos: `.env.example`, `scripts/seed.ts` e as 2 edge functions. **Nenhum em `app/` ou `lib/`.** O app usa só a anon. |
| 4 | Ativar RLS | ✅ | É o Princípio I da constituição. O hook bloqueia migração que crie tabela com `clinic_id` sem `ENABLE ROW LEVEL SECURITY`. |
| 5 | Criptografia de dados | ⚠️ | Em trânsito, TLS pela Supabase e pela Vercel. Em repouso, o disco da Supabase. **Nenhuma coluna cifrada na aplicação**: zero uso de `pgcrypto` ou `pgsodium`. Para dado de saúde, é decisão a tomar, não omissão a corrigir às cegas. |
| 6 | Auth Server side | ✅ | Fechado em 25/08 com o T020. Os guards são Server Components e usam `getUser()`, que valida o token no servidor, e não `getSession()`, que confia no cookie. |
| 7 | Restringir acessos | ✅ | Cascata de `my_permission` no banco, RLS por `clinic_id`, e fallback `none`. 80 testes de unidade e 15 de navegador. |
| 8 | Bloquear Mass Assignment | ❌ | **Gap sistêmico, com exemplo provado.** 42 policies `FOR ALL` usam a mesma condição para leitura e escrita. Só **uma** tabela tem `GRANT` por coluna. O caso concreto: `team_members` deixa qualquer membro alterar as próprias permissões e o próprio percentual de repasse (`docs/seguranca/autoconcessao-team-members-2026-08-25.md`). |
| 9 | Proteger cookies | ⚠️ | Usa o padrão do `@supabase/ssr`, que é `httpOnly` e `sameSite`. Não há configuração explícita nem verificação. Padrão bom não conferido é suposição. |
| 10 | Hash nas senhas | ✅ | Supabase Auth. E nenhum caminho do sistema define senha de terceiro: removido da edge function, bloqueado pelo hook, e coberto por um teste e2e que falha se o botão voltar. |
| 11 | Rate limit | ❌ | Nada na aplicação, nada nas edge functions. A Supabase Auth tem limites próprios, configuráveis no painel, que **não foram revisados**. |
| 12 | Bot protection | ❌ | Sem CAPTCHA em lugar nenhum. O mais exposto não é o login: é o **formulário público de anamnese**, que é sem autenticação por desenho. |
| 13 | Queries parametrizadas | ✅ | `supabase-js` e PostgREST parametrizam. O único `EXECUTE format` das migrações usa `%I` para identificador num REVOKE, sem dado de usuário. |
| 14 | Validação dos Inputs | ⚠️ | A edge function valida e-mail por regex. **Não há validação de esquema em nenhuma fronteira do app**: zero `zod` ou equivalente. |
| 15 | Vazar conteúdo | ⚠️ | O login já não permite enumerar usuário (corrigido em 25/08, requisito `NGS1.02.16` da SBIS). Mas as edge functions devolvem `e.message` cru no `catch`, o que pode entregar detalhe interno. |
| 16 | Restringir uploads | ❌ | **Dívida já registrada.** As policies de `storage.objects` aplicadas na Lovable não filtram por `bucket_id`, não há limite de tamanho nem de tipo de arquivo, e nada disso está portado para cá. |
| 17 | Trim respostas de API | ⚠️ | Bom começo: **nenhum `select("*")` no app**, tudo com colunas nomeadas. Mas só `team_members` tem `GRANT SELECT` por coluna; nas demais, a coluna que a RLS libera vai inteira. |
| 18 | Add security headers | ❌ | `next.config.mjs` tem exatamente uma linha de configuração, `reactStrictMode`. Sem CSP, HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`. |
| 19 | Forçar HTTPS | ⚠️ | A Vercel redireciona para HTTPS. Sem HSTS, o **primeiro** acesso de cada navegador ainda passa por HTTP e é atacável. |
| 20 | Scan de dependências | ❌ | Não existe `.github/workflows`, não há Dependabot, e `npm audit` não é gate de nada. |

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - O que protege o cliente em 08/09 (Priority: P1)

Antes do lançamento, os riscos que estão **no ar agora, na Lovable**, ficam
cobertos: o formulário público de anamnese deixa de ser um alvo aberto, os
limites de autenticação passam a ser conhecidos em vez de presumidos, e o
armazenamento de arquivo para de aceitar qualquer coisa.

**Why this priority**: é o único bloco desta spec que muda alguma coisa para o
cliente fundador. Todo o resto protege um sistema que ainda não atende ninguém.

**Independent Test**: disparar 50 envios seguidos ao endpoint público de
anamnese e confirmar que os últimos são recusados, não gravados.

**Acceptance Scenarios**:

1. **Given** o formulário público de anamnese no ar, **When** um script tentar
   enviar em volume, **Then** o CAPTCHA e o limite recusam antes de gravar.
2. **Given** a tela de login, **When** houver tentativas repetidas de senha,
   **Then** o limite da Supabase Auth barra, e o valor desse limite está
   documentado.
3. **Given** um upload de arquivo, **When** o tipo ou o tamanho estiver fora do
   permitido, **Then** o banco recusa, e não só a tela.

---

### User Story 2 - Fechar o mass assignment (Priority: P1)

Nenhum usuário consegue alterar, sobre si mesmo, campo que decide o próprio
poder ou o próprio dinheiro: permissão, nível de permissão e percentual de
repasse.

**Why this priority**: é o único ❌ da lista com **exploração já provada** neste
sistema. Não é risco teórico.

**Independent Test**: autenticado como membro comum, tentar
`update team_members set permission_level='master' where id = <o meu>`; o banco
recusa.

**Acceptance Scenarios**:

1. **Given** um membro com permissão `operacional`, **When** tentar elevar o
   próprio `permission_level`, **Then** o banco recusa.
2. **Given** o mesmo membro, **When** tentar mudar o próprio `repasse_percent`,
   **Then** o banco recusa.
3. **Given** um admin da clínica, **When** alterar a permissão **de outra
   pessoa**, **Then** funciona e fica auditado.
4. **Given** as 42 policies `FOR ALL` do banco, **When** a varredura rodar,
   **Then** existe uma decisão registrada para cada uma: separar por operação,
   ou justificar por que `FOR ALL` é adequado ali.

---

### User Story 3 - O perímetro da stack nova (Priority: P2)

Antes de a stack Next.js assumir em outubro, ela sobe com cabeçalhos de
segurança, HTTPS forçado por HSTS, validação de esquema nas fronteiras e
varredura de dependência automática.

**Why this priority**: é obrigatório antes de outubro e **não muda nada em
08/09**. Tratar como urgente agora seria proteger o sistema errado.

**Independent Test**: rodar a URL de produção em um verificador de cabeçalhos e
obter nota A, com CSP sem `unsafe-eval`.

**Acceptance Scenarios**:

1. **Given** a aplicação em produção, **When** um navegador pedir qualquer
   página, **Then** vêm CSP, HSTS, `X-Content-Type-Options: nosniff`,
   `Referrer-Policy` e `Permissions-Policy`.
2. **Given** um `pull request`, **When** houver dependência com
   vulnerabilidade conhecida, **Then** o CI falha antes do merge.
3. **Given** qualquer fronteira que receba dado de fora, **When** o corpo não
   casar com o esquema, **Then** é recusado antes de tocar o banco.

---

### Edge Cases

- **CSP e o Next.js.** `unsafe-eval` é necessário em desenvolvimento para o hot
  reload e **nunca** pode ir para produção. CSP com nonce exige gerar o nonce no
  middleware, o que muda a estratégia de cache.
- **CAPTCHA e a experiência da recepção.** A secretária faz dezenas de ações por
  dia. CAPTCHA no login é aceitável; CAPTCHA em operação corriqueira faz a
  equipe abandonar o sistema, que é o risco descrito na pesquisa de mercado.
- **Rate limit e a clínica com IP único.** Toda a recepção sai pelo mesmo IP.
  Limite por IP mal calibrado bloqueia a clínica inteira.
- **HSTS com `preload` é quase irreversível.** Entrar na lista é fácil, sair
  leva meses. Começar com `max-age` curto e só depois subir.
- **Cifra em coluna quebra busca.** Cifrar CPF ou telefone impede busca por
  esses campos, que é operação diária da recepção.

---

## Requirements *(mandatory)*

### Bloco A — o que entra antes de 08/09, na plataforma Lovable

- **FR-001**: O formulário público de anamnese MUST exigir CAPTCHA. A Supabase
  suporta hCaptcha e Cloudflare Turnstile de forma nativa, ligados em
  Authentication → Bot and Abuse Protection.
- **FR-002**: Os limites de autenticação da Supabase MUST ser revisados e
  **registrados** em `docs/seguranca/`. Limite que ninguém sabe qual é não pode
  ser contado como proteção.
- **FR-003**: O bucket de armazenamento MUST ter limite de tamanho e lista de
  tipos permitidos, aplicados no banco.
- **FR-004**: As policies de `storage.objects` MUST filtrar por `bucket_id`.
  Hoje não filtram, e no dia em que existir um segundo bucket, ou o upload da
  clínica falha, ou o isolamento cai.

### Bloco B — mass assignment, faixa A, **fora da semana do lançamento**

- **FR-005**: `team_members` MUST impedir que um usuário altere o próprio
  `permission_level`, `permissions` e as colunas de repasse. Por trigger, e não
  só por policy: a regra é "não pode mudar **estas colunas** em si mesmo", e
  policy expressa isso mal.
- **FR-006**: As 42 policies `FOR ALL` MUST ser varridas, e cada uma MUST ter
  decisão registrada: separar por operação ou justificar.
- **FR-007**: Tabela com coluna que decide poder ou dinheiro MUST usar `GRANT`
  por coluna, como já se faz em `team_members` para leitura.

### Bloco C — o perímetro da stack nova, antes de outubro

- **FR-008**: `next.config.mjs` MUST servir CSP, HSTS, `X-Content-Type-Options:
  nosniff`, `Referrer-Policy: strict-origin-when-cross-origin` e
  `Permissions-Policy` restringindo câmera, microfone e geolocalização.
- **FR-009**: HSTS MUST começar com `max-age` curto e subir para
  `max-age=63072000; includeSubDomains` depois de confirmado. `preload` só
  quando houver certeza, porque a saída da lista leva meses.
- **FR-010**: A CSP MUST NOT conter `unsafe-eval` em produção.
- **FR-011**: Toda fronteira que aceita dado de fora MUST validar por esquema
  antes de tocar o banco.
- **FR-012**: As edge functions MUST NOT devolver `e.message` cru ao cliente.
  Mensagem genérica para fora, detalhe no log.
- **FR-013**: O repositório MUST ter varredura de dependência automática, e ela
  MUST ser gate de merge.
- **FR-014**: A configuração de cookie de sessão MUST ser explicitada e
  verificada, em vez de herdada em silêncio.

### Bloco D — a decisão que não é implementação

- **FR-015**: O projeto MUST decidir, por escrito, se alguma coluna de dado de
  saúde precisa de cifra na aplicação, além da cifra em repouso da Supabase. A
  decisão MUST registrar o custo: coluna cifrada não é buscável, e busca por
  telefone é operação diária da recepção.

---

## Success Criteria *(mandatory)*

- **SC-001**: 50 envios automatizados seguidos ao formulário público de anamnese
  não gravam mais que o limite definido.
- **SC-002**: Nenhum usuário consegue elevar a própria permissão ou o próprio
  repasse, verificado por tentativa real no banco.
- **SC-003**: A URL de produção obtém nota A em verificador de cabeçalhos.
- **SC-004**: Um `pull request` com dependência vulnerável conhecida é barrado
  antes do merge.
- **SC-005**: Os limites de autenticação estão escritos em `docs/seguranca/`,
  com o valor de cada um.
- **SC-006**: Os 20 itens da auditoria têm situação atualizada, e nenhum
  permanece em ⚠️ sem decisão registrada.

---

## Assumptions

- **A lista de 20 itens é boa, e é genérica.** Ela não conhece a distinção entre
  as duas plataformas, nem que a `NEXT_PUBLIC_SUPABASE_ANON_KEY` é pública por
  desenho. Aplicá-la ao pé da letra levaria a esconder uma chave que precisa ser
  pública e a configurar cabeçalho no sistema que ainda não atende ninguém.
- **Nada aqui entra na semana do lançamento além do Bloco A.** A regra de 25/08
  vale: não se troca regra de permissão na véspera.
- **CAPTCHA e rate limit da Supabase são configuração de painel**, não código.
  São ações do Arthur, e por isso o Bloco A é majoritariamente dele.
- **A cifra em coluna fica como decisão, não como tarefa.** Implementar antes de
  decidir o custo operacional é como se perde busca por telefone sem perceber.

---

## Relação com a régua NGS1 da certificação

Sete destes vinte itens são também requisitos da certificação SBIS, mapeados na
análise do OpenClinic (`docs/planejamento/openclinic-analise-2026-08-25.md`
§3.1): `NGS1.02.13` (tentativas de login), `NGS1.02.20` (bloqueio por
inatividade), `NGS1.03.11` (autoconcessão), `NGS1.05.01` (comunicação cifrada),
`NGS1.06.03` (validação de entrada), `NGS1.06.01` (anexo fora do banco com nome
opaco) e `NGS1.04.03` (backup cifrado).

**Consequência prática:** esta spec e a tarefa OC-2 são o mesmo trabalho visto
de dois ângulos. Fazer as duas separado é fazer duas vezes.

---

## Fontes da pesquisa

- CAPTCHA nativo da Supabase, com hCaptcha e Cloudflare Turnstile, em
  Authentication → Bot and Abuse Protection.
- Limites de autenticação da Supabase, customizáveis em Authentication → Rate
  Limits.
- Cabeçalhos no Next.js: estáticos em `next.config` para o caso geral, e nonce
  no middleware só quando a CSP exigir. HSTS recomendado em
  `max-age=63072000; includeSubDomains; preload`, com a ressalva de que
  `preload` é quase irreversível.
- `unsafe-eval` é necessário em desenvolvimento e não pode ir para produção.
