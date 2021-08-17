# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module CourseClassesHelper
  include PdfHelper
  include CourseClassesPdfHelper

  def permit_rs_browse_params
    [:page, :update, :utf8]
  end

  def name_form_column(record, options)
    options.merge!(disabled: true) if current_user.role_id == Role::ROLE_PROFESSOR
    text_field :record, :name, options.merge!(class: "name-input text-input", autocomplete: "off", maxlength: "255", size: "30")
  end

  def course_form_column(record, options)
    options.merge!(disabled: true) if current_user.role_id == Role::ROLE_PROFESSOR
    record_select_field :course, record.course || Course.new, options.merge!(class: "text-input")
  end

  def professor_form_column(record, options)
    options.merge!(disabled: true) if current_user.role_id == Role::ROLE_PROFESSOR
    record_select_field :professor, record.professor || Professor.new, options.merge!(class: "text-input")
  end

  def year_form_column(record, options)
    options.merge!(disabled: true) if current_user.role_id == Role::ROLE_PROFESSOR
    select :record, :year, options_for_select(YearSemester.selectable_years, record.year), {:include_blank => true}, options
  end

  def semester_form_column(record, options)
    options.merge!(disabled: true) if current_user.role_id == Role::ROLE_PROFESSOR
    select :record, :semester, options_for_select(YearSemester::SEMESTERS, record.semester), {:include_blank => true}, options
  end

end
