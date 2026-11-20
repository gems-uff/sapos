# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Numero e Data obrigatorios em branco (issue #770): o servidor so confere o
# formato; a obrigatoriedade fica com o atributo required do navegador.
RSpec.describe Admissions::FilledFormField, "obrigatoriedade de Numero e Data", type: :model do
  def erros(tipo, valor)
    template = FactoryBot.create(:form_template)
    campo = FactoryBot.create(:form_field, form_template: template, field_type: tipo,
      configuration: JSON.dump("required" => true))
    formulario = FactoryBot.create(:filled_form, form_template: template)
    preenchido = Admissions::FilledFormField.new(filled_form: formulario, form_field: campo, value: valor)
    preenchido.valid?
    preenchido.errors.full_messages
  end

  it "controle: Texto obrigatorio em branco e recusado" do
    expect(erros(Admissions::FormField::STRING, "")).not_to be_empty
  end

  it "controle: Numero e Data preenchidos passam" do
    expect(erros(Admissions::FormField::NUMBER, "7")).to be_empty
    expect(erros(Admissions::FormField::DATE, "10/05/2024")).to be_empty
  end

  it "recusa Numero obrigatorio em branco", pending: "issue #770" do
    expect(erros(Admissions::FormField::NUMBER, "")).not_to be_empty
  end

  it "recusa Data obrigatoria em branco", pending: "issue #770" do
    expect(erros(Admissions::FormField::DATE, "")).not_to be_empty
  end
end
