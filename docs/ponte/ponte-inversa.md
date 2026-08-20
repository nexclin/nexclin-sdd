# A ponte inversa — corrigir o Lovable sem consumir crédito

> **Fonte de verdade deste procedimento.** A skill `nx-ponte` consulta este
> arquivo. Validado em 17/08/2026: push pelo repositório chega ao editor e
> publica com **zero consumo de crédito** (5 antes, 5 depois).

## O que é

O sentido que a plataforma faz sozinha é **Lovable → GitHub**: o bot dela
commita cada alteração feita pelo chat. A ponte inversa é o oposto —
**GitHub → Lovable** — e é ela que torna a fase de correção gratuita.

Isso importa porque o orçamento de crédito é apertado e uma funcionalidade real
consome de 30 a 60. Sem a ponte inversa, a fase de correção não fica cara: fica
inviável.

**Estado do plano em 20/08/2026** (conferido na tela): workspace *Erick's
Lovable*, plano **Pro**, com **20 créditos mensais** e **5 créditos diários de
build**. A versão anterior deste documento dizia "plano Free, 5 créditos por
dia" — estava desatualizada. Reconfira antes de planejar uma janela; é este
número que decide o que dá para pedir ao agente.

## De onde dá para executar — testado

| Etapa | Precisa de quê | Roda de outro dispositivo? |
|---|---|---|
| Clonar / atualizar | credencial do GitHub | **sim** |
| Editar e commitar | nada além do editor local | **sim** |
| Enviar (`git push`) | credencial do GitHub | **sim** |
| Conferir versão publicada | só `curl` | **sim** |
| **Publicar (Publish → Update)** | **sessão logada na Lovable, no navegador** | **não** |
| Conferir crédito | mesma sessão | **não** |

