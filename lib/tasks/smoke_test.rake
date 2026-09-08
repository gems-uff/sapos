# frozen_string_literal: true

# lib/tasks/smoke_test.rake

# A 8.1 deixou de aceitar `ActionMailer::Base.mail(...)` como chamada de classe: o
# method_missing de classe do ActionMailer nao despacha mais :mail como action, e a
# chamada estoura com NoMethodError. O smoke test precisa entao de um mailer
# concreto com action nomeada -- esta classe existe so para exercitar o caminho
# Rails -> sendmail no deploy, e por isso mora aqui, e nao em app/mailers.
class SmokeTestMailer < ActionMailer::Base
  def deploy_validation
    mail(
      from: "teste-sistema@sapos.ic.uff.br",
      to: "teste-sistema@sapos.ic.uff.br",
      subject: "[SAPOS] Validação de Deploy",
      body: "Validando configurações do sendmail."
    )
  end
end

namespace :smoke_test do
  desc "Verifica se o delivery_method é :sendmail e se o binário está disponível e executável"
  task check_sendmail_binary: :environment do
    puts "Verificando binário do sendmail..."

    unless ActionMailer::Base.delivery_method == :sendmail
      puts "❌ delivery_method não é :sendmail (atual: #{ActionMailer::Base.delivery_method})"
      exit 1
    end

    location = ActionMailer::Base.sendmail_settings[:location]
    if File.executable?(location)
      puts "✅ Sendmail encontrado em #{location}"
    else
      puts "❌ Sendmail não encontrado em #{location}"
      exit 1
    end
  end

  desc "Verifica se as dependências do servidor e do Rails para e-mail estão funcionais"
  task check_mailer: :environment do
    puts "Testando integração com o Mailer/Sendmail..."

    begin
      SmokeTestMailer.deploy_validation.deliver_now
      puts "✅ Sucesso! O Sendmail aceitou o comando."
    rescue StandardError => e
      puts "❌ Falha na configuração do Mailer: #{e.message}"
      exit 1
    end
  end

  desc "Executa todos os smoke tests de e-mail em sequência"
  task all: [:check_sendmail_binary, :check_mailer] do
    puts "\n✅ Todos os smoke tests de e-mail passaram."
  end
end
