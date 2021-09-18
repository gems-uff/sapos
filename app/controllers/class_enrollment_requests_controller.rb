# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollmentRequestsController < ApplicationController
  authorize_resource
  
  active_scaffold :"class_enrollment_request" do |config|

    config.action_links.add 'show_effect',
      label: I18n.t('class_enrollment_request.actions.effect'),
      ignore_method:  :hide_effect_actions?,
      type: :collection,
      keep_open: false

    base_member = { type: :member, keep_open: false, position: false, crud_type: :update, method: :put, refresh_list: true }
    config.action_links.add "set_invalid",
      label:  "<i title='#{I18n.t('class_enrollment_request.invalid.label')}' class='fa fa-times-circle'></i>".html_safe,
      ignore_method: :hide_validate_actions?,
      security_method: :set_invalid_security_method,
      confirm: I18n.t('class_enrollment_request.invalid.confirm'),
      **base_member

    config.action_links.add "set_requested",
      label:  "<i title='#{I18n.t('class_enrollment_request.requested.label')}' class='fa fa-question-circle'></i>".html_safe,
      ignore_method: :hide_validate_actions?,
      security_method: :set_requested_security_method,
      confirm: I18n.t('class_enrollment_request.requested.confirm'),
      **base_member

    config.action_links.add "set_valid",
      label:  "<i title='#{I18n.t('class_enrollment_request.valid.label')}' class='fa fa-check-circle'></i>".html_safe,
      ignore_method: :hide_validate_actions?,
      security_method: :set_valid_security_method,
      confirm: I18n.t('class_enrollment_request.valid.confirm'),
      **base_member

    config.action_links.add 'set_effected',
      label:  "<i title='#{I18n.t('class_enrollment_request.effected.label')}' class='fa fa-plus-circle'></i>".html_safe,
      ignore_method: :hide_effect_actions?,
      security_method: :set_effected_security_method,
      confirm: I18n.t('class_enrollment_request.effected.confirm'),
      **base_member

    config.list.sorting = {:enrollment_request => 'ASC'}
    columns = [:enrollment_request, :course_class, :status, :class_enrollment]
    config.list.columns = [:enrollment_request, :course_class, :status, :parent_status, :class_enrollment, :allocations, :professor]
    config.show.columns = [:enrollment_request, :course_class, :status, :parent_status, :class_enrollment, :allocations, :professor]
    config.create.columns = columns
    config.update.columns = columns

    config.columns.add :enrollment_number, :student, :enrollment_level, :enrollment_status, :admission_date, :scholarship_durations_active, :advisor 
    config.columns.add :year, :semester
    config.columns.add :parent_status, :professor

    config.create.label = :create_class_enrollment_request_label
    config.update.label = :update_class_enrollment_request_label
    config.actions.swap :search, :field_search

    config.columns[:class_enrollment].actions_for_association_links.delete :new

    config.field_search.columns = [
      :status,
      :parent_status,
      :year,
      :semester,
      :enrollment_number, 
      :student, 
      :enrollment_level, 
      :enrollment_status, 
      :admission_date, 
      :scholarship_durations_active, 
      :advisor,
      :course_class,
      :professor
    ]

    config.columns[:year].includes = [:enrollment_request]
    config.columns[:year].search_sql = "enrollment_requests.year"
    config.columns[:year].search_ui = :select
    config.columns[:year].options = {
      :options => YearSemester.selectable_years,
      :include_blank => true,
      :default => nil
    }

    config.columns[:semester].includes = [:enrollment_request]
    config.columns[:semester].search_sql = "enrollment_requests.semester"
    config.columns[:semester].search_ui = :select
    config.columns[:semester].options = {
      :options => YearSemester::SEMESTERS,
      :include_blank => true,
      :default => nil
    }

    config.columns[:enrollment_number].includes = [:enrollment_request]
    config.columns[:enrollment_number].search_sql = "enrollment_requests.enrollment_id"
    config.columns[:enrollment_number].search_ui = :select

    config.columns[:student].includes = { :enrollment_request => :enrollment }
    config.columns[:student].search_sql = "enrollments.student_id"
    config.columns[:student].search_ui = :select
    
    config.columns[:enrollment_level].includes = { :enrollment_request => :enrollment }
    config.columns[:enrollment_level].search_sql = "enrollments.level_id"
    config.columns[:enrollment_level].search_ui = :select

    config.columns[:enrollment_status].includes = { :enrollment_request => :enrollment }
    config.columns[:enrollment_status].search_sql = "enrollments.enrollment_status_id"
    config.columns[:enrollment_status].search_ui = :select


    config.columns[:admission_date].options = {:format => :monthyear}
    config.columns[:admission_date].includes = { :enrollment_request => :enrollment }
    config.columns[:admission_date].search_sql = "enrollments.admission_date"


    config.columns[:scholarship_durations_active].includes = { :enrollment_request => :enrollment }
    config.columns[:scholarship_durations_active].search_sql = ""
    config.columns[:scholarship_durations_active].search_ui = :select


    config.columns[:advisor].includes = { :enrollment_request => { :enrollment => :advisements } }
    config.columns[:advisor].search_sql = "advisements.professor_id"
    config.columns[:advisor].search_ui = :select

    config.columns[:course_class].search_ui = :record_select

    config.columns[:parent_status].includes = [:enrollment_request]
    config.columns[:parent_status].search_sql = ""
    config.columns[:parent_status].search_ui = :select
    config.columns[:parent_status].options = {:options => ClassEnrollmentRequest::STATUSES, default: ClassEnrollmentRequest::REQUESTED, :include_blank => I18n.t("active_scaffold._select_")}

    config.columns[:professor].includes = [:course_class]
    config.columns[:professor].search_sql = "course_classes.professor_id"
    config.columns[:professor].search_ui = :select


    config.columns[:class_enrollment].allow_add_existing = false;

    config.columns[:enrollment_request].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:status].form_ui = :select
    config.columns[:status].options = {:options => ClassEnrollmentRequest::STATUSES, default: ClassEnrollmentRequest::REQUESTED, :include_blank => I18n.t("active_scaffold._select_")}

    config.actions.exclude :deleted_records, :show, :delete, :create, :update
  end

  def self.condition_for_admission_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date1 = Date.new(year.to_i, month.to_i)
      date2 = Date.new(month.to_i==12 ? year.to_i + 1 : year.to_i, (month.to_i % 12) + 1)

      ["DATE(#{column.search_sql.last}) >= ? and DATE(#{column.search_sql.last}) < ?", date1, date2]
    end
  end

  def self.condition_for_scholarship_durations_active_column(column, value, like_pattern)
    query_active_scholarships = "select enrollment_id from scholarship_durations where DATE(scholarship_durations.end_date) >= DATE(?) AND  (scholarship_durations.cancel_date is NULL OR DATE(scholarship_durations.cancel_date) >= DATE(?))"
    case value
      when '0' then
        sql = "enrollments.id not in (#{query_active_scholarships})"
      when '1' then
        sql = "enrollments.id in (#{query_active_scholarships})"
      else
        return ""
    end

    [sql, Time.now, Time.now]
  end

  def self.condition_for_parent_status_column(column, value, like_pattern)
    check_parent = 'cer.enrollment_request_id = enrollment_requests.id'
    invalid = "select 1 from class_enrollment_requests cer where cer.status = '#{ClassEnrollmentRequest::INVALID}' and #{check_parent}"
    not_valid = "select 1 from class_enrollment_requests cer where cer.status != '#{ClassEnrollmentRequest::VALID}' and cer.status != '#{ClassEnrollmentRequest::EFFECTED}' and #{check_parent}"
    not_effected = "select 1 from class_enrollment_requests cer where cer.status != '#{ClassEnrollmentRequest::EFFECTED}' and #{check_parent}"
    case value
      when ClassEnrollmentRequest::INVALID then
        sql = "exists (#{invalid})"
      when ClassEnrollmentRequest::VALID then
        sql = "not exists (#{not_valid})"
      when ClassEnrollmentRequest::EFFECTED then
        sql = "not exists (#{not_effected})"
      when ClassEnrollmentRequest::REQUESTED then
        sql = "not exists (#{invalid}) and exists (#{not_valid})"
      else
        return ""
    end
    [sql]
  end

  def hide_validate_actions?(record)
    cannot? :update, record
  end

  def set_invalid_security_method(record)
    record.status != ClassEnrollmentRequest::INVALID && can?(:update, record)
  end

  def set_requested_security_method(record)
    record.status != ClassEnrollmentRequest::REQUESTED && can?(:update, record)
  end

  def set_valid_security_method(record)
    record.status != ClassEnrollmentRequest::VALID && can?(:update, record)
  end

  def set_effected_security_method(record)
    record.status != ClassEnrollmentRequest::EFFECTED && can?(:update, record)
  end

  def hide_effect_actions?(record=nil)
    return cannot? :effect, ClassEnrollmentRequest if record.blank?
    cannot? :effect, record
  end

  def set_status(status, message)
    process_action_link_action(:set_status) do |record|
      if self.successful = record.set_status!(status)
        yield record if block_given?
        flash[:info] = I18n.t(message, count: 1)
      else
        flash[:error] = I18n.t(message, count: 0)
      end
    end
  end

  def set_invalid
    raise CanCan::AccessDenied.new("Acesso negado!", :update, ClassEnrollmentRequest) if cannot? :update, ClassEnrollmentRequest
    set_status(ClassEnrollmentRequest::INVALID, 'class_enrollment_request.invalid.applied')
  end

  def set_requested
    raise CanCan::AccessDenied.new("Acesso negado!", :update, ClassEnrollmentRequest) if cannot? :update, ClassEnrollmentRequest
    set_status(ClassEnrollmentRequest::REQUESTED, 'class_enrollment_request.requested.applied')
  end

  def set_valid
    raise CanCan::AccessDenied.new("Acesso negado!", :update, ClassEnrollmentRequest) if cannot? :update, ClassEnrollmentRequest
    set_status(ClassEnrollmentRequest::VALID, 'class_enrollment_request.valid.applied')
  end

  def set_effected
    raise CanCan::AccessDenied.new("Acesso negado!", :effect, ClassEnrollmentRequest) if cannot? :effect, ClassEnrollmentRequest
    set_status(ClassEnrollmentRequest::EFFECTED, 'class_enrollment_request.effected.applied') do |record|
      emails = [EmailTemplate.load_template("class_enrollment_requests:email_to_student").prepare_message({record: record})]
      Notifier.send_emails(notifications: emails)
    end
  end

  def show_effect
    raise CanCan::AccessDenied.new("Acesso negado!", :effect, ClassEnrollmentRequest) if cannot? :effect, ClassEnrollmentRequest
    each_record_in_page {}
    class_enrollment_requests = find_page(:sorting => active_scaffold_config.list.user.sorting).items
    @count = class_enrollment_requests.filter { |record| record.status != ClassEnrollmentRequest::EFFECTED }.count
    respond_to_action(:show_effect)
  end

  def effect
    raise CanCan::AccessDenied.new("Acesso negado!", :effect, ClassEnrollmentRequest) if cannot? :effect, ClassEnrollmentRequest
    count = 0
    each_record_in_page {}
    class_enrollment_requests = find_page(:sorting => active_scaffold_config.list.user.sorting).items
    class_enrollment_requests.each do |record|
      changed = record.set_status!(ClassEnrollmentRequest::EFFECTED)
      if changed
        emails = [EmailTemplate.load_template("class_enrollment_requests:email_to_student").prepare_message({
          :record => record,
        })]
        Notifier.send_emails(notifications: emails)
      end
      count += 1 if changed
    end
    do_refresh_list
    @message = I18n.t('class_enrollment_request.effected.applied', count: count)
    respond_to_action(:effect)
  end

  protected

  def show_effect_respond_to_html
    render(:action => 'show_effect')
  end
  
  def show_effect_respond_to_js
    render(:partial => 'effect')
  end

  def effect_respond_on_iframe
    flash[:info] = @message
    responds_to_parent do
      render :action => 'on_effect', :formats => [:js], :layout => false
    end
  end

  def effect_respond_to_html
    flash[:info] = @message
    return_to_main
  end
  
  def effect_respond_to_js
    flash.now[:info] = @message
    do_refresh_list 
    @popstate = true
    render :action => 'on_effect', :formats => [:js]
  end

  def set_status_respond_to_html
    return_to_main
  end

  def set_status_respond_to_js
    do_refresh_list if successful? && !render_parent?
    render(:action => 'on_set_status')
  end

  def set_status_respond_on_iframe
    do_refresh_list if successful? && !render_parent?
    responds_to_parent do
      render :action => 'on_set_status', :formats => [:js], :layout => false
    end
  end

end
