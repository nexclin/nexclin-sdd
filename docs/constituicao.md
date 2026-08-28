<!--
SYNC IMPACT REPORT
==================
Version change: 2.0.0 → 2.0.1
Data: 2026-08-27

PATCH: emenda de endereço, não de princípio. Os nove princípios ficam intactos,
palavra por palavra. Mudou onde as coisas moram, porque o Spec Kit saiu do
projeto e as specs viraram regras vivas em `docs/regras/`.

Linhas alteradas:
  - IV. SDD com Parada Humana: `specs/` vira `docs/regras/`, e o artefato ganha
        o nome que já tinha na prática, regra viva.
  - Fluxo de Desenvolvimento: a ordem canônica deixa de citar comandos
        `/speckit-*`, que não existem mais aqui, e passa a citar a cadeia real
        (`grill-with-docs`, `nx-regra`, `to-tickets`, `implement`).
  - Fluxo de Desenvolvimento: "spec ou task" vira "regra ou issue".

Este arquivo mudou de lugar no mesmo trabalho: era `.specify/memory/
constituicao.md`, agora é `docs/constituicao.md`. Lei que aponta para pasta
inexistente corrói as outras linhas.

Princípios modificados: nenhum
Princípios adicionados: nenhum
Templates a revisar: nenhum, os do Spec Kit foram apagados junto com `.specify/`
TODOs adiados: nenhum

--- histórico ---

SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 2.0.0
Data: 2026-08-23

Por que MAJOR e não MINOR. A regra de versionamento deste próprio arquivo diz
que MAJOR é "remoção/redefinição incompatível de princípio ou governança". O
Princípio IV determinava que `../nexclin-lovable` é **somente leitura**. Desde
17/08/2026 isso deixou de valer: a ponte inversa tornou aquele diretório o
canal pelo qual a correção chega ao cliente, e o `CLAUDE.md` §4(i) já registrava
a mudança enquanto a constituição não. Uma restrição no formato "nunca faça X"
virou "faça X sob procedimento" — isso é redefinição incompatível, ainda que
apenas alinhe o texto à prática. Somam-se três princípios novos, o que
isoladamente seria MINOR; prevalece o grau mais alto.

Princípios modificados:
  - II.  Privacidade e Auditoria — ampliado: dumps, buckets, minimização,
         retenção e o que fazer quando um segredo vaza.
  - IV.  SDD com Parada Humana — a cláusula de somente leitura é substituída
         pelo procedimento da ponte inversa.
  - VI.  Valor Operacional — ganha "pergunte por onde o cliente opera" e o
         mapa de verticais.
Princípios adicionados:
  - VII.  O Dado Atravessa; a Tela Não
  - VIII. Uma Regra, Uma Fonte
  - IX.   Verificação Vale Mais que Build Verde
Seções modificadas:
  - Restrições Técnicas & Stack — hosting deixa de ser dado constitucional e
    passa a decisão de arquitetura datada e revisável.
  - Fluxo de Desenvolvimento — inclui a ponte e o gate de tipos.
Templates a revisar: plan-template.md, spec-template.md, tasks-template.md
TODOs adiados: nenhum
-->

# NexClin Constitution

> Plataforma operacional inteligente para clínicas médicas e odontológicas.
> Esta constituição é a lei do repositório: supera qualquer preferência de
> implementação. Em conflito, a constituição prevalece.

## Contexto que dá sentido às regras

Sem isto, os princípios viram burocracia. **O NexClin guarda dado de saúde de
pacientes reais.** Nome, telefone, anamnese, diagnóstico, valor pago. Um erro de
isolamento não gera bug: gera vazamento de dado sensível de terceiros que nunca
escolheram estar aqui — os pacientes das clínicas, que não são nossos clientes e
não assinaram nada conosco.

**Quem opera o sistema:** médico, secretária, gestor de clínica. Não são
desenvolvedores. Não vão inspecionar o console para descobrir por que o número
está errado — vão **decidir em cima dele**.

**Duas plataformas convivem até outubro/2026:** a Lovable, temporária, no ar
desde 01/09 com clientes fundadores gratuitos; e a stack Next.js deste
repositório, que a substitui. Confundir as duas é o erro mais caro possível.

## Core Principles

### I. Segurança Mora no Banco

A segurança é propriedade do banco de dados, não da aplicação.

- Toda tabela com `clinic_id` **MUST** ter RLS habilitado — sem exceção.
- O modelo é **default deny**: o que não é explicitamente concedido é negado.
  O fallback de qualquer resolução de acesso é `none`.
