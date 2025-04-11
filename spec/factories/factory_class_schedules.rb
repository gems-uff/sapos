# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :class_schedule do
    year { 1 }
    semester { 1 }
    enrollment_start { "2021-07-27 17:02:22" }
    enrollment_end { "2021-07-27 17:02:22" }
    enrollment_adjust { "2021-07-27 17:02:22" }
    enrollment_insert { "2021-07-27 17:02:22" }
    enrollment_remove { "2021-07-27 17:02:22" }
    grade_pendency { "2021-07-27 17:02:22" }
  end
end
