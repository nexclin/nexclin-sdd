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
  17/08 (ver `docs/planejamento/verificacoes-tecnicas-16-08.md`): o envio pelo
  git chega ao editor e publica **sem consumir crédito**. O chat é o último
  recurso, não o caminho.
- **Alteração de banco pelo lado antigo desatualiza os tipos gerados.**
  Regenerar e enviar faz parte da correção, não é passo opcional.

## A ponte inversa — o caminho sem crédito, passo a passo

O sentido que a plataforma faz sozinha é **Lovable → GitHub**: o bot dela
commita cada alteração feita pelo chat. A ponte inversa é o oposto —
**GitHub → Lovable** — e é ela que torna a fase de correção gratuita.

### Preparação, uma vez só

```bash
cd C:/Users/ahifr/Downloads
gh repo clone nexclin/nexclin nexclin-lovable
```

Este clone é o `../nexclin-lovable` que o `CLAUDE.md` regra (i) trata como
somente leitura **para agentes**. Arthur escreve nele; agentes não.

### A cada correção

1. **Anote o crédito antes.** No editor, clique no nome do projeto (canto
   superior esquerdo) → o painel mostra `Credits · N left`. Anote o N.
2. **Atualize o clone.** `git pull origin main` — **obrigatório**. O bot da
   Lovable também commita em `main` por conta própria (varreduras de segurança
   fizeram isso em 02/08 e 16/08). Pular esse passo gera push rejeitado.
3. **Conserto mínimo**, no seu editor, local.
4. **Envie:**
   ```bash
   git add <arquivos>
   git commit -m "fix: <o que corrige>"
   git push origin main
   ```
   Só `main` sincroniza — é a branch ativa, e só uma sincroniza por vez.
   **Nunca use `--force`:** reescrever o histórico de `main` confunde o lado da
   plataforma.
5. **Confirme no editor.** Abra o projeto. O commit aparece no histórico como
   entrada **"Pushed from GitHub"**, com o diff. Se não aparecer em ~2 minutos
   mesmo após recarregar, **pare e avise** — a ponte caiu e o custo da fase
   muda.
6. **Publique.** Isto **não é automático** — este é o passo que todo mundo
   esquece. Botão **Publish** (canto superior direito) → **Update**. Quando
   terminar, o botão passa a ler *Up to date*.
7. **Confira no site publicado**, em janela anônima:
   `https://nexclin.lovable.app`. A janela anônima elimina cache e sessão.
   > Cuidado: `/login` e `/signup` rebatem para `/` se você tiver sessão
   > ativa. Para conferir a tela de acesso sem deslogar, use
   > `/request-access`, que renderiza com sessão e usa o mesmo painel de marca.
8. **Anote o crédito depois.** Tem de ser o mesmo N do passo 1. Qualquer
   consumo maior que zero reprova a ponte e precisa ser reportado.
9. **Marque na planilha** o apontamento como corrigido.

### Correção de banco

Não passa pelo repositório: vai pelo **SQL editor do Lovable Cloud**
(`More → Cloud → SQL editor`), que também não consome crédito.

**Antes de qualquer escrita**, exporte: `More → Cloud → Overview → Advanced
settings → Export project data`. O tier atual **não tem recuperação no tempo** —
um `DELETE` ou `UPDATE` errado é irreversível. O export é a única rede.

O editor pede confirmação em operações destrutivas ("Confirm destructive
operation" → *Run anyway*). Leia a query antes de confirmar; é a última
barreira que existe.

### O que torna isso possível — e frágil

O workspace está no **plano Free, com 5 créditos por dia**. Se a ponte inversa
falhar, a fase de correção não fica cara: ela fica **inviável**, porque uma
funcionalidade real consome de 30 a 60 créditos. Por isso o passo 8 não é
burocracia.

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
