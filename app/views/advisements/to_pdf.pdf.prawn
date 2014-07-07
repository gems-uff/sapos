# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('relatorio.pdf', :hide_footer => true) do |pdf|
  header(pdf, I18n.t("pdf_content.advisements.to_pdf.filename"), :pdf_type => :report)
  advisements_table(pdf, advisements: @advisements)
end

