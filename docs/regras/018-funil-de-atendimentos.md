# 018 · Funil de atendimentos

> **Regra viva.** Nasceu em 29/08/2026, de o Arthur operar o Kanban de
> atendimentos **pela primeira vez com base cheia**. Até aquele dia o funil
> estava vazio, e não por acaso: os 240 leads não apareciam em coluna nenhuma
> por causa do artefato 7 do povoamento, corrigido no mesmo dia.
>
> **Faixa das quatro:** todas são **requisito da stack nova**, e nenhuma sobe
> para a Lovable. Pelo corolário da §2.5, item de backlog não é trabalho
> adiado: é requisito da stack nova, e mora na regra do módulo em vez de dormir
> numa lista.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md`

---

## 1. O problema

O funil da tela de Atendimentos organiza o lead em cinco estágios e permite
arrastar entre eles. Ele responde **onde** o lead está. Não responde **há quanto
tempo**, não deixa remover cartão sem fricção, e com volume real empurra os
cartões para baixo da dobra.

As três primeiras são de gestão. A quarta é de densidade, e tem uma ressalva que
importa mais que ela mesma.

**A ressalva:** a lista que o Arthur viu gigante tinha **240 leads simulados,
48 por coluna**. Uma clínica fundadora começa em zero e leva semanas para ter
dezenas. Em 08/09 a coluna terá dois ou três cartões. Dimensionar a tela para
240 seria otimizar para um volume que não vai existir, e o custo disso é real:
tela desenhada para muito fica vazia e estranha com pouco.

O que **não** depende de volume é o desperdício de altura no topo, e é só isso
que a FR-004 trata.

---

## 2. Requisitos

### Responder há quanto tempo, e não só onde

- **FR-001**: O cartão do funil **MUST** mostrar há quanto tempo o lead está no
  estágio atual, e o funil **MUST** permitir ordenar ou destacar por esse tempo.

  *Porquê:* "onde o lead está" é cadastro. "Há dezoito dias em Novo Contato" é
  gestão, e gestão é o que o NexClin vende. Um lead parado é receita parada, e
  hoje ninguém vê isso sem abrir cartão por cartão.

  **O dado já existe, e isto é o achado que barateia o requisito.**
  `Atendimentos.tsx:250` grava `funnel_move` em `lead_history` a cada
  movimento, com `created_at`. O tempo no estágio é a diferença entre agora e o
  último `funnel_move` do lead. **Não exige coluna nova.**

- **FR-002**: O histórico de movimentação **MUST** guardar o ESTÁGIO, e não a
  frase.

  *Porquê:* hoje `details` recebe `'Movido para ' || label`, texto livre. Para
  calcular tempo por estágio seria preciso extrair o estágio de dentro de uma
  frase em português, e renomear um rótulo na tela quebraria o cálculo em
  silêncio. É a mesma classe do artefato 3 do povoamento, em que descrição livre
  não casava com nome de serviço.

### Remover sem fricção, e sem perder o histórico

- **FR-003**: O cartão **MUST** oferecer exclusão direta, no lado oposto ao
  nome, e **MUST NOT** exigir diálogo de confirmação.

  *Porquê:* pedido do Arthur em 29/08, e o raciocínio dele está certo:
  confirmação a cada exclusão treina a pessoa a clicar em "sim" sem ler. A
  confirmação que sempre aparece deixa de ser barreira e vira reflexo.

- **FR-004**: A exclusão **MUST** ser desfazível por uma janela de alguns
  segundos, e a exclusão de lead **MUST NOT** apagar o histórico dele.

  *Porquê, e são dois porquês diferentes.*

  **O desfazer não é desfazer.** Hoje `deleteMutation` faz `DELETE` de verdade
  (`Atendimentos.tsx:266`). Linha apagada não volta. Então "desfazer em oito
  segundos" **não pode ser implementado como desfazer**: tem de ser
  **adiamento**. A tela remove o cartão na hora, segura a exclusão pela janela,
  e só executa quando ela expira. Quem cancela nunca chega a apagar nada.

  Fazer o contrário, apagar e tentar recriar, produziria um registro novo com
  `id` novo, e todo vínculo do antigo já teria cascateado embora.

  **E a exclusão hoje destrói prova.** A linha 268 faz
  `lead_history.delete().eq("lead_id", id)` **antes** de apagar o lead. Isso é
  redundante, porque `lead_history.lead_id` já tem `ON DELETE CASCADE`, e é
  danoso pelo mesmo motivo que o FR-005 da regra 017 recusou chave estrangeira
  para `patients`: **trilha que some junto com o que ela auditava não é
  trilha.**

  Tornar a exclusão mais fácil sem consertar isto multiplica a perda. É por
  isso que os dois estão no mesmo requisito, e não em dois.

### Caber na tela

- **FR-005**: O topo da tela de funil **MUST** caber junto com a primeira linha
  de cartões, sem rolagem.

  *Porquê:* hoje migalha, título, subtítulo e filtros consomem a altura toda, e
  os cartões começam abaixo da dobra. O usuário rola para ver o que a tela
  existe para mostrar.

  **Isto NÃO é sobre o tamanho dos ícones nem sobre o volume da lista.** É
  sobre o cabeçalho. Reduzir ícone para caber mais cartão seria otimizar para os
  240 leads simulados, e em 08/09 a coluna terá três.

---

## 3. O que muda no banco

**Quase nada, e é uma boa notícia.**

O FR-001 se resolve lendo `lead_history`, que já existe e já é povoado.

O FR-002 muda o que se ESCREVE em `lead_history.details`, ou acrescenta coluna
`to_stage`. Acrescentar coluna é melhor: `details` continua sendo a frase para
humano, e o estágio vira dado. Coluna anulável, então o histórico antigo
continua válido e o cálculo trata nulo como desconhecido.

O FR-004 remove um `DELETE` do código, e não acrescenta nada ao banco. Se a
exclusão virar reversível de verdade um dia, aí sim entra `deleted_at`, e isso
é decisão da seção 7.

---

## 4. Premissas

O funil tem cinco estágios, e eles são os do produto:
`novo_contato`, `em_atendimento`, `agendou`, `nao_agendou`, `recaptacao`. A
lista canônica está em `Atendimentos.tsx:179-183`.

**Escrever esses cinco aqui não é redundância.** Em 29/08 o povoamento inventou
outros cinco, e o efeito não foi número errado: foi o funil inteiro aparecer
vazio, com 240 leads na base. Vocabulário de estágio que não está escrito em
lugar nenhum é vocabulário que alguém reinventa.

---

## 5. Dependências

FR-001 depende de `funnel_move` continuar sendo gravado a cada movimento. Se um
caminho novo mover lead sem historiar, o tempo no estágio passa a mentir para
esses leads, e mentira parcial é pior que ausência, porque não se percebe.

---

## 6. Como se prova

- **FR-001:** mover um lead, esperar, e o cartão dizer o tempo certo. Com um
  lead movido há dias na base povoada, o número tem de bater com o
  `created_at` do último `funnel_move`.
- **FR-002:** ler `lead_history` e achar o estágio como dado, sem precisar
  interpretar a frase.
- **FR-003:** excluir pelo ícone do cartão, sem diálogo.
- **FR-004:** excluir, clicar em desfazer dentro da janela, e o lead continuar
  existindo **com o mesmo `id`**. Depois excluir e deixar a janela expirar, e o
  `lead_history` dele ter sobrevivido ou ter sido preservado onde a regra
  decidir.
- **FR-005:** abrir o funil numa tela de notebook e ver a primeira linha de
  cartões sem rolar.

---

## 7. O que falta decidir

**O histórico de um lead excluído vive onde?** Três saídas, e nenhuma é óbvia:

1. `lead_history` deixa de cascatear, e as linhas ficam órfãs, como a
   `patient_access_log` do FR-005 faz de propósito.
2. O lead passa a ter exclusão lógica, com `deleted_at`, e nada é apagado.
3. O histórico é copiado para uma trilha de exclusões antes de sumir.

A **2** é a mais completa e a que mais mexe: toda consulta de lead passa a
precisar do filtro, e esquecer o filtro em um lugar traz de volta o que foi
excluído. A **1** é a mais barata e é coerente com o que já foi decidido para a
trilha de leitura.

**Quanto dura a janela de desfazer?** O Arthur falou em oito a dez segundos.
Falta decidir se ela sobrevive à navegação: sair da tela dentro da janela
executa, ou cancela?
