# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :form_template, class: Admissions::FormTemplate, aliases: [
    "admissions/form_template"
  ] do
    name { "Formulario" }
    template_type { "Formulário" }
  end
end
