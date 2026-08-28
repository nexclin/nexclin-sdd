# Handoff, 27/08/2026: a reorganização foi executada

> **Para a sessão que vem depois.** A reorganização planejada em
> [`2026-08-27-handoff-reorganizacao.md`](2026-08-27-handoff-reorganizacao.md)
> está **feita, os dez passos**, na branch `trabalho/27-08-reorganizacao`.
> Este documento diz o que mudou, o que quebrou de propósito, e o que continua
> pendente.
>
> **Nenhum arquivo de código foi tocado.** `app/`, `lib/`, `e2e/`, `scripts/` e
> `supabase/` estão exatamente como estavam. `tsc --noEmit` limpo, 225 testes
> passando em 8 arquivos.

---

## A primeira coisa a fazer

**Ler o `CLAUDE.md` novo.** Ele foi de 25 KB para 11 KB, e a §6, que era onde
toda sessão lia "o que fazer agora", **não existe mais**. No lugar dela, a seção
1 manda ler o handoff mais recente de `docs/historico/`, que é este, e as issues
abertas em `nexclin/nexclin-sdd`.

**Se um dia o handoff não for escrito, a sessão seguinte começa mais cega do que
antes.** Esse risco foi assumido de propósito, e está escrito no próprio
`CLAUDE.md`.

---

## O que mudou, em dez commits

| Passo | Commit | O quê |
|---|---|---|
| 1 | `366a411` | `.specify/` apagado, constituição em `docs/constituicao.md`, emendada para v2.0.1 |
| 2 | `93b0f23` | `specs/` vira `docs/regras/`, e a spec vira **regra viva** |
| 3 | `4aa61e9` | 28 issues fechadas, 15 abertas (`#36` a `#50`) |
| 4 | `a32a9e1` | `docs/` de dez pastas por assunto para sete por pergunta |
| 5 | `8bf256c` | raiz limpa: dois HTMLs apagados, quatro arquivos movidos |
| 6 | `0f3ceee` | `CLAUDE.md` de 25 KB para 11 KB |
| 7 | `e2bd4e5` | skills de 43 para 22, e o `to-spec` vira `nx-regra` |
| 8 | `8f730d3` | nasce `.claude/rules/estrutura.md` |
| 9 | `14c8dad` | nasce `CONTEXT.md`, onze termos, 58 linhas |
| 10 | `709f0f8` | links, hook, tipos e testes conferidos |

### As sete pastas, e a pergunta de cada uma

`regras/` o que o sistema deve fazer · `historico/` o que aconteceu · `adr/` por
que é assim · `dominio/` o que as palavras significam · `ponte/` como a correção
chega à plataforma ao vivo · `harness/` como este repositório dirige o Claude
Code · `referencia/` o que existe hoje.

**Todo nome em `historico/` começa com `AAAA-MM-DD`**, e é isso que faz a pasta
se ordenar sozinha. O arquivo mais recente é o estado mais recente.

### Onde as coisas foram parar

A tabela completa de tradução de caminho antigo para novo está na **seção 4 de
[`../README.md`](../README.md)**. Consulte-a antes de concluir que um documento
sumiu.

---

## O que quebrou de propósito, e não tem conserto

**Commits de agosto apontam para caminhos mortos.** Toda mensagem de commit e
todo documento datado que cita `specs/NNN/spec.md` deixou de resolver. Foi custo
aceito na decisão.

**`plan.md` e `tasks.md` de cinco specs foram apagados.** O conteúdo está no
histórico do git, mas deixou de ser navegável. As 19 tarefas em aberto que não
viraram issue agora existem como **parágrafo dentro da regra**, não como item
marcável.

**Comentários de código citam caminhos antigos.** Dez arquivos em `supabase/`,
`lib/`, `app/` e `scripts/` referenciam documentos que mudaram de lugar. Eles
**não foram corrigidos de propósito**: código não se toca nesta reorganização, e
`supabase/migrations` tem ordem cronológica que é contrato com o banco. A seção 4
de `docs/README.md` é a tradução.

**`docs/historico/2026-08-25-mapa-de-execucao.md` está desatualizado**, com aviso
no topo dizendo isso. Ele contava tarefas dentro dos `tasks.md`.

---

## O que ficou pendente desta reorganização

**Nada.** Os dez passos fecharam, e os dois ADRs aprovados foram escritos
(`0004-o-spec-kit-sai.md` e `0005-bifurcar-o-to-spec.md`).

**Uma divergência de contagem, registrada para ninguém tropeçar:** o plano dizia
"43 para 20 skills" e listava **22 nomes** para ficar. Ficaram os 22 nomes da
lista, e saíram 22. A lista era a autoridade; o "20" era o número redondo do
título.

**A branch não foi mesclada.** Ela está em `trabalho/27-08-reorganizacao`, dez
commits à frente de `main`, e o merge é decisão do Arthur.

---

## O que continua correndo, e é trabalho de produto

Está em [`2026-08-27-pendencias.md`](2026-08-27-pendencias.md), que **não foi
alterado por esta reorganização**. As que estão com o Arthur:

- **Publicar na Lovable** o commit `0feb8b0` (o tour não paira sobre o
  formulário, o retorno vai para o topo), e rodar a migração `20260827020000`
  antes.
- **Criar `teste@nexclin.com`** pelo cadastro. A conta vai **limpa** para o amigo
  cuja família tem distribuidora, para avaliar a interface. **Não povoar.**
- Trocar a senha da conta-mestra. Domínio, que destrava o SMTP.
- **Transcrever o segundo vídeo do Erick.** Se houver bateria de bugs lá, ela tem
  precedência sobre tudo.

**A decisão pendente mais antiga: conta mestra definindo usuários da clínica.** O
Arthur quer que a mestra crie e repasse as credenciais, e isso é a regra (e) da
constituição. A alternativa que entrega o mesmo fluxo sem emenda é senha
temporária gerada pelo sistema, com troca obrigatória no primeiro acesso. **Ele
ainda não escolheu, e a regra espera essa escolha.**

---

## As 15 issues abertas, e a ordem entre elas

Milestone [Regra 002](https://github.com/nexclin/nexclin-sdd/milestone/2), doze
issues, e a ordem importa:

```
#39 aplicar a migracao ──▶ #40 app: soft delete ──▶ #41 #42 #43 #44 (aceites)
                                                          └──▶ #45 backport ──▶ #46
#36 provar o formulario ──▶ #37 DECISAO public_token ──▶ #38 (so se aprovado)
#47 Supabase Pro, independente e com data propria: antes de 08/09
```

Milestone SPEC 001, três issues, e as três dependem de atos do Arthur:
**#48** (senha do superadmin) destrava **#49** e **#50**.

**O gate que continua valendo:** o export do banco está feito, mas **falta a
cópia em nuvem**. Enquanto ela não existir há um ponto de retorno, num disco só.

---

## Três coisas que mudaram de hábito, e vão pegar

1. **Estado de execução é issue, nunca arquivo.** Não crie `tasks.md`, nem lista
   de pendências dentro de uma regra. Foi exatamente isso que fez 28 issues
   pararem de ser tocadas.
2. **Mudança que altera comportamento descrito numa regra atualiza a regra no
   mesmo commit.** É a regra (l) do `CLAUDE.md`, e é o que separa regra viva de
   spec que envelheceu calada.
3. **Regra nova só para o que atravessa para outubro.** Front puro não gera
   regra: vira requisito da stack nova, em `docs/regras/000-backlog.md`. Use a
   skill `nx-regra`.
