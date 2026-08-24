# Plano de migração — Lovable → stack Next.js

**Data:** 24/08/2026 · **Janela alvo:** meados de setembro a outubro/2026
**Prazo do plano:** era 30/09 e **não existia rascunho** desde 19/08. Este é ele.
**Decisão de hospedagem:** `hospedagem-2026-08-23.md` (fica em Supabase; a
pergunta que decide é residência do dado, não provedor).

---

## O que estamos migrando, exatamente

**Não é uma migração de banco. É uma troca de aplicação sobre o mesmo banco —
ou quase.**

| | Lovable | Stack nova |
|---|---|---|
| Front | React 18 + Vite | Next.js App Router |
| Banco | Supabase gerenciado **pela Lovable** | Supabase **próprio** |
| Schema | 44 tabelas | **as mesmas 44**, já replicadas (SPEC 001, F1) |
| Auth | Supabase Auth | Supabase Auth |
| Deploy | Publish manual | Vercel, automático |

O schema **já está replicado** no projeto novo. O que falta migrar é **o dado
que as clínicas produzirem entre 01/09 e a virada** — e é isso que torna o plano
delicado, não o schema.

## A regra que governa tudo

> **O banco migra intacto** (Princípio VII). Lançamento errado em agosto não é
> descartado em outubro: **é importado.**

Daí a ordem de grandeza: o Arthur estima **R$ 100–200 mil de faturamento**
lançado por clínica no mês da Lovable. Não é dado de teste que se joga fora.

---

## Fase M0 — Pré-requisitos que não são negociáveis

Nada começa sem estes quatro. **Três já estão pendentes há dias.**

| # | O quê | Por que trava a migração |
|---|---|---|
| M0.1 | **Região do projeto Supabase novo** | A região **não muda depois**. Migrar dado para um projeto na região errada é migrar duas vezes |
| M0.2 | **Supabase Pro ligado** no projeto novo | Sem backup diário, a janela de importação não tem rede de proteção |
| M0.3 | **Auditoria de paridade de schema** | O relatório da F1 comparou 44 tabelas. Precisa ser **refeito na véspera**: a Lovable pode ter alterado o schema por conta própria — o bot dela já commitou migração de segurança sozinho em 20/08 |
| M0.4 | **Export do banco da Lovable** confirmado | Só se pode exportar 1× a cada 24h, e o link chega por e-mail |

## Fase M1 — Congelar a divergência de schema

**O risco silencioso da migração não é o dado — é o schema mudar embaixo.**

- A partir do início da janela, **nenhuma alteração de schema** na Lovable sem
  a migração correspondente entrar em `supabase/migrations` deste repositório.
- Rodar o comparador de schema **semanalmente** durante setembro, não só na
  véspera. Divergência descoberta no dia da virada é divergência descoberta
  tarde demais.
- **Atenção ao bot da Lovable:** ele commita em `main` por conta própria em
  varreduras de segurança. Já fez em 02/08, 16/08 e 20/08. Toda varredura dessas
  pode acrescentar policy ou coluna.

## Fase M2 — Ordem de cópia, ditada pelas chaves estrangeiras

A ordem não é escolha de estilo: inverter produz violação de FK.

```
1. Globais e configuração   clinics · plans · saas_settings · coupons
2. Identidade               auth.users → profiles → user_roles → team_members
3. Cadastros de apoio       services · consultation_types · closing_types
                            payment_methods · bank_accounts · chart_of_accounts
4. Pessoas                  patients · leads
5. Operação                 appointments → appointment_items
                            funnel_2_entries → closings
6. Financeiro               receivables · expenses
7. Derivados                tasks · anamnesis_* · billings · account_timeline
```

**`auth.users` é o passo mais delicado.** Não é uma tabela de negócio: é o
sistema de autenticação. Copiar linhas de `auth.users` entre projetos **não
preserva senha** de forma confiável.

> **Decisão a tomar, e ela é de produto, não técnica:** ou (a) todo mundo
> recebe um e-mail de redefinição de senha na virada, ou (b) migra-se o hash
> via API de admin, o que é mais frágil e menos auditável.
>
> **Recomendação: (a).** É honesto, é um e-mail só, e o fundador entende
> "mudamos de infraestrutura, defina sua senha de novo". Vale registrar como
> decisão datada antes de setembro.

## Fase M3 — O ensaio, que é o que separa plano de esperança

**Ensaiar a migração inteira com o dado real de setembro, antes da virada.**

