# FR-011 e maior do que estava escrito: NENHUMA policy chama `my_permission`

**07/09/2026, vespera do lancamento.** Medido, e nao suposto.

## O que a regra 021 dizia

O FR-011 acusava **quatro** tabelas financeiras, `receivables`, `expenses`,
`revenues` e `fixed_expenses`, de terem policy `FOR ALL TO authenticated` por
`clinic_id` **sem consultar permissao de modulo**.

A acusacao esta certa, e as quatro estao ali, todas com a mesma forma:

```sql
CREATE POLICY "Users can manage receivables in their clinic"
  ON public.receivables FOR ALL TO authenticated
  USING (clinic_id IN (SELECT profiles.clinic_id FROM profiles
                        WHERE profiles.user_id = auth.uid()))
```

## O que a medida mostrou

**O problema nao e das quatro. E das setenta e cinco.**

| Medida | Valor |
|---|---|
| `CREATE POLICY` nas 60 migracoes | **75** |
| policies com `my_permission` dentro do `USING` | **0** |

**Controle positivo, porque isto e afirmacao negativa:** a palavra
`my_permission` aparece em **6** arquivos de migracao, entao a busca alcanca o
texto. A funcao existe, e criada, e recebe `GRANT EXECUTE` para
`authenticated`. O que nao existe e **uma policy que a chame**.

## O que isso significa

O `CLAUDE.md` afirma que *"a cascata de acesso vive em `my_permission(_module)`,
no banco"*. **Ela vive no banco como funcao, e nao como regra aplicada.** Quem
aplica permissao de modulo hoje e o frontend, e a alinea (c) diz o contrario
com todas as letras: *"segurança mora no banco; a tela apenas reflete. Nenhuma
regra de acesso pode existir só no frontend."*

Na pratica: um usuario autenticado de uma clinica alcanca **qualquer tabela da
sua clinica** por chamada direta a API, mesmo com o modulo negado na tela. O
isolamento entre clinicas continua de pe, e isso e o que impede o dano maior:
a ancora `profiles.clinic_id` esta em todas as 75, e o
`prevent_clinic_id_change` a protege.

## Por que nao foi corrigido hoje, e a razao nao e preguica

1. **Reescrever 75 policies na vespera do lancamento** troca uma falha que
   ninguem esta explorando por um risco de derrubar acesso legitimo a dado de
   cliente no primeiro dia. A §2.5 nao pede isso.
2. **O dano nao aparece em 08/09.** Nas clinicas fundadoras, quem opera e a
   dona e a secretaria, com todos os modulos liberados. Permissao parcial e
   cenario de clinica com equipe, que nenhuma tem ainda.
3. **A correcao nao pode ser provada hoje.** Provar exige um segundo usuario
   com modulo negado, e ele nao existe: e a issue #50, e e do Arthur. Sem isso,
   qualquer teste passa sem testar nada, que e a armadilha do teste vazio ja
   registrada.
4. **Ha uma dobra na propria funcao** que precisa de decisao antes: o
   `my_permission` devolve **`'full'` por padrao** quando nao ha `team_members`
   para o usuario, com o comentario "compat retro". Aplicar as policies sem
   mexer nisso nao muda nada para quem nao tem `team_member`, e muda tudo para
   quem tem. Qual dos dois e o certo e decisao de produto.

## O que fica proposto, e depende do Arthur

**Nao e correcao de vespera, e nao e "requisito da stack nova" tambem.** E das
duas coisas, em duas etapas:

**Etapa 1, depois de 08/09 e antes de a primeira clinica ter equipe.** Aplicar
`my_permission` nas policies das **quatro tabelas financeiras**, que sao as que
o FR-011 nomeia e as que guardam dinheiro. Quatro policies, com o segundo
usuario criado antes, e o bloco 4 de `021-censo-financeiro.sql` como prova.

**Etapa 2, na stack nova.** As 75 nascem chamando a cascata, e nao se repete o
padrao de policy que so olha `clinic_id`.

**A regra 021 precisa de emenda no FR-011**, porque ele acusa quatro e o
problema e geral. A emenda fica para quando a decisao acima for tomada, para
nao escrever duas vezes.

## Verificacao, para rodar no editor de SQL

Nao consegui rodar isto no banco ao vivo nesta sessao: o editor da Lovable
parou de aceitar texto colado e a leitura da pagina passou a ser bloqueada. **A
medida acima e das migracoes do repositorio, e nao do banco.** Elas deveriam
coincidir, e "deveriam" nao e prova. O bloco abaixo fecha isso:

```sql
select count(*) filter (where qual like '%my_permission%')  as com_cascata,
       count(*)                                             as policies_no_total
from pg_policies
where schemaname = 'public';
```

**Esperado pela leitura das migracoes:** `com_cascata` igual a **0**. Se vier
diferente de zero, alguem aplicou policy fora do repositorio, e ai este
documento e que precisa de correcao.
