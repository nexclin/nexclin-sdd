---
name: nx-ponte
description: Trabalha na plataforma Lovable que está no ar e recebe os primeiros clientes em 01/09 — correção de bug apontado nas baterias de teste, sem consumir crédito, via repositório. Use para qualquer conserto que precise chegar ao cliente antes da migração para a stack nova.
---

# A ponte — manter o produto atual de pé até a migração

O primeiro cliente entra em **01/09/2026 na plataforma Lovable**, não na stack
nova. Esta skill cobre o trabalho nessa plataforma durante a ponte. A stack
nova segue em paralelo, sem pressa, e a troca só acontece quando ela fizer
tudo o que a atual faz.

## Regras da ponte

- **Só bug entra.** A regra do plano é literal: bug corrige antes do
  lançamento; melhoria vira backlog e entra depois. Nada novo entra agora.
  Classificação é trabalho do agente `triador-apontamentos`.
- **Nada de refatorar.** Código que vai ser substituído não merece
  investimento. Conserto mínimo, cirúrgico.
- **Correção via repositório, não pelo editor da plataforma** — a
  sincronização é de mão dupla e escrever pelo git evita consumir crédito de
  alteração. Se o envio não aparecer publicado, pare e avise: isso muda o
  custo da fase de correções e precisa ser reapresentado aos sócios.
- **Alteração de banco pelo lado antigo desatualiza os tipos gerados.**
  Regenerar e enviar faz parte da correção, não é passo opcional.

## Roteiro de uma correção

1. Ler o apontamento já triado (tipo, severidade, reprodução).
2. Reproduzir no ambiente publicado antes de tocar em qualquer arquivo. Bug
   que você não reproduziu, você não corrigiu — apenas mexeu.
3. Localizar no código da plataforma atual. `INVENTARIO.md` §3 mapeia rota →
   arquivo.
4. Conserto mínimo. Se a correção exigir mudar regra de negócio, ela deixou de
   ser bug: devolva para decisão.
5. Enviar pelo repositório, conferir no site publicado, marcar na planilha.
6. Se tocou banco: regenerar tipos e enviar junto.

## A trava de lançamento

Bugs abertos que impedem ou atrapalham muito o uso precisam chegar a **zero**
antes de abrir para cliente. Ao terminar uma leva, reporte a contagem — é o
número que os sócios acompanham.

## O que esta skill não faz

Migração de dados. O ensaio de cópia usando base de clínica real tem
procedimento próprio (ordem das tabelas, recriação de acessos, janela de
troca) e prazo separado. Enquanto ele não estiver escrito e ensaiado, **não há
troca de plataforma** — o risco não é perder dado, é a stack nova chegar ao dia
da troca sem alguma função que o cliente já usava.
