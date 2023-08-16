# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module AdvisementsPdfHelper
  def advisements_table(pdf, options = {})
    advisements ||= options[:advisements]

    widths = [140, 140, 140, 140]

    header = [[
      "<b>#{I18n.t("pdf_content.advisements.to_pdf.professor_name")}</b>",
      "<b>#{I18n.t("pdf_content.advisements.to_pdf.enrollment_number")}</b>",
      "<b>#{I18n.t("pdf_content.advisements.to_pdf.student_name")}</b>",
      "<b>#{I18n.t("pdf_content.advisements.to_pdf.level_name")}</b>"
    ]]

    simple_pdf_table(pdf, widths, header, advisements) do |table|
      table.column(0).align = :left
      table.column(0).padding = [2, 4]
      table.column(2).align = :left
      table.column(2).padding = [2, 4]
    end
  end
end
