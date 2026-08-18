# Prompt para a próxima sessão — cole em um chat novo

> Copie tudo abaixo da linha. Foi escrito para ser autossuficiente: um chat sem
> nenhum contexto desta conversa consegue executar.

---

Você está trabalhando no repositório NexClin (`C:\Users\ahifr\Downloads\NexClin`).
Leia o `CLAUDE.md` primeiro — ele é a memória do projeto. Depois leia este
briefing inteiro antes de tocar em qualquer coisa.

## 1. Onde estamos

**NexClin é um SaaS de gestão para clínicas médicas e odontológicas.** Existem
duas plataformas em jogo, e confundi-las é o erro mais caro possível:

| | O que é | Papel |
|---|---|---|
| **Lovable** (`nexclin.lovable.app`) | o produto pronto, em produção | **é aqui que o primeiro cliente entra, em 01/09** |
| **Stack nova** (este repositório) | Next.js + Supabase próprio | migração posterior, invisível para o cliente |

O que **lança** é o Lovable. A stack nova segue em paralelo, sem pressa.

### Já está fechado — não refaça, não rediscuta

- **As duas verificações técnicas passam.** Corrigir código na Lovable custa
  **R$ 0**: commit no repositório `nexclin/nexclin` (branch `main`) → aparece no
  editor → clique manual de *Publish → Update*. Procedimento completo em
  `docs/ponte/ponte-inversa.md`, automatizado em `scripts/ponte.sh`. O clique é
  obrigatório: o site **não** republica sozinho (testado, 20 minutos de
  observação).
- **Fase 0 da SPEC 002 confirmada no banco ao vivo.** Achado 1 (policies `anon`
  em anamnese) **corrigido**. Achado 2 (ação sobre `patients` não deixa rastro)
  **vivo**. Registro em `docs/seguranca/confirmacao-fase0-2026-08-16.md`.
- **Auditoria de RLS nas duas plataformas** — zero tabelas sem RLS, zero
  policies `anon`, zero triggers desabilitados, âncora `prevent_clinic_id_change`
  ativa nos dois. **44 tabelas em cada banco**, paridade.
  Ver `docs/seguranca/auditoria-rls-2026-08-17.md`.
- **Seed idempotente funcionando** (`npm run seed`, roda 2x sem duplicar).
- **Fluxo de recuperação de senha construído** na stack nova:
  `/esqueci-senha`, `/auth/callback`, `/nova-senha`.
- **Três planos criados no banco do Lovable, ainda ocultos**: Essencial 3
  usuários R$ 249 / anual R$ 2.739 · Clínica 5 usuários R$ 399 / R$ 4.389 ·
  Corpo Clínico 8 usuários R$ 599 / R$ 6.589. Trial de 30 dias, `max_users`
  3/5/8, `visibility = 'hidden'`.

### Decisões tomadas agora, que regem esta sessão

1. **Onda 1 nas três faixas.** As faixas se diferenciam por **número de
   usuários**, não por funcionalidade. Todos os planos abrem as mesmas 7 áreas.
2. **A trilha de auditoria entra na janela de 22–23/08**, antes do lançamento —
   não em 31/10. Não é tarefa desta sessão, mas o cronograma conta com ela.
3. **Os preços estão aprovados.** Os planos podem ser publicados.

## 2. Onde chegaremos em breve

| Quando | O quê |
|---|---|
| 17–21/08 | Bateria de testes do Vinícius (em andamento) — olhar de gestão clínica |
| 22–23/08 | Fim de semana de correção: bugs da bateria + Fase 2 da SPEC 002 (trilha de auditoria) + corrigir `invite-team-user` |
| 24–26/08 | Bateria do Erick, sobre a versão corrigida |
| 27–28/08 | Tutorial em vídeo, base de conhecimento, grupo de suporte, apresentação comercial |
| 29–30/08 | Segunda leva de correção e congelamento do que entra |
| 31/08 | Ensaio de onboarding com clínica fictícia |
| **01/09** | **Lançamento** |

**A trava de lançamento** — bugs abertos que impedem ou atrapalham muito o uso —
precisa chegar a **zero** antes de abrir para cliente.

## 3. Onde queremos chegar

Lançar em 01/09 na plataforma Lovable, com a trava em zero, e migrar para a
stack nova depois, sem o cliente perceber. O plano de cópia de dados ainda não
existe e tem prazo 30/09 — paridade de schema é condição necessária, não
suficiente.

## 4. O que executar nesta sessão

Quatro blocos. **Três são automatizáveis; um exige a mão do Arthur.**

### Bloco A — Planos para Onda 1 e publicação

No banco do Lovable, via `More → Cloud → SQL editor` no navegador (o Arthur
está logado). As 15 ModuleKeys oficiais são: `dashboard, leads, pacientes,
anamnese, consultas, acompanhamento, tarefas, contas_receber, contas_pagar,
fluxo_caixa, relatorios_vendas, relatorios_demais, configuracoes, equipe,
insights`.

**A Onda 1 são 7 áreas:** Configurações, Pacientes, Atendimentos (`leads`),
Consultas, Tarefas, Contas a Receber e Dashboard. Mapeie para as chaves exatas e
**confirme o mapeamento com o Arthur antes de gravar** — "Consultas" pode
significar `consultas`, `acompanhamento`, ou as duas.

