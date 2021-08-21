# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequestsController < ApplicationController
  authorize_resource

  active_scaffold :"enrollment_request" do |config|
    config.list.sorting = {:year => 'DESC', :semester => 'DESC', :enrollment => 'ASC'}
    config.list.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at]
    config.create.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at]
    config.update.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at]
    config.create.label = :create_enrollment_request_label
    config.update.label = :update_enrollment_request_label

    config.columns[:enrollment].form_ui = :record_select

    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {
      :options => YearSemester::SEMESTERS,
      :include_blank => true,
      :default => nil
    }
    config.columns[:year].options = {
      :options => YearSemester.selectable_years,
      :include_blank => true,
      :default => nil
    }
    config.columns[:status].form_ui = :select
    config.columns[:status].options = {:options => ClassEnrollmentRequest::STATUSES, default: ClassEnrollmentRequest::REQUESTED, :include_blank => I18n.t("active_scaffold._select_")}

    config.actions.exclude :deleted_records
  end
  record_select :per_page => 10, :search_on => [:year, :semester, :enrollment], :order_by => 'year DESC, semester DESC', :full_text_search => true


end
