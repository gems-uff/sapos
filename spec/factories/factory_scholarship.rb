# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :scholarship do
    sponsor
    level
    sequence :scholarship_number do |number|
      "S#{number}"
    end
    start_date { 3.days.ago }
    end_date { 3.days.from_now }
  end
end
