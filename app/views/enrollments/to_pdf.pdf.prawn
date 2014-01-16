# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('to_pdf.pdf', :hide_footer => true) do |pdf|
  header_ic(pdf, I18n.t('pdf_content.enrollment.to_pdf.filename'))
  search_table(pdf, search: @search)
  enrollments_table(pdf, :enrollments => @enrollments)
end

