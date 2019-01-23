# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollmentsController < ApplicationController
  authorize_resource

  active_scaffold :class_enrollment do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.list.columns = [:enrollment,:course_class, :situation, :grade, :disapproved_by_absence]
    config.create.label = :create_class_enrollment_label
    config.update.label = :update_class_enrollment_label

    config.columns[:enrollment].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:grade].options =  {:format => :i18n_number, :i18n_options => {:format_as => "grade"}}
    config.columns[:situation].form_ui = :select
    config.columns[:situation].options = {:options => ClassEnrollment::SITUATIONS, :include_blank => I18n.t("active_scaffold._select_")}

    #config.columns =
    #    [:enrollment, :course_class, :situation, :grade, :disapproved_by_absence, :obs]
    config.columns =
	[:enrollment, :course_class, :situation, :disapproved_by_absence, :grade, :obs]     

    config.actions.exclude :deleted_records
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true


  protected

  def before_update_save(record)
    return if record.grade.nil? or !record.valid? or !record.should_send_email_to_professor?
    absence_changed = record.saved_change_to_disapproved_by_absence? ? '*' : ''
    info = {
      :name => record.enrollment.to_label,
      :professor => record.course_class.professor.name,
      :course => record.course_class.label_with_course,
      :situation => "#{record.situation}#{record.saved_change_to_situation? ? '*' : ''}",
      :grade => "#{record.grade_to_view}#{record.saved_change_to_grade? ? '*' : ''}",
      :absence => ((record.attendance_to_label == "I") ? I18n.t('active_scaffold.true') : I18n.t('active_scaffold.false')) + absence_changed
    }
    message_to_professor = {
      :to => record.course_class.professor.email,
      :subject => I18n.t('notifications.class_enrollment.email_to_professor.subject', info),
      :body => I18n.t('notifications.class_enrollment.email_to_professor.body', info)
    }
    emails = [message_to_professor]
    Notifier.send_emails(notifications: emails)
  end

end 
