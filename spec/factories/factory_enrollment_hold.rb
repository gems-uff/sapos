# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment_hold do
    enrollment
    year { 1.year.from_now.year }
    semester { YearSemester.current.semester }
    number_of_semesters { 1 }
  end
end
