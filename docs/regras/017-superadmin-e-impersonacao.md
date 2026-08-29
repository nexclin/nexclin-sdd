# 017 · Superadmin e impersonação

> **Regra viva.** Nasceu depois da execução, e não antes: os cinco requisitos
> abaixo são a leitura de defeitos encontrados em produção em 28/08/2026, ao
> povoar uma clínica de teste e operar o painel como o Arthur opera.
>
> **Estado em 29/08/2026, noite:** FR-001, FR-002 e FR-003 corrigidos e
> **provados na tela**. FR-004 corrigido e publicado. **FR-005 saiu de aberto
> para especificado**: as quatro decisões que faltavam foram tomadas pelo Arthur
> nesta data e estão na seção 7. A implementação é a próxima entrega, e é o
> único item desta regra com prazo legal.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Validação de mercado:**
> [`2026-08-28-validacao-superadmin-mercado.md`](../historico/2026-08-28-validacao-superadmin-mercado.md)

---

## 1. O problema

O painel de superadmin é por onde a conta mestra opera as dezoito clínicas.
Nunca tinha sido exercitado com base cheia. Quando foi, em 28/08/2026, três
defeitos apareceram no mesmo dia, e os três compartilham uma forma: **a tela não
falhava, ela informava errado.**

Erro visível se investiga. Zero silencioso, tela branca sem mensagem e
porcentagem impossível são lidos como fato.

---

## 2. Requisitos

### Informar certo, ou não informar

- **FR-001**: Tela de superadmin **MUST NOT** exibir número que o RLS possa ter
  zerado sem erro. Contagem sobre dado de outra clínica **MUST** vir de função
  com `SECURITY DEFINER` que verifique `is_superadmin` por dentro.

  *Porquê:* o painel "Uso do Sistema" mostrava seis zeros numa clínica com 180
  pacientes e 420 consultas. A consulta estava certa; a policy de `patients`
  concede a linha cuja clínica bate com a do perfil de quem pergunta, e o
  superadmin está ancorado na própria. O banco devolvia zero, sem erro, numa
  tela feita para decidir sobre a conta do cliente. Corrigido em
  `20260828040000`.

- **FR-002**: A função de contagem **MUST** devolver número, e **MUST NOT**
  devolver linha. *Porquê:* a saída óbvia seria conceder `SELECT` de superadmin
  nas tabelas operacionais, e isso abriria leitura de dado de paciente de todas
  as clínicas para entregar seis números. Dado de saúde é sensível pela LGPD, e
  a maior lacuna já registrada deste painel é não haver trilha de leitura de
  dado clínico. É minimização: entregar o que a tela precisa e nada além.

### Não quebrar no caminho do suporte

- **FR-003**: Componente sob guarda de permissão **MUST** ter todos os hooks
  antes de qualquer saída antecipada.

  *Porquê:* `Dashboard.tsx` tinha `if (permLoading) return null` entre um
  `useState` e outro. Na primeira passada o React registrava poucos hooks;
  quando a permissão resolvia, o corpo inteiro rodava e apareciam dezenas a
  mais. React error #310, e **tela branca**. Disparava com mais frequência na
  impersonação, porque é o caminho em que a permissão demora um ciclo a mais,
  já que a clínica muda no meio.

  **Isto já estava escrito** em `.claude/rules/app.md`, na lista de dívidas da
  referência, descrito como "quebra intermitentemente". Não era intermitente:
  era determinístico, e ninguém tinha achado o gatilho.

- **FR-004**: O encerramento da impersonação **MUST** estar alcançável de fora
  do app da clínica.

  *Porquê:* o controle de sair vivia só dentro do app impersonado. Quando esse
  app quebrou pelo FR-003, não havia saída: a área de superadmin continuava
  funcionando e não oferecia nenhum botão de encerrar, e sobrava sair da conta
  inteira.

  **Corrigido em 29/08/2026**, e a correção é uma linha: o `ImpersonationBanner`
  passou a ser renderizado também no `SuperAdminLayout`. É o **mesmo
  componente**, e não uma cópia. Ele lê a sessão ativa e chama `exitClinic` por
  conta própria, então não renderiza nada quando não há impersonação. Duplicar a
  lógica criaria duas verdades sobre o mesmo estado, e uma delas envelheceria.

  **A lição é maior que o conserto:** o defeito não estava no banner, que sempre
  funcionou. Estava em ele existir num lugar só, e esse lugar ser justamente o
  que pode quebrar. Saída de emergência dentro da sala que pega fogo não é
  saída.

