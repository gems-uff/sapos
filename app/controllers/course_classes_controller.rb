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
      label: "<i title='#{I18n.t("xls_content.course_class.import_grades_xls_label")}' class='fa fa-upload'></i>".html_safe,
      page: true,
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
    if request.post? && params[:confirm] == "1"
      stored_results = session[xls_import_session_key(@course_class)]
      if stored_results.blank? || stored_results[:rows].blank?
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_nothing_saved")
        redirect_to course_classes_path and return
      end

      if stored_results[:stored_at] < CustomVariable.import_grades_session_timeout.ago
        session.delete(xls_import_session_key(@course_class))
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_expired")
        redirect_to import_grades_xls_course_class_path(@course_class) and return
      end

      recomputed = stored_results[:rows].map do |row|
        class_enrollment = @course_class.class_enrollments.find_by(id: row[:class_enrollment_id])
        unless class_enrollment
          next { enrollment_number: row[:enrollment_number], class_enrollment_id: row[:class_enrollment_id], status: "not_enrolled", diverged: true }
        end

        data = {
          grade: row[:imported_grade],
          situation: row[:imported_situation],
          attendance: row[:imported_attendance],
          obs: row[:imported_obs]
        }
        result = compute_import_row(row[:enrollment_number], class_enrollment, data, false)
        result[:diverged] = (
          class_enrollment.grade != row[:snapshot_grade] ||
          class_enrollment.situation != row[:snapshot_situation] ||
          class_enrollment.disapproved_by_absence != row[:snapshot_attendance] ||
          class_enrollment.grade_not_count_in_gpr != row[:snapshot_grade_not_count_in_gpr]
        )
        result
      end

      if recomputed.any? { |r| r[:diverged] }
        @results = recomputed
        @duplicate_enrollment_numbers = []
        store_import_preview(recomputed, stored_at: stored_results[:stored_at])
        flash.now[:warning] = I18n.t("xls_content.course_class.import_grades_xls_results.data_changed_warning")
        render :import_grades_xls_results and return
      end

      changes = recomputed.map do |r|
        {
          status: r[:status],
          class_enrollment_id: r[:class_enrollment_id],
          enrollment_number: r[:enrollment_number],
          final_grade: r[:final_grade],
          final_attendance: r[:final_attendance],
          final_situation: r[:final_situation],
          final_obs: r[:final_obs]
        }
      end

      saved_count, failed, notification_failures = apply_xls_import_changes(changes)
      session.delete(xls_import_session_key(@course_class))
      if failed.any?
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_partial_failure",
        details: failed.map { |f| "#{f[:enrollment_number]}: #{f[:errors].join(", ")}" }.join("; "))
      elsif saved_count > 0
        flash[:info] = I18n.t("xls_content.course_class.import_grades_xls_success", count: saved_count)
        if notification_failures.any?
          flash[:warning] = I18n.t("xls_content.course_class.import_grades_xls_notification_failure", enrollment_numbers: notification_failures.join(", "))
        end
      else
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_nothing_saved")
      end

      redirect_to course_classes_path and return
    elsif request.post? && params[:spreadsheet].present?
      begin
        @results, @duplicate_enrollment_numbers = build_xls_import_preview(params[:spreadsheet])
        store_import_preview(@results)
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
      rows, duplicate_enrollment_numbers = parse_rows_xls(file)

      results = []
      rows.each do |enrollment_number, data|
        enrollment = Enrollment.find_by(enrollment_number: enrollment_number)
        unless enrollment
          results << { enrollment_number: enrollment_number, status: "not_found" }
          next
        end
        if duplicate_enrollment_numbers.include?(enrollment_number)
          results << { enrollment_number: enrollment_number, status: "duplicate" }
          next
        end
        class_enrollment = @course_class.class_enrollments.find_by(enrollment: enrollment)
        unless class_enrollment
          results << { enrollment_number: enrollment_number, status: "not_enrolled" }
          next
        end

        results << compute_import_row(enrollment_number, class_enrollment, data, false)
      end
      [results, duplicate_enrollment_numbers]
    end

    def compute_import_row(enrollment_number, class_enrollment, data, duplicate_in_spreadsheet)
      grade_of_disapproval_for_absence = CustomVariable.grade_of_disapproval_for_absence
      minimum_grade_for_approval = CustomVariable.minimum_grade_for_approval

      if data[:grade].present?
        normalized_grade = data[:grade].to_s.strip.tr(",", ".")
        if normalized_grade.match?(/\A\d+(\.\d+)?\z/)
          imported_grade_scaled = normalized_grade.to_f * 10
          final_grade = imported_grade_scaled
          invalid_grade = false
        else
          imported_grade_scaled = nil
          final_grade = class_enrollment.grade
          invalid_grade = true
        end
      else
        imported_grade_scaled = nil
        final_grade = class_enrollment.grade
        invalid_grade = false
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

      if data[:attendance].present? && [ClassEnrollment::ATTENDANCE_TRUE, ClassEnrollment::ATTENDANCE_FALSE].include?(data[:attendance])
        final_attendance = data[:attendance] == ClassEnrollment::ATTENDANCE_TRUE
        invalid_attendance = false
      elsif data[:attendance].present?
        final_attendance = !class_enrollment.disapproved_by_absence
        invalid_attendance = true
      else
        final_attendance = !class_enrollment.disapproved_by_absence
        invalid_attendance = false
      end

      if !final_attendance
        final_situation = ClassEnrollment::DISAPPROVED
        final_grade = grade_of_disapproval_for_absence if class_enrollment.course_has_grade
      elsif final_grade.present? && !class_enrollment.grade_not_count_in_gpr?
        final_situation = final_grade.to_f >= minimum_grade_for_approval ? ClassEnrollment::APPROVED : ClassEnrollment::DISAPPROVED
      end

      final_obs = data[:obs].present? ? data[:obs] : class_enrollment.obs
      final_grade_view = final_grade.present? ? (final_grade.to_f / 10.0).to_s.tr(".", ",") : nil

      {
        enrollment_number: enrollment_number,
        class_enrollment_id: class_enrollment.id,
        status: "pending",

        current_grade: class_enrollment.grade_to_view.to_s.tr(".", ","),
        current_grade_raw: class_enrollment.grade,
        imported_grade: data[:grade],
        final_grade: final_grade,
        final_grade_view: final_grade_view,
        grade_diff: imported_grade_scaled.present? && imported_grade_scaled != final_grade.to_f,
        invalid_grade: invalid_grade,
        current_grade_not_count_in_gpr_raw: class_enrollment.grade_not_count_in_gpr,

        imported_attendance: data[:attendance],
        current_attendance_raw: class_enrollment.disapproved_by_absence,
        final_attendance: final_attendance,
        attendance_diff: data[:attendance].present? && (data[:attendance] == ClassEnrollment::ATTENDANCE_TRUE) != final_attendance,
        invalid_attendance: invalid_attendance,

        current_situation: class_enrollment[:situation],
        imported_situation: data[:situation],
        final_situation: final_situation,
        situation_diff: data[:situation].present? && ClassEnrollment::SITUATIONS.include?(data[:situation]) && data[:situation] != final_situation,
        invalid_situation: invalid_situation,

        duplicate_in_spreadsheet: duplicate_in_spreadsheet,

        final_obs: final_obs,
        imported_obs: data[:obs],
        diverged: false
      }
    end

    def store_import_preview(results, stored_at: Time.current)
      session[xls_import_session_key(@course_class)] = {
        stored_at: stored_at,
        rows: results.filter_map do |r|
          next unless r[:status] == "pending"
          {
            enrollment_number: r[:enrollment_number],
            class_enrollment_id: r[:class_enrollment_id],
            imported_grade: r[:imported_grade],
            imported_situation: r[:imported_situation],
            imported_attendance: r[:imported_attendance],
            imported_obs: r[:imported_obs],
            snapshot_grade: r[:current_grade_raw],
            snapshot_situation: r[:current_situation],
            snapshot_attendance: r[:current_attendance_raw],
            snapshot_grade_not_count_in_gpr: r[:current_grade_not_count_in_gpr_raw]
          }
        end
      }
    end

    def apply_xls_import_changes(changes)
      saved_count = 0
      failed = []
      updated_enrollments = []
      ClassEnrollment.transaction do
        changes.each do |raw_change|
          change = raw_change.with_indifferent_access
          next unless change[:status] == "pending"
          class_enrollment = @course_class.class_enrollments.find_by(id: change[:class_enrollment_id])
          next unless class_enrollment
          class_enrollment.grade = change[:final_grade]
          class_enrollment.disapproved_by_absence = !change[:final_attendance]
          class_enrollment.situation = change[:final_situation]
          class_enrollment.obs = change[:final_obs]
          class_enrollment.skip_notification = true
          if class_enrollment.save
            saved_count += 1
            updated_enrollments << class_enrollment
          else
            failed << {
              enrollment_number: change[:enrollment_number],
              errors: class_enrollment.errors.full_messages
            }
          end
        end
        raise ActiveRecord::Rollback if failed.any?
      end
      notification_failures = []
      if failed.any?
        saved_count = 0
      else
        notification_failures = notify_import_changed(updated_enrollments)
      end
      [saved_count, failed, notification_failures]
    end

    def notify_import_changed(enrollments)
      notification_failures = []
      enrollments.each do |class_enrollment|
        class_enrollment.skip_notification = false
        begin
          class_enrollment.send(:notify_student_and_advisor)
        rescue Net::SMTPError, Net::OpenTimeout, Net::ReadTimeout
          notification_failures << class_enrollment.enrollment.enrollment_number
        end
      end
      notification_failures
    end
end
