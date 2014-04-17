# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('class_schedule.pdf', :page_layout => :landscape, :hide_footer => true) do |pdf|
  header(pdf, "#{I18n.t('pdf_content.course_class.class_schedule.title')} (#{@year}/#{@semester})".upcase)

  class_schedule_table(pdf, course_classes: @course_classes)  
end

