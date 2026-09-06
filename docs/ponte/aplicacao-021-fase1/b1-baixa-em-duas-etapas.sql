-- ===========================================================================
-- 021 FASE 1, BLOCO 1 — a baixa passa a ter valor recebido, autor e hora
-- ===========================================================================
--
-- Atende FR-002 e FR-003 de docs/regras/021-financeiro-que-nao-erra-o-caixa.md.
--
-- FR-004, saldo inicial da conta bancaria, NAO esta aqui, e a razao importa:
-- ele JA ESTA FEITO. `bank_accounts.opening_balance` e `opening_date` existem
-- desde a migracao 20260427222514, e a regra dizia o contrario porque foi
-- escrita a partir de uma leitura incompleta das migracoes em 05/09/2026. A
-- regra foi corrigida no mesmo commit que este arquivo.
--
-- O QUE FALTA HOJE, e foi conferido lendo 20260322140448:
--   `receivables` tem `value`, `gross_value`, `net_value`, `status` e
--   `paid_at DATE`. Nao tem onde gravar o que o banco CREDITOU, nem quem deu a
--   baixa, nem a hora.
--   `expenses` tem `value`, `status` e `paid_at DATE`. Nem `net_value` nem
--   `gross_value`, e tambem nenhuma coluna de autor.
--
-- POR QUE TRES COLUNAS E NAO UMA
--
--   `settled_value`  o que de fato entrou ou saiu. `value` continua sendo o
--                    PREVISTO. Quando os dois divergem, por tarifa, desconto,
--                    juro ou pagamento parcial, hoje o sistema grava o previsto
--                    como se fosse o realizado, e e assim que nasce divergencia
--                    de caixa.
--   `settled_by`     quem decidiu que o dinheiro entrou. Alinea (d) da
--                    constituicao. Ficou mais urgente com a decisao de 04/09 de
--                    login de superadmin compartilhado pelos tres socios: sem
--                    autor, tres pessoas viram uma.
--   `settled_at`     a HORA, em timestamptz. `paid_at` e DATE e continua sendo
--                    a DATA DE CAIXA, que e o que `dataDeCaixa` le. Sao duas
--                    perguntas: em que dia o dinheiro entrou, e em que instante
--                    alguem afirmou isso. Trocar o tipo de `paid_at` quebraria
--                    `dataDeCaixa` nas duas telas.
--
-- TUDO NULO PARA A LINHA ANTIGA, DE PROPOSITO. Nulo aqui quer dizer "baixa
-- anterior a esta regra". Preencher com palpite transformaria ausencia de
-- registro em registro falso, e auditoria com dado inventado e pior que
-- auditoria vazia.
--
-- RLS: nenhuma politica nova. Sao colunas em tabelas que ja tem RLS por
-- `clinic_id` desde 20260322140448, e coluna nova herda a politica da tabela.
-- ---------------------------------------------------------------------------

alter table public.receivables
  add column if not exists settled_value numeric,
  add column if not exists settled_by    uuid references auth.users(id) on delete set null,
  add column if not exists settled_at    timestamptz;

alter table public.expenses
  add column if not exists settled_value numeric,
  add column if not exists settled_by    uuid references auth.users(id) on delete set null,
  add column if not exists settled_at    timestamptz;

-- Valor de baixa negativo nao existe. Estorno e outro lancamento, nao um
-- numero com sinal trocado. `not valid` NAO seria certo aqui: como toda linha
-- antiga esta nula, e nulo passa em CHECK, a restricao ja nasce valida.
alter table public.receivables
  drop constraint if exists receivables_settled_value_nao_negativo;
alter table public.receivables
  add constraint receivables_settled_value_nao_negativo
  check (settled_value is null or settled_value >= 0);

alter table public.expenses
  drop constraint if exists expenses_settled_value_nao_negativo;
alter table public.expenses
  add constraint expenses_settled_value_nao_negativo
  check (settled_value is null or settled_value >= 0);

comment on column public.receivables.settled_value is
  'Valor efetivamente recebido na baixa. `value` continua sendo o previsto. FR-002 da regra 021.';
comment on column public.receivables.settled_by is
  'Quem deu a baixa. Nulo em baixa anterior a 06/09/2026. FR-003 da regra 021.';
comment on column public.receivables.settled_at is
  'Instante da baixa, com fuso. `paid_at` continua sendo a data de caixa. FR-003 da regra 021.';
comment on column public.expenses.settled_value is
  'Valor efetivamente pago na baixa. `value` continua sendo o previsto. FR-002 da regra 021.';
comment on column public.expenses.settled_by is
  'Quem deu a baixa. Nulo em baixa anterior a 06/09/2026. FR-003 da regra 021.';
comment on column public.expenses.settled_at is
  'Instante da baixa, com fuso. `paid_at` continua sendo a data de caixa. FR-003 da regra 021.';
