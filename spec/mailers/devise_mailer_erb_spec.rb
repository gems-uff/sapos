# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O ramo ERB do DeviseMailer#headers_for estava sem cobertura (#720): os
# templates devise:* padrao sao Liquid, e so uma instalacao que gravou o seu
# em ERB antes da trava passa por ali. Sai com a #684.
RSpec.describe DeviseMailer, "com template ERB gravado", type: :mailer do
  before(:each) do
    @user = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "erb_devise@ic.uff.br", "Usuaria Erb"
    )
    EmailTemplate.disable_erb_validation! do
      EmailTemplate.create!(
        name: "devise:reset_password_instructions", template_type: "ERB", enabled: true,
        subject: "Senha de <%= @resource.name %>",
        to: "<%= @resource.email %>",
        body: "Token: <%= @token %>"
      )
    end
  end

  it "monta assunto, destinatario e corpo pelo ERB, com o reply_to das variaveis" do
    FactoryBot.create(:custom_variable, variable: "reply_to", value: "secretaria@sapos.test")

    mensagem = DeviseMailer.reset_password_instructions(@user, "tok-123")

    expect(mensagem.subject).to eq("Senha de Usuaria Erb")
    expect(mensagem.to).to eq(["erb_devise@ic.uff.br"])
    expect(mensagem.body.decoded).to include("Token: tok-123")
    expect(mensagem.reply_to).to eq(["secretaria@sapos.test"])
  end

  it "redireciona para o endereco de teste quando ha redirect_email" do
    FactoryBot.create(:custom_variable, variable: "redirect_email", value: "teste@sapos.test")

    mensagem = DeviseMailer.reset_password_instructions(@user, "tok-123")

    expect(mensagem.to).to eq(["teste@sapos.test"])
    expect(mensagem.subject).to eq("Senha de Usuaria Erb (Originalmente para erb_devise@ic.uff.br)")
  end
end
