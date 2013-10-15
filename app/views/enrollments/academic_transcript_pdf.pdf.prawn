# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

prawn_document(:left_margin => 20, :right_margin => 20, :top_margin => 30, :bottom_margin => 80, :filename => 'transcript.pdf') do |pdf|
    header(pdf)

    document_title(pdf, I18n.t('pdf_content.enrollment.academic_transcript.title'))

    enrollment_header(pdf, enrollment: @enrollment)

    transcript_table(pdf, class_enrollments: @class_enrollments)

    accomplished_table(pdf, accomplished_phases: @accomplished_phases)
    
    if not @enrollment.dismissal.nil? and @enrollment.dismissal.dismissal_reason.show_advisor_name
    	advisors_list(pdf, enrollment: @enrollment)
    end

    pdf.repeat(:all, dynamic: true) do
      page_footer(pdf)
    end
end

