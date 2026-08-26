# A prioridade inverteu: a Lovable passa na frente da stack nova

> Decisão do Arthur em 26/08/2026. **Contradiz o que a §2.5 do `CLAUDE.md` vinha
> orientando na prática**, e por isso fica registrada com a razão, não só com o
> resultado.

## O que muda

Até hoje, a orientação de trabalho era: corrigir na Lovable só o que atravessa,
e construir o que é novo na stack nova, porque o front React/Vite vai ser
reescrito em Next.js de qualquer forma.

**A partir de agora é o contrário.** Nas palavras dele:

> *"Tudo que a gente está fazendo aqui agora é para ter o Lovable pronto até o
> dia nove. Eu defini como prioridade fazer as coisas do Lovable. Então a gente
> vai seguir concluindo toda a modelagem do INI, tudo que já está definido, e o
> processo de migração vai ser concluído após o Lovable estar funcionando."*

E, sobre trabalhar nas duas frentes ao mesmo tempo:

> *"não dá para fazer isso se a gente ficar fazendo em paralelo."*

## A regra nova, em uma frase

**Toda especificação já definida é implementada na Lovable. A stack nova espera.**

## O que isso custa, dito uma vez e sem repetir

As telas construídas na Lovable serão reescritas em Next.js na migração. Isso é
retrabalho, e ele é real: as quatro telas de configuração fechadas hoje na stack
nova (T012 a T015) precisam de equivalentes lá, e depois os equivalentes são
descartados.

**O Arthur sabe disso e decidiu assim mesmo**, e a razão é boa: o lançamento é
em 08/09, e um produto que não abre não tem migração para fazer. Cliente
fundador não espera arquitetura.

Fica registrado para ninguém reabrir a discussão a cada tarefa. A decisão está
tomada; o custo está anotado; segue-se.

## Consequências práticas, para não haver dúvida no meio do caminho

| Assunto | Antes | Agora |
|---|---|---|
| Modelagem INI (régua, hora clínica, metas) | stack nova | **Lovable** |
| Apontamentos do Erick | triar e decidir faixa | **corrigir na Lovable** |
| Migrações pendentes na stack nova | aplicar | **espera** |
| Aceites da SPEC 001, 003 e 005 | bloqueiam o avanço | **esperam**, e não bloqueiam mais |
| Export e versão do banco | gate | **não é essencial agora** |
| SMTP e login do superadmin | gargalo de tudo | deixa de ser gargalo |

## Duas decisões que saíram na mesma conversa

### D-005.5: a ModuleKey `consultas` sai do contrato

Aprovada, pela opção B do clarify. O contrato passa a ter **14 chaves**.

A razão: hoje a chave existe no contrato, mas o item de menu "Consultas" leva
para `/acompanhamento`, protegido por outra chave. É uma permissão que ninguém
consegue conceder nem negar de fato, e o `docs/dominio/modulos.md` chama isso de
dívida de segurança.

**A aplicação fica para a fase de migração, e isso é deliberado.** Mexer no
contrato de permissões a treze dias de abrir é trocar um problema conhecido e
inerte por um desconhecido e ativo. É o mesmo raciocínio que já foi aplicado ao
furo do `team_members`, e que se provou certo lá.

Se a `residuos` da SPEC 013 for aprovada, as duas emendas viram uma só e o
contrato volta a 15.

### T017 da SPEC 005 fica adiado, e não pulado

O `quickstart.md` que a tarefa cita **nunca existiu**. Das sete specs, só a 001 e
a 002 têm esse arquivo.

Não vale escrever um agora, e o motivo é a própria inversão de prioridade: o
aceite da SPEC 005 exige o app Next.js rodando, que é exatamente o que acaba de
ser adiado. Um roteiro escrito hoje seria um documento que ninguém executa até
outubro.

**Os critérios de aceite não se perdem**: eles já estão na spec, como SC-001 a
SC-005, e é a partir deles que o roteiro nasce quando a migração começar.

## O que continua valendo da §2.5

Uma coisa não muda, e é a que mais importa: **o banco migra intacto**. Tudo que
as clínicas lançarem na Lovable vem junto em outubro. A régua de "dado
atravessa, cálculo de tela não" continua de pé, e continua sendo o motivo de
financeiro na Lovable ter de estar certo, não aproximado.
