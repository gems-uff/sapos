# frozen_string_literal: true

# Troca o valor de CustomVariable.redirect_email na instancia de homologacao,
# para exercitar e-mail com tudo redirecionado a um endereco de teste, e repoe a
# trava depois. Roda NO SERVIDOR, por rails runner:
#
#   set -a; source ~/.sapos_staging_env; set +a
#   ssh "$SAPOS_STAGING_SSH" "f=\$(mktemp /tmp/trava.XXXXXX.rb); chmod 644 \$f; cat > \$f; \
#     sudo -i -u $SAPOS_STAGING_INSTANCE bash -lc \"cd ~/instance && bundle exec rails runner \$f <endereco|VAZIA>\"; \
#     rm -f \$f" < trava_email.rb
#
# <endereco> destrava redirecionando; VAZIA repoe a trava mestra. O script
# NUNCA apaga a variavel: ausente, ela manda o e-mail ao destinatario real.
# Imprime so o estado (AUSENTE, VAZIA, ENDERECO), nao o endereco. Confira o
# resultado pela tela, com o conferir_redirect_email.rb, antes e depois.
estado = ->(valor) { valor.nil? ? "AUSENTE" : (valor == "" ? "VAZIA" : "ENDERECO") }

variavel = CustomVariable.find_by(variable: "redirect_email")
abort "redirect_email AUSENTE: nada alterado. Criar a variavel e decisao do mantenedor." if variavel.nil?

novo = ARGV[0] == "VAZIA" ? "" : ARGV[0].to_s
abort "uso: trava_email.rb <endereco|VAZIA>" unless novo == "" || novo.match?(/\A[^@\s]+@[^@\s]+\z/)

puts "antes=#{estado.call(CustomVariable.redirect_email)}"
variavel.update!(value: novo)
puts "depois=#{estado.call(CustomVariable.redirect_email)} enviando=#{Notifier.sending?}"
