# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('grades_report.pdf', I18n.t('pdf_content.enrollment.grades_report.title'), :watermark => (current_user.role_id == Role::ROLE_PROFESSOR), :pdf_type => :grades_report) do |pdf|

    enrollment_student_header(pdf, enrollment: @enrollment)

    grades_report_header(pdf, enrollment: @enrollment)


    grades_report_table(pdf, enrollment: @enrollment, class_enrollments: @class_enrollments)



    no_page_break(pdf) do
        thesis_table(pdf, enrollment: @enrollment, show_advisors: true)
    end

    no_page_break(pdf) do
    	accomplished_table(pdf, accomplished_phases: @accomplished_phases)
    end

    no_page_break(pdf) do
        deferrals_table(pdf, deferrals: @deferrals)
    end

    no_page_break(pdf) do
        enrollment_scholarships_table(pdf, enrollment: @enrollment)
    end

    no_page_break(pdf) do
        enrollment_holds_table(pdf, enrollment: @enrollment)
    end

end

