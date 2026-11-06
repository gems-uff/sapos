# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :filled_form_field, class: Admissions::FilledFormField, aliases: [
    "admissions/filled_form_field"
  ] do
    value { "1" }
    file { nil }
    list { nil }
    filled_form
    # O campo tem de ser do template do formulario preenchido, como o modelo exige.
    form_field { association :form_field, form_template: filled_form.form_template }
  end
end
