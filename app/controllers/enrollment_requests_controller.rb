# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequestsController < ApplicationController
  include EnrollmentSearchConcern
  include EnrollmentRequestSearchConcern
  authorize_resource
  helper :course_classes

  active_scaffold :"enrollment_request" do |config|

    config.action_links.add 'help',
      label: I18n.t('enrollment_request.actions.help'),
      type: :collection,
      keep_open: false

    config.columns.add :status, :student, :enrollment_level, :enrollment_status
    config.columns.add :admission_date, :scholarship_durations_active, :advisor, :has_advisor 
    config.list.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at]
    config.update.columns = [:class_enrollment_requests, :enrollment_request_comments]
    config.show.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at, :class_enrollment_requests, :enrollment_request_comments]
    
    config.actions.swap :search, :field_search
    
    add_year_search_column(config)
    add_semester_search_column(config)

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
    config.columns[:advisor].includes = { :enrollment => :advisements }

    add_has_advisor_search_column(config)
    config.columns[:has_advisor].includes = [ :enrollment ]

    config.columns[:status].search_sql = ""
    config.columns[:status].search_ui = :select
    config.columns[:status].options = { options: ClassEnrollmentRequest::STATUSES,
                                        default: ClassEnrollmentRequest::REQUESTED,
                                        include_blank: I18n.t("active_scaffold._select_")}

    config.field_search.columns = [
      :status,
      :year,
      :semester,
      :enrollment, 
      :student, 
      :enrollment_level, 
      :enrollment_status, 
      :admission_date, 
      :scholarship_durations_active, 
      :has_advisor,
      :advisor
    ]

    config.columns[:enrollment].sort_by sql: 'students.name'
    config.columns[:enrollment].includes = { enrollment: :student }

    config.list.sorting = {:year => 'DESC', :semester => 'DESC', :enrollment => 'ASC'}


    config.update.link.label = "<i title='#{I18n.t('enrollment_request.validate.link')}' class='fa fa-check-square-o'></i>".html_safe
    config.update.hide_nested_column = false
    config.update.refresh_list = true
    config.actions.exclude :deleted_records, :delete, :create
  end
  record_select :per_page => 10, :search_on => [:year, :semester, :enrollment], :order_by => 'year DESC, semester DESC', :full_text_search => true
  
  class <<self
    alias_method :condition_for_admission_date_column, :custom_condition_for_admission_date_column
    alias_method :condition_for_scholarship_durations_active_column, :custom_condition_for_scholarship_durations_active_column
    alias_method :condition_for_has_advisor_column, :custom_condition_for_has_advisor_column
  end

  def self.condition_for_status_column(column, value, like_pattern)
    custom_condition_for_status(value, 'enrollment_requests.id in', 'enrollment_requests.id not in', '')
  end



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

  def help
    raise CanCan::AccessDenied.new if cannot? :read, ClassEnrollmentRequest
    respond_to_action(:help)
  end

  def help_respond_to_html
    render(:action => 'help')
  end
  
  def help_respond_to_js
    render(:partial => 'shared_help')
  end
end
