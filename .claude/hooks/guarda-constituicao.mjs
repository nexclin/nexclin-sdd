#!/usr/bin/env node
/**
 * Guarda da Constituição — hook PostToolUse.
 *
 * Cada checagem aqui existe porque a falha JÁ aconteceu neste projeto.
 * Não adicione regra especulativa: se não houve incidente, não entra.
 *
 *  1. RLS ausente     — Princípio I. Tabela com clinic_id sem RLS vaza dado
 *                       entre clínicas. Foi a brecha crítica do MVP.
 *  2. Policy aberta    — `USING (true)` anula o isolamento sem parecer errado.
 *  3. Senha definida   — Princípio II. O audit log do Lovable tem uma linha
 *                       `password set` (28/07/2026). A action foi removida no
 *                       porte; este guarda impede que volte.
 *  4. Segredo no código— Princípio V. Chave em arquivo versionado é vazamento
 *                       permanente: fica no histórico do git.
 *
 * Contrato: lê o JSON do hook no stdin, escreve JSON no stdout.
 * Silencioso quando passa (ruído constante treina o operador a ignorar).
 */

import { readFileSync } from 'node:fs';

const RAIZ_MIGRACOES = /supabase[/\\]migrations[/\\].+\.sql$/i;
const RAIZ_FUNCOES = /supabase[/\\]functions[/\\]/i;
const CODIGO = /\.(ts|tsx|js|mjs|sql)$/i;

/** Tabelas globais: existem fora do escopo de uma clínica, RLS não se aplica. */
const TABELAS_GLOBAIS = new Set([
  'clinics', 'plans', 'coupons', 'saas_settings',
  'superadmin_operators', 'user_roles', 'schema_migrations',
]);

function lerStdin() {
  try {
    return JSON.parse(readFileSync(0, 'utf8'));
  } catch {
    return null;
  }
}

/** Princípios I e II — o que o banco precisa garantir sozinho. */
function checarMigracao(sql) {
  const achados = [];
  const semComentarios = sql.replace(/--[^\n]*/g, ' ');

  const criadas = [...semComentarios.matchAll(
    /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?["']?(\w+)["']?([\s\S]*?);/gi,
  )];

  for (const [, tabela, corpo] of criadas) {
    if (TABELAS_GLOBAIS.has(tabela.toLowerCase())) continue;
    if (!/clinic_id/i.test(corpo)) continue;

    const habilitaRls = new RegExp(
      `alter\\s+table\\s+(?:public\\.)?["']?${tabela}["']?\\s+enable\\s+row\\s+level\\s+security`,
      'i',
    );
    if (!habilitaRls.test(semComentarios)) {
      achados.push(
        `Tabela \`${tabela}\` tem \`clinic_id\` mas a migração não habilita RLS. ` +
        `Princípio I da constituição: RLS em TODA tabela com clinic_id, sem exceção. ` +
        `Acrescente: ALTER TABLE ${tabela} ENABLE ROW LEVEL SECURITY;`,
      );
    }
  }

  // Exceção deliberada: `-- guarda:permitido <motivo>` na linha anterior à policy.
  // O motivo fica no diff e no blame — exceção sem justificativa não passa.
  const dispensadas = new Set(
    [...sql.matchAll(/--\s*guarda:permitido[^\n]*\n\s*create\s+policy\s+["']?([^"'\n]+?)["']?\s+on/gi)]
      .map(([, nome]) => nome.trim().toLowerCase()),
  );

  const abertas = [...semComentarios.matchAll(
    /create\s+policy\s+["']?([^"'\n]+?)["']?\s+on\s+(?:public\.)?["']?(\w+)["']?([\s\S]{0,400}?)using\s*\(\s*true\s*\)/gi,
  )];
  for (const [, politica, tabela, meio] of abertas) {
    if (dispensadas.has(politica.trim().toLowerCase())) continue;

    if (/\bto\s+anon\b/i.test(meio)) {
      achados.push(
        `Policy \`${politica}\` concede ao papel **anon** um \`USING (true)\` sobre ` +
        `\`${tabela}\` — qualquer pessoa não autenticada que descubra um id lê a linha, ` +
        `de qualquer clínica. Se \`${tabela}\` guarda dado de saúde, isto é exposição ` +
        `de dado sensível por URL adivinhável (LGPD, art. 11). Restrinja por token de ` +
        `uso único com expiração, ou passe o acesso por edge function com service role. ` +
        `Se for exceção consciente, escreva \`-- guarda:permitido <motivo>\` na linha ` +
        `acima da policy.`,
      );
      continue;
    }

    achados.push(
      `Policy \`${politica}\` usa \`USING (true)\` em \`${tabela}\` — libera a tabela ` +
      `inteira e anula o isolamento multi-tenant. Default deny (Princípio I): filtre por ` +
      `clinic_id ou use get_my_clinic_id(). Tabela global de propósito? Adicione-a a ` +
      `TABELAS_GLOBAIS neste guarda. Exceção pontual? \`-- guarda:permitido <motivo>\`.`,
    );
  }

  return achados;
}

/** Remove comentários para que menções em prosa não virem falso positivo. */
function semComentariosTs(src) {
  return src.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/^\s*\/\/[^\n]*/gm, ' ');
}

/**
 * Os únicos arquivos onde definir senha é permitido, pela emenda de 28/08/2026
 * à Seção II da constituição.
 *
 * A emenda liberou UM caminho, o do superadmin provisionando clínica nova, e
 * manteve todo o resto proibido. A lista é curta de propósito: foi um caminho
 * lateral que produziu a violação original, o `invite-team-user` criando o
 * usuário já com senha, e uma liberação ampla reabriria exatamente aquela
 * porta. Arquivo novo aqui exige nova emenda.
 */
const ONDE_SENHA_E_PERMITIDA = [
  /supabase[\\/]functions[\\/]superadmin-manage-user[\\/]/i,
  /supabase[\\/]functions[\\/]superadmin-provisionar-clinica[\\/]/i,
];

/**
 * Princípio II, com a emenda de 28/08/2026: só o superadmin define senha, e só
 * ao provisionar clínica nova. Admin de clínica sobre outro usuário continua
 * proibido, e é esse o risco que a regra sempre quis impedir.
 */
function checarSenha(bruto, caminho = '') {
  if (ONDE_SENHA_E_PERMITIDA.some((p) => p.test(caminho))) return [];
  const conteudo = semComentariosTs(bruto);
  const achados = [];
  const suspeitos = [
    /set_password/i,
    /updateUserById\s*\([^)]*\bpassword\b/is,
    /admin\.updateUser[^)]*\bpassword\s*:/is,
    // Criar já com senha é a mesma violação por outra porta: quem convida
    // escolhe a senha de quem é convidado. Passou despercebido pelo hook e
    // foi para produção no `invite-team-user` (T014 da SPEC 001), corrigido
    // no T017. A catraca fecha aqui para não repetir.
    /admin\.createUser\s*\([^)]*\bpassword\b/is,
  ];
  for (const padrao of suspeitos) {
    if (padrao.test(conteudo)) {
      achados.push(
        `Caminho que DEFINE senha detectado (\`${padrao.source.slice(0, 40)}…\`), ` +
        `e este arquivo não é um dos onde a emenda de 28/08/2026 permite. ` +
        `Princípio II, emendado: só o SUPERADMIN define senha, e só ao ` +
        `provisionar clínica nova, com auditoria. Admin ou membro de clínica ` +
        `nunca define senha de outro usuário, e para esses a via continua sendo ` +
        `resetPasswordForEmail. Se este caminho é mesmo de provisionamento pelo ` +
        `superadmin, o arquivo precisa entrar em ONDE_SENHA_E_PERMITIDA, e isso ` +
        `é decisão consciente, não conveniência: foi um caminho lateral, o ` +
        `invite-team-user criando usuário já com senha, que produziu a violação ` +
        `original.`,
      );
      break;
    }
  }
  return achados;
}

