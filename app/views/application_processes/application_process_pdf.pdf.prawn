# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('to_pdf.pdf', I18n.t('pdf_content.enrollment.to_pdf.filename'), :pdf_type => :report) do |pdf|
  pdf.text "Hello World"
end