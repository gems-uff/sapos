# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CourseClassesController < ApplicationController
  authorize_resource
  include SharedPdfConcern
  include NumbersHelper

  before_action :remove_constraint_to_show_enrollment_column, only: [:edit]

  active_scaffold :course_class do |config|
    config.columns.add :class_enrollments_count

    config.action_links.add "class_schedule_pdf",
      label: I18n.t("pdf_content.class_schedule.class_schedule_pdf.link"),
      page: true,
      type: :collection,
      parameters: { format: :pdf }

    config.action_links.add "summary_pdf",
      label: "<i title='#{I18n.t(
        "pdf_content.course_class.summary.link"
      )}' class='fa fa-list-alt'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :pdf }

    config.list.sorting = { name: "ASC", id: "DESC" }
    config.list.columns = [
      :name, :course, :professor, :year, :semester, :class_enrollments_count
    ]
    config.show.columns = [
      :year, :semester, :name, :course, :professor, :allocations,
      :class_enrollments_count, :class_enrollments, :enrollments
    ]
    config.create.columns = [
      :name, :course, :professor, :year, :semester, :obs_schedule,
      :not_schedulable, :allocations
    ]
    config.update.columns = [
      :name, :course, :professor, :year, :semester, :obs_schedule,
      :not_schedulable, :class_enrollments, :allocations
    ]

    config.create.label = :create_course_class_label

    config.actions.swap :search, :field_search
    config.field_search.columns = [
      :name, :year, :semester, :professor, :course, :enrollments
    ]

    config.columns[:professor].search_sql = "professors.name"
    config.columns[:professor].search_ui = :text
    config.columns[:course].search_sql = "courses.name"
    config.columns[:course].search_ui = :text
    config.columns[:name].search_ui = :text
    config.columns[:enrollments].search_ui = :record_select
    config.columns[:course].form_ui = :record_select
    config.columns[:course].options[:params] = { available: true }
    config.columns[:professor].form_ui = :record_select
    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {
      options: YearSemester::SEMESTERS,
      include_blank: true,
      default: nil
    }
    config.columns[:year].options = {
      options: YearSemester.selectable_years,
      include_blank: true,
      default: nil
    }

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, label: :record_select_output,
    order_by: "year DESC, semester DESC, name, id DESC",
    full_text_search: true
  )

  def summary_pdf
    course_class = CourseClass.find(params[:id])

    respond_to do |format|
      format.pdf do
        title = I18n.t("pdf_content.course_class.summary.title")
        send_data render_course_classes_summary_pdf(course_class),
          filename: "#{title} - #{course_class.name_with_class}.pdf",
          type: "application/pdf"
      end
    end
  end

  def class_schedule_pdf
    each_record_in_page { }
    @course_classes = find_page
    @on_demand = Course
      .joins(:course_type).where(course_types: { on_demand: true })
    @search = search_params

    empty_year_semester = (
      search_params.nil? ||
      search_params[:year].empty? ||
      search_params[:semester].empty?
    )
    if empty_year_semester
      flash[:error] = I18n.t(
        "pdf_content.class_schedule.class_schedule_pdf.year_semester_error"
      )
      redirect_to action: :index
    else
      year = search_params[:year]
      semester = search_params[:semester]

      respond_to do |format|
        format.pdf do
          title = I18n.t("pdf_content.class_schedule.class_schedule_pdf.title")
          send_data render_class_schedules_class_schedule_pdf(year, semester),
            filename: "#{title} (#{year}_#{semester}).pdf",
            type: "application/pdf"
        end
      end
    end
  end

  protected
    def before_update_save(record)
      return unless
        record.valid? && record.class_enrollments.all? do |class_enrollment|
          class_enrollment.valid?
        end
      changed = record.class_enrollments.any? do |class_enrollment|
        class_enrollment.should_send_email_to_professor?
      end
      return unless changed
      emails = [
        EmailTemplate.load_template("course_classes:email_to_professor")
          .prepare_message({ record: record })
      ]
      Notifier.send_emails(notifications: emails)
    end

  private
    def remove_constraint_to_show_enrollment_column
      Thread.current[:constraint_columns]["class_enrollment-subform"]
        .delete(:enrollment)
    rescue
    end
end
