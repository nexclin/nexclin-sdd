# O que não deu para provar, 06/09/2026

Fecha as issues #74 (regra 021) e #100 (entrega 1 da regra 022), e completa
#59 e #79 com a parte que ainda falta.

**A alínea (j) da constituição existe por isto:** "implementado ≠ funciona".
Quando não deu para provar o comportamento na tela, o registro diz literalmente
*código lido, não comportamento provado*, e o item continua aberto. Nada aqui é
arredondado para cima.

## Regra 021, financeiro que não erra o caixa

### Provado, e como

| O que | Prova |
|---|---|
| O bloco `b1` aplica sem tocar em linha existente | O Arthur rodou em 06/09. `intactas` igual a `linhas`: 604 em `receivables`, 157 em `expenses`, e zero baixas gravadas |
| As seis colunas novas existem com o tipo certo | Bloco de conferência, com controle positivo que procura coluna inexistente |
| O SQL da ponte passa no guarda da constituição | Rodado em 06/09 nos três arquivos. Controle positivo confirmou que o guarda **reprova** RLS ausente e `USING (true)` no mesmo caminho |
| `FR-004` já estava atendido no banco | `opening_balance` e `opening_date` existem desde `20260427222514`. **A regra afirmava o contrário e foi corrigida** |

### Código lido, não comportamento provado

- **A baixa em duas etapas nas duas telas** (`#66`, `#67`). O portão de tipo
  passa e o diff foi lido. **Ninguém deu baixa numa tela real.** As provas são
  as issues #71 e #72, e são do Arthur.
- **`valorDeCaixa` preferindo `settled_value`.** A cadeia foi lida e o
  fallback preserva toda linha antiga, que é nula na coluna nova. **Nenhuma
  baixa nova existe ainda**, então a preferência nunca foi exercitada com dado.
- **O aviso de divergência** entre valor recebido e líquido calculado. É um
  `if` sobre dois números, lido, nunca visto na tela.

### Não provado, e não é por falta de esforço

- **A divergência de `revenues` contra `receivables`**, e as 28 linhas. Os
  blocos 3, 3b e 3c do censo não foram rodados. Sem eles, o portão 1 (#60), que
  decide o destino de `revenues`, continua sem base.
- **`FR-011`, as políticas que não chamam `my_permission`.** Lido nas migrações
  de 22/03: `receivables`, `expenses`, `revenues` e `fixed_expenses` têm
  política `FOR ALL TO authenticated` por `clinic_id` e **nenhuma consulta
  permissão de módulo**. Isso viola a alínea (c). **Não foi provado em execução**
  porque exige um segundo usuário, que não existe (ver #50).
- **`initialBalance` do Saldo do Período** ignora todo movimento anterior ao
  período. Achado por leitura em 06/09, não corrigido, porque muda número que o
  Arthur já olha e a decisão é dele.

## Regra 022, motor de rotina, entrega 1

### Provado

| O que | Prova |
|---|---|
| O selo de prazo pisca, com contraste e peso | Renderizado num Chromium com o CSS de produção, animação congelada em duas fases. `animationName` responde `nx-selo-atrasada`, `fontWeight` 700, texto branco, fundos diferentes nas duas fases |
| Só três telas exibem responsável | Busca em todo `src`. São Tarefas, o painel de alertas do dashboard e Consultas, e as três têm foto |

### Código lido, não comportamento provado

- **A foto do responsável.** A cadeia `team_members.name` para
  `team_members.user_id` para `profiles.avatar_url` foi lida e corrigida depois
  de eu ter casado contra a tabela errada. **Na tela do Arthur ela cai nas
  iniciais**, e o censo parcial de 06/09 explica por quê: `responsible` guarda
  **setor** ("Comercial", "Financeiro"), não pessoa. Não é bug de código, é o
  dado, e é o que o FR-005 existe para encerrar.
- **A contagem regressiva com segundo.** O relógio de um segundo liga quando
  existe tarefa dentro de doze horas. Lido, nunca cronometrado na tela.

### Não provado

- **Quantos valores de `responsible` não casam com membro, e quantas tarefas
  estão neles.** É o bloco 1 do censo de tarefas, não rodado. **É o número que
  destrava a fase 1 inteira da 022**, porque decide se a conversão é segura.
- **A cascata de permissão em `tasks`.** Mesmo bloqueio do FR-011: falta o
  segundo usuário.

## O padrão que estes dois registros mostram

Das oito coisas não provadas, **cinco esperam a mesma causa**: não existe um
segundo usuário na clínica, e dois blocos de censo não foram rodados. Nenhuma
delas espera código.

**A issue #50, convidar um segundo usuário, é a mais barata da fila e destrava
mais coisa que qualquer outra.**
