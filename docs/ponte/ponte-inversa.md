# A ponte inversa — corrigir o Lovable sem consumir crédito

> **Fonte de verdade deste procedimento.** A skill `nx-ponte` consulta este
> arquivo. Validado em 17/08/2026: push pelo repositório chega ao editor e
> publica com **zero consumo de crédito** (5 antes, 5 depois).

## O que é

O sentido que a plataforma faz sozinha é **Lovable → GitHub**: o bot dela
commita cada alteração feita pelo chat. A ponte inversa é o oposto —
**GitHub → Lovable** — e é ela que torna a fase de correção gratuita.

Isso importa porque o workspace está no **plano Free, com 5 créditos por dia**,
e uma funcionalidade real consome de 30 a 60. Sem a ponte inversa, a fase de
correção não fica cara: fica inviável.

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
2. **Não dar pull antes.** Push rejeitado por causa dos commits do bot.
3. **Conferir `/login` logado.** Rebate para `/` e você conclui que não publicou.
4. **Cache do navegador.** Sempre janela anônima, ou use o `conferir`.