Depois: `visibility` de `hidden` para `public` nos três planos, e a duração
padrão de trial em `saas_settings` de 14 para **30** dias.

Por que Onda 1 e não tudo: o plano de lançamento registra que **repasse** tem
imposto fixado em zero e atribuição de profissional estimada — "para um público
de médicos, é o relatório mais sensível que existe" — e que **Insights** depende
de provedor externo que não sobrevive à migração.

### Bloco B — `WITH CHECK` na policy de `profiles`, em produção

A policy de UPDATE em `profiles` no Lovable não tem `WITH CHECK`; o Postgres
reaproveita o `USING`, que só valida `user_id`. A âncora multi-tenant fica
apoiada só no trigger. **Já aplicado na stack nova** (migração
`20260817021500_endurece_update_profiles_with_check.sql`); falta produção:

```sql
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    AND clinic_id IS NOT DISTINCT FROM public.get_my_clinic_id()
  );
```

Não quebra nada: a condição é a mesma que o trigger já impõe.

### Bloco C — Fila de especificações

Prazo 23/08. O documento que ordena as próximas etapas técnicas depois da
fundação não existe no repositório. Deve listar, em ordem de dependência, as
specs que faltam — os módulos da Onda 1 na stack nova são o núcleo. Leia
`specs/` para ver o padrão já usado.

### Bloco D — Publicar o `v2.4.3` *(exige o Arthur)*

O repositório da plataforma está em `v2.4.3` e o site publicado em `v2.4.2`,
resíduo do teste da ponte. Um *Publish → Update* fecha. Depois,
`bash scripts/ponte.sh conferir` prova o deploy.

## 5. Como orquestrar — engenharia de grafos

Use subagentes em **grafo**, não em esteira. Os princípios abaixo vêm da
literatura de orquestração multi-agente e são para seguir, não para adaptar:

1. **Grafo acíclico com dependências explícitas.** Blocos A, B e C são
   independentes — disparo simultâneo. D depende de ação humana e fica fora do
   grafo.
2. **Isolamento de contexto.** Cada agente em contexto próprio, dono de **uma**
   coisa. Roteie para cada nó **apenas o estado prerequisito** que ele precisa —
   contexto compartilhado a mais é o que produz alucinação em pipeline longo.
3. **Nenhum agente consome o resultado de outro.** Sem dependência, sem
   propagação de erro.
4. **Escopo negativo obrigatório.** Diga a cada agente o que ele **não** deve
   fazer. Se perceber que precisa sair do escopo, **para e reporta**.
5. **Verificação como sinal de coordenação**, não como etapa final. Cada retorno
   é revisado sozinho, contra a fonte, com evidência — `arquivo:linha`, saída de
   comando, resultado de consulta. **Agente descreve com confiança trabalho que
   não fez.** Sem evidência, é alegação.
6. **Barreira no fim.** Só quando todos voltarem, verifique contra o critério de
   aceite de cada bloco — nunca contra "o agente disse que fez".

**Antes de disparar, me entreviste** sobre o que ficou ambíguo. Não invente
premissa.

## 6. Regras rígidas — valem para tudo

- **RLS em toda tabela com `clinic_id`.** Default deny. Segurança mora no banco;
  a tela só reflete.
- **Nenhum caminho define senha de terceiro.** Só `resetPasswordForEmail`.
- **Nenhuma credencial em código, spec ou arquivo versionado.** O `.env.local`
  é bloqueado por regra de permissão do repositório, de propósito — não tente
  escrevê-lo nem contornar.
- **Migração é a única via de mudança de schema** neste repositório. Mudança no
  banco do Lovable vai pelo SQL editor do Cloud, e **exporte antes de qualquer
  escrita** (`Cloud → Overview → Advanced settings → Export project data`): não
  há recuperação no tempo nesse tier.
- **Só bug entra** até o lançamento. Melhoria é backlog.
- **"Implementado ≠ funciona".** Toda entrega fecha com critério de aceite
  executado, não com relato.

## 7. Estado do repositório

Branch `pr30`, com PR aberto para `main`. Commite cada bloco separadamente, com
mensagem que explique **por que**, não só o quê. O servidor de dev sobe com
`npm run dev`.

## 8. Pendências conhecidas — não são desta sessão

- **Achado 2** (rastro em `patients`) — janela de 22–23/08
- **`invite-team-user`** aceita `password` do cliente e cria usuário com ela,
  contra a regra da constituição, **em produção** — mesma janela
- **`npm audit`**: 1 vulnerabilidade crítica, 5 altas incluindo `next`.
  `--force` sobe versão major; fica para depois de 01/09
- **"Build unsuccessful"** marcado no editor da Lovable apesar de o deploy
  funcionar — reconferir antes de 22/08
- **Migração para Vercel**, que eliminaria o clique manual de Publish — decisão
  de calendário, não de procedimento
- **Auditoria profunda de segurança e banco** — o Arthur quer fazer, com muitos
  agentes em paralelo. É a próxima fase depois desta.
