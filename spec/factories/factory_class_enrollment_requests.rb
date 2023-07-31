# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Read about factories at https://github.com/thoughtbot/factory_bot

# frozen_string_literal: true

FactoryBot.define do
  factory :class_enrollment_request do
    enrollment_request { nil }
    course_class { nil }
    class_enrollment { nil }
    status { ClassEnrollmentRequest::REQUESTED }
  end
end
