# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :admission_process_ranking, class: Admissions::AdmissionProcessRanking, aliases: [
    "admissions/admission_process_ranking"
  ] do
    ranking_config
    admission_process
  end
end
