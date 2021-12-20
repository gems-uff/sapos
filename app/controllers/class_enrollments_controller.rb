# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollmentsController < ApplicationController
  authorize_resource

  active_scaffold :class_enrollment do |config|
    include EnrollmentSearchConcern
    include EnrollmentRequestSearchConcern
    columns = [
      :enrollment, :course_class, :situation, :disapproved_by_absence, 
      :grade, :obs, :grade_not_count_in_gpr, 
      :justification_grade_not_count_in_gpr, :grade_label
    ]
    config.columns = columns
    config.list.sorting = {:enrollment => 'ASC'}
    config.list.columns = [:enrollment,:course_class, :situation, :grade_label, :disapproved_by_absence]
    config.create.columns = columns - [:grade_label]
    config.update.columns = columns - [:grade_label]
    config.show.columns = [
      :enrollment, :course_class, :situation, :disapproved_by_absence, 
      :grade_label, :obs, :grade_not_count_in_gpr, :justification_grade_not_count_in_gpr,
    ]
    config.list.columns = [:enrollment,:course_class, :situation, :grade_label, :disapproved_by_absence]
    config.create.label = :create_class_enrollment_label
    config.update.label = :update_class_enrollment_label

    config.columns[:enrollment].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:grade].options =  {:format => :i18n_number, :i18n_options => {:format_as => "grade"}}
    config.columns[:situation].form_ui = :select
    config.columns[:situation].options = {:options => ClassEnrollment::SITUATIONS, :include_blank => I18n.t("active_scaffold._short_select_")}
    config.columns[:justification_grade_not_count_in_gpr].form_ui = :hidden
    config.columns[:justification_grade_not_count_in_gpr].label = ""

    config.columns.add :student, :enrollment_level, :enrollment_status
    config.columns.add :admission_date, :scholarship_durations_active, :advisor, :has_advisor 
    config.columns.add :year, :semester, :professor, :course_type

    config.actions.swap :search, :field_search

    add_year_search_column(config)
    config.columns[:year].includes = [ :course_class ]
    config.columns[:year].search_sql = "course_classes.year"

    add_semester_search_column(config)
    config.columns[:semester].includes = [ :course_class ]
    config.columns[:semester].search_sql = "course_classes.semester"

    config.columns[:enrollment].search_ui = :record_select

    add_student_search_column(config)
    config.columns[:student].includes = [ :enrollment ]
    
    add_enrollment_level_search_column(config)
    config.columns[:enrollment_level].includes = [ :enrollment ]

    add_enrollment_status_search_column(config)
    config.columns[:enrollment_status].includes = [ :enrollment ]

    add_admission_date_search_column(config)
    config.columns[:admission_date].includes = [ :enrollment ]

    add_scholarship_durations_active_search_column(config)
    config.columns[:scholarship_durations_active].includes = [ :enrollment ]

    add_advisor_search_column(config)
    config.columns[:advisor].includes = { enrollment: :advisements }

    add_has_advisor_search_column(config)
    config.columns[:has_advisor].includes = [ :enrollment ]

    config.columns[:course_class].search_ui = :record_select

    add_course_type_search_column(config)
    config.columns[:course_type].includes = { course_class: { course: :course_type } }

    add_professor_search_column(config)
    config.columns[:professor].includes = { course_class: :professor }

    config.field_search.columns = [
      :situation,
      :year,
      :semester,
      :enrollment,
      :student, 
      :enrollment_level, 
      :enrollment_status, 
      :admission_date, 
      :scholarship_durations_active, 
      :has_advisor,
      :advisor,
      :course_class,
      :course_type,
      :professor,
      :disapproved_by_absence,
    ]

    config.columns[:enrollment].sort_by sql: 'students.name'
    config.columns[:enrollment].includes = { enrollment: :student }

    config.columns[:course_class].sort_by sql: 'courses.name'
    config.columns[:course_class].includes =  { course_class: :course }

    config.columns[:grade_label].sort_by sql: 'grade'

    config.actions.exclude :deleted_records
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

  class <<self
    alias_method :condition_for_admission_date_column, :custom_condition_for_admission_date_column
    alias_method :condition_for_scholarship_durations_active_column, :custom_condition_for_scholarship_durations_active_column
    alias_method :condition_for_has_advisor_column, :custom_condition_for_has_advisor_column
  end


  protected

  def before_update_save(record)
    return if record.grade.nil? or !record.valid? or !record.should_send_email_to_professor?
    emails = [EmailTemplate.load_template("class_enrollments:email_to_professor").prepare_message({
      :record => record,
    })]
    Notifier.send_emails(notifications: emails)
  end

end 
