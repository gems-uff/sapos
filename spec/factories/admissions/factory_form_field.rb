# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :form_field, class: Admissions::FormField, aliases: [
    "admissions/form_field"
  ] do
    name { "Campo" }
    field_type { Admissions::FormField::TEXT }
    form_template
  end
end
