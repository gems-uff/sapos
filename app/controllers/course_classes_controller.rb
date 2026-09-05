# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CourseClassesController < ApplicationController
  authorize_resource
  include SharedPdfConcern
  include SharedXlsConcern
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

    config.action_links.add "summary_xls",
      label: "<i title='#{I18n.t(
        "xls_content.course_class.summary.link"
      )}' class='fa fa-table'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :xlsx }
    config.action_links.add "import_grades_xls",
      label: "<i title='Importar Notas' class='fa fa-upload'></i>".html_safe,
      type: :member,
      position: :replace


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

    year_param = search_param_value(:year)
    semester_param = search_param_value(:semester)
    empty_year_semester = year_param.blank? || semester_param.blank?

    if empty_year_semester
      flash[:error] = I18n.t(
        "pdf_content.class_schedule.class_schedule_pdf.year_semester_error"
      )
      redirect_to action: :index
    else
      year = year_param
      semester = semester_param

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

  def summary_xls
    @course_class = CourseClass.find(params[:id])
    @class_enrollments = ClassEnrollment.where(ClassEnrollment.arel_table[:course_class_id].eq(@course_class.id))

    respond_to do |format|
      format.xlsx do
        title = I18n.t("xls_content.course_class.summary.title")
        send_data render_course_classes_summary_xls(@class_enrollments),
          filename: "#{title} - #{@course_class.name_with_class}(#{@course_class.year}-#{@course_class.semester}).xlsx",
          type: "text/xlsx"
      end
    end
  end

  def import_grades_xls
    @course_class = CourseClass.find(params[:id])
    authorize! :import_grades_xls, @course_class
    if params[:confirm] == "1"
      stored_results = session[xls_import_session_key(@course_class)]
      if stored_results.blank?
        flash[:error] = "Nenhuma nota foi importada."
        redirect_to course_classes_path and return
      end
      saved_count = apply_xls_import_changes(stored_results)
      session.delete(xls_import_session_key(@course_class))
      if saved_count > 0
        flash[:info] = "#{saved_count} Notas importadas com sucesso!"
      else
        flash[:error] = "Nenhuma nota foi importada."
      end

      redirect_to course_classes_path and return
    elsif request.post? && params[:spreadsheet].present?
      begin
        @results = build_xls_import_preview(params[:spreadsheet])
        session[xls_import_session_key(@course_class)] = @results
        render :import_grades_xls_results and return
      rescue ArgumentError
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_error")
        redirect_to import_grades_xls_course_class_path(@course_class) and return
      end
    end
    respond_to do |format|
      format.html { render layout: false if request.xhr? }
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
    def search_param_value(key)
      value = search_params&.dig(key)
      value.is_a?(Hash) ? value[:from] : value
    end

    def remove_constraint_to_show_enrollment_column
      Thread.current[:constraint_columns]["class_enrollment-subform"]
        .delete(:enrollment)
    rescue
    end

    def xls_import_session_key(course_class)
      "xls_import_grades_#{course_class.id}"
    end

    def build_xls_import_preview(file)
      grade_of_disapproval_for_absence = CustomVariable.grade_of_disapproval_for_absence
      minimum_grade_for_approval = CustomVariable.minimum_grade_for_approval
      rows = parse_rows_xls(file)

      results = []
      rows.each do |enrollment_number, data|
        enrollment = Enrollment.find_by(enrollment_number: enrollment_number)
        unless enrollment
          results << { enrollment_number: enrollment_number, status: "not_found" }
          next
        end
        class_enrollment = @course_class.class_enrollments.find_by(enrollment: enrollment)
        unless class_enrollment
          results << { enrollment_number: enrollment_number, status: "not_enrolled" }
          next
        end

        if data[:grade].present?
          imported_grade_scaled = data[:grade].to_s.tr(",", ".").to_f * 10
          final_grade = imported_grade_scaled
        else
          imported_grade_scaled = nil
          final_grade = class_enrollment.grade
        end
        if data[:situation].present? && ClassEnrollment::SITUATIONS.include?(data[:situation])
          final_situation = data[:situation]
          invalid_situation = false
        elsif data[:situation].present?
          final_situation = class_enrollment.situation
          invalid_situation = true
        else
          final_situation = class_enrollment.situation
          invalid_situation = false
        end
        if data[:attendance].present?
          final_attendance = data[:attendance] == ClassEnrollment::ATTENDANCE_TRUE
        else
          final_attendance = !class_enrollment.disapproved_by_absence
        end
        if !final_attendance
          final_grade = grade_of_disapproval_for_absence
          final_situation = ClassEnrollment::DISAPPROVED
        elsif final_grade.present?
          final_situation = final_grade.to_f >= minimum_grade_for_approval ? ClassEnrollment::APPROVED : ClassEnrollment::DISAPPROVED
        end
        if data[:obs].present?
          final_obs = data[:obs]
        else
          final_obs = class_enrollment.obs
        end

        final_grade_view = final_grade.present? ? (final_grade.to_f / 10.0).to_s.tr(".", ",") : nil

        results << {
          enrollment_number: enrollment_number,
          class_enrollment_id: class_enrollment.id,
          status: "pending",

          current_grade: class_enrollment.grade_to_view.to_s.tr(".", ","),
          imported_grade: data[:grade],
          final_grade: final_grade,
          final_grade_view: final_grade_view,
          grade_diff: imported_grade_scaled.present? && imported_grade_scaled != final_grade.to_f,

          imported_attendance: data[:attendance],
          final_attendance: final_attendance,
          attendance_diff: data[:attendance].present? && (data[:attendance] == ClassEnrollment::ATTENDANCE_TRUE) != final_attendance,

          current_situation: class_enrollment[:situation],
          imported_situation: data[:situation],
          final_situation: final_situation,
          situation_diff: data[:situation].present? && ClassEnrollment::SITUATIONS.include?(data[:situation]) && data[:situation] != final_situation,
          invalid_situation: invalid_situation,

          final_obs: final_obs

        }
      end
      results
    end

    def apply_xls_import_changes(changes)
      saved_count = 0
      changes.each do |raw_change|
        change = raw_change.with_indifferent_access
        next unless change[:status] == "pending"
        class_enrollment = @course_class.class_enrollments.find_by(id: change[:class_enrollment_id])
        next unless class_enrollment
        class_enrollment.grade = change[:final_grade]
        class_enrollment.disapproved_by_absence = !change[:final_attendance]
        class_enrollment.situation = change[:final_situation]
        class_enrollment.obs = change[:final_obs]
        if class_enrollment.save
          saved_count += 1
        else
          Rails.logger.debug class_enrollment.errors.full_messages.inspect
        end
      end
      saved_count
    end
end
