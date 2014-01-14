# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "prawn/measurement_extensions"

new_document('transcript.pdf') do |pdf|
    
    header_uff(pdf, I18n.t("pdf_content.enrollment.header.title"))

    enrollment_student_header(pdf, enrollment: @enrollment)

    enrollment_header(pdf, enrollment: @enrollment)

    transcript_table(pdf, class_enrollments: @class_enrollments)

    no_page_break(pdf) do
        thesis_table(pdf, enrollment: @enrollment)
    end
 
end

