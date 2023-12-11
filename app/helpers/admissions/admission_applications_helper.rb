# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionApplicationsHelper
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
    result = ""
    if record.status.present?
      result += record.status
    elsif current_user.present? && record.pendencies.where(
        user_id: current_user.id,
        status: Admissions::AdmissionPendency::PENDENT
      ).first.present?
      result += Admissions::AdmissionPendency::PENDENT
    else
      result += active_scaffold_config.list.empty_field_text
    end
    if record.status_message.present?
      result += ": #{record.status_message}"
    end
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
end
