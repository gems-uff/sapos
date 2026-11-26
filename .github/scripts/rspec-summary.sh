#!/usr/bin/env bash
# Escreve no resumo do job o resultado de uma rodada do RSpec e derruba o job
# quando a rodada nao merece confianca.
#
# uso: rspec-summary.sh ROTULO REPRODUZIR LOG [LOG...]
#
#   ROTULO      nome da perna, no titulo do resumo
#   REPRODUZIR  comando que repete a perna localmente (a seed e acrescentada)
#   LOG         arquivo com a saida de `bundle exec rspec | tee LOG`; com
#               varios, um por maquina da mesma rodada, as contagens se somam
#
# SEM_PISO=1 deixa de fora a comparacao com o piso: a maquina que roda parte
# da suite nao alcanca o piso sozinha, e quem o confere e o job que soma as
# partes.
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

rotulo=$1
reproduzir=$2
shift 2
resumo=${GITHUB_STEP_SUMMARY:-/dev/stdout}
piso=$(grep -vE '^\s*(#|$)' "$(dirname "$0")/../min-examples" | head -n 1 | tr -d '[:space:]')

linhas=()
seed=""
exemplos=0
falhas=0
fora=0
ausente=""
for log in "$@"; do
  linha=""
  if [ -f "$log" ]; then
    # "3521 examples, 0 failures, 26 pending"; com erro fora de exemplo,
    # "0 examples, 0 failures, 1 error occurred outside of examples". Sob o
    # parallel_rspec cada worker imprime a sua linha e a ultima e a soma deles
    # ("... 26 pendings"), que nao carrega o erro fora de exemplo: por isso esse
    # erro e procurado no log inteiro, e nao so na ultima linha.
    linha=$(grep -E '^[0-9]+ examples?, [0-9]+ failures?' "$log" | tail -n 1 || true)
    n=$(grep -cE '[0-9]+ errors? occurred outside of examples' "$log" || true)
    fora=$((fora + ${n:-0}))
    [ -z "$seed" ] && seed=$(grep -oE 'Randomized with seed [0-9]+' "$log" | head -n 1 | grep -oE '[0-9]+$' || true)
  fi
  if [ -z "$linha" ]; then
    ausente="$ausente $log"
    continue
  fi
  linhas+=("$linha")
  n=$(grep -oE '^[0-9]+' <<<"$linha" || true)
  exemplos=$((exemplos + ${n:-0}))
  n=$(grep -oE '[0-9]+ failures?' <<<"$linha" | grep -oE '^[0-9]+' || true)
  falhas=$((falhas + ${n:-0}))
done

problema=""
if [ -z "$piso" ]; then
  problema="piso ausente em .github/min-examples"
elif [ "$#" -eq 0 ] || [ -n "$ausente" ]; then
  problema="nenhuma linha de resumo do RSpec em${ausente:- (nenhum log)}"
elif [ "$falhas" -gt 0 ] || [ "$fora" -gt 0 ]; then
  problema="a rodada tem falhas ou erros"
elif [ -z "${SEM_PISO:-}" ] && [ "$exemplos" -lt "$piso" ]; then
  problema="$exemplos exemplos, abaixo do piso de $piso (.github/min-examples)"
fi

{
  echo "### RSpec ($rotulo)"
  echo
  if [ -n "${SEM_PISO:-}" ]; then
    echo "- exemplos: $exemplos (parte da suite; o piso, $piso, e conferido na soma das partes)"
  else
    echo "- exemplos: $exemplos (piso $piso)"
  fi
  for linha in "${linhas[@]}"; do
    echo "- resumo: \`$linha\`"
  done
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
  if grep -qs 'run the group again' "$@"; then
    echo
    echo "Workers do parallel_rspec que falharam (rode cada um em serial):"
    echo '```'
    grep -hE '^TEST_ENV_NUMBER=' "$@" || true
    echo '```'
  fi
} >>"$resumo"

if [ -n "$problema" ]; then
  echo "::error title=RSpec ($rotulo)::$problema"
  exit 1
fi
