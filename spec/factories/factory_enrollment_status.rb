# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :enrollment_status do
    sequence :name do |name|
      "EnrollmentStatus_#{name}"
    end
  end
end
