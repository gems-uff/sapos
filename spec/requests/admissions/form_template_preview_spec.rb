# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A pre-visualizacao de formulario (action link fa-play da lista de
# formularios) nunca era aberta por nenhum exemplo (#720): o GET que mostra o
# formulario vazio e o POST/PATCH que valida o preenchido sem gravar nada.
RSpec.describe "Pre-visualizacao de formulario", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm.preview@ic.uff.br", "Adm"
    )
    @template = FactoryBot.create(:form_template, name: "Formulario Preview")
    @campo = FactoryBot.create(
      :form_field, form_template: @template, name: "Motivacao",
      configuration: { required: true }.to_json
    )
  end

  def preenchido(valor)
    {
      record: {
        form_template_id: @template.id,
        fields_attributes: { "0" => { form_field_id: @campo.id, value: valor } },
      },
    }
  end

  it "mostra o formulario vazio, sem aviso nem erro" do
    get preview_form_template_path(@template)

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css("form.preview")["action"]).to eq(preview_form_template_path(@template))
    expect(response.body).to include("Motivacao")
    expect(html.at_css(".messages-container .success")).to be_nil
    expect(html.at_css("#errorExplanation")).to be_nil
  end

  it "acusa o campo obrigatorio vazio no envio" do
    expect do
      post preview_form_template_path(@template), params: preenchido("")
    end.not_to change { Admissions::FilledForm.count }

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css("#errorExplanation")).to be_present
    expect(html.at_css(".messages-container .success")).to be_nil
  end

  it "confirma o formulario valido sem gravar, tambem por PATCH" do
    expect do
      patch preview_form_template_path(@template), params: preenchido("Quero estudar")
    end.not_to change { Admissions::FilledForm.count }

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css(".messages-container .success").text).to eq(
      I18n.t("active_scaffold.admissions/form_template.preview.valid")
    )
    expect(html.at_css("#errorExplanation")).to be_nil
    expect(response.body).to include("Quero estudar")
  end
end