### Registrar quem viu o quê

- **FR-005**: Toda leitura de dado de paciente durante impersonação **MUST**
  ser registrada, com operador, clínica, paciente e horário.

  *Porquê:* a exigência de mercado para software de saúde é "quem viu o quê,
  quando". Hoje `superadmin_audit_log` registra **ação administrativa**, que é o
  que a regra (d) da constituição pede, e a impersonação registra a **entrada**.
  Nenhum dos dois registra o que foi visto lá dentro. Um operador abre duzentos
  prontuários e a trilha guarda uma linha dizendo que ele entrou.
  **Especificado em 29/08/2026.** As quatro decisões estão na seção 7, e o que
  elas produzem são os quatro sub-requisitos abaixo.

- **FR-005a, a tabela.** A trilha **MUST** viver em `patient_access_log`, e ela
  **MUST** ser somente-anexação: sem policy de `UPDATE` e sem policy de
  `DELETE`, para ninguém, inclusive superadmin. Pela regra (b) da constituição,
  o que não é concedido é negado, então a ausência de policy É a proibição.

  A tabela **MUST NOT** ter chave estrangeira para `patients`. Isto é
  deliberado e contra-intuitivo: com `ON DELETE CASCADE`, apagar um paciente
  apagaria junto a prova de que alguém o leu, que é exatamente ao contrário do
  que uma trilha serve. Ela guarda `patient_id` como uuid solto, e guarda
  `operator_email` desnormalizado pela mesma razão, para sobreviver ao operador
  ser desativado.

  Ela **MUST** amarrar cada leitura à **sessão de impersonação**, e não só ao
  operador. `superadmin_impersonation_sessions` já tem `id`, então a pergunta
  "o que foi visto naquele atendimento de suporte" passa a ter resposta, em vez
  de só "o que aquela pessoa já viu algum dia".

- **FR-005b, quem escreve.** A escrita **MUST** ser feita por RPC
  `SECURITY DEFINER`, e **MUST NOT** existir policy de `INSERT` para
  `authenticated`. Cliente não escreve na trilha direto: se escrevesse, poderia
  forjar linha.

  O RPC **MUST** resolver a sessão ativa por `auth.uid()`, e **MUST** recusar
  silenciosamente quando não houver impersonação, porque o escopo decidido é
  esse. E **MUST** conferir que o paciente pertence à clínica da sessão, senão
  um operador poderia gravar leitura de paciente de outra clínica e sujar a
  trilha de quem não foi lido.

- **FR-005c, o gancho.** A tela de prontuário **MUST** chamar o RPC ao abrir.
  Vale o prontuário, e **não** a lista de pacientes: a lista mostra nome, o
  prontuário mostra dado clínico, e registrar cada render de lista afogaria a
  trilha no que não importa.

- **FR-005d, retenção.** A política **MUST** estar escrita, e nada apaga
  automaticamente antes de 08/09. O risco até o lançamento é registrar de
  menos, e não guardar demais.

  **A limitação honesta, e ela vai escrita porque será perguntada numa
  auditoria:** com o gancho na tela, um cliente adulterado consegue ler sem
  gravar. O desenho que fecha isso é o prontuário deixar de ser `SELECT` direto
  e passar a vir de um RPC que devolve o dado E grava a linha, e ele é
  **requisito da stack nova**. Na Lovable fica o gancho, porque aquelas telas
  são descartadas em outubro. A trilha prova acesso legítimo; ela não defende
  de operador mal-intencionado com o navegador aberto.

---

## 3. O que muda no banco

`20260828040000` cria `superadmin_contagens_da_clinica(uuid)`, que devolve seis
inteiros e exige `is_superadmin` na primeira linha, antes de olhar tabela
nenhuma. `SECURITY DEFINER` ignora RLS, então sem essa guarda qualquer usuário
autenticado contaria a base de qualquer clínica.

O FR-005 exige uma migração própria, e ela é **faixa A**: cria
`patient_access_log` com RLS, e o RPC `registrar_leitura_de_paciente(uuid)`.

