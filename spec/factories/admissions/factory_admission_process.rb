# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_process, class: Admissions::AdmissionProcess, aliases: [
    "admissions/admission_process"
  ] do
    name { "Mestrado 2024.1" }
    simple_url { "mestrado" }
    year { 2024 }
    semester { 1 }
    start_date { Date.parse("2024/01/01") }
    end_date { Date.parse("2024/02/01") }
    edit_date { Date.parse("2024/02/15") }
    form_template
    # letter_template
    min_letters { 0 }
    max_letters { 0 }
    allow_multiple_applications { false }
    visible { true }
    staff_can_edit { true }
    staff_can_undo { true }
    require_session { false }

    trait :with_letter_template do
      letter_template { create(:form_template, template_type: "Carta de Recomendação") }
      min_letters { nil }
      max_letters { nil }
    end
  end
end
