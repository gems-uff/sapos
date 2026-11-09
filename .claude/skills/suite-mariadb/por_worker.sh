#!/bin/sh
# Roda um comando com o DATABASE_URL apontado para o banco deste worker do
# parallel_rspec: /sapos_test? vira /sapos_test2?, /sapos_test3? ... O primeiro
# worker tem TEST_ENV_NUMBER vazio e fica com sapos_test.
#
# O DATABASE_URL traz o nome do banco e prevalece sobre o database: do YAML, e
# o parallel_tests o repassa igual a todos os workers: sem isto, todos caem no
# mesmo banco, e a varredura de vazamento de um apaga o before(:all) do outro.
# Tudo que o worker dispara herda a URL ja reescrita -- o cliente proprio do
# Query.run_read_only_query e a rake task de notificacoes, que e outro processo.
case "$DATABASE_URL" in
  */sapos_test\?*) ;;
  *) echo "por_worker.sh: DATABASE_URL precisa conter /sapos_test?" >&2; exit 1 ;;
esac
DATABASE_URL=$(printf '%s' "$DATABASE_URL" | sed "s|/sapos_test?|/sapos_test${TEST_ENV_NUMBER}?|")
export DATABASE_URL
exec "$@"
