# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('summary.pdf', :page_layout => :landscape, :hide_footer => true) do |pdf|
  header_ic(pdf, "#{I18n.t('pdf_content.course_class.summary.title')}".upcase)

  summary_header(pdf, course_class: @course_class)
  summary_table(pdf, course_class: @course_class)   
  summary_footer(pdf, course_class: @course_class)     

  pdf.start_new_page
  header_ic(pdf, "#{I18n.t('pdf_content.course_class.summary.email_title')}".upcase)
  summary_header(pdf, course_class: @course_class)
  summary_emails_table(pdf, course_class: @course_class) 
end

