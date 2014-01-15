# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('grades_report.pdf') do |pdf|
    header_ic(pdf, I18n.t('pdf_content.enrollment.grades_report.title'))

    enrollment_student_header(pdf, enrollment: @enrollment)

    enrollment_header(pdf, enrollment: @enrollment, show_dismissal: true)


    grades_report_table(pdf, enrollment: @enrollment, class_enrollments: @class_enrollments)



    no_page_break(pdf) do
        thesis_table(pdf, enrollment: @enrollment, show_advisors: true)
    end

    no_page_break(pdf) do
    	accomplished_table(pdf, accomplished_phases: @accomplished_phases)
    end

end

