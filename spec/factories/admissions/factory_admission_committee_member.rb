# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_committee_member, class: Admissions::AdmissionCommitteeMember, aliases: [
    "admissions/admission_committee_member"
  ] do
    admission_committee
    user
  end
end
