# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_application, class: Admissions::AdmissionApplication, aliases: [
    "admissions/admission_application"
  ] do
    name { "ana" }
    email { "ana@email.com" }
    admission_process
    filled_form

    trait :in_process_with_letters do
      admission_process { create(:admission_process, :with_letter_template) }
    end
  end
end
