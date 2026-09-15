# 025 · Importação e exportação de dados da clínica

> **Regra viva.** Nasce antes da execução, guia a execução, e é corrigida no
> mesmo commit em que a execução a contradiz.
>
> **Estado em 12/09/2026:** especificada, nada implementado. Alvo: **Lovable e
> stack nova**, pela exceção nomeada no Princípio IV da constituição (2.1.0).
> Importação é faixa **A** inteira: o que entrar errado migra em outubro.
>
> **Lei:** `docs/constituicao.md` · **Contexto:** `CLAUDE.md` ·
> **Origem:** ditado pelo Arthur em 11/09/2026 e interrogado em 4 rodadas.

---

## 1. O problema

Uma clínica que entra no NexClin traz anos de pacientes, leads, consultas e
tarefas numa planilha ou no sistema anterior, e hoje o único jeito de colocá-los
no sistema é digitar um por um. Não existe importação em módulo nenhum: o botão
"Carregar Template" da Anamnese carrega um modelo de formulário por
especialidade, não dados. Exportar só existe nos relatórios, em CSV e XLSX. O
resultado é que a clínica começa vazia, o recall não tem histórico para
calcular, e o dado que a clínica já tinha fica fora do sistema que foi vendido
para gerir a clínica. Do outro lado, exportar paciente é levar dado de saúde
para fora, e hoje ninguém registra quem levou o quê.

## 2. Requisitos

### Importação

- **FR-001** · faixa **A**
  O sistema **MUST** importar **pacientes, leads, consultas e tarefas**, de
  CSV e XLSX, com mapeamento de colunas feito na tela antes de gravar.
  *Porquê:* são as quatro bases que a clínica traz do sistema anterior e as
  que o recall, o funil e a produtividade leem. Mapear na tela é o que permite
  aceitar a planilha de qualquer origem (iClinic, Feegow, Excel solto) sem um
  conversor por concorrente.

- **FR-002** · faixa **A**
  Só o **master** **MUST** importar, e toda importação **MUST** gerar
  auditoria com quem importou, o nome do arquivo e as quatro contagens
  (importadas, completadas, puladas, rejeitadas).
  *Porquê:* alínea (d) da constituição: é ação administrativa sobre dado de
  cliente. Importar errado é o erro que migra, então quem aperta é quem
  responde pela clínica.

- **FR-003** · faixa **A**
  Linha que bate com registro existente por **telefone ou CPF** (comparação
  por dígitos, sem máscara) **MUST** preencher só o que estava vazio no
  registro, e **MUST NOT** sobrescrever campo preenchido.
  *Porquê:* a planilha é o passado; o sistema é o presente. Sobrescrever
  apagaria o que a clínica já corrigiu no NexClin. Pular perderia o dado novo
  da planilha.

- **FR-004** · faixa **A**
  Linha sem campo obrigatório (`business_rules.patient_required_fields` para
  paciente; nome para lead; paciente e data para consulta; título para tarefa)
  **MUST** ser rejeitada e listada no relatório, linha a linha.
  *Porquê:* a regra de obrigatório que vale na tela vale na importação, senão
  a importação vira a porta dos fundos da validação.

- **FR-005** · faixa **A**
  Nome de médico ou de responsável que não casa com membro da equipe **MUST**
  entrar vazio e marcado no relatório; a linha **MUST NOT** ser rejeitada nem
  criar membro.
  *Porquê:* rejeitar perde a consulta; criar membro cria lixo em
  `team_members` a partir de um erro de grafia. O casamento é por nome exato,
  sem acento e sem caixa, com `team_members.name`.

- **FR-006** · faixa **A**
  Lead importado **MAY** trazer coluna de estágio mapeável para os estágios do
  funil; sem ela, entra em "novo". A **cadência** (FR-001 da regra 018)
  **MUST** contar da data da importação, para todo lead importado.
  *Porquê:* a cadência mede quanto tempo a clínica levou para responder dentro
  do NexClin. O passado da planilha não é dívida do sistema novo, e 200 leads
  "vencidos" no primeiro dia matam o funil antes de ele começar.

