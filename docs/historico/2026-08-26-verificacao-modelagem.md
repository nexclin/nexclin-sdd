# Verificação completa da modelagem INI, 26/08/2026

> Pedida pelo Arthur: *"verifique se todas as funcionalidades implementadas
> estão funcionando corretamente, e se não estiver, corrija, mas como se já
> fosse lançar hoje"*.

## O que foi verificado, e como

| Camada | Método | Resultado |
|---|---|---|
| Sete módulos puros | 43 provas executadas contra o código compilado | **43 de 43** |
| Tipos | `tsc --noEmit -p tsconfig.app.json` | limpo |
| Build de produção | `vite build` | verde, 19,8s |
| Revisão estática | leitura das seis telas novas | 3 defeitos |
| Higiene do repositório | `git status` antes de commitar | 1 achado |

**O que esta verificação não cobre, dito uma vez:** nada aqui foi exercitado por
uma pessoa na tela, contra dado real. É código provado, não comportamento
provado. O que ela cobre é a aritmética e a decisão, que é onde o erro é caro e
silencioso.

---

## Os três defeitos, e os três eram reais

### 1. O fuso horário, e ele acertava todas as telas

Todo cálculo de data usa `getUTCDate` e irmãos, porque comparar por dia em UTC
evita que horário de verão e fuso de servidor mudem o resultado. Isso é certo
para a **conta** e errado para o **hoje**: o usuário está em UTC-3.

Medido, e não suposto:

```
instante: 2026-09-01T00:30:00.000Z
local BR : 31/08/2026, 21:30
UTC diz  : dia 1, mês 9
BR  diz  : dia 31, mês 8
```

Ou seja, **das 21h à meia-noite, todo dia**, e é o horário em que dono de
clínica olha o sistema:

- a tela de metas mostraria **setembro** no dia 31 de agosto;
- a régua de cobrança contaria **um dia a mais** de atraso em tudo;
- o recall contaria um dia a mais sem voltar;
- a próxima cobrança pularia de mês cedo demais.

`src/lib/hoje.ts` devolve a meia-noite UTC do dia do calendário em São Paulo.
Os `getUTC*` das funções puras passam a devolver o dia brasileiro, e **nenhuma
delas precisou mudar**.

### 2. O telefone curto virava um link quebrado

Cobrança e Recall montavam o link do WhatsApp com um regex escrito na própria
tela, duplicando a regra que `linkDeWhatsapp` já implementa e já testa.

A cópia **não recusava número curto**. Um telefone de quatro dígitos no cadastro
virava `https://wa.me/551234`, oferecido como botão válido, e que não abre
conversa nenhuma. A pessoa clica, não acontece nada, e ela conclui que o sistema
está quebrado.

É o Princípio VIII cobrando: duas implementações da mesma regra, e a segunda
esqueceu metade. As telas passaram a usar a função testada, e agora distinguem
"sem telefone" de "telefone incompleto".

### 3. `Number(x) ?? padrão` não protege de NaN

Precificação carregava os parâmetros gravados assim. `NaN ?? y` devolve **NaN**,
e a partir dali o cálculo inteiro vira NaN sem erro nenhum: a tela mostraria
"R$ NaN" como hora clínica e como preço mínimo.

E `||` também não serve, porque **imposto zero é legítimo**. Virou checagem
explícita com `Number.isFinite`.

---

## O achado de procedimento

O `npm install` que rodei para instalar `@lovable.dev/mcp-js` disparou um gerador
do próprio pacote, que **reescreveu `supabase/functions/mcp/index.ts` de 239
linhas para 2**.

Não é código meu, e teria quebrado a edge function de MCP se fosse junto no
commit. Revertido antes.

**Só apareceu porque a verificação olhou o `git status` antes de commitar.** Vale
como regra: instalar dependência num repositório que não é seu pode mexer em
arquivo gerado, e o `git status` é a única coisa que denuncia.

---

## O que ficou provado, por módulo

| Módulo | O que as provas protegem |
|---|---|
| `hoje.ts` | O dia brasileiro, incluindo a virada de mês às 21h30 |
| `reguaDeCobranca.ts` | Nenhum dia entre -3 e 400 fica sem faixa nem cai em duas; pago e cancelado nunca entram; variável sem dado não vaza para a mensagem |
| `precificacao.ts` | Cobrando o mínimo, a conta fecha exatamente no custo direto; soma de 100% devolve nulo em vez de infinito |
| `ocupacao.ts` | Taxa de falta sobre quem teve desfecho, não sobre o futuro; ocupação grampeada em 100% |
| `recall.ts` | Prazo zero desliga; exatamente no prazo já conta como vencido; a mensagem fala em meses |
| `diasUteis.ts` | Páscoa conferida contra anos reais; feriado em fim de semana não desconta duas vezes |
| `composicao.ts` | Caixa de 100 luvas por R$ 30 dá R$ 0,30 e não R$ 30; insumo órfão é contado, não somado como zero |

---

## O que continua pendente, e não é defeito

**Três migrações não aplicadas:** `20260826030000` (imobilizado e parâmetros),
`20260826040000` (informativos) e `20260826050000` (insumos). As telas funcionam
sem elas e dizem qual falta, em vez de quebrar.

**O mesmo defeito de fuso existe na stack nova**, em `lib/superadmin/acoes.ts`,
que chama `proximaCobranca(dia, new Date())`. Não corrigido porque a stack nova
está adiada por decisão de 26/08, e corrigir código congelado sem poder testá-lo
é acrescentar risco sem retorno. Fica anotado aqui para não se perder.
