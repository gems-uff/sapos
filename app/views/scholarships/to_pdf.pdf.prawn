# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

prawn_document(:filename => 'relatorio.pdf') do |pdf|
  header(pdf)
  document_title(pdf, I18n.t("pdf_content.scholarships.to_pdf.filename"))
  scholarships_table(pdf, scholarships: @scholarships)
end

