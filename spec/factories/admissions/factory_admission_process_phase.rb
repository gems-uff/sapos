# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_process_phase, class: Admissions::AdmissionProcessPhase, aliases: [
    "admissions/admission_process_phase"
  ] do
    admission_process
    admission_phase
  end
end
