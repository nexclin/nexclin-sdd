# CONTEXT.md, o vocabulário do NexClin

Glossário, e nada além. Só termo que **já causou confusão real** aqui. Termo que
nunca foi mal-entendido custa token e não evita nada. Teto: 60 linhas.

**Regra viva.** Documento que nasce antes da execução, guia a execução, e é
corrigido no mesmo commit em que a execução o contradiz. Vive em `docs/regras/`.
*Errado:* escrever a regra depois e chamar de documentação. Isso é histórico.

**Atravessar.** Sobreviver à troca da plataforma Lovable pela stack Next.js em
outubro. Banco atravessa; front não. Regra escrita atravessa; tela não.
*Errado:* "isso atravessa porque é importante". Atravessar não é prioridade, é
sobrevivência à migração.

**Faixa A, B e C.** A triagem da §2.5. A muda o que fica **gravado** e corrige-se;
B depende de regra que a stack nova também vai precisar e a regra escrita basta;
C é tela e não se corrige.
*Errado:* classificar relatório como C. Relatório é a exceção nomeada: o cliente
opera por ele, e tem de funcionar em 08/09.

**Âncora.** `profiles.clinic_id`, a coluna que define de qual clínica é o usuário
logado. Toda RLS multi-tenant sai dela.
*Errado:* a aplicação escrever `clinic_id`. Quem escreve é o banco, por default
ou trigger. Aplicação que escolhe a clínica vira a autoridade sobre ela.

**ModuleKey.** Uma das 15 strings do contrato único de módulos. As mesmas em
`plans.enabled_modules`, `team_members.permissions`, guards e menu.
*Errado:* inventar chave para uma tela nova. Chave nova exige emenda à
constituição; tela nova vive sob chave existente.

**Impersonação.** O superadmin entra numa conta de cliente para dar suporte,
trocando a âncora de forma auditada, com banner âmbar em todas as rotas.
*Errado:* chamar de "login como". Não há troca de sessão: é a mesma identidade,
com a âncora deslocada e a entrada e a saída gravadas.

**Ponte.** O caminho pelo qual a correção chega à plataforma ao vivo: commit no
clone `../nexclin-lovable` e Publish. Procedimento em `docs/ponte/`.
*Errado:* chamar de "deploy". O Publish publica o **preview**, não o commit, e
**não** redeploya edge function.

**Recebível.** A parcela a receber de um fechamento, com líquido e vencimento
calculados pelo meio de pagamento. Vive em `receivables`.
*Errado:* tratar como sinônimo de receita. Receita é o que foi vendido;
recebível é uma parcela dela, com data e taxa próprias.

**Repasse.** A parte do valor que vai para o profissional que atendeu, por modelo
e percentual definidos em `team_members`.
*Errado:* somar repasse como despesa da clínica em relatório de resultado sem
dizer que o imposto está fixado em zero, porque hoje ele está.

**Esqueleto da clínica.** O app em `app/app/` com layout, menu e rotas de pé, e
sem módulo de negócio dentro. Foi o que a regra 001 entregou.
*Errado:* chamar de MVP. Ele navega e não opera nada.

**Apontamento.** Um item relatado por sócio testando a plataforma, no formato da
base do Notion. Vira bug ou requisito depois da triagem, nunca antes.
*Errado:* corrigir apontamento antes de triar. Metade não é bug, e parte do que
é bug não atravessa.
