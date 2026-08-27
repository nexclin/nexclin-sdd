# As seis migrações de 26/08, bloco a bloco

> Mesmo formato dos blocos de 25/08, que funcionou. Um bloco por passo, cada um
> com o que esperar de volta.
>
> **Destino: o banco da Lovable.** É onde o cliente fundador entra em 08/09, e a
> prioridade invertida de 26/08 diz que a stack nova espera
> (`docs/planejamento/inversao-de-prioridade-26-08.md`). As mesmas migrações vão
> para o projeto próprio na migração de setembro e outubro.

## Por que sou eu que escrevo e você que cola

Em 19/08 ficou provado que o editor de SQL da plataforma **executa uma consulta
diferente da que está na tela** quando é dirigido por automação. Registro em
`docs/seguranca/nota-sql-editor-lovable-2026-08-19.md`. Desde então nenhum
agente aplica migração ali.

## O caminho curto: um arquivo, uma colagem

**Se quiser resolver de uma vez, abra `TUDO-EM-UM.sql` nesta mesma pasta, copie
o arquivo inteiro e cole no editor de SQL.** São as seis migrações
concatenadas na ordem certa, e é seguro rodar mais de uma vez.

Depois, rode a conferência final que está no fim deste documento. Ela devolve
onze linhas, e todas têm de vir `true`.

### O erro que este atalho existe para evitar

Em 27/08 as onze linhas vieram `false`, porque o que foi colado foram as
**consultas de conferência** deste documento, e não as migrações. É um engano
razoável: as consultas são o que aparece em bloco de código aqui, e as migrações
aparecem só como caminho de arquivo.

**Conferência confere, migração aplica.** Se a conferência devolve `false`, ela
está funcionando: está dizendo que a migração ainda não entrou.

O resto do documento explica bloco a bloco, para quem quiser aplicar um por vez e
entender o que cada um faz.

---

## O ponto de retorno, antes de qualquer coisa

**Cloud → Database → Backups**, e anote a data e a hora do mais recente. Confirme
que é de hoje.

Nenhuma destas seis apaga dado. Cinco só criam tabela e coluna; a sexta muda
`appointments`, e mesmo assim só acrescenta uma coluna com valor padrão. O risco
aqui é bem menor que o dos blocos de ontem, e o backup continua sendo a rede.

## A ordem, e por que ela é essa

| Bloco | Migração | O quê | Muda tabela existente? |
|---|---|---|---|
| 1 | `20260826010000` | Toda ação de superadmin vira linha na timeline | não |
| 2 | `20260826020000` | Sessão de suporte com prazo | acrescenta coluna |
| 3 | `20260826030000` | Imobilizado e parâmetros de preço | não |
| 4 | `20260826040000` | Informativos de orçamento e consentimento | não |
| 5 | `20260826050000` | Insumos, fornecedores e composição | não |
| 6 | `20260826060000` | Salas, equipamentos e **duração da consulta** | **sim, `appointments`** |

Os blocos 1 e 2 vêm primeiro porque são os únicos que tocam auditoria: se algo
der errado neles, você descobre antes de as outras cinco escreverem qualquer
coisa. O 6 vem por último porque é o único que altera uma tabela em uso.

---

## Bloco 1. A linha do tempo da conta

Cole o conteúdo de
`supabase/migrations/20260826010000_toda_acao_de_superadmin_vira_linha_na_timeline.sql`.

**O que ele conserta.** A tela de detalhe da conta desenha uma linha do tempo, e
uma varredura em `app/`, `lib/` e `supabase/functions/` mostrou que
`account_timeline` tinha **uma leitura e zero escritas**. Era uma tela mostrando
dado que ninguém escrevia.

É trigger e não função de aplicação de propósito: com trigger, quem escrever
auditoria por qualquer caminho produz a linha do tempo sem saber que ela existe,
inclusive as funções de impersonação, que escrevem de dentro do banco.

