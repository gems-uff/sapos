# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('summary.pdf', "#{I18n.t('pdf_content.course_class.summary.title')}".upcase, :page_layout => :landscape, :pdf_type => :report) do |pdf|

  summary_header(pdf, course_class: @course_class)
  summary_table(pdf, course_class: @course_class)   
  summary_footer(pdf, course_class: @course_class)     

  pdf.start_new_page
  header(pdf, "#{I18n.t('pdf_content.course_class.summary.email_title')}".upcase, nil, :pdf_type => :report)
  summary_header(pdf, course_class: @course_class)
  summary_emails_table(pdf, course_class: @course_class) 
end

