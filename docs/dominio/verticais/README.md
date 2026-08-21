# Verticais — o que é, quando abre, como se define

## A tese antes dos nichos

O NexClin é um **ERP de clínica pequena com o financeiro completo**. Essa é a
lacuna real: os prontuários consolidados (iClinic, HiDoctor) têm contas a
receber e param aí. Vender contra eles pela lista de funções é perder — eles
entregam prontuário, prescrição e assinatura por R$ 99 por médico. Vender
contra a planilha e o WhatsApp, pelo controle do dinheiro e da captação, é
ganhar.

Um vertical só existe se **reforça** essa tese dentro de um nicho. Se ele nos
obriga a virar prontuário especializado, é armadilha, não oportunidade.

## O que é um vertical aqui

Não é fork, não é tema, não é módulo novo. Um vertical é um **pacote de
configuração** sobre o mesmo núcleo de 15 módulos:

| Camada | O que muda por vertical | Onde vive |
|---|---|---|
| Vocabulário | "paciente" vs "cliente", "consulta" vs "sessão" | i18n do vertical |
| Catálogos | serviços, objeções, canais, plano de contas padrão | seed do vertical |
| Campos obrigatórios | `patient_required_fields`, `appointment_required_fields` | configuração da clínica |
| Regras temporais | confirmação, anamnese, satisfação | `business_rules` |
| Relatórios em destaque | quais aparecem primeiro | configuração |
| **Tabela nova** | **quase nunca** | exige spec própria e reabre a discussão |

A régua: se serve por configuração, é vertical. Se exige tabela e tela
próprias, **pare** — isso é um produto novo disfarçado de campo a mais, e o
custo real aparece na manutenção, não na primeira entrega.

## Portões de abertura

Estado em agosto de 2026, conforme a pesquisa de mercado:

| Vertical | Estado | Portão para abrir |
|---|---|---|
| [Médico](medico.md) | **ativo** | — |
| [Psicologia](psicologia.md) | próximo | depois dos 10 primeiros clientes médicos |
| [Estética](estetica.md) | teste | 1 ou 2 clínicas no grupo fundador |
| [Odontologia](odontologia.md) | **fechado** | caixa para bancar odontograma |

Portão fechado não se contorna com exceção pontual. Foi assim que produtos
com tese clara viraram genéricos.

## A observação que vale mais que a tabela

> O adjacente mais barato de atacar é aquele que a consultoria do sócio já
> atende. Antes de escolher por TAM, vale perguntar o que existe na carteira.
> Um segmento com 20 mil clínicas e três clientes quentes vale mais, nos
> primeiros 12 meses, que um com 125 mil e nenhum.

Ou seja: **a carteira do Vinícius decide a ordem**, não o tamanho de mercado.
Se ele tiver três clínicas de estética prontas para entrar, estética passa na
frente de psicologia mesmo com TAM menor.

## Conflito registrado

O `CLAUDE.md` do repositório descreve o produto como sendo para "clínicas
médicas e odontológicas". A pesquisa de mercado recomenda **ignorar
odontologia** até haver caixa para um vertical dedicado. As duas fontes se
contradizem; esta pasta segue a pesquisa. Quando a decisão for tomada em
definitivo, atualize o `CLAUDE.md` — texto de posicionamento desatualizado vira
promessa que alguém tenta cumprir.
