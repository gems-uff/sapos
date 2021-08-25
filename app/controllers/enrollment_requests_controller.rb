# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequestsController < ApplicationController
  authorize_resource
  helper :course_classes

  active_scaffold :"enrollment_request" do |config|
    config.list.sorting = {:year => 'DESC', :semester => 'DESC', :enrollment => 'ASC'}
    config.list.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at]
    config.create.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at]
    config.update.columns = [:year, :semester, :enrollment, :status, :last_student_change_at, :last_staff_change_at, :class_enrollment_requests, :enrollment_request_comments]
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


    config.action_links.add 'show_validate', 
      :label => "<i title='#{I18n.t('enrollment_request.validate.link')}' class='fa fa-check-square-o'></i>".html_safe, 
      :type => :member

    config.actions.exclude :deleted_records
  end
  record_select :per_page => 10, :search_on => [:year, :semester, :enrollment], :order_by => 'year DESC, semester DESC', :full_text_search => true

  def show_validate
    do_show_validate
    respond_to_action(:show_validate)
  end

  def validate
    do_validate
    respond_to_action(:validate)
  end

 
  
  protected

  def before_update_save(record)
    message = params[:comment_message]
    changed = false
    changed ||= record.changed? || record.class_enrollment_requests.any? { |cer| cer.changed? }
    changed ||= ! message.nil? && ! message.empty?
    if changed
      record.last_staff_change_at = Time.current
      if ! message.nil? && ! message.empty?
        @comment = record.enrollment_request_comments.build(message: message, user: current_user)
      end
      # ToDo: notify student
    end
  end


  def show_validate_respond_to_html
    if successful?
      render(:action => 'validate')
    else
      return_to_main
    end
  end

  def show_validate_respond_to_js
    render(:partial => 'validate_form')
  end

  def validate_respond_on_iframe
    do_refresh_list if successful? && active_scaffold_config.update.refresh_list && !render_parent?
    responds_to_parent do
      render :action => 'on_validate', :formats => [:js], :layout => false
    end
  end

  def validate_respond_to_html
    if successful? # just a regular post
      message = as_(:updated_model, :model => ERB::Util.h(@record.to_label))
      if params[:dont_close]
        flash.now[:info] = message
        render(:action => 'validate')
      else
        flash[:info] = message
        return_to_main
      end
    else
      render(:action => 'validate')
    end
  end

  def validate_respond_to_js
    if successful?
      record_to_refresh_on_update if !render_parent? && active_scaffold_config.actions.include?(:list)
      flash.now[:info] = as_(:updated_model, :model => ERB::Util.h((@updated_record || @record).to_label)) if active_scaffold_config.update.persistent
    end
    render :action => 'on_validate'
  end

  def validate_respond_to_xml
    response_to_api(:xml, update_columns_names)
  end

  def validate_respond_to_json
    response_to_api(:json, update_columns_names)
  end

  def do_show_validate
    @record = find_if_allowed(params[:id], :validate)
  end

  def do_validate
    do_show_validate
    update_save
  end

 
end