- Nenhuma regra de acesso pode existir apenas no frontend. A tela **MUST**
  apenas refletir o que o banco já garante.
- A âncora multi-tenant (`profiles.clinic_id`) **MUST** ser imutável para o
  usuário comum — só superadmin ou service role a altera, protegida por trigger.
- Policy de UPDATE **MUST** declarar `WITH CHECK` explícito. Sem ele o Postgres
  reaproveita o `USING`, e a âncora fica apoiada só no trigger — uma camada em
  vez de duas.

**Rationale:** isolamento multi-tenant não pode depender da corretude da camada
de aplicação, que é a de menor confiança e a mais reescrita. Com RLS no
Postgres, uma falha de UI degrada função, não confidencialidade.

### II. Privacidade e Auditoria (LGPD por Arquitetura)

LGPD é requisito de arquitetura, não feature opcional — e não é sobre o texto da
lei, é sobre pessoas que confiaram um dado de saúde a uma clínica.

- Toda ação administrativa sobre dado de cliente **MUST** gerar auditoria:
  quem, o quê, quando, e o diff `old→new` quando houver alteração.
- Senha de cliente **MUST NEVER** ser definida por admin ou operador. A única
  via é o reset por e-mail. Nenhuma action, função ou edge function seta senha.
- Dado pessoal **MUST NOT** trafegar em query string, log, mensagem de erro ou
  título de commit.
- **Minimização:** um endpoint devolve o mínimo necessário. Endpoint público de
  anamnese devolve o formulário, **nunca** as respostas já preenchidas.
- **Credencial de link:** identificador que serve de credencial (token de
  formulário público) **MUST** ser um campo dedicado, rotacionável e expirável
  — nunca a chave primária, que não rotaciona nem expira.
- **Dump e export são dado de saúde.** Export de banco **MUST NOT** ser
  versionado, anexado a issue/PR, colado em chat ou deixado em bucket sem
  policy. Onde vive um dump, a autorização é verificada explicitamente —
  "bucket privado" não é camada de autorização.
- **Storage tem RLS como qualquer tabela.** Policies em `storage.objects`
  **MUST** filtrar por bucket e por clínica. Policy que autoriza por papel sem
  olhar o bucket é armadilha: funciona enquanto só existe um bucket e quebra
  silenciosamente quando nasce o segundo.
- **Segredo versionado é vazamento permanente.** `rm` não apaga histórico. Se
  uma credencial entrou no git, a resposta **MUST** ser rotacionar a chave na
  origem — não remover o arquivo.
- **Retenção e expurgo** precisam de política escrita antes de o volume de dado
  real tornar a decisão cara.

**Rationale:** confiança do mercado de saúde se sustenta em rastreabilidade e no
princípio de que ninguém — nem o suporte — assume a identidade de um cliente.

### III. Contrato Único de Módulos

As 15 ModuleKeys oficiais são o contrato único do sistema.

- `dashboard, leads, pacientes, anamnese, consultas, acompanhamento, tarefas,
  contas_receber, contas_pagar, fluxo_caixa, relatorios_vendas,
  relatorios_demais, configuracoes, equipe, insights`.
- Planos, permissões individuais e telas **MUST** usar exatamente as mesmas
  strings. Nenhum módulo novo entra sem ser adicionado a esse contrato.
- Regra de acesso: **o plano é o teto; a permissão individual distribui abaixo
  do teto e nunca o excede.**

**Rationale:** um único vocabulário elimina divergência entre cobrança,
autorização e navegação — a fonte mais comum de brechas de acesso.

### IV. Spec-Driven Development com Parada Humana

Nenhuma feature nasce de código; nasce de spec aprovada.

- Nenhuma feature **MUST** ser implementada sem **regra viva** aprovada em
  `docs/regras/`. Regra viva é o documento que nasce antes da execução, guia a
  execução, e **MUST** ser corrigido no mesmo commit em que a execução o
  contradiz. Onde este texto diz *spec*, leia *regra viva*: o artefato é o
  mesmo, o endereço mudou em 27/08/2026.
- O executor gera plano por fases e **MUST** PARAR para aprovação humana antes
  de iniciar cada fase.
- **"Implementado ≠ funciona":** toda fase **MUST** fechar com critérios de
  aceite executados por um humano. Quando o executor não conseguir provar o
  comportamento na tela, **MUST** registrar literalmente *"código lido, não
  comportamento provado"* e deixar o item aberto. Relatar como concluído o que
  não foi verificado é a única falha desta constituição que não tem conserto
  técnico.
