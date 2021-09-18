# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequestsController < ApplicationController
  authorize_resource
  helper :course_classes

  active_scaffold :"enrollment_request" do |config|
    config.columns << :status
    config.list.sorting = {:year => 'DESC', :semester => 'DESC', :enrollment => 'ASC'}
    config.list.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at]
    config.update.columns = [:class_enrollment_requests, :enrollment_request_comments]
    config.show.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at, :class_enrollment_requests, :enrollment_request_comments]
    
    config.update.link.label = "<i title='#{I18n.t('enrollment_request.validate.link')}' class='fa fa-check-square-o'></i>".html_safe
    config.update.hide_nested_column = false
    config.update.refresh_list = true
    config.actions.exclude :deleted_records, :delete, :create
  end
  record_select :per_page => 10, :search_on => [:year, :semester, :enrollment], :order_by => 'year DESC, semester DESC', :full_text_search => true
  
  protected

  def before_update_save(record)
    @comment = nil
    message = params[:record][:comment_message]
    changed = false
    changed ||= record.changed? || record.class_enrollment_requests.any? { |cer| cer.changed? }
    if message.present?
      @comment = EnrollmentRequestComment.new(message: message, user: current_user)
      changed = true
    end
    if changed && record.errors.none?
      record.last_staff_change_at = Time.current
      record.enrollment_request_comments << @comment if @comment.present?
      emails = [EmailTemplate.load_template("enrollment_requests:email_to_student").prepare_message({
        :record => record,
        :student_enrollment_url => student_enroll_url(id: record.enrollment.id, year: record.year, semester: record.semester)
      })]
      Notifier.send_emails(notifications: emails)
    end
  end 
end
