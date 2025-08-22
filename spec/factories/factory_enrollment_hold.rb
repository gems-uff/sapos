# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment_hold do
    association :enrollment, factory: :enrollment, admission_date: 2.year.ago.to_date
    year { YearSemester.current.year }
    semester { YearSemester.current.semester }
    number_of_semesters { 1 }
  end
end
