#!/usr/bin/env bash
# Confere um merge de catch-up: o que o humano digitou durante a resolucao, o
# que do lado de cima pode ter se perdido -- inclusive o que o diff contra o
# merge automatico nao pega -- e parte do que o git nao ve. Uso, de qualquer
# ponto do checkout:
#
#   "$(git rev-parse --show-toplevel)"/.claude/skills/merge-downstream/conferir_merge.sh [commit-de-merge] [ref-de-cima]
#
# Sem argumentos, confere o HEAD contra a origin/main -- nunca contra a main
# local, que o git fetch nao avanca. Supoe o merge feito no ramo (git merge
# origin/main): pai 1 e o ramo, pai 2 o lado de cima.
#
# Cada secao imprime o que mediu; ATENCAO marca o que pede leitura humana. O
# codigo de retorno nao e veredito: 0 depois do relatorio, diga ele o que
# disser, e 1 quando os argumentos sao recusados. A coerencia do Gemfile.lock
# so e conferida quando o merge auditado e o HEAD e Gemfile e Gemfile.lock
# estao limpos na arvore: o bundler le o lock da arvore de trabalho, nao o do
# commit. Precisa de git 2.38 ou mais novo (merge-tree --write-tree).
set -u

MERGE="${1:-HEAD}"
UPSTREAM="${2:-origin/main}"

TOP=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "erro: fora de um repositorio git" >&2; exit 1; }
# Todo caminho abaixo e relativo a raiz do repositorio.
cd "$TOP" || exit 1

if ! MERGE_C=$(git rev-parse -q --verify "$MERGE^{commit}"); then
  echo "erro: $MERGE nao e um commit" >&2; exit 1
fi
if ! git rev-parse -q --verify "$MERGE_C^2" >/dev/null; then
  echo "erro: $MERGE nao e um commit de merge" >&2; exit 1
fi
if ! UPSTREAM_C=$(git rev-parse -q --verify "$UPSTREAM^{commit}"); then
  echo "erro: $UPSTREAM nao e um commit (rode git fetch origin, ou nomeie a ref)" >&2; exit 1
fi

P1=$(git rev-parse "$MERGE_C^1")
P2=$(git rev-parse "$MERGE_C^2")
# A base e a bifurcacao entre os dois pais. Nao use merge-base com o upstream:
# depois do merge ele ja e ancestral, o intervalo sai vazio e todo teste de
# "o lado de cima mexeu nisso?" passa a dizer que nao.
BASE=$(git merge-base "$P1" "$P2") || { echo "erro: os dois pais nao tem ancestral comum" >&2; exit 1; }
MERGE_TREE=$(git rev-parse "$MERGE_C^{tree}")

echo "### commit"
git log -1 --format='%h  %an  %ad%n%s' --date=iso "$MERGE_C"
echo "  pai 1 (ramo):    $(git log -1 --format='%h %s' "$P1")"
echo "  pai 2 (de cima): $(git log -1 --format='%h %s' "$P2")"
echo "  bifurcacao:      $(git log -1 --format='%h %s' "$BASE")"

echo
echo "### o pai 2 e mesmo o topo de $UPSTREAM?"
if [ "$P2" = "$UPSTREAM_C" ]; then
  echo "  sim, e o topo atual"
else
  echo "  nao. $UPSTREAM esta em $(git rev-parse --short "$UPSTREAM_C")."
  echo "  faltam $(git rev-list --count "$MERGE_C".."$UPSTREAM_C") commits."
  echo "  (nem sempre e defeito: o merge pode ser antigo. 'git reflog show $UPSTREAM'"
  echo "   diz o que a ref apontava em cada momento.)"
fi

