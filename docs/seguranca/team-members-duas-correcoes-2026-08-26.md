# Duas correções para o mesmo furo em `team_members`, e uma brecha na que está no ar

> 26/08/2026. Conferido no código das duas, não suposto.

## O que existe

O furo de autoconcessão em `team_members` (registro em
`autoconcessao-team-members-2026-08-25.md`) recebeu **duas** correções
independentes:

| Origem | Onde está | Estado |
|---|---|---|
| Minha, `20260825100000` | repositório, e colada no banco da Lovable | aplicada |
| Do bot da Lovable, `20260826021707` | repositório da plataforma | aplicada lá |

A segunda veio de `gpt-engineer-app[bot]`, autor de 20 commits novos no
`nexclin/nexclin`. O Arthur diz que não usa o agente da Lovable e que só commita
pela ponte inversa. A conta da plataforma é a **"Erick's Lovable"**, o que torna
o Erick a explicação mais provável. **Isso precisa ser confirmado com ele antes
de qualquer conclusão**, porque muda quem responde por aquele código.

## A correção do bot é boa, e faz mais que a minha em uma coisa

Ela cria `can_manage_team()` e separa a policy única em quatro, por operação.
Isso é mais completo que o meu trigger: eu deixei os GRANTs e a policy como
estavam, de propósito, para não quebrar a tela de Equipe na semana do
lançamento.

E o trigger `prevent_team_self_escalation` bloqueia mudança de `role`,
`permission_level`, `permissions`, `active`, `user_id` e `clinic_id`. Cobre mais
colunas que o meu na parte de permissão.

## E ela tem duas brechas que a minha fecha

### 1. Repasse continua livre

O trigger dela lista seis colunas, e **nenhuma é de dinheiro**:

```
role, permission_level, permissions, active, user_id, clinic_id
```

Ficam de fora `repasse_percent`, `modelo_repasse`, `calcula_sobre` e
`valor_fixo_sublocacao`. Ou seja: **um profissional ainda pode aumentar o
próprio percentual de repasse.** É metade do achado original, e é a metade que
é dinheiro saindo da clínica.

O meu trigger cobre isso com uma regra diferente, e a diferença é intencional:
repasse só muda por `admin`, e a condição é o **papel**, não a linha. Quem
define quanto a clínica repassa é quem responde pela clínica.

### 2. Quem pode gerenciar a equipe se promove sozinho

O trigger dela começa assim:

```sql
IF auth.uid() IS NULL OR public.can_manage_team() THEN
  RETURN NEW;
END IF;
```

E `can_manage_team()` devolve `true` para `permission_level IN ('master',
'gerencial')`.

Logo, **um usuário `gerencial` sai do trigger antes de qualquer checagem, e pode
alterar a própria linha para `master`.** A anti-escalada não vale para quem já
tem um degrau de gestão, que é exatamente o perfil que teria motivo para subir.

O meu trigger não abre essa exceção: *ninguém* muda a própria permissão, nem o
admin. Para o admin isso não custa nada, porque `has_role(uid,'admin')` já
devolve `full` antes de a permissão individual ser consultada.

## O que fazer, e não é escolher uma das duas

**As duas convivem sem conflito.** São triggers com nomes diferentes na mesma
tabela, e o Postgres executa ambas; a mais restritiva ganha, que é o
comportamento desejado. A policy granular do bot é melhor que a policy única que
eu preservei.

Então a recomendação é: **manter as duas na Lovable**, e portar a policy
granular dela para o repositório, numa migração que junte o melhor dos dois
lados.

O que **não** se deve fazer é remover a minha por parecer redundante. Ela é a
única que trata repasse, e é a única sem a exceção do `gerencial`.

## A pergunta que fica aberta, e é maior que este arquivo

Vinte commits entraram no repositório da plataforma por fora da ponte inversa,
incluindo um endpoint MCP novo que expõe pacientes, consultas e resumo
financeiro por OAuth (`supabase/functions/mcp/index.ts`, mais
`src/pages/OAuthConsent.tsx`).

O endpoint usa o token do usuário e `get_my_clinic_id()`, então a RLS continua
valendo, e o desenho está certo nesse ponto. Mas é **uma superfície externa nova
num sistema com dado de saúde, a treze dias do lançamento**, e ela não passou por
revisão nem por spec.

Isso não é decisão técnica. É de sociedade: quem pode publicar no repositório da
plataforma, e sob qual procedimento. Entra na pauta do grupo, não numa migração.