- **A plataforma ao vivo é editável, sob procedimento.** O clone em
  `../nexclin-lovable` deixou de ser somente leitura em 17/08/2026: é por ele
  que a correção chega ao cliente. O que continua proibido é editá-lo fora do
  procedimento — só bug, conserto mínimo, `git pull` antes, `main` sempre, nunca
  `--force`, e **function antes do Publish do front**. Fonte:
  `docs/ponte/ponte-inversa.md`.

**Rationale:** o MVP anterior provou que velocidade sem especificação e sem gate
humano gera retrabalho caro. A parada por fase mantém o humano no controle das
decisões irreversíveis.

### V. Segredos Fora do Código e Qualidade Verificável

- Nenhuma credencial **MUST** aparecer em código, spec ou arquivo versionado.
  Segredos vivem em variáveis de ambiente, fora do git.
- TypeScript **MUST** ser estrito.
- Guards de rota e lógica de permissão **MUST** ter testes automatizados — são o
  perímetro de segurança da camada de aplicação.

### VI. Valor Operacional Antes de Feature, e o Cliente Decide Onde Isso Está

O NexClin é uma plataforma operacional inteligente, não um sistema de cadastros.

- Toda funcionalidade **MUST** aumentar receita, reduzir custo, economizar tempo
  ou melhorar a decisão da clínica.
- O diferencial é embarcar metodologia real de gestão clínica como inteligência
  do produto, não competir feature a feature com sistemas genéricos.
- **Antes de priorizar, pergunte por onde o cliente realmente opera.** Em
  20/08/2026 descobrimos que o time do fundador **não usa o dashboard** — puxa
  as bases pelos relatórios, toda semana, e decide em cima. A intuição de quem
  constrói (o dashboard é a cara do produto) não bateu com a de quem usa. Essa
  pergunta **MUST** preceder qualquer classificação de prioridade.
- **Verticais:** médico é o vertical ativo. Psicologia e estética estão na fila.
  Odontologia está fechada como escopo. Feature que só serve a um vertical
  inativo não entra sem decisão explícita.

### VII. O Dado Atravessa; a Tela Não

Princípio de triagem, e o que torna a janela até outubro/2026 administrável.

A plataforma Lovable é temporária; a stack Next.js a substitui. Mas **o banco
migra intacto** — e com ele tudo que as clínicas registrarem. Estimativa do
Arthur: R$ 100–200 mil de faturamento lançado por clínica no período.
**Lançamento errado em agosto não é descartado em outubro: é importado.**

Diante de qualquer apontamento, pergunte *o que fica gravado?*

| Faixa | Pergunta | Ação |
|---|---|---|
| **A** | Muda o que é **persistido** — valor, data, atribuição, a qual conta pertence? | **Corrigir.** O erro migra. |
| **B** | Muda só **como a tela soma ou exibe** dado já gravado certo? | **Escrever a regra**, datada. Implementar é opcional. |
| **C** | Front, layout, mensagem? | Não corrigir, salvo se impedir o cliente de operar. |

- **Financeiro não tem faixa B.** Gestão financeira é o diferencial pelo qual o
  produto foi vendido; número errado ali destrói o argumento de venda.
- **Relatório é exceção nomeada da faixa C** — ver Princípio VI.
- **Backlog não é trabalho adiado; é requisito da stack nova.** Item de backlog
  **MUST** entrar na spec do módulo correspondente, não dormir numa lista.

### VIII. Uma Regra, Uma Fonte

Toda regra de negócio **MUST** ter exatamente uma implementação, e o resto
chama essa implementação.

- Regra duplicada à mão é a falha mais recorrente deste projeto, e sempre a cópia
  é a errada. Casos reais: o vencimento do recebível tinha um helper canônico e
  uma segunda cópia escrita à mão dentro do handler (V-22); o valor orçado tinha
  a regra certa no hook do dashboard e uma segunda, errada, no relatório (V-29).
- Regra que decide **o que fica gravado** pertence ao **banco** — trigger ou
  constraint — não ao front. Seis caminhos de inserção no front garantem que o
  sétimo nasça sem a regra. E só a migração atravessa para a stack nova.
- **Um conceito, uma tabela, com chave estrangeira.** Duas tabelas para o mesmo
  conceito, sem FK, produzem falha silenciosa: em `appointments`, a coluna
  `consultation_type_id` não tem FK e a tela grava ali um `services.id`,
  enquanto o cálculo procurava em `consultation_types` — o valor da consulta era
  **sempre zero**, e nada acusava (V-18).
