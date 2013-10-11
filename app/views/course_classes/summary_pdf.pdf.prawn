# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

prawn_document(:page_layout => :landscape, :filename => 'summary.pdf') do |pdf|
  header(pdf)
  document_title(pdf, "#{I18n.t('pdf_content.course_class.summary.title')}".upcase)

  summary_header(pdf, course_class: @course_class)
  summary_table(pdf, course_class: @course_class)   
  summary_footer(pdf, course_class: @course_class)     
end

