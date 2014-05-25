# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document(I18n.t("pdf_content.scholarship_durations.to_pdf.filename"), :hide_footer => true) do |pdf|
  header(pdf, I18n.t("pdf_content.scholarship_durations.to_pdf.filename"))
  scholarship_durations_table(pdf, scholarship_durations: @scholarship_durations)
end

