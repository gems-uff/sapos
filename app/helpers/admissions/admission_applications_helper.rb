# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionApplicationsHelper
  include StudentHelperConcern
  include EnrollmentHelperConcern
  include ClassEnrollmentHelperConcern

  # StudentHelperConcern
  alias_method(
    :student_city_form_column,
    :custom_city_form_column
  )
  alias_method(
    :student_birth_city_form_column,
    :custom_birth_city_form_column
  )
  alias_method(
    :student_identity_issuing_place_form_column,
    :custom_identity_issuing_place_form_column
  )
  alias_method(
    :student_photo_form_column,
    :custom_photo_form_column
  )

  # EnrollmentHelperConcern
  alias_method(
    :enrollment_deferral_approval_date_form_column,
    :custom_deferral_approval_date_form_column
  )
  alias_method(
    :enrollment_accomplishment_conclusion_date_form_column,
    :custom_accomplishment_conclusion_date_form_column
  )
  alias_method(
    :enrollment_dismissal_date_form_column,
    :custom_dismissal_date_form_column
  )
  alias_method(
    :enrollment_admission_date_form_column,
    :custom_admission_date_form_column
  )
  alias_method(
    :enrollment_level_form_column,
    :custom_level_form_column
  )

  # ClassEnrollmentHelperConcern
  alias_method(
    :class_enrollment_course_class_form_column,
    :custom_course_class_form_column
  )
  alias_method(
    :class_enrollment_disapproved_by_absence_form_column,
    :custom_disapproved_by_absence_form_column
  )
  alias_method(
    :class_enrollment_grade_form_column,
    :custom_grade_form_column
  )
  alias_method(
    :class_enrollment_grade_not_count_in_gpr_form_column,
    :custom_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :class_enrollment_obs_form_column,
    :custom_obs_form_column
  )
  alias_method(
    :class_enrollment_justification_grade_not_count_in_gpr_form_column,
    :custom_justification_grade_not_count_in_gpr_form_column
  )
  alias_method(
    :field_attributes,
    :custom_field_attributes
  )

  def letter_requests_column(record, column)
    if record.letter_requests.any?
      "#{record.letter_requests.first(3).filter_map do |letter|
           h(letter.to_label) if letter.filled_form.is_filled
         end.join(', ')} / #{record.requested_letters}".html_safe
    else
      active_scaffold_config.list.empty_field_text
    end
  end

  def status_column(record, column)
    return record.descriptive_status if params[:simple_view].present?
    result = ""
    if record.status.present?
      result += record.status
    elsif current_user.present? && record.pendencies.where(
        user_id: current_user.id,
        status: Admissions::AdmissionPendency::PENDENT,
        admission_phase_id: record.admission_phase_id
      ).first.present?
      result += Admissions::AdmissionPendency::PENDENT
    end
    if record.status_message.present?
      result = [result, record.status_message].reject(&:empty?).join(": ")
    end
    if record.enrollment.present?
      result = [result, "Com matrícula"].reject(&:empty?).join(" - ")
    elsif record.student.present?
      result = [result, "Com aluno"].reject(&:empty?).join(" - ")
    end
    result = active_scaffold_config.list.empty_field_text if result.empty?
    result
  end

  def filled_form_show_column(record, column)
    render partial: "filled_form_show", locals: {
      record: record,
      column: column
    }
  end

  def letter_requests_show_column(record, column)
    render active_scaffold: "admissions/letter_requests", params: {
      parent_scaffold: "admissions/admission_applications",
      admission_application_id: record.id,
      association: "letter_requests"
    }
  end

  def results_show_column(record, column)
    render active_scaffold: "admissions/admission_phase_results", params: {
      parent_scaffold: "admissions/admission_applications",
      admission_application_id: record.id,
      association: "results"
    }
  end

  def evaluations_show_column(record, column)
    render active_scaffold: "admissions/admission_phase_evaluations", params: {
      parent_scaffold: "admissions/admission_applications",
      admission_application_id: record.id,
      association: "evaluations"
    }
  end

  def rankings_show_column(record, column)
    render active_scaffold: "admissions/admission_ranking_results", params: {
      parent_scaffold: "admissions/admission_applications",
      admission_application_id: record.id,
      association: "rankings"
    }
  end

  def status_search_column(record, options)
    select(record, :status, [
      [I18n.t("active_scaffold._select_"), nil],
      ["-", -current_user.id],
      [Admissions::AdmissionPendency::PENDENT, current_user.id]
    ] + Admissions::AdmissionApplication::STATUSES.map do |status|
      [status, status]
    end, options, options)
  end

  def mapping_search_column(record, options)
    select(record, :status, [
      [I18n.t("active_scaffold._select_"), nil],
      ["Com aluno", :student],
      ["Com matrícula", :enrollment],
      ["Com aluno sem matrícula", :student_no_enrollment],
    ], options, options)
  end

  def options_for_association_conditions(association, record)
    result = enrollment_options_for_association_conditions(association, record)
    return result if result != "<not found>"
    super
  end

end
