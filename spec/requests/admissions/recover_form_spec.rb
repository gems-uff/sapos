# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O codigo de identificacao e a credencial da inscricao. Quando a recuperacao
# falha, o formulario tem de voltar preenchido -- mas pelo flash, nao pela query
# string: URL vai para o log de acesso do servidor, para o historico do
# navegador e para o link que o candidato compartilha ao pedir ajuda.
#
# O caso que mais importa nao e o erro de digitacao: quando o captcha expira, o
# token esta CORRETO e mesmo assim ia para a URL.
RSpec.describe "Admissions recuperacao de inscricao", type: :request do
  before(:each) do
    template = FactoryBot.create(:form_template, name: "Inscrição")
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026/2", simple_url: "mestrado-2026-2",
      form_template: template, require_session: true,
      start_date: Date.today - 10.days,
      end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
    @application = FactoryBot.create(
      :admission_application, admission_process: @process,
      email: "candidato@example.com",
      filled_form: FactoryBot.create(
        :filled_form, form_template: template, is_filled: true
      )
    )
  end

  def recuperar(token:, email:)
    post find_admissions_path, params: {
      admissions_admission_application: { token: token, email: email }
    }
  end

  context "quando a recuperacao falha" do
    it "nao repete o codigo nem o e-mail na URL do redirect" do
      recuperar(token: @application.token, email: "outro@example.com")

      expect(response).to have_http_status(:redirect)
      expect(response.headers["Location"]).not_to include(@application.token)
      expect(response.headers["Location"]).not_to include("outro%40example.com")
      expect(response.headers["Location"]).not_to include("token")
      expect(response.headers["Location"]).not_to include("email")
    end

    it "ainda devolve o formulario preenchido, pelo flash" do
      recuperar(token: "CODIGO-QUE-NAO-EXISTE", email: "candidato@example.com")
      follow_redirect!

      expect(response.body).to include("candidato@example.com")
      expect(response.body).to include("CODIGO-QUE-NAO-EXISTE")
    end

    it "avisa o candidato do que houve" do
      recuperar(token: "CODIGO-QUE-NAO-EXISTE", email: "candidato@example.com")

      expect(flash[:alert]).to eq I18n.t("errors.admissions.application_not_found")
    end
  end

  context "quando a recuperacao funciona" do
    it "leva o candidato para a inscricao" do
      recuperar(token: @application.token, email: @application.email)

      expect(response).to redirect_to(admission_apply_path(
        admission_id: @process.simple_id, id: @application.token
      ))
    end
  end
end
