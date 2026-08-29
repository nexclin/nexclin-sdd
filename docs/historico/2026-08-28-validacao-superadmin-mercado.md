# Validação do painel de superadmin contra o mercado

**28/08/2026.** Pedido do Arthur: *"pesquise e valide na internet as
funcionalidades ideais pra existir em uma conta de superadmin, e verificar se a
nossa conta da NexClin dentro do seu nicho compõe tudo que é preciso. Não só por
estar pronto, mas eu quero ver se o que a gente tem hoje se adapta bem ao
mercado."*

**Método.** Duas frentes de pesquisa, o padrão genérico de painel administrativo
de SaaS multi-inquilino e as exigências específicas de software de saúde no
Brasil, comparadas contra o inventário real das doze telas, lido no código e nas
migrações, e não suposto. Fontes no fim.

---

## 1. O veredito, antes do detalhe

**O painel está acima do padrão de mercado no que é operação de SaaS, e abaixo
do exigido no que é dado de saúde.** As duas conclusões são igualmente
importantes e apontam para lados opostos do trabalho.

Ele tem MRR, ARR, churn, ARPU, inadimplência, gestão de planos, cupons,
faturamento, comunicação, métricas, trilha de auditoria com `old → new`, quatro
papéis de operador e impersonação registrada. Isso cobre, e em alguns pontos
excede, a lista que a pesquisa devolve como padrão para 2026.

O que falta é quase todo do recorte de saúde, e boa parte é obrigação legal, não
diferencial competitivo.

---

## 2. O que existe hoje, verificado no código

| Tela | O que faz | Padrão de mercado |
|---|---|---|
| Dashboard | MRR, ARR, contas ativas, trial, churn, ARPU, inadimplentes | atende |
| Contas e detalhe | administração de inquilino, linha do tempo, ações de plano | atende |
| Planos | planos e `enabled_modules`, que é bandeira de recurso por plano | atende |
| Cupons | desconto | atende |
| Faturamento | cobranças, com auditoria | atende |
| Métricas | uso agregado | **quebrado**, ver seção 4 |
| Comunicação | mensagem para a base | atende |
| Logs | `superadmin_audit_log` | atende |
| Operadores | quatro papéis, `super_owner`, `admin`, `suporte`, `financeiro` | atende |
| Configurações | `saas_settings` | atende |

**Dois pontos em que o produto está acima do padrão.** A trilha de auditoria
guarda `previous_state`, `new_state`, `reason` e `ip_address`, o que é mais do
que a maioria dos painéis registra. E a impersonação com registro é recurso que
muitos SaaS não têm, e que aqui é o caminho normal de suporte.

---

## 3. As lacunas do nicho, que é onde o produto fica devendo

Ordenadas por consequência, e não por esforço.

### 3.1 Não há trilha de LEITURA de dado clínico

A exigência de mercado para software de saúde é explícita: *"a trilha de
auditoria mostra quem viu o quê, quando"*. O `superadmin_audit_log` registra
**ação administrativa**, que é o que a regra (d) da constituição pede, e a
impersonação registra a **entrada** na conta.

Nenhum dos dois registra **o que foi visto lá dentro**. Um operador entra numa
clínica, abre prontuário de duzentos pacientes e sai, e a trilha guarda uma
linha dizendo que ele entrou.

Para dado comum isso seria aceitável. Para dado de saúde, que a LGPD classifica
como sensível, é a lacuna mais séria do painel.

### 3.2 Não há tela para pedido do titular

A LGPD dá ao titular direito de acesso, portabilidade e eliminação. Não existe
tela para atender isso: nem para localizar todo dado de um paciente, nem para
exportá-lo, nem para eliminá-lo com registro.

Hoje um pedido desses vira consulta SQL escrita à mão por quem tiver acesso ao
banco. Isso não é fluxo, é improviso, e improviso não se audita.

### 3.3 Não há política de retenção e eliminação

Nenhuma tela define por quanto tempo o dado fica, nem executa descarte. O banco
cresce para sempre, e a LGPD pede o contrário.

### 3.4 Os papéis existem mas não limitam

O enum tem quatro papéis. O que não achei foi o ponto onde `suporte` é impedido
de cancelar conta, ou `financeiro` de impersonar. Se a distinção existe só como
rótulo, o painel tem quatro nomes e um nível de acesso, e o benefício de
segurança do RBAC não se realiza.

**Isto é verificação pendente, não acusação:** não li todas as guardas.

---

## 4. Um defeito achado durante a validação

**As contagens de uso vêm zeradas.** Na Clínica Teste Final, com 180 pacientes e
420 consultas no banco, o painel "Uso do Sistema" mostra seis zeros.

A consulta está certa. O RLS é que filtra: **não existe policy de superadmin em
`patients`, `appointments`, `leads`, `tasks` nem `receivables`**, então o
superadmin só conta o que é da própria clínica dele.

A tela não falha, ela mente. Erro de permissão seria visível; zero silencioso se
lê como "esta clínica não usa o sistema", e é numa tela feita para decidir sobre
a conta do cliente.

**Duas saídas, e elas diferem em risco:** dar `SELECT` de superadmin nas
tabelas, o que abre prontuário de todas as clínicas para a conta mestra, ou uma
RPC `SECURITY DEFINER` que devolve só as contagens. A segunda entrega o que a
tela precisa e nada além, e é a recomendada. A primeira agrava exatamente a
lacuna 3.1.

---

## 5. O que eu faria, nesta ordem

1. **A RPC de contagens.** Conserta o defeito da seção 4 sem abrir dado de
   paciente. Pequena, e destrava uma tela que hoje informa errado.
2. **Trilha de leitura durante impersonação.** Registrar qual paciente foi
   aberto, com operador, clínica e horário. É a lacuna do nicho.
3. **Verificar se os quatro papéis limitam de fato.** Barato de checar, e muda a
   avaliação de segurança do painel.
4. **Tela de pedido do titular.** Acesso, portabilidade e eliminação, com
   registro. É obrigação legal, e hoje é improviso.
5. **Retenção.** A menos urgente das cinco, e a que ninguém lembra até precisar.

**O que eu não faria agora:** paleta de comandos, internacionalização, bandeira
de recurso por clínica. A pesquisa os cita como padrão de 2026, e nenhum resolve
problema que o NexClin tenha hoje.

---

## Fontes

- [How to Build an Admin Panel for a SaaS Product, Sequenzy](https://www.sequenzy.com/blog/how-to-build-saas-admin-panel)
- [What Is an Admin Panel in Modern SaaS, Flatlogic](https://flatlogic.com/blog/what-is-an-admin-panel-in-modern-saas/)
- [SaaS Architecture Explained 2026, VASUYASHII](https://www.vasuyashii.com/blog/saas-architecture-explained)
- [LGPD para Clínicas Médicas, Conclínica](https://conclinica.com.br/lgpd-para-clinicas-medicas/)
- [Compliance para Saúde: LGPD, HIPAA, CFM, ANVISA, Vantico](https://vantico.com.br/compliance-para-saude/)
- [LGPD na Saúde, Portal Telemedicina](https://portaltelemedicina.com.br/lgpd-na-saude-como-garantir-a-seguranca-de-dados-dos-pacientes)
- [LGPD em Clínicas Médicas e o software, ByDoctor](https://bydoctor.com.br/blog/lgpd-software-clinica-medica-o-que-e-como-impacta)
