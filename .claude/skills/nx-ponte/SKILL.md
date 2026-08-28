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
- **Correção via repositório, não pelo chat da plataforma.** Validado em
  17/08 (ver `../../../docs/historico/2026-08-16-verificacoes-tecnicas.md`): o envio pelo
  git chega ao editor e publica **sem consumir crédito**. O chat é o último
  recurso, não o caminho.
- **Alteração de banco pelo lado antigo desatualiza os tipos gerados.**
  Regenerar e enviar faz parte da correção, não é passo opcional.

## A ponte inversa — o caminho sem crédito

**O procedimento completo vive em `docs/ponte/ponte-inversa.md`. Leia esse
arquivo antes de executar qualquer correção — ele é a fonte de verdade, e o
que estiver aqui em conflito com ele está errado.**

O resumo, para saber o que esperar:

| Etapa | Comando | Precisa de navegador? |
|---|---|---|
| Clonar / atualizar | `bash scripts/ponte.sh preparar` | não |
| Corrigir | seu editor, no clone | não |
| Enviar | `bash scripts/ponte.sh enviar "fix: msg"` | não |
| **Publicar** | **Publish → Update, na Lovable** | **sim** |
| Provar que saiu | `bash scripts/ponte.sh conferir` | não |

**O Publish não tem CLI nem API pública** — confirmado na documentação da
Lovable e por teste próprio em 17/08: o site não republica sozinho após o push.
Toda correção termina num clique humano, e é o passo que mais se esquece. Se
esquecer, a correção fica no editor e o cliente continua vendo o bug.

Correção de **banco** não passa pelo repositório: vai pelo SQL editor do Cloud,
com **Export obrigatório antes de qualquer escrita** — não há recuperação no
tempo neste tier.

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
