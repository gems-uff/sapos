# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# start_date e end_date da formacao academica sao colunas date, e o subformulario
# as renderiza com f.text_field. O text_field emite Date#to_s, que no Rails 7 e
# sempre ISO -- quem fazia sair dd/mm/aaaa era o monkey-patch global aposentado
# pela #625. Sem ele o campo volta "2019-08-05", e a validacao de tela ao lado
# exige DD/MM/YYYY: o formulario passa a recusar o envio por causa de um valor
# que o proprio sistema escreveu, e sem mensagem util.
RSpec.describe "Admissions scholarity date format", type: :request do
  before(:each) do
    @template = FactoryBot.create(:form_template, name: "Inscrição")
    @campo = FactoryBot.create(
      :form_field, form_template: @template, name: "Formação",
      field_type: Admissions::FormField::SCHOLARITY,
      configuration: {
        values: ["Graduação", "Mestrado"],
        statuses: ["Completo", "Em andamento"]
      }.to_json
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2",
      simple_url: "mestrado-escolaridade", form_template: @template,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
    @filled_form = FactoryBot.create(
      :filled_form, form_template: @template, is_filled: true
    )
    @campo_preenchido = FactoryBot.create(
      :filled_form_field, filled_form: @filled_form, form_field: @campo,
      value: nil
    )
    FactoryBot.create(
      :filled_form_field_scholarity,
      filled_form_field: @campo_preenchido,
      start_date: Date.new(2019, 8, 5), end_date: Date.new(2023, 12, 20)
    )
    @application = FactoryBot.create(
      :admission_application, admission_process: @process,
      filled_form: @filled_form
    )
  end

  def valores_dos_campos_de_data
    get edit_admission_apply_path(
      admission_id: @process.simple_id, id: @application.token
    )
    Nokogiri::HTML(response.body)
      .css("input[name*='scholarities_attributes'][name*='_date']")
      .map { |i| i["value"] }.compact.reject(&:empty?)
  end

  it "renders the form" do
    get edit_admission_apply_path(
      admission_id: @process.simple_id, id: @application.token
    )

    expect(response).to have_http_status(:ok)
  end

  it "renders both dates of the scholarity" do
    expect(valores_dos_campos_de_data.size).to eq 2
  end

  # E o formato que a validacao da propria tela exige.
  it "renders the dates in the Brazilian format" do
    expect(valores_dos_campos_de_data).to contain_exactly(
      "05/08/2019", "20/12/2023"
    )
  end

  it "never renders a date in the ISO format" do
    expect(valores_dos_campos_de_data).to all(
      match(%r{\A\d{2}/\d{2}/\d{4}\z})
    )
  end
end
