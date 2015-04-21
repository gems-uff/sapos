# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phase_completion do
    enrollment_id 1
    phase_id 1
    due_date "2014-01-18 16:47:49"
    completion_date "2014-01-18 16:47:49"
  end
end
