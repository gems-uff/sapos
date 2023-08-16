# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module StudentEnrollmentHelper
  def find_class_enrollment_request_for_class_schedule_table_row(
    enrollment_request, row
  )
    cer = nil
    enrollment_request.class_enrollment_requests.each do |temp_cer|
      if !row[0][:on_demand] && temp_cer.course_class_id == row[0][:id]
        cer = temp_cer
      elsif row[0][:on_demand] && (
        temp_cer.course_class.course_id == row[0][:course_id]
      )
        cer = temp_cer
        row[0][:id] = cer.course_class_id
        row[-1] = cer.course_class.professor.name
      end
    end
    cer
  end

  def display_class_schedule_table_row?(semester, cer)
    semester.main_enroll_open? ||
    semester.adjust_enroll_insert_open? ||
    cer.present?
  end

  def display_non_on_demand_or_selected_on_demand?(row, cer)
    !row[0][:on_demand] || (
      cer.present? && !(
        cer.action == ClassEnrollmentRequest::REMOVE &&
        cer.status == ClassEnrollmentRequest::EFFECTED
      )
    )
  end

  def on_demand_row_style(cer)
    return "" if cer.blank?
    return "" if cer.action == ClassEnrollmentRequest::REMOVE &&
      cer.status == ClassEnrollmentRequest::EFFECTED

    'style="display: none;"'.html_safe
  end

  def cer_tr_class(cer, count)
    even = count.even? ? "even-record" : ""
    return "class=\"record #{even}\"".html_safe if cer.blank?
    "class=\"record #{even} enroll-row-#{
      ClassEnrollmentRequest::STATUSES_MAP[cer.db_status]
    }\"".html_safe
  end

  def cer_row_status(cer)
    return "&nbsp;".html_safe if cer.blank? || !cer.persisted?
    row_status = cer.db_status
    row_status = "#{cer.db_action} #{row_status}" if
      cer.db_action == ClassEnrollmentRequest::REMOVE
    row_status.html_safe
  end

  def enroll_table_td(options)
    tdclass = options[:tdclass] || nil
    labelclass = options[:labelclass] || nil
    content_tag(:td, class: tdclass) do
      options[:form].label(
        options[:labelid],
        for: "table_row_#{options[:row_index]}",
        class: labelclass
      ) do
        yield if block_given?
      end
    end
  end
end
