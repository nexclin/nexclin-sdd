# 0003 · Onde o NexClin roda

**Situação:** Aceita · **Data:** 23/08/2026 · **Decide:** Arthur Hideo
**Revisar em:** 30/09/2026, junto do plano de cópia de dados

> Este documento nasceu em `docs/arquitetura/hospedagem-2026-08-23.md` e virou
> ADR em 27/08/2026, na reorganização. O corpo é o mesmo, palavra por palavra: só
> o cabeçalho e o endereço mudaram. A constituição exige que a escolha de
> hospedagem viva em documento datado, com o critério e a data da última revisão,
> e o formato ADR é exatamente isso.
**Origem:** Arthur levantou que "a melhor hospedagem hoje não seria Vercel e
Supabase — as pessoas têm falado em Railway, Cloudflare, AWS".
**Exigido por:** constituição v2.0.0, *Restrições Técnicas* — a escolha de
hospedagem vive em documento datado, com o critério e a data da última revisão.

---

## A conclusão, antes do raciocínio

**Ficar em Supabase + Next.js. Não migrar.** O que causa a lentidão que você
sente quase certamente **não é o provedor — é a distância entre a função e o
banco**, e isso se resolve com duas configurações, não com uma migração.

E há um fator que nenhuma das comparações que circulam mede, e que para o
NexClin é o mais pesado de todos: **onde o dado fisicamente mora**.

---

## 1. O fator decisivo é LGPD, não latência

Desde **23/08/2025** vale a **Resolução CD/ANPD nº 19/2024**. Armazenar dado
pessoal em servidor fora do Brasil **é transferência internacional de dados** —
inclusive quando é só "a nuvem". Para dado **de saúde**, que a LGPD trata como
dado sensível, isso exige mapear a operação (finalidade, duração, país de
destino, identificação do importador) e adotar **cláusulas-padrão contratuais**
da ANPD.

Não é proibido. É **trabalho de conformidade recorrente + uma objeção de venda**
que o concorrente vai usar contra nós numa clínica que pergunta "onde ficam os
dados dos meus pacientes?".

> **Consequência prática:** qualquer provedor **sem região no Brasil** é
> estruturalmente pior para este produto, independentemente de preço ou de
> benchmark. Isso elimina candidatos antes de olhar performance.

## 2. Os candidatos, contra esse critério

| Provedor | Região no Brasil | Postgres gerenciado | Veredito |
|---|---|---|---|
| **Supabase** | **Sim** — South America (São Paulo), sobre `sa-east-1` | é o produto | **Fica** |
| **Vercel** | **Sim** — `gru1` (São Paulo) para funções | não hospeda banco | **Fica**, com região fixada |
| **Railway** | **Não** — 7 regiões, nenhuma na América do Sul (2026) | sim, HA em Patroni desde mar/2026 | **Eliminado** pela residência |
| **Cloudflare** | PoPs no Brasil | **não hospeda Postgres** — D1 é SQLite | **Eliminado** pela arquitetura |
| **AWS (RDS/Aurora)** | Sim — `sa-east-1` | sim | **Só se crescermos muito** — ver §4 |

### Por que Cloudflare está fora, e não é preço

A camada de dados da Cloudflare é **D1 (SQLite serverless)**, R2, KV e Durable
Objects. **Não existe Postgres.** E o Princípio I da nossa constituição diz que
*a segurança mora no banco*: todo o isolamento multi-tenant do NexClin é **RLS
do Postgres**. Sair do Postgres não é trocar de hospedagem — é **reescrever o
modelo de segurança do produto**, que é justamente a peça que hoje está correta
e auditada (44 tabelas, zero sem RLS).

Cloudflare continua útil como CDN/DNS na frente. Como plataforma de dados, não.

### Por que Railway está fora

Railway ficou bom em banco — HA Postgres desde março/2026. Mas em 2026 **não
tem região na América do Sul**. Trocaríamos um problema de latência por o mesmo
problema **mais** o problema de residência. É andar para trás nos dois eixos.

## 3. A causa provável da lentidão — e por que migrar não resolveria

Função serverless roda em **uma região fixa**. O padrão da Vercel é os EUA.
Se as funções rodam em `iad1` (Virgínia) e o banco em `sa-east-1` (São Paulo),
**cada consulta atravessa o continente**: ~110–140 ms de ida e volta.

E o Next.js App Router faz **várias consultas por página** (server components,
cada um buscando o seu). Cinco consultas sequenciais nesse cenário = **meio
segundo só de viagem**, antes de qualquer renderização. É exatamente a sensação
de "delay na página".

**Trocar de provedor não conserta isso.** Co-localizar conserta:

