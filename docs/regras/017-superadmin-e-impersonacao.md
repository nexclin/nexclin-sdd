# 017 · Superadmin e impersonação

> **Regra viva.** Nasceu depois da execução, e não antes: os cinco requisitos
> abaixo são a leitura de defeitos encontrados em produção em 28/08/2026, ao
> povoar uma clínica de teste e operar o painel como o Arthur opera.
>
> **Estado em 29/08/2026:** FR-001, FR-002 e FR-003 corrigidos e **provados na
> tela**. FR-004 corrigido, aguardando publicação. **FR-005 continua aberto**, e
> depende de decisão do Arthur, na seção 7.
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
  **Ainda aberto**, e depende da decisão da seção 7.

---

## 3. O que muda no banco

`20260828040000` cria `superadmin_contagens_da_clinica(uuid)`, que devolve seis
inteiros e exige `is_superadmin` na primeira linha, antes de olhar tabela
nenhuma. `SECURITY DEFINER` ignora RLS, então sem essa guarda qualquer usuário
autenticado contaria a base de qualquer clínica.

O FR-005, quando decidido, exige tabela própria de trilha de leitura.

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
- **FR-005:** sem prova, porque não foi feito.

---

## 7. A decisão que falta

**Uma, e ela destrava o FR-005.** O que exatamente se registra numa leitura de
prontuário durante impersonação?

1. **Cada paciente aberto.** Uma linha por prontuário visto. É o que a exigência
   de saúde pede ao pé da letra, e é a mais cara: a trilha cresce rápido e
   precisa de retenção própria.
2. **Cada tela aberta, sem identificar o paciente.** Registra que o operador
   abriu a lista de pacientes às 14h02, e não quem ele leu. Mais barato, e não
   responde "quem viu o quê".
3. **Só a janela de sessão**, com hora de entrada e de saída, e o que ele podia
   ter visto. É o que já existe hoje, apenas explicitado.

**A primeira é a que atende o requisito.** As outras duas atendem a auditoria
administrativa, que já está atendida.