**Retorno esperado:** sem erro. Inclui um reparo idempotente do histórico já
auditado, então pode inserir algumas linhas.

**Conferência:**

```sql
SELECT count(*) AS auditorias_sem_linha_do_tempo
  FROM public.superadmin_audit_log a
 WHERE a.clinic_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM public.account_timeline t
                    WHERE t.metadata ->> 'audit_log_id' = a.id::text);
```

Esperado: **0**.

---

## Bloco 2. A sessão de suporte ganha prazo

Cole o conteúdo de `supabase/migrations/20260826020000_impersonacao_com_prazo.sql`.

**O achado, e ele é pior que a ausência do prazo.** A impersonação troca a
**âncora**: `superadmin_enter_clinic` faz `UPDATE profiles SET clinic_id` no
perfil do operador, e `get_my_clinic_id()` lê `profiles.clinic_id` e mais nada.

Operador que entra numa conta e fecha o navegador sem clicar em sair fica com o
perfil apontando para a clínica do cliente **até alguém clicar em sair**. E na
próxima vez que abrir o sistema, entra direto lá dentro.

Por isso o prazo **desfaz a troca da âncora**, e não só esconde o banner. Um
prazo que só escondesse o aviso mantendo o acesso seria pior que nada.

**Depois de aplicar, rode isto e OLHE O NÚMERO:**

```sql
SELECT public.encerra_impersonacoes_vencidas();
```

Zero é o esperado. **Maior que zero é achado, não detalhe:** significa que havia
perfil de operador apontando para a clínica de um cliente sem ninguém saber.

---

## Bloco 3. Imobilizado e parâmetros de preço

Cole o conteúdo de
`supabase/migrations/20260826030000_imobilizado_e_parametros_de_preco.sql`.

**O que ele destrava.** A tela de Precificação hoje funciona com a depreciação em
**zero** e os parâmetros que se perdem ao sair da tela. Depois deste bloco, o
imobilizado entra na conta da hora clínica e os parâmetros passam a ser salvos.

Traz dois `CHECK` que impedem o número absurdo: ocupação entre 0 e 1, e a soma de
imposto, repasse e margem menor que 100. Somando 100 não sobra nada para pagar o
custo e o preço mínimo tende ao infinito; passando de 100, a divisão vira
negativa e a tela diria que está tudo bem.

**Conferência:**

```sql
SELECT to_regclass('public.assets') IS NOT NULL AS tem_assets,
       to_regclass('public.pricing_params') IS NOT NULL AS tem_params;
```

Esperado: **true** nas duas.

---

## Bloco 4. Informativos de orçamento e consentimento

Cole o conteúdo de
`supabase/migrations/20260826040000_informativos_de_orcamento_e_consentimento.sql`.

Blocos de texto reutilizáveis em orçamento, termo e recibo. O `CHECK` do `kind`
separa os três, porque um texto de garantia vazando para o termo de
consentimento é onde erro de texto vira problema de verdade.

**Vale repetir o que a tela já diz:** aqui mora o **texto** do termo, não a
assinatura. Assinatura com validade jurídica exige certificado digital e é
roadmap. Ter o texto aqui não substitui a assinatura.

**Conferência:**

```sql
SELECT to_regclass('public.budget_notices') IS NOT NULL AS existe;
```

---

## Bloco 5. Insumos, fornecedores e composição

Cole o conteúdo de
`supabase/migrations/20260826050000_insumos_fornecedores_e_composicao.sql`.

Três tabelas que fecham o custo variável do procedimento. A coluna que importa é
`units_per_purchase`: uma caixa de 100 luvas por R$ 30 custa **R$ 0,30 o par**, e
lançar os R$ 30 como custo do procedimento é o erro de custeio mais comum em
clínica.

**Conferência:**

```sql
SELECT to_regclass('public.suppliers') IS NOT NULL AS fornecedores,
       to_regclass('public.supplies') IS NOT NULL AS insumos,
       to_regclass('public.service_supplies') IS NOT NULL AS composicao;
```

