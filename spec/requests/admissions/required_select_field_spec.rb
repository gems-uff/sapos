# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Select obrigatorio so exigia preenchimento no navegador num ramo estreito da
# configuracao: com "default_check" ligado E um default fora da lista de valores,
# que vira prompt. Fora dele -- inclusive no caso comum, sem default_check --
# nada exigia. O <li> saia marcado como obrigatorio, o servidor recusava, e entre
# os dois nao havia ninguem barrando.
#
# Diferente do campo de radio, que tambem nao usa o required do HTML5 mas
# registra validacao propria em customFormValidations: ali a exigencia existe,
# so passa por outro mecanismo. No select nao havia nem um nem outro.
RSpec.describe "Admissions required select field", type: :request do
  def processo_com(simple_url, configuration)
    template = FactoryBot.create(:form_template, name: "Inscrição")
    FactoryBot.create(
      :form_field, form_template: template, name: "Cota",
      field_type: Admissions::FormField::SELECT,
      configuration: configuration.to_json
    )
    FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2",
      simple_url:, form_template: template,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  def select_do(processo)
    get new_admission_apply_path(admission_id: processo.simple_id)
    Nokogiri::HTML(response.body).css("select").find do |s|
      s["name"].to_s.end_with?("[value]")
    end
  end

  VALORES = ["Ampla concorrência", "Cotas"].freeze

  it "marks a required select as required" do
    processo = processo_com(
      "mestrado-select-obrigatorio", { values: VALORES, required: true }
    )

    expect(select_do(processo)["required"]).to be_present
  end

  # Controle. Sem ele, passar a marcar required em todo select passaria batido.
  it "leaves an optional select without the browser requirement" do
    processo = processo_com(
      "mestrado-select-opcional", { values: VALORES, required: false }
    )

    expect(select_do(processo)["required"]).to be_nil
  end

  # Controle do unico ramo que ja exigia: default fora da lista vira prompt.
  # Garante que a correcao nao troque um mecanismo pelo outro.
  it "keeps requiring the select that shows a prompt as default" do
    processo = processo_com("mestrado-select-prompt", {
      values: VALORES, required: true,
      default_check: true, default: "Selecione"
    })

    expect(select_do(processo)["required"]).to be_present
  end

  it "still refuses a blank select on the server" do
    processo = processo_com(
      "mestrado-select-servidor", { values: VALORES, required: true }
    )
    campo = processo.form_template.fields.first

    expect {
      post admission_apply_index_path(admission_id: processo.simple_id), params: {
        commit: "Enviar inscrição",
        record: {
          name: "ZZ-TESTE Candidato", email: "zzteste@ic.uff.br",
          filled_form_attributes: {
            form_template_id: processo.form_template.id,
            enable_submission: "1",
            fields_attributes: { "0" => { form_field_id: campo.id, value: "" } }
          }
        }
      }
    }.not_to change { Admissions::AdmissionApplication.count }
  end
end