O RLS dela tem uma assimetria de propósito. **Superadmin lê tudo**, porque é
quem audita. **A clínica lê só as linhas dela**, e isso não é generosidade: é
a resposta à pergunta que o titular do dado tem direito de fazer, que é quem da
plataforma abriu o prontuário do paciente dela. Ninguém atualiza e ninguém
apaga.

---

## 4. Premissas

O painel de superadmin vive num endereço separado, com guarda, login e tabela de
operadores próprios, e quatro papéis. **É mais restritivo que o padrão de
mercado**, em que a conta mestra costuma ser a mesma conta com tudo liberado, e
a escolha é deliberada: uma falha de permissão numa conta única vazaria dado de
todas as clínicas.

Essa decisão está implementada e não estava escrita. Se for para fechá-la, o
lugar é um ADR, não esta regra.

---

## 5. Dependências

O FR-005 depende de a impersonação continuar sendo o caminho de suporte. Se um
dia o suporte deixar de entrar na conta, a trilha de leitura muda de forma.

---

## 6. Como se prova que funciona

- **FR-001 e FR-002:** abrir o detalhe de uma clínica com base povoada e ver as
  seis contagens com número. Provado na Clínica Teste Final, com 180 pacientes.
- **FR-003:** entrar numa clínica pela impersonação e o app renderizar. Provado
  em 28/08: antes ficava em branco com React #310, depois abriu o dashboard.
- **FR-004:** entrar numa clínica, ir para `/superadmin` e ver o banner com o
  botão de encerrar. Aguardando publicação: **código lido, não comportamento
  provado**, pela regra (j).
- **FR-005:** ainda sem prova, porque não foi implementado. Os critérios de
  aceite, quando for:
  1. entrar numa clínica por impersonação, abrir um prontuário, e a linha
     aparecer com operador, clínica, paciente, sessão e horário;
  2. abrir o **mesmo** prontuário duas vezes e sair **duas** linhas, porque a
     decisão foi registrar cada abertura;
  3. abrir prontuário **fora** de impersonação e **nenhuma** linha ser gravada;
  4. tentar `INSERT`, `UPDATE` e `DELETE` diretos na tabela como usuário
     autenticado, e os três serem negados;
  5. um admin de clínica ver as linhas da própria clínica, e **não** ver as de
     outra.

---

## 7. As decisões, tomadas em 29/08/2026

**O que se registra numa leitura de prontuário durante impersonação?**
**Cada paciente aberto**, uma linha por prontuário visto. As outras duas opções
que estavam na mesa, registrar a tela sem identificar o paciente e registrar só
a janela da sessão, atendem auditoria administrativa, que já está atendida por
`superadmin_audit_log`. Nenhuma das duas responde "quem viu o quê", que é a
pergunta do requisito.

**A trilha cobre quem?** **Só impersonação.** É o que esta regra sempre disse,
e a razão de não ampliar agora é de risco, não de preguiça: o operador da
plataforma lendo prontuário de clínica que não é dele é exposição de outra
ordem que a equipe da clínica lendo os próprios pacientes. Ampliar para a
equipe **fica como requisito da stack nova**, e não como dívida solta.

**Como a leitura chega na trilha?** **A tela chama o RPC ao abrir.** O desenho
mais forte, em que o prontuário só é lido através do RPC, mexeria em telas que
serão reescritas em outubro. A limitação está escrita no FR-005d, de propósito,
porque limitação que só existe na cabeça de quem construiu não sobrevive à
primeira troca de pessoa.

**Qual retenção?** **A política escrita, sem expurgo automático.** A coluna e o
job de limpeza nascem quando houver o que limpar. Antes de 08/09 o risco é a
trilha não registrar, e não a trilha crescer.

---

## 8. O que esta regra NÃO decide

O prazo de retenção em número de anos. A prática do setor para log de acesso a
dado de saúde é longa, e nenhuma norma brasileira fixa um número para log de
acesso. Escrever "cinco anos" aqui seria inventar precisão que não existe, e
número inventado numa regra vira número citado numa auditoria.

**Fica como decisão aberta, e ela não bloqueia a implementação:** a tabela nasce
sem coluna de expiração, e acrescentar coluna anulável depois é barato. O que
seria caro é o contrário, apagar cedo demais.
