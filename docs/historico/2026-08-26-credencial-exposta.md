# Senha da conta-mestra exposta em chat, 26/08/2026

> Segundo registro do mesmo tipo em dois dias. O primeiro é
> `2026-08-25-credencial-exposta.md`, sobre a senha do Vinícius.

## O que aconteceu

A senha da conta-mestra (`erpclinicas@gmail.com`) foi colada em texto puro numa
mensagem de chat, junto com o e-mail, para que eu entrasse no sistema e
executasse os aceites da SPEC 003.

Não entrei, e não vou entrar: digitar credencial de login não é coisa que eu
faça, em nenhum contexto.

## Por que a senha está queimada

Não é formalidade. Mensagem de chat trafega e fica gravada em pelo menos três
lugares fora do gerenciador de senhas: o histórico da conversa, o transcript da
sessão em disco, e qualquer backup dele. Uma senha que existe nesses três
lugares não é mais um segredo, independentemente de quem leu.

A §3.6 do `CLAUDE.md` já registra que **a senha anterior desta mesma conta foi
descartada pelo mesmo motivo**. É a segunda vez com a mesma conta.

## O que fazer

1. Trocar por **recovery no painel do Supabase**. Não definir a nova senha em
   nenhum lugar que não seja o gerenciador.
2. Não repetir o padrão `Nome123!`. A senha exposta seguia um formato adivinhável
   a partir do nome do produto, o que reduz o custo de um ataque de dicionário a
   quase nada mesmo sem o vazamento.
3. Conferir `last_sign_in_at` da conta depois da troca.

## O lado bom, e ele é real

Fazer isso **fecha o T012 da SPEC 001**, que estava pendente desde o começo e é
o gargalo de todos os aceites do superadmin: `last_sign_in_at` nunca foi
preenchido, ou seja, o superadmin da stack nova nunca logou. Enquanto ele não
logar, nenhum dos sete critérios de aceite pode ser executado.

Então a troca não é só reparo. É o passo que destrava a spec.

## Por que eu não faço login, dito uma vez para não voltar ao assunto

Três razões, e a terceira é a que importa:

1. Regra minha, sem exceção: não digito senha em campo de autenticação.
2. Fazer isso transformaria cada aceite manual em algo que ninguém viu
   acontecer. O aceite existe justamente para uma pessoa olhar a tela.
3. A regra (e) da constituição diz que senha de cliente jamais é definida por
   admin. O espírito dela é que credencial pertence a uma pessoa e não circula.
   Colar a senha do superadmin num chat para um agente usar é a mesma ideia
   pelo avesso.

## O que eu ofereço no lugar

O roteiro clicável dos aceites, passo a passo, com o resultado esperado de cada
um, em `specs/003-superadmin-blindado/tasks.md`. Você executa, e onde algo
divergir eu conserto com a evidência na mão.