- **FR-007** · faixa **A**
  Consulta importada **MUST** ser só histórico de agenda: **MUST NOT** gerar
  recebível, fechamento nem repasse.
  *Porquê:* cada consulta com valor gera recebível e repasse pelo meio de
  pagamento, e a planilha não traz esse detalhe. Importar o financeiro do
  passado é outra regra, com conciliação; aqui a consulta entra para o recall
  e para o histórico do paciente.

- **FR-008** · faixa **A**
  O relatório linha a linha da importação **MUST** ser baixado na hora e
  **MUST NOT** ser guardado no banco. Só as contagens ficam, na auditoria.
  *Porquê:* guardar as linhas rejeitadas é guardar dado de paciente fora da
  tabela de paciente, e a minimização do Princípio II proíbe.

### Exportação

- **FR-009** · faixa **A**
  Exportar **MUST** exigir um sinal próprio por membro, `pode_exportar`,
  ligado pelo dono no diálogo de equipe. O perfil operacional **MUST** nascer
  sem ele. Toda exportação **MUST** gerar auditoria: quem, qual base, quantas
  linhas.
  *Porquê:* nível de permissão é escopo de leitura; exportar é ato
  administrativo sobre dado de saúde, e um sinal só, auditado, é o que a
  alínea (d) pede. "Dump e export são dado de saúde", Princípio II.

- **FR-010** · faixa **B**
  O sistema **MUST** exportar pacientes, leads, consultas e tarefas, em CSV e
  XLSX, com o mesmo componente que os relatórios já usam. Financeiro continua
  exportando pelos relatórios, que já auditam pelo mesmo caminho a partir
  desta regra.
  *Porquê:* é a contrapartida da importação e a portabilidade que a LGPD
  exige; e o componente já existe, não se cria um segundo.

- **FR-011** · faixa **A**
  Anamnese **MUST** exportar **por paciente**, e **MUST NOT** exportar em
  lote.
  *Porquê:* o caso de uso é a portabilidade do titular (LGPD, art. 18). Lote
  de anamnese é dump de dado de saúde, e não tem quem peça.

## 3. O que muda no banco

| Objeto | Mudança |
|---|---|
| `data_audit_log.action` | o `CHECK` passa a aceitar `IMPORT` e `EXPORT` além de `INSERT`, `UPDATE`, `DELETE`. **Achado da leitura:** hoje o `CHECK` recusa qualquer outro valor e `record_id` é `NOT NULL`; uma importação não tem `record_id` único, então `record_id` recebe o id do lote (uuid gerado na hora) e `previous_state` guarda `{arquivo, base, importadas, completadas, puladas, rejeitadas}`. Exportação grava `{base, linhas}` |
| `team_members.pode_exportar` | `boolean NOT NULL DEFAULT false`. Só o master edita (a policy de `team_members` já impede membro de mudar a própria permissão, migração de 25/08) |
| RPC `importar_lote(base, linhas jsonb)` | função `SECURITY DEFINER` que aplica FR-003, FR-004, FR-005 e FR-007 **no banco**, devolve as contagens e a lista de rejeitadas, e grava a auditoria na mesma transação. Recusa quem não é master. **Porquê no banco e não no front:** alínea (c), segurança mora no banco; e uma importação de 2.000 linhas pelo cliente, uma a uma, cai no meio e deixa metade |
| `patients`, `leads`, `appointments`, `tasks` | **nada de coluna**. A origem "importação" de lead entra em `origins` da clínica se não existir, como dado, e não como coluna |
| `appointments` importadas | usam `responsible_member_id` e `doctor_member_id` da regra 024 quando o nome casa (FR-005); `sold_value` e `closing_*` ficam zerados (FR-007) |
| `leads` importados | `created_at` é a data da importação (FR-006), e o `lead_history` recebe uma linha `import` com o estágio mapeado, para a cadência ter de onde contar |

