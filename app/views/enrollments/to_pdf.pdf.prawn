# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

prawn_document(:filename => 'to_pdf.pdf') do |pdf|
  header(pdf)
  document_title(pdf, I18n.t("pdf_content.enrollment.to_pdf.filename"))
  enrollments_table(pdf, :enrollments => @enrollments)
end

