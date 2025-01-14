# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

new_document(
  @filename,
  I18n.t("pdf_content.enrollment.grades_report.title"),
  watermark: (
    current_user.nil? ? false : cannot?(
      :generate_report_without_watermark, @enrollment
    )
  ),
  pdf_type: :grades_report,
  signature_override: can?(:override_report_signature_type, @enrollment) ? @signature_type : nil
) do |pdf|
  enrollment_student_header(pdf, enrollment: @enrollment)

  grades_report_header(pdf, enrollment: @enrollment)

  grades_report_table(pdf, enrollment: @enrollment, class_enrollments: @class_enrollments)

  justification_grade_not_count_in_gpr_table(pdf, enrollment: @enrollment)

  thesis_table(pdf, enrollment: @enrollment, show_advisors: true)

  obs_table(pdf, enrollment: @enrollment)

  accomplished_table(pdf, accomplished_phases: @accomplished_phases)

  deferrals_table(pdf, deferrals: @deferrals)

  enrollment_holds_table(pdf, enrollment: @enrollment)

  enrollment_scholarships_table(pdf, enrollment: @enrollment)
end
