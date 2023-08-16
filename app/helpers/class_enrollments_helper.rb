# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ClassEnrollmentsHelper
  include EnrollmentSearchHelperConcern
  include ClassEnrollmentHelperConcern

  # EnrollmentSearchHelperConcern
  alias_method(
    :enrollment_search_column,
    :custom_enrollment_number_search_column
  )
  alias_method(
    :student_search_column,
    :custom_student_search_column
  )
  alias_method(
    :enrollment_level_search_column,
    :custom_enrollment_level_search_column
  )
  alias_method(
    :enrollment_status_search_column,
    :custom_enrollment_status_search_column
  )
  alias_method(
    :admission_date_search_column,
    :custom_admission_date_search_column
  )
  alias_method(
    :scholarship_durations_active_search_column,
    :custom_scholarship_durations_active_search_column
  )
  alias_method(
    :advisor_search_column,
    :custom_advisor_search_column
  )
  alias_method(
    :has_advisor_search_column,
    :custom_has_advisor_search_column
  )
  alias_method(
    :professor_search_column,
    :custom_professor_search_column
  )
  alias_method(
    :course_type_search_column,
    :custom_course_type_search_column
  )
  alias_method(
    :class_enrollment_justification_grade_not_count_in_gpr_form_column,
    :custom_justification_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :field_attributes,
    :custom_field_attributes
  )

  # ClassEnrollmentHelperConcern
  alias_method(
    :enrollment_form_column,
    :custom_enrollment_form_column
  )
  alias_method(
    :course_class_form_column,
    :custom_course_class_form_column
  )
  alias_method(
    :disapproved_by_absence_form_column,
    :custom_disapproved_by_absence_form_column
  )
  alias_method(
    :grade_form_column,
    :custom_grade_form_column
  )
  alias_method(
    :grade_not_count_in_gpr_form_column,
    :custom_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :obs_form_column,
    :custom_obs_form_column
  )
end
