#!/usr/bin/env bash
# Confere um merge de catch-up: o que o humano digitou durante a resolucao, e o
# que do lado de cima pode ter se perdido. Uso:
#
#   .claude/skills/merge-downstream/conferir_merge.sh [commit-de-merge] [ref-de-cima]
#
# Sem argumentos, confere o HEAD contra a main.
set -u

MERGE="${1:-HEAD}"
UPSTREAM="${2:-main}"

if ! git rev-parse -q --verify "$MERGE^2" >/dev/null; then
  echo "erro: $MERGE nao e um commit de merge" >&2
  exit 1
fi

P1=$(git rev-parse "$MERGE^1")
P2=$(git rev-parse "$MERGE^2")

echo "### commit"
git log -1 --format='%h  %an  %ad%n%s' --date=iso "$MERGE"
echo "  pai 1 (ramo):    $(git log -1 --format='%h %s' "$P1")"
echo "  pai 2 (de cima): $(git log -1 --format='%h %s' "$P2")"

echo
echo "### o pai 2 e mesmo o topo de $UPSTREAM?"
if [ "$P2" = "$(git rev-parse "$UPSTREAM")" ]; then
  echo "  sim, e o topo atual"
else
  echo "  nao. $UPSTREAM esta em $(git rev-parse --short "$UPSTREAM")."
  echo "  faltam $(git rev-list --count "$MERGE".."$UPSTREAM") commits."
  echo "  (nem sempre e defeito: o merge pode ser antigo. 'git reflog show $UPSTREAM'"
  echo "   diz o que a ref apontava em cada momento.)"
fi

echo
echo "### houve intervencao manual na resolucao?"
# Reconstroi o merge automatico e compara com a arvore que ficou gravada. O que
# sobrar do diff foi digitado por alguem -- resolucao de conflito ou nao.
AUTO=$(git merge-tree --write-tree "$P1" "$P2" 2>/dev/null | head -1)
if [ -z "$AUTO" ]; then
  echo "  nao deu para reconstruir (merge-tree falhou)"
elif [ "$AUTO" = "$(git rev-parse "$MERGE^{tree}")" ]; then
  echo "  nao: a arvore gravada e identica a do merge automatico"
else
  echo "  sim, nestes arquivos:"
  git diff --numstat "$AUTO" "$MERGE^{tree}" | sed 's/^/    /'
  echo "  (ver o teor: git diff $AUTO $MERGE^{tree} -- <arquivo>)"
fi

echo
echo "### o ramo contem tudo o que esta em $UPSTREAM?"
if git merge-base --is-ancestor "$UPSTREAM" "$MERGE"; then
  echo "  sim"
else
  echo "  NAO -- faltam $(git rev-list --count "$MERGE".."$UPSTREAM") commits"
fi

echo
echo "### algo de cima pode ter sido descartado?"
# Diferenca liquida do ramo para o upstream. Arquivo so com acrescimo nao pode
# ter perdido nada; a atencao vai para os que tem remocao.
COM_REMOCAO=$(git diff --numstat "$P2" "$MERGE" | awk '$2 > 0 {print $3}')
if [ -z "$COM_REMOCAO" ]; then
  echo "  nenhum arquivo remove linha em relacao ao lado de cima"
else
  # A base e a bifurcacao entre os dois pais. Nao use merge-base com o upstream:
  # depois do merge ele ja e ancestral, o intervalo sai vazio e o teste passa a
  # dizer "ok" para tudo.
  BASE=$(git merge-base "$P1" "$P2")
  for f in $COM_REMOCAO; do
    N=$(git log --oneline "$BASE".."$P2" -- "$f" | wc -l | tr -d ' ')
    if [ "$N" -gt 0 ]; then
      echo "  ATENCAO  $f -- o lado de cima mexeu nele $N vez(es) desde a bifurcacao"
    else
      echo "  ok       $f -- o lado de cima nao tocou nele; a remocao e do proprio ramo"
    fi
  done
fi

echo
echo "### conflito semantico: arquivos do ramo que sombreiam arquivo de gem"
# O git nao ve esses: existem so de um lado, entao nao ha o que mesclar. Uma
# copia parada desfaz calada a parte do upgrade que mexeu no original.
NOVOS=$(git diff --name-only --diff-filter=A "$P2" "$MERGE")
ACHOU=0
for f in $NOVOS; do
  b=$(basename "$f")
  for dir in $(bundle list --paths 2>/dev/null); do
    hit=$(find "$dir" -name "$b" -type f 2>/dev/null | head -1)
    if [ -n "$hit" ]; then
      echo "  $f"
      echo "    tambem existe em: $hit"
      echo "    compare os dois: diff \"$hit\" \"$f\""
      ACHOU=1
      break
    fi
  done
done
[ "$ACHOU" = 0 ] && echo "  nenhum"

echo
echo "### Gemfile.lock"
if git diff --quiet "$P2" "$MERGE" -- Gemfile.lock; then
  echo "  identico ao do lado de cima"
else
  echo "  difere do lado de cima em $(git diff --numstat "$P2" "$MERGE" -- Gemfile.lock | awk '{print $1"+/"$2"-"}')"
  TMP_UP=$(mktemp); TMP_BR=$(mktemp); TMP_RE=$(mktemp)
  echo "  gems com versao diferente (fora as exclusivas do ramo):"
  git show "$P2:Gemfile.lock" | grep -oE '^    [a-z0-9_-]+ \([0-9][^)]*\)' | sort -u > "$TMP_UP"
  git show "$MERGE:Gemfile.lock"    | grep -oE '^    [a-z0-9_-]+ \([0-9][^)]*\)' | sort -u > "$TMP_BR"
  diff "$TMP_UP" "$TMP_BR" | sed 's/^/    /' || true
  rm -f "$TMP_UP" "$TMP_BR"
  echo "  coerencia (vazio = o lock ja e o que o bundler resolveria):"
  bundle lock --print 2>/dev/null > "$TMP_RE" && diff -q Gemfile.lock "$TMP_RE" >/dev/null \
    && echo "    ok" || echo "    DIVERGE -- veja: bundle lock --print | diff Gemfile.lock -"
  rm -f "$TMP_RE"
fi
