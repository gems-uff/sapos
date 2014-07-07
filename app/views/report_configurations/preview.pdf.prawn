# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('preview.pdf', :hide_footer => true) do |pdf|
  header(pdf, I18n.t("pdf_content.custom_variables.pdf_header.preview"), pdf_config: @pdf_config)
end

