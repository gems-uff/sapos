# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

FactoryBot.define do
  factory :enrollment_hold do
    enrollment
    year { YearSemester.current.year }
    semester { YearSemester.current.semester }
    number_of_semesters { 1 }
  end
end
