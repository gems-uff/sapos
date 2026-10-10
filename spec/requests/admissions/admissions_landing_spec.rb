# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Porta de entrada do candidato (#681): a lista de editais abertos, a página do
# edital que pede nome e e-mail antes do formulário, a criação da inscrição e a
# recuperação por e-mail de quem esqueceu o código.
RSpec.describe "Admissions::Admissions: entrada do candidato", type: :request do
  before(:each) do
    @template = create_admission_template("Inscrição", { "nota" => Admissions::FormField::NUMBER })
    @open = FactoryBot.create(
      :admission_process, name: "Mestrado Aberto", simple_url: "landing-aberto",
      form_template: @template, require_session: true,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days, edit_date: Date.today + 20.days
    )
    @hidden = FactoryBot.create(
      :admission_process, name: "Edital Oculto", simple_url: "landing-oculto",
      form_template: @template, visible: false,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days, edit_date: Date.today + 20.days
    )
    @closed = create_closed_admission_process(@template, simple_url: "landing-fechado")
  end

  def params_for(**attrs)
    { admissions_admission_application: attrs }
  end

  describe "GET index" do
    it "lista os editais abertos e visíveis" do
      get admissions_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mestrado Aberto")
      expect(response.body).not_to include("Edital Oculto")
      expect(response.body).not_to include(@closed.name)
    end

    it "repreenche o formulário de recuperação pela query string" do
      get admissions_path, params: { email: "x@example.com", token: "ABC" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("x@example.com")
    end
  end

  describe "GET show" do
    it "mostra o formulário de nome e e-mail quando o edital exige sessão" do
      get admission_path(@open.simple_url)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(@open.title)
    end

    it "vai direto para a inscrição quando o edital não exige sessão" do
      @open.update!(require_session: false)
      get admission_path(@open.simple_url)
      expect(response).to redirect_to(new_admission_apply_path(admission_id: @open.simple_id))
    end

    it "aceita o id numérico e recusa edital fechado" do
      get admission_path(@open.id)
      expect(response).to have_http_status(:ok)

      get admission_path(@closed.simple_url)
      expect(response).to redirect_to(admissions_path)
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.invalid_process"))
    end
  end

  describe "POST create" do
    it "cria a inscrição, guarda o código na sessão e leva ao formulário" do
      expect {
        post admission_path(@open.simple_url), params: params_for(name: "Ana", email: "ana@example.com")
      }.to change { Admissions::AdmissionApplication.count }.by(1)

      application = Admissions::AdmissionApplication.last
      expect(application.admission_process).to eq(@open)
      expect(application.filled_form.is_filled).to be false
      expect(response).to redirect_to(edit_admission_apply_path(admission_id: @open.simple_id, id: application.token))
      expect(session[:admission_tokens]).to include(application.token)
    end

    it "reaproveita a inscrição não enviada do mesmo e-mail" do
      existing = create_application(@open, name: "Ana", email: "ana@example.com", filled: false)
      expect {
        post admission_path(@open.simple_url), params: params_for(name: "Ana Maria", email: "ana@example.com")
      }.not_to change { Admissions::AdmissionApplication.count }
      expect(existing.reload.name).to eq("Ana Maria")
      expect(response).to redirect_to(edit_admission_apply_path(admission_id: @open.simple_id, id: existing.token))
    end

    it "recusa novo cadastro de e-mail já inscrito quando o edital não permite repetir" do
      create_application(@open, name: "Ana", email: "ana@example.com")
      post admission_path(@open.simple_url), params: params_for(name: "Ana", email: "ana@example.com")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("errors.admissions.application_exists"))
    end

    it "cria outra inscrição para o mesmo e-mail quando o edital permite" do
      @open.update!(allow_multiple_applications: true)
      create_application(@open, name: "Ana", email: "ana@example.com")
      expect {
        post admission_path(@open.simple_url), params: params_for(name: "Ana", email: "ana@example.com")
      }.to change { Admissions::AdmissionApplication.count }.by(1)
    end

    it "volta ao formulário com os erros quando falta o nome" do
      post admission_path(@open.simple_url), params: params_for(name: "", email: "ana@example.com")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(@open.title)
    end
  end

  describe "POST find com 'forgot'" do
    before(:each) do
      allow(Notifier).to receive(:send_emails)
      @ana = create_application(@open, name: "Ana", email: "ana@example.com")
    end

    it "manda os códigos por e-mail e volta para a lista com aviso" do
      post find_admissions_path, params: params_for(token: "forgot", email: "ana@example.com")

      expect(Notifier).to have_received(:send_emails) do |notifications:|
        expect(notifications.size).to eq(1)
        expect(notifications[0][:to]).to eq("ana@example.com")
        expect(notifications[0][:body]).to include(@ana.token)
      end
      expect(response).to redirect_to(admissions_url(params: { email: "ana@example.com" }))
      expect(flash[:notice]).to eq(I18n.t("admissions.admissions.find_by_email.success", email: "ana@example.com", count: 1))
    end

    it "restringe ao edital de origem, inclusive pelo id numérico" do
      other = FactoryBot.create(
        :admission_process, name: "Doutorado", simple_url: "landing-outro", form_template: @template,
        start_date: Date.today - 10.days, end_date: Date.today + 10.days, edit_date: Date.today + 20.days
      )
      create_application(other, name: "Ana", email: "ana@example.com")

      post find_admissions_path, params: params_for(token: "forgot", email: "ana@example.com", _source: @open.simple_url)
      expect(response).to redirect_to(admission_url(id: @open.simple_url, params: { email: "ana@example.com" }))
      expect(flash[:notice]).to eq(I18n.t("admissions.admissions.find_by_email.success", email: "ana@example.com", count: 1))

      post find_admissions_path, params: params_for(token: "forgot", email: "ana@example.com", _source: @open.id.to_s)
      expect(response).to redirect_to(admission_url(id: @open.id.to_s, params: { email: "ana@example.com" }))
    end

    it "avisa quando não há inscrição para o e-mail, na lista e no edital" do
      post find_admissions_path, params: params_for(token: "forgot", email: "ninguem@example.com")
      expect(response).to redirect_to(admissions_path)
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.application_not_found"))

      post find_admissions_path, params: params_for(token: "forgot", email: "ana@example.com", _source: @closed.simple_url)
      expect(response).to redirect_to(admission_path(id: @closed.simple_url))
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.application_process_not_found"))
    end
  end

  describe "POST find com código" do
    it "abre a inscrição enviada e guarda o código na sessão" do
      ana = create_application(@open, name: "Ana", email: "ana@example.com")
      post find_admissions_path, params: params_for(token: ana.token, email: "ana@example.com", _source: @open.simple_url)
      expect(response).to redirect_to(admission_apply_path(admission_id: @open.simple_id, id: ana.token))
      expect(session[:admission_tokens]).to include(ana.token)
    end

    it "leva a inscrição não enviada para a edição" do
      ana = create_application(@open, name: "Ana", email: "ana@example.com", filled: false)
      post find_admissions_path, params: params_for(token: ana.token, email: "ana@example.com")
      expect(response).to redirect_to(edit_admission_apply_path(admission_id: @open.simple_id, id: ana.token))
    end

    it "recusa código de outro edital" do
      ana = create_application(@open, name: "Ana", email: "ana@example.com")
      post find_admissions_path, params: params_for(token: ana.token, email: "ana@example.com", _source: @closed.simple_url)
      expect(response).to redirect_to(admission_path(id: @closed.simple_url))
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.application_process_not_found"))
    end
  end
end
