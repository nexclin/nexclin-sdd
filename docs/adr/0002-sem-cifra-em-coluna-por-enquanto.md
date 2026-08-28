# 0002 · Nenhuma coluna de dado de saúde é cifrada na aplicação, por enquanto

**Situação:** Proposta, decidida pelo executor em 25/08/2026 sob delegação
**Data:** 25/08/2026
**Decide:** Arthur Hideo. Decidida aqui pela documentação, a pedido dele.
**Reversível, e a reversão é aditiva: ver §Como reverter.**

---

## Contexto

O item 5 da auditoria de segurança (`specs/016-endurecimento-seguranca/spec.md`)
ficou em ⚠️: existe cifra em trânsito (TLS, pela Supabase e pela Vercel) e cifra
em repouso (o disco da Supabase), e **nenhuma coluna é cifrada pela aplicação**.
Zero uso de `pgcrypto` ou `pgsodium`, verificado por varredura nas 55 migrações.

A pergunta é se alguma coluna precisa: CPF, telefone, o texto da anamnese, o
diagnóstico.

## A decisão

**Não.** Nenhuma coluna passa a ser cifrada na aplicação neste momento. A
proteção do dado de saúde continua sendo: RLS por `clinic_id`, cascata de
permissão, trilha de auditoria, TLS em trânsito e cifra em repouso do provedor.

A decisão é **datada e revisável**, não permanente.

## Por que, e o que sustenta

**1. Nenhuma norma levantada exige cifra em coluna.** O `compliance.md` do
projeto OpenClinic, que é o levantamento regulatório mais completo a que o
NexClin tem acesso, lista o que a LGPD exige de um controlador: trilha de
auditoria, controle de acesso, portabilidade, e "medidas técnicas e
administrativas" do art. 46, sem especificar cifra de campo. A certificação SBIS
exige comunicação cifrada (`NGS1.05.01`) e **backup cifrado** (`NGS1.04.03`) —
não cifra de coluna. O `NGS1.06.01` exige que anexo fora do banco tenha sigilo e
nome de arquivo opaco, que é outra coisa e está na SPEC 016 como item 16.

**2. O custo é operacional e cai sobre quem usa o sistema todo dia.** Coluna
cifrada não é buscável nem ordenável. A pesquisa de mercado do projeto registra
que **quem opera o sistema o dia inteiro é a recepção**, e que buscar paciente
por nome ou telefone é a operação mais frequente que existe. Cifrar telefone
significa que a secretária deixa de achar o paciente que está no balcão. O
`prd.md` do OpenClinic diz a mesma coisa com outras palavras: a qualidade do
agendamento decide a adoção do produto, independentemente do resto.

**3. Cifra em coluna protege contra uma ameaça que não é a nossa hoje.** Ela
serve para quando o adversário lê o banco mas não tem a chave: dump vazado,
insider com acesso ao Postgres, backup em mão errada. Das três, a única real
aqui hoje é o **dump**, e ela tem tratamento próprio e mais barato:
`registro-exports-banco.md` exige que o export viva fora do repositório, e o
`.gitignore` foi endurecido para isso. Cifrar coluna para proteger dump é
resolver pela porta cara um problema que já tem porta barata.

**4. Cifra malfeita é pior que ausência.** Chave guardada junto do dado não
protege de nada e dá sensação de proteção. Fazer certo exige decidir custódia de
chave, rotação e recuperação — e o `modulos.md` do OpenClinic lista exatamente
isso como ADR próprio, ainda não escrito, do projeto deles. Entrar nisso agora,
sem norma que obrigue, é gastar a semana errada.

## Consequências assumidas

- **Quem tiver acesso direto ao Postgres lê tudo.** Isso inclui a Supabase como
  operadora e qualquer credencial de service role que vaze. É risco aceito, e a
  mitigação é a custódia da service role, não a cifra.
- **Um dump vazado é legível.** A mitigação é o procedimento de export, que já
  existe e é obrigatório.
- **A decisão fica exposta se a ANPD publicar norma específica.** O
  `compliance.md` registra que "dados pessoais sensíveis — dados de saúde" é
  tema prioritário da Agenda Regulatória da ANPD para 2025–2026 e **está em
  elaboração**. Se a norma sair exigindo cifra de campo, esta decisão vira
  dívida com prazo.

## O que fica marcado para revisar

| Gatilho | O que fazer |
|---|---|
| A ANPD publicar norma específica para dado de saúde | Reabrir este ADR |
| O projeto buscar a certificação SBIS de fato | Conferir `NGS1.11.11` (anonimização) e `NGS1.11.12` (pseudonimização), que são Estágio 2 e 3 e podem ser o caminho melhor que cifra |
| Entrar campo que **não** precisa ser buscável e é altamente sensível | Cifrar só ele. Cifra por campo é aditiva |
| Backup passar a sair do controle da Supabase | `NGS1.04.03` exige backup cifrado |

## Como reverter

Reversão é aditiva e barata: cifrar uma coluna nova, ou uma coluna existente que
não seja usada em busca, não exige desfazer nada deste ADR. Basta escrever o ADR
seguinte com o gatilho que mudou.

O que **não** é barato é cifrar coluna já usada em busca, e é justamente por isso
que esta decisão existe por escrito: para que a escolha seja feita com o custo à
vista, e não por omissão.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| **Cifrar CPF e telefone** | São os dois campos mais buscados pela recepção. Cifrar quebra a operação diária. |
| **Cifrar o texto da anamnese** | É o candidato mais defensável, porque não é buscado. Fica registrado como o **primeiro** a reconsiderar se o gatilho mudar. Não entra agora por não haver norma que obrigue nem ameaça que a cifra resolva melhor que a RLS. |
| **Cifrar tudo** | Inviabiliza busca, relatório e agregação, que são o produto. |
| **Adiar sem registrar** | É o que estava acontecendo. Decisão não escrita vira omissão, e omissão não tem gatilho de revisão. |
