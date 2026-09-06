# Constituição do NexClin

> **Este arquivo é um ponteiro, de propósito.** O Spec Kit lê a constituição
> daqui, e a constituição real deste projeto mora em
> [`../../docs/constituicao.md`](../../docs/constituicao.md), onde ela é
> emendada com número de versão e histórico.
>
> Duplicar o texto criaria duas leis que divergem no primeiro commit. Quem
> executa uma skill `speckit-*` deve abrir o arquivo apontado acima e tratá-lo
> como a lei, inteiro.

## O que vence, em ordem

1. [`docs/constituicao.md`](../../docs/constituicao.md), a lei do repositório.
2. [`CLAUDE.md`](../../CLAUDE.md), em especial a **§2.5**, que decide o que se
   corrige na plataforma ao vivo e o que só vira regra escrita.
3. A **regra viva** da área, em [`docs/regras/`](../../docs/regras/).

## As quatro que mais mordem um plano

Ficam aqui porque um plano que as ignora nasce errado, e quem gera plano nem
sempre abre a constituição inteira antes.

- **(a) e (b)** RLS em toda tabela com `clinic_id`, e default deny.
- **(c)** Segurança mora no banco. Nenhuma regra de acesso pode existir só no
  frontend.
- **(h)** Nenhuma feature sem regra viva aprovada. O plano para para aprovação
  humana antes de cada fase.
- **(j)** "Implementado ≠ funciona". Toda fase fecha com aceite executado à mão.
  Quando não der para provar na tela, registre literalmente *"código lido, não
  comportamento provado"* e deixe o item aberto.

A reunião de 03/09 acrescentou a **regra dos 200%**: 100% é construído e testado
por quem construiu, 200% é validado pela ótica do usuário final. Ver
[`docs/historico/2026-09-04-reuniao-03-09-decisoes.md`](../../docs/historico/2026-09-04-reuniao-03-09-decisoes.md).
