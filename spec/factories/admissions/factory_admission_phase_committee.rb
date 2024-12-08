# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_phase_committee, class: Admissions::AdmissionPhaseCommittee, aliases: [
    "admissions/admission_phase_committee"
  ] do
    admission_phase
    admission_committee
  end
end
