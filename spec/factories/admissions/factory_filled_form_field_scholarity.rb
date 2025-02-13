# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :filled_form_field_scholarity, class: Admissions::FilledFormFieldScholarity, aliases: [
    "admissions/filled_form_field_scholarity"
  ] do
    filled_form_field
    level { "Graduação" }
    status { "Completo" }
    institution { "UFF" }
    course { "Computação" }
    location { "Niteroi/RJ" }
    grade { "9" }
    grade_interval { "0..10" }
    start_date { 5.years.ago }
    end_date { 1.year.ago }
  end
end
