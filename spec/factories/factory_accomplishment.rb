# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :accomplishment do
    phase
    enrollment
    after(:build) do |obj|
      if obj.conclusion_date.nil?
        obj.conclusion_date = Date.today
      end
      if obj.phase.levels.empty?
        level = FactoryBot.create(:level)
        phase_duration = FactoryBot.create(:phase_duration, :level => level, :phase => obj.phase)
      else
        level = obj.phase.levels.first
      end
      
      obj.enrollment.level = level
    end
  end
end
