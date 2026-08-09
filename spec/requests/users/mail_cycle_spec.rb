# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Cobre o ciclo completo dos e-mails do Devise usados pelo SAPOS: disparar a
# ação, conferir que a mensagem sai para o endereço certo e com o link certo, e
# então seguir o link até o efeito esperado no banco.
#
# Em teste o `delivery_method` é `:test` (`config/environments/test.rb`), então a
# caixa de entrada é `ActionMailer::Base.deliveries` — o mesmo conteúdo que o
# `letter_opener_web` mostra em `/letter_opener` no ambiente de desenvolvimento.
# Não é preciso mock: o mecanismo já é o do próprio ActionMailer.
#
# Os corpos vêm dos templates Liquid em `app/views/devise/mailer/`, montados pelo
# `DeviseMailer`, que só entrega quando o EmailTemplate está habilitado. Sem
# registro em `email_templates`, `EmailTemplate.load_template` devolve o builtin,
# que nasce habilitado.
RSpec.describe "Devise mail cycle", type: :request do
  # Os links dos templates trazem o token como parâmetro de query.
  def token_in(mail, param)
    mail.body.decoded[/#{param}=([A-Za-z0-9_-]+)/, 1]
  end

  # Procurar pelo destinatário, em vez de usar `deliveries.last`, porque uma só
  # ação pode gerar mais de uma mensagem — a troca de e-mail avisa o endereço
  # antigo e pede confirmação no novo. Da mais recente para a mais antiga, como
  # numa caixa de entrada: `create_confirmed_user` faz `User.create` antes do
  # `skip_confirmation!`, então deixa um e-mail de confirmação para trás.
  def mail_to(address)
    ActionMailer::Base.deliveries.reverse.find do |mail|
      mail.to.to_a.include?(address)
    end
  end

  before(:each) do
    @role = FactoryBot.create :role_administrador
    ActionMailer::Base.deliveries.clear
  end

  describe "invitation" do
    it "sends the invitation to the invited address" do
      User.invite!(
        email: "invited@ic.uff.br", name: "ana", roles: [@role]
      )

      mail = mail_to("invited@ic.uff.br")
      expect(mail).to_not be_nil
      expect(mail.subject).to eql(
        I18n.t("devise.mailer.invitation_instructions.subject")
      )
      expect(mail.body.decoded).to include(accept_user_invitation_path)
    end

    it "accepts the invitation and sets the password when the link is followed" do
      user = User.invite!(
        email: "invited@ic.uff.br", name: "ana", roles: [@role]
      )
      token = token_in(mail_to("invited@ic.uff.br"), "invitation_token")
      expect(token).to_not be_nil

      get accept_user_invitation_path(invitation_token: token)
      expect(response).to have_http_status(:ok)

      put user_invitation_path, params: { user: {
        invitation_token: token,
        password: "A1b2c3d4!", password_confirmation: "A1b2c3d4!"
      } }

      expect(user.reload.invitation_accepted_at).to_not be_nil
      expect(user.valid_password?("A1b2c3d4!")).to be true
    end

    it "does not accept the invitation with a token that was not issued" do
      user = User.invite!(
        email: "invited@ic.uff.br", name: "ana", roles: [@role]
      )

      put user_invitation_path, params: { user: {
        invitation_token: "nao-emitido",
        password: "A1b2c3d4!", password_confirmation: "A1b2c3d4!"
      } }

      expect(user.reload.invitation_accepted_at).to be_nil
    end
  end

  describe "confirmation of an email change" do
    it "asks for confirmation on the new address and warns the old one" do
      user = create_confirmed_user([@role], "old@ic.uff.br")
      ActionMailer::Base.deliveries.clear

      user.update!(email: "new@ic.uff.br")

      confirmation = mail_to("new@ic.uff.br")
      expect(confirmation).to_not be_nil
      expect(confirmation.subject).to eql(
        I18n.t("devise.mailer.confirmation_instructions.subject")
      )

      warning = mail_to("old@ic.uff.br")
      expect(warning).to_not be_nil
      expect(warning.subject).to eql(
        I18n.t("devise.mailer.email_changed.subject")
      )
    end

    it "applies the email change when the link is followed" do
      user = create_confirmed_user([@role], "old@ic.uff.br")
      ActionMailer::Base.deliveries.clear
      user.update!(email: "new@ic.uff.br")
      token = token_in(mail_to("new@ic.uff.br"), "confirmation_token")
      expect(token).to_not be_nil

      get user_confirmation_path(confirmation_token: token)

      expect(user.reload.email).to eql("new@ic.uff.br")
      expect(user.unconfirmed_email).to be_nil
    end

    it "keeps the old email when the link carries a token that was not issued" do
      user = create_confirmed_user([@role], "old@ic.uff.br")
      user.update!(email: "new@ic.uff.br")

      get user_confirmation_path(confirmation_token: "nao-emitido")

      expect(user.reload.email).to eql("old@ic.uff.br")
      expect(user.unconfirmed_email).to eql("new@ic.uff.br")
    end
  end

  describe "forgotten password" do
    it "sends the reset link to the address of the user" do
      create_confirmed_user([@role], "forgot@ic.uff.br")
      ActionMailer::Base.deliveries.clear

      post user_password_path, params: { user: { email: "forgot@ic.uff.br" } }

      mail = mail_to("forgot@ic.uff.br")
      expect(mail).to_not be_nil
      expect(mail.subject).to eql(
        I18n.t("devise.mailer.reset_password_instructions.subject")
      )
      expect(mail.body.decoded).to include(edit_user_password_path)
    end

    it "changes the password when the link is followed" do
      user = create_confirmed_user([@role], "forgot@ic.uff.br")
      ActionMailer::Base.deliveries.clear
      post user_password_path, params: { user: { email: "forgot@ic.uff.br" } }
      token = token_in(mail_to("forgot@ic.uff.br"), "reset_password_token")
      expect(token).to_not be_nil

      get edit_user_password_path(reset_password_token: token)
      expect(response).to have_http_status(:ok)

      put user_password_path, params: { user: {
        reset_password_token: token,
        password: "N9v8b7c6!", password_confirmation: "N9v8b7c6!"
      } }

      expect(user.reload.valid_password?("N9v8b7c6!")).to be true
    end

    it "warns the user that the password has changed" do
      user = create_confirmed_user([@role], "forgot@ic.uff.br")
      ActionMailer::Base.deliveries.clear
      post user_password_path, params: { user: { email: "forgot@ic.uff.br" } }
      token = token_in(mail_to("forgot@ic.uff.br"), "reset_password_token")
      expect(token).to_not be_nil
      ActionMailer::Base.deliveries.clear

      put user_password_path, params: { user: {
        reset_password_token: token,
        password: "N9v8b7c6!", password_confirmation: "N9v8b7c6!"
      } }

      mail = mail_to("forgot@ic.uff.br")
      expect(mail).to_not be_nil
      expect(mail.subject).to eql(
        I18n.t("devise.mailer.password_change.subject")
      )
      expect(user.reload.valid_password?("N9v8b7c6!")).to be true
    end

    it "keeps the password when the link carries a token that was not issued" do
      user = create_confirmed_user([@role], "forgot@ic.uff.br")

      put user_password_path, params: { user: {
        reset_password_token: "nao-emitido",
        password: "N9v8b7c6!", password_confirmation: "N9v8b7c6!"
      } }

      expect(user.reload.valid_password?("A1b2c3d4!")).to be true
    end
  end

  describe "unlock of a locked account" do
    it "sends the unlock link when the account is locked" do
      user = create_confirmed_user([@role], "locked@ic.uff.br")
      ActionMailer::Base.deliveries.clear

      user.lock_access!

      mail = mail_to("locked@ic.uff.br")
      expect(mail).to_not be_nil
      expect(mail.subject).to eql(
        I18n.t("devise.mailer.unlock_instructions.subject")
      )
      expect(mail.body.decoded).to include(user_unlock_path)
    end

    it "unlocks the account when the link is followed" do
      user = create_confirmed_user([@role], "locked@ic.uff.br")
      ActionMailer::Base.deliveries.clear
      user.lock_access!
      token = token_in(mail_to("locked@ic.uff.br"), "unlock_token")
      expect(token).to_not be_nil
      expect(user.reload.access_locked?).to be true

      get user_unlock_path(unlock_token: token)

      expect(user.reload.access_locked?).to be false
    end
  end
end
