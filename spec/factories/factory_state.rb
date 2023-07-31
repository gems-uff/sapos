# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :state do
    sequence :name do |name|
      "State_#{name}"
    end
    sequence :code do |code|
      "State_#{code}"
    end
    country
  end
end