**Conclusão honesta:** a parte de código é totalmente independente de
dispositivo — de qualquer máquina com git você corrige e envia. Mas **a
publicação exige um navegador logado na Lovable.** Não existe CLI nem API
pública para isso: a
[documentação da Lovable](https://docs.lovable.dev/features/publish) diz
explicitamente que mudanças não são publicadas automaticamente e que é preciso
clicar em Publish. Confirmado também por teste próprio.

Consequência prática: você pode corrigir do celular, de outro computador, de
qualquer lugar — mas alguém com sessão na Lovable precisa dar o clique final.
Enquanto for você sozinho, planeje corrigir onde tiver o navegador.

**Saída possível, se isso incomodar:** conectar Vercel ou Netlify ao repositório
`nexclin/nexclin`. Essas plataformas publicam a cada commit, o que eliminaria o
clique — ao custo de sair do domínio `lovable.app` e passar a gerenciar o
hosting. É decisão de arquitetura, não de procedimento; fica registrada, não
recomendada agora.

## O procedimento

Use o script `scripts/ponte.sh`, que faz tudo que é automatizável e para
exatamente onde a mão humana é necessária.

### 1. Preparar

```bash
bash scripts/ponte.sh preparar
```

Clona (na primeira vez) ou atualiza o clone, mostra o estado da branch e grava
qual bundle está publicado agora. **O `git pull` não é opcional:** o bot da
Lovable também commita em `main` por conta própria — fez isso em 02/08 e 16/08,
em varreduras de segurança. Sem atualizar, o push é rejeitado.

### 2. Corrigir

Edite no clone. Regras da ponte: **só bug**, conserto mínimo, nada de refatorar
código que vai ser substituído. Se a correção exigir mudar regra de negócio, ela
deixou de ser bug — devolva para decisão.

### 3. Enviar

```bash
bash scripts/ponte.sh enviar "fix: descrição do que corrige"
```

Commita e envia para `main`. Só `main` sincroniza — é a branch ativa, e só uma
sincroniza por vez. **Nunca `--force`:** reescrever o histórico de `main`
confunde o lado da plataforma.

### 4. Publicar — o passo manual

Anote o crédito **antes**: no editor, clique no nome do projeto (canto superior
esquerdo) → `Credits · N left`.

Abra o [projeto](https://lovable.dev/projects/09bc3d2d-df13-4ce3-a41f-6aa1606a75df).
O commit aparece no histórico como **"Pushed from GitHub"**, com o diff. Se não
aparecer em ~2 minutos com recarga, **pare e avise** — a ponte caiu, e isso muda
o custo da fase de correções.

Clique em **Publish → Update**. O botão passa a ler *Up to date*.

Anote o crédito **depois**. Tem de ser o mesmo N. Qualquer consumo maior que
zero reprova a ponte e precisa ser reportado aos sócios.

### 5. Conferir

```bash
bash scripts/ponte.sh conferir
```

Fica observando o site publicado até o bundle mudar, o que prova que o deploy
saiu. Não depende de navegador.

Para conferir a olho, use **janela anônima** — e cuidado: `/login` e `/signup`
rebatem para `/` quando há sessão ativa. Para ver a tela de acesso sem deslogar,
use `/request-access`, que renderiza logado e usa o mesmo painel de marca.

### 6. Fechar

Marque o apontamento como corrigido na página de Apontamentos do Notion.

## O Publish publica o PREVIEW, não o commit

> Descoberto ao vivo em 20/08/2026, na segunda correção do dia. Custou um
> "publiquei e nada mudou" que quase passou despercebido.

Depois do push, o editor mostra o commit com um destes rótulos:

- **"Previewing"** — o preview já foi construído com esse commit. Publicar sobe
  esse código.
- **"Preview is out of date"** + botão **"Update preview"** — o preview ainda é
  de um commit anterior. **Publicar agora sobe o código VELHO**, e o botão
  Publish ainda vai dizer "Your website is up to date".

Foi exatamente o que aconteceu: cliquei Publish com o preview desatualizado, o
painel respondeu "Published / up to date", e o bundle no ar **não mudou**.

**Ordem correta:**
1. `enviar` pela ponte
2. No editor, se aparecer "Preview is out of date" → **Update preview** e
   **espere terminar** (levou ~11 minutos numa mudança de 15 arquivos)
3. Só quando o commit ler **"Previewing"**, clique Publish → Publish changes
4. `conferir` — o bundle TEM de mudar. Se não mudou, você publicou o preview
   velho; volte ao passo 2.

**Regra de bolso:** o `conferir` não é formalidade. É a única coisa que
distingue "publiquei" de "achei que publiquei". Duas vezes no mesmo dia o painel
da Lovable afirmou sucesso sem ter publicado o que se pedia — uma na edge
function, outra aqui.

## Correção de edge function — o Publish NÃO cobre

> Descoberto ao vivo em 20/08/2026, corrigindo o `invite-team-user`.
> Custou um estado inconsistente em produção. Leia antes de mexer em function.

**O Publish sobe só o front.** Uma alteração em `supabase/functions/` chega ao
repositório e ao workspace do editor — dá para lê-la em `More → Code` — mas a
**versão em execução continua a antiga**. Confira em
`More → Cloud → Edge functions`, coluna *Last updated*: se o carimbo é velho,
a correção não está no ar.

Isso é traiçoeiro porque o front novo **é** publicado. Se o contrato entre os
dois mudou (campo que deixou de ser enviado, resposta nova), produção fica com
metade da correção e a funcionalidade quebra — pior do que antes de começar.

**Ordem obrigatória quando a correção toca front e function:** garanta a function
primeiro, publique o front depois. Nunca o contrário.

**O CLI do Supabase não serve aqui.** O projeto é gerenciado pela Lovable e vive
numa organização de que a conta do Arthur não participa:
`supabase functions deploy --project-ref xbnffervqqphgsyeffdz` responde
**403 — "your account does not have the necessary privileges"**. Testado, não
suposto.

**O caminho que funciona** é pedir ao agente no chat do editor, com escopo
travado para ele não reescrever o que acabou de ser enviado pela ponte:

```
Faca APENAS o deploy da edge function `<nome>`. O codigo dela ja esta correto
no repositorio e nao deve ser alterado. NAO edite nenhum arquivo, NAO reescreva
codigo, NAO crie migracao, NAO mexa no frontend. A unica acao pedida e
redeployar essa function.
```

**Custo medido:** crédito mensal **não** foi consumido (20 antes, 20 depois);
saíram **0,4 do crédito diário de build** (5 → 4,6). Ou seja: deploy de function
é barato, mas não é grátis como o resto da ponte — conte com isso ao planejar
uma janela com várias functions.

**Confirme depois** recarregando `More → Cloud → Edge functions`: o *Last
updated* da function tocada tem de virar "1 minute ago" enquanto as outras
seguem antigas. E confira a resposta do agente: tem de dizer que nenhum arquivo
foi alterado.

## Correção de banco

**Não passa pelo repositório.** Vai pelo SQL editor do Lovable Cloud
(`More → Cloud → SQL editor`), que também não consome crédito.

**Antes de qualquer escrita, exporte:** `More → Cloud → Overview → Advanced
settings → Export project data`. O tier atual não tem recuperação no tempo — um
`DELETE` ou `UPDATE` errado é definitivo, e o export é a única rede.

O editor pede confirmação em operação destrutiva ("Confirm destructive
operation" → *Run anyway*). Leia a query antes de confirmar; é a última barreira
que existe.

Mudança de banco pelo lado antigo **desatualiza os tipos gerados** — regenerar e
enviar faz parte da correção, não é passo opcional.

## Armadilhas que só aparecem executando

1. **Esquecer o Publish.** A correção fica no editor e o cliente continua vendo
   o bug. É o erro mais provável de todos.
2. **Achar que o Publish sobe edge function.** Não sobe. Publicar o front de uma
   correção que também muda a function deixa produção pela metade — ver a seção
   "Correção de edge function" acima.
3. **Não dar pull antes.** Push rejeitado por causa dos commits do bot.
4. **Conferir `/login` logado.** Rebate para `/` e você conclui que não publicou.
5. **Cache do navegador.** Sempre janela anônima, ou use o `conferir`.
