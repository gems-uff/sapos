# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :form_condition, class: Admissions::FormCondition, aliases: [
    "admissions/form_condition"
  ] do
    mode { Admissions::FormCondition::NONE }
    field { "a" }
    condition { "=" }
    value { "1" }
  end
end
