#!/usr/bin/env bash
# Escreve no resumo do job o resultado de uma rodada do RSpec e derruba o job
# quando a rodada nao merece confianca.
#
# uso: rspec-summary.sh LOG ROTULO REPRODUZIR
#
#   LOG         arquivo com a saida de `bundle exec rspec | tee LOG`
#   ROTULO      nome da perna, no titulo do resumo
#   REPRODUZIR  comando que repete a perna localmente (a seed e acrescentada)
#
# O codigo de saida do rspec ja derruba o passo que o rodou. Esta checagem pega
# o que um codigo zero esconde: uma rodada com menos exemplos que antes
# (arquivo que deixou de carregar, describe que nao roda mais, filtro que
# excluiu demais) ou um log sem a linha de resumo. Pending entra na contagem,
# como no proprio RSpec: reproducao de defeito que vira pending nao reduz nada.
#
# O piso fica em .github/min-examples, um lugar so para os dois workflows.
# Suba-o quando acrescentar exemplos; baixe-o so com o motivo escrito no commit.
set -u

log=$1
rotulo=$2
reproduzir=$3
resumo=${GITHUB_STEP_SUMMARY:-/dev/stdout}
piso=$(grep -vE '^\s*(#|$)' "$(dirname "$0")/../min-examples" | head -n 1 | tr -d '[:space:]')

linha=""
seed=""
if [ -f "$log" ]; then
  # "3521 examples, 0 failures, 26 pending"; com erro fora de exemplo,
  # "0 examples, 0 failures, 1 error occurred outside of examples". Sob o
  # parallel_rspec cada worker imprime a sua linha e a ultima e a soma deles
  # ("... 26 pendings"), que nao carrega o erro fora de exemplo: por isso esse
  # erro e procurado no log inteiro, e nao so na ultima linha.
  linha=$(grep -E '^[0-9]+ examples?, [0-9]+ failures?' "$log" | tail -n 1 || true)
  fora=$(grep -cE '[0-9]+ errors? occurred outside of examples' "$log" || true)
  seed=$(grep -oE 'Randomized with seed [0-9]+' "$log" | head -n 1 | grep -oE '[0-9]+$' || true)
fi

exemplos=$(grep -oE '^[0-9]+' <<<"$linha" || true)
exemplos=${exemplos:-0}
falhas=$(grep -oE '[0-9]+ failures?' <<<"$linha" | grep -oE '^[0-9]+' || true)

problema=""
if [ -z "$piso" ]; then
  problema="piso ausente em .github/min-examples"
elif [ -z "$linha" ]; then
  problema="nenhuma linha de resumo do RSpec em $log"
elif [ "${falhas:-0}" -gt 0 ] || [ "${fora:-0}" -gt 0 ]; then
  problema="a rodada tem falhas ou erros"
elif [ "$exemplos" -lt "$piso" ]; then
  problema="$exemplos exemplos, abaixo do piso de $piso (.github/min-examples)"
fi

{
  echo "### RSpec ($rotulo)"
  echo
  echo "- exemplos: $exemplos (piso $piso)"
  echo "- resumo: \`${linha:-ausente}\`"
  echo "- seed: \`${seed:-desconhecida}\`"
  [ -n "$problema" ] && echo "- **falhou:** $problema"
  echo
  echo "Reproduzir localmente:"
  echo '```'
  echo "$reproduzir --seed ${seed:-0}"
  echo "$reproduzir --seed ${seed:-0} --bisect   # se for dependencia de ordem"
  echo '```'
  # Com o parallel_rspec, a ordem que falhou e a de um worker sobre o seu
  # subconjunto de arquivos, e a suite inteira com a mesma seed nao a repete.
  # O --verbose-rerun-command imprime o comando exato de cada worker que
  # falhou; rodado em serial, ele reproduz a ordem, e o --bisect vai no fim.
  if [ -f "$log" ] && grep -q 'run the group again' "$log"; then
    echo
    echo "Workers do parallel_rspec que falharam (rode cada um em serial):"
    echo '```'
    grep -E '^TEST_ENV_NUMBER=' "$log" || true
    echo '```'
  fi
} >>"$resumo"

if [ -n "$problema" ]; then
  echo "::error title=RSpec ($rotulo)::$problema"
  exit 1
fi
