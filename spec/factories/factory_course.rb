# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course do
    course_type
    sequence :name do |name|
      "Course_#{name}"
    end
    sequence :code do |code|
      "#{code}"
    end
    credits 10
    workload 68
  end
end
