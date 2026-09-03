# Registro técnico do NexClin, 23/07 a 03/09/2026

> Documento **neutro**. Registra o que mudou, quando, e por quê, sem argumentar
> valor. Serve para qualquer sócio auditar, e é a base de prova dos outros dois
> documentos desta data.
>
> Todo número aqui sai do `git log` e do banco de produção, e é reproduzível.

---

## 1. O ponto de partida

O sistema existia desde **01/01/2025** e foi construído inteiramente pelo chat
da plataforma Lovable. O histórico registra:

| Período | Commits | Autoria |
|---|---|---|
| 01/01/2025 a 22/07/2026 | **1211** | 1210 do bot `gpt-engineer-app`, 1 da própria Lovable |

**Zero commits humanos diretos.** Nenhuma pessoa abriu o código para conferir,
testar ou corrigir. Não havia testes automatizados, regra de negócio escrita,
documentação de decisão, nem auditoria.

Isso não é crítica ao trabalho anterior: é a descrição de um sistema **gerado**,
que nunca foi **verificado**.

---

## 2. O que existe hoje e não existia em 23/07

| Artefato | Quantidade | O que é |
|---|---|---|
| Repositório de especificação | **198 commits** | arquitetura, regras, migrações e histórico |
| Regras vivas | **13 arquivos** | o que o sistema deve fazer, e por quê |
| ADRs | **6** | decisões caras de reverter, com as alternativas recusadas |
| Migrações de banco | **39 novas** | RLS, trilhas de auditoria, travas de integridade |
| Testes automatizados | **233** | eram zero |
| Handoffs | **52** | o histórico auditável de cada sessão |
| Constituição | 1 | regras inegociáveis, com hooks que as aplicam sozinhos |
| Procedimento de ponte | 27 arquivos | como a correção chega à produção sem consumir crédito |

---

## 3. Defeitos encontrados e corrigidos

O sistema era considerado próximo de pronto. A verificação encontrou:

| Quando | Origem | Achados |
|---|---|---|
| 17 a 21/08 | bateria de teste do Vinícius | **33 apontamentos** |
| 23/08 | auditoria dos 33 | 24 corrigidos |
| 25/08 | verificação da bateria | **18 itens** de correção |
| 27/08 | vídeo do Erick | zero bugs, 5 pedidos de funcionalidade |
| 31/08 | relatório do Vinícius | **8 itens**, 3 de faixa A envolvendo dinheiro |
| 02 e 03/09 | verificação em tela e varredura | **7 defeitos**, nenhum relatado antes |

**Mais de sessenta defeitos**, nenhum deles visível abrindo o sistema.

### Os cinco mais graves, e o que cada um fazia

**1. "Substituir lançamento" apagava dinheiro recebido.** O diálogo oferecia
substituir um lançamento existente, e o caminho rodava `DELETE` nos recebíveis
da consulta, **inclusive no da entrada já paga**. O dinheiro saía do contas a
receber, do fluxo de caixa e de todo relatório, sem rastro. O Vinícius previu o
estrago antes de ver o código.

**2. Parcelas de cartão entravam todas no caixa de hoje.** Marcar "já foi
recebido" numa venda em 3x punha as três parcelas como pagas na data de hoje. O
caixa do dia ficava inflado com dinheiro que a clínica só recebe em noventa
dias.

**3. A cortina do tutorial trancava a conta.** Um `div` preto cobrindo a tela
inteira permanecia depois que o tour perdia o alvo, sem cartão e sem botão de
saída. Nenhum clique passava. Medido ao vivo: `elementFromPoint` no centro dos
botões devolvia a cortina.

**4. A agenda escondia o que ela mesma gravava.** O filtro nascia em "este mês" e
o dia era extraído em UTC. Consulta marcada para o mês seguinte, ou após as 21h,
sumia da lista, enquanto a trava de conflito acusava choque de horário sobre ela.

**5. Oito clínicas não conseguiam agendar.** O cadastro de serviço exigia apenas
o nome, e a macro categoria podia ficar vazia. Serviço sem macro não aparece no
seletor de tipo de consulta **e** faz a receita cair no balde de vendas por
ausência.

---

## 4. O padrão que se repetiu cinco vezes

Cinco defeitos diferentes tinham a mesma forma: **um conserto correto aplicado a
uma tela e não às irmãs.**

1. a regra de senha valia no cadastro público e não no provisionamento;
2. o dia brasileiro valia no filtro de período e não na tela de Consultas;
3. `exibeDataLocal` valia em Contas a Pagar e não em Contas a Receber;
4. `instanteLocal` valia em Consultas e não em Tarefas;
5. `stopPropagation` valia num botão e não no checkbox ao lado.

Por isso seis dos testes novos são **guardas de fonte**: eles leem o código e
exigem que toda tela da mesma família use a mesma função. Defeito de "qual
função a tela escolheu chamar" não é detectado por teste de função.

---

## 5. Verificações contra o banco de produção

| O que foi medido | Resultado |
|---|---|
| planos com `enabled_modules` em formato errado | **nenhum.** Os 4 estão corretos |
| clínicas sem assinatura | **nenhuma.** 22 de 22 têm |
| recebíveis de consulta classificados como venda | **nenhum.** Consulta voltou vazia |
| clínicas que não conseguem agendar | **8 de 22** |
| guarda de gestão de operadores | provada nos 4 critérios, com controle positivo |

---

## 6. O que continua aberto

**Não provado em tela:** os três consertos financeiros estão publicados e
cobertos por 18 testes, sem confirmação com dado real.

**Escrito e não aplicado:** duas migrações, uma delas a que faz clínica nova
nascer com tipos de consulta e categorias de despesa.

**Especificado e não implementado:** a regra 020 dos avisos internos, as duas
lacunas de LGPD da regra 019, e a anamnese por especialidade.

**Conhecido e aceito:** o celular não ficou adequado e foi retirado da prioridade
por decisão consciente.

**Dívida estrutural:** `receivables` é escrita por seis caminhos diferentes, e é
assim que o mesmo fato entra em formatos distintos. Não se conserta na plataforma
atual, e é o que a stack nova precisa nascer sem.

---

## 7. Dois erros deste registro, anotados de propósito

Documento que só conta acerto não serve para auditar nada.

**Meio dia de trabalho foi para um arquivo que o aplicativo não serve.** O
relato falava da "tela de consultas", e o conserto foi para `pages/Consultas.tsx`,
que **não é roteado**. A tela real é `Acompanhamento.tsx`. Só apareceu porque a
conferência de bundle provou que o código novo estava no ar com o defeito
intacto. O backlog já registrava aquele arquivo como órfão, e não foi lido antes.

**Um alarme falso quase foi reportado.** A leitura pela API indicava "21 de 22
clínicas sem tipo de consulta". O número vinha do RLS escondendo as outras
clínicas, e não de elas estarem vazias. Foi corrigido antes de sair, e a medição
correta veio do editor de SQL, onde não há RLS.
