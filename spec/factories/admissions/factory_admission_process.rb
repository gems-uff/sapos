# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_process, class: Admissions::AdmissionProcess, aliases: [
    "admissions/admission_process"
  ] do
    name { "Mestrado 2024.1" }
    year { 2024 }
    semester { 1 }
    start_date { Date.parse("2024/01/01") }
    end_date { Date.parse("2024/02/01") }
    form_template
  end
end
