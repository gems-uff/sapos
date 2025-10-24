# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ClassEnrollmentRequestsController < ApplicationController
  include EnrollmentSearchConcern
  include EnrollmentRequestSearchConcern
  authorize_resource

  active_scaffold :"class_enrollment_request" do |config|
    config.action_links.add "show_effect",
      label: I18n.t("class_enrollment_request.actions.effect"),
      ignore_method:  :hide_effect_actions?,
      type: :collection,
      keep_open: false

    config.action_links.add "help",
      label: I18n.t("class_enrollment_request.actions.help"),
      type: :collection,
      keep_open: false

    base_member = {
      type: :member, keep_open: false, position: false,
      crud_type: :update, method: :put, refresh_list: true
    }
    config.action_links.add "set_invalid",
      label:  "<i title='#{I18n.t("class_enrollment_request.invalid.label")}'
                  class='fa fa-times-circle'></i>".html_safe,
      ignore_method: :hide_validate_actions?,
      security_method: :set_invalid_security_method,
      confirm: I18n.t("class_enrollment_request.invalid.confirm"),
      **base_member

    config.action_links.add "set_requested",
      label:  "<i title='#{I18n.t("class_enrollment_request.requested.label")}'
                  class='fa fa-question-circle'></i>".html_safe,
      ignore_method: :hide_validate_actions?,
      security_method: :set_requested_security_method,
      confirm: I18n.t("class_enrollment_request.requested.confirm"),
      **base_member

    config.action_links.add "set_valid",
      label:  "<i title='#{I18n.t("class_enrollment_request.valid.label")}'
                  class='fa fa-check-circle'></i>".html_safe,
      ignore_method: :hide_validate_actions?,
      security_method: :set_valid_security_method,
      confirm: I18n.t("class_enrollment_request.valid.confirm"),
      **base_member

    config.action_links.add "set_effected",
      label:  "<i title='#{I18n.t("class_enrollment_request.effected.label")}'
                  class='fa fa-plus-circle'></i>".html_safe,
      ignore_method: :hide_effect_actions?,
      security_method: :set_effected_security_method,
      confirm: I18n.t("class_enrollment_request.effected.confirm"),
      **base_member

    columns = [:enrollment_request, :course_class, :status, :class_enrollment]
    config.list.columns = [
      :enrollment_request, :enrollment, :course_class, :class_enrollment,
      :allocations, :professor, :action, :status
    ]
    config.show.columns = [
      :enrollment_request, :course_class, :class_enrollment,
      :allocations, :professor, :action, :status
    ]
    config.create.columns = columns
    config.update.columns = columns

    config.columns.add :student, :enrollment_level, :enrollment_status
    config.columns.add :admission_date, :scholarship_durations_active
    config.columns.add :advisor, :has_advisor
    config.columns.add :year, :semester, :allocations, :professor, :course_type

    config.create.label = :create_class_enrollment_request_label
    config.actions.swap :search, :field_search

    config.columns[:class_enrollment].actions_for_association_links.delete :new

    add_year_search_column(config)
    config.columns[:year].includes = [:enrollment_request]
    config.columns[:year].search_sql = "enrollment_requests.year"

    add_semester_search_column(config)
    config.columns[:semester].includes = [:enrollment_request]
    config.columns[:semester].search_sql = "enrollment_requests.semester"

    config.columns[:enrollment].search_ui = :select
    config.columns[:enrollment].search_sql = "enrollment_requests.enrollment_id"
    config.columns[:enrollment].sort_by sql: "students.name"
    config.columns[:enrollment].includes = {
      enrollment_request: { enrollment: :student }
    }
    config.columns[:enrollment].actions_for_association_links = [:show]

    add_student_search_column(config)
    config.columns[:student].includes = { enrollment_request: :enrollment }

    add_enrollment_level_search_column(config)
    config.columns[:enrollment_level].includes = {
      enrollment_request: :enrollment
    }

    add_enrollment_status_search_column(config)
    config.columns[:enrollment_status].includes = {
      enrollment_request: :enrollment
    }

    add_admission_date_search_column(config)
    config.columns[:admission_date].includes = {
      enrollment_request: :enrollment
    }

    add_scholarship_durations_active_search_column(config)
    config.columns[:scholarship_durations_active].includes = {
      enrollment_request: :enrollment
    }

    add_advisor_search_column(config)
    config.columns[:advisor].includes = {
      enrollment_request: { enrollment: :advisements }
    }

    add_has_advisor_search_column(config)
    config.columns[:has_advisor].includes = {
      enrollment_request: [ :enrollment ]
    }

    config.columns[:course_class].search_ui = :record_select

    add_course_type_search_column(config)
    config.columns[:course_type].includes = {
      course_class: { course: :course_type }
    }

    add_professor_search_column(config)
    config.columns[:professor].includes = { course_class: :professor }

    config.field_search.columns = [
      :action,
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
      :advisor,
      :course_class,
      :course_type,
      :professor
    ]

    config.columns[:class_enrollment].allow_add_existing = false

    config.columns[:enrollment_request].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:status].form_ui = :select
    config.columns[:status].options = {
      options: ClassEnrollmentRequest::STATUSES,
      default: ClassEnrollmentRequest::REQUESTED,
      include_blank: I18n.t("active_scaffold._select_")
    }

    config.columns[:action].form_ui = :select
    config.columns[:action].options = {
      options: ClassEnrollmentRequest::ACTIONS,
      default: ClassEnrollmentRequest::INSERT,
      include_blank: I18n.t("active_scaffold._select_")
    }

    config.columns[:enrollment_request].sort_by(
      sql: "enrollment_requests.year, enrollment_requests.semester"
    )
    config.columns[:enrollment_request].includes = [ :enrollment_request ]
    config.list.sorting = { enrollment: "ASC" }

    config.columns[:course_class].sort_by sql: "courses.name"
    config.columns[:course_class].includes = { course_class: :course }

    config.columns[:allocations].sort_by method: proc { self.allocations.to_s }
    config.columns[:allocations].includes = { course_class: :allocations }

    config.columns[:professor].sort_by sql: "professors.name"

    config.actions.exclude :deleted_records, :show, :delete, :create, :update
  end

  class << self
    alias_method(
      :condition_for_admission_date_column,
      :custom_condition_for_admission_date_column
    )
    alias_method(
      :condition_for_scholarship_durations_active_column,
      :custom_condition_for_scholarship_durations_active_column
    )
    alias_method(
      :condition_for_has_advisor_column,
      :custom_condition_for_has_advisor_column
    )
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

  def hide_effect_actions?(record = nil)
    return cannot? :effect, ClassEnrollmentRequest if record.blank?
    cannot? :effect, record
  end

  def set_status(status, message)
    process_action_link_action(:set_status) do |record|
      if self.successful = record.set_status!(status)
        yield record if block_given?
        flash[:info] = I18n.t(message, count: 1)
      else
        flash[:info] = (I18n.t(message, count: 0))
        flash[:error] = record.errors.full_messages
      end
    end
  end

  def set_invalid
    raise CanCan::AccessDenied.new if cannot? :update, ClassEnrollmentRequest
    set_status(
      ClassEnrollmentRequest::INVALID,
      "class_enrollment_request.invalid.applied"
    )
  end

  def set_requested
    raise CanCan::AccessDenied.new if cannot? :update, ClassEnrollmentRequest
    set_status(
      ClassEnrollmentRequest::REQUESTED,
      "class_enrollment_request.requested.applied"
    )
  end

  def set_valid
    raise CanCan::AccessDenied.new if cannot? :update, ClassEnrollmentRequest
    set_status(
      ClassEnrollmentRequest::VALID,
      "class_enrollment_request.valid.applied"
    )
  end

  def set_effected
    raise CanCan::AccessDenied.new if cannot? :effect, ClassEnrollmentRequest
    set_status(
      ClassEnrollmentRequest::EFFECTED,
      "class_enrollment_request.effected.applied"
    ) do |record|
      if record.action == ClassEnrollmentRequest::INSERT
        emails = [
          EmailTemplate.load_template(
            "class_enrollment_requests:email_to_student"
          ).prepare_message({ record: record })
        ]
      else
        emails = [
          EmailTemplate.load_template(
            "class_enrollment_requests:removal_email_to_student"
          ).prepare_message({ record: record })
        ]
      end
      Notifier.send_emails(notifications: emails)
    end
  end

  def show_effect
    raise CanCan::AccessDenied.new if cannot? :effect, ClassEnrollmentRequest
    each_record_in_page { }
    class_enrollment_requests = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items
    @count = class_enrollment_requests.filter do |record|
      record.status != ClassEnrollmentRequest::EFFECTED
    end.count
    respond_to_action(:show_effect)
  end

  def help
    raise CanCan::AccessDenied.new if cannot? :read, ClassEnrollmentRequest
    respond_to_action(:help)
  end

  def effect
    raise CanCan::AccessDenied.new if cannot? :effect, ClassEnrollmentRequest
    count = 0
    each_record_in_page { }
    class_enrollment_requests = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items
    emails = []

    enrollment_request_id = nil
    effected = []
    class_enrollment_requests.sort_by(&:enrollment_request_id).each do |record|
      if record.enrollment_request_id != enrollment_request_id
        if effected.present?
          enrollment_request = effected[0].enrollment_request
          emails << EmailTemplate.load_template(
            "enrollment_requests:email_to_student"
          ).prepare_message({
            record: enrollment_request,
            student_enrollment_url: student_enroll_url(
              id: enrollment_request.enrollment.id,
              year: enrollment_request.year,
              semester: enrollment_request.semester
            ),
            keep: enrollment_request.class_enrollment_requests.select do |cer|
              !effected.include? cer
            end,
            change: effected
          })
        end
        effected = []
        enrollment_request_id = record.enrollment_request_id
      end
      if record.set_status!(ClassEnrollmentRequest::EFFECTED)
        count += 1
        effected << record
      end
    end
    if effected.present?
      enrollment_request = effected[0].enrollment_request
      emails << EmailTemplate.load_template(
        "enrollment_requests:email_to_student"
      ).prepare_message({
        record: enrollment_request,
        student_enrollment_url: student_enroll_url(
          id: enrollment_request.enrollment.id,
          year: enrollment_request.year,
          semester: enrollment_request.semester
        ),
        keep: enrollment_request.class_enrollment_requests.select do |cer|
          !effected.include? cer
        end,
        change: effected
      })
    end
    Notifier.send_emails(notifications: emails)

    do_refresh_list
    @message = I18n.t("class_enrollment_request.effected.applied", count: count)
    respond_to_action(:effect)
  end

  protected
    def show_effect_respond_to_html
      render(action: "show_effect")
    end

    def show_effect_respond_to_js
      render(partial: "effect")
    end

    def help_respond_to_html
      render(action: "help")
    end

    def help_respond_to_js
      render(partial: "enrollment_requests/shared_help")
    end

    def effect_respond_on_iframe
      flash[:info] = @message
      responds_to_parent do
        render action: "on_effect", formats: [:js], layout: false
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
      render action: "on_effect", formats: [:js]
    end

    def set_status_respond_to_html
      return_to_main
    end

    def set_status_respond_to_js
      do_refresh_list if !render_parent?
      @popstate = true
      render(action: "on_set_status")
    end

    def set_status_respond_on_iframe
      do_refresh_list if !render_parent?
      responds_to_parent do
        render action: "on_set_status", formats: [:js], layout: false
      end
    end
end