echo
echo "### houve intervencao manual na resolucao?"
# Reconstroi o merge automatico e compara com a arvore que ficou gravada. O que
# sobrar do diff foi digitado por alguem -- resolucao de conflito ou nao.
AUTO_OUT=$(git -c core.quotePath=false merge-tree --write-tree --name-only "$P1" "$P2" 2>/dev/null)
AUTO_RC=$?
AUTO=$(printf '%s\n' "$AUTO_OUT" | head -1)
TYPED=""
CONFLICTED=""
if [ -z "$AUTO" ] || [ "$AUTO_RC" -gt 1 ]; then
  echo "  nao deu para reconstruir (merge-tree --write-tree precisa de git 2.38 ou mais novo)"
  AUTO=""
else
  # Com conflito, as linhas depois da arvore nomeiam os arquivos conflitados,
  # ate uma linha em branco.
  [ "$AUTO_RC" = 1 ] && CONFLICTED=$(printf '%s\n' "$AUTO_OUT" | sed -n '2,/^$/p' | sed '/^$/d')
  if [ "$AUTO" = "$MERGE_TREE" ]; then
    echo "  nao: a arvore gravada e identica a do merge automatico"
  else
    TYPED=$(git -c core.quotePath=false diff --name-only --no-renames "$AUTO" "$MERGE_TREE")
    echo "  sim, nestes arquivos:"
    git -c core.quotePath=false diff --numstat --no-renames "$AUTO" "$MERGE_TREE" | sed 's/^/    /'
    echo "  (ver o teor: git diff $AUTO $MERGE_TREE -- <arquivo>)"
  fi
  if [ -n "$CONFLICTED" ]; then
    echo "  os dois pais conflitam em:"
    printf '%s\n' "$CONFLICTED" | sed 's/^/    /'
    # Conflito binario ou modify/delete nao tem marcador: a reconstrucao ja traz
    # a versao de um dos lados, e a resolucao que a manteve deixa o diff acima
    # vazio para aquele arquivo, com a mudanca do outro lado sumida.
    printf '%s\n' "$CONFLICTED" | while IFS= read -r f; do
      printf '%s\n' "$TYPED" | grep -qxF -- "$f" && continue
      echo "  ATENCAO  $f -- conflitou e ficou igual a reconstrucao (conflito binario ou modify/delete):"
      echo "           a resolucao manteve a versao de um dos lados; confira se a mudanca do outro nao sumiu"
    done
    # Marcador que ficou gravado. A reconstrucao rotula os marcadores com o SHA
    # dos pais e o git merge com HEAD e o nome da ref, entao as duas arvores
    # nunca saem iguais: o marcador so se acha lendo o arquivo.
    printf '%s\n' "$CONFLICTED" | while IFS= read -r f; do
      if git grep -q -E '^(<<<<<<<|>>>>>>>)( |$)' "$MERGE_C" -- "$f" 2>/dev/null; then
        echo "  ATENCAO  $f -- marcador de conflito commitado"
      fi
    done
  fi
fi

echo
echo "### o ramo contem tudo o que esta em $UPSTREAM?"
if git merge-base --is-ancestor "$UPSTREAM_C" "$MERGE_C"; then
  echo "  sim"
elif git merge-base --is-ancestor "$MERGE_C" "$UPSTREAM_C"; then
  echo "  o merge ja esta em $UPSTREAM; $(git rev-list --count "$MERGE_C".."$UPSTREAM_C") commits vieram depois dele (atraso, nao perda)"
else
  echo "  NAO -- faltam $(git rev-list --count "$MERGE_C".."$UPSTREAM_C") commits"
fi

echo
echo "### algo de cima pode ter sido descartado?"
# Diferenca liquida do ramo para o lado de cima. Arquivo so com acrescimo nao
# pode ter perdido nada; a atencao vai para os que tem remocao. Binario nao tem
# contagem de linha (numstat imprime "-") e entra sempre.
COM_REMOCAO=$(git -c core.quotePath=false diff --numstat --no-renames "$P2" "$MERGE_C" \
  | awk -F'\t' '$2 == "-" || $2 > 0 {print $3}')
if [ -z "$COM_REMOCAO" ]; then
  echo "  nenhum arquivo remove linha em relacao ao lado de cima"
