# Registro do dia 26/08/2026

> Escrito para servir de base a relatório. Cada linha diz **o que mudou** e
> **por que**, com o commit ao lado, para que ninguém precise ler diff.
>
> Dois repositórios distintos, e a distinção importa:
> `nexclin/nexclin` é a plataforma Lovable, que vai ao ar em 08/09.
> `nexclin/nexclin-sdd` é este, fonte de verdade de spec, migração e decisão.

---

## O que mudou de rumo

**A prioridade inverteu.** Até 25/08 a orientação era corrigir na Lovable só o
que atravessa e construir o novo na stack nova. Em 26/08 o Arthur inverteu: toda
especificação já definida é implementada **na Lovable**, e a stack nova espera. A
razão é o lançamento em 08/09, e o custo (retrabalho na reescrita de outubro)
está anotado em `2026-08-26-inversao-de-prioridade.md`.

**A migração para a stack nova passou a ser setembro e outubro**, com a
formalização em outubro.

---

## Entregue na plataforma Lovable

Onze commits, todos publicados.

| Commit | O que entrega | Por que importa |
|---|---|---|
| `c69bfe8` | **Régua de cobrança** | O sistema já sabia quem estava em atraso e não fazia nada. Cinco faixas, a primeira antes do vencimento |
| `a95fae7` | **Custo da hora clínica e preço mínimo** | O produto deixa de registrar o que a clínica cobrou e passa a dizer se ela devia estar cobrando aquilo |
| `55cf84a` | **Meta do mês por dia útil** | Meta de fim de mês não muda o que alguém faz hoje. Feriados nacionais calculados |
| `a7543d1` | **Ocupação e taxa de falta** | A agenda passa a medir o que a precificação perguntava. A falta é 20% a 30% e não aparecia em lugar nenhum |
| `e7b51ae` | **Recall** | `recall_days` existia na tela e nada no código consumia. Mais o "usado em" nas onze seções de Configurações |
| `7e54069` | **Informativos** | O termo de consentimento sai do arquivo do Word e passa a ter uma fonte só |
| `75158b2` | **Cadastro de imobilizado e salvamento dos parâmetros** | Eu tinha construído o consumidor sem o produtor |
| `5f638fd` | **Insumos, fornecedores e composição de custo** | `services.cost` era um número digitado à mão que ninguém sabia de onde veio |
| `55c0852` | **Três correções da verificação** | Fuso, telefone curto e NaN silencioso. Detalhe abaixo |
| `1e41a31` | **Salas, equipamentos e duração da consulta** | Conflito de sala só era descoberto quando os dois pacientes chegavam |
| `e11ab83` | **Restauração da edge function de MCP** | Erro meu, detalhe abaixo |

---

## Entregue neste repositório

