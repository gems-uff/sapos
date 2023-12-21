# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module CourseClassesHelper
  include PdfHelper
  include CourseClassesPdfHelper
  include ClassSchedulesPdfHelper
  include ClassEnrollmentHelperConcern

  # ClassEnrollmentHelperConcern
  alias_method(
    :class_enrollment_enrollment_form_column,
    :custom_enrollment_form_column
  )
  alias_method(
    :class_enrollment_disapproved_by_absence_form_column,
    :custom_disapproved_by_absence_form_column
  )
  alias_method(
    :class_enrollment_grade_form_column,
    :custom_grade_form_column
  )
  alias_method(
    :class_enrollment_grade_not_count_in_gpr_form_column,
    :custom_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :class_enrollment_obs_form_column,
    :custom_obs_form_column
  )
  alias_method(
    :class_enrollment_justification_grade_not_count_in_gpr_form_column,
    :custom_justification_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :field_attributes,
    :custom_field_attributes
  )

  def permit_rs_browse_params
    [:page, :update, :utf8]
  end

  def name_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    text_field :record, :name, options.merge!(
      class: "name-input text-input", autocomplete: "off",
      maxlength: "255", size: "30"
    )
  end

  def course_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    record_select_field :course, record.course || Course.new, options
  end

  def professor_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    record_select_field :professor, record.professor || Professor.new, options
  end

  def year_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    select :record, :year, options_for_select(
      YearSemester.selectable_years, record.year
    ), { include_blank: true }, options
  end

  def semester_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    select :record, :semester, options_for_select(
      YearSemester::SEMESTERS, record.semester
    ), { include_blank: true }, options
  end

  def not_schedulable_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    check_box :record, :not_schedulable, options
  end

  def obs_schedule_form_column(record, options)
    if can?(:post_grades, record) && cannot?(:update_all_fields, record)
      options[:disabled] = true
    end
    text_field :record, :obs_schedule, options.merge!(
      class: "name-input text-input", autocomplete: "off",
      maxlength: "255", size: "30"
    )
  end
end
