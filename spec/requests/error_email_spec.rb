# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O e-mail de erro vai para uma lista de discussão e fica guardado nas caixas de
# quem a assina. Ele leva só a parte técnica: a exceção, onde ela ocorreu, o
# backtrace, o id do usuário e o id da requisição, que localiza o resto no log
# do servidor. O que identifica uma pessoa ou permite agir em nome dela -- dado
# pessoal, valor de parâmetro, conteúdo e credencial da sessão -- fica no
# servidor.
#
# O ambiente de teste não monta o middleware, então o spec registra o
# notificador de e-mail com a mesma configuração dos ambientes
# (config.x.error_email) e confere o e-mail que ele de fato monta.
RSpec.describe "E-mail de erro", type: :request do
  before(:each) do
    ActionMailer::Base.deliveries.clear
    ExceptionNotifier.register_exception_notifier(
      :email,
      Rails.application.config.x.error_email.merge(
        exception_recipients: %w[erros@example.com]
      )
    )
  end

  after(:each) do
    ExceptionNotifier.unregister_exception_notifier(:email)
  end

  def error_email
    # Criar o usuário também envia e-mail; só interessa o da lista de erros.
    mails = ActionMailer::Base.deliveries.select do |mail|
      mail.to == %w[erros@example.com]
    end
    expect(mails.size).to eq 1
    mail = mails.last
    [mail.subject, (mail.text_part || mail).body.decoded].join("\n")
  end

  def expect_no_trace_of(text, *secrets)
    secrets.compact.each do |secret|
      expect(text).not_to include(secret.to_s)
    end
  end

  def session_cookie
    cookies[Rails.application.config.session_options[:key]]
  end

  context "com usuário autenticado" do
    before(:each) do
      @user = create_confirmed_user(
        [FactoryBot.create(:role_administrador)],
        "pessoa.sintetica@example.com", "Pessoa Sintetica"
      )
      sign_in @user
    end

    # O caminho do middleware: a exceção que escapa do controller é notificada
    # com o env da requisição.
    it "leva só a parte técnica de uma exceção da requisição" do
      get enrollment_holds_path(busca: "VALOR-DA-QUERY")
      csrf = session[:_csrf_token]
      exception = begin
        raise "falha sintetica"
      rescue => e
        e
      end

      ExceptionNotifier.notify_exception(exception, env: request.env)

      text = error_email
      expect(text).to include("RuntimeError", "falha sintetica",
        "enrollment_holds#index", "user_id: #{@user.id}", request.request_id)
      expect(text).to match(/Instância\s*: #{Regexp.escape(Rails.root.to_s)}$/)
      expect(session_cookie).to be_present
      expect_no_trace_of(text,
        session_cookie, csrf, @user.authenticatable_salt,
        @user.email, @user.name, "VALOR-DA-QUERY")
    end

    # Sessão viva com token que não bate é notificada (ApplicationController
    # #notify_invalid_token).
    it "leva só a parte técnica de um token de CSRF que não bate" do
      forgery_protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      get enrollment_holds_path
      csrf = session[:_csrf_token]

      post enrollment_holds_path, params: {
        authenticity_token: "token-que-nao-bate",
        record: { observation: "VALOR-DO-FORMULARIO" }
      }, headers: { "HTTP_REFERER" => enrollment_holds_url }

      text = error_email
      expect(text).to include("InvalidAuthenticityToken",
        "user_id: #{@user.id}")
      expect_no_trace_of(text,
        session_cookie, csrf, @user.authenticatable_salt,
        @user.email, @user.name, "VALOR-DO-FORMULARIO")
    ensure
      ActionController::Base.allow_forgery_protection = forgery_protection
    end
  end

  # Todas as instâncias rodam no mesmo servidor e mandam para a mesma lista: o
  # e-mail tem de dizer de qual delas veio, também quando a exceção é
  # notificada sem requisição (Admissions::AdmissionProcessesController).
  it "diz a instância no e-mail de exceção sem requisição" do
    exception = begin
      raise "falha sem requisicao"
    rescue => e
      e
    end

    ExceptionNotifier.notify_exception(exception)

    # O backtrace desse caminho não é limpo e já traz o Rails.root; o que
    # interessa é a linha que diz a instância.
    text = error_email
    expect(text).to include("falha sem requisicao")
    expect(text).to match(/Instância\s*: #{Regexp.escape(Rails.root.to_s)}$/)
  end

  # Formulário de inscrição que o cliente deixou passar e o servidor recusou
  # (Admissions::ApplyController#update). O motivo da recusa é técnico; o que
  # o candidato preencheu, não.
  it "leva o motivo da recusa da inscrição sem o que o candidato preencheu" do
    template = FactoryBot.create(:form_template, name: "Inscrição")
    process = FactoryBot.create(
      :admission_process, name: "Processo", simple_url: "processo",
      form_template: template, min_letters: 2, max_letters: 3,
      letter_template: FactoryBot.create(:form_template, name: "Carta"),
      require_session: false,
      start_date: Date.current - 10.days, end_date: Date.current + 10.days,
      edit_date: Date.current + 20.days
    )
    application = FactoryBot.create(
      :admission_application, admission_process: process,
      email: "candidata.sintetica@example.com",
      filled_form: FactoryBot.create(
        :filled_form, form_template: template, is_filled: false
      )
    )
    blank_letter = { email: "", name: "", telephone: "" }

    put admission_apply_path(
      admission_id: process.simple_id, id: application.token
    ), params: { record: {
      name: "Candidata Sintetica",
      email: "candidata.sintetica@example.com",
      letter_requests_attributes: { "0" => blank_letter, "1" => blank_letter }
    } }

    text = error_email
    expect(text).to include("apply#update", "min_letters")
    expect(session_cookie).to be_present
    expect_no_trace_of(text,
      session_cookie, session[:_csrf_token],
      "Candidata Sintetica", "candidata.sintetica@example.com",
      # O token na URL abre a inscrição; o e-mail leva o padrão da rota.
      application.token)
    expect(text).to include("/admissions/:admission_id/apply/:id")
  end
end
