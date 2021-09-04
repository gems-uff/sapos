# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollmentRequestsController < ApplicationController
  authorize_resource
  
  active_scaffold :"class_enrollment_request" do |config|

    config.action_links.add 'show_effect',
      :label => I18n.t('class_enrollment_request.actions.effect'),
      :ignore_method => :hide_effect?,
      :type => :collection,
      :keep_open => false

    config.action_links.add 'single_effect',
      :label =>  "<i title='#{I18n.t('class_enrollment_request.actions.effect_single')}' class='fa fa-book'></i>".html_safe,
      :ignore_method => :hide_single_effect?,
      :type => :member,
      :keep_open => false,
      :position => false,
      :crud_type => :update,
      :method => :put,
      :confirm  => I18n.t('class_enrollment_request.actions.effect_confirm')

    config.list.sorting = {:enrollment_request => 'ASC'}
    columns = [:enrollment_request, :course_class, :status, :class_enrollment]
    config.list.columns = [:enrollment_request, :course_class, :status, :parent_status, :class_enrollment, :allocations, :professor]
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
    config.columns[:parent_status].search_sql = "enrollment_requests.status"
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

    config.actions.exclude :deleted_records
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

  def hide_effect?
    cannot? :effect, ClassEnrollmentRequest
  end

  def hide_single_effect?(record)
    record.status == ClassEnrollmentRequest::EFFECTED || (cannot? :effect, ClassEnrollmentRequest)
  end

  def single_effect
    raise CanCan::AccessDenied.new("Acesso negado!", :effect, ClassEnrollmentRequest) if cannot? :effect, ClassEnrollmentRequest
    process_action_link_action do |record|
      if (self.successful = record.to_effected && record.save)
        emails = [EmailTemplate.load_template("class_enrollment_requests:email_to_student").prepare_message({
          :record => record,
        })]
        Notifier.send_emails(notifications: emails)
        flash[:info] = I18n.t('class_enrollment_request.effect.applied', count: 1)
      else
        flash[:error] = I18n.t('class_enrollment_request.effect.applied', count: 0)
      end
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
      changed = record.to_effected && record.save
      if changed
        emails = [EmailTemplate.load_template("class_enrollment_requests:email_to_student").prepare_message({
          :record => record,
        })]
        Notifier.send_emails(notifications: emails)
      end
      count += 1 if changed
    end
    do_refresh_list
    @message = I18n.t('class_enrollment_request.effect.applied', count: count)
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



end
