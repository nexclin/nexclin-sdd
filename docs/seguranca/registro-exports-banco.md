# Registro de exports do banco — onde estão, sem estarem aqui

> **O arquivo nunca entra neste repositório.** Um export do Lovable/Supabase
> traz paciente, consulta e valor — dado de saúde. Commitado, vaza para todo
> clone, para sempre, e `rm` não tira do histórico. Aqui fica só o **registro**
> de que o export existe: data, nome, hash e onde vive. Isso basta para
> auditoria e não expõe nada.
>
> O `.gitignore` foi endurecido em 20/08/2026 para que um dump solto na árvore
> não seja pego por um `git add -A` distraído (`*.dump`, `*.zip`, `*.tar.gz`,
> `backups/`, `dumps/`…). `supabase/migrations/*.sql` continua versionado por
> desenho — é DDL, é a fonte de verdade do schema, e não contém dado.

## Onde os exports vivem

| Camada | Caminho | Por quê |
|---|---|---|
| Cópia de trabalho | `C:\Users\ahifr\NexClin-Backups\` | Fora do repositório e fora do `Downloads`, onde se perderia entre centenas de arquivos. |
| Cópia durável | pasta privada em nuvem (Drive/OneDrive) | **Obrigatória.** O T004 da SPEC 002 registra: se o Cloud da Lovable for desabilitado, os exports deixam de ser baixáveis. A cópia local passa a ser a única que existe. |

## Como o export funciona na Lovable

**Corrigido em 25/08/2026, pelo Arthur, com o export feito na frente.** As duas
primeiras restrições registradas aqui antes **eram falsas**, e o erro tinha
custo: ele fazia a Fase 2 inteira parecer travada por uma espera que não existe.

- **É síncrono.** `More → Cloud → Overview → Advanced settings → Export project
  data → Export data`, e o arquivo baixa na hora. Não há espera por e-mail.
- **Pode ser repetido quando se quiser.** Não existe limite de um a cada 24
  horas. Se uma janela precisar de dois pontos de retorno no mesmo dia, faça
  dois.
- **Não há recuperação no tempo neste tier.** Esta continua valendo, e é ela que
  sustenta o T004 como gate absoluto: o export é a única rede. O gate segue de
  pé; só deixou de ser caro.

**Cuidado que continua valendo, e agora é o único:** na mesma tela, logo abaixo
do `Export data`, ficam `Pause` (Pause Cloud) e `Remove` (Remove Lovable Cloud,
que apaga a instância em definitivo). Três botões empilhados em cerca de 200
pixels, os dois de baixo em vermelho. Clique com a tela inteira à vista.

## Histórico

| Data | Arquivo | SHA-256 | Motivo | Cópia em nuvem |
|---|---|---|---|---|
| 20/08/2026 | `lovable-export-2026-08-20.zip` | *(preencher com `sha256sum`)* | Gate T004 da SPEC 002 — ponto de retorno antes das escritas da Fase 2 (trilha de auditoria em `patients`) na janela de 22–23/08. | *(confirmar)* |
| **25/08/2026** | `nexclin_260825.backup.zip` | `b56d8d5f9fafd194f17a055bc91dc47619c249f3518590f8615a3176574c873e` | **Gate T004 da SPEC 002 cumprido.** Ponto de retorno antes das escritas da Fase 2 (`data_audit_log`, trigger de auditoria em `patients`, `deleted_at`, policies separadas por operação). | **pendente do Arthur** |

> Ao registrar um export novo, acrescente uma linha — não substitua a anterior.
> Saber que existiam três pontos de retorno, e de quando, é a informação útil
> quando algo dá errado.

## Detalhes do export de 25/08/2026

- **Tamanho:** 795.899 bytes (o zip contém um único arquivo,
  `nexclin_260825.backup`, de 795.759 bytes).
- **Caminho:** `C:\Users\ahifr\NexClin-Backups\nexclin_260825.backup.zip`.
- **Verificação da cópia:** o `sha256` foi calculado na origem e no destino e
  **bateu** antes de o original ser removido. Copiar e conferir, e só então
  apagar, é o que impede que um erro de cópia vire perda do único ponto de
  retorno.
- **Foi baixado dentro da pasta do repositório** (`C:\Users\ahifr\Downloads\
  NexClin\`) e movido de lá. O `.gitignore` já o cobria por `*.zip`, então não
  houve risco de commit; mesmo assim, dump de dado de saúde não fica na árvore
  de trabalho, porque um `git add -f` distraído ou uma pasta sincronizada
  desfazem essa proteção.
- **Falta a cópia em nuvem**, que é obrigatória por este documento. Enquanto ela
  não existir, há **um** ponto de retorno, num disco só.
