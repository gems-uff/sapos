# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :scholarship_duration do
    enrollment
    scholarship
    start_date { 2.days.ago }
    end_date { 2.days.from_now }
    before(:create) do |scholarship_duration|
      scholarship_duration.scholarship.level = scholarship_duration.enrollment.level
    end
  end
end