---

## Bloco 6. Salas, equipamentos e a duração da consulta

Cole o conteúdo de
`supabase/migrations/20260826060000_salas_equipamentos_e_duracao_da_consulta.sql`.

**Este é o único que altera uma tabela em uso.** Ele acrescenta
`duration_minutes` em `appointments`, com padrão de 30 e um teto de 12 horas.

O teto não é preciosismo: duração digitada errada, como 3000 em vez de 30,
bloquearia a sala por dois dias, e o erro apareceria como "a agenda travou" e não
como "alguém digitou um zero a mais".

**Toda consulta existente ganha 30 minutos de uma vez**, e é por isso que o
conflito é **mostrado** e não impedido: a base nasce com conflitos que não são
reais, e limpar exige antes que alguém veja.

**Conferência:**

```sql
SELECT to_regclass('public.resources') IS NOT NULL AS tem_recursos,
       EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema='public' AND table_name='appointments'
                  AND column_name='duration_minutes') AS tem_duracao;
```

Esperado: **true** nas duas.

**O efeito colateral que vale tanto quanto:** a tela de Precificação estimava a
ocupação da agenda multiplicando consultas pela duração média dos serviços, e
dizia na cara que era estimativa. Com duração por consulta, ela passa a ser
medida.

---

## Conferência final, depois dos seis

```sql
SELECT 'assets'               AS objeto, (to_regclass('public.assets') IS NOT NULL)::text AS existe
UNION ALL SELECT 'pricing_params',       (to_regclass('public.pricing_params') IS NOT NULL)::text
UNION ALL SELECT 'budget_notices',       (to_regclass('public.budget_notices') IS NOT NULL)::text
UNION ALL SELECT 'suppliers',            (to_regclass('public.suppliers') IS NOT NULL)::text
UNION ALL SELECT 'supplies',             (to_regclass('public.supplies') IS NOT NULL)::text
UNION ALL SELECT 'service_supplies',     (to_regclass('public.service_supplies') IS NOT NULL)::text
UNION ALL SELECT 'resources',            (to_regclass('public.resources') IS NOT NULL)::text
UNION ALL SELECT 'appointment_resources',(to_regclass('public.appointment_resources') IS NOT NULL)::text
UNION ALL SELECT 'appointments.duration_minutes',
       EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema='public' AND table_name='appointments'
                  AND column_name='duration_minutes')::text
UNION ALL SELECT 'fn espelha_auditoria_na_timeline',
       EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
                WHERE n.nspname='public' AND p.proname='espelha_auditoria_na_timeline')::text
UNION ALL SELECT 'fn encerra_impersonacoes_vencidas',
       EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
                WHERE n.nspname='public' AND p.proname='encerra_impersonacoes_vencidas')::text
ORDER BY 1;
```

Esperado: **`true` nas onze linhas.** Qualquer `false` diz exatamente qual bloco
não entrou.

---

## O que muda nas telas depois dos seis

| Tela | Antes | Depois |
|---|---|---|
| Precificação | depreciação zero, parâmetros não salvam | conta completa, parâmetros gravados |
| Precificação, ocupação | estimada pela duração média | **medida** por consulta |
| Informativos | avisa que a tabela não existe | funciona |
| Insumos | avisa que a tabela não existe | funciona |
| Salas | avisa que a tabela não existe | funciona |
| Detalhe da conta, no superadmin | linha do tempo vazia | alimentada por trigger |

## Se algum bloco der erro

Nenhum destes seis apaga dado, e todos usam `IF NOT EXISTS` ou `DROP ... IF
EXISTS` antes de criar. Rodar de novo é seguro.

Erro que apareça, me mande a mensagem inteira. Erro de migração costuma dizer
exatamente qual objeto já existe ou qual falta, e isso resolve em uma linha.
