# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :ranking_group, class: Admissions::RankingGroup, aliases: [
    "admissions/ranking_group"
  ] do
    ranking_config
    name { "AC"}
  end
end
