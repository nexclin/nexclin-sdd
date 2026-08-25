# Credencial de teste exposta em arquivo de texto — 25/08/2026

**Achado ao ler o arquivo de apontamentos da bateria de 25/08.**
**Ação necessária do Arthur. Nada foi feito automaticamente.**

---

## O que aconteceu

O arquivo `NexClin - Teste 25.08.txt`, com os apontamentos da bateria, começa
com as duas primeiras linhas sendo **o login e a senha do Vinícius em texto
claro**.

O usuário é `vinicius.barros_@hotmail.com`, e é uma conta real na plataforma que
está no ar. A senha não é reproduzida aqui de propósito: registrar a senha num
documento é repetir o problema que o documento descreve.

## Por onde essa senha já passou

Pelo menos:

1. **O arquivo de texto**, na pasta `Downloads` do Arthur.
2. **O canal por onde o arquivo foi enviado** — WhatsApp, pela forma como
   chegou. Mensagem de WhatsApp fica no aparelho de todo mundo do grupo, no
   backup em nuvem de cada um, e não é apagável de forma confiável.
3. **A sessão do agente que leu o arquivo**, ao processar os apontamentos.

Três cópias fora de controle é mais que suficiente para tratar a senha como
**queimada**.

## Por que isto importa mais do que parece

Não é uma senha de ambiente de teste isolado. **É uma conta real na plataforma
que recebe cliente em 08/09**, e a plataforma guarda dado de saúde de paciente.
A constituição abre com essa frase: um erro de isolamento não gera bug, gera
vazamento de dado sensível de terceiros que nunca escolheram estar aqui.

E há precedente no próprio projeto: a senha da conta-mestra
(`erpclinicas@gmail.com`) foi queimada exatamente assim, exposta em chat, e o
`CLAUDE.md` §3.6 registra que a nova só pode ser definida por reset manual.
**É o mesmo erro, três semanas depois.**

## O que fazer

| # | Ação | Quem |
|---|---|---|
| 1 | **Trocar a senha do Vinícius**, por recuperação por e-mail. Não pelo admin: a regra (e) não abre exceção para caso urgente. | Vinícius |
| 2 | Apagar o `.txt` da pasta `Downloads` depois de extraídos os apontamentos | Arthur |
| 3 | Combinar com os sócios que **credencial não anda junto com relato de teste** | Arthur |

## O que já foi feito por esta sessão

- **O arquivo não foi copiado para o repositório**, e a senha não foi escrita em
  nenhum arquivo versionado. O hook `guarda-constituicao` recusaria, mas a
  decisão foi anterior ao hook.
- Os apontamentos foram extraídos e trabalhados **sem** as duas primeiras
  linhas.

## A causa, que não é descuido

Vale nomear, porque a correção certa é de processo e não de repreensão: **o
Vinícius mandou a senha porque ninguém disse a ele que não precisava.** Ele está
colaborando, testando de graça, e a forma óbvia de "aqui está o que eu vi" é
mandar tudo, inclusive como entrar.

A prevenção é dar a ele um jeito de relatar que **não peça credencial**: o
formato da base de Apontamentos do Notion, que a skill `nx-apontamento` já
produz, tem quatro campos e nenhum deles é senha.

**Registrar isso na orientação da próxima bateria custa uma linha e resolve.**
