# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_phase_evaluation, class: Admissions::AdmissionPhaseEvaluation, aliases: [
    "admissions/admission_phase_evaluation"
  ] do
    admission_phase { create(:admission_phase, :with_member_form) }
    user
    admission_application
    filled_form
  end
end
