#!/usr/bin/env node
/**
 * Guarda da Ponte — hook PreToolUse sobre Bash.
 *
 * Mesmo princípio do guarda-constituicao: cada regra aqui existe porque a falha
 * JÁ aconteceu. Nada especulativo.
 *
 * A IDEIA veio de `git-guardrails-claude-code`, de Matt Pocock (MIT). O ARQUIVO
 * dele não serve aqui: ele bloqueia `git push`, e `git push` é exatamente como
 * este projeto entrega correção ao cliente (a ponte inversa). Copiar aquela
 * lista quebraria o mecanismo de entrega. O que se aproveita é a forma, um hook
 * que recusa antes de executar; o conteúdo é a falha deste projeto.
 *
 *  1. `git add -A` e `git add .`
 *     O pacote `@lovable.dev/mcp-js` tem um gerador que reescreve
 *     `supabase/functions/mcp/index.ts` no `npm install` e no `vite build`,
 *     reduzindo o arquivo de 239 linhas para 2. Aconteceu em 26/08 e de novo em
 *     27/08. Nas duas vezes só não foi para o commit porque alguém olhou o
 *     `git status` antes. Adicionar por caminho torna a sorte desnecessária.
 *
 *  2. `git checkout .` e `git restore .`
 *     Descartam trabalho não commitado de toda a árvore sem dizer o que
 *     descartaram. Restaurar por caminho tem o mesmo efeito e é reversível de
 *     cabeça.
 *
 *  3. `git commit -a`
 *     É `git add -A` com outro nome.
 *
 * `git push --force` também entra, porque `docs/ponte/ponte-inversa.md` diz
 * "nunca --force" e o repositório da plataforma é compartilhado com o editor
 * da Lovable: reescrever a história ali descarta o que o editor publicou.
 *
 * Contrato: lê o JSON do hook no stdin, escreve JSON no stdout.
 * Silencioso quando passa.
 */

import { readFileSync } from 'node:fs';

const REGRAS = [
  {
    padrao: /\bgit\s+add\s+(-A\b|--all\b|\.(?:\s|$))/,
    motivo:
      '`git add -A` e `git add .` são proibidos neste projeto. O gerador do ' +
      '`@lovable.dev/mcp-js` reescreve `supabase/functions/mcp/index.ts` de 239 ' +
      'linhas para 2 no `npm install` e no `vite build`, e isso já aconteceu ' +
      'duas vezes (26 e 27/08). Adicione por caminho: `git add src/arquivo.tsx`.',
  },
  {
    padrao: /\bgit\s+commit\s+(-[a-zA-Z]*a[a-zA-Z]*\b|--all\b)/,
    motivo:
      '`git commit -a` é `git add -A` com outro nome, e cai na mesma armadilha ' +
      'do gerador do MCP. Faça `git add` por caminho e depois `git commit`.',
  },
  {
    padrao: /\bgit\s+(checkout|restore)\s+\.(?:\s|$)/,
    motivo:
      'Descartar a árvore inteira apaga trabalho sem dizer o que apagou. ' +
      'Restaure por caminho: `git checkout -- caminho/do/arquivo`.',
  },
  {
    padrao: /\bgit\s+push\b[^\n]*(--force\b|(?<![\w-])-f(?![\w-]))/,
    motivo:
      '`--force` é proibido pela ponte inversa (`docs/ponte/ponte-inversa.md`). ' +
      'O repositório da plataforma é compartilhado com o editor da Lovable: ' +
      'reescrever a história descarta o que foi publicado por lá.',
  },
];

let entrada;
try {
  entrada = JSON.parse(readFileSync(0, 'utf8'));
} catch {
  process.exit(0);
}

const comando = entrada?.tool_input?.command;
if (typeof comando !== 'string' || comando.length === 0) process.exit(0);

/**
 * Remove o corpo dos heredocs antes de procurar comando perigoso.
 *
 * Encontrado pelo próprio guarda, no primeiro uso: ele recusou o commit que o
 * instalava, porque a MENSAGEM do commit citava `git add -A` ao explicar por
 * que ele é proibido. Texto dentro de heredoc é dado, não comando, e um guarda
 * que confunde os dois torna impossível escrever sobre a regra que ele aplica.
 */
function semHeredocs(cmd) {
  return cmd.replace(
    /<<-?\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\1[\s\S]*?^\s*\2\s*$/gm,
    '<<HEREDOC-REMOVIDO',
  );
}

const alvo = semHeredocs(comando);
const achado = REGRAS.find((r) => r.padrao.test(alvo));
if (!achado) process.exit(0);

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    permissionDecision: 'deny',
    permissionDecisionReason:
      `Guarda da Ponte recusou o comando:\n\n  ${comando}\n\n${achado.motivo}\n\n` +
      `Se a regra é que está errada, emende o guarda em ` +
      `.claude/hooks/guarda-ponte.mjs, não contorne o comando.`,
  },
  systemMessage: '⛔ Guarda da Ponte bloqueou um comando git perigoso',
}));
