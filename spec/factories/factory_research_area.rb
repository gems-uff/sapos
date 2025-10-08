# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :research_area do
    sequence :name do |name|
      "ResearchArea_#{name}"
    end
    sequence :code do |code|
      "ResearchArea_#{code}"
    end
    available { true }
  end
end
