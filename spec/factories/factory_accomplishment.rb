# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :accomplishment do
    phase
    enrollment
    after_build do |obj|
      if obj.phase.levels.empty?
        level = FactoryGirl.create(:level)
        phase_duration = FactoryGirl.create(:phase_duration, :level => level, :phase => obj.phase)
      else
        level = obj.phase.levels.first
      end
      
      obj.enrollment.level = level
    end
  end
end
