prawn_document(:left_margin => 20, :right_margin => 20, :top_margin => 30, :bottom_margin => 80, :filename => 'grades_report.pdf') do |pdf|
    header(pdf)

    document_title(pdf, I18n.t('pdf_content.enrollment.grades_report.title'))

    enrollment_header(pdf, enrollment: @enrollment)

    grades_report_table(pdf, enrollment: @enrollment)

    accomplished_table(pdf, accomplished_phases: @accomplished_phases)

    advisors_list(pdf, enrollment: @enrollment)

    pdf.repeat(:all, dynamic: true) do
      page_footer(pdf)
    end
end

