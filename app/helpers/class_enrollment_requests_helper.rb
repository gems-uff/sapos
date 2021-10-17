# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ClassEnrollmentRequestsHelper

  include EnrollmentSearchHelperConcern

  alias_method :enrollment_search_column, :custom_enrollment_number_search_column
  alias_method :student_search_column, :custom_student_search_column
  alias_method :enrollment_level_search_column, :custom_enrollment_level_search_column
  alias_method :enrollment_status_search_column, :custom_enrollment_status_search_column
  alias_method :admission_date_search_column, :custom_admission_date_search_column
  alias_method :scholarship_durations_active_search_column, :custom_scholarship_durations_active_search_column
  alias_method :advisor_search_column, :custom_advisor_search_column
  alias_method :has_advisor_search_column, :custom_has_advisor_search_column
  alias_method :professor_search_column, :custom_professor_search_column
  alias_method :course_type_search_column, :custom_course_type_search_column

end