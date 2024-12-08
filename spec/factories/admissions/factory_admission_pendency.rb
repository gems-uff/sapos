# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_pendency, class: Admissions::AdmissionPendency, aliases: [
    "admissions/admission_pendency"
  ] do
    admission_phase
    admission_application
    mode { Admissions::AdmissionPendency::SHARED }
    status { Admissions::AdmissionPendency::PENDENT }
  end
end
