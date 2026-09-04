# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
# O filtro casa por SUBSTRING do nome do parametro, e alcanca tambem a query
# string, porque o Rails loga `request.filtered_path`. O :email entra aqui
# porque endereco de candidato e de aluno aparece em query string de tela
# publica -- e log de aplicacao nao e lugar de dado pessoal. (O log de acesso do
# servidor web nao passa por este filtro; por isso credencial nao deve ir para
# a URL em primeiro lugar.)
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :email,
]

# Override of ActiveRecord::LogSubscriber::sql to force the filtering of all sql queries that contain carrier_wave_files
# https://github.com/rails/rails/blob/master/activerecord/lib/active_record/log_subscriber.rb
module LogTruncater
  def sql(event)
    payload = event.payload
    sql = payload[:sql]
    if sql.include? "carrier_wave_files"  # filters out any sql that includes this table
      if payload[:sql] =~ /\A\s*(\w+)/i
        payload[:sql] = "#{$1} carrier_wave_files [SQL Filtered]"
      else
        payload[:sql] = "carrier_wave_files [SQL Filtered]"
      end
    end
    result = self.method(:sql).super_method.call(event)
    payload[:sql] = sql
    result
  end
end

class ActiveRecord::LogSubscriber
  prepend LogTruncater
end