1. Criar um projeto Supabase **de ensaio**, na mesma região do definitivo.
2. Rodar o roteiro completo de cópia nele.
3. **Conferir por soma, não por amostra:**
   - contagem de linhas por tabela, origem × destino;
   - **soma de `receivables.gross_value`** por clínica e por mês;
   - **soma de `expenses.value`** idem;
   - contagem de `appointments` por status.
4. Divergência de **um centavo** para a investigação. Financeiro não tem
   tolerância — é o diferencial pelo qual o produto foi vendido.

**Se o ensaio não rodar limpo duas vezes seguidas, a virada não acontece.**

## Fase M4 — A virada

| Passo | Detalhe |
|---|---|
| 1 | Janela de indisponibilidade anunciada ao fundador **com antecedência** |
| 2 | Congelar escrita na Lovable (avisar; não há trava técnica) |
| 3 | Export final |
| 4 | Rodar a cópia — a mesma ensaiada, sem improviso |
| 5 | Conferir as somas de novo |
| 6 | Apontar o domínio para a stack nova |
| 7 | Reset de senha em massa, se a decisão for (a) |
| 8 | **Manter a Lovable no ar, só leitura, por 2 semanas** — é a saída se algo aparecer depois |

## Fase M5 — O que a stack nova precisa ter ANTES da virada

Aqui está o gargalo real, e ele não é de migração de dado.

**Hoje a stack nova tem 2 de 11 telas do superadmin** e nenhum módulo de
clínica. Não dá para virar para uma aplicação que não faz o que a atual faz.

Mínimo, pelas 7 áreas da Onda 1:

| Área | Estado na stack nova |
|---|---|
| Auth + guards (T019, T020) | parcial |
| Dashboard | não portado |
| Pacientes | não portado |
| Atendimentos (leads) | não portado |
| Consultas | não portado |
| Tarefas | não portado |
| Contas a Receber | não portado |
| Configurações | não portado |
| Equipe | não portado |

**Consequência honesta:** o gargalo de outubro **não é a cópia do dado — é
reconstruir os módulos.** A cópia é um roteiro de um dia; os módulos são
semanas. Se em meados de setembro os módulos não estiverem de pé, a data que
cede é a da virada, não a qualidade.

> **Recomendação:** usar a skill `nx-modulo` para portar um módulo por vez, na
> ordem da `fila-especificacoes.md`, e medir o ritmo real no primeiro. O primeiro
> módulo portado é a única estimativa confiável dos outros oito.

## Fase M6 — As dívidas de modelo entram AQUI, não depois

A migração é a **única** janela barata para consertar o modelo, porque o dado
passa por uma transformação de qualquer jeito.

| Dívida | O que fazer na cópia |
|---|---|
| `appointment_items` com unidades misturadas | Normalizar: `sold_value` passa a ser **unitário**, como `prescribed_value`. A cópia divide pelo `quantity` |
| `consultation_type_id` sem FK | Unificar `services` e `consultation_types` num conceito só, **com FK**. A cópia resolve o id |
| `revenues` sem escritor | **Não copiar.** Ou nasce alimentada, ou não nasce |
| Descrição carregando o sufixo de desconto | A cópia extrai o sufixo para colunas próprias e grava a descrição limpa |

**Fazer isso depois custa uma migração com backfill sobre dado de cliente real.
Fazer na cópia custa uma linha de transformação no script.**

---

## Riscos, e o que fazer com cada um

| Risco | Probabilidade | O que reduz |
|---|---|---|
| Módulos não prontos em outubro | **alta** | Medir o ritmo no primeiro módulo, em setembro. É o único dado real |
| Schema divergiu sem ninguém ver | média | Comparador semanal (M1), não só na véspera |
| Senha dos usuários | certa | Decidir por (a) e avisar antes |
| Divergência financeira na cópia | baixa se ensaiada | Conferência por soma, não por amostra (M3) |
| Projeto na região errada | **desconhecida — e é o mais barato de checar** | M0.1, hoje |

## O que ainda não está decidido, e precisa estar antes de setembro

1. **Senha na virada** — (a) reset em massa ou (b) migrar hash. Recomendação: (a).
2. **Data da virada** — depende do ritmo dos módulos, não do calendário.
3. **A Lovable fica no ar quanto tempo depois?** Recomendação: 2 semanas, leitura.
4. **Quem avisa o fundador, e com quanto tempo?** Sem dono definido.