else
  printf '%s\n' "$COM_REMOCAO" | while IFS= read -r f; do
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
NOVOS=$(git -c core.quotePath=false diff --name-only --diff-filter=A "$P2" "$MERGE_C")
if ! GEM_DIRS=$(bundle list --paths 2>/dev/null) || [ -z "$GEM_DIRS" ]; then
  echo "  (nao conferido: bundle list --paths falhou -- as gems estao instaladas?)"
elif [ -z "$NOVOS" ]; then
  echo "  nenhum: o ramo nao traz arquivo novo"
else
  ACHOU=0
  while IFS= read -r f; do
    b=$(basename "$f")
    while IFS= read -r dir; do
      hit=$(find "$dir" -name "$b" -type f 2>/dev/null | head -1)
      if [ -n "$hit" ]; then
        echo "  $f"
        echo "    tambem existe em: $hit"
        echo "    compare os dois: diff \"$hit\" \"$f\""
        ACHOU=1
        break
      fi
    done <<<"$GEM_DIRS"
  done <<<"$NOVOS"
  [ "$ACHOU" = 0 ] && echo "  nenhum"
fi

echo
echo "### pending da main para issue que o ramo conserta"
# A main guarda a reproducao de defeito com pending: "issue #NNN" (AGENTS.md).
# Se o ramo conserta a NNN, depois do merge o exemplo passa e o RSpec acusa
# "Expected pending ... to fail". As issues do ramo saem do assunto dos commits
# do lado do ramo ("Issue #NNN: ...") e do nome do ramo no assunto do merge.
ISSUES=$( { git log --format=%s "$BASE".."$P1" | sed -nE 's/^Issue #([0-9]+):.*/\1/p'
            git log -1 --format=%s "$MERGE_C" | sed -nE 's/.*issue_([0-9]+).*/\1/p'; } | sort -un)
if [ -z "$ISSUES" ]; then
  echo "  nenhuma issue identificada no ramo (nenhum commit 'Issue #NNN:'); procure a mao:"
  echo "  git grep -n 'pending: \"issue #NNN\"' $MERGE_C -- spec"
else
  echo "  issues do ramo: $(printf '#%s ' $ISSUES)"
  ACHOU=0
  for n in $ISSUES; do
    HITS=$(git grep -n -E "pending: *[\"']issue #$n[\"']" "$MERGE_C" -- spec 2>/dev/null | sed "s|^$MERGE_C:||")
    [ -n "$HITS" ] || continue
    ACHOU=1
    echo "  ATENCAO  pending da issue #$n, que o ramo trabalha:"
    printf '%s\n' "$HITS" | sed 's/^/    /'
  done
  if [ "$ACHOU" = 1 ]; then
    echo "  se o ramo conserta o cenario, a marca sai (o exemplo fica, como regressao);"
    echo "  cenario que o ramo nao conserta, na entrega pela metade, mantem a marca"
  else
    echo "  nenhum pending marcado com issue do ramo"
  fi
fi

echo
echo "### Gemfile.lock"
# Versoes travadas: as linhas de quatro espacos das secoes specs.
gem_versions() {
  git show "$1:Gemfile.lock" 2>/dev/null \
    | grep -oE '^    [A-Za-z0-9_.-]+ \([0-9][^)]*\)' | sed 's/^    //' | LC_ALL=C sort -u
}
if ! git cat-file -e "$MERGE_C:Gemfile.lock" 2>/dev/null; then
  echo "  o merge nao tem Gemfile.lock"