/** Princípio V — segredo versionado fica no histórico para sempre. */
function checarSegredo(conteudo) {
  const achados = [];
  const padroes = [
    [/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\./, 'JWT literal (service_role key?)'],
    [/sb_secret_[A-Za-z0-9_-]{10,}/, 'chave secreta do Supabase'],
    [/re_[A-Za-z0-9]{20,}/, 'API key do Resend'],
    [/(service_role|SUPABASE_SERVICE_ROLE_KEY)\s*[:=]\s*["'][A-Za-z0-9._-]{20,}["']/, 'service role hardcoded'],
  ];
  for (const [padrao, rotulo] of padroes) {
    if (padrao.test(conteudo)) {
      achados.push(
        `Possível ${rotulo} escrito no arquivo. Princípio V: segredo vive só em ` +
        `.env.local, fora do git. Se já foi commitado, rotacione a chave — remover ` +
        `do arquivo não a tira do histórico.`,
      );
    }
  }
  return achados;
}

const entrada = lerStdin();
const caminho = entrada?.tool_input?.file_path ?? entrada?.tool_response?.filePath ?? '';
if (!caminho || !CODIGO.test(caminho)) process.exit(0);

let conteudo;
try {
  conteudo = readFileSync(caminho, 'utf8');
} catch {
  process.exit(0);
}

const achados = [];
if (RAIZ_MIGRACOES.test(caminho)) achados.push(...checarMigracao(conteudo));
if (RAIZ_MIGRACOES.test(caminho) || RAIZ_FUNCOES.test(caminho)) achados.push(...checarSenha(conteudo, caminho));
achados.push(...checarSegredo(conteudo));

if (achados.length === 0) process.exit(0);

const relatorio = achados.map((a, i) => `${i + 1}. ${a}`).join('\n');
process.stdout.write(JSON.stringify({
  decision: 'block',
  reason:
    `Guarda da Constituição bloqueou ${caminho}:\n\n${relatorio}\n\n` +
    `Corrija antes de seguir. A constituição está em docs/constituicao.md. ` +
    `Se a regra é que está errada, emende a constituição primeiro, não o guarda.`,
  systemMessage: `⛔ Guarda da Constituição: ${achados.length} violação(ões) em ${caminho.split(/[/\\]/).pop()}`,
}));
