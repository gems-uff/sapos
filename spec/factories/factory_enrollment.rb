# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :enrollment do
    student
    level
    enrollment_status
    entrance_exam_result I18n.translate("activerecord.attributes.enrollment.entrance_exam_results.firstplace")
    sequence :enrollment_number do |number|
      number
    end
    admission_date YearSemester.current.semester_begin
  end
end
