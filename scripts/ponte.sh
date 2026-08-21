#!/usr/bin/env bash
# Ponte inversa GitHub -> Lovable. Procedimento em docs/ponte/ponte-inversa.md
#
# Automatiza tudo que nao exige navegador. O Publish nao tem CLI: o script para
# nele, avisa, e depois prova que o deploy saiu comparando o bundle publicado.
set -uo pipefail

REPO="nexclin/nexclin"
CLONE="${PONTE_CLONE:-$HOME/Downloads/nexclin-lovable}"
SITE="https://nexclin.lovable.app"
PROJETO="https://lovable.dev/projects/09bc3d2d-df13-4ce3-a41f-6aa1606a75df"
ESTADO="$CLONE/.ponte-bundle"

bundle_publicado() {
  curl -s --max-time 20 "$SITE/" | grep -o '/assets/index-[A-Za-z0-9_-]*\.js' | head -1
}

case "${1:-}" in

  preparar)
    if [ ! -d "$CLONE/.git" ]; then
      echo "clonando $REPO em $CLONE"
      gh repo clone "$REPO" "$CLONE" || exit 1
    fi
    cd "$CLONE" || exit 1
    # O proprio .ponte-bundle e estado deste script, nao codigo da plataforma.
    # Sem isto o 'git add -A' do 'enviar' o commitaria em producao.
    # Residuos das nossas proprias ferramentas nao podem vazar para producao
    # pelo `git add -A` do 'enviar'. .ponte-bundle e estado deste script;
    # supabase/.temp/ e cache do CLI do Supabase.
    for lixo in '.ponte-bundle' 'supabase/.temp/'; do
      grep -qxF "$lixo" .git/info/exclude 2>/dev/null         || echo "$lixo" >> .git/info/exclude
    done
    echo "== atualizando (o bot da Lovable tambem commita em main) =="
    git checkout -q main && git pull --ff-only origin main || {
      echo "!! pull falhou. Resolva antes de editar."; exit 1; }
    B=$(bundle_publicado)
    echo "$B" > "$ESTADO"
    echo
    echo "clone   : $CLONE"
    echo "branch  : $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"
    echo "no ar   : $B"
    echo
    echo "Pronto. Edite no clone. So bug, conserto minimo."
    ;;

  enviar)
    MSG="${2:-}"
    [ -z "$MSG" ] && { echo "uso: ponte.sh enviar \"fix: mensagem\""; exit 1; }
    cd "$CLONE" || { echo "rode 'preparar' antes"; exit 1; }

    # GATE DE TIPOS — nao e opcional, e nao e o `npm run build`.
    #
    # Em 20/08/2026 uma varredura minha gerou `new dataLocal(Date())` em 17
    # lugares. O `npm run build` passou verde: vite usa esbuild, que REMOVE
    # tipos sem checa-los. O codigo foi publicado e derrubou o app inteiro por
    # ~1h35 — imports sao estaticos, e o erro estourava na avaliacao do modulo.
    #
    # Cuidado: `tsc -p tsconfig.json` nao serve. O projeto usa `references` com
    # `"files": []`, entao esse comando checa ZERO arquivos e responde verde.
    # O config que realmente checa e o tsconfig.app.json.
    echo "== checando tipos (o build NAO faz isso) =="
    if [ -f tsconfig.app.json ]; then
      if ! npx --no-install tsc --noEmit -p tsconfig.app.json; then
        echo
        echo "!! TIPOS QUEBRADOS. Nada foi enviado."
        echo "   Corrija antes. O build passar nao prova nada aqui."
        exit 1
      fi
      echo "   ok, zero erros"
    else
      echo "   !! tsconfig.app.json nao encontrado — gate PULADO, confira a mao"
    fi

    git diff --stat
    [ -z "$(git status --porcelain)" ] && { echo "nada para enviar"; exit 1; }
    git add -A && git commit -q -m "$MSG" && git push -q origin main || {
      echo "!! push falhou. Rode 'preparar' para atualizar e tente de novo."; exit 1; }
    echo
    echo "enviado: $(git rev-parse --short HEAD)  $MSG"
    echo
    echo "=============================================================="
    echo " AGORA O PASSO MANUAL — nao existe CLI para isto"
    echo "=============================================================="
    echo " 1. Anote o credito ANTES (nome do projeto > Credits N left)"
    echo " 2. Abra  $PROJETO"
    echo " 3. Confirme a entrada 'Pushed from GitHub' com o seu diff"
    echo " 4. Publish > Update   (ate ler 'Up to date')"
    echo " 5. Anote o credito DEPOIS — tem de ser o mesmo N"
    echo
    echo " Depois rode:  bash scripts/ponte.sh conferir"
    ;;

  conferir)
    ANTES=$(cat "$ESTADO" 2>/dev/null || echo "")
    [ -z "$ANTES" ] && { echo "sem referencia; rode 'preparar' antes do proximo envio"; exit 1; }
    echo "bundle antes do deploy: $ANTES"
    echo "observando o site publicado (ate 10 min)..."
    for i in $(seq 1 40); do
      AGORA=$(bundle_publicado)
      if [ -n "$AGORA" ] && [ "$AGORA" != "$ANTES" ]; then
        echo "$(date -u +%H:%M:%S) UTC  novo bundle: $AGORA"
        echo
        echo ">>> PUBLICADO. O deploy saiu."
        echo "$AGORA" > "$ESTADO"
        exit 0
      fi
      printf "."
      sleep 15
    done
    echo
    echo ">>> 10 minutos sem mudanca no bundle."
    echo "    Quase sempre significa que o Publish > Update nao foi clicado."
    exit 1
    ;;

  *)
    echo "Ponte inversa GitHub -> Lovable"
    echo "  bash scripts/ponte.sh preparar              clona/atualiza e marca o que esta no ar"
    echo "  bash scripts/ponte.sh enviar \"fix: msg\"     commita, envia e lembra do Publish"
    echo "  bash scripts/ponte.sh conferir              prova que o deploy saiu"
    echo
    echo "Procedimento completo: docs/ponte/ponte-inversa.md"
    ;;
esac
