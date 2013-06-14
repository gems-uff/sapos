# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phase_duration do
    phase
    level
    deadline_semesters 1
    deadline_months 1
    deadline_days 1
  end
end
