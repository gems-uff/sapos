# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollmentsController < ApplicationController
  authorize_resource

  active_scaffold :class_enrollment do |config|
    
    columns = [
      :enrollment, :course_class, :situation, :disapproved_by_absence, :grade, :grade_not_count_in_gpr, 
      :justification_grade_not_count_in_gpr, :obs, :grade_label
    ]
    config.columns = columns
    config.list.sorting = {:enrollment => 'ASC'}
    config.list.columns = [:enrollment,:course_class, :situation, :grade_label, :disapproved_by_absence]
    config.create.columns = columns - [:grade_label]
    config.update.columns = columns - [:grade_label]
    config.list.columns = [:enrollment,:course_class, :situation, :grade_label, :disapproved_by_absence]
    config.create.label = :create_class_enrollment_label
    config.update.label = :update_class_enrollment_label

    config.columns[:enrollment].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:grade].options =  {:format => :i18n_number, :i18n_options => {:format_as => "grade"}}
    config.columns[:situation].form_ui = :select
    config.columns[:situation].options = {:options => ClassEnrollment::SITUATIONS, :include_blank => I18n.t("active_scaffold._short_select_")}
    
    config.actions.exclude :deleted_records
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true


  protected

  def before_update_save(record)
    return if record.grade.nil? or !record.valid? or !record.should_send_email_to_professor?
    emails = [EmailTemplate.load_template("class_enrollments:email_to_professor").prepare_message({
      :record => record,
    })]
    Notifier.send_emails(notifications: emails)
  end

end 
