# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "prawn/measurement_extensions"

new_document(
  @filename,
  I18n.t("pdf_content.enrollment.header.title"),
  watermark: cannot?(
    :generate_report_without_watermark, @enrollment
  ),
  pdf_type: :transcript
) do |pdf|
  enrollment_student_header(pdf, enrollment: @enrollment)

  enrollment_header(pdf, enrollment: @enrollment, program_level: @program_level)

  transcript_table(pdf, class_enrollments: @class_enrollments)

  justification_grade_not_count_in_gpr_table(pdf, enrollment: @enrollment)

  thesis_table(pdf, enrollment: @enrollment)

  obs_table(pdf, enrollment: @enrollment)

  enrollment_holds_table(pdf, enrollment: @enrollment)
end
