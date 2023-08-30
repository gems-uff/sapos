# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class EnrollmentsController < ApplicationController
  include EnrollmentSearchConcern
  include SharedPdfConcern

  authorize_resource
  include NumbersHelper
  include ApplicationHelper
  include EnrollmentUsersHelper

  helper :advisements
  helper :scholarship_durations

  before_action :remove_constraint_to_show_enrollment_column, only: [:edit]

  active_scaffold :enrollment do |config|
    config.action_links.add "to_pdf",
      label: I18n.t("active_scaffold.to_pdf"),
      page: true,
      type: :collection,
      parameters: { format: :pdf }
    config.action_links.add "new_users",
      label: I18n.t("active_scaffold.new_users_action"),
      ignore_method: :hide_new_users?,
      type: :collection,
      keep_open: false
    config.action_links.add "academic_transcript_pdf",
      label: "
        <i title='#{I18n.t("pdf_content.enrollment.academic_transcript.link")}'
           class='fa fa-book'></i>
      ".html_safe,
      page: true,
      type: :member,
      parameters: { format: :pdf }
    config.action_links.add "grades_report_pdf",
      label: "<i title='#{I18n.t("pdf_content.enrollment.grades_report.link")}'
                 class='fa fa-file-text-o'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :pdf }

    config.columns.add :scholarship_durations_active, :active, :professor
    config.columns.add :phase, :delayed_phase, :course_class_year_semester
    config.columns.add :deferral_type
    config.columns.add :listed_advisors, :listed_accomplishments
    config.columns.add :listed_deferrals, :listed_scholarships
    config.columns.add :listed_class_enrollments
    config.columns.add :phase_due_dates, :enrollment_hold

    config.list.columns = [
      :enrollment_number, :student, :enrollment_status, :level,
      :admission_date, :dismissal
    ]
    config.list.sorting = { enrollment_number: "ASC" }

    config.create.label = :create_enrollment_label
    config.actions.swap :search, :field_search

    config.field_search.columns = [
      :enrollment_number,
      :student,
      :level,
      :enrollment_status,
      :admission_date,
      :active,
      :scholarship_durations_active,
      :professor,
      :accomplishments,
      :delayed_phase,
      :course_class_year_semester,
      :research_area,
      :enrollment_hold
    ]

    config.columns[:enrollment_hold].search_sql = ""

    config.columns[:accomplishments].allow_add_existing = false
    config.columns[:accomplishments].search_sql = ""
    config.columns[:active].search_sql = ""
    config.columns[:active].search_ui = :select
    config.columns[:admission_date].options = { format: :monthyear }
    config.columns[:admission_date].search_sql = "enrollments.admission_date"
    config.columns[:course_class_year_semester].search_sql = ""
    config.columns[:delayed_phase].search_sql = ""
    config.columns[:delayed_phase].search_ui = :select
    config.columns[:dismissal].clear_link
    config.columns[:dismissal].sort_by(sql: "dismissals.date")
    config.columns[:enrollment_number].search_sql =
      "enrollments.enrollment_number"
    config.columns[:enrollment_number].search_ui = :text
    config.columns[:enrollment_status].clear_link
    config.columns[:enrollment_status].form_ui = :select
    config.columns[:enrollment_status].search_sql = "enrollment_statuses.id"
    config.columns[:enrollment_status].search_ui = :select
    config.columns[:level].clear_link
    config.columns[:level].form_ui = :select
    config.columns[:level].search_sql = "levels.id"
    config.columns[:level].search_ui = :select
    config.columns[:level].send_form_on_update_column = true
    config.columns[:level].update_columns = [
      :accomplishments, :phase, :deferrals, :deferral_type
    ]
    config.columns[:professor].includes = { advisements: :professor }
    config.columns[:professor].search_sql = "professors.name"
    config.columns[:professor].search_ui = :text
    config.columns[:research_area].form_ui = :record_select
    config.columns[:scholarship_durations_active].search_sql = ""
    config.columns[:scholarship_durations_active].search_ui = :select
    config.columns[:student].form_ui = :record_select
    config.columns[:student].search_ui = :record_select
    config.columns[:thesis_defense_date].options = {
      data: CustomVariable.academic_calendar_range
    }

    columns = [
      :enrollment_number,
      :student,
      :admission_date,
      :enrollment_status,
      :level,
      :research_area,
      :thesis_title,
      :thesis_defense_date,
      :obs,

      :advisements,
      :scholarship_durations,
      :accomplishments,
      :phase_due_dates,
      :deferrals,
      :enrollment_holds,
      :class_enrollments,
      :thesis_defense_committee_participations,
      :dismissal
    ]

    config.create.columns = columns - [
      :accomplishments, :deferrals, :phase_due_dates
    ]
    config.update.columns = columns - [:phase_due_dates]
    config.show.columns =  columns - [:accomplishments]

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10,
    search_on: [:enrollment_number],
    order_by: "enrollment_number",
    full_text_search: true
  )

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
      :condition_for_accomplishments_column,
      :custom_condition_for_accomplishments_column
    )
    alias_method(
      :condition_for_active_column,
      :custom_condition_for_active_column
    )
    alias_method(
      :condition_for_course_class_year_semester_column,
      :custom_condition_for_course_class_year_semester_column
    )
    alias_method(
      :condition_for_delayed_phase_column,
      :custom_condition_for_delayed_phase_column
    )
    alias_method(
      :condition_for_enrollment_hold_column,
      :custom_condition_for_enrollment_hold_column
    )
  end

  def to_pdf
    each_record_in_page { }
    enrollments_list = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items
    @enrollments = enrollments_list.map do |enrollment|
      [
        enrollment.student[:name],
        enrollment[:enrollment_number],
        enrollment[:admission_date],
        if enrollment.dismissal
          enrollment.dismissal[:date]
        end
      ]
    end

    @search = search_params

    respond_to do |format|
      format.pdf do
        send_data render_to_string,
          filename: "#{I18n.t("pdf_content.enrollment.to_pdf.filename")}.pdf",
          type: "application/pdf"
      end
    end
  end

  def academic_transcript_pdf
    enrollment = Enrollment.find(params[:id])
    respond_to do |format|
      format.pdf do
        title = I18n.t("pdf_content.enrollment.academic_transcript.title")
        student = enrollment.student.name
        send_data render_enrollments_academic_transcript_pdf(enrollment),
          filename: "#{title} - #{student}.pdf",
          type: "application/pdf"
      end
    end
  end

  def grades_report_pdf
    enrollment = Enrollment.find(params[:id])
    respond_to do |format|
      format.pdf do
        title = I18n.t("pdf_content.enrollment.grades_report.title")
        student = enrollment.student.name
        send_data render_enrollments_grades_report_pdf(enrollment),
          filename: "#{title} - #{student}.pdf",
          type: "application/pdf"
      end
    end
  end

  def hide_new_users?
    cannot? :invite, User
  end

  def new_users
    raise CanCan::AccessDenied.new if cannot? :invite, User
    each_record_in_page { }
    enrollments = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items
    @counts = new_users_count(enrollments)
    @statuses_with_users = EnrollmentStatus.where(user: true).collect(&:name)
    respond_to_action(:new_users)
  end

  def create_users
    raise CanCan::AccessDenied.new if cannot? :invite, User
    each_record_in_page { }
    enrollments = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items
    created = create_enrollments_users(enrollments, params["add_option"])
    if created > 0
      users_l = "usuário".pluralize(created)
      created_l = "criado".pluralize(created)
      @info_message = "#{created} #{users_l} #{created_l}"
    else
      @error_message = "Nenhum usuário criado"
    end
    self.successful = true
    respond_to_action(:create_users)
  end

  protected
    def new_users_respond_to_js
      render partial: "new_users"
    end

    def create_users_respond_on_iframe
      flash[:info] = @info_message unless @info_message.nil?
      flash[:error] = @error_message unless @error_message.nil?
      responds_to_parent do
        render action: "on_create_users", formats: [:js], layout: false
      end
    end

    def create_users_respond_to_html
      flash[:info] = @info_message unless @info_message.nil?
      flash[:error] = @error_message unless @error_message.nil?
      return_to_main
    end

    def create_users_respond_to_js
      flash.now[:info] = @info_message unless @info_message.nil?
      flash.now[:error] = @error_message unless @error_message.nil?
      do_refresh_list
      @popstate = true
      render action: "on_create_users", formats: [:js]
    end

    def before_update_save(record)
      return if !record.valid?
      return if !record.class_enrollments.all? do |class_enrollment|
        class_enrollment.valid?
      end
      emails = []
      record.class_enrollments.each do |class_enrollment|
        if class_enrollment.should_send_email_to_professor?
          emails << EmailTemplate.load_template(
            "class_enrollments:email_to_professor"
          ).prepare_message({
            record: class_enrollment,
          })
        end
      end
      return if emails.empty?
      Notifier.send_emails(notifications: emails)
    end

  private
    def remove_constraint_to_show_enrollment_column
      Thread.current[:constraint_columns] = nil
      rescue
    end
end
