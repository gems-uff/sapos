# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

FactoryBot.define do
  factory :scholarship_suspension do
    start_date { 1.days.ago }
    end_date { 1.days.from_now }
    active { true }
    scholarship_duration
  end
end
