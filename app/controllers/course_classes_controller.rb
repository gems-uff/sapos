# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CourseClassesController < ApplicationController
  authorize_resource
  include SharedPdfConcern
  include SharedXlsConcern
  include NumbersHelper

  IMPORT_SESSION_KEY = "xls_import_grades"

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
      type: :member


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

    if request.get? && params[:cancel] == "1"
      if find_import_preview(params[:token])
        discard_import_preview
      else
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_stale_preview")
      end
      redirect_to course_classes_path and return
    end

    if request.post? && params[:confirm] == "1"
      preview = find_import_preview(params[:token])
      unless preview
        if session[IMPORT_SESSION_KEY].blank?
          flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_nothing_saved")
          redirect_to course_classes_path and return
        end
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_stale_preview")
        redirect_to import_grades_xls_course_class_path(@course_class) and return
      end

      if preview.expired?
        discard_import_preview
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_expired")
        redirect_to import_grades_xls_course_class_path(@course_class) and return
      end

      stored_results = preview.payload
      if stored_results[:rows].blank?
        discard_import_preview
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_nothing_saved")
        redirect_to course_classes_path and return
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
        result = compute_import_row(row[:enrollment_number], class_enrollment, data)
        result[:diverged] = (
          class_enrollment.grade != row[:snapshot_grade] ||
          class_enrollment.situation != row[:snapshot_situation] ||
          class_enrollment.disapproved_by_absence != row[:snapshot_attendance] ||
          class_enrollment.grade_not_count_in_gpr != row[:snapshot_grade_not_count_in_gpr] ||
          class_enrollment.obs.to_s != row[:snapshot_obs].to_s
        )
        result
      end

      total_rows = stored_results[:total_rows] || recomputed.size

      if recomputed.any? { |r| r[:diverged] || r[:status] != "pending" }
        @results = recomputed
        @token = preview.token
        # created_at fica como estava: a expiracao conta do envio original.
        preview.payload = build_preview_payload(recomputed, total_rows)
        preview.save!
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

      saved_count, failure, notification_failures = apply_xls_import_changes(changes)
      discard_import_preview

      if failure
        flash[:error] = I18n.t(
          "xls_content.course_class.import_grades_xls_none_saved",
          details: "#{failure[:enrollment_number]}: #{failure[:errors].join(", ")}"
        )
      elsif saved_count == 0
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_nothing_saved")
      else
        pending_count = total_rows - saved_count
        flash[:info] =
          if pending_count <= 0
            I18n.t("xls_content.course_class.import_grades_xls_success", count: saved_count)
          else
            I18n.t("xls_content.course_class.import_grades_xls_success_with_pending", saved: saved_count, total: total_rows, pending: pending_count)
          end
        if notification_failures.any?
          flash[:warning] = I18n.t("xls_content.course_class.import_grades_xls_notification_failure", enrollment_numbers: notification_failures.join(", "))
        end
      end

      redirect_to course_classes_path and return
    elsif request.post? && params[:spreadsheet].present?
      begin
        @results = build_xls_import_preview(params[:spreadsheet])
        @token = SecureRandom.hex(16)
        store_import_preview(@results, token: @token)
        render :import_grades_xls_results and return
      rescue SpreadsheetTooLarge
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_too_large")
        redirect_to import_grades_xls_course_class_path(@course_class) and return
      rescue SpreadsheetEmpty
        flash[:error] = I18n.t("xls_content.course_class.import_grades_xls_empty")
        redirect_to import_grades_xls_course_class_path(@course_class) and return
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

    def build_xls_import_preview(file)
      parsed_rows = parse_rows_xls(file)

      enrollment_numbers = parsed_rows.map { |data| data[:enrollment_number] }

      enrollments_by_number = Enrollment
      .where(enrollment_number: enrollment_numbers)
      .to_a
      .group_by { |enrollment| enrollment.enrollment_number.to_s.strip.downcase }
      .transform_values(&:first)

      enrollments = enrollments_by_number.values

      class_enrollments_by_enrollment_id = @course_class
      .class_enrollments
      .where(enrollment_id: enrollments.map(&:id))
      .to_a
      .group_by(&:enrollment_id)
      .transform_values(&:first)

      resolved_rows = parsed_rows.map do |data|
        enrollment_number = data[:enrollment_number]
        normalized_enrollment_number = enrollment_number.to_s.strip.downcase
        enrollment = enrollments_by_number[normalized_enrollment_number]
        class_enrollment = enrollment && class_enrollments_by_enrollment_id[enrollment.id]
        group_key =
        if class_enrollment
          "class_enrollment:#{class_enrollment.id}"
        elsif enrollment
          "enrollment:#{enrollment.id}"
        else
          "unmatched:#{enrollment_number.to_s.strip.downcase}"
        end

        data.merge(
          enrollment: enrollment,
          class_enrollment: class_enrollment,
          group_key: group_key
        )
      end

      occurrence_counts = resolved_rows.each_with_object(Hash.new(0)) { |r, h| h[r[:group_key]] += 1 }
      duplicate_group_keys = occurrence_counts.select { |_, count| count > 1 }.keys

      results = []
      resolved_rows.each do |data|
        enrollment_number = data[:enrollment_number]

        if duplicate_group_keys.include?(data[:group_key])
          results << {
            enrollment_number: enrollment_number,
            status: "duplicate",
            occurrence_count: occurrence_counts[data[:group_key]]
          }
          next
        end

        unless data[:enrollment]
          results << { enrollment_number: enrollment_number, status: "not_found" }
          next
        end

        unless data[:class_enrollment]
          results << { enrollment_number: enrollment_number, status: "not_enrolled" }
          next
        end

        results << compute_import_row(enrollment_number, data[:class_enrollment], data)
      end
      results
    end

    def compute_import_row(enrollment_number, class_enrollment, data)
      grade_of_disapproval_for_absence = CustomVariable.grade_of_disapproval_for_absence
      minimum_grade_for_approval = CustomVariable.minimum_grade_for_approval

      if data[:grade].present?
        imported_grade_scaled = parse_import_grade(data[:grade])
        if imported_grade_scaled
          final_grade = imported_grade_scaled
          invalid_grade = false
        else
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
        if class_enrollment.course_has_grade && !grade_of_disapproval_for_absence.nil?
          final_grade = grade_of_disapproval_for_absence
        end
      elsif final_grade.present? && !class_enrollment.grade_not_count_in_gpr?
        final_situation = final_grade.to_f >= minimum_grade_for_approval ? ClassEnrollment::APPROVED : ClassEnrollment::DISAPPROVED
      end

      final_obs = data[:obs].present? ? data[:obs] : class_enrollment.obs
      final_grade_view = final_grade.present? ? (final_grade.to_f / 10.0).to_s.tr(".", ",") : nil
      validation_errors = prospective_validation_errors(class_enrollment, final_grade, final_attendance, final_situation, final_obs)
      nothing_to_launch = data[:grade].blank? &&
        final_grade == class_enrollment.grade &&
        final_situation == class_enrollment.situation &&
        final_attendance == !class_enrollment.disapproved_by_absence &&
        final_obs.to_s == class_enrollment.obs.to_s
      status =
        if invalid_grade || validation_errors.any? then "invalid"
        elsif nothing_to_launch then "unchanged"
        else "pending"
        end

      {
        enrollment_number: enrollment_number,
        class_enrollment_id: class_enrollment.id,
        status: status,
        current_grade: class_enrollment.grade_to_view.to_s.tr(".", ","),
        current_grade_raw: class_enrollment.grade,
        current_obs_raw: class_enrollment.obs,
        imported_grade: data[:grade],
        final_grade: final_grade,
        final_grade_view: final_grade_view,
        grade_diff: imported_grade_scaled.present? && imported_grade_scaled != final_grade.to_f,
        invalid_grade: invalid_grade,
        current_grade_not_count_in_gpr_raw: class_enrollment.grade_not_count_in_gpr,

        imported_attendance: data[:attendance],
        current_attendance_raw: class_enrollment.disapproved_by_absence,
        final_attendance: final_attendance,
        invalid_attendance: invalid_attendance,

        current_situation: class_enrollment[:situation],
        imported_situation: data[:situation],
        final_situation: final_situation,
        situation_diff: data[:situation].present? && ClassEnrollment::SITUATIONS.include?(data[:situation]) && data[:situation] != final_situation,
        invalid_situation: invalid_situation,

        final_obs: final_obs,
        imported_obs: data[:obs],
        diverged: false,
        validation_errors: validation_errors
      }
    end

    def prospective_validation_errors(class_enrollment, final_grade, final_attendance, final_situation, final_obs)
      probe = ClassEnrollment.find(class_enrollment.id)
      probe.grade = final_grade
      probe.disapproved_by_absence = !final_attendance
      probe.situation = final_situation
      probe.obs = final_obs
      probe.valid?
      probe.errors.full_messages
    end

    def find_import_preview(token)
      return nil if token.blank?
      preview = ImportGradePreview.find_by(token: token.to_s)
      preview if preview&.owned_by?(current_user, @course_class)
    end

    def discard_import_preview
      token = session.delete(IMPORT_SESSION_KEY)
      ImportGradePreview.where(token: token).delete_all if token.present?
    end

    def build_preview_payload(results, total_rows)
      {
        total_rows: total_rows,
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
            snapshot_grade_not_count_in_gpr: r[:current_grade_not_count_in_gpr_raw],
            snapshot_obs: r[:current_obs_raw]
          }
        end
      }
    end

    def store_import_preview(results, token:)
      ImportGradePreview.replace!(
        user: current_user, course_class: @course_class, token: token,
        payload: build_preview_payload(results, results.size)
      )
      session[IMPORT_SESSION_KEY] = token
    end

    def apply_xls_import_changes(changes)
      updated = []
      failure = nil
      current_number = nil
      notify_professor = false
      begin
        ClassEnrollment.transaction do
          changes.each do |change|
            next unless change[:status] == "pending"
            class_enrollment = @course_class.class_enrollments.find_by(id: change[:class_enrollment_id])
            next unless class_enrollment
            current_number = change[:enrollment_number]

            class_enrollment.grade = change[:final_grade]
            class_enrollment.disapproved_by_absence = !change[:final_attendance]
            class_enrollment.situation = change[:final_situation]
            class_enrollment.obs = change[:final_obs]
            class_enrollment.skip_notification = true
            notify_professor ||= class_enrollment.should_send_email_to_professor?

            unless class_enrollment.save
              failure = {
                enrollment_number: current_number,
                errors: class_enrollment.errors.full_messages
              }
              raise ActiveRecord::Rollback
            end
            updated << class_enrollment
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        log_import_exception("gravacao", e)
        failure = { enrollment_number: current_number, errors: [e.message] }
      end
      return [0, failure, []] if failure
      notification_failures = notify_import_changed(updated)
      if notify_professor && !notify_professor_of_import
        notification_failures << @course_class.professor.email
      end
      [updated.size, nil, notification_failures]
    end

    def log_import_exception(context, error)
      Rails.logger.error("[import_grades_xls] #{context}: #{error.class}: #{error.message}")
    end

    def notify_import_changed(enrollments)
      notification_failures = []
      enrollments.each do |class_enrollment|
        class_enrollment.skip_notification = false
        begin
          class_enrollment.send(:notify_student_and_advisor)
        rescue StandardError => e
          log_import_exception("notificacao de aluno/orientador", e)
          notification_failures << class_enrollment.enrollment.enrollment_number
        end
      end
      notification_failures
    end

    def notify_professor_of_import
      professor_email = @course_class.professor&.email
      return true if professor_email.blank?
      email = EmailTemplate.load_template("course_classes:email_to_professor")
        .prepare_message({ record: @course_class })
      Notifier.send_emails(notifications: [email])
      true
    rescue StandardError => e
      log_import_exception("notificacao do professor", e)
      false
    end

    def parse_import_grade(raw)
      if raw.is_a?(Numeric)
        value = raw.to_f
      else
        text = raw.to_s.strip.tr(",", ".")
        return nil unless text.match?(/\A\d+(\.\d)?\z/)
        value = text.to_f
      end
      scaled = (value * 10).round
      return nil unless (value * 10 - scaled).abs < 1e-6 && scaled.between?(0, 100)
      scaled
    end
end
