# Roteiro de verificação — o que provar antes do briefing do Erick

**Data:** 23/08/2026 · **Executor:** Arthur (exige sessão logada)
**Por que não sou eu:** a política de rede deste ambiente bloqueia
`nexclin.lovable.app` e `lovable.dev` — os dois respondem `http=000` no CONNECT.
Não é falta de login: o pacote não sai daqui. Testado duas vezes.

> **Antes de tudo: publicar.** Nada abaixo faz sentido sem um `Publish → Update`
> com todos os commits do dia. São **oito**, e nenhum toca edge function — vão
> num Publish só.

## Ordem de publicação

| # | Commit | O que carrega |
|---|---|---|
| 1 | `8ad3a15` | V-29, V-25, V-28A — relatórios |
| 2 | `be92a38` | V-18, V-20 — a entrada abate a consulta |
| 3 | `1dbf842` | V-32, V-15, V-16, V-11, V-12, V-04B |
| 4 | `a239dec` | V-27, V-19, V-10, V-01, V-03 |
| 5 | `2948c7f` | calendário da marca em todo o app |
| 6 | `63f87a4` | calendário volta a ser teal + V-14 |
| 7 | `799c82d` | dashboard: V-13, V-21.1, drill-down |
| 8 | `3287cf9` | multiplicação dupla no financeiro |
| 9 | `a7531e0` | calendário flutua + layout responsivo |

Confirme com `Publish → Update` até ler **"Up to date"**. Lembre da armadilha nº 1:
se aparecer *"Preview is out of date"*, clique **Update preview** primeiro e
espere ler **"Previewing"**.

---

## Teste 1 — V-21.6: o gráfico do fluxo de caixa

**Hipótese a testar:** o gráfico já lê de `receivables` (não da tabela vazia
`revenues`), então deve aparecer. Se não aparecer, a causa é outra.

1. Dashboard → período **Este mês**.
2. Role até o bloco **Fluxo de Caixa**.
3. Registre **as três coisas**, não só "apareceu/não apareceu":
   - o **saldo** exibido em número;
   - se a **linha** do gráfico é visível;
   - quantos **pontos** o eixo tem (rótulos no rodapé).

**Como interpretar:**

| O que você vê | O que significa |
|---|---|
| Saldo > 0 **e** linha visível | ✅ V-21.6 caiu junto com o V-27 |
| Saldo > 0, linha **invisível**, 1–2 pontos | Não é bug de dado: com poucos pontos a linha some. Vira ajuste de render |
| Saldo **zerado** | O problema é de dado, não de gráfico — me mande print e eu investigo |

## Teste 2 — V-21.2: ticket médio

**Hipótese:** o cálculo já é `(consultas + vendas) ÷ nº de fechamentos`, que é
por orçamento aprovado, como a D-9 pede. Parecia errado porque o valor da
consulta era **sempre zero** (V-18) — e isso foi corrigido.

O caso de teste é o do Vinícius, e ele fecha na mão:

1. Crie **dois orçamentos aprovados** para o **mesmo paciente**, em dias
   diferentes: um de **R$ 1.400** e outro de **R$ 700**.
2. Dashboard → período que cubra os dois.
3. **Ticket médio esperado: R$ 1.050** — porque `(1400 + 700) ÷ 2`.

> Se vier **R$ 2.100**, está contando por paciente em vez de por orçamento.
> Se vier **R$ 350** ou outro valor pequeno, está contando por item.

## Teste 3 — a multiplicação dupla (o achado mais grave)

Prova direta de `3287cf9`. **Faça este mesmo que não faça os outros**: é o único
que mexe em número de dinheiro.

1. Consulta nova → orçamento com **um item, quantidade 2, valor unitário R$ 200**.
2. Aprove **tudo**.
3. Relatórios → **Produtividade por Profissional**.

**Esperado:** Valor Orçado **R$ 400** · Valor Fechado **R$ 400** · Conversão **100%**.

> Se o fechado vier **R$ 800**, a correção não subiu — a multiplicação dupla
> ainda está lá.

4. Agora **reprove** uma das duas doses e recarregue.
   **Esperado:** orçado 400, fechado 200, conversão **50%**.

## Teste 4 — a entrada abate a consulta (D-3)

O item que o Vinícius disse que "vai fuder com tudo".

1. Nova consulta, **tipo com preço R$ 300**, **entrada R$ 100**.
2. Marque **compareceu**.
3. Orçamento de prescrição de **R$ 250**, aprovado.
4. Abra a tela financeira.

**Esperado:** Total a receber **R$ 450** (300 + 250 − 100), e o abatimento
aparecendo na **consulta** (que fica em 200), **não** na prescrição (que fica
inteira em 250).

## Teste 5 — hora da consulta (V-32)

1. Nova consulta às **10:00**.
2. Salve e olhe a lista.

**Esperado:** 10:00. Se aparecer 07:00, não subiu.

> Consulta criada **antes** de publicar continua 3h adiantada — o instante está
> errado no banco. Só a limpeza da D-14 resolve o passado.

## Teste 6 — convite de equipe (A4 / T017 / V-04B)

O item mais barato da trava, e o único que prova o T017.

1. Configurações → Equipe → **+ Novo** → secretária, marcar "criar acesso".
2. Salvar. **Esperado:** link de convite na tela, **sem** pedir senha.
3. Abrir o link em **janela anônima** → deve cair em `/nova-senha`.
4. Definir senha e entrar.
5. Voltar em Equipe: **uma única linha** para essa pessoa (V-04B).

## Teste 7 — layout, o que você levantou hoje

Abra a mesma tela na **TV** e no **monitor**:

- O conteúdo fica **centralizado** nos dois? (antes ficava colado à esquerda na TV)
- Os cartões **reorganizam** sozinhos, sem sobrar faixa vazia?
- Precisa de **zoom** em algum dos dois?
- O calendário do "Personalizado" **cobre** o conteúdo em vez de empurrar?

Medi em 2560, 1920, 1366, 820 e 390: nenhuma com rolagem horizontal, todas
centralizadas. Mas medição em harness não substitui o seu olho na tela real.

---

## E o que continua sem resposta

| # | Pendência | Por quê |
|---|---|---|
| A-SEC | Consulta de `storage.objects` | Decide se há vazamento de dado de saúde. Segue sem resposta desde 20/08 |
| A3 / T002 | `select level, count(*) from chart_of_accounts where clinic_id='<Vinícius>' and active group by level;` | Sem ela, V-24 não avança |
| H1 | **Região do projeto Supabase novo** | A região **não muda depois**. Se estiver fora do Brasil, é melhor descobrir agora do que em outubro |
| — | `.env` versionado em `nexclin/nexclin` | Se tiver `service_role`, é rotação urgente. A regra de permissão me bloqueou a leitura, e eu não contornei |