- Coluna que existe e ninguém escreve é dívida ativa, não inofensiva: o DRE lia
  `revenues`, tabela que nenhum caminho do app alimenta, e vinha zerado desde
  sempre (V-27).

### IX. Verificação Vale Mais que Build Verde

- **Build verde não prova tipo.** O Vite usa esbuild, que remove tipos sem
  checá-los. Em 20/08/2026 isso derrubou o app por 1h35. O gate **MUST** ser
  `tsc --noEmit` no config que de fato inclui os arquivos — no projeto da
  plataforma, `tsconfig.app.json`; `tsconfig.json` usa `references` com
  `"files": []` e responde verde checando zero arquivos.
- **Aritmética de dinheiro MUST ser simulada antes de enviar**, com os números
  do caso real relatado, incluindo o caso de borda. "Parece certo" não é
  verificação.
- **Mudança visual MUST ser vista.** Captura de tela do componente, antes e
  depois — não descrição do CSS.
- **Publicar não é publicar até ser conferido.** Painel que diz "sucesso" já
  mentiu duas vezes no mesmo dia.

## Restrições Técnicas & Stack

- **Stack-alvo:** Next.js (App Router) + TypeScript + Supabase próprio
  (Postgres + Auth + RLS + Edge Functions).
- **Hospedagem é decisão de arquitetura datada, não cláusula constitucional.**
  A escolha vigente **MUST** viver num documento datado em `docs/`, com o
  critério que a sustenta (custo previsível, latência de banco, independência de
  fornecedor) e a data da última revisão. Trocar de provedor é uma decisão de
  engenharia; trocar sem registrar o porquê é como se perde a memória do projeto.
- **Custo previsível é requisito de arquitetura:** desenvolver mais não pode
  custar mais. Foi o modelo de créditos que inviabilizou o Lovable.
- **Fonte de verdade do schema:** `supabase/migrations`. Toda mudança de banco
  **MUST** ser migração versionada — nunca alteração manual no painel.
- **E-mail transacional:** Resend. O SMTP embutido não entrega (comprovado) e
  **MUST NOT** ser usado para auth.
- **Independência de fornecedor:** cada peça — código, banco, hosting — **MUST**
  permanecer substituível.
- **Camadas de autorização:** `user_roles` → `team_members` →
  `superadmin_operators`, resolvidas no banco.
- **Fuso:** o Brasil é UTC−3. Data pura (`date`) **MUST NOT** passar por UTC;
  data-e-hora (`timestamptz`) **MUST** carregar o fuso na gravação. Os dois
  erros existiram em produção e deslocavam o dado em um dia e em três horas.

## Fluxo de Desenvolvimento

- Ordem canônica: `grill-with-docs` (interrogar a ideia) → `nx-regra` (escrever
  a regra viva em `docs/regras/`) → `to-tickets` (abrir as issues) →
  `implement` (executar por fases). O Spec Kit saiu do projeto em 27/08/2026;
  o motivo está em `docs/adr/0004-o-spec-kit-sai.md`.
- Cada regra produz execução por fases, com aceite manual antes de avançar.
- Toda alteração de banco entra por migração; seeds são idempotentes.
- Correção na plataforma ao vivo segue `docs/ponte/ponte-inversa.md`: gate de
  tipos, `main`, sem `--force`, function antes do front, e `conferir` ao fim.
- Nenhuma credencial em PR, regra ou issue.

## Governance

- Esta constituição supera qualquer prática ou preferência de implementação.
- **Emendas** exigem: registro do motivo, incremento de versão, Sync Impact
  Report e revisão dos templates dependentes.
- **Versionamento (SemVer):** MAJOR — remoção/redefinição incompatível; MINOR —
  novo princípio ou expansão material; PATCH — redação e correções.
- **Conformidade:** todo plano e revisão **MUST** verificar aderência aos
  princípios I–IX. Complexidade que os contrarie precisa ser justificada por
  escrito ou rejeitada.
- **Orientação de runtime:** `CLAUDE.md` é o guia operacional e permanece
  subordinado a esta constituição. Quando os dois divergirem sobre um fato do
  mundo, **a constituição MUST ser corrigida** — foi assim que a cláusula de
  somente leitura sobreviveu seis dias além da sua validade.

**Version**: 2.0.1 | **Ratified**: 2026-08-02 | **Last Amended**: 2026-08-27
