# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Caminhos do lado do candidato que nenhum exemplo percorria (#720): a tela do
# processo com sessao repreenchida pela recuperacao, a recusa do captcha na
# inscricao e na recuperacao, o acesso direto ao formulario de processo com
# sessao, o codigo de inscricao inexistente e a edicao depois do prazo.
RSpec.describe "Acesso do candidato a inscricao", type: :request do
  before(:each) do
    @template = FactoryBot.create(:form_template, name: "Inscricao")
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado Acesso", simple_url: "mestrado-acesso",
      form_template: @template, require_session: true,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  def inscricao(processo, email: "candidato.acesso@example.com")
    FactoryBot.create(
      :admission_application, admission_process: processo, email:,
      filled_form: FactoryBot.create(:filled_form, form_template: processo.form_template, is_filled: true)
    )
  end

  describe "tela do processo com sessao" do
    it "repreenche e abre a recuperacao quando o link traz o e-mail" do
      get admission_path(id: @process.simple_id), params: { email: "link.recuperacao@example.com" }

      expect(response).to have_http_status(:ok)
      html = Nokogiri::HTML(response.body)
      expect(html.at_css("#new-admission")["style"]).to include("display: none;")
      expect(html.at_css("#edit-admission")["style"]).not_to include("display: none;")
      expect(response.body).to include('value="link.recuperacao@example.com"')
    end

    it "volta repreenchida, pelo flash, quando a recuperacao a partir dela falha" do
      post find_admissions_path, params: {
        admissions_admission_application: {
          token: "CODIGO-INEXISTENTE", email: "candidato.acesso@example.com", _source: @process.simple_id,
        },
      }

      expect(response).to redirect_to(admission_path(id: @process.simple_id))
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("CODIGO-INEXISTENTE")
      expect(response.body).to include(I18n.t("errors.admissions.application_not_found"))
    end
  end

  describe "captcha recusado" do
    before(:each) do
      allow(Rails.application.config).to receive(:should_use_recaptcha).and_return(true)
      allow_any_instance_of(Admissions::AdmissionsController)
        .to receive(:verify_recaptcha).and_return(false)
      allow_any_instance_of(ActionView::Base).to receive(:recaptcha_tags).and_return("")
    end

    it "na inscricao nova, volta para a tela do processo sem gravar" do
      expect do
        post admission_path(id: @process.simple_id), params: {
          admissions_admission_application: { name: "Candidato", email: "captcha@example.com" },
        }
      end.not_to change { Admissions::AdmissionApplication.count }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="captcha@example.com"')
      expect(session[:admission_tokens]).to be_blank
    end

    it "na recuperacao, nem procura a inscricao e volta com o aviso" do
      app = inscricao(@process)

      post find_admissions_path, params: {
        admissions_admission_application: { token: app.token, email: app.email },
      }

      expect(response).to redirect_to(admissions_path)
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.invalid_captcha"))
      expect(session[:admission_tokens]).to be_blank
    end
  end

  describe "formulario de inscricao" do
    it "recusa o acesso direto ao formulario novo de processo com sessao" do
      get new_admission_apply_path(admission_id: @process.simple_id)

      expect(response).to redirect_to(admissions_path)
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.invalid_application"))
    end

    it "recusa codigo de inscricao inexistente" do
      get admission_apply_path(admission_id: @process.simple_id, id: "CODIGO-INEXISTENTE")

      expect(response).to redirect_to(admissions_path)
      expect(flash[:alert]).to eq(I18n.t("errors.admissions.invalid_application"))
    end

    context "depois do prazo de edicao" do
      before(:each) do
        @fechado = FactoryBot.create(
          :admission_process, name: "Mestrado Encerrado", simple_url: "mestrado-encerrado",
          form_template: @template,
          start_date: Date.today - 30.days, end_date: Date.today - 20.days,
          edit_date: Date.today - 10.days
        )
        @app = inscricao(@fechado)
      end

      it "manda a edicao de volta para a inscricao com o aviso" do
        get edit_admission_apply_path(admission_id: @fechado.simple_id, id: @app.token)

        expect(response).to redirect_to(admission_apply_path(admission_id: @fechado.simple_id, id: @app.token))
        expect(flash[:alert]).to eq(I18n.t("errors.admissions.closed_process"))
      end

      it "recusa a gravacao sem tocar a inscricao" do
        expect do
          put admission_apply_path(admission_id: @fechado.simple_id, id: @app.token),
            params: { record: { name: "Outro Nome" } }
        end.not_to change { @app.reload.name }

        expect(response).to redirect_to(admission_apply_path(admission_id: @fechado.simple_id, id: @app.token))
        expect(flash[:alert]).to eq(I18n.t("errors.admissions.closed_process"))
      end
    end
  end
end
