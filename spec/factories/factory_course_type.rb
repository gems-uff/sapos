# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :course_type do
    sequence :name do |name|
      "CourseType_#{name}"
    end
    allow_multiple_classes { true }
  end
end
