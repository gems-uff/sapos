# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A rota publica do recomendador so era percorrida pelo PUT valido dos fluxos
# de ponta a ponta (workflow_com_cartas_spec.rb). Sem cobertura (#720): abrir a
# carta (GET show), gravar carta invalida, codigo de acesso inexistente e
# processo fechado.
RSpec.describe "Carta de recomendacao pela rota publica", type: :request do
  before(:each) do
    @letter_template = FactoryBot.create(:form_template, name: "Carta", template_type: "Carta de Recomendação")
    @campo = FactoryBot.create(
      :form_field, form_template: @letter_template, name: "Avaliacao do candidato",
      configuration: { required: true }.to_json
    )
    @process = FactoryBot.create(
      :admission_process, simple_url: "mestrado-cartas", letter_template: @letter_template,
      start_date: Date.current - 10.days, end_date: Date.current + 10.days
    )
    application = FactoryBot.create(:admission_application, admission_process: @process, name: "Candidata Carta")
    @carta = FactoryBot.create(
      :letter_request, admission_application: application, name: "Recomendador Um",
      filled_form: FactoryBot.create(:filled_form, form_template: @letter_template, is_filled: false)
    )
  end

  def carta_path(token = @carta.access_token)
    admission_letter_path(admission_id: @process.simple_id, id: token)
  end

  def enviar(valor)
    put carta_path, params: {
      record: {
        name: @carta.name, email: @carta.email,
        filled_form_attributes: {
          id: @carta.filled_form.id, enable_submission: "1",
          fields_attributes: { "0" => { form_field_id: @campo.id, value: valor } },
        },
      },
    }
  end

  it "abre a carta com quem pediu, para quem e o campo do formulario" do
    get carta_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Candidata Carta")
    expect(response.body).to include("Recomendador Um")
    expect(response.body).to include("Avaliacao do candidato")
    expect(response.body).not_to include(I18n.t("admissions.letters.show.letter_sent"))
  end

  it "devolve a carta invalida na mesma tela, sem marca-la como enviada" do
    enviar("")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Avaliacao do candidato")
    expect(response.body).not_to include(I18n.t("admissions.letters.show.letter_sent"))
    expect(@carta.reload.filled_form.is_filled).to be(false)
  end

  it "recusa e-mail do recomendador sem formato" do
    @carta.email = "nao-e-mail"
    enviar("Recomendo")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Avaliacao do candidato")
    expect(@carta.reload.filled_form.is_filled).to be(false)
  end

  # Controle do anterior: a mesma carta, com o campo preenchido, e aceita.
  it "aceita a carta valida e volta para a lista de processos" do
    enviar("Recomendo")

    expect(response).to redirect_to(admissions_path)
    expect(flash[:notice]).to eq(I18n.t("admissions.letters.update.success"))
    expect(@carta.reload.filled_form.is_filled).to be(true)
  end

  it "recusa codigo de acesso inexistente" do
    get carta_path("CODIGO-INEXISTENTE")

    expect(response).to redirect_to(admissions_path)
    expect(flash[:alert]).to eq(I18n.t("errors.admissions.invalid_letter"))
  end

  it "recusa a carta de processo fechado para inscricao e para edicao" do
    @process.update!(start_date: Date.current - 30.days, end_date: Date.current - 20.days, edit_date: Date.current - 10.days)

    get carta_path

    expect(response).to redirect_to(admissions_path)
    expect(flash[:alert]).to eq(I18n.t("errors.admissions.closed_process"))
  end
end
