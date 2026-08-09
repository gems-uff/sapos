# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Expired session", type: :request do
  # A página de login aberta por horas perde o cookie de sessão, e o token de
  # CSRF do formulário deixa de bater. O usuário não deve levar um 500 por isso.
  before(:each) do
    @forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  after(:each) do
    ActionController::Base.allow_forgery_protection = @forgery_protection
  end

  it "sends the user back to the login page instead of raising" do
    post user_session_path, params: {
      authenticity_token: "token-de-uma-sessao-que-expirou",
      user: { email: "ana.sapos@ic.uff.br", password: "A1b2c3d4!" }
    }

    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq I18n.t("errors.session_expired")
  end

  it "answers non-navigational requests with 422, not with a redirect" do
    post user_session_path(format: :json), params: {
      authenticity_token: "token-de-uma-sessao-que-expirou"
    }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "does not notify when the session is empty, which is what expiring looks like" do
    expect(ExceptionNotifier).not_to receive(:notify_exception)

    post user_session_path, params: {
      authenticity_token: "token-de-uma-sessao-que-expirou"
    }
  end

  it "notifies when the token fails with a session that carries data" do
    # Sessão viva e token inválido não é expiração: é defeito nosso, ataque ou
    # cliente adulterando o form. O usuário não leva 500, mas o mantenedor sabe.
    user = create_confirmed_user([FactoryBot.create(:role_administrador)])
    sign_in user

    expect(ExceptionNotifier).to receive(:notify_exception).with(
      an_instance_of(ActionController::InvalidAuthenticityToken),
      hash_including(:env, :data)
    )

    # Não serve o /users/sign_in aqui: o require_no_authentication do Devise é
    # prependado depois e desvia o usuário logado antes da checagem de CSRF.
    post enrollment_holds_path, params: {
      authenticity_token: "token-que-nao-bate-com-a-sessao"
    }, headers: { "HTTP_REFERER" => enrollment_holds_url }

    # Não vai para o login: a sessão dele não expirou, e mandá-lo ao login faria
    # o require_no_authentication do Devise devolvê-lo à raiz trocando o aviso
    # pelo dele. Volta para onde estava, com a mensagem que descreve o caso.
    expect(response).to redirect_to(enrollment_holds_url)
    expect(flash[:alert]).to eq I18n.t("errors.invalid_form_token")
  end
end
