# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :phase_completion do
    enrollment
    phase
    due_date { "2014-01-18 16:47:49" }
    completion_date { "2014-01-18 16:47:49" }
  end
end
