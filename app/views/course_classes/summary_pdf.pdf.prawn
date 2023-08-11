# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

title = I18n.t("pdf_content.course_class.summary.title")
new_document(
  "summary.pdf",
  title.upcase,
  page_layout: :landscape, pdf_type: :report
) do |pdf|
  summary_header(pdf, course_class: @course_class)
  summary_table(pdf, course_class: @course_class)
  summary_footer(pdf, course_class: @course_class)

  pdf.start_new_page
  email_title = I18n.t("pdf_content.course_class.summary.email_title")
  header(pdf, email_title.upcase, nil, pdf_type: :report)
  summary_header(pdf, course_class: @course_class)
  summary_emails_table(pdf, course_class: @course_class)
end
