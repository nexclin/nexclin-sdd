# 019 · Conformidade LGPD do painel

> **Regra viva.** Nasceu em 29/08/2026, de auditar as quatro lacunas registradas
> em [`2026-08-28-validacao-superadmin-mercado.md`](../historico/2026-08-28-validacao-superadmin-mercado.md),
> seção 3. Uma delas foi fechada no mesmo dia; as outras três estão aqui.
>
> **Por que separada da 017:** a 017 é sobre o painel de superadmin e a
> impersonação. Esta é sobre obrigação legal, e ela vale mesmo se o painel
> mudar de forma. Dado de saúde é sensível pela LGPD, e o produto se vende para
> clínicas: a conformidade é requisito de arquitetura, não feature.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md`

---

## 1. O problema

Quatro lacunas foram levantadas em 28/08. O estado delas em 29/08:

| # | lacuna | estado |
|---|---|---|
| 3.1 | não há trilha de leitura de dado clínico | **fechada**, FR-005 da regra 017 |
| 3.2 | não há tela para pedido do titular | aberta, FR-002 abaixo |
| 3.3 | não há política de retenção e eliminação | aberta, FR-003 abaixo |
| 3.4 | os papéis existem mas não limitam | **confirmada**, FR-001 abaixo |

A 3.4 estava marcada como *"verificação pendente, não acusação"*. A verificação
foi feita, e o resultado está no FR-001.

---

## 2. Requisitos

### O papel tem de limitar, e no banco

- **FR-001**: O papel do operador de superadmin **MUST** ser verificado no
  banco, e **MUST NOT** existir só como rótulo de tela.

  **A VERIFICAÇÃO, feita em 29/08/2026 contra o banco ao vivo, e não contra os
  arquivos:**

  | consulta | resultado |
  |---|---|
  | funções do banco que decidem por papel | **0** |
  | policies que decidem por papel | **0** |
  | funções de superadmin existentes | 7 |
  | operadores cadastrados | **1, papel `super_owner`** |

  Quatro funções casaram numa busca textual larga, e as quatro são falso
  positivo: `descricao_de_acao_de_superadmin`, `encerra_impersonacoes_vencidas`
  e `seed_chart_of_accounts` contêm a palavra "suporte" em texto, e
  `seed_superadmin_operator` **atribui** `super_owner` em vez de conferi-lo.

  `is_superadmin(uuid)` pergunta apenas se o usuário é operador **ativo**. Não
  olha o papel. Logo, no banco, `suporte` e `financeiro` podem tudo que
  `super_owner` pode: impersonar qualquer clínica, cancelar conta, provisionar,
  definir senha.

  **A única verificação de papel no produto inteiro** está em
  `SuperAdminOperadores.tsx:42`, `isSuperOwner`, e ela decide se um botão
  aparece. Isso é **violação da regra (c) da constituição**: segurança mora no
  banco, e a tela apenas reflete. Botão escondido não é permissão negada.

  **A urgência é menor do que a gravidade, e as duas precisam ser ditas.** Existe
  **um** operador, e ele é `super_owner`, então hoje ninguém está com poder além
  do que deveria. O buraco é **latente**: ele abre no instante em que o segundo
  operador for criado com `suporte` ou `financeiro`. Enquanto o painel tiver um
  único operador, o risco real é zero.

  **O que decide a prioridade é uma pergunta de negócio**, e está na seção 7: o
  Erick ou o mentor viram operadores antes de 08/09?

### O titular tem direitos, e eles precisam de caminho

- **FR-002**: **MUST** existir caminho auditado para **recuperar e exportar**
  todo o histórico de um paciente, inclusive de anos atrás. A eliminação vem
  depois, e não antes.

  **A ORDEM DOS DOIS FOI INVERTIDA EM 29/08/2026**, depois da resposta do
  Vinícius, e a inversão é a informação:

  > *"Tem paciente que já entrou na justiça e precisava de um laudo ou
  > prontuário de anos atrás. Aí tivemos que correr atrás de conseguir junto ao
  > sistema. Nunca pediram pra apagar nada."*

  A versão anterior desta regra tratava acesso, portabilidade e eliminação como
  três faces do mesmo requisito, seguindo o texto da LGPD. Na operação real de
  clínica, **o pedido que acontece é o de recuperação, e o gatilho é processo
  judicial.** O de eliminação nunca aconteceu.

  Isso não torna a eliminação dispensável: ela continua sendo direito do titular
  e vai ser exigida um dia. Torna-a **menos urgente que a recuperação**, que já
  aconteceu, tem prazo de tribunal, e hoje depende de alguém "correr atrás junto
  ao sistema".

  *Porquê ainda vale:* um pedido desses hoje vira consulta SQL escrita à mão por
  quem tiver acesso ao banco. **Isso não é fluxo, é improviso, e improviso não
  se audita**: não fica registro de quem atendeu, quando, nem o que foi
  entregue. Num processo judicial, é justamente isso que se pergunta.

  **A tensão que este requisito esconde, e que precisa ser resolvida junto:**
  o direito de eliminação conflita com a trilha de auditoria, que existe
  justamente para não sumir. As duas coisas são exigidas ao mesmo tempo.

  A saída é a mesma que o FR-005a da regra 017 já adotou, e ela vira princípio
  aqui: **elimina-se o dado do titular, preserva-se o REGISTRO DO ACESSO a ele.**
  `patient_access_log` guarda `patient_id` como uuid solto, sem chave
  estrangeira, exatamente para sobreviver à eliminação do paciente. A trilha
  passa a dizer que alguém leu um paciente que não existe mais, que é a resposta
  correta, e não uma contradição.

### O dado não pode ficar para sempre

- **FR-003**: **MUST** existir política de retenção escrita **por tipo de
  documento**, e ela **MUST** tratar o prazo como MÍNIMO antes de tratá-lo como
  máximo.

  **ESTE REQUISITO ESTAVA ESCRITO AO CONTRÁRIO.** A versão anterior dizia que o
  banco cresce para sempre e a LGPD pede o oposto, o que é verdade e é a
  preocupação errada para este produto. O Vinícius, em 29/08:

  > *"Tem prazo sim. Na prática, ninguém guarda e troca de sistema e às vezes
  > perde tudo. Mas o sistema é obrigado a ter isso. Mas os prazos variam sim,
  > prontuário que é o documento mais importante do paciente."*

  Três coisas saem daí, e as três mudam o desenho:

  1. **O prazo é MÍNIMO, e a falha real é perder antes.** Guardar demais é
     desperdício de disco. Perder um prontuário que a lei obrigava a manter é
     defesa judicial impossível. Os dois riscos não têm o mesmo peso.
  2. **O prazo varia por tipo de documento**, e prontuário é o mais longo. Uma
     política única para "dado de paciente" seria errada nos dois sentidos.
  3. **A perda acontece na TROCA DE SISTEMA.** Não é o banco que apaga: é a
     migração que deixa para trás.

  **O item 3 aponta para dentro de casa.** O NexClin troca de arquitetura em
  outubro, e migra o banco da Lovable para a stack nova. É exatamente o momento
  em que, segundo quem opera clínica, as clínicas perdem tudo. **A migração de
  outubro é o primeiro teste desta regra**, e não um evento à parte dela.

  *O que NÃO se decide aqui:* o número de anos. Continua em aberto, e agora por
  um motivo melhor do que antes: sabe-se que ele **varia por documento**, então
  um número só nunca teria servido.

  O FR-005d da regra 017 já decidiu isto para a trilha de leitura: **política
  escrita, sem expurgo automático antes de 08/09**, porque até o lançamento o
  risco é registrar de menos e não guardar demais. Esta regra estende o mesmo
  raciocínio ao resto, e **não** o transforma em promessa de prazo.

---

## 3. O que muda no banco

**FR-001** é o único com desenho já claro, e é pequeno:

Uma função `papel_do_operador()` que devolve o papel de `auth.uid()`, e um
`operador_pode(acao text)` que decide. As funções sensíveis passam a chamá-lo
na primeira linha, do mesmo jeito que `superadmin_contagens_da_clinica` já
chama `is_superadmin`.

O que cada papel pode é decisão da seção 7, e **não** deve ser inventado aqui.

**FR-002 e FR-003** dependem de decisão antes de virar esquema.

---

## 4. Premissas

O painel vive em endereço separado, com tabela de operadores própria e quatro
papéis: `super_owner`, `admin`, `suporte`, `financeiro`. Isso é **mais
restritivo que o padrão de mercado**, em que a conta mestra costuma ser uma só
com tudo liberado.

A escolha é deliberada e boa. O FR-001 existe porque ela ainda não foi
realizada: hoje o produto tem quatro nomes e um nível de acesso.

---

## 5. Dependências

FR-001 depende de `superadmin_operators.role` continuar sendo a fonte do papel.

FR-002 depende da trilha do FR-005 da regra 017 estar de pé, senão "o que foi
entregue ao titular" não tem como ser provado.

---

## 6. Como se prova

- **FR-001:** criar um operador `suporte`, assumir a identidade dele e tentar
  uma ação de `super_owner`. Tem de ser negada **pelo banco**, e não pela
  ausência do botão. A técnica está na seção 6 da regra 017: dentro de
  `BEGIN`/`ROLLBACK`, `SET LOCAL ROLE authenticated` mais
  `SET LOCAL "request.jwt.claims"`.
- **FR-002:** atender um pedido de titular de ponta a ponta e a trilha mostrar
  quem atendeu, quando, e o que saiu.
- **FR-003:** a política existir escrita, e o descarte, quando houver, apagar o
  que passou do prazo e nada além.

---

## 7. O que falta decidir

**A pergunta que ordena tudo: haverá segundo operador antes de 08/09?** Se o
Erick ou o mentor forem cadastrados, o FR-001 vira urgente. Se o painel seguir
com um operador `super_owner` até outubro, ele é requisito da stack nova e
espera.

**O que cada papel pode.** Precisa vir do Arthur, e a proposta abaixo é ponto de
partida, não decisão:

| papel | proposta |
|---|---|
| `super_owner` | tudo, inclusive gerir operadores |
| `admin` | tudo menos gerir operadores |
| `suporte` | impersonar e ler, sem cancelar conta e sem mexer em cobrança |
| `financeiro` | assinatura e cobrança, sem impersonar |

**Se `suporte` pode impersonar, ele lê prontuário.** Isso é aceitável porque a
trilha do FR-005 registra, e não seria aceitável sem ela. Vale notar a ordem em
que as duas coisas ficaram prontas: a trilha veio primeiro, e é ela que torna o
papel de suporte defensável.

**Prazo de retenção em anos.** Continua em aberto, e pelo mesmo motivo escrito
na seção 8 da regra 017: nenhuma norma brasileira fixa número para log de acesso,
e número inventado numa regra vira número citado numa auditoria.
