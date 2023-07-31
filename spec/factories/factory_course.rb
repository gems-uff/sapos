# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :course do
    course_type
    sequence :name do |name|
      "Course_#{name}"
    end
    sequence :code do |code|
      "Code_#{code}"
    end
    credits { 10 }
    workload { 68 }
  end
end
