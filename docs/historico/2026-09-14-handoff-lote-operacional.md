# Handoff, 14/09/2026: o lote operacional, e o que espera dois cliques

Para a sessão seguinte continuar sem reler a conversa. Cobre 13 e 14/09:
planos e tarefas das frentes 023 e 024, a mudança das issues para
`nexclin/nexclin`, o censo rodado no banco, e o código escrito na Lovable.

## Onde as coisas estão

| O que | Onde |
|---|---|
| Planos e tarefas | `docs/planos/023-avisos-e-recados-da-equipe/` e `docs/planos/024-perfil-operacional/` |
| Issues | **`nexclin/nexclin`**, milestones 021 a 024. `nexclin-sdd` está sem issue aberta |
| Censo de 14/09 | [`2026-09-14-censo-operacional.md`](2026-09-14-censo-operacional.md) |
| Migrações escritas e **não aplicadas** | `supabase/migrations/20260914010000_*` (024) e `20260914020000_*` (023); blocos em `docs/ponte/aplicacao-024-fase1/` e `docs/ponte/aplicacao-023/b5-*` |
| Código na Lovable, publicado | `e7980d3` (escopo.ts, perfil operacional), `a72ac8a` (funções puras), `a7f488e` (totais e anamnese). Só o primeiro estava no ar às 19:33 UTC |
| Código na Lovable, **commit local sem push** | `05edccd` em `main` do clone `C:\Users\ahifr\Downloads\nexclin-lovable`, "ahead 1". As telas das duas frentes |

## O que trava, e é de dois cliques

1. **As duas migrações não rodaram.** O Arthur deu aval explícito para rodar
   sem export novo (o último é de 25/08), com a razão: as clínicas ainda não
   fizeram implantação séria de dado. **O classificador do modo automático do
   app recusou duas vezes** a digitação de DDL no editor de SQL de produção,
   mesmo com o aval. Não foi contornado. Caminhos: o Arthur cola os blocos
   `b1` (024) e `b5` (023) no editor, ou muda o modo de permissão da sessão
   para um que pergunte em vez de recusar.
2. **Depois das migrações:** no clone, `git pull --rebase origin main` se o
   bot tiver commitado, `git push origin main`, e o Arthur faz Publish. Só
   então o `05edccd` vai ao ar. **Publicar antes das migrações quebra
   Tarefas e Consultas**, porque as telas gravam colunas que não existem.

## O que foi decidido nesta sessão e não está em regra

- **Issues moram em `nexclin/nexclin`**, decisão do Arthur em 14/09. Está no
  `CLAUDE.md` e em `docs/agents/issue-tracker.md`.
- **Uma pasta por regra em `docs/planos/`**, decisão de 13/09. Emenda na ADR
  0006 e no `docs/planos/README.md`.
- **Tarefas numeradas por centena por frente**: 023 em T2xx, 024 em T3xx.
- **O ranking de produtividade aparece também abaixo dos seis blocos do
  painel operacional**, para o FR-013 (visível a todo membro) valer para a
  secretária, que não tem `relatorios_demais`. Não está na lista do FR-014 e
  precisa entrar na regra 024 como precisão, pela alínea (l), quando a tela
  for aceita.
- **"Assumidas" no ranking só o dono vê**: a policy de `data_audit_log` de
  25/08 abre a trilha só para admin. A tabela diz "só o dono vê" em vez de
  zero. Se o ranking precisar da medida para todos, é uma função
  `SECURITY DEFINER` de contagem, e isso é banco, não tela.
- **Leads com cadência vencida** no painel são aproximação: lead ativo sem
  mudança há mais dias que `followup_days`. A cadência da regra 018 por
  `lead_history` é da stack nova.

## Aberto, em ordem

1. As clínicas fundadoras **não aparecem em `clinics.name`** por Claros
   Clinic nem Cezar Essence. Duas clínicas estão sem nome. Perguntar ao
   Arthur antes de qualquer aceite com clínica real.
2. Portão 3 da 024: `team_members` sem `user_id` em 17 clínicas, quase todas
   de teste. Joana e Lancinha, da Clínica Lançamento, logam e não têm
   `team_members`: não conseguem assumir. T352 leva ao Arthur.
3. Realtime da 023 (Fase 3, T241 a T246) não começou. A conversa atualiza a
   cada 30 segundos.
4. Aceites na tela de tudo que está em `05edccd`: nada foi provado no
   navegador. "Código lido, não comportamento provado", em todas.

## Ambiente

- A aba do editor de SQL da Lovable ficou aberta no Chrome. O editor
  **não travou** depois da primeira consulta automatizada, ao contrário da
  nota de 19/08: seis consultas em sequência com `Clear` e `Ctrl+Enter`.
- Perl com `?.` e `${` no replacement quebra; para JSX, usar o Edit.
