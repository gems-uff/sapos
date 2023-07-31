# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :deferral do
    deferral_type
    approval_date { Date.parse("2014/01/01") }
    enrollment
    after(:build) do |obj|
      if obj.deferral_type.phase.levels.empty?
        level = FactoryBot.create(:level)
        FactoryBot.create(:phase_duration, level: level, phase: obj.deferral_type.phase)
      else
        level = obj.deferral_type.phase.levels.first
      end
      obj.enrollment.level = level
    end
  end
end
