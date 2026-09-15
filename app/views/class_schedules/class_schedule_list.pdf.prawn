# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

title = I18n.t("pdf_content.class_schedule.class_schedule_list.title")
new_document(
  "class_schedule_list.pdf",
  "#{title} (#{@year}/#{@semester})".upcase,
  page_layout: :landscape, pdf_type: :schedule
) do |pdf|
  class_schedule_list_pdf(
    pdf, course_classes: @course_classes, on_demand: @on_demand
  )
end
