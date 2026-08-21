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

## Restrições do export na Lovable

- **Assíncrono.** A tela confirma com "Database export started"; o link chega
  **por e-mail**, depois. Disparar não é ter.
- **1 a cada 24 horas.** Se uma janela de correção precisar de dois pontos de
  retorno no mesmo dia, não haverá — planeje as escritas para caberem em um só,
  ou distribua entre dois dias.
- **Não há recuperação no tempo neste tier.** O export é a única rede. É por
  isso que o T004 é gate absoluto: nenhuma escrita antes dele.

## Histórico

| Data | Arquivo | SHA-256 | Motivo | Cópia em nuvem |
|---|---|---|---|---|
| 20/08/2026 | `lovable-export-2026-08-20.zip` | *(preencher com `sha256sum`)* | Gate T004 da SPEC 002 — ponto de retorno antes das escritas da Fase 2 (trilha de auditoria em `patients`) na janela de 22–23/08. | *(confirmar)* |

> Ao registrar um export novo, acrescente uma linha — não substitua a anterior.
> Saber que existiam três pontos de retorno, e de quando, é a informação útil
> quando algo dá errado.
