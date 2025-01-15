# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_phase_result, class: Admissions::AdmissionPhaseResult, aliases: [
    "admissions/admission_phase_result"
  ] do
    admission_phase { create(:admission_phase, :with_shared_form) }
    admission_application
    filled_form
    mode { Admissions::AdmissionPhaseResult::SHARED }
  end
end
