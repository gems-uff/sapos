# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollmentRequestsController < ApplicationController
  authorize_resource
  
  active_scaffold :"class_enrollment_request" do |config|
    config.list.sorting = {:enrollment_request => 'ASC'}
    columns = [:enrollment_request, :course_class, :status, :class_enrollment]
    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns

    config.columns.add :enrollment_number, :student, :enrollment_level, :enrollment_status, :admission_date, :scholarship_durations_active, :professor
    config.columns.add :year, :semester

    config.create.label = :create_class_enrollment_request_label
    config.update.label = :update_class_enrollment_request_label
    config.actions.swap :search, :field_search

    config.field_search.columns = [
      :status,
      :year,
      :semester,
      :enrollment_number, 
      :student, 
      :enrollment_level, 
      :enrollment_status, 
      :admission_date, 
      :scholarship_durations_active, 
      :professor,
      :course_class,
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


    config.columns[:professor].includes = { :enrollment_request => { :enrollment => :advisements } }
    config.columns[:professor].search_sql = "advisements.professor_id"
    config.columns[:professor].search_ui = :select

    config.columns[:course_class].search_ui = :record_select

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
end
