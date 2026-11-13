# frozen_string_literal: true

# Apaga o que o exercicio_email_inscricao.rb deixou na replica: a inscricao de
# teste, o formulario preenchido dela e as linhas de notification_logs das
# mensagens do exercicio. Roda NO SERVIDOR, por rails runner:
#
#   set -a; source ~/.sapos_staging_env; set +a
#   ssh "$SAPOS_STAGING_SSH" "f=\$(mktemp /tmp/limpa.XXXXXX.rb); chmod 644 \$f; cat > \$f; \
#     sudo -i -u $SAPOS_STAGING_INSTANCE bash -lc \"cd ~/instance && bundle exec rails runner \$f\"; \
#     rm -f \$f" < limpa_exercicio_email.rb
#
# So alcanca o que leva o marcador: inscricao cujo nome comeca por
# ZZ-TESTE-HOMOLOG e cujo e-mail e zz-teste-homolog...@example.com, e mensagem
# cujo assunto ou destinatario cita esse endereco. Imprime contagens, nunca
# conteudo.
MARCA = "ZZ-TESTE-HOMOLOG"
ENDERECO = "zz-teste-homolog%@example.com"

inscricoes = Admissions::AdmissionApplication
  .where("name LIKE ?", "#{MARCA}%").where("email LIKE ?", ENDERECO)
formularios = inscricoes.filter_map(&:filled_form)
apagadas = inscricoes.count
inscricoes.each(&:destroy!)
# A candidatura so faz belongs_to do formulario preenchido, sem dependent.
formularios.each { |formulario| formulario.reload.destroy! }

mensagens = NotificationLog.where("subject LIKE :e OR `to` LIKE :e", e: "%zz-teste-homolog%")
registradas = mensagens.count
mensagens.delete_all

restam = Admissions::AdmissionApplication.where("name LIKE ?", "#{MARCA}%").count
puts "inscricoes_apagadas=#{apagadas} formularios_apagados=#{formularios.size} " \
     "mensagens_apagadas=#{registradas} inscricoes_com_o_marcador_restantes=#{restam}"