else
  if git diff --quiet "$P2" "$MERGE_C" -- Gemfile.lock; then
    echo "  identico ao do lado de cima"
  else
    echo "  difere do lado de cima em $(git diff --numstat "$P2" "$MERGE_C" -- Gemfile.lock | awk '{print $1"+/"$2"-"}')"
    # comm, nao diff: no sandbox do Claude Code o diff nao le pipe nem /dev/fd.
    MUDOU=$(LC_ALL=C comm -3 <(gem_versions "$P2") <(gem_versions "$MERGE_C") \
      | awk -F'\t' '{ if ($1 == "") print "> " $2; else print "< " $1 }')
    if [ -z "$MUDOU" ]; then
      echo "  nenhuma versao travada difere: a diferenca esta em dependencias, plataformas ou checksums"
    else
      # Em merge de catch-up saudavel, toda diferenca para o lado de cima e
      # versao que o ramo travou. Sobra para explicar: versao que nenhum pai
      # tinha (o merge resolveu de novo) e versao que os dois pais tinham e o
      # merge trocou.
      echo "  versoes que diferem (< lado de cima, > merge), conferidas contra o lock do ramo:"
      BR_V=$(gem_versions "$P1")
      printf '%s\n' "$MUDOU" | while IFS= read -r l; do
        if printf '%s\n' "$BR_V" | grep -qxF -- "${l#? }"; then
          case $l in
            ">"*) echo "    $l  -- do ramo" ;;
            *)    echo "  ATENCAO  $l  -- os dois pais tinham essa versao, e o merge a trocou" ;;
          esac
        else
          case $l in
            ">"*) echo "  ATENCAO  $l  -- nenhum dos pais tinha essa versao: o merge resolveu de novo" ;;
            *)    echo "    $l  -- o ramo trocou ou tirou" ;;
          esac
        fi
      done
    fi
  fi
  # Versao que um lado subiu desde a bifurcacao e o merge nao tem mais: pegar o
  # lock de um lado e resolver de novo mantem as versoes daquele lado, e o que o
  # outro tinha subido some sem conflito nenhum.
  if git cat-file -e "$BASE:Gemfile.lock" 2>/dev/null; then
    for lado in "o lado de cima" "o ramo"; do
      if [ "$lado" = "o ramo" ]; then P=$P1; else P=$P2; fi
      PERDIDAS=$(LC_ALL=C comm -12 \
        <(LC_ALL=C comm -13 <(gem_versions "$BASE") <(gem_versions "$P")) \
        <(LC_ALL=C comm -23 <(gem_versions "$P") <(gem_versions "$MERGE_C")))
      if [ -n "$PERDIDAS" ]; then
        echo "  ATENCAO  versoes que $lado subiu e o merge nao tem:"
        printf '%s\n' "$PERDIDAS" | sed 's/^/    /'
      fi
    done
  fi
  if [ -n "$(git diff --name-only "$BASE" "$P1" -- Gemfile)" ] && [ -n "$(git diff --name-only "$BASE" "$P2" -- Gemfile)" ]; then
    echo "  ATENCAO  o Gemfile mudou dos dois lados desde a bifurcacao: o lock mesclado pode nao casar com nenhum"
  fi
  if [ "$(git rev-parse HEAD)" != "$MERGE_C" ] || [ -n "$(git status --porcelain -- Gemfile Gemfile.lock)" ]; then
    echo "  (coerencia nao conferida: o merge auditado nao e o HEAD, ou Gemfile/Gemfile.lock estao modificados"
    echo "   na arvore -- o bundler le o lock da arvore de trabalho, nao o do merge)"
  elif ! command -v bundle >/dev/null 2>&1; then
    echo "  (coerencia nao conferida: bundle nao esta no PATH)"
  else
    # Sem arquivo temporario: no sandbox o mktemp cai num TMPDIR que ele nega.
    RESOLVIDO=$(bundle lock --print 2>/dev/null)
    RC=$?
    if [ "$RC" != 0 ]; then
      echo "  bundle lock --print nao rodou (saida $RC), entao nada foi medido:"
      bundle lock --print 2>&1 >/dev/null | tail -3 | sed 's/^/    /'
    elif [ "$RESOLVIDO" = "$(cat Gemfile.lock)" ]; then
      echo "  coerencia: ok (o lock e o que o bundler resolveria; nao prova que seja o lock que voce queria)"
    else
      echo "  ATENCAO  coerencia: DIVERGE -- veja: bundle lock --print | diff Gemfile.lock -"
    fi
  fi
fi
exit 0
