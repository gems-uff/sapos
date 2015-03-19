# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :allocation do
    day { I18n.translate("date.day_names").first }
    course_class
    start_time 10
    end_time 12
  end
end
