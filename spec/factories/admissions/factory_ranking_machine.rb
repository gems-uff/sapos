# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :ranking_machine, class: Admissions::RankingMachine, aliases: [
    "admissions/ranking_machine"
  ] do
    name { "Máquina de Ranking" }
  end
end
