# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

prawn_document(:filename => I18n.t("pdf_content.scholarship_durations.to_pdf.filename")) do |pdf|
  header(pdf)
  document_title(pdf, I18n.t("pdf_content.scholarship_durations.to_pdf.filename"))
  scholarship_durations_table(pdf, scholarship_durations: @scholarship_durations)
end

