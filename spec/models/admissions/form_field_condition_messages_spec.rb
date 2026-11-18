# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Mensagens da condicao de campo de formula. O erro de modo em branco e gerado
# como condition_blank_mode_error, mas o pt-BR traduz condition_blank_modo_error:
# a mensagem sai "Translation missing".
RSpec.describe Admissions::FormField, "mensagens da condicao", type: :model do
  def mensagens(condicao)
    template = FactoryBot.create(:form_template, template_type: Admissions::FormTemplate::CONSOLIDATION_FORM)
    campo = FactoryBot.build(
      :form_field, form_template: template, field_type: Admissions::FormField::CODE,
      configuration: JSON.dump("template_type" => "Liquid", "code" => "1", "condition" => condicao)
    )
    campo.valid?
    campo.errors.full_messages.join(" | ")
  end

  # Controle: a mensagem do campo em branco esta traduzida.
  it "explica o campo de condicao em branco" do
    expect(mensagens("mode" => Admissions::FormCondition::CONDITION, "field" => ""))
      .to include("Campo de condição não pode ficar em branco")
  end

  it "explica o modo de condicao em branco", pending: "issue #736" do
    texto = mensagens("mode" => "")

    expect(texto).to include("Modo de condição não pode ficar em branco")
    expect(texto).not_to include("Translation missing")
  end
end
