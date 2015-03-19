# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

FactoryGirl.define do
  factory :scholarship do
    sponsor
    level
    sequence :scholarship_number do |number|
      number
    end
    start_date 3.days.ago
    end_date 3.days.from_now
  end
end
