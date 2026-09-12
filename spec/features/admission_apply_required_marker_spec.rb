# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O formulário público de candidatura marca com asterisco vermelho o rótulo de
# todo campo obrigatório. A regra vive em custom/admissions.scss; antes dela, as
# instalações remendavam a falta com um bloco <style> dentro de campos HTML do
# template, que a sanitização do campo agora poda. Regra de CSS não aparece em
# request spec: só o estilo computado do ::after, lido no navegador, prova que
# o asterisco está lá -- e que o campo opcional não o ganha.
RSpec.describe "Admission apply: marcador de campo obrigatório", type: :feature, js: true do
  before(:each) do
    @destroy_later = []
    @template = FactoryBot.create(:form_template, name: "Inscrição")
    @destroy_later << @obrigatorio = FactoryBot.create(
      :form_field, form_template: @template, name: "Campo Obrigatório",
      field_type: Admissions::FormField::STRING,
      configuration: { required: true }.to_json
    )
    @destroy_later << @opcional = FactoryBot.create(
      :form_field, form_template: @template, name: "Campo Opcional",
      field_type: Admissions::FormField::STRING,
      configuration: { required: false }.to_json
    )
    @destroy_later << @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2", simple_url: "mestrado-marcador",
      form_template: @template,
      start_date: Date.today - 10.days,
      end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
    @destroy_later << @template
  end

  after(:each) do
    Admissions::AdmissionApplication.destroy_all
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  def after_of_label(field_name)
    page.evaluate_script(<<~JS)
      (function () {
        var label = Array.from(document.querySelectorAll("li.form-element dt label"))
          .find(function (l) { return l.textContent.trim() === #{field_name.to_json}; });
        if (!label) { return null; }
        var s = getComputedStyle(label, "::after");
        return { content: s.content, color: s.color };
      })()
    JS
  end

  it "põe asterisco vermelho no rótulo do campo obrigatório e nada no opcional" do
    visit new_admission_apply_path(admission_id: @process.simple_id)

    obrigatorio = after_of_label("Campo Obrigatório")
    expect(obrigatorio).not_to be_nil
    expect(obrigatorio["content"]).to eq('"*"')
    expect(obrigatorio["color"]).to eq("rgb(255, 0, 0)")

    opcional = after_of_label("Campo Opcional")
    expect(opcional).not_to be_nil
    expect(opcional["content"]).to eq("none")
  end
end
