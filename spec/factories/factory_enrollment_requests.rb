# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment_request do
    year { 1 }
    semester { 1 }
    enrollment
    last_student_change_at { "2021-08-16 23:19:51" }
    student_view_at { "2021-08-16 23:19:51" }
    last_staff_change_at { "2021-08-16 23:19:51" }
  end
end