Trinta e três commits, mesclados pelo PR
[#34](https://github.com/nexclin/nexclin-sdd/pull/34), mais os posteriores.

### SPEC 005, Configurações da clínica: fechada em código

| Tarefa | O quê |
|---|---|
| T009 | A escrita dos catálogos: `entrada.ts` pura, `acoes.ts` que grava, um formulário para os dez |
| T011 | Regras de negócio, com cada campo dizendo o que muda quando se mexe nele |
| T012 | Plano de contas em árvore, com corte de ciclo e ordenação que entende número |
| T013 | Contas bancárias, a décima entrada do registro declarativo |
| T014 | Metas com dias úteis e feriados calculados |
| T015 | Modelos de anamnese, lendo as duas formas que a coluna guarda |

225 testes, `tsc` limpo. T017 adiado, não pulado: o `quickstart.md` que ele cita
nunca existiu, e o aceite exige o app Next.js rodando.

### SPEC 003, Superadmin: o painel passou a escrever

Medição de 26/08: **as onze telas existiam e a única escrita em todo o
`app/superadmin/` era a impersonação.** Ganhou criar conta, mudar plano, situação
e data de cobrança, e editor de planos.

### SPEC 006, Modelagem INI: escrita hoje, depois do código

Registra os dez requisitos implantados na Lovable e as cinco decisões de
arquitetura. Escrita sem aceites, a pedido.

---

## Achados de segurança

| Achado | Estado |
|---|---|
| **Autoconcessão em `team_members`** | Qualquer membro podia alterar as próprias permissões e o próprio percentual de repasse. Corrigido por trigger |
| **Duas correções para o mesmo furo** | O bot da Lovable também corrigiu, e a correção dele tem duas brechas que a nossa fecha: repasse continua livre, e quem é `gerencial` se promove sozinho |
| **A linha do tempo da conta não era alimentada** | Uma tela desenhando dado que ninguém escrevia. Corrigido por trigger |
| **Impersonação sem prazo** | A impersonação troca a **âncora**, e operador que fechava o navegador sem sair ficava com o perfil apontando para a clínica do cliente indefinidamente |
| **Senha da conta-mestra exposta em chat** | Segunda vez nesta conta. Precisa de troca por recovery |
| **Endpoint MCP publicado por fora da ponte** | Expõe pacientes e resumo financeiro por OAuth. O desenho respeita a RLS, mas é superfície externa nova sem revisão. É pauta de sócios |

---

## A verificação completa, e os três defeitos que ela achou

43 provas nos módulos puros, `tsc` limpo, `vite build` verde, mais revisão
estática. Três defeitos, todos reais:

**1. O fuso acertava todas as telas.** Medido: às 21h30 do dia 31/08 em Brasília,
`new Date()` já é 01/09 em UTC. Das 21h à meia-noite, todo dia, a tela de metas
mostraria o mês errado e a régua contaria um dia a mais de atraso em tudo.
Corrigido com `hoje.ts`.

**2. Telefone curto virava link quebrado.** Cobrança e Recall duplicavam a regra
do WhatsApp num regex inline, e a cópia não recusava número curto. Quatro dígitos
viravam um botão que não abre conversa nenhuma.

**3. `Number(x) ?? padrão` não protege de NaN.** A tela mostraria "R$ NaN" sem
erro nenhum. E `||` também não serve, porque imposto zero é legítimo.

---

## Dois erros meus, registrados porque ensinam

**A edge function de MCP entrou num commit esvaziada.** O pacote
`@lovable.dev/mcp-js` tem um gerador que reescreve
`supabase/functions/mcp/index.ts`, e ele roda no `npm install` **e** no `vite
build`. Reduziu o arquivo de 239 linhas para 2.

Eu achei e documentei isso de manhã, na verificação. À tarde vi no `git status`,
usei `git add -A` assim mesmo, e o arquivo entrou. Corrigido em `e11ab83`, e
conferido contra o remoto: 239 linhas nos dois.

**Ver o problema e evitar o problema são coisas diferentes.** A regra que fica é
mecânica: neste repositório, nunca `git add -A` depois de um build.

**Três vezes usei `python -c` com aspas duplas** contendo crases de markdown, e o
bash executou as crases como comando. Isso comeu trechos de documento em duas
ocasiões, corrigidas em `66fb43b` e `cd9f23f`. Quando o texto tem crase, o
caminho é arquivo, não `-c`.

---

## O que fica pendente, e de quem depende

| Pendência | Depende de |
|---|---|
| ~~Seis migrações não aplicadas~~ | **Aplicadas em 27/08.** Detalhe abaixo |
| Apontamentos do Erick | Arthur, transcrever o vídeo |
| Reteste do Vinícius | Vinícius. Os 23 itens estão corrigidos e publicados desde 25/08 |
| SMTP (Resend) | Arthur. Sem ele não sai reset de senha nem convite |
| Login do superadmin da stack nova | SMTP. `last_sign_in_at` nunca foi preenchido |
| Aceites das SPECs 001, 003 e 005 | Login do superadmin |
| Emenda D-005.5, `consultas` sai do contrato | Aprovada, aplicação na fase de migração |
| Centros de custo | Único item "importa" da modelagem ainda não implantado |

**O gargalo real são as seis migrações.** Sem elas, metade do que está publicado
é uma tela que avisa o que falta em vez de fazer o que promete.

---

## Adendo de 27/08: as seis migrações entraram

Aplicadas por colagem no editor de SQL da plataforma. A conferência final
devolveu **`true` nas onze linhas**.

**Duas coisas aprendidas na aplicação, e as duas são sobre o documento e não
sobre o banco.**

A primeira tentativa devolveu `false` nas onze, e não porque alguma migração
falhou: o que foi colado foram as **consultas de conferência** do roteiro. O
engano é razoável e a culpa é do documento: as conferências eram o único
conteúdo em bloco de código, e as migrações apareciam só como caminho de
arquivo. Quem copia do que está à vista copia a conferência.

Corrigido com `docs/ponte/blocos-26-08/TUDO-EM-UM.sql`, um arquivo gerado com as
seis concatenadas na ordem, para uma colagem só. A fonte de verdade continua
sendo `supabase/migrations/`.

**A segunda é o resultado que interessa.**
`SELECT public.encerra_impersonacoes_vencidas();` devolveu **0**. Não havia
nenhuma sessão de suporte aberta com a âncora trocada, ou seja, o furo existia e
nunca foi acionado. A partir de agora ele tem prazo.

E o reparo da linha do tempo tinha **27 ações auditadas** sem linha
correspondente, que é o tamanho do histórico que a tela de detalhe da conta
mostrava vazio.

### O que passou a funcionar

| Tela | Antes | Depois |
|---|---|---|
| Precificação | depreciação zero, parâmetros se perdiam | conta completa, parâmetros gravados |
| Precificação, ocupação | estimada pela duração média | **medida** por consulta |
| Informativos, Insumos, Salas | alerta de tabela faltando | funcionam |
| Detalhe da conta | linha do tempo vazia | alimentada por trigger |
