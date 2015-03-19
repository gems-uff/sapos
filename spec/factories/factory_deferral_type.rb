# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :deferral_type do
    phase
    sequence :name do |i|
      "DeferralType_#{i}"
    end
    duration_semesters 0
    duration_months 0
    duration_days 1
  end
end