## 4. Premissas

- A comparação de telefone e CPF é por dígitos: `(11) 99999-0000` e
  `11999990000` são a mesma pessoa. Telefone vazio dos dois lados **não** casa
  ninguém.
- O mapeamento de colunas é feito uma vez por arquivo, na tela, e não é
  guardado. Se a clínica importar três arquivos do mesmo sistema, mapeia três
  vezes. Guardar mapeamento é melhoria, não requisito.
- Tamanho: a planilha inteira sobe em uma chamada de RPC. Arquivo acima de
  5.000 linhas é dividido em lotes pela tela, cada lote com a própria linha
  de auditoria, e o relatório final soma. O número sai do limite prático de
  payload do PostgREST, não de medição; medir na primeira clínica real.
- `business_rules.patient_required_fields` existe e tem `["name"]` como
  padrão desde a migração de 24/03.

## 5. Dependências

- **Antes:** regra 024, pelas colunas `responsible_member_id` e
  `doctor_member_id` (FR-005 desta) e pelo tipo `recall_paciente`, que a
  tarefa importada pode trazer.
- **Antes:** o `DELETE` de tarefa já removido (FR-009 da 024): importação
  errada de tarefa se corrige cancelando, e não apagando.
- **Não depende do FR-011 da regra 021:** a RPC checa master por conta
  própria, e a auditoria é por linha, não por módulo.
- **Depende desta:** a implantação das clínicas fundadoras. Cezar Essence e
  Claros Clinic começam vazias enquanto isto não existe.

## 6. Como se prova que funciona

1. Master importa 50 pacientes de uma planilha com máscara de telefone
   variada: 50 importados; reimporta o mesmo arquivo: 0 importados, 50
   pulados; muda um e-mail vazio na planilha e reimporta: 1 completado, e o
   campo já preenchido no sistema não muda.
2. Linha sem nome: rejeitada, aparece no relatório baixado com o motivo. O
   relatório não está em tabela nenhuma.
3. Consulta com médico "Dr. Joao" quando o membro se chama "Dr. João": casa
   (sem acento, sem caixa). Com "Dr. Joaquim": entra vazia e marcada.
4. Consulta importada com valor na planilha: `sold_value` zero, nenhum
   recebível criado. **Este é o item de aceite financeiro, e não fecha sem
   print.**
5. Lead importado com estágio "Agendou" e data de 2025: entra em "agendou" e a
   cadência conta de hoje; não aparece como vencido no funil.
6. Maria (operacional) não vê o botão de importar; pela API, a RPC recusa.
7. Maria sem `pode_exportar` não vê exportar; dono liga o sinal; Maria exporta
   pacientes e `data_audit_log` tem a linha `EXPORT` com 50 linhas e o nome
   dela.
8. Anamnese: exporta de dentro do paciente; não existe botão na lista.
9. Duas clínicas: importação de uma não aparece na outra. **Exige o segundo
   usuário da issue #50.**
10. Automatizado, na Lovable, em `src/lib/importacao.ts`: mapear colunas;
    decidir por linha (importa, completa, pula, rejeita) a partir do registro
    existente e dos obrigatórios; normalizar telefone e CPF; casar nome com
    membro; mapear estágio; produzir as quatro contagens e o relatório. **O
    que não cobre:** a RPC, o `CHECK` da auditoria, o componente de
    exportação e a tela.

## 7. A decisão que falta, e precisa do Arthur

**Nenhuma.** Fechadas em 11/09 e 12/09 (grilling, rodadas 1 a 5): as quatro
bases importam de uma vez; conflito preenche só o vazio; obrigatório rejeita;
nome que não casa entra vazio; estágio mapeável e cadência da importação;
consulta importada sem recebível; relatório baixado e não guardado; exportar
por sinal auditado; anamnese por paciente. Fora desta versão: importar
financeiro do passado (recebíveis e contas), guardar mapeamento por origem,
importar respostas de anamnese.
