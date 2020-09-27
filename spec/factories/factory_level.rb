# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :level do
    sequence :name do |name|
      "Level_#{name}"
    end
    default_duration 48
  end
end
