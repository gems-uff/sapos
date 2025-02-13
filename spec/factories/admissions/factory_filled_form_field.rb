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
    form_field
  end
end
