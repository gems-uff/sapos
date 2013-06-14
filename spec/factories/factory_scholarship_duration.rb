# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :scholarship_duration do
    enrollment
    scholarship
    start_date 2.days.ago
    end_date 2.days.from_now
  end
end