1. **Banco em São Paulo.** Ao criar o projeto Supabase escolhe-se a região, e
   **ela não muda depois** — migrar de região é recriar o projeto.
   ⚠️ **Verificar antes de qualquer outra coisa** em qual região o projeto novo
   está. Se estiver fora do Brasil, é melhor descobrir **agora**, com o banco
   ainda sem cliente, do que em outubro.
2. **Funções na mesma região.** Fixar `gru1` na configuração da Vercel, para
   que a função nasça ao lado do banco.
3. **Menos idas ao banco.** Consulta sequencial em server component é o que
   multiplica a latência. Agrupar e paralelizar vale mais que qualquer provedor.

> **Medir antes de migrar.** Nenhuma decisão de troca deve sair de "as pessoas
> têm falado". Sai de número: tempo de resposta da consulta, medido da função,
> antes e depois de fixar a região.

## 4. Quando AWS passaria a fazer sentido

Não agora. Faria sentido se aparecer **um** destes:

- **Necessidade de Multi-AZ com failover automático.** O Supabase não tem
  failover Multi-AZ; réplicas de leitura existem nos planos altos, com menos
  flexibilidade que o RDS.
- **Exigência contratual de cliente grande** (rede de clínicas, convênio) por
  infraestrutura própria ou certificação específica.
- **Custo do Supabase ultrapassar o de operar RDS + o tempo de quem opera.**

**A armadilha do "vamos só self-hospedar o Supabase no RDS":** não funciona
direto. O Supabase depende de extensões do Postgres que um serviço gerenciado
restrito não deixa instalar — no RDS/Aurora não há superusuário de verdade, só
`rds_superuser`, que não pode `CREATE EXTENSION` fora da lista aprovada, e boa
parte das que o Supabase usa não está nela. Self-hospedar de verdade significa
**EC2 + operar o stack inteiro**: backup, patch, SSL, tuning. Para um time de um
desenvolvedor, isso troca trabalho de produto por trabalho de infraestrutura.

## 5. O que decide a responsividade de verdade, e não é o provedor

Na ordem em que dão retorno:

1. **Co-localização** função ↔ banco (§3). Maior ganho, menor custo.
2. **Índice.** As consultas mais pesadas do NexClin filtram por
   `clinic_id` + intervalo de data. Índice composto nessas colunas vale mais
   que qualquer upgrade de plano.
3. **RLS bem escrita.** Policy que chama função `SECURITY DEFINER` por linha
   custa caro em tabela grande. `get_my_clinic_id()` precisa estar estável.
4. **Menos viagens.** Ver §3.3.
5. **Cache do cliente.** O React Query já está no projeto e é subaproveitado.
6. **Plano de compute.** Último recurso — dinheiro comprando o que arquitetura
   resolveria melhor.

## 6. Ações

| # | Ação | Quem | Quando |
|---|---|---|---|
| H1 | **Conferir a região do projeto Supabase novo.** Fora do Brasil ⇒ recriar agora, sem cliente | Arthur | antes de 01/09 |
| H2 | Conferir a região do banco da plataforma Lovable (é lá que o dado real vai entrar em setembro) | Arthur | antes de 01/09 |
| H3 | Fixar a região das funções em `gru1` na Vercel | Claude | com a Fase 4 da SPEC 001 |
| H4 | Medir tempo de consulta da função antes/depois | Claude | após H3 |
| H5 | Índices compostos `clinic_id` + data nas tabelas de maior volume | Claude | spec própria |
| H6 | Registrar as transferências internacionais que existirem, com as CPCs da ANPD | Arthur + jurídico | antes do 1º pagante |

---

## Fontes

- [ANPD — Transferência Internacional de Dados](https://www.gov.br/anpd/pt-br/assuntos/assuntos-internacionais/transferencia-internacional-de-dados)
- [Armazenamento em nuvem configura transferência internacional (Conjur)](https://conjur.com.br/2024-dez-07/armazenamento-em-nuvem-configura-transferencia-internacional-de-dados/)
- [O que muda após agosto de 2025 — Resolução CD/ANPD 19/2024](https://www.smnadv.com.br/transferencia-internacional-de-dados-o-que-muda-apos-agosto-de-2025-e-como-sua-empresa-se-prepara/)
- [Supabase — Regional Invocations](https://supabase.com/features/regional-invocations)
- [Railway vs Cloudflare (Northflank, 2026)](https://northflank.com/blog/railway-vs-cloudflare)
- [Best PaaS for Multi-Region Deployments 2026 (Railway)](https://blog.railway.com/p/best-paas-multi-region-deployments-2026)
- [Best PostgreSQL Hosting 2026: RDS vs Supabase vs Neon vs Self-Hosted](https://dev.to/philip_mcclarence_2ef9475/best-postgresql-hosting-in-2026-rds-vs-supabase-vs-neon-vs-self-hosted-5fkp)
- [Supabase — Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
